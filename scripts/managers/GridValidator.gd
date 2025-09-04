extends Node
# GridValidator.gd - AUTOLOAD #2 
# Validates grid positions, placements, and state before GridManager uses them
# MUST come before GridManager in autoload order!

# ============================================================================
# SIGNALS
# ============================================================================
signal validation_failed(position: Vector2i, reason: String)
signal validation_passed(position: Vector2i, action: String)

# ============================================================================
# PROPERTIES
# ============================================================================
var grid_size: Vector2i = Vector2i(50, 50)  # Default grid dimensions
var tile_size: int = 64  # Size of each grid tile in pixels
var valid_positions: Dictionary = {}  # Cache of validated positions

# Validation rules
var max_distance_from_center: int = 25
var min_distance_between_machines: int = 2
var allow_overlap: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "GridValidator"
	print("[GridValidator] Initialized as Autoload #2")
	
	# Register with GameManager
	if GameManager:
		GameManager.register_system("GridValidator", self)
		print("[GridValidator] Registered with GameManager")

# ============================================================================
# POSITION VALIDATION
# ============================================================================
func is_valid_position(grid_pos: Vector2i) -> bool:
	"""Check if a grid position is within valid bounds"""
	if grid_pos.x < 0 or grid_pos.x >= grid_size.x:
		return false
	if grid_pos.y < 0 or grid_pos.y >= grid_size.y:
		return false
	return true

func is_within_farm_bounds(grid_pos: Vector2i) -> bool:
	"""Check if position is within the playable farm area"""
	var center: Vector2i = grid_size / 2
	var distance: float = grid_pos.distance_to(Vector2(center))
	return distance <= max_distance_from_center

func validate_crop_placement(grid_pos: Vector2i, crop_type: String = "") -> Dictionary:
	"""Validate if a crop can be placed at this position"""
	var result: Dictionary = {
		"valid": false,
		"reason": "",
		"grid_pos": grid_pos
	}
	
	# Check basic position validity
	if not is_valid_position(grid_pos):
		result["reason"] = "Position outside grid bounds"
		validation_failed.emit(grid_pos, result["reason"])
		return result
	
	# Check farm bounds
	if not is_within_farm_bounds(grid_pos):
		result["reason"] = "Position outside farm area"
		validation_failed.emit(grid_pos, result["reason"])
		return result
	
	# TODO: Check if tile is already occupied (when GridManager is available)
	# TODO: Check soil quality requirements
	# TODO: Check crop-specific placement rules
	
	result["valid"] = true
	validation_passed.emit(grid_pos, "crop_placement")
	return result

func validate_machine_placement(grid_pos: Vector2i, machine_type: String) -> Dictionary:
	"""Validate if a machine can be placed at this position"""
	var result: Dictionary = {
		"valid": false,
		"reason": "",
		"grid_pos": grid_pos,
		"machine_type": machine_type
	}
	
	# Check basic position validity
	if not is_valid_position(grid_pos):
		result["reason"] = "Position outside grid bounds"
		validation_failed.emit(grid_pos, result["reason"])
		return result
	
	# Check farm bounds
	if not is_within_farm_bounds(grid_pos):
		result["reason"] = "Position outside farm area"  
		validation_failed.emit(grid_pos, result["reason"])
		return result
	
	# TODO: Check minimum distance from other machines
	# TODO: Check if position allows machine access
	# TODO: Check machine-specific requirements
	
	result["valid"] = true
	validation_passed.emit(grid_pos, "machine_placement")
	return result

func validate_player_movement(from_pos: Vector2i, to_pos: Vector2i, player_id: int = -1) -> Dictionary:
	"""Validate if a player can move from one position to another"""
	var result: Dictionary = {
		"valid": false,
		"reason": "",
		"from_pos": from_pos,
		"to_pos": to_pos,
		"player_id": player_id
	}
	
	# Check destination validity
	if not is_valid_position(to_pos):
		result["reason"] = "Destination outside grid bounds"
		validation_failed.emit(to_pos, result["reason"])
		return result
	
	# Check movement distance (prevent teleporting)
	var distance: float = from_pos.distance_to(Vector2(to_pos))
	if distance > 10.0:  # Max movement per update
		result["reason"] = "Movement distance too large"
		validation_failed.emit(to_pos, result["reason"])
		return result
	
	# TODO: Check for obstacles
	# TODO: Check collision with other players
	# TODO: Validate pathfinding
	
	result["valid"] = true
	validation_passed.emit(to_pos, "player_movement")
	return result

# ============================================================================
# ACTION VALIDATION
# ============================================================================
func validate_tool_action(grid_pos: Vector2i, tool: String, player_id: int = -1) -> Dictionary:
	"""Validate if a tool action can be performed at this position"""
	var result: Dictionary = {
		"valid": false,
		"reason": "",
		"grid_pos": grid_pos,
		"tool": tool,
		"player_id": player_id
	}
	
	# Check position validity
	if not is_valid_position(grid_pos):
		result["reason"] = "Position outside grid bounds"
		validation_failed.emit(grid_pos, result["reason"])
		return result
	
	# Validate tool-specific rules
	match tool:
		"hoe":
			# Can till empty soil
			result = _validate_hoe_action(grid_pos)
		"watering_can":
			# Can water tilled soil or crops
			result = _validate_watering_action(grid_pos)
		"seed_bag":
			# Can plant on tilled, watered soil
			result = _validate_planting_action(grid_pos)
		"harvester":
			# Can harvest mature crops
			result = _validate_harvest_action(grid_pos)
		"fertilizer":
			# Can fertilize soil or crops
			result = _validate_fertilizer_action(grid_pos)
		"soil_test":
			# Can test any soil
			result = _validate_soil_test_action(grid_pos)
		_:
			result["reason"] = "Unknown tool: %s" % tool
			validation_failed.emit(grid_pos, result["reason"])
			return result
	
	if result["valid"]:
		validation_passed.emit(grid_pos, "tool_action_%s" % tool)
	
	return result

# ============================================================================
# TOOL-SPECIFIC VALIDATION (private methods)
# ============================================================================
func _validate_hoe_action(grid_pos: Vector2i) -> Dictionary:
	var result: Dictionary = {"valid": true, "reason": ""}
	# TODO: Check if soil is already tilled
	# TODO: Check if there's a crop already planted
	return result

func _validate_watering_action(grid_pos: Vector2i) -> Dictionary:
	var result: Dictionary = {"valid": true, "reason": ""}
	# TODO: Check if soil exists at position
	# TODO: Check if already fully watered
	return result

func _validate_planting_action(grid_pos: Vector2i) -> Dictionary:
	var result: Dictionary = {"valid": true, "reason": ""}
	# TODO: Check if soil is tilled and watered
	# TODO: Check if position is empty
	return result

func _validate_harvest_action(grid_pos: Vector2i) -> Dictionary:
	var result: Dictionary = {"valid": true, "reason": ""}
	# TODO: Check if crop exists and is mature
	return result

func _validate_fertilizer_action(grid_pos: Vector2i) -> Dictionary:
	var result: Dictionary = {"valid": true, "reason": ""}
	# TODO: Check if soil or crop can be fertilized
	return result

func _validate_soil_test_action(grid_pos: Vector2i) -> Dictionary:
	var result: Dictionary = {"valid": true, "reason": ""}
	# Soil test can always be used
	return result

# ============================================================================
# BATCH VALIDATION
# ============================================================================
func validate_area(start_pos: Vector2i, end_pos: Vector2i, action: String) -> Dictionary:
	"""Validate an action across a rectangular area"""
	var result: Dictionary = {
		"valid": true,
		"failed_positions": [],
		"total_positions": 0,
		"valid_positions": 0
	}
	
	var min_x: int = min(start_pos.x, end_pos.x)
	var max_x: int = max(start_pos.x, end_pos.x)
	var min_y: int = min(start_pos.y, end_pos.y)
	var max_y: int = max(start_pos.y, end_pos.y)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos: Vector2i = Vector2i(x, y)
			result["total_positions"] += 1
			
			var pos_result: Dictionary
			match action:
				"crop_placement":
					pos_result = validate_crop_placement(pos)
				"machine_placement":
					pos_result = validate_machine_placement(pos, "unknown")
				_:
					pos_result = {"valid": is_valid_position(pos)}
			
			if pos_result["valid"]:
				result["valid_positions"] += 1
			else:
				result["failed_positions"].append(pos)
				result["valid"] = false
	
	return result

# ============================================================================
# CONFIGURATION
# ============================================================================
func set_grid_size(new_size: Vector2i) -> void:
	grid_size = new_size
	valid_positions.clear()  # Clear cache
	print("[GridValidator] Grid size updated to: %s" % grid_size)

func set_farm_bounds(max_distance: int) -> void:
	max_distance_from_center = max_distance
	print("[GridValidator] Farm bounds updated to distance: %d" % max_distance)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Convert world position to grid coordinates"""
	return Vector2i(
		int(world_pos.x / tile_size),
		int(world_pos.y / tile_size)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convert grid coordinates to world position"""
	return Vector2(
		grid_pos.x * tile_size + tile_size / 2,
		grid_pos.y * tile_size + tile_size / 2
	)

func get_grid_center() -> Vector2i:
	"""Get the center position of the grid"""
	return grid_size / 2

func get_debug_info() -> Dictionary:
	return {
		"grid_size": grid_size,
		"tile_size": tile_size,
		"max_distance": max_distance_from_center,
		"cached_positions": valid_positions.size()
	}
