extends Node
# GridManager.gd - AUTOLOAD #3
# Manages the actual farm grid data, tiles, crops, and machines
# Uses GridValidator for all validation before making changes

# ============================================================================
# TILE DATA STRUCTURE
# ============================================================================
class FarmTile:
	var position: Vector2i
	var tile_type: String = "soil"  # soil, water, path, building
	var is_tilled: bool = false
	var water_level: float = 0.0    # 0.0 to 1.0
	var fertility: float = 0.7      # 0.0 to 1.0
	var ph_level: float = 7.0       # 0.0 to 14.0 (7.0 = neutral)
	
	# What's on this tile
	var crop: Dictionary = {}       # Crop data if any
	var machine: Dictionary = {}    # Machine data if any
	var item: Dictionary = {}       # Dropped item if any
	
	# Visual/state
	var needs_update: bool = false
	var last_modified: float = 0.0
	
	func _init(pos: Vector2i = Vector2i.ZERO) -> void:
		position = pos
		last_modified = Time.get_unix_time_from_system()
	
	func to_dict() -> Dictionary:
		return {
			"position": position,
			"tile_type": tile_type,
			"is_tilled": is_tilled,
			"water_level": water_level,
			"fertility": fertility,
			"ph_level": ph_level,
			"crop": crop,
			"machine": machine,
			"item": item,
			"last_modified": last_modified
		}
	
	func from_dict(data: Dictionary) -> void:
		position = data.get("position", Vector2i.ZERO)
		tile_type = data.get("tile_type", "soil")
		is_tilled = data.get("is_tilled", false)
		water_level = data.get("water_level", 0.0)
		fertility = data.get("fertility", 0.7)
		ph_level = data.get("ph_level", 7.0)
		crop = data.get("crop", {})
		machine = data.get("machine", {})
		item = data.get("item", {})
		last_modified = data.get("last_modified", Time.get_unix_time_from_system())
	
	func has_crop() -> bool:
		return not crop.is_empty()
	
	func has_machine() -> bool:
		return not machine.is_empty()
	
	func has_item() -> bool:
		return not item.is_empty()
	
	func is_empty() -> bool:
		return not has_crop() and not has_machine() and not has_item()
	
	func mark_dirty() -> void:
		needs_update = true
		last_modified = Time.get_unix_time_from_system()

# ============================================================================
# SIGNALS
# ============================================================================
signal tile_changed(position: Vector2i, tile: FarmTile)
signal crop_planted(position: Vector2i, crop_type: String)
signal crop_harvested(position: Vector2i, crop_type: String, yield_amount: int)
signal machine_placed(position: Vector2i, machine_type: String)
signal machine_removed(position: Vector2i, machine_type: String)
signal grid_updated()

# ============================================================================
# PROPERTIES
# ============================================================================
var grid_data: Dictionary = {}  # Vector2i -> FarmTile
var grid_size: Vector2i = Vector2i(50, 50)
var tile_size: int = 64

# Grid references
var grid_validator: Node = null

# Performance
var dirty_tiles: Array[Vector2i] = []
var chunk_size: int = 16
var loaded_chunks: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "GridManager"
	print("[GridManager] Initializing as Autoload #3...")
	
	# Get reference to GridValidator (should be available as Autoload #2)
	grid_validator = GridValidator
	if not grid_validator:
		print("[GridManager] WARNING: GridValidator not found!")
	else:
		print("[GridManager] GridValidator connected")
	
	# Initialize the grid
	_initialize_grid()
	
	# Register with GameManager
	if GameManager:
		GameManager.register_system("GridManager", self)
		print("[GridManager] Registered with GameManager")
	
	print("[GridManager] Initialization complete!")

func _initialize_grid() -> void:
	print("[GridManager] Initializing %dx%d grid..." % [grid_size.x, grid_size.y])
	
	# Create basic grid structure (don't create all tiles at once for performance)
	# We'll create tiles on-demand as they're accessed
	
	# Set grid size in validator
	if grid_validator:
		grid_validator.set_grid_size(grid_size)
	
	print("[GridManager] Grid initialized")

# ============================================================================
# TILE ACCESS AND MANAGEMENT
# ============================================================================
func get_tile(pos: Vector2i) -> FarmTile:
	"""Get tile at position, creating it if it doesn't exist"""
	if pos in grid_data:
		return grid_data[pos]
	
	# Create tile on-demand
	if _is_valid_position(pos):
		var tile: FarmTile = FarmTile.new(pos)
		grid_data[pos] = tile
		return tile
	
	return null

func set_tile(pos: Vector2i, tile: FarmTile) -> bool:
	"""Set tile at position"""
	if not _is_valid_position(pos):
		return false
	
	grid_data[pos] = tile
	tile.mark_dirty()
	_mark_tile_dirty(pos)
	tile_changed.emit(pos, tile)
	return true

func has_tile(pos: Vector2i) -> bool:
	"""Check if tile exists at position"""
	return pos in grid_data

func remove_tile(pos: Vector2i) -> bool:
	"""Remove tile from grid"""
	if pos in grid_data:
		grid_data.erase(pos)
		_mark_tile_dirty(pos)
		return true
	return false

# ============================================================================
# CROP MANAGEMENT
# ============================================================================
func plant_crop(pos: Vector2i, crop_type: String, player_id: int = -1) -> bool:
	"""Plant a crop at the specified position"""
	# Validate the action first
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_crop_placement(pos, crop_type)
		if not validation["valid"]:
			print("[GridManager] Cannot plant crop: %s" % validation["reason"])
			return false
	
	var tile: FarmTile = get_tile(pos)
	if not tile:
		return false
	
	# Check if tile can accept a crop
	if tile.has_crop():
		print("[GridManager] Cannot plant crop - tile already has crop")
		return false
	
	if not tile.is_tilled:
		print("[GridManager] Cannot plant crop - soil not tilled")
		return false
	
	# Plant the crop
	tile.crop = {
		"type": crop_type,
		"planted_at": Time.get_unix_time_from_system(),
		"planted_by": player_id,
		"growth_stage": 0,
		"health": 1.0,
		"water_needs": 0.5,
		"maturity_time": _get_crop_maturity_time(crop_type)
	}
	
	tile.mark_dirty()
	_mark_tile_dirty(pos)
	
	print("[GridManager] Planted %s at %s" % [crop_type, pos])
	crop_planted.emit(pos, crop_type)
	return true

func harvest_crop(pos: Vector2i, player_id: int = -1) -> Dictionary:
	"""Harvest crop at position, returns yield info"""
	var result: Dictionary = {
		"success": false,
		"crop_type": "",
		"yield": 0,
		"quality": 0.0
	}
	
	# Validate the action
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_tool_action(pos, "harvester", player_id)
		if not validation["valid"]:
			result["reason"] = validation["reason"]
			return result
	
	var tile: FarmTile = get_tile(pos)
	if not tile or not tile.has_crop():
		result["reason"] = "No crop at position"
		return result
	
	var crop: Dictionary = tile.crop
	
	# Check if crop is mature
	var age: float = Time.get_unix_time_from_system() - crop["planted_at"]
	if age < crop["maturity_time"]:
		result["reason"] = "Crop not mature yet"
		return result
	
	# Calculate yield based on conditions
	var base_yield: int = _get_base_yield(crop["type"])
	var quality_modifier: float = _calculate_quality_modifier(tile)
	var final_yield: int = max(1, int(base_yield * quality_modifier))
	
	# Remove crop from tile
	result["success"] = true
	result["crop_type"] = crop["type"]
	result["yield"] = final_yield
	result["quality"] = quality_modifier
	
	tile.crop = {}
	tile.mark_dirty()
	_mark_tile_dirty(pos)
	
	print("[GridManager] Harvested %d %s at %s" % [final_yield, crop["type"], pos])
	crop_harvested.emit(pos, crop["type"], final_yield)
	return result

# ============================================================================
# SOIL MANAGEMENT
# ============================================================================
func till_soil(pos: Vector2i, player_id: int = -1) -> bool:
	"""Till soil at position"""
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_tool_action(pos, "hoe", player_id)
		if not validation["valid"]:
			print("[GridManager] Cannot till soil: %s" % validation["reason"])
			return false
	
	var tile: FarmTile = get_tile(pos)
	if not tile:
		return false
	
	if tile.has_crop() or tile.has_machine():
		print("[GridManager] Cannot till soil - tile occupied")
		return false
	
	tile.is_tilled = true
	tile.mark_dirty()
	_mark_tile_dirty(pos)
	
	print("[GridManager] Tilled soil at %s" % pos)
	return true

func water_tile(pos: Vector2i, amount: float = 0.3, player_id: int = -1) -> bool:
	"""Add water to tile"""
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_tool_action(pos, "watering_can", player_id)
		if not validation["valid"]:
			print("[GridManager] Cannot water tile: %s" % validation["reason"])
			return false
	
	var tile: FarmTile = get_tile(pos)
	if not tile:
		return false
	
	tile.water_level = min(1.0, tile.water_level + amount)
	tile.mark_dirty()
	_mark_tile_dirty(pos)
	
	return true

# ============================================================================
# MACHINE MANAGEMENT
# ============================================================================
func place_machine(pos: Vector2i, machine_type: String, player_id: int = -1) -> bool:
	"""Place a machine at position"""
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_machine_placement(pos, machine_type)
		if not validation["valid"]:
			print("[GridManager] Cannot place machine: %s" % validation["reason"])
			return false
	
	var tile: FarmTile = get_tile(pos)
	if not tile:
		return false
	
	if not tile.is_empty():
		print("[GridManager] Cannot place machine - tile occupied")
		return false
	
	tile.machine = {
		"type": machine_type,
		"placed_at": Time.get_unix_time_from_system(),
		"placed_by": player_id,
		"health": 1.0,
		"efficiency": 1.0,
		"last_used": 0.0
	}
	
	tile.mark_dirty()
	_mark_tile_dirty(pos)
	
	print("[GridManager] Placed %s at %s" % [machine_type, pos])
	machine_placed.emit(pos, machine_type)
	return true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _is_valid_position(pos: Vector2i) -> bool:
	if grid_validator:
		return grid_validator.is_valid_position(pos)
	# Fallback validation
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

func _mark_tile_dirty(pos: Vector2i) -> void:
	if not pos in dirty_tiles:
		dirty_tiles.append(pos)

func _get_crop_maturity_time(crop_type: String) -> float:
	# Return maturity time in seconds
	match crop_type:
		"lettuce": return 30.0    # 30 seconds for testing
		"corn": return 45.0
		"wheat": return 60.0
		"tomato": return 90.0
		"potato": return 75.0
		_: return 60.0

func _get_base_yield(crop_type: String) -> int:
	match crop_type:
		"lettuce": return 2
		"corn": return 3
		"wheat": return 4
		"tomato": return 2
		"potato": return 3
		_: return 2

func _calculate_quality_modifier(tile: FarmTile) -> float:
	var quality: float = 1.0
	
	# Water factor
	quality *= (0.5 + tile.water_level * 0.5)
	
	# Fertility factor
	quality *= tile.fertility
	
	# pH factor (optimal around 6.5-7.5)
	var ph_diff: float = abs(tile.ph_level - 7.0)
	quality *= max(0.5, 1.0 - ph_diff * 0.1)
	
	return clamp(quality, 0.1, 2.0)

# ============================================================================
# SERIALIZATION
# ============================================================================
func serialize_grid() -> Dictionary:
	var data: Dictionary = {}
	for pos in grid_data:
		data[str(pos)] = grid_data[pos].to_dict()
	return {
		"grid_size": grid_size,
		"tiles": data,
		"version": 1
	}

func deserialize_grid(data: Dictionary) -> void:
	grid_data.clear()
	
	if "grid_size" in data:
		grid_size = data["grid_size"]
	
	if "tiles" in data:
		for pos_str in data["tiles"]:
			var pos_array: Array = pos_str.strip_edges("()").split(",")
			if pos_array.size() == 2:
				var pos: Vector2i = Vector2i(pos_array[0].to_int(), pos_array[1].to_int())
				var tile: FarmTile = FarmTile.new(pos)
				tile.from_dict(data["tiles"][pos_str])
				grid_data[pos] = tile

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"grid_size": grid_size,
		"loaded_tiles": grid_data.size(),
		"dirty_tiles": dirty_tiles.size(),
		"validator_available": grid_validator != null
	}

func print_tile_info(pos: Vector2i) -> void:
	var tile: FarmTile = get_tile(pos)
	if tile:
		print("Tile at %s: %s" % [pos, tile.to_dict()])
	else:
		print("No tile at %s" % pos)
