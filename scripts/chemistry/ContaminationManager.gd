extends RefCounted
class_name ContaminationManager
# ContaminationManager.gd - Contamination helpers (stubs)

func spread(tile: FarmTileData, delta: float) -> void:
	# No-op placeholder for contamination spread.
	pass

func get_contamination_factor(tile: FarmTileData) -> float:
	"""Return a 0..1 multiplier lowering quality if contaminated.
	Currently returns 1.0 (no effect)."""
	return 1.0

