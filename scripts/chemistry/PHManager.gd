extends RefCounted
class_name PHManager
# PHManager.gd - pH helpers (stubs)

func adjust_ph(tile: FarmTileData, delta: float) -> void:
	if tile == null or delta == 0.0:
		return
	tile.ph_level += delta

func get_ph_factor(tile: FarmTileData) -> float:
	"""Return a 0.5..1.0 factor peaking near pH 7.0 (stub)."""
	if tile == null:
		return 1.0
	var diff: float = abs(tile.ph_level - 7.0)
	return clamp(1.0 - diff * 0.1, 0.5, 1.0)

