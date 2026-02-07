extends Camera2D

# --- CONFIGURAÇÃO LEAD ROOM (OLHAR ADIANTE) ---
# Aumentamos drasticamente este valor para atingir o efeito de 2/3 da tela.
# Se sua resolução for 640px de largura, 1/3 é aprox 213px. O centro é 320.
# O offset necessário seria ~100px. Ajuste conforme sua resolução.
@export var look_ahead_x_max: float = 100.0 

# Reduzimos a velocidade do Lerp para ser "discreto e devagar".
# Valores entre 1.0 e 3.0 evitam tontura. O anterior (5.0) era muito rápido.
@export var look_ahead_x_lerp_speed: float = 1.5

# Zona morta para evitar que a câmera trema se o player se mover 1 pixel.
@export var ignore_small_movements: float = 10.0

# --- CONFIGURAÇÃO VERTICAL (Mantida do original, levemente ajustada) ---
@export var base_y_bias: float = 6.0
@export var look_up_y: float = -40.0 # Aumentado para ver mais acima
@export var look_down_y: float = 40.0 # Aumentado para ver mais abaixo
@export var vertical_lerp_speed: float = 2.0 # Mais suave verticalmente também
@export var vel_y_threshold: float = 180.0 # Só move vertical se cair rápido

# --- CONFIGURAÇÃO PEEK (Olhadinha) ---
@export var peek_hold_delay: float = 0.30
@export var peek_ramp_seconds: float = 0.8 # Mais lento para ser suave
@export var peek_return_speed: float = 2.0
@export var peek_up_extra_y: float = -60.0
@export var peek_down_extra_y: float = 60.0
@export var peek_requires_still: bool = true
@export var still_speed_threshold: float = 6.0

# Variáveis internas
var _target_offset_x: float = 0.0
var _peek_up_hold: float = 0.0
var _peek_down_hold: float = 0.0

func _ready() -> void:
	make_current()
	# Inicia o offset x no zero
	_target_offset_x = 0.0

func _physics_process(delta: float) -> void:
	var player := get_parent() as CharacterBody2D
	if player == null:
		return

	# Obtemos input para o Peek, mas usamos velocity para o Lead Room (mais seguro)
	var input_node := player.get_node_or_null("PlayerInput") as PlayerInput
	var up_held := false
	var down_held := false
	var axis := 0
	
	if input_node:
		var snap := input_node.snapshot
		up_held = snap.up_held
		down_held = snap.down_held
		axis = snap.axis

	# -------------------------------------------------------------------------
	# LÓGICA HORIZONTAL (LEAD ROOM / LOOK AHEAD)
	# -------------------------------------------------------------------------
	var v_x: float = player.velocity.x
	
	# Só mudamos o alvo da câmera se o jogador estiver se movendo significativamente.
	# Isso cria uma histerese (zona morta) que evita que a câmera balance se o player
	# der apenas um toquinho no controle.
	if absf(v_x) > ignore_small_movements:
		var direction_sign: int = 1 if v_x > 0 else -1
		_target_offset_x = float(direction_sign) * look_ahead_x_max
	
	# O segredo da suavidade: Lerp independente da velocidade do player.
	# A câmera "tenta" chegar no alvo com uma velocidade constante (lerp_speed),
	# criando aquele efeito cinematográfico de atraso/avanço.
	var new_offset_x: float = lerp(offset.x, _target_offset_x, delta * look_ahead_x_lerp_speed)

	# -------------------------------------------------------------------------
	# LÓGICA VERTICAL (DINÂMICA + PEEK)
	# -------------------------------------------------------------------------
	var target_y: float = base_y_bias
	
	# Olha para baixo se cair muito rápido (ajuda em poços)
	if player.velocity.y > vel_y_threshold:
		target_y += look_down_y
	elif player.velocity.y < -vel_y_threshold:
		# Opcional: olhar pra cima se subir muito rápido (ex: mola)
		# Geralmente em plataforma 2D preferimos ver o chão, então isso é sutil.
		target_y += look_up_y

	# --- Lógica de Peek (Olhadinha Estática) ---
	var can_peek: bool = player.is_on_floor()
	if peek_requires_still:
		if axis != 0 or absf(v_x) > still_speed_threshold:
			can_peek = false

	var is_crouching: bool = false
	var is_looking_up: bool = false

	if can_peek and player.has_method("is_crouching"):
		is_crouching = bool(player.call("is_crouching"))
	else:
		is_crouching = can_peek and down_held

	if can_peek and player.has_method("is_looking_up"):
		is_looking_up = bool(player.call("is_looking_up"))
	else:
		is_looking_up = can_peek and up_held and (not down_held)

	_peek_down_hold = _update_hold(_peek_down_hold, delta, is_crouching and down_held)
	_peek_up_hold = _update_hold(_peek_up_hold, delta, is_looking_up and up_held)

	var down_factor: float = _hold_to_factor(_peek_down_hold)
	var up_factor: float = _hold_to_factor(_peek_up_hold)

	target_y += (peek_down_extra_y * down_factor) + (peek_up_extra_y * up_factor)

	# Aplica suavização vertical
	var new_offset_y: float = lerp(offset.y, target_y, delta * vertical_lerp_speed)

	# -------------------------------------------------------------------------
	# APLICAÇÃO FINAL
	# -------------------------------------------------------------------------
	offset = Vector2(new_offset_x, new_offset_y)

# --- HELPERS DO PEEK ---
func _update_hold(current: float, delta: float, held: bool) -> float:
	if held:
		return min(current + delta, peek_hold_delay + peek_ramp_seconds)
	return max(current - (delta * peek_return_speed), 0.0)

func _hold_to_factor(hold: float) -> float:
	if hold <= peek_hold_delay:
		return 0.0
	var t: float = (hold - peek_hold_delay) / max(0.001, peek_ramp_seconds)
	return clamp(t, 0.0, 1.0)
