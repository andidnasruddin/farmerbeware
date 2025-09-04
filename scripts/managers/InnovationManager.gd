extends Node
# InnovationManager.gd - AUTOLOAD #12
# Manages meta progression: XP/levels, permanent unlocks, and run modifiers.
# Dependencies: GameManager (state), SaveManager (meta persistence via export/import), EventManager (optional dispatch)

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
const SAVE_VERSION: String = "1.0"

# XP curve parameters (simple linear ramp; can be replaced by a table later)
const XP_LEVEL_BASE: int = 100
const XP_LEVEL_STEP: int = 50

# Default run modifier values (1.0 = no change)
const DEFAULT_MODIFIERS := {
	"money_multiplier": 1.0,
	"processing_speed": 1.0,
	"crop_growth": 1.0,
	"reputation_gain": 1.0,
	"drop_chance": 1.0
}

# ============================================================================
# DATA STRUCTURES
# ============================================================================
# Meta state:
# {
# 	"version": String,
# 	"xp": int,
# 	"level": int,
# 	"unlocks": Array[String],
# 	"modifiers": Dictionary
# }

# ============================================================================
# SIGNALS
# ============================================================================
signal xp_changed(current_xp: int, delta: int)
signal level_up(new_level: int)
signal unlock_added(id: String)
signal unlock_removed(id: String)
signal modifiers_applied(modifiers: Dictionary)

# ============================================================================
# PROPERTIES
# ============================================================================
var game_manager: Node = null
var save_manager: Node = null
var event_manager: Node = null

var total_xp: int = 0
var current_level: int = 1

var unlocked: Dictionary = {}	# id -> true
var active_modifiers: Dictionary = DEFAULT_MODIFIERS.duplicate(true)

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "InnovationManager"
	print("[InnovationManager] Initializing as Autoload #12...")

	# Connect to systems
	game_manager = GameManager
	save_manager = get_node_or_null("/root/SaveManager")
	event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		event_manager = get_node_or_null("/root/EventBus")	# optional fallback

	# Register with GameManager
	if game_manager and game_manager.has_method("register_system"):
		game_manager.register_system("InnovationManager", self)
		print("[InnovationManager] Registered with GameManager")

	_initialize_innovation()
	print("[InnovationManager] Initialization complete")

func _initialize_innovation() -> void:
	"""Initialize values"""
	total_xp = 0
	current_level = 1
	unlocked.clear()
	active_modifiers = DEFAULT_MODIFIERS.duplicate(true)

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func add_xp(amount: int, reason: String = "") -> void:
	"""Add XP and handle level ups."""
	if amount <= 0:
		return
	var prev_level: int = current_level
	total_xp += amount
	emit_signal("xp_changed", total_xp, amount)

	# Recompute level based on total XP
	var new_level: int = _compute_level_for_xp(total_xp)
	if new_level > prev_level:
		for lvl in range(prev_level + 1, new_level + 1):
			emit_signal("level_up", lvl)
		current_level = new_level

func unlock(id: String) -> bool:
	"""Unlock a permanent upgrade if not already unlocked."""
	if id.is_empty():
		return false
	if unlocked.has(id):
		return false
	unlocked[id] = true
	emit_signal("unlock_added", id)
	return true

func remove_unlock(id: String) -> bool:
	"""Remove a permanent upgrade."""
	if not unlocked.has(id):
		return false
	unlocked.erase(id)
	emit_signal("unlock_removed", id)
	return true

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func get_unlocks() -> Array[String]:
	var ids: Array[String] = []
	for k in unlocked.keys():
		ids.append(String(k))
	return ids

func apply_run_modifiers() -> void:
	"""Recompute active modifiers from current unlocks and emit update."""
	_reset_modifiers_to_default()

	# Placeholder mapping; expand as your design defines specific IDs
	for id in unlocked.keys():
		var s: String = String(id)
		if s.begins_with("economy_"):
			active_modifiers["money_multiplier"] = float(active_modifiers["money_multiplier"]) * 1.05
		elif s.begins_with("processing_"):
			active_modifiers["processing_speed"] = float(active_modifiers["processing_speed"]) * 1.05
		elif s.begins_with("farming_"):
			active_modifiers["crop_growth"] = float(active_modifiers["crop_growth"]) * 1.05
		elif s.begins_with("reputation_"):
			active_modifiers["reputation_gain"] = float(active_modifiers["reputation_gain"]) * 1.10
		elif s.begins_with("loot_"):
			active_modifiers["drop_chance"] = float(active_modifiers["drop_chance"]) * 1.05

	emit_signal("modifiers_applied", active_modifiers)

func get_active_modifiers() -> Dictionary:
	return active_modifiers

func reset_meta() -> void:
	"""Clear all meta progress (use carefully)."""
	total_xp = 0
	current_level = 1
	unlocked.clear()
	_reset_modifiers_to_default()
	emit_signal("modifiers_applied", active_modifiers)

# ============================================================================
# SYSTEM INTEGRATION
# ============================================================================
func export_meta_state() -> Dictionary:
	"""Return meta progression data for SaveManager to persist."""
	return {
		"version": SAVE_VERSION,
		"xp": total_xp,
		"level": current_level,
		"unlocks": get_unlocks(),
		"modifiers": active_modifiers.duplicate(true)
	}

func import_meta_state(data: Dictionary) -> bool:
	"""Load meta progression data from SaveManager."""
	if data.is_empty():
		return false

	total_xp = int(data.get("xp", 0))
	current_level = max(1, int(data.get("level", _compute_level_for_xp(total_xp))))

	unlocked.clear()
	var arr: Array = data.get("unlocks", [])
	for v in arr:
		unlocked[String(v)] = true

	var mods: Dictionary = data.get("modifiers", {})
	if mods.is_empty():
		apply_run_modifiers()
	else:
		active_modifiers = DEFAULT_MODIFIERS.duplicate(true)
		for k in mods.keys():
			active_modifiers[k] = mods[k]
		emit_signal("modifiers_applied", active_modifiers)
	return true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _compute_level_for_xp(xp: int) -> int:
	"""Compute level from total XP using a simple linear curve."""
	var level: int = 1
	var remaining: int = xp
	while true:
		var req: int = _xp_required_for_level(level)
		if remaining < req:
			break
		remaining -= req
		level += 1
	return level

func _xp_required_for_level(level: int) -> int:
	"""XP required to go from this level to the next."""
	return max(1, XP_LEVEL_BASE + (level - 1) * XP_LEVEL_STEP)

func _reset_modifiers_to_default() -> void:
	active_modifiers = DEFAULT_MODIFIERS.duplicate(true)

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"xp": total_xp,
		"level": current_level,
		"unlocks": get_unlocks(),
		"modifiers": active_modifiers
	}
