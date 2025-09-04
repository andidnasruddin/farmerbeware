extends Resource
class_name MovementConfig
# MovementConfig.gd - Movement/physics tuning for CharacterBody2D

# ============================================================================
# PROPERTIES
# ============================================================================
@export var base_move_speed: float = 300.0
@export var sprint_multiplier: float = 1.5

# Acceleration/deceleration for smoothing
@export var acceleration: float = 2000.0
@export var deceleration: float = 2500.0

# Optional friction (use 0 for velocity-driven control)
@export var friction: float = 0.0

# Input handling
@export var deadzone: float = 0.2
@export var snap_to_cardinal: bool = false
