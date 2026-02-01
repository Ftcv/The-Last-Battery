extends Camera2D

# Look-ahead horizontal (reduzido)
@export var look_ahead_x_max: float = 36.0
@export var look_ahead_x_lerp_speed: float = 5.0

# Vertical (reduzido)
@export var base_y_bias: float = 6.0
@export var look_up_y: float = -6.0
@export var look_down_y: float = 14.0
@export var vertical_lerp_speed: float = 4.0
@export var vel_y_threshold: float = 60.0

# Sensibilidade: não mover offset em baixa velocidade (anti “micro jitter”)
@export var min_speed_for_lookahead: float = 60.0

# --- NOVO: Peek (look up / look down por hold) ---
@export var peek_hold_delay: float = 0.30       # tempo segurando antes de começar a mover a câmera
@export var peek_ramp_seconds: float = 0.35     # tempo para chegar no máximo
@export var peek_return_speed: float = 3.0      # quão rápido volta ao normal

@export var peek_up_extra_y: float = -22.0      # negativo sobe a câmera
@export var peek_down_extra_y: float = 26.0     # positivo desce a câmera

@export var peek_requires_still: bool = true    # evita peek up/down enquanto anda
@export var still_speed_threshold: float = 6.0  # tolerância de "parado"

var _facing_sign: int = 1

# --- NOVO: acumuladores de hold ---
var _peek_up_hold: float = 0.0
var _peek_down_hold: float = 0.0

func _ready() -> void:
	make_current()

func _physics_process(delta: float) -> void:
	var player := get_parent() as CharacterBody2D
	if player == null:
		return


	var input_node := player.get_node_or_null("PlayerInput") as PlayerInput
	if input_node == null:
		return # Sem input, não tenta adivinhar via InputMap aqui (regra do projeto).

	var snap := input_node.snapshot
	var up_held: bool = snap.up_held
	var down_held: bool = snap.down_held
	var axis: int = snap.axis


	if abs(player.velocity.x) > 1.0:
		_facing_sign = 1 if player.velocity.x >= 0.0 else -1

	# --- speed01 mais “calmo” e com zona morta ---
	var speed_x: float = abs(player.velocity.x)
	var max_for_scale: float = 260.0 # aumenta pra reduzir sensibilidade

	var t: float = 0.0
	if speed_x > min_speed_for_lookahead:
		t = clamp((speed_x - min_speed_for_lookahead) / (max_for_scale - min_speed_for_lookahead), 0.0, 1.0)

	# Smoothstep (reduz “nervosismo” perto do zero)
	var speed01: float = t * t * (3.0 - 2.0 * t)

	var target_x: float = float(_facing_sign) * look_ahead_x_max * speed01

	var target_y: float = base_y_bias
	if player.velocity.y < -vel_y_threshold:
		target_y += look_up_y
	elif player.velocity.y > vel_y_threshold:
		target_y += look_down_y

	# --- NOVO: Peek vertical (somado ao target_y) ---
	var can_peek: bool = player.is_on_floor()

	if peek_requires_still:
		# "parado" = eixo neutro e velocidade baixa
		if axis != 0 or abs(player.velocity.x) > still_speed_threshold:
			can_peek = false

	# Se o Player tiver métodos, usamos (melhor). Se não, fallback no input.
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

	var new_offset := offset
	new_offset.x = lerp(new_offset.x, target_x, clamp(delta * look_ahead_x_lerp_speed, 0.0, 1.0))
	new_offset.y = lerp(new_offset.y, target_y, clamp(delta * vertical_lerp_speed, 0.0, 1.0))
	offset = new_offset

# --- NOVO: helpers do peek ---
func _update_hold(current: float, delta: float, held: bool) -> float:
	if held:
		return min(current + delta, peek_hold_delay + peek_ramp_seconds)
	return max(current - (delta * peek_return_speed), 0.0)

func _hold_to_factor(hold: float) -> float:
	if hold <= peek_hold_delay:
		return 0.0
	var t: float = (hold - peek_hold_delay) / max(0.001, peek_ramp_seconds)
	return clamp(t, 0.0, 1.0)
