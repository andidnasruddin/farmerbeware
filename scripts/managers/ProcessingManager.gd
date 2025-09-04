extends Node
# ProcessingManager.gd - AUTOLOAD #9
# Manages processing machines, recipe execution, and job timing.
# Dependencies: GameManager (autoload #1), TimeManager (day flow), EventManager (global events), CropManager (optional inputs)

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
enum MachineState { IDLE, RUNNING, PAUSED, JAMMED }

const MAX_CONCURRENT_JOBS: int = 8
const DEFAULT_PROCESS_DURATION: float = 10.0

# ============================================================================
# DATA STRUCTURES
# ============================================================================
# Machine data shape:
# machines[machine_id: String] = {
#   "id": String,
#   "type": String,
#   "position": Vector2i,
#   "state": int,                 # MachineState
#   "inventory": {                # Simplified store
#       "inputs": Dictionary,     # String -> int
#       "outputs": Dictionary     # String -> int
#   }
# }
#
# Recipe data shape:
# recipes[recipe_id: String] = {
#   "inputs": Dictionary,         # String -> int
#   "outputs": Dictionary,        # String -> int
#   "duration": float             # seconds
# }
#
# Active job data shape:
# active_jobs[machine_id: String] = {
#   "recipe_id": String,
#   "start_time": float,
#   "duration": float,
#   "end_time": float,
#   "progress": float             # 0.0 - 1.0
# }

# ============================================================================
# SIGNALS
# ============================================================================
signal machine_registered(machine_id: String)
signal machine_unregistered(machine_id: String)
signal machine_state_changed(machine_id: String, from_state: int, to_state: int)

signal processing_started(machine_id: String, recipe_id: String, duration: float)
signal processing_progress(machine_id: String, progress: float)
signal processing_completed(machine_id: String, recipe_id: String, output_items: Dictionary)
signal processing_failed(machine_id: String, reason: String)
signal inventory_changed(machine_id: String)

# ============================================================================
# PROPERTIES
# ============================================================================
var machines: Dictionary = {}         # String -> Dictionary
var recipes: Dictionary = {}          # String -> Dictionary
var active_jobs: Dictionary = {}      # machine_id -> job dict

var game_manager: Node = null
var time_manager: Node = null
var event_manager: Node = null
var crop_manager: Node = null

var processing_enabled: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "ProcessingManager"
	print("[ProcessingManager] Initializing as Autoload #9...")

	# Connect to other systems
	game_manager = GameManager
	time_manager = TimeManager
	crop_manager = CropManager

	# Be defensive when binding events system
	event_manager = get_node_or_null("/root/EventManager")
	if event_manager == null:
		event_manager = get_node_or_null("/root/EventBus")  # optional fallback

	if game_manager:
		if game_manager.has_method("register_system"):
			game_manager.register_system("ProcessingManager", self)
		if game_manager.has_signal("state_changed"):
			game_manager.state_changed.connect(_on_game_state_changed)
		print("[ProcessingManager] Registered with GameManager")
	else:
		print("[ProcessingManager] WARNING: GameManager not found")

	if time_manager:
		if time_manager.has_signal("day_started"):
			time_manager.day_started.connect(_on_day_started)
		if time_manager.has_signal("phase_changed"):
			time_manager.phase_changed.connect(_on_phase_changed)
		print("[ProcessingManager] TimeManager connected")
	else:
		print("[ProcessingManager] WARNING: TimeManager not found")

	if event_manager:
		print("[ProcessingManager] Event system connected")
	else:
		print("[ProcessingManager] WARNING: Event system not found")

	if crop_manager:
		print("[ProcessingManager] CropManager connected")

	set_process(true)
	_initialize_processing()
	print("[ProcessingManager] Initialization complete")

func _initialize_processing() -> void:
	"""Initialize internal stores and example defaults (no real recipes yet)."""
	machines.clear()
	recipes.clear()
	active_jobs.clear()

	# Placeholder: add a simple default recipe so systems can test flow
	recipes["basic_flour"] = {
		"inputs": {"wheat": 3},
		"outputs": {"flour": 1},
		"duration": DEFAULT_PROCESS_DURATION
	}

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func register_machine(machine_id: String, machine_type: String, position: Vector2i = Vector2i.ZERO) -> bool:
	"""Register a new machine with empty inventory."""
	if machines.has(machine_id):
		return false

	machines[machine_id] = {
		"id": machine_id,
		"type": machine_type,
		"position": position,
		"state": MachineState.IDLE,
		"inventory": {"inputs": {}, "outputs": {}}
	}
	emit_signal("machine_registered", machine_id)
	_emit_event("machine_registered", {"machine_id": machine_id, "machine_type": machine_type})
	return true

func unregister_machine(machine_id: String) -> bool:
	"""Remove a machine; cancels any running job."""
	if not machines.has(machine_id):
		return false

	if active_jobs.has(machine_id):
		_cancel_job(machine_id, "machine_unregistered")

	machines.erase(machine_id)
	emit_signal("machine_unregistered", machine_id)
	_emit_event("machine_unregistered", {"machine_id": machine_id})
	return true

func add_recipe(recipe_id: String, data: Dictionary) -> void:
	"""Add or replace a recipe definition."""
	if not data.has("inputs") or not data.has("outputs"):
		print("[ProcessingManager] WARNING: Recipe missing 'inputs' or 'outputs'")
	if not data.has("duration"):
		data["duration"] = DEFAULT_PROCESS_DURATION
	recipes[recipe_id] = data

func can_start_processing(machine_id: String, recipe_id: String) -> bool:
	"""Check if a machine can start a recipe (exists, idle, has inputs)."""
	if not processing_enabled:
		return false
	if not machines.has(machine_id):
		return false
	if active_jobs.has(machine_id):
		return false
	if not recipes.has(recipe_id):
		return false

	var needed: Dictionary = recipes[recipe_id]["inputs"]
	var inv: Dictionary = machines[machine_id]["inventory"]["inputs"]
	for item in needed.keys():
		var req: int = int(needed[item])
		var have: int = int(inv.get(item, 0))
		if have < req:
			return false
	return true

func start_processing(machine_id: String, recipe_id: String) -> bool:
	"""Start processing a recipe on a machine and consume inputs."""
	if not can_start_processing(machine_id, recipe_id):
		_emit_event("processing_failed", {"machine_id": machine_id, "recipe_id": recipe_id, "reason": "precheck_failed"})
		return false

	var recipe: Dictionary = recipes[recipe_id]
	var inv_inputs: Dictionary = machines[machine_id]["inventory"]["inputs"]

	# Consume inputs
	for item in recipe["inputs"].keys():
		inv_inputs[item] = int(inv_inputs.get(item, 0)) - int(recipe["inputs"][item])
		if inv_inputs[item] <= 0:
			inv_inputs.erase(item)

	var now: float = Time.get_unix_time_from_system()
	var duration: float = float(recipe.get("duration", DEFAULT_PROCESS_DURATION))

	active_jobs[machine_id] = {
		"recipe_id": recipe_id,
		"start_time": now,
		"duration": duration,
		"end_time": now + duration,
		"progress": 0.0
	}

	_set_machine_state(machine_id, MachineState.RUNNING)
	emit_signal("inventory_changed", machine_id)
	emit_signal("processing_started", machine_id, recipe_id, duration)
	_emit_event("processing_started", {"machine_id": machine_id, "recipe_id": recipe_id, "duration": duration})
	return true

func cancel_processing(machine_id: String) -> bool:
	"""Cancel the current job (no refund logic here)."""
	if not active_jobs.has(machine_id):
		return false
	_cancel_job(machine_id, "user_cancelled")
	return true

func _process(delta: float) -> void:
	"""Advance active jobs while game is playing."""
	if not processing_enabled:
		return
	if game_manager and game_manager.has_node(".") and game_manager.current_state != GameManager.GameState.PLAYING:
		return

	if active_jobs.is_empty():
		return

	var now: float = Time.get_unix_time_from_system()
	for machine_id in active_jobs.keys():
		var job: Dictionary = active_jobs[machine_id]
		var duration: float = max(0.001, float(job["duration"]))
		var elapsed: float = now - float(job["start_time"])
		var progress: float = clamp(elapsed / duration, 0.0, 1.0)

		if progress != float(job["progress"]):
			job["progress"] = progress
			active_jobs[machine_id] = job
			emit_signal("processing_progress", machine_id, progress)

		if now >= float(job["end_time"]):
			_complete_job(machine_id, job)

# ============================================================================
# SYSTEM INTEGRATION
# ============================================================================
func _on_day_started(day_number: int) -> void:
	"""Handle new day setup for machines."""
	# Example: clear jams or apply daily maintenance here (placeholder)
	pass

func _on_phase_changed(from_phase: int, to_phase: int) -> void:
	"""React to time phases if needed (placeholder)."""
	pass

func _on_game_state_changed(from_state: int, to_state: int) -> void:
	"""Pause/Resume behavior can be added here (placeholder)."""
	pass

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func add_item_to_machine(machine_id: String, item_id: String, amount: int, to_inputs: bool = true) -> bool:
	"""Add items into a machine inventory."""
	if not machines.has(machine_id) or amount <= 0:
		return false
	var slot: String = "inputs" if to_inputs else "outputs"
	var inv: Dictionary = machines[machine_id]["inventory"][slot]
	inv[item_id] = int(inv.get(item_id, 0)) + amount
	emit_signal("inventory_changed", machine_id)
	return true

func remove_item_from_machine(machine_id: String, item_id: String, amount: int, from_outputs: bool = true) -> bool:
	"""Remove items from machine inventory."""
	if not machines.has(machine_id) or amount <= 0:
		return false
	var slot: String = "outputs" if from_outputs else "inputs"
	var inv: Dictionary = machines[machine_id]["inventory"][slot]
	if int(inv.get(item_id, 0)) < amount:
		return false
	inv[item_id] = int(inv[item_id]) - amount
	if inv[item_id] <= 0:
		inv.erase(item_id)
	emit_signal("inventory_changed", machine_id)
	return true

func _complete_job(machine_id: String, job: Dictionary) -> void:
	"""Finalize a job, grant outputs, and return machine to IDLE."""
	if not machines.has(machine_id):
		active_jobs.erase(machine_id)
		return

	var recipe_id: String = String(job["recipe_id"])
	var recipe: Dictionary = recipes.get(recipe_id, {})
	var outputs: Dictionary = recipe.get("outputs", {})

	var inv_outputs: Dictionary = machines[machine_id]["inventory"]["outputs"]
	for item in outputs.keys():
		inv_outputs[item] = int(inv_outputs.get(item, 0)) + int(outputs[item])

	active_jobs.erase(machine_id)
	_set_machine_state(machine_id, MachineState.IDLE)
	emit_signal("inventory_changed", machine_id)
	emit_signal("processing_completed", machine_id, recipe_id, outputs)
	_emit_event("processing_complete", {"machine_id": machine_id, "recipe_id": recipe_id, "outputs": outputs})

func _cancel_job(machine_id: String, reason: String) -> void:
	"""Cancel a running job and mark machine idle."""
	active_jobs.erase(machine_id)
	_set_machine_state(machine_id, MachineState.IDLE)
	emit_signal("processing_failed", machine_id, reason)
	_emit_event("processing_failed", {"machine_id": machine_id, "reason": reason})

func _set_machine_state(machine_id: String, new_state: int) -> void:
	"""Update machine state and emit state change if different."""
	if not machines.has(machine_id):
		return
	var from_state: int = int(machines[machine_id]["state"])
	if from_state == new_state:
		return
	machines[machine_id]["state"] = new_state
	emit_signal("machine_state_changed", machine_id, from_state, new_state)

func _emit_event(event_name: String, payload: Dictionary) -> void:
	"""Dispatch an event to EventManager if available."""
	if event_manager == null:
		return
	if event_manager.has_method("emit"):
		event_manager.emit(event_name, payload)
	elif event_manager.has_method("dispatch"):
		event_manager.dispatch(event_name, payload)

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"machines": machines.size(),
		"active_jobs": active_jobs.size(),
		"recipes": recipes.size(),
		"processing_enabled": processing_enabled,
		"connected_time": time_manager != null,
		"connected_event": event_manager != null,
		"connected_game": game_manager != null
	}
