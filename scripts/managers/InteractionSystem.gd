extends Node
# InteractionSystem.gd - AUTOLOAD #4
# Handles player input, validates actions, and coordinates with grid systems
# Depends on: GameManager, GridValidator, GridManager

# ============================================================================
# INTERACTION DATA STRUCTURES
# ============================================================================
class PlayerAction:
	var player_id: int = -1
	var action_type: String = ""      # "till", "water", "plant", "harvest", etc.
	var target_position: Vector2i = Vector2i.ZERO
	var tool_used: String = ""
	var additional_data: Dictionary = {}
	var timestamp: float = 0.0
	var is_valid: bool = false
	var validation_reason: String = ""

	func _init(p_id: int, action: String, pos: Vector2i, tool: String = "") -> void:
		player_id = p_id
		action_type = action
		target_position = pos
		tool_used = tool
		timestamp = Time.get_unix_time_from_system()

# ============================================================================
# SIGNALS
# ============================================================================
signal action_requested(action: PlayerAction)
signal action_validated(action: PlayerAction)
signal action_executed(action: PlayerAction, result: Dictionary)
signal action_failed(action: PlayerAction, reason: String)
signal input_mode_changed(mode: String)

# ============================================================================
# PROPERTIES
# ============================================================================
var grid_manager: Node = null
var grid_validator: Node = null

# Pipeline members
var _target_calc: TargetCalculator = null
var _action_validator: ActionValidator = null
var _action_handlers: ActionHandlers = null

# Input state
var input_enabled: bool = true
var current_input_mode: String = "farm"  # "farm", "ui", "disabled"
var selected_tool: String = "hoe"
var target_position: Vector2i = Vector2i.ZERO
var _is_carrying: bool = false

# Action queue for multiplayer coordination
var pending_actions: Array[PlayerAction] = []
var action_history: Array[PlayerAction] = []
var max_history_size: int = 100

# Input mapping
var tool_inputs: Dictionary = {
	"tool_hoe": "hoe",
	"tool_watering_can": "watering_can",
	"tool_seed_bag": "seed_bag",
	"tool_harvester": "harvester",
	"tool_fertilizer": "fertilizer",
	"tool_soil_test": "soil_test"
}

# Performance
var input_cooldown: float = 0.1  # Minimum time between actions
var last_action_time: float = 0.0

var input_queue: InteractionQueue = null
const INPUT_QUEUE_WINDOW_MS: int = 100

# Preview / player support
var _preview_node: Node = null            # GridDebugOverlay (in group "grid_preview")
var _cursor_facing: Vector2i = Vector2i(1, 0)
var _player: PlayerController = null      # first node in group "player"
var _preview_tick_accum: float = 0.0
const PREVIEW_TICK: float = 0.03    # ~33 FPS for preview
var _last_preview_facing: Vector2i = Vector2i.ZERO

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "InteractionSystem"
	print("[InteractionSystem] Initializing as Autoload #4...")
	
	set_physics_process(true)
	
	# Discover nodes as they appear
	get_tree().node_added.connect(_on_node_added)
	_player = _find_player()
	_preview_node = _find_preview_node()

	# Get references to other systems
	grid_manager = GridManager
	grid_validator = GridValidator

	if grid_manager:
		print("[InteractionSystem] GridManager connected")
	else:
		print("[InteractionSystem] WARNING: GridManager not found!")

	if grid_validator:
		print("[InteractionSystem] GridValidator connected")
	else:
		print("[InteractionSystem] WARNING: GridValidator not found!")

	# Input mapping (ensure actions exist)
	_ensure_input_map()

	# Pipeline
	_target_calc = TargetCalculator.new()
	_action_validator = ActionValidator.new()
	_action_handlers = ActionHandlers.new()

	# Queue
	input_queue = InteractionQueue.new()
	input_queue.max_size = 3
	input_queue.window_ms = INPUT_QUEUE_WINDOW_MS
	add_child(input_queue)

	# Register with GameManager
	if GameManager:
		GameManager.register_system("InteractionSystem", self)
		print("[InteractionSystem] Registered with GameManager")
		GameManager.state_changed.connect(_on_game_state_changed)

	set_process(true)
	print("[InteractionSystem] Initialization complete!")

	# Initial preview
	_update_preview()

func _find_preview_node() -> Node:
	return get_tree().get_first_node_in_group("grid_preview")

func _find_player() -> PlayerController:
	return get_tree().get_first_node_in_group("player") as PlayerController

func _on_node_added(n: Node) -> void:
	# Preview node late-load
	if _preview_node == null and n.is_in_group("grid_preview"):
		_preview_node = n
	# Player late-load
	if _player == null and n.is_in_group("player"):
		_player = n as PlayerController

func _process(_delta: float) -> void:
	if input_queue and not input_queue.is_empty():
		input_queue.drain_to(Callable(self, "_process_queued_action"))

func _physics_process(delta: float) -> void:
	_preview_tick_accum += delta
	# Update when facing changed
	if _cursor_facing != _last_preview_facing:
		_last_preview_facing = _cursor_facing
		_update_preview()
		return
	# Or update at a modest cadence so held keys feel smooth
	if _preview_tick_accum >= PREVIEW_TICK:
		_preview_tick_accum = 0.0
		_update_preview()

func _process_queued_action(entry: Dictionary) -> bool:
	var data: Dictionary = entry.get("data", {}) as Dictionary
	var origin: Vector2i = data.get("pos", Vector2i.ZERO)
	var tool_name: String = String(data.get("tool", selected_tool))
	var action_type: String = String(entry.get("type", ""))
	if action_type.is_empty():
		return false

	# 1) Targets
	var facing: Vector2i = data.get("facing", Vector2i(1, 0))
	var targets: Array[Vector2i] = _target_calc.compute_positions(tool_name, origin, facing)
	if targets.is_empty():
		return false

	# 2) Validate per tile via GridValidator
	var vres: Dictionary = _action_validator.validate(tool_name, targets, grid_validator, 0)
	var valid: bool = bool(vres.get("valid", false))
	if not valid:
		var reason: String = String(vres.get("reason", "invalid"))
		print("[InteractionSystem] Action failed: %s" % reason)
		return false
	var valid_positions: Array[Vector2i] = vres.get("valid_positions", []) as Array[Vector2i]

	# 3) Execute via ActionHandlers -> GridManager
	var tool_params: Dictionary = {}
	match tool_name:
		"watering_can":
			tool_params["water_add"] = 25
		"seed_bag":
			tool_params["seed_id"] = "lettuce"
		"fertilizer":
			tool_params["npk_amount"] = 10
		_:
			pass

	var hres: Dictionary = _action_handlers.perform(action_type, tool_name, valid_positions, grid_manager, tool_params, 0)
	var success: bool = bool(hres.get("success", false))
	if success:
		var pa: PlayerAction = PlayerAction.new(0, action_type, origin, tool_name)
		action_executed.emit(pa, hres)

		var details: Dictionary = hres.get("details", {}) as Dictionary
		match action_type:
			"test_soil":
				var t: Dictionary = details.get("tile_info", {}) as Dictionary
				var ph: float = float(t.get("ph_level", 7.0))
				var h2o: float = float(t.get("water_content", 0.0))
				var n: float = float(t.get("nitrogen", 0.0))
				var p: float = float(t.get("phosphorus", 0.0))
				var k: float = float(t.get("potassium", 0.0))
				var om: float = float(t.get("organic_matter", 0.0))
				print("[SoilTest] pos=%s pH=%.2f H2O=%.0f%% N=%.0f P=%.0f K=%.0f OM=%.0f" % [
					origin, ph, h2o, n, p, k, om
				])
			"fertilize":
				var fertilized: int = int(details.get("fertilized", 0))
				var npk_amount: int = int(tool_params.get("npk_amount", 10))
				print("[Fertilizer] Applied to %d tiles (+%d NPK)" % [fertilized, npk_amount])
			_:
				print("[InteractionSystem] Action executed (queued): %s at %s -> %s" % [
					action_type, origin, details
				])
		return true

	print("[InteractionSystem] Action execution failed: %s" % String(hres.get("reason", "unknown")))
	return false

# ============================================================================
# INPUT MAPPING
# ============================================================================
func _setup_input_map() -> void:
	print("[InteractionSystem] Input mapping configured")

func _ensure_input_map() -> void:
	# Movement
	_ensure_action("move_up", [KEY_W, KEY_UP])
	_ensure_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	# Actions
	_ensure_action("action_primary", [KEY_E, KEY_SPACE])
	_ensure_action("action_throw", [KEY_Q])
	_ensure_action("sprint", [KEY_SHIFT])
	_ensure_action("inspect", [KEY_TAB])
	_ensure_action("emote_wheel", [KEY_F])
	# Tool hotkeys 1-7
	_ensure_action("tool_1", [KEY_1])
	_ensure_action("tool_2", [KEY_2])
	_ensure_action("tool_3", [KEY_3])
	_ensure_action("tool_4", [KEY_4])
	_ensure_action("tool_5", [KEY_5])
	_ensure_action("tool_6", [KEY_6])
	_ensure_action("tool_7", [KEY_7])

func _ensure_action(name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for code in keys:
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = code
		if not _has_event(name, ev):
			InputMap.action_add_event(name, ev)

func _has_event(action: String, ev: InputEvent) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and ev is InputEventKey and e.keycode == ev.keycode:
			return true
	return false

# ============================================================================
# INPUT HANDLING
# ============================================================================
func _input(event: InputEvent) -> void:
	if not input_enabled or current_input_mode == "disabled":
		return

	# Handle tool selection (always allowed for clarity)
	if event is InputEventKey and event.pressed:
		_handle_tool_selection(event)

	# Handle mouse actions
	if event is InputEventMouseButton:
		_handle_mouse_action(event)

	# Handle grid-cursor movement (debug cursor)
	if event is InputEventKey and event.pressed:
		_handle_movement_input(event)

func _handle_tool_selection(event: InputEventKey) -> void:
	match event.keycode:
		KEY_1: select_tool("hoe")
		KEY_2: select_tool("watering_can")
		KEY_3: select_tool("seed_bag")
		KEY_4: select_tool("harvester")
		KEY_5: select_tool("fertilizer")
		KEY_6: select_tool("soil_test")

func _handle_mouse_action(event: InputEventMouseButton) -> void:
	if not event.pressed:
		return
	var world_pos: Vector2 = event.position
	var grid_pos: Vector2i = Vector2i.ZERO
	if grid_validator:
		grid_pos = grid_validator.world_to_grid(world_pos)
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_perform_primary_action(grid_pos)
		MOUSE_BUTTON_RIGHT:
			_perform_secondary_action(grid_pos)

func _handle_movement_input(event: InputEventKey) -> void:
	var movement_delta: Vector2i = Vector2i.ZERO
	match event.keycode:
		KEY_W, KEY_UP: movement_delta = Vector2i(0, -1)
		KEY_S, KEY_DOWN: movement_delta = Vector2i(0, 1)
		KEY_A, KEY_LEFT: movement_delta = Vector2i(-1, 0)
		KEY_D, KEY_RIGHT: movement_delta = Vector2i(1, 0)
	if movement_delta != Vector2i.ZERO:
		var new_pos: Vector2i = target_position + movement_delta
		_request_player_movement(new_pos)
		_cursor_facing = movement_delta
		_update_preview()

func _enqueue_action(action_type: String, grid_pos: Vector2i, tool_name: String) -> void:
	if input_queue:
		input_queue.enqueue(action_type, {
			"pos": grid_pos,
			"tool": tool_name,
			"player_id": 0
		})

# ============================================================================
# ACTION PROCESSING
# ============================================================================
func _perform_primary_action(grid_pos: Vector2i) -> void:
	if _is_carrying:
		return
	var current_time: float = Time.get_unix_time_from_system()
	if current_time - last_action_time < input_cooldown:
		return
	var action_type: String = _get_primary_action_for_tool(selected_tool)
	if action_type.is_empty():
		return
	_enqueue_action(action_type, grid_pos, selected_tool)
	last_action_time = current_time

func _perform_secondary_action(grid_pos: Vector2i) -> void:
	var action: PlayerAction = PlayerAction.new(0, "inspect", grid_pos, "")
	_process_action(action)

func _get_primary_action_for_tool(tool: String) -> String:
	match tool:
		"hoe": return "till"
		"watering_can": return "water"
		"seed_bag": return "plant"
		"harvester": return "harvest"
		"fertilizer": return "fertilize"
		"soil_test": return "test_soil"
		_: return ""

func _process_action(action: PlayerAction) -> void:
	action_requested.emit(action)
	if not _validate_action(action):
		action_failed.emit(action, action.validation_reason)
		print("[InteractionSystem] Action failed: %s" % action.validation_reason)
		return
	action.is_valid = true
	action_validated.emit(action)
	var result: Dictionary = _execute_action(action)
	if result.get("success", false):
		_record_successful_action(action, result)
		action_executed.emit(action, result)
		print("[InteractionSystem] Action executed: %s at %s" % [action.action_type, action.target_position])
	else:
		action_failed.emit(action, result.get("reason", "Unknown error"))
		print("[InteractionSystem] Action execution failed: %s" % result.get("reason", "Unknown error"))

func _validate_action(action: PlayerAction) -> bool:
	if not grid_validator:
		action.validation_reason = "GridValidator not available"
		return false
	var validation_result: Dictionary = {}
	match action.action_type:
		"till", "water", "plant", "harvest", "fertilize", "test_soil":
			validation_result = grid_validator.validate_tool_action(
				action.target_position, action.tool_used, action.player_id)
		"inspect":
			validation_result = {"valid": grid_validator.is_valid_position(action.target_position)}
		_:
			validation_result = {"valid": false, "reason": "Unknown action type"}
	if validation_result.get("valid", false):
		return true
	action.validation_reason = validation_result.get("reason", "Validation failed")
	return false

func _execute_action(action: PlayerAction) -> Dictionary:
	if not grid_manager:
		return {"success": false, "reason": "GridManager not available"}
	var result: Dictionary = {"success": false}
	match action.action_type:
		"till":
			result["success"] = grid_manager.till_soil(action.target_position, action.player_id)
		"water":
			result["success"] = grid_manager.water_tile(action.target_position, 0.3, action.player_id)
		"plant":
			var crop_type: String = String(action.additional_data.get("crop_type", "lettuce"))
			result["success"] = grid_manager.plant_crop(action.target_position, crop_type, action.player_id)
		"harvest":
			result = grid_manager.harvest_crop(action.target_position, action.player_id)
		"fertilize":
			result["success"] = false
			result["reason"] = "Fertilization not implemented yet"
		"test_soil":
			var tile: FarmTileData = grid_manager.get_tile(action.target_position)
			if tile:
				result["success"] = true
				result["tile_info"] = tile.to_dict()
			else:
				result["reason"] = "No tile at position"
		"inspect":
			result = _inspect_tile(action.target_position)
		_:
			result["reason"] = "Unknown action type: %s" % action.action_type
	return result

func _inspect_tile(pos: Vector2i) -> Dictionary:
	if not grid_manager:
		return {"success": false, "reason": "GridManager not available"}
	var tile: FarmTileData = grid_manager.get_tile(pos)
	if not tile:
		return {"success": false, "reason": "No tile at position"}
	var info: Dictionary = {
		"success": true,
		"position": pos,
		"tile_data": tile.to_dict()
	}
	if tile.has_crop():
		info["description"] = "Tile has %s crop" % tile.crop.get("type", "unknown")
	elif tile.has_machine():
		info["description"] = "Tile has %s machine" % tile.machine.get("type", "unknown")
	elif tile.state == FarmTileData.TileState.TILLED or tile.state == FarmTileData.TileState.WATERED:
		var state_label: String = "Watered" if tile.state == FarmTileData.TileState.WATERED else "Tilled"
		info["description"] = "%s soil (water: %.0f%%)" % [state_label, tile.water_content]
	else:
		info["description"] = "Untilled soil"
	return info

# ============================================================================
# TOOL MANAGEMENT
# ============================================================================
func select_tool(tool_name: String) -> bool:
	if not tool_name in ["hoe", "watering_can", "seed_bag", "harvester", "fertilizer", "soil_test"]:
		print("[InteractionSystem] Unknown tool: %s" % tool_name)
		return false
	selected_tool = tool_name
	print("[InteractionSystem] Selected tool: %s" % selected_tool)
	_update_preview()
	return true

func get_current_tool() -> String:
	return selected_tool

func set_carry_state(flag: bool) -> void:
	_is_carrying = flag
	_update_preview()

# ============================================================================
# PLAYER MOVEMENT (cursor)
# ============================================================================
func _request_player_movement(new_pos: Vector2i) -> void:
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_player_movement(target_position, new_pos)
		if validation.get("valid", false):
			target_position = new_pos
			print("[InteractionSystem] Player moved to %s" % target_position)
		else:
			print("[InteractionSystem] Invalid movement: %s" % String(validation.get("reason", "")))

# ============================================================================
# ACTION HISTORY
# ============================================================================
func _record_successful_action(action: PlayerAction, result: Dictionary) -> void:
	action.additional_data["result"] = result
	action_history.append(action)
	if action_history.size() > max_history_size:
		action_history.pop_front()

func get_recent_actions(count: int = 10) -> Array[PlayerAction]:
	var recent_count: int = min(count, action_history.size())
	return action_history.slice(-recent_count)

# ============================================================================
# STATE MANAGEMENT
# ============================================================================
func _on_game_state_changed(from_state: int, to_state: int) -> void:
	match to_state:
		GameManager.GameState.PLAYING:
			set_input_mode("farm")
		GameManager.GameState.PAUSED:
			set_input_mode("ui")
		GameManager.GameState.MENU, GameManager.GameState.LOBBY:
			set_input_mode("ui")
		_:
			set_input_mode("disabled")

func set_input_mode(mode: String) -> void:
	if mode != current_input_mode:
		current_input_mode = mode
		input_enabled = (mode != "disabled")
		input_mode_changed.emit(mode)
		print("[InteractionSystem] Input mode changed to: %s" % mode)
		if mode == "disabled":
			_clear_preview()
		else:
			_update_preview()

# ============================================================================
# PREVIEW UPDATE (player-tile preferred, cursor fallback)
# ============================================================================
func _update_preview() -> void:
	if _preview_node == null:
		_preview_node = _find_preview_node()
	if _preview_node == null:
		return
	if current_input_mode == "disabled" or selected_tool.is_empty():
		_clear_preview()
		return

	var facing: Vector2i
	var origin: Vector2i

	if _player != null and grid_validator != null and grid_validator.has_method("world_to_grid"):
		var fx: int = 0
		if _player.facing_direction.x > 0.2: fx = 1
		elif _player.facing_direction.x < -0.2: fx = -1
		var fy: int = 0
		if _player.facing_direction.y > 0.2: fy = 1
		elif _player.facing_direction.y < -0.2: fy = -1
		facing = Vector2i(fx, fy)
		if facing == Vector2i.ZERO:
			facing = (_cursor_facing if _cursor_facing != Vector2i.ZERO else Vector2i(1, 0))
		var player_tile: Vector2i = grid_validator.world_to_grid(_player.global_position)
		origin = player_tile + facing
	else:
		facing = (_cursor_facing if _cursor_facing != Vector2i.ZERO else Vector2i(1, 0))
		origin = target_position + facing

	var targets: Array[Vector2i] = _target_calc.compute_positions(selected_tool, origin, facing)
	if targets.is_empty():
		_clear_preview()
		return

	var val: Dictionary = {}
	for p in targets:
		var v: Dictionary = grid_validator.validate_tool_action(p, selected_tool, 0)
		val[p] = bool(v.get("valid", false))

	if _preview_node and _preview_node.has_method("set_preview"):
		_preview_node.set_preview(targets, val)
	# print("[IS] preview targets=", targets, " tool=", selected_tool, " node_ok=", _preview_node != null)

func _clear_preview() -> void:
	if _preview_node and _preview_node.has_method("clear_preview"):
		_preview_node.clear_preview()

# ============================================================================
# DEBUG AND UTILITY
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"input_enabled": input_enabled,
		"input_mode": current_input_mode,
		"selected_tool": selected_tool,
		"target_position": target_position,
		"pending_actions": pending_actions.size(),
		"action_history": action_history.size(),
		"grid_manager_available": grid_manager != null,
		"grid_validator_available": grid_validator != null
	}

func simulate_action(action_type: String, pos: Vector2i) -> Dictionary:
	var action: PlayerAction = PlayerAction.new(0, action_type, pos, selected_tool)
	_process_action(action)
	return {"action_processed": true, "position": pos}

func request_primary_action(tool_name: String, grid_pos: Vector2i, player_id: int = 0, facing: Vector2i = Vector2i(1, 0)) -> void:
	var action_type: String = _get_primary_action_for_tool(tool_name)
	if action_type.is_empty():
		return
	if input_queue:
		input_queue.enqueue(action_type, {
			"pos": grid_pos,
			"tool": tool_name,
			"player_id": player_id,
			"facing": facing
		})

func request_action_from_network(peer_id: int, tool_name: String, grid_pos: Vector2i, facing: Vector2i) -> void:
	# Host-only usage: route a networked request through the same queue/path
	var action_type: String = _get_primary_action_for_tool(tool_name)
	if action_type.is_empty():
		return
	if input_queue:
		input_queue.enqueue(action_type, {
			"pos": grid_pos,
			"tool": tool_name,
			"player_id": peer_id,
			"facing": facing
		})
