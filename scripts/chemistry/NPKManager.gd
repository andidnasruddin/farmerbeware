extends RefCounted
class_name NPKManager
# NPKManager.gd - Nutrient (N/P/K) helpers (stubs)

# =========================================================================
# CORE (stubs)
# =========================================================================
func compute_npk_index(tile: FarmTileData) -> float:
	"""Return 0..1 index summarizing N/P/K balance (stubbed)."""
	if tile == null:
		return 0.5
	var avg: float = (tile.nitrogen + tile.phosphorus + tile.potassium) / 3.0
	return clamp(avg / 100.0, 0.0, 1.0)

func apply_fertilizer(tile: FarmTileData, fertilizer_id: String, amount: float) -> void:
	"""Apply a simple NPK bump (no-op safe)."""
	if tile == null or amount <= 0.0:
		return
	match fertilizer_id:
		"nitrogen_boost":
			tile.nitrogen += amount
		"phosphorus_boost":
			tile.phosphorus += amount
		"potassium_boost":
			tile.potassium += amount
		_:
			# Balanced default
			tile.nitrogen += amount * 0.5
			tile.phosphorus += amount * 0.3
			tile.potassium += amount * 0.2

