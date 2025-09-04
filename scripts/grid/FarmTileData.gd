extends Resource
class_name FarmTileData
# FarmTileData.gd - Resource for grid tile state and metadata
# Holds identity, state, chemistry, and history. No heavy logic here.

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
enum TileState {
	EMPTY,   # default
	TILLED,
	PLANTED,
	WATERED,
	BLOCKED, # machine/building placed
	PATH,
	FENCE
}

# ============================================================================
# SIGNALS
# ============================================================================

# (none)

# ============================================================================
# PROPERTIES
# ============================================================================
# Identity
@export var position: Vector2i = Vector2i.ZERO
@export var chunk_id: Vector2i = Vector2i.ZERO
@export var grid_index: int = -1
@export var is_fenced: bool = false

# State
@export var state: int = TileState.EMPTY

# Contents (keep gameplay compatibility with GridManager)
@export var crop: Dictionary = {}		# {type, planted_at, planted_by, growth_stage, health, water_needs, maturity_time}
@export var machine: Dictionary = {}	# {type, placed_at, placed_by, health, efficiency, last_used}
@export var item: Dictionary = {}

# Chemistry (stub fields; calculations come later)
@export var nitrogen: float = 50.0		# 0..100
@export var phosphorus: float = 50.0	# 0..100
@export var potassium: float = 50.0		# 0..100
@export var ph_level: float = 7.0		# 3.0..9.0 typical
@export var water_content: float = 0.0	# 0..100
@export var organic_matter: float = 10.0
@export var fertilizer_type: String = ""
@export var contamination_level: float = 0.0

# History
@export var previous_crops: Array[String] = []
@export var last_harvest_quality: int = 0
@export var same_crop_count: int = 0
@export var fallow_days: int = 0
@export var total_harvests: int = 0

# Misc
var last_modified: float = 0.0

# ============================================================================
# INITIALIZATION
# ============================================================================
func _init(pos: Vector2i = Vector2i.ZERO) -> void:
	position = pos
	last_modified = Time.get_unix_time_from_system()

func has_crop() -> bool:
	return not crop.is_empty()

func has_machine() -> bool:
	return not machine.is_empty()

func has_item() -> bool:
	return not item.is_empty()

func is_empty() -> bool:
	return not has_crop() and not has_machine() and not has_item()

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func set_state(new_state: int) -> void:
	"""Set tile state and refresh timestamp"""
	state = new_state
	_touch()

func set_position(pos: Vector2i) -> void:
	position = pos
	_touch()

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func to_dict() -> Dictionary:
	return {
		"position": position,
		"chunk_id": chunk_id,
		"grid_index": grid_index,
		"is_fenced": is_fenced,
		"state": state,
		"crop": crop,
		"machine": machine,
		"item": item,
		"nitrogen": nitrogen,
		"phosphorus": phosphorus,
		"potassium": potassium,
		"ph_level": ph_level,
		"water_content": water_content,
		"organic_matter": organic_matter,
		"fertilizer_type": fertilizer_type,
		"contamination_level": contamination_level,
		"previous_crops": previous_crops,
		"last_harvest_quality": last_harvest_quality,
		"same_crop_count": same_crop_count,
		"fallow_days": fallow_days,
		"total_harvests": total_harvests,
		"last_modified": last_modified
	}

func from_dict(data: Dictionary) -> void:
	position = data.get("position", position)
	chunk_id = data.get("chunk_id", chunk_id)
	grid_index = int(data.get("grid_index", grid_index))
	is_fenced = bool(data.get("is_fenced", is_fenced))
	state = int(data.get("state", state))
	crop = data.get("crop", crop)
	machine = data.get("machine", machine)
	item = data.get("item", item)
	nitrogen = float(data.get("nitrogen", nitrogen))
	phosphorus = float(data.get("phosphorus", phosphorus))
	potassium = float(data.get("potassium", potassium))
	ph_level = float(data.get("ph_level", ph_level))
	water_content = float(data.get("water_content", water_content))
	organic_matter = float(data.get("organic_matter", organic_matter))
	fertilizer_type = String(data.get("fertilizer_type", fertilizer_type))
	contamination_level = float(data.get("contamination_level", contamination_level))
	previous_crops = data.get("previous_crops", previous_crops)
	last_harvest_quality = int(data.get("last_harvest_quality", last_harvest_quality))
	same_crop_count = int(data.get("same_crop_count", same_crop_count))
	fallow_days = int(data.get("fallow_days", fallow_days))
	total_harvests = int(data.get("total_harvests", total_harvests))
	last_modified = float(data.get("last_modified", Time.get_unix_time_from_system()))

	# --- Legacy migration handling ---
	# Older tiles used 0..1 water_level and a single fertility value, plus is_tilled flag/state via booleans.
	if data.has("water_level") and not data.has("water_content"):
		var wl: float = clamp(float(data["water_level"]), 0.0, 1.0)
		water_content = wl * 100.0

	if data.has("fertility") and not data.has("organic_matter"):
		# Map legacy fertility (0..1) to organic_matter (approx 0..100)
		var fert: float = float(data["fertility"])  # assume 0..1
		organic_matter = clamp(fert * 20.0, 0.0, 100.0)

	if not data.has("state"):
		# Derive a best-effort state from legacy fields
		var derived: int = TileState.EMPTY
		if machine is Dictionary and not machine.is_empty():
			derived = TileState.BLOCKED
		elif crop is Dictionary and not crop.is_empty():
			derived = TileState.PLANTED
		elif bool(data.get("is_tilled", false)):
			derived = TileState.TILLED
		state = derived

func get_debug_info() -> Dictionary:
	return {
		"pos": position,
		"state": state,
		"chemistry": {
			"N": nitrogen, "P": phosphorus, "K": potassium,
			"pH": ph_level, "H2O": water_content, "OM": organic_matter
		},
		"hist": {
			"prev": previous_crops,
			"quality": last_harvest_quality,
			"harvests": total_harvests
		}
	}

func _touch() -> void:
	last_modified = Time.get_unix_time_from_system()
