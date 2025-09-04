extends Node
class_name PlayerMovement
# PlayerMovement.gd - Movement/physics smoothing for CharacterBody2D

@export var config: MovementConfig

func _ready() -> void:
	if config == null:
		config = preload("res://scripts/player/MovementConfig.gd").new()

func compute_target_speed(sprinting: bool, carrying: bool, stats: PlayerStats) -> float:
	var base: float = config.base_move_speed
	if sprinting and stats and stats.sprint_enabled:
		base *= config.sprint_multiplier
	if carrying and stats:
		base *= stats.carry_speed_multiplier
	return base

func update_velocity(current: Vector2, delta: float, direction: Vector2, target_speed: float) -> Vector2:
	# Normalize direction for consistent speed
	var dir: Vector2 = direction.normalized()
	var desired: Vector2 = dir * target_speed

	# Accel/decel per axis for responsive feel
	var out: Vector2 = current
	var accel := config.acceleration
	var decel := config.deceleration

	# X
	var dx := desired.x - current.x
	if abs(dx) > 0.001:
		var ax := (accel if sign(dx) == sign(desired.x) else decel) * delta
		out.x = move_toward(current.x, desired.x, ax)
	# Y
	var dy := desired.y - current.y
	if abs(dy) > 0.001:
		var ay := (accel if sign(dy) == sign(desired.y) else decel) * delta
		out.y = move_toward(current.y, desired.y, ay)

	# Optional friction when no input
	if direction == Vector2.ZERO and config.friction > 0.0:
		out = out.move_toward(Vector2.ZERO, config.friction * delta)

	return out
