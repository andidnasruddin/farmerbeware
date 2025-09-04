extends RefCounted
class_name TileUpdate
# TileUpdate.gd - Typed update request for batching tile changes

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
enum UpdateType {
	STATE,
	CHEMISTRY,
	WATER,
	FERTILIZER,
	CONTAMINATION,
	RESET
}

# ============================================================================
# PROPERTIES
# ============================================================================
var position: Vector2i = Vector2i.ZERO
var update_type: int = UpdateType.STATE
var payload: Dictionary = {}		# Additional data for the update
var priority: int = 0				# Lower = sooner
var timestamp: float = 0.0

# ============================================================================
# INITIALIZATION
# ============================================================================
func _init(pos: Vector2i = Vector2i.ZERO, utype: int = UpdateType.STATE, data: Dictionary = {}, prio: int = 0) -> void:
	position = pos
	update_type = utype
	payload = data
	priority = prio
	timestamp = Time.get_unix_time_from_system()

# ============================================================================
# UTILITY
# ============================================================================
func describe() -> String:
	return "TileUpdate(%s, %d, prio=%d)" % [position, update_type, priority]
