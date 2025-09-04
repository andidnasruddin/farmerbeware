extends Node
# ContractManager.gd - AUTOLOAD #8
# Manages daily contract listings, acceptance, completion, and event signaling.
# Dependencies: GameManager (autoload #1), TimeManager (day flow), EventBus (global events), CropManager (future validation)

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
const MAX_ACTIVE_CONTRACTS: int = 3

# ============================================================================
# DATA STRUCTURES
# ============================================================================
# Contract dictionary shape:
# {
#   "id": int,
#   "title": String,
#   "reward": int,
#   "expires_on": int,         # day number (inclusive)
#   "requirements": Dictionary # shape TBD (kept generic for now)
# }
#
# Accepted contract progress shape:
# accepted_contracts[id]: {
#   "progress": Dictionary,    # shape TBD; updated as items delivered
#   "accepted_on": int
# }

# ============================================================================
# SIGNALS
# ============================================================================
signal contracts_refreshed(day_number: int)
signal contract_added(contract_id: int)
signal contract_removed(contract_id: int, reason: String)
signal contract_accepted(contract_id: int)
signal contract_completed(contract_id: int, reward: int)
signal contract_failed(contract_id: int, reason: String)
signal progress_updated(contract_id: int, progress: Dictionary)

# ============================================================================
# PROPERTIES
# ============================================================================
var active_contracts: Array[Dictionary] = []
var accepted_contracts: Dictionary = {}      # int -> Dictionary
var current_day: int = 0

var game_manager: Node = null
var time_manager: Node = null
var event_bus: Node = null
var crop_manager: Node = null

var _next_contract_id: int = 1
var _rng := RandomNumberGenerator.new()

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "ContractManager"
	print("[ContractManager] Initializing as Autoload #8...")

	# Connect to other systems (autoloads before #8 are expected to be present)
	game_manager = GameManager if Engine.is_editor_hint() == false else GameManager
	if game_manager:
		print("[ContractManager] GameManager connected")
		if game_manager.has_method("register_system"):
			game_manager.register_system("ContractManager", self)
			print("[ContractManager] Registered with GameManager")
	else:
		print("[ContractManager] WARNING: GameManager not found!")

	time_manager = TimeManager if Engine.is_editor_hint() == false else TimeManager
	if time_manager:
		print("[ContractManager] TimeManager connected")
		if time_manager.has_signal("day_started"):
			time_manager.day_started.connect(_on_day_started)
		else:
			print("[ContractManager] WARNING: TimeManager missing 'day_started' signal")
	else:
		print("[ContractManager] WARNING: TimeManager not found!")

	event_bus = get_node_or_null("/root/EventManager")
	if event_bus == null:
		event_bus = get_node_or_null("/root/EventBus")  # fallback if you ever autoload EventBus directly
	if event_bus:
		print("[ContractManager] Event system connected")
	else:
		print("[ContractManager] WARNING: Event system not found!")

	crop_manager = CropManager if Engine.is_editor_hint() == false else CropManager
	if crop_manager:
		print("[ContractManager] CropManager connected")
	else:
		print("[ContractManager] WARNING: CropManager not found (validation will be limited)")

	_rng.randomize()
	print("[ContractManager] Initialization complete")

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func refresh_contracts_for_day(day_number: int) -> void:
	"""Create daily contract list. Keeps logic simple until Contract system is implemented."""
	current_day = day_number
	active_contracts.clear()
	accepted_contracts.clear()

	for i in range(MAX_ACTIVE_CONTRACTS):
		var contract: Dictionary = _generate_placeholder_contract(day_number)
		active_contracts.append(contract)
		emit_signal("contract_added", contract["id"])

	emit_signal("contracts_refreshed", day_number)
	_emit_event_bus("contracts_refreshed", {"day_number": day_number})
	print("[ContractManager] Contracts refreshed for day %d" % day_number)

func accept_contract(contract_id: int) -> bool:
	"""Mark a contract as accepted so it can be progressed and delivered."""
	var idx: int = _find_contract_index(contract_id)
	if idx == -1:
		print("[ContractManager] accept_contract: contract %d not found" % contract_id)
		return false

	if accepted_contracts.has(contract_id):
		print("[ContractManager] accept_contract: contract %d already accepted" % contract_id)
		return false

	accepted_contracts[contract_id] = {
		"progress": {},      # shape TBD; updated by delivery or item tracking
		"accepted_on": current_day,
	}

	emit_signal("contract_accepted", contract_id)
	_emit_event_bus("contract_accepted", {"contract_id": contract_id})
	print("[ContractManager] Contract %d accepted" % contract_id)
	return true

func submit_delivery(contract_id: int, items: Dictionary) -> bool:
	"""Attempt to complete a contract with delivered items.
	Args:
		contract_id: ID of the contract being delivered
		items: Dictionary of delivered items (shape TBD)
	Returns:
		True if contract is completed and rewards granted
	"""
	var idx: int = _find_contract_index(contract_id)
	if idx == -1:
		print("[ContractManager] submit_delivery: contract %d not found" % contract_id)
		return false

	if not accepted_contracts.has(contract_id):
		print("[ContractManager] submit_delivery: contract %d not accepted" % contract_id)
		return false

	var contract: Dictionary = active_contracts[idx]
	# Placeholder validation: accept anything for now (actual validation will use CropManager + contract data)
	var is_valid: bool = _validate_items_against_contract(items, contract)
	if not is_valid:
		emit_signal("contract_failed", contract_id, "invalid_items")
		_emit_event_bus("contract_failed", {"contract_id": contract_id, "reason": "invalid_items"})
		print("[ContractManager] Delivery failed for %d: invalid items" % contract_id)
		return false

	# Reward via GameManager shared pool if available
	var reward: int = int(contract.get("reward", 0))
	_grant_reward(reward, "contract_completed:%d" % contract_id)

	# Remove from lists
	active_contracts.remove_at(idx)
	accepted_contracts.erase(contract_id)

	emit_signal("contract_completed", contract_id, reward)
	_emit_event_bus("contract_complete", {"contract_id": contract_id, "reward": reward})
	print("[ContractManager] Contract %d completed (+%d)" % [contract_id, reward])
	return true

func remove_expired_contracts(day_number: int) -> void:
	"""Remove any contracts whose 'expires_on' is earlier than the provided day."""
	var removed: Array[int] = []
	for i in range(active_contracts.size() - 1, -1, -1):
		var c: Dictionary = active_contracts[i]
		if day_number > int(c.get("expires_on", day_number)):
			removed.append(int(c.get("id", -1)))
			active_contracts.remove_at(i)

	for id in removed:
		accepted_contracts.erase(id)
		emit_signal("contract_removed", id, "expired")
		_emit_event_bus("contract_removed", {"contract_id": id, "reason": "expired"})
		print("[ContractManager] Contract %d expired and removed" % id)

# ============================================================================
# SYSTEM INTEGRATION
# ============================================================================
func _on_day_started(day_number: int) -> void:
	"""Handle new day flow from TimeManager."""
	print("[ContractManager] Day started: %d" % day_number)
	remove_expired_contracts(day_number)
	refresh_contracts_for_day(day_number)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func get_active_contracts() -> Array[Dictionary]:
	return active_contracts

func is_contract_accepted(contract_id: int) -> bool:
	return accepted_contracts.has(contract_id)

func _find_contract_index(contract_id: int) -> int:
	for i in active_contracts.size():
		if int(active_contracts[i].get("id", -1)) == contract_id:
			return i
	return -1

func _generate_placeholder_contract(day_number: int) -> Dictionary:
	# Simple placeholder generation: reward scales slightly with day
	var id := _next_contract_id
	_next_contract_id += 1

	var base_reward: int = 100 + (day_number * 10)
	var variance: int = _rng.randi_range(-20, 40)
	var reward: int = max(50, base_reward + variance)

	return {
		"id": id,
		"title": "Daily Contract %d" % id,
		"reward": reward,
		"expires_on": day_number,  # Expires end of current day (placeholder)
		"requirements": {},        # Defined later when Contract system is implemented
	}

func _validate_items_against_contract(items: Dictionary, contract: Dictionary) -> bool:
	# Placeholder: accept any delivery until full validation logic exists
	return true

func _grant_reward(amount: int, reason: String) -> void:
	if amount <= 0:
		return
	if game_manager and game_manager.has_method("add_money"):
		game_manager.add_money(amount, reason)
	elif game_manager and game_manager.has_method("emit_signal"):
		# Fallback: at least notify via signal if money API is different
		game_manager.emit_signal("money_changed", amount)
	else:
		print("[ContractManager] WARNING: No valid reward path. Missing GameManager.add_money?")

func _emit_event_bus(event_name: String, payload: Dictionary) -> void:
	# Defensive dispatch to EventBus if available
	if event_bus == null:
		return
	if event_bus.has_method("emit"):
		event_bus.emit(event_name, payload)
	elif event_bus.has_method("dispatch"):
		event_bus.dispatch(event_name, payload)
	else:
		# If EventBus API differs, systems can connect to our signals directly
		pass

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"day": current_day,
		"active_count": active_contracts.size(),
		"accepted_count": accepted_contracts.size(),
		"connected_time": time_manager != null,
		"connected_eventbus": event_bus != null,
		"connected_game": game_manager != null,
	}
