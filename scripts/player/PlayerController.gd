extends CharacterBody2D
class_name PlayerController
# PlayerController.gd - Core player controller (states, stamina, tools)

# ============================================================================
# ENUMS
# ============================================================================
enum PlayerState { IDLE, MOVING, SPRINTING, CARRYING, USING_TOOL, IN_MINIGAME, THROWING }

# ============================================================================
# SIGNALS
# ============================================================================
signal tool_changed(tool_name: String)
signal item_picked_up(item)
signal action_performed(action: String, grid_pos: Vector2i)

# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================
@export var player_id: int = 0
@export var player_name: String = "Player"
@export var stats: PlayerStats
@export var movement_config: MovementConfig
@export var current_tool: String = "hoe"

# ============================================================================
# RUNTIME
# ============================================================================
var state: PlayerState = PlayerState.IDLE
var carried_item = null
var facing_direction: Vector2 = Vector2.DOWN
var stamina: float = 100.0

# Nodes
var movement: PlayerMovement = null
var inventory: PlayerInventory = null

# Input flags
var input_enabled: bool = true

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready() -> void:
	if stats == null:
		stats = preload("res://scripts/player/PlayerStats.gd").new()
	if movement_config == null:
		movement_config = preload("res://scripts/player/MovementConfig.gd").new()

	# Child movement node
	if not has_node("Movement"):
		var mv: PlayerMovement = PlayerMovement.new()
		mv.name = "Movement"
		add_child(mv)
		movement = mv
	else:
		movement = $Movement as PlayerMovement

	if movement and movement.config == null:
		movement.config = movement_config

	stamina = stats.stamina_max
	set_physics_process(true)

	# Child inventory node
	if has_node("Inventory"):
		inventory = $Inventory as PlayerInventory
	else:
		var inv: PlayerInventory = PlayerInventory.new()
		inv.name = "Inventory"
		add_child(inv)
		inventory = inv

	# Sync initial stamina/tools
	if inventory:
		inventory.current_tool_changed.connect(_on_inventory_tool_changed)
		var t: Tool = inventory.get_current_tool()
		if t:
			current_tool = t.id
			tool_changed.emit(current_tool)

func _unhandled_input(event: InputEvent) -> void:
	# Hotkeys for tools 1–7 (simple name mapping; Tool system arrives later)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: if inventory: inventory.select_hotkey(1)
			KEY_2: if inventory: inventory.select_hotkey(2)
			KEY_3: if inventory: inventory.select_hotkey(3)
			KEY_4: if inventory: inventory.select_hotkey(4)
			KEY_5: if inventory: inventory.select_hotkey(5)
			KEY_6: if inventory: inventory.select_hotkey(6)
			KEY_7: if inventory: inventory.select_hotkey(7)
	# Trigger tool action with E/Space
	if event.is_action_pressed("action_primary"):
		_attempt_primary_action()

func _physics_process(delta: float) -> void:
	if not input_enabled:
		_update_idle_state()
		return

	var move_dir := _get_move_input()
	var sprinting := Input.is_action_pressed("sprint") and _can_sprint()
	var carrying := carried_item != null

	# Speed target
	var target_speed := movement.compute_target_speed(sprinting, carrying, stats)
	velocity = movement.update_velocity(velocity, delta, move_dir, target_speed)

	# Facing for visuals
	if move_dir != Vector2.ZERO:
		facing_direction = move_dir.normalized()

	# Stamina
	_update_stamina(delta, sprinting)

	# State
	_update_state(move_dir, sprinting, carrying)

	# Physics
	move_and_slide()

func _attempt_primary_action() -> void:
	# Determine origin tile (in front of player), then call InteractionSystem
	var gv: Node = GridValidator
	var origin: Vector2i = Vector2i.ZERO
	if gv and gv.has_method("world_to_grid"):
		origin = gv.world_to_grid(global_position)
	
	# Convert facing_direction (Vector2) to Vector2i (default right if zero)
	var fx: int
	if facing_direction.x > 0.1:
		fx = 1
	elif facing_direction.x < -0.1:
		fx = -1
	else:
		fx = 0
	
	var fy: int
	if facing_direction.y > 0.1:
		fy = 1
	elif facing_direction.y < -0.1:
		fy = -1
	else:
		fy = 0
	
	var facing_vi: Vector2i = Vector2i(fx, fy)
	if facing_vi == Vector2i.ZERO:
		facing_vi = Vector2i(1, 0)
	
	# Act on the tile in front for intuitive tools
	var target: Vector2i = origin + facing_vi
	
	# Use current tool from inventory/controller
	var tool_name: String = current_tool
	if tool_name.is_empty():
		return
	
	if InteractionSystem and InteractionSystem.has_method("request_primary_action"):
		InteractionSystem.request_primary_action(tool_name, target, player_id, facing_vi)

# ============================================================================
# INPUT HELPERS
# ============================================================================
func _get_move_input() -> Vector2:
	var x := 0.0
	var y := 0.0
	if Input.is_action_pressed("move_left"): x -= 1.0
	if Input.is_action_pressed("move_right"): x += 1.0
	if Input.is_action_pressed("move_up"): y -= 1.0
	if Input.is_action_pressed("move_down"): y += 1.0
	var v := Vector2(x, y)
	if movement_config.snap_to_cardinal and v != Vector2.ZERO:
		# Snap to 4-dir
		if abs(v.x) > abs(v.y): v = Vector2(sign(v.x), 0)
		else: v = Vector2(0, sign(v.y))
	return v if v.length() >= movement_config.deadzone else Vector2.ZERO

# ============================================================================
# STAMINA
# ============================================================================
func _can_sprint() -> bool:
	return stats.sprint_enabled and stamina > 0.0

func _update_stamina(delta: float, sprinting: bool) -> void:
	if sprinting:
		stamina -= stats.sprint_stamina_cost_per_sec * delta
	else:
		stamina += stats.stamina_recovery_per_sec * delta
	stamina = clamp(stamina, 0.0, stats.stamina_max)

# ============================================================================
# STATE
# ============================================================================
func _update_state(move_dir: Vector2, sprinting: bool, carrying: bool) -> void:
	if carrying:
		state = PlayerState.CARRYING
	elif sprinting and move_dir != Vector2.ZERO:
		state = PlayerState.SPRINTING
	elif move_dir != Vector2.ZERO:
		state = PlayerState.MOVING
	else:
		_update_idle_state()

func _update_idle_state() -> void:
	state = PlayerState.IDLE
	velocity = velocity.move_toward(Vector2.ZERO, movement_config.deceleration * get_physics_process_delta_time())

# ============================================================================
# TOOLS
# ============================================================================
func _set_tool(name: String) -> void:
	if current_tool == name:
		return
	current_tool = name
	tool_changed.emit(current_tool)

func _on_inventory_tool_changed(tool: Tool, _index: int) -> void:
	current_tool = tool.id if tool else ""
	tool_changed.emit(current_tool)
	print("[Player] Tool changed to: ", current_tool)

# ============================================================================
# EXTERNAL CONTROL
# ============================================================================
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
