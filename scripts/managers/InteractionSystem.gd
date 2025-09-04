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

# Input state
var input_enabled: bool = true
var current_input_mode: String = "farm"  # "farm", "ui", "disabled"
var selected_tool: String = "hoe"
var target_position: Vector2i = Vector2i.ZERO

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

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "InteractionSystem"
	print("[InteractionSystem] Initializing as Autoload #4...")
	
	# Get references to other systems
	grid_manager = GridManager
	grid_validator = GridValidator
	
	if not grid_manager:
		print("[InteractionSystem] WARNING: GridManager not found!")
	else:
		print("[InteractionSystem] GridManager connected")
		
	if not grid_validator:
		print("[InteractionSystem] WARNING: GridValidator not found!")
	else:
		print("[InteractionSystem] GridValidator connected")
	
	# Set up input handling
	_setup_input_map()
	
	# Register with GameManager
	if GameManager:
		GameManager.register_system("InteractionSystem", self)
		print("[InteractionSystem] Registered with GameManager")
		
		# Connect to GameManager signals
		GameManager.state_changed.connect(_on_game_state_changed)
	
	print("[InteractionSystem] Initialization complete!")

func _setup_input_map() -> void:
	"""Setup input action mappings if they don't exist"""
	# TODO: This would normally be done in the Input Map
	# For now, we'll handle it programmatically in _input()
	print("[InteractionSystem] Input mapping configured")

# ============================================================================
# INPUT HANDLING
# ============================================================================
func _input(event: InputEvent) -> void:
	if not input_enabled or current_input_mode == "disabled":
		return
	
	# Handle tool selection
	if event is InputEventKey and event.pressed:
		_handle_tool_selection(event)
	
	# Handle mouse actions
	if event is InputEventMouseButton:
		_handle_mouse_action(event)
	
	# Handle movement (for future player movement)
	if event is InputEventKey and event.pressed:
		_handle_movement_input(event)

func _handle_tool_selection(event: InputEventKey) -> void:
	"""Handle tool selection via keyboard"""
	match event.keycode:
		KEY_1:
			select_tool("hoe")
		KEY_2:
			select_tool("watering_can")
		KEY_3:
			select_tool("seed_bag")
		KEY_4:
			select_tool("harvester")
		KEY_5:
			select_tool("fertilizer")
		KEY_6:
			select_tool("soil_test")

func _handle_mouse_action(event: InputEventMouseButton) -> void:
	"""Handle mouse clicks for farm actions"""
	if not event.pressed:
		return
	
	# Convert mouse position to grid position
	var world_pos: Vector2 = event.position  # This would need proper camera conversion
	var grid_pos: Vector2i = Vector2i.ZERO
	
	if grid_validator:
		grid_pos = grid_validator.world_to_grid(world_pos)
	
	# Different actions based on mouse button
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_perform_primary_action(grid_pos)
		MOUSE_BUTTON_RIGHT:
			_perform_secondary_action(grid_pos)

func _handle_movement_input(event: InputEventKey) -> void:
	"""Handle player movement input (WASD or arrow keys)"""
	var movement_delta: Vector2i = Vector2i.ZERO
	
	match event.keycode:
		KEY_W, KEY_UP:
			movement_delta = Vector2i(0, -1)
		KEY_S, KEY_DOWN:
			movement_delta = Vector2i(0, 1)
		KEY_A, KEY_LEFT:
			movement_delta = Vector2i(-1, 0)
		KEY_D, KEY_RIGHT:
			movement_delta = Vector2i(1, 0)
	
	if movement_delta != Vector2i.ZERO:
		var new_pos: Vector2i = target_position + movement_delta
		_request_player_movement(new_pos)

# ============================================================================
# ACTION PROCESSING
# ============================================================================
func _perform_primary_action(grid_pos: Vector2i) -> void:
	"""Perform the primary action for the selected tool"""
	# Check cooldown
	var current_time: float = Time.get_unix_time_from_system()
	if current_time - last_action_time < input_cooldown:
		return
	
	var action_type: String = _get_primary_action_for_tool(selected_tool)
	if action_type.is_empty():
		return
	
	var action: PlayerAction = PlayerAction.new(0, action_type, grid_pos, selected_tool)  # Player 0 for now
	_process_action(action)
	
	last_action_time = current_time

func _perform_secondary_action(grid_pos: Vector2i) -> void:
	"""Perform secondary action (usually inspect/info)"""
	var action: PlayerAction = PlayerAction.new(0, "inspect", grid_pos, "")
	_process_action(action)

func _get_primary_action_for_tool(tool: String) -> String:
	"""Get the primary action type for a tool"""
	match tool:
		"hoe":
			return "till"
		"watering_can":
			return "water"
		"seed_bag":
			return "plant"
		"harvester":
			return "harvest"
		"fertilizer":
			return "fertilize"
		"soil_test":
			return "test_soil"
		_:
			return ""

func _process_action(action: PlayerAction) -> void:
	"""Validate and execute an action"""
	action_requested.emit(action)
	
	# Step 1: Validate the action
	if not _validate_action(action):
		action_failed.emit(action, action.validation_reason)
		print("[InteractionSystem] Action failed: %s" % action.validation_reason)
		return
	
	action.is_valid = true
	action_validated.emit(action)
	
	# Step 2: Execute the action
	var result: Dictionary = _execute_action(action)
	
	# Step 3: Handle result
	if result.get("success", false):
		_record_successful_action(action, result)
		action_executed.emit(action, result)
		print("[InteractionSystem] Action executed: %s at %s" % [action.action_type, action.target_position])
	else:
		action_failed.emit(action, result.get("reason", "Unknown error"))
		print("[InteractionSystem] Action execution failed: %s" % result.get("reason", "Unknown error"))

func _validate_action(action: PlayerAction) -> bool:
	"""Validate an action using the grid validator"""
	if not grid_validator:
		action.validation_reason = "GridValidator not available"
		return false
	
	# Use appropriate validation based on action type
	var validation_result: Dictionary = {}
	
	match action.action_type:
		"till", "water", "plant", "harvest", "fertilize", "test_soil":
			validation_result = grid_validator.validate_tool_action(
				action.target_position, 
				action.tool_used, 
				action.player_id
			)
		"inspect":
			validation_result = {"valid": grid_validator.is_valid_position(action.target_position)}
		_:
			validation_result = {"valid": false, "reason": "Unknown action type"}
	
	if validation_result.get("valid", false):
		return true
	else:
		action.validation_reason = validation_result.get("reason", "Validation failed")
		return false

func _execute_action(action: PlayerAction) -> Dictionary:
	"""Execute a validated action using the grid manager"""
	if not grid_manager:
		return {"success": false, "reason": "GridManager not available"}
	
	var result: Dictionary = {"success": false}
	
	match action.action_type:
		"till":
			result["success"] = grid_manager.till_soil(action.target_position, action.player_id)
		
		"water":
			result["success"] = grid_manager.water_tile(action.target_position, 0.3, action.player_id)
		
		"plant":
			var crop_type: String = action.additional_data.get("crop_type", "lettuce")  # Default crop
			result["success"] = grid_manager.plant_crop(action.target_position, crop_type, action.player_id)
		
		"harvest":
			result = grid_manager.harvest_crop(action.target_position, action.player_id)
		
		"fertilize":
			# TODO: Implement fertilization in GridManager
			result["success"] = false
			result["reason"] = "Fertilization not implemented yet"
		
		"test_soil":
			# Get tile info
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
	"""Get detailed information about a tile"""
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
	
	# Add human-readable info
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
	"""Select a tool for the current player"""
	if not tool_name in ["hoe", "watering_can", "seed_bag", "harvester", "fertilizer", "soil_test"]:
		print("[InteractionSystem] Unknown tool: %s" % tool_name)
		return false
	
	selected_tool = tool_name
	print("[InteractionSystem] Selected tool: %s" % selected_tool)
	return true

func get_current_tool() -> String:
	return selected_tool

# ============================================================================
# PLAYER MOVEMENT
# ============================================================================
func _request_player_movement(new_pos: Vector2i) -> void:
	"""Request player movement to a new grid position"""
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_player_movement(target_position, new_pos)
		if validation["valid"]:
			target_position = new_pos
			print("[InteractionSystem] Player moved to %s" % target_position)
			# TODO: Update actual player position in scene
		else:
			print("[InteractionSystem] Invalid movement: %s" % validation["reason"])

# ============================================================================
# ACTION HISTORY
# ============================================================================
func _record_successful_action(action: PlayerAction, result: Dictionary) -> void:
	"""Record a successful action in history"""
	action.additional_data["result"] = result
	action_history.append(action)
	
	# Limit history size
	if action_history.size() > max_history_size:
		action_history.pop_front()

func get_recent_actions(count: int = 10) -> Array[PlayerAction]:
	"""Get recent actions from history"""
	var recent_count: int = min(count, action_history.size())
	return action_history.slice(-recent_count)

# ============================================================================
# STATE MANAGEMENT
# ============================================================================
func _on_game_state_changed(from_state: int, to_state: int) -> void:
	"""Handle game state changes"""
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
	"""Set the current input mode"""
	if mode != current_input_mode:
		current_input_mode = mode
		input_enabled = (mode != "disabled")
		input_mode_changed.emit(mode)
		print("[InteractionSystem] Input mode changed to: %s" % mode)

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
	"""Simulate an action for testing purposes"""
	var action: PlayerAction = PlayerAction.new(0, action_type, pos, selected_tool)
	_process_action(action)
	return {"action_processed": true, "position": pos}
