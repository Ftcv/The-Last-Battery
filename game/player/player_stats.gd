# res://game/player/player_stats.gd
extends Resource
class_name PlayerStats

@export_group("Snap")
@export var floor_snap_length: float = 8.0

@export_group("Movimento - chão")
@export var max_walk_speed: float = 200.0
@export var max_run_speed: float = 300.0
@export var acceleration: float = 50.0
@export var friction: float = 0.18
@export var stop_threshold: float = 1.0

@export_group("Movimento - ar (controle)")
@export var air_accel_multiplier: float = 0.85
@export var air_friction_multiplier: float = 1.0
@export var run_air_speed_bonus: float = 35.0

@export_group("Pulo / Gravidade")
@export var jump_speed: float = -225.0
@export var run_jump_multiplier: float = 1.25
@export var jump_cut_multiplier: float = 0.5
@export var gravity: float = 8.0
@export var max_fall_speed: float = 300.0

@export_group("Glide")
@export var glide_gravity_divisor: float = 4.0
@export var max_glide_fall_speed: float = 100.0
@export var glide_open_brake: float = 40.0
@export var glide_open_upward_cap: float = 0.0

@export_group("Coyote / Buffer")
@export var coyote_seconds: float = 0.12
@export var jump_buffer_seconds: float = 0.0

@export_group("Slide (ladeira)")
@export var slide_speed_start: float = 5.0
@export var max_slide_speed: float = 50.0
@export var slide_acceleration: float = 0.5
@export var slope_threshold: float = 0.2 # rad

@export_group("Crouch")
@export var crouch_speed_cap: float = 120.0

@export_group("Ground Pound")
@export var ground_pound_start_speed: float = 250.0
@export var ground_pound_max_speed: float = 520.0
@export var ground_pound_gravity_multiplier: float = 2.0
@export var ground_pound_land_seconds: float = 0.16

@export_group("Wall Action")
@export var max_wall_slide_speed: float = 120.0
@export var wall_slide_gravity_divisor: float = 2.5
@export var wall_jump_y: float = -240.0
@export var wall_jump_x: float = 220.0
@export var wall_jump_lock_seconds: float = 0.10

@export_group("Cartwheel / Attack")
@export var attack_initial_boost: float = 30.0 
@export var attack_min_speed: float = 180.0 
@export var attack_base_max_speed: float = 320.0 
@export var attack_seconds: float = 0.40 # Base timer

# Configurações de input sustentado (aceleração manual)
@export var attack_hold_acceleration: float = 10.0 
@export var attack_friction: float = 0.04 
@export var attack_overspeed_friction: float = 0.01 
@export var attack_allow_start_still: bool = true

@export_group("DKC SNES Physics")
# 0x0040 no SNES ~ 0.25px/frame acumulativo.
# No Godot, um valor de 60.0 somado diretamente à velocity.x dá o "pop" correto.
@export var attack_hit_boost: float = 60.0 

# O SNES reseta o timer para 24 frames (~0.4s) a cada hit.
@export var attack_hit_extend_seconds: float = 0.4 

# Hitbox extra (pixel perfect): Estende o colisor fisicamente para frente.
@export var attack_hitbox_extend_x: float = 10.0 

# Bounce fixo (0x0600) para o Jump-Kill
@export var enemy_bounce_velocity: float = -350.0 

@export_group("HP / Dano")
@export var max_hp: int = 3
@export var invuln_seconds: float = 0.60
@export var hurt_lock_seconds: float = 0.25
@export var knockback_x: float = 220.0
@export var knockback_y: float = -170.0
