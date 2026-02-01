# res://game/player/player_input.gd
extends Node
class_name PlayerInput

@export var action_left: StringName = &"left"
@export var action_right: StringName = &"right"
@export var action_run: StringName = &"run"
@export var action_up: StringName = &"up" 
@export var action_down: StringName = &"down"
@export var action_glide: StringName = &"ui_rs"
@export var action_jump: StringName = &"jump"
@export var action_attack: StringName = &"attack"

class Snapshot:
	var axis: int = 0
	var run_held: bool = false
	var up_held: bool = false
	var down_held: bool = false
	var down_pressed: bool = false
	var glide_held: bool = false
	var jump_released: bool = false
	var jump_buffered: bool = false
	var attack_pressed: bool = false

var snapshot := Snapshot.new()

var _jump_buffer_ticks_max: int = 0
var _jump_buffer_ticks_left: int = 0

func configure_from_stats(stats: PlayerStats) -> void:
	set_jump_buffer_seconds(stats.jump_buffer_seconds)

func set_jump_buffer_seconds(seconds: float) -> void:
	_jump_buffer_ticks_max = int(ceil(maxf(0.0, seconds) * float(Engine.physics_ticks_per_second)))
	_jump_buffer_ticks_left = 0

func poll() -> void:
	var a := Input.get_axis(action_left, action_right)
	snapshot.axis = int(signf(a))

	snapshot.run_held = Input.is_action_pressed(action_run)
	snapshot.up_held = Input.is_action_pressed(action_up)
	snapshot.down_held = Input.is_action_pressed(action_down)
	snapshot.down_pressed = Input.is_action_just_pressed(action_down)

	snapshot.glide_held = Input.is_action_pressed(action_glide)
	snapshot.attack_pressed = Input.is_action_just_pressed(action_attack)
	snapshot.jump_released = Input.is_action_just_released(action_jump)

	var pressed := Input.is_action_just_pressed(action_jump)
	if pressed:
		_jump_buffer_ticks_left = 1 if _jump_buffer_ticks_max <= 0 else _jump_buffer_ticks_max
	elif _jump_buffer_ticks_left > 0:
		_jump_buffer_ticks_left -= 1

	snapshot.jump_buffered = _jump_buffer_ticks_left > 0

func peek_jump() -> bool:
	return snapshot.jump_buffered

func consume_jump() -> bool:
	if _jump_buffer_ticks_left <= 0:
		return false
	_jump_buffer_ticks_left = 0
	snapshot.jump_buffered = false
	return true
