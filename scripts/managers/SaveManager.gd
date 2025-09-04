extends Node
# SaveManager.gd - AUTOLOAD #11
# Handles save/load of run state and meta, autosave timing, and listing/deleting saves.
# Dependencies: GameManager (state/money), TimeManager (day/phases), EventManager (optional dispatch)

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
const SAVE_DIR: String = "user://saves"
const META_FILE: String = "user://meta.json"
const SAVE_EXTENSION: String = ".json"
const SAVE_VERSION: String = "1.0"

const DEFAULT_AUTOSAVE_INTERVAL: float = 120.0	# seconds

# ============================================================================
# DATA STRUCTURES
# ============================================================================
# Save file (JSON):
# {
# 	"version": String,
# 	"timestamp": float,				# unix time
# 	"slot": String,
# 	"game": {						# minimal run state stub (expand later)
# 		"state": String,
# 		"money": int,
# 		"day": int
# 	}
# }
#
# Meta file (JSON):
# {
# 	"last_slot": String,
# 	"options": Dictionary
# }

# ============================================================================
# SIGNALS
# ============================================================================
signal save_started(slot: String)
signal save_completed(slot: String, path: String)
signal save_failed(slot: String, reason: String)

signal load_started(slot: String)
signal load_completed(slot: String)
signal load_failed(slot: String, reason: String)

signal autosave_triggered(slot: String)
signal saves_listed(files: Array[String])

# ============================================================================
# PROPERTIES
# ============================================================================
var game_manager: Node = null
var time_manager: Node = null
var event_manager: Node = null

var current_slot: String = "slot_1"
var autosave_enabled: bool = true
var autosave_interval: float = DEFAULT_AUTOSAVE_INTERVAL
var _last_autosave_time: float = 0.0

# Cache last saved data (for quick access / debugging)
var _last_saved_data: Dictionary = {}
var _last_loaded_data: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "SaveManager"
	print("[SaveManager] Initializing as Autoload #11...")

	# Connect systems
	game_manager = GameManager
	time_manager = TimeManager
	event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		event_manager = get_node_or_null("/root/EventBus")	# fallback naming

	# Register with GameManager
	if game_manager and game_manager.has_method("register_system"):
		game_manager.register_system("SaveManager", self)
		print("[SaveManager] Registered with GameManager")

	# Ensure save directory exists
	_ensure_save_dir()

	# Load meta to restore last slot and options
	_load_meta()

	set_process(true)
	print("[SaveManager] Initialization complete")

func _process(_delta: float) -> void:
	# Simple time-based autosave (paused if disabled)
	if not autosave_enabled:
		return
	var now: float = Time.get_unix_time_from_system()
	if now - _last_autosave_time >= autosave_interval:
		_auto_save()

# ============================================================================
# CORE FUNCTIONALITY - Saving/Loading
# ============================================================================
func save_game(slot: String = current_slot) -> bool:
	"""Serialize minimal run state and write to disk."""
	emit_signal("save_started", slot)
	var data: Dictionary = _gather_game_state(slot)
	var path: String = _get_save_path(slot)

	if not _write_json(path, data):
		emit_signal("save_failed", slot, "write_error")
		print("[SaveManager] ERROR: Failed writing save to ", path)
		return false

	_last_saved_data = data
	_write_meta({"last_slot": slot})
	emit_signal("save_completed", slot, path)
	print("[SaveManager] Saved slot '", slot, "' to ", path)
	return true

func load_game(slot: String = current_slot) -> bool:
	"""Read save from disk and apply basic state safely."""
	emit_signal("load_started", slot)
	var path: String = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		emit_signal("load_failed", slot, "not_found")
		print("[SaveManager] WARNING: Save not found at ", path)
		return false

	var data := _read_json(path)
	if data.is_empty():
		emit_signal("load_failed", slot, "parse_error")
		print("[SaveManager] ERROR: Invalid save data at ", path)
		return false

	_last_loaded_data = data
	_apply_game_state(data.get("game", {}))
	current_slot = slot
	_write_meta({"last_slot": current_slot})
	emit_signal("load_completed", slot)
	print("[SaveManager] Loaded slot '", slot, "' from ", path)
	return true

func quick_save() -> bool:
	return save_game(current_slot)

func quick_load() -> bool:
	return load_game(current_slot)

func list_saves() -> Array[String]:
	"""Return list of save files in SAVE_DIR (filenames without extension)."""
	var result: Array[String] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		emit_signal("saves_listed", result)
		return result

	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name == "":
			break
		if dir.current_is_dir():
			continue
		if name.ends_with(SAVE_EXTENSION):
			result.append(name.substr(0, name.length() - SAVE_EXTENSION.length()))
	dir.list_dir_end()

	emit_signal("saves_listed", result)
	return result

func delete_save(slot: String) -> bool:
	var path: String = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		print("[SaveManager] ERROR: Failed to delete ", path)
		return false
	if slot == current_slot:
		current_slot = "slot_1"
	_write_meta({"last_slot": current_slot})
	print("[SaveManager] Deleted slot '", slot, "'")
	return true

# ============================================================================
# SYSTEM INTEGRATION
# ============================================================================
func set_autosave_enabled(enabled: bool) -> void:
	autosave_enabled = enabled
	if enabled:
		_last_autosave_time = Time.get_unix_time_from_system()

func set_autosave_interval(seconds: float) -> void:
	autosave_interval = max(5.0, seconds)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _auto_save() -> void:
	_last_autosave_time = Time.get_unix_time_from_system()
	if save_game(current_slot):
		emit_signal("autosave_triggered", current_slot)

func _gather_game_state(slot: String) -> Dictionary:
	# Collect minimal game state; expand as other systems define APIs
	var state_str: String = "UNKNOWN"
	var money_val: int = 0
	var day_num: int = 1

	if game_manager:
		# Try to capture state string (fallback to enum int)
		if "current_state" in game_manager:
			var cs = game_manager.current_state
			state_str = str(cs)	# callers can stringify enums
		if "current_money" in game_manager:
			money_val = int(game_manager.current_money)

	if time_manager and "current_day" in time_manager:
		day_num = int(time_manager.current_day)

	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"slot": slot,
		"game": {
			"state": state_str,
			"money": money_val,
			"day": day_num
		}
	}

func _apply_game_state(game: Dictionary) -> void:
	# Apply only what is safe at this stage; expand later
	if game_manager:
		if "money" in game and "current_money" in game_manager:
			game_manager.current_money = int(game["money"])
		# Optionally request state transition in future; for now, keep current flow

	if time_manager:
		# If TimeManager supports day override later, apply here
		pass

func _ensure_save_dir() -> void:
	var ok := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if ok != OK and ok != ERR_ALREADY_IN_USE and ok != ERR_ALREADY_EXISTS:
		print("[SaveManager] WARNING: Could not ensure save dir: ", SAVE_DIR)

func _get_save_path(slot: String) -> String:
	return SAVE_DIR + "/" + slot + SAVE_EXTENSION

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parse := JSON.new()
	var err := parse.parse(text)
	if err != OK:
		return {}
	var data = parse.get_data()
	return data if typeof(data) == TYPE_DICTIONARY else {}

func _write_json(path: String, data: Dictionary) -> bool:
	var text := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true

func _load_meta() -> void:
	if not FileAccess.file_exists(META_FILE):
		return
	var meta := _read_json(META_FILE)
	if meta.is_empty():
		return
	if "last_slot" in meta:
		current_slot = String(meta["last_slot"])

func _write_meta(extra: Dictionary = {}) -> void:
	var meta := {
		"last_slot": current_slot,
		"options": {}
	}
	for k in extra.keys():
		meta[k] = extra[k]
	_write_json(META_FILE, meta)

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"current_slot": current_slot,
		"autosave_enabled": autosave_enabled,
		"autosave_interval": autosave_interval,
		"last_autosave": _last_autosave_time > 0.0
	}
