extends RefCounted
class_name SoilChemistry
# SoilChemistry.gd - Chemistry orchestration (stubs/no-op for now)
# Manages NPK, pH, water, and contamination interactions.

# ============================================================================
# PROPERTIES
# ============================================================================
var npk: NPKManager = null
var ph_manager: PHManager = null
var water_manager: WaterManager = null
var contamination_manager: ContaminationManager = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _init() -> void:
	npk = NPKManager.new()
	ph_manager = PHManager.new()
	water_manager = WaterManager.new()
	contamination_manager = ContaminationManager.new()

# ============================================================================
# CORE FUNCTIONALITY (no-op safe stubs)
# ============================================================================
func evaluate_tile_quality(tile: FarmTileData) -> float:
	"""Return a 0.1..2.0 quality factor based on chemistry (stubbed)."""
	if tile == null:
		return 1.0
	# Simple placeholder using pH proximity to 7.0 and basic NPK index
	var ph_factor: float = ph_manager.get_ph_factor(tile)
	var npk_idx: float = npk.compute_npk_index(tile) # 0..1
	var water_factor: float = water_manager.get_water_factor(tile) # 0.5..1.0
	var contam_factor: float = contamination_manager.get_contamination_factor(tile) # 0..1 (1.0 default)
	var q: float = 1.0 * ph_factor * (0.5 + 0.5 * npk_idx) * water_factor * contam_factor
	return clamp(q, 0.1, 2.0)

func process_evaporation(tile: FarmTileData, delta: float) -> void:
	"""Apply water evaporation to a tile (no-op safe)."""
	if tile == null:
		return
	water_manager.evaporation(tile, delta)
	clamp_tile(tile)

func apply_fertilizer(tile: FarmTileData, fertilizer_id: String, amount: float) -> void:
	"""Apply a fertilizer effect to the tile (stubbed)."""
	if tile == null:
		return
	npk.apply_fertilizer(tile, fertilizer_id, amount)
	clamp_tile(tile)

func clamp_tile(tile: FarmTileData) -> void:
	"""Clamp chemistry values into safe ranges."""
	if tile == null:
		return
	tile.nitrogen = clamp(tile.nitrogen, 0.0, 100.0)
	tile.phosphorus = clamp(tile.phosphorus, 0.0, 100.0)
	tile.potassium = clamp(tile.potassium, 0.0, 100.0)
	tile.ph_level = clamp(tile.ph_level, 3.0, 9.0)
	tile.water_content = clamp(tile.water_content, 0.0, 100.0)
	tile.organic_matter = clamp(tile.organic_matter, 0.0, 100.0)
	tile.contamination_level = clamp(tile.contamination_level, 0.0, 100.0)

func process_batch(tiles: Array[FarmTileData], delta: float) -> void:
	"""Batch-process a set of tiles (no-op safe)."""
	if tiles == null:
		return
	for t in tiles:
		process_evaporation(t, delta)

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"npk": npk != null,
		"ph": ph_manager != null,
		"water": water_manager != null,
		"contam": contamination_manager != null
	}
