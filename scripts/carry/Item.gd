extends RigidBody2D
class_name Item

@export var weight: float = 1.0
@export var can_be_picked: bool = true
@export var use_gravity: bool = false         # top-down: keep off
@export var default_linear_damp: float = 8.0  # slows horizontal drift
@export var default_angular_damp: float = 5.0
@export var carried_z: int = 1000             # draw on top while carried

var _carrier: Node2D = null
var _orig_parent: Node = null
var _old_layer: int = 0
var _old_mask: int = 0
var _old_freeze: bool = false
var _old_freeze_mode: int = RigidBody2D.FREEZE_MODE_KINEMATIC
var _old_z: int = 0

func _ready() -> void:
	set_physics_process(true)
	if not is_in_group("item"):
		add_to_group("item")
	if not use_gravity:
		gravity_scale = 0.0
	linear_damp = default_linear_damp
	angular_damp = default_angular_damp

func _physics_process(_delta: float) -> void:
	if _carrier != null:
		var cp := _carrier as Node2D
		if cp:
			global_position = cp.global_position
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0

func is_carried() -> bool:
	return _carrier != null

func pickup(carry_point: Node) -> bool:
	if not can_be_picked or _carrier != null or carry_point == null:
		return false
	var cp := carry_point as Node2D
	if cp == null:
		return false

	# Save state
	_orig_parent = get_parent()
	_old_layer = collision_layer
	_old_mask = collision_mask
	_old_freeze = freeze
	_old_freeze_mode = freeze_mode
	_old_z = z_index

	# Disable physics/collisions while carried; draw on top
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0
	z_index = carried_z
	visible = true

	# Reparent to carry point, snap to it
	cp.add_child(self)
	global_position = cp.global_position
	rotation = 0.0

	_carrier = cp
	return true

func drop(world_parent: Node = null) -> bool:
	if _carrier == null:
		return false
	if world_parent == null:
		world_parent = _orig_parent if _orig_parent != null else get_tree().current_scene

	var gp: Vector2 = global_position
	world_parent.add_child(self)
	global_position = gp

	# Restore physics/collisions/z
	freeze_mode = _old_freeze_mode
	freeze = _old_freeze
	collision_layer = _old_layer
	collision_mask = _old_mask
	z_index = _old_z

	_carrier = null
	return true

func throw(dir: Vector2, force: float, world_parent: Node = null) -> bool:
	if _carrier == null:
		return false
	var ok := drop(world_parent)
	if not ok:
		return false
	var d: Vector2 = dir.normalized()
	var mag: float = max(50.0, force * max(0.3, 1.0 / max(0.1, weight)))
	var impulse: Vector2 = d * mag
	apply_impulse(impulse)
	return true

func throw_with_velocity(dir: Vector2, force: float, base_velocity: Vector2, world_parent: Node = null) -> bool:
	if _carrier == null:
		return false

	# Drop to world first
	var ok := drop(world_parent)
	if not ok:
		return false

	# Nudge forward a bit so it doesn't collide with the player on the same frame
	var d: Vector2 = dir.normalized()
	global_position += d * 6.0

	# Inherit player's velocity so it doesn't look like a drop while running
	linear_velocity = base_velocity

	# Apply throw impulse
	var mag: float = max(50.0, force * max(0.3, 1.0 / max(0.1, weight)))
	var impulse: Vector2 = d * mag
	apply_impulse(impulse)
	return true
