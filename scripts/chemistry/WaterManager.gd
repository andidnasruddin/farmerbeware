extends RefCounted
class_name WaterManager
# WaterManager.gd - Water/moisture helpers (stubs)

const EVAP_RATE_PER_SEC: float = 0.0	# no-op default

func evaporation(tile: FarmTileData, delta: float) -> void:
	if tile == null or delta <= 0.0:
		return
	# No-op by default; set EVAP_RATE_PER_SEC > 0 to enable slow decay.
	tile.water_content = max(0.0, tile.water_content - (EVAP_RATE_PER_SEC * delta))

func irrigate(tile: FarmTileData, amount_0_1: float) -> void:
	if tile == null or amount_0_1 <= 0.0:
		return
	var delta: float = clamp(amount_0_1, 0.0, 1.0) * 100.0
	tile.water_content = clamp(tile.water_content + delta, 0.0, 100.0)

func get_water_factor(tile: FarmTileData) -> float:
	"""Return 0.5..1.0 factor based on water_content (0..100)."""
	if tile == null:
		return 1.0
	var frac: float = clamp(tile.water_content / 100.0, 0.0, 1.0)
	return 0.5 + 0.5 * frac

