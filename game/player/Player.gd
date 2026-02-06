# res://game/player/Player.gd
extends CharacterBody2D

# -----------------------------------------------------------------------------
# MÁQUINA DE ESTADOS
# -----------------------------------------------------------------------------
enum State {
	IDLE,
	ANDANDO,
	PULANDO,
	CAINDO,
	GLIDANDO,
	SWING_ROPE,
	DESLIZANDO,
	AGACHADO,
	OLHANDO_CIMA,
	GROUND_POUND,
	GROUND_POUND_LAND,
	CARTWHEEL,
	WALL_SLIDE,
	MACHUCADO,
	MORTO
}

# -----------------------------------------------------------------------------
# CONFIGURAÇÕES
# -----------------------------------------------------------------------------
@export_group("Config")
@export var debug_print: bool = false
@export var stats: PlayerStats
@export var attack_action: StringName = &"attack"

@export_group("Scene Config")
@export var attack_hitbox_offset_x: float = 14.0
@export var attack_hitbox_offset_y: float = 0.0

@export_group("Tuning Fino (Local)")
# Tempo segurando BAIXO antes de iniciar o Ground Pound (evita acidentes)
@export var gp_hold_threshold: float = 0.12 

# -----------------------------------------------------------------------------
# DEPENDÊNCIAS (NODES)
# -----------------------------------------------------------------------------
@onready var coyote_jump_timer: Timer = get_node_or_null("CoyoteTimer")
@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var player_input: PlayerInput = get_node_or_null("PlayerInput")
@onready var attack_hitbox: Area2D = get_node_or_null("AttackHitbox")

# -----------------------------------------------------------------------------
# VARIÁVEIS DE ESTADO
# -----------------------------------------------------------------------------
var state: State = State.IDLE
var is_alive: bool = true

# Timers Lógicos
var _invuln_left: float = 0.0
var _hurt_left: float = 0.0
var _wall_jump_lock_left: float = 0.0
var _gp_land_left: float = 0.0
var _gp_hold_timer: float = 0.0 
var _attack_left: float = 0.0

# Controle de Movimento
var _is_running: bool = false
var _slide_speed: float = 0.0
var _slope_direction: int = 0
var _facing: int = 1
var _was_on_floor: bool = false
var _down_was_held: bool = false

# Controle de Ataque
var _attack_dir: int = 1
var _cartwheel_air_jump_charges: int = 0

var _ok: bool = true

# -----------------------------------------------------------------------------
# API PÚBLICA
# -----------------------------------------------------------------------------
func is_crouching() -> bool:
	return state == State.AGACHADO

func is_looking_up() -> bool:
	return state == State.OLHANDO_CIMA

# -----------------------------------------------------------------------------
# CICLO DE VIDA (INIT)
# -----------------------------------------------------------------------------
func _ready() -> void:
	_ok = _validate_and_init()
	if not _ok:
		set_physics_process(false)
		set_process(false)

func _validate_and_init() -> bool:
	if stats == null:
		stats = PlayerStats.new()

	if coyote_jump_timer == null or anim_sprite == null or player_input == null:
		return false

	floor_snap_length = stats.floor_snap_length
	coyote_jump_timer.one_shot = true
	coyote_jump_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	coyote_jump_timer.wait_time = stats.coyote_seconds

	player_input.configure_from_stats(stats)
	_slide_speed = stats.slide_speed_start
	_was_on_floor = is_on_floor()
	is_alive = true

	_setup_attack_hitbox()
	_update_attack_hitbox_position(_facing)

	set_state(State.IDLE if is_on_floor() else State.CAINDO)
	return true

func _setup_attack_hitbox() -> void:
	if attack_hitbox == null: return
	attack_hitbox.monitoring = false
	
	var cb_body := Callable(self, "_on_attack_body_entered")
	if not attack_hitbox.body_entered.is_connected(cb_body):
		attack_hitbox.body_entered.connect(cb_body)

	var cb_area := Callable(self, "_on_attack_area_entered")
	if not attack_hitbox.area_entered.is_connected(cb_area):
		attack_hitbox.area_entered.connect(cb_area)

# -----------------------------------------------------------------------------
# PHYSICS PROCESS
# -----------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not _ok: return
	var dt_ticks := delta * float(Engine.physics_ticks_per_second)
	_tick_timers(delta)

	if state == State.MORTO:
		_apply_gravity(dt_ticks)
		move_and_slide()
		_play_animations()
		return

	player_input.poll()
	var input := player_input.snapshot
	var down_pressed := input.down_held and not _down_was_held
	_down_was_held = input.down_held
	var attack_pressed := input.attack_pressed

	_update_facing(input.axis)
	_update_run_latch(input)
	_update_state(input, down_pressed, attack_pressed, delta)

	match state:
		State.DESLIZANDO: _apply_slide(dt_ticks, input)
		State.MACHUCADO: _apply_inertia(dt_ticks)
		State.AGACHADO: _apply_crouch(dt_ticks, input)
		State.OLHANDO_CIMA: _apply_look_up(dt_ticks)
		State.GROUND_POUND: _apply_ground_pound(dt_ticks)
		State.GROUND_POUND_LAND: _apply_land_lock(dt_ticks, input)
		State.CARTWHEEL: _apply_cartwheel(dt_ticks)
		State.WALL_SLIDE: _apply_wall_slide(dt_ticks, input)
		_: _apply_walk(dt_ticks, input)

	_apply_jump_logic_cartwheel_aware()

	if input.jump_released and velocity.y < 0.0:
		if _wall_jump_lock_left <= 0.0:
			velocity.y *= stats.jump_cut_multiplier

	_apply_gravity(dt_ticks)
	move_and_slide()
	_post_move()
	_play_animations()
	
	if debug_print:
		print("St:", State.keys()[state], " Battery:", Global.session.battery, " VX:", int(velocity.x))

# -----------------------------------------------------------------------------
# TIMERS
# -----------------------------------------------------------------------------
func _tick_timers(delta: float) -> void:
	if _invuln_left > 0.0:
		_invuln_left = maxf(0.0, _invuln_left - delta)
	if _hurt_left > 0.0:
		_hurt_left = maxf(0.0, _hurt_left - delta)
		if _hurt_left <= 0.0 and state == State.MACHUCADO:
			set_state(State.IDLE if is_on_floor() else State.CAINDO)

	if state == State.GROUND_POUND_LAND and _gp_land_left > 0.0:
		_gp_land_left = maxf(0.0, _gp_land_left - delta)

	if _attack_left > 0.0:
		_attack_left = maxf(0.0, _attack_left - delta)
		if _attack_left <= 0.0 and state == State.CARTWHEEL:
			_end_cartwheel()
			
	if _wall_jump_lock_left > 0.0:
		_wall_jump_lock_left = maxf(0.0, _wall_jump_lock_left - delta)

func _update_facing(axis: int) -> void:
	if _wall_jump_lock_left > 0.0: return
	if axis < 0: _facing = -1
	elif axis > 0: _facing = 1
	if anim_sprite != null: anim_sprite.flip_h = _facing < 0
	_update_attack_hitbox_position(_facing)

func _update_attack_hitbox_position(dir: int) -> void:
	if attack_hitbox == null: return
	attack_hitbox.position.x = attack_hitbox_offset_x * float(dir)
	attack_hitbox.position.y = attack_hitbox_offset_y

func _update_run_latch(input: PlayerInput.Snapshot) -> void:
	if is_on_floor(): _is_running = input.run_held
	elif not input.run_held: _is_running = false

func _current_speed_cap(input: PlayerInput.Snapshot) -> float:
	var cap := stats.max_run_speed if _is_running else stats.max_walk_speed
	if not is_on_floor() and input.run_held and not _is_running:
		cap = maxf(cap, stats.max_walk_speed + stats.run_air_speed_bonus)
	return cap

# -----------------------------------------------------------------------------
# MÁQUINA DE ESTADOS: TRANSIÇÕES
# -----------------------------------------------------------------------------
func set_state(next: State) -> void:
	if next == state: return
	if not _can_transition(state, next): return
	_exit_state(state)
	state = next
	_enter_state(state)

func _can_transition(from: State, to: State) -> bool:
	if from == State.MORTO: return false
	if from == State.MACHUCADO and to in [State.DESLIZANDO, State.GROUND_POUND, State.CARTWHEEL, State.WALL_SLIDE]:
		return false
	return true

func _enter_state(s: State) -> void:
	match s:
		State.DESLIZANDO: _slide_speed = stats.slide_speed_start
		State.GLIDANDO: _apply_glide_open_pop()
		State.GROUND_POUND:
			_gp_hold_timer = 0.0
			if velocity.y < stats.ground_pound_start_speed: velocity.y = stats.ground_pound_start_speed
		State.GROUND_POUND_LAND: _gp_land_left = stats.ground_pound_land_seconds
		State.CARTWHEEL:
			_attack_left = stats.attack_seconds
			_attack_dir = _facing
			_cartwheel_air_jump_charges = 0
			var start_speed := stats.attack_start_speed
			if absf(velocity.x) > start_speed:
				start_speed = minf(absf(velocity.x), stats.attack_base_max_speed)
			velocity.x = start_speed * float(_attack_dir)
			_set_attack_hitbox_enabled(true)
		State.WALL_SLIDE:
			if velocity.y > 0: velocity.y = 0 
			var w_normal = get_wall_normal().x
			if w_normal != 0:
				_facing = -int(sign(w_normal))
				if anim_sprite: anim_sprite.flip_h = _facing < 0

func _exit_state(s: State) -> void:
	match s:
		State.DESLIZANDO: _slide_speed = stats.slide_speed_start
		State.CARTWHEEL: _set_attack_hitbox_enabled(false)

func _update_state(input: PlayerInput.Snapshot, _down_pressed: bool, attack_pressed: bool, delta: float) -> void:
	# --- AJUSTE 1: Ground Pound Land em Rampa vira Slide ---
	if state == State.GROUND_POUND_LAND:
		if absf(get_floor_angle()) > stats.slope_threshold:
			set_state(State.DESLIZANDO)
		return
	# -------------------------------------------------------

	# Timer Ground Pound
	if (not is_on_floor()) and input.down_held and input.axis == 0 and state != State.WALL_SLIDE:
		_gp_hold_timer += delta
		if _gp_hold_timer >= gp_hold_threshold:
			set_state(State.GROUND_POUND)
			return
	else:
		_gp_hold_timer = 0.0

	if state not in [State.MACHUCADO, State.GROUND_POUND, State.GROUND_POUND_LAND] and is_on_floor() and attack_pressed:
		if input.axis != 0: _facing = input.axis
		set_state(State.CARTWHEEL)
		return
	elif state not in [State.MACHUCADO] and is_on_floor() and attack_pressed and stats.attack_allow_start_still:
		set_state(State.CARTWHEEL)
		return

	if state == State.CARTWHEEL: return
	if state != State.MACHUCADO and _should_slide(input):
		set_state(State.DESLIZANDO)
		return

	if state == State.DESLIZANDO and not _should_slide(input):
		set_state(State.ANDANDO if absf(velocity.x) > 0.1 else State.IDLE)
		return

	if state == State.GROUND_POUND and not is_on_floor(): return

	if not is_on_floor():
		if _is_touching_world_wall() and velocity.y > 20.0 and state != State.WALL_SLIDE:
			var w_normal = get_wall_normal().x
			var holding_against = (w_normal < 0 and input.axis > 0) or (w_normal > 0 and input.axis < 0)
			if holding_against:
				set_state(State.WALL_SLIDE)
				return
		
		if state == State.WALL_SLIDE:
			var w_normal = get_wall_normal().x
			var holding_against = (w_normal < 0 and input.axis > 0) or (w_normal > 0 and input.axis < 0)
			if not _is_touching_world_wall() or not holding_against:
				set_state(State.CAINDO)
				return
			return 

		if input.glide_held and velocity.y >= 0.0: set_state(State.GLIDANDO)
		else: set_state(State.PULANDO if velocity.y < 0.0 else State.CAINDO)
		return

	if input.down_held:
		set_state(State.AGACHADO)
		return
	if input.up_held and input.axis == 0 and absf(velocity.x) <= 0.1:
		set_state(State.OLHANDO_CIMA)
		return
	if absf(velocity.x) > 0.1: set_state(State.ANDANDO)
	else: set_state(State.IDLE)

func _should_slide(input: PlayerInput.Snapshot) -> bool:
	if not is_on_floor() or not input.down_held: return false
	return absf(get_floor_angle()) > stats.slope_threshold

# -----------------------------------------------------------------------------
# FÍSICA E COMPORTAMENTO
# -----------------------------------------------------------------------------
func _apply_walk(dt_ticks: float, input: PlayerInput.Snapshot) -> void:
	if _wall_jump_lock_left > 0.0:
		_apply_friction(dt_ticks, 0.02)
		return
	var cap := _current_speed_cap(input)
	var current_friction = _get_friction_to_apply()
	if input.axis != 0:
		velocity.x += stats.acceleration * float(input.axis) * dt_ticks
		velocity.x = clampf(velocity.x, -cap, cap)
	else: _apply_friction(dt_ticks, current_friction)

# --- AJUSTE 2: Agachado sem movimento, mas com inércia (gelo) ---
func _apply_crouch(dt_ticks: float, _input: PlayerInput.Snapshot) -> void:
	# Não aplicamos aceleração (não pode andar)
	# Aplicamos fricção dinâmica:
	# Se for gelo -> fricção baixa -> desliza longe
	# Se for chão -> fricção alta -> para rápido
	var f = _get_friction_to_apply()
	_apply_friction(dt_ticks, f)

func _apply_look_up(dt_ticks: float) -> void: _apply_friction(dt_ticks, stats.friction)
func _apply_inertia(dt_ticks: float) -> void:
	var friction := stats.friction
	if not is_on_floor(): friction *= stats.air_friction_multiplier
	_apply_friction(dt_ticks, friction)

func _apply_friction(dt_ticks: float, friction_factor: float) -> void:
	var t := _lerp_factor_per_ticks(friction_factor, dt_ticks)
	velocity.x = lerpf(velocity.x, 0.0, t)
	if absf(velocity.x) < stats.stop_threshold: velocity.x = 0.0

func _lerp_factor_per_ticks(base_t: float, ticks: float) -> float:
	return 1.0 - pow(1.0 - clampf(base_t, 0.0, 1.0), maxf(0.0, ticks))

func _apply_slide(dt_ticks: float, input: PlayerInput.Snapshot) -> void:
	if not _should_slide(input):
		_slide_speed = stats.slide_speed_start
		return
	_slide_speed = minf(_slide_speed + stats.slide_acceleration * dt_ticks, stats.max_slide_speed)
	_slope_direction = int(signf(get_floor_normal().x))
	if _slope_direction == 0: _slope_direction = 1
	velocity.x = _slide_speed * float(_slope_direction) * stats.gravity
	if anim_sprite != null: anim_sprite.flip_h = _slope_direction < 0

func _apply_wall_slide(dt_ticks: float, input: PlayerInput.Snapshot) -> void:
	var grav_reduced := stats.gravity / stats.wall_slide_gravity_divisor
	velocity.y += grav_reduced * dt_ticks
	velocity.y = minf(velocity.y, stats.max_wall_slide_speed)
	
	# FORCE PUSH contra a parede
	var w_normal = get_wall_normal().x
	if w_normal == 0:
		w_normal = -input.axis if input.axis != 0 else -_facing
	velocity.x = -w_normal * 10.0

func _apply_ground_pound(dt_ticks: float) -> void:
	velocity.x = lerpf(velocity.x, 0.0, 0.25)
	velocity.y += (stats.gravity * stats.ground_pound_gravity_multiplier) * dt_ticks
	velocity.y = minf(velocity.y, stats.ground_pound_max_speed)

func _apply_land_lock(dt_ticks: float, input: PlayerInput.Snapshot) -> void:
	_apply_friction(dt_ticks, stats.friction)
	if _gp_land_left <= 0.0:
		if input.axis != 0 or input.jump_buffered or input.attack_pressed or not input.down_held:
			set_state(State.IDLE)

func _apply_cartwheel(dt_ticks: float) -> void:
	var base_max := stats.attack_base_max_speed
	var start_speed := stats.attack_start_speed
	var moving_same_dir: bool = (int(sign(velocity.x)) == _attack_dir)
	
	if absf(velocity.x) > base_max and moving_same_dir:
		var t_fric = _lerp_factor_per_ticks(stats.attack_overspeed_friction, dt_ticks)
		velocity.x = lerpf(velocity.x, base_max * float(_attack_dir), t_fric)
	else:
		var target := start_speed * float(_attack_dir)
		var t_accel = _lerp_factor_per_ticks(0.18, dt_ticks)
		velocity.x = lerpf(velocity.x, target, t_accel)

func _end_cartwheel() -> void:
	_set_attack_hitbox_enabled(false)
	set_state(State.ANDANDO if absf(velocity.x) > 0.1 else State.IDLE if is_on_floor() else State.CAINDO)

func _set_attack_hitbox_enabled(enabled: bool) -> void:
	if attack_hitbox: attack_hitbox.monitoring = enabled

func _apply_jump_logic_cartwheel_aware() -> void:
	if state in [State.MACHUCADO, State.MORTO, State.GROUND_POUND, State.GROUND_POUND_LAND]: return
	if not player_input.peek_jump(): return

	if state == State.WALL_SLIDE:
		player_input.consume_jump()
		var w_normal_x = get_wall_normal().x
		if w_normal_x == 0: w_normal_x = -_facing
		velocity.y = stats.wall_jump_y
		velocity.x = stats.wall_jump_x * w_normal_x
		_wall_jump_lock_left = stats.wall_jump_lock_seconds
		_facing = int(sign(velocity.x))
		if anim_sprite: anim_sprite.flip_h = _facing < 0
		_cartwheel_air_jump_charges = 1
		set_state(State.PULANDO)
		return

	if is_on_floor() or coyote_jump_timer.time_left > 0.0:
		player_input.consume_jump()
		_jump_now()
	elif state == State.CARTWHEEL and _cartwheel_air_jump_charges > 0:
		player_input.consume_jump()
		_cartwheel_air_jump_charges -= 1
		_jump_now()

func _jump_now() -> void:
	var mult := stats.run_jump_multiplier if _is_running else 1.0
	velocity.y = stats.jump_speed * mult
	set_state(State.PULANDO)

func _apply_gravity(dt_ticks: float) -> void:
	if is_on_floor() or state == State.WALL_SLIDE: return 
	if state == State.GLIDANDO:
		velocity.y += (stats.gravity / stats.glide_gravity_divisor) * dt_ticks
		velocity.y = minf(velocity.y, stats.max_glide_fall_speed)
	else:
		velocity.y += stats.gravity * dt_ticks
		velocity.y = minf(velocity.y, stats.max_fall_speed)

func _apply_glide_open_pop() -> void:
	if is_on_floor() or velocity.y <= 0.0: return
	velocity.y = maxf(velocity.y - stats.glide_open_brake, -stats.glide_open_upward_cap)

func _post_move() -> void:
	if is_on_wall() and state != State.WALL_SLIDE: velocity.x = 0.0
	if is_on_ceiling(): velocity.y = maxf(velocity.y, 0.0)
	if is_on_floor() and state != State.DESLIZANDO: velocity.y = 0.0

	var now_on_floor := is_on_floor()
	if _was_on_floor and not now_on_floor and velocity.y >= 0.0 and state != State.PULANDO:
		coyote_jump_timer.start()
	if now_on_floor and not _was_on_floor: coyote_jump_timer.stop()
	if now_on_floor and not _was_on_floor and state == State.GROUND_POUND: set_state(State.GROUND_POUND_LAND)
	if (not now_on_floor) and _was_on_floor and state == State.CARTWHEEL: _cartwheel_air_jump_charges = max(_cartwheel_air_jump_charges, 1)
	_was_on_floor = now_on_floor

func _on_attack_body_entered(body: Node) -> void: _handle_attack_hit(body)
func _on_attack_area_entered(area: Area2D) -> void: _handle_attack_hit(area)

func _handle_attack_hit(target: Node) -> void:
	if state != State.CARTWHEEL or target == self: return
	var did_something := false
	if target.has_method("take_damage"):
		target.call("take_damage", 1, _attack_dir)
		did_something = true
	elif target.has_method("die"):
		target.call("die")
		did_something = true

	if did_something:
		_attack_left = maxf(_attack_left, stats.attack_extend_seconds_on_hit)
		velocity.x += stats.attack_speed_boost_add * float(_attack_dir)
		_cartwheel_air_jump_charges = 1 

func take_damage(amount: int, from_dir: int) -> void:
	if state == State.MORTO or _invuln_left > 0.0: return
	Global.session.battery -= amount 
	if Global.session.battery <= 0:
		_die()
		return
	_invuln_left = stats.invuln_seconds
	_hurt_left = stats.hurt_lock_seconds
	set_state(State.MACHUCADO)
	var dir := clampi(from_dir, -1, 1)
	if dir == 0: dir = -_facing
	velocity.x = stats.knockback_x * float(dir)
	velocity.y = stats.knockback_y

func heal(amount: int) -> void:
	Global.session.battery = clampi(Global.session.battery + amount, 0, Global.session.max_battery)

func _die() -> void:
	is_alive = false
	set_state(State.MORTO)
	velocity = Vector2.ZERO
	_set_attack_hitbox_enabled(false)

func _play_animations() -> void:
	if anim_sprite == null: return
	if state == State.MORTO: _play_anim("death")
	elif state == State.MACHUCADO: _play_anim("hurt")
	elif state == State.CARTWHEEL: _play_anim("attack")
	elif state in [State.GROUND_POUND, State.GROUND_POUND_LAND]: _play_anim("ground_pound")
	elif state == State.WALL_SLIDE: _play_anim("wall_slide")
	elif is_on_floor():
		if state == State.DESLIZANDO and absf(get_floor_angle()) > stats.slope_threshold: _play_anim("slope_slide")
		elif state == State.AGACHADO: _play_anim("crouch")
		elif state == State.OLHANDO_CIMA: _play_anim("look_up")
		elif absf(velocity.x) > 0.1: _play_anim("run" if _is_running else "walk")
		else: _play_anim("idle")
	elif state == State.GLIDANDO: _play_anim("glide")
	else:
		if velocity.y < 0.0: _play_anim("wall_jump" if _wall_jump_lock_left > 0.0 else "jump_up")
		else: _play_anim("jump_down")

func _play_anim(anim_name: String) -> void:
	var anim_id := StringName(anim_name)
	if anim_sprite.animation == anim_id and anim_sprite.is_playing(): return
	if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_id):
		anim_sprite.play(anim_id)

# --- HELPERS ---
func _get_friction_to_apply() -> float:
	if is_on_floor() and _is_floor_ice():
		return stats.friction * 0.15 
	return stats.friction

func _is_floor_ice() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y < -0.5:
			var collider = col.get_collider()
			if collider is TileMapLayer:
				var coords = collider.local_to_map(collider.to_local(col.get_position() - col.get_normal()))
				var data = collider.get_cell_tile_data(coords)
				if data and data.get_custom_data("is_ice"):
					return true
	return false

func _is_touching_world_wall() -> bool:
	if not is_on_wall(): return false
	
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		# Normal horizontal = parede
		if absf(col.get_normal().x) > 0.5:
			var collider = col.get_collider()
			
			# 1. Se for TileMapLayer, aceita direto (assumindo que terreno é world)
			if collider is TileMapLayer:
				return true
				
			# 2. Se for TileMap legado
			if collider is TileMap:
				return true
			
			# 3. Se for objeto com layer
			if collider and "collision_layer" in collider:
				if (collider.collision_layer & PhysicsLayers.bit(PhysicsLayers.WORLD)) != 0:
					return true
	return false
