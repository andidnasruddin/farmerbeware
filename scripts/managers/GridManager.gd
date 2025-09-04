extends Node
# GridManager.gd - AUTOLOAD #3
# Manages the farm grid data using FarmTileData Resources
# Uses GridValidator for validation before making changes

# ============================================================================
# SIGNALS
# ============================================================================
signal tile_changed(position: Vector2i, tile: FarmTileData)
signal crop_planted(position: Vector2i, crop_type: String)
signal crop_harvested(position: Vector2i, crop_type: String, yield_amount: int)
signal machine_placed(position: Vector2i, machine_type: String)
signal machine_removed(position: Vector2i, machine_type: String)
signal grid_expanded(new_size: Vector2i)
signal chunk_dirty(chunk_pos: Vector2i)
signal grid_updated()

# ============================================================================
# PROPERTIES
# ============================================================================
var grid_data: Dictionary = {}				# Vector2i -> FarmTileData
var grid_size: Vector2i = DEFAULT_GRID_SIZE
var tile_size: int = 64
var chunk_manager: ChunkManager = null

# Grid references
var grid_validator: Node = null

# Fence bounds (rectangular farm area)
var fence_bounds: Rect2i = Rect2i(Vector2i.ZERO, DEFAULT_GRID_SIZE)

# Performance
var dirty_tiles: Array[Vector2i] = []
var chunk_size: int = CHUNK_SIZE
var loaded_chunks: Dictionary = {}

const DEFAULT_GRID_SIZE: Vector2i = Vector2i(10, 10)
const MAX_GRID_SIZE: Vector2i = Vector2i(100, 100)
const CHUNK_SIZE: int = 10
var soil_chemistry: SoilChemistry = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "GridManager"
	print("[GridManager] Initializing as Autoload #3...")
	
	grid_validator = GridValidator
	if not grid_validator:
		print("[GridManager] WARNING: GridValidator not found!")
	else:
		print("[GridManager] GridValidator connected")
	
	_initialize_grid()
	
	if GameManager:
		GameManager.register_system("GridManager", self)
		print("[GridManager] Registered with GameManager")
	
	print("[GridManager] Initialization complete!")
	
	chunk_manager = ChunkManager.new(CHUNK_SIZE, grid_size)
	soil_chemistry = SoilChemistry.new()

func _initialize_grid() -> void:
	print("[GridManager] Initializing %dx%d grid..." % [grid_size.x, grid_size.y])
	if grid_validator and grid_validator.has_method("set_grid_size"):
		grid_validator.set_grid_size(grid_size)
	if grid_validator and grid_validator.has_method("set_fence_bounds"):
		grid_validator.set_fence_bounds(fence_bounds)
	print("[GridManager] Grid initialized")

func expand_grid(new_size: Vector2i) -> void:
	# Cap to MAX_GRID_SIZE and ignore downsizing for now
	var target: Vector2i = Vector2i(
		min(new_size.x, MAX_GRID_SIZE.x),
		min(new_size.y, MAX_GRID_SIZE.y)
	)
	if target == grid_size:
		return

	var old_size: Vector2i = grid_size
	grid_size = target
	if chunk_manager:
		chunk_manager.set_config(CHUNK_SIZE, grid_size)
	fence_bounds = Rect2i(Vector2i.ZERO, grid_size)

	# Recompute indices and chunk ids for existing tiles
	for pos in grid_data.keys():
		var tile: FarmTileData = grid_data[pos]
		tile.grid_index = GridHelpers.grid_to_index(pos, grid_size.x)
		tile.chunk_id = GridHelpers.grid_to_chunk(pos, CHUNK_SIZE)

	# Notify validator and listeners
	if grid_validator and grid_validator.has_method("set_grid_size"):
		grid_validator.set_grid_size(grid_size)
	if grid_validator and grid_validator.has_method("set_fence_bounds"):
		grid_validator.set_fence_bounds(fence_bounds)

	emit_signal("grid_expanded", grid_size)
	print("[GridManager] Grid expanded from %s to %s" % [old_size, grid_size])

# ============================================================================
# TILE ACCESS AND MANAGEMENT
# ============================================================================
func get_tile(pos: Vector2i) -> FarmTileData:
	"""Get tile at position, creating it if it doesn't exist"""
	if pos in grid_data:
		return grid_data[pos]
	
	if _is_valid_position(pos):
		var tile: FarmTileData = FarmTileData.new(pos)
		tile.grid_index = GridHelpers.grid_to_index(pos, grid_size.x)
		tile.chunk_id = GridHelpers.grid_to_chunk(pos, CHUNK_SIZE)
		grid_data[pos] = tile
		return tile
	
	return null

func set_tile(pos: Vector2i, tile: FarmTileData) -> bool:
	"""Set tile at position"""
	if not _is_valid_position(pos):
		return false
	
	grid_data[pos] = tile
	_mark_tile_dirty(pos)
	tile_changed.emit(pos, tile)
	return true

func has_tile(pos: Vector2i) -> bool:
	return pos in grid_data

func remove_tile(pos: Vector2i) -> bool:
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
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_crop_placement(pos, crop_type)
		if not validation.get("valid", false):
			print("[GridManager] Cannot plant crop: %s" % validation.get("reason", "invalid"))
			return false
	
	var tile: FarmTileData = get_tile(pos)
	if not tile:
		return false
	
	if tile.has_crop():
		print("[GridManager] Cannot plant crop - tile already has crop")
		return false
	
	# Require tilled or watered soil for planting
	if tile.state != FarmTileData.TileState.TILLED and tile.state != FarmTileData.TileState.WATERED:
		print("[GridManager] Cannot plant crop - soil not prepared (tilled/watered)")
		return false
	
	tile.crop = {
		"type": crop_type,
		"planted_at": Time.get_unix_time_from_system(),
		"planted_by": player_id,
		"growth_stage": 0,
		"health": 1.0,
		"water_needs": 0.5,
		"maturity_time": _get_crop_maturity_time(crop_type)
	}
	
	tile.state = FarmTileData.TileState.PLANTED
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
	
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_tool_action(pos, "harvester", player_id)
		if not validation.get("valid", false):
			result["reason"] = validation.get("reason", "invalid")
			return result
	
	var tile: FarmTileData = get_tile(pos)
	if not tile or not tile.has_crop():
		result["reason"] = "No crop at position"
		return result
	
	var crop: Dictionary = tile.crop
	
	# Check maturity
	var age: float = Time.get_unix_time_from_system() - float(crop.get("planted_at", 0.0))
	if age < float(crop.get("maturity_time", 0.0)):
		result["reason"] = "Crop not mature yet"
		return result
	
	var base_yield: int = _get_base_yield(String(crop.get("type", "")))
	var quality_modifier: float = _calculate_quality_modifier(tile)
	var final_yield: int = max(1, int(base_yield * quality_modifier))
	
	# Clear crop and set soil back to tilled for convenience
	result["success"] = true
	result["crop_type"] = String(crop.get("type", ""))
	result["yield"] = final_yield
	result["quality"] = quality_modifier
	
	tile.crop = {}
	if tile.state == FarmTileData.TileState.PLANTED:
		tile.state = FarmTileData.TileState.TILLED
	_mark_tile_dirty(pos)
	
	print("[GridManager] Harvested %d %s at %s" % [final_yield, result["crop_type"], pos])
	crop_harvested.emit(pos, result["crop_type"], final_yield)
	return result

# ============================================================================
# SOIL MANAGEMENT
# ============================================================================
func till_soil(pos: Vector2i, player_id: int = -1) -> bool:
	"""Till soil at position"""
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_tool_action(pos, "hoe", player_id)
		if not validation.get("valid", false):
			print("[GridManager] Cannot till soil: %s" % validation.get("reason", "invalid"))
			return false
	
	var tile: FarmTileData = get_tile(pos)
	if not tile:
		return false
	
	if tile.has_crop() or tile.has_machine():
		print("[GridManager] Cannot till soil - tile occupied")
		return false
	
	tile.state = FarmTileData.TileState.TILLED
	_mark_tile_dirty(pos)
	print("[GridManager] Tilled soil at %s" % pos)
	return true

func water_tile(pos: Vector2i, amount: float = 0.3, player_id: int = -1) -> bool:
	"""Add water to tile. Amount is 0..1 fraction; converts to 0..100 scale."""
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_tool_action(pos, "watering_can", player_id)
		if not validation.get("valid", false):
			print("[GridManager] Cannot water tile: %s" % validation.get("reason", "invalid"))
			return false
	
	var tile: FarmTileData = get_tile(pos)
	if not tile:
		return false
	
	# Convert 0..1 fraction to 0..100 chemistry scale
	var delta: float = clamp(amount, 0.0, 1.0) * 100.0
	tile.water_content = clamp(tile.water_content + delta, 0.0, 100.0)
	
	# If soil is just tilled and no crop, we can mark as WATERED
	if not tile.has_crop() and tile.state == FarmTileData.TileState.TILLED:
		tile.state = FarmTileData.TileState.WATERED
	
	_mark_tile_dirty(pos)
	return true

# ============================================================================
# MACHINE MANAGEMENT
# ============================================================================
func place_machine(pos: Vector2i, machine_type: String, player_id: int = -1) -> bool:
	"""Place a machine at position"""
	if grid_validator:
		var validation: Dictionary = grid_validator.validate_machine_placement(pos, machine_type)
		if not validation.get("valid", false):
			print("[GridManager] Cannot place machine: %s" % validation.get("reason", "invalid"))
			return false
	
	var tile: FarmTileData = get_tile(pos)
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
	tile.state = FarmTileData.TileState.BLOCKED
	
	_mark_tile_dirty(pos)
	print("[GridManager] Placed %s at %s" % [machine_type, pos])
	machine_placed.emit(pos, machine_type)
	return true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _is_valid_position(pos: Vector2i) -> bool:
	if grid_validator and grid_validator.has_method("is_valid_position"):
		return grid_validator.is_valid_position(pos)
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

func _mark_tile_dirty(pos: Vector2i) -> void:
	if not pos in dirty_tiles:
		dirty_tiles.append(pos)
	var cpos: Vector2i = chunk_manager.mark_dirty_by_pos(pos) if chunk_manager else GridHelpers.grid_to_chunk(pos, CHUNK_SIZE)
	emit_signal("chunk_dirty", cpos)

func _get_crop_maturity_time(crop_type: String) -> float:
	match crop_type:
		"lettuce": return 30.0
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

func _calculate_quality_modifier(tile: FarmTileData) -> float:
	var quality: float = 1.0
	
	# Water factor (use 0..100 scale -> 0..1)
	var water_frac: float = clamp(tile.water_content / 100.0, 0.0, 1.0)
	quality *= (0.5 + water_frac * 0.5)
	
	# Fertility proxy from organic matter (10.0 ~ neutral 1.0)
	var fert_factor: float = clamp(tile.organic_matter / 10.0, 0.5, 1.5)
	quality *= fert_factor
	
	# pH factor (optimal around 6.5-7.5)
	var ph_diff: float = abs(tile.ph_level - 7.0)
	quality *= max(0.5, 1.0 - ph_diff * 0.1)
	
	return clamp(quality, 0.1, 2.0)
	
func is_chunk_dirty(chunk_id: Vector2i) -> bool:
	return chunk_manager != null and chunk_manager.is_chunk_dirty(chunk_id)

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
		"version": 2
	}

func deserialize_grid(data: Dictionary) -> void:
	grid_data.clear()
	if "grid_size" in data:
		grid_size = data["grid_size"]
		# Reconfigure fence and chunks when size changes
		fence_bounds = Rect2i(Vector2i.ZERO, grid_size)
		if chunk_manager:
			chunk_manager.set_config(CHUNK_SIZE, grid_size)
		if grid_validator:
			if grid_validator.has_method("set_grid_size"):
				grid_validator.set_grid_size(grid_size)
			if grid_validator.has_method("set_fence_bounds"):
				grid_validator.set_fence_bounds(fence_bounds)
	if "tiles" in data:
		for pos_str in data["tiles"]:
			var parts: Array = pos_str.strip_edges("()").split(",")
			if parts.size() == 2:
				var pos: Vector2i = Vector2i(parts[0].to_int(), parts[1].to_int())
				var tile: FarmTileData = FarmTileData.new(pos)
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
	var tile: FarmTileData = get_tile(pos)
	if tile:
		print("Tile at %s: %s" % [pos, tile.to_dict()])
	else:
		print("No tile at %s" % pos)
