extends Node
class_name CarrySystem

@export var player_path: NodePath
@export var carry_point_path: NodePath
@export var pickup_radius: float = 48.0
@export var throw_force: float = 450.0
# --- Throwing Progress Charge --- #
@export var min_throw_force: float = 150.0
@export var max_throw_force: float = 1500.0
@export var max_charge_time: float = 0.8    # seconds to reach max
@export var tap_drop_time: float = 0.08     # release sooner = drop/weak toss

var player: PlayerController = null
var carry_point: Node2D = null
var carried: Item = null
var _charging: bool = false
var _charge_time: float = 0.0

signal charge_started()
signal charge_changed(ratio: float)
signal charge_released(force: float)

# --- System --- #

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	if player_path != NodePath():
		player = get_node(player_path) as PlayerController
	if carry_point_path != NodePath():
		carry_point = get_node(carry_point_path) as Node2D
	if player == null:
		var n := get_tree().get_first_node_in_group("player")
		player = n as PlayerController
	set_process_input(true)
	print("[Carry] ready player=", player, " carry_point=", carry_point)

func _input(event: InputEvent) -> void:
	# Start charge only if we can throw something
	if event.is_action_pressed("action_throw"):
		print("[Carry] Q pressed. carried=", carried)
		if carried:
			_charging = true
			_charge_time = 0.0
			emit_signal("charge_started")
		else:
			_try_pickup()
	elif event.is_action_released("action_throw"):
		print("[Carry] Q released. charging=", _charging, " time=", _charge_time)
		if _charging:
			_finish_charge_and_throw()
			_charging = false

func _physics_process(delta: float) -> void:
	if _charging:
		_charge_time = min(_charge_time + delta, max_charge_time)
		var ratio: float = clamp(_charge_time / max_charge_time, 0.0, 1.0)
		emit_signal("charge_changed", ratio)

func _try_pickup() -> void:
	if player == null or carry_point == null:
		return
	var nearest: Item = _find_nearest_item(player.global_position, pickup_radius)
	if nearest == null:
		return
	print("[Carry] nearest=", nearest)
	if nearest.pickup(carry_point):
		carried = nearest
		print("[Carry] picked up ", carried)
		if player:
			player.carried_item = carried
		if InteractionSystem and InteractionSystem.has_method("set_carry_state"):
			InteractionSystem.set_carry_state(true)

func _do_drop() -> void:
	if carried == null:
		return
	var wp := get_tree().current_scene
	if carried.drop(wp):
		if player:
			player.carried_item = null
		carried = null
		if InteractionSystem and InteractionSystem.has_method("set_carry_state"):
			InteractionSystem.set_carry_state(false)

func _do_throw() -> void:
	if carried == null:
		return

	# Prefer movement direction; fall back to facing; final fallback: right
	var dir: Vector2 = Vector2.RIGHT
	var base_vel: Vector2 = Vector2.ZERO
	if player:
		base_vel = player.velocity
		if base_vel.length() > 20.0:
			dir = base_vel.normalized()
		else:
			var fd: Vector2 = player.facing_direction
			if fd.length() > 0.1:
				dir = fd.normalized()

	# World parent for drop
	var wp := get_tree().current_scene

	# Keep a local ref in case carried is cleared
	var it: Item = carried
	# Throw with inherited velocity
	if it.throw_with_velocity(dir, throw_force, base_vel, wp):
		if player:
			player.carried_item = null
		carried = null
		if InteractionSystem and InteractionSystem.has_method("set_carry_state"):
			InteractionSystem.set_carry_state(false)

func _finish_charge_and_throw() -> void:
	if carried == null:
		return
	# Tap → drop (or very weak toss)
	if _charge_time <= tap_drop_time:
		_do_drop()
		emit_signal("charge_released", 0.0)
		return

	# Compute direction from movement, else facing
	var dir: Vector2 = Vector2.RIGHT
	var base_vel: Vector2 = Vector2.ZERO
	if player:
		base_vel = player.velocity
		if base_vel.length() > 20.0:
			dir = base_vel.normalized()
		else:
			var fd: Vector2 = player.facing_direction
			if fd.length() > 0.1:
				dir = fd.normalized()

	var t: float = clamp(_charge_time / max_charge_time, 0.0, 1.0)
	var force: float = lerp(min_throw_force, max_throw_force, t)

	var wp := get_tree().current_scene
	var it: Item = carried
	if it.throw_with_velocity(dir, force, base_vel, wp):
		emit_signal("charge_released", force)
		if player:
			player.carried_item = null
		carried = null
		if InteractionSystem and InteractionSystem.has_method("set_carry_state"):
			InteractionSystem.set_carry_state(false)

func _find_nearest_item(origin: Vector2, radius: float) -> Item:
	var best: Item = null
	var best_d2 := radius * radius
	for n in get_tree().get_nodes_in_group("item"):
		var it := n as Item
		if it == null or it.is_carried() or not it.can_be_picked:
			continue
		var d2 := origin.distance_squared_to(it.global_position)
		if d2 <= best_d2:
			best_d2 = d2
			best = it
	return best
