extends Node
class_name DifficultyScaler

# ============================================================================
# SIGNALS
# ============================================================================
signal difficulty_applied(day: int, week: int, mods: Dictionary)

# ============================================================================
# PROPERTIES
# ============================================================================
var time_manager: Node = null
var event_manager: Node = null

# Baseline: captured once from TimeManager at first apply
var _base_phase_durations: Dictionary = {}
var _captured_base: bool = false

# Day/Week tracking
var current_day: int = 1
var current_week: int = 1

# Dynamic difficulty tracking (derived from yesterday)
var _dyn_bonus: float = 0.0			# 0..0.5 additional difficulty never decreases
var _last_results: Dictionary = {}

# Assist mode lowers pressure without disabling weekly scaling
@export var assist_mode: bool = false	# -20% pressure/frequency

# Caps/minima
@export var max_difficulty_mult: float = 2.0	# 200%
@export var min_phase_seconds: float = 45.0		# absolute floor per phase

# Weekly base increments (applied per week after week 1)
@export var weekly_time_pressure: float = 0.15	# +15% per week (reduces phase durations)
@export var weekly_event_freq: float = 0.25		# +25% per week (all event types)
@export var weekly_disaster_extra: float = 0.15	# +15% per week (extra on disasters)

# Dynamic difficulty knobs (optional)
@export var dyn_bonus_perfect: float = 0.05		# add if easy day (contracts perfect + lots of time left)
@export var dyn_bonus_good: float = 0.03		# add if good day
@export var dyn_bonus_ok: float = 0.01			# small nudge

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "DifficultyScaler"
	time_manager = get_node_or_null("/root/TimeManager")
	event_manager = get_node_or_null("/root/EventManager")

	if time_manager:
		time_manager.day_started.connect(_on_day_started)
		time_manager.day_ended.connect(_on_day_ended)
		current_day = time_manager.get_current_day()
		current_week = time_manager.get_current_week()

# ============================================================================
# CORE
# ============================================================================
func _on_day_started(day: int) -> void:
	current_day = day
	current_week = time_manager.get_current_week()

	if not _captured_base:
		_capture_base_phase_durations()

	var mods: Dictionary = _compute_modifiers(current_week)
	_apply_time_pressure(mods)
	_apply_event_freq(mods)
	emit_signal("difficulty_applied", current_day, current_week, mods)

func _on_day_ended(day: int, results: Dictionary) -> void:
	_last_results = results if results != null else {}
	_update_dynamic_bonus(_last_results)

func _capture_base_phase_durations() -> void:
	if time_manager == null:
		return
	# Make a deep copy once; use these as baseline every day
	_base_phase_durations = {}
	for k in time_manager.phase_durations.keys():
		_base_phase_durations[k] = float(time_manager.phase_durations[k])
	_captured_base = true

func _compute_modifiers(week: int) -> Dictionary:
	var w_idx: int = max(0, week - 1)

	var time_pressure: float = min(weekly_time_pressure * float(w_idx), max_difficulty_mult - 1.0)
	var event_freq: float = min(weekly_event_freq * float(w_idx), max_difficulty_mult - 1.0)
	var disaster_extra: float = min(weekly_disaster_extra * float(w_idx), max_difficulty_mult - 1.0)

	var dyn: float = clamp(_dyn_bonus, 0.0, 0.5)

	if assist_mode:
		time_pressure = max(0.0, time_pressure - 0.20)
		event_freq = max(0.0, event_freq - 0.20)

	return {
		"time_pressure": time_pressure + dyn,
		"event_freq": event_freq + dyn,
		"disaster_extra": disaster_extra + (dyn * 0.5),
		"assist": assist_mode
	}

	# Assist mode reduces pressure/frequency (not disasters)
	if assist_mode:
		time_pressure = max(0.0, time_pressure - 0.20)
		event_freq = max(0.0, event_freq - 0.20)

	return {
		"time_pressure": time_pressure + dyn,
		"event_freq": event_freq + dyn,
		"disaster_extra": disaster_extra + (dyn * 0.5),
		"assist": assist_mode
	}

func _apply_time_pressure(mods: Dictionary) -> void:
	if time_manager == null or not _captured_base:
		return
	var tp: float = float(mods.get("time_pressure", 0.0))
	# tp=0.20 means reduce durations by 20% (more pressure)
	var factor: float = clamp(1.0 - tp, 0.25, 1.0)	# never below 25% of base
	for k in _base_phase_durations.keys():
		var base_s: float = float(_base_phase_durations[k])
		var new_s: float = max(min_phase_seconds, base_s * factor)
		time_manager.phase_durations[k] = new_s
	# Optional: log for tuning
	print("[Difficulty] Time pressure applied: ", tp, " -> factor=", factor)

func _apply_event_freq(mods: Dictionary) -> void:
	if event_manager == null:
		return
	var ef: float = float(mods.get("event_freq", 0.0))
	var de: float = float(mods.get("disaster_extra", 0.0))

	# Multiply all event probabilities by (1 + ef), clamp to 0.95
	if "event_probabilities" in event_manager:
		var probs: Dictionary = event_manager.event_probabilities
		for t in probs.keys():
			var v: float = float(probs[t])
			probs[t] = clamp(v * (1.0 + ef), 0.0, 0.95)
		event_manager.event_probabilities = probs

	# Disaster extra: specifically bump disasters further
	if int(event_manager.EventType.DISASTER) in event_manager.event_probabilities:
		var k: int = int(event_manager.EventType.DISASTER)
		var dv: float = float(event_manager.event_probabilities[k])
		event_manager.event_probabilities[k] = clamp(dv * (1.0 + de), 0.0, 0.98)

	print("[Difficulty] Event freq=", ef, " disaster_extra=", de)

func _update_dynamic_bonus(results: Dictionary) -> void:
	# Heuristic: look at money earned, any contract stats if provided, and time slack
	var add: float = 0.0
	var money: float = float(results.get("money_earned", 0.0))
	var phase_completed: bool = bool(results.get("phase_completed", true))

	# If you later include contract stats, improve this:
	# var contracts_completed: int = int(results.get("contracts_completed", 0))
	# var contracts_total: int = int(results.get("contracts_total", 0))
	# var success_rate: float = contracts_total > 0 ? float(contracts_completed) / float(contracts_total) : 0.0

	if phase_completed and money >= 0.0:
		# Simple tiering; tune as needed
		if money >= 500 and current_week == 1:
			add = dyn_bonus_perfect
		elif money >= 300:
			add = dyn_bonus_good
		elif money >= 150:
			add = dyn_bonus_ok

	# Never decrease; only raise (clamped later)
	_dyn_bonus = clamp(_dyn_bonus + add, 0.0, 0.5)

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"day": current_day,
		"week": current_week,
		"base_captured": _captured_base,
		"dyn_bonus": _dyn_bonus,
		"assist_mode": assist_mode
	}
