extends Node
# TimeManager.gd - AUTOLOAD #5
# Manages day/night cycles, game phases, and time-based events
# Coordinates timing for all game systems

# ============================================================================
# TIME PHASES - Different parts of each day
# ============================================================================
enum TimePhase {
	PLANNING,    # Review contracts, plan the day
	MORNING,     # Start farming, full energy
	MIDDAY,      # Continued farming, events may happen
	EVENING,     # Last chance for actions, slower growth
	NIGHT,       # Results processing, save progress
	TRANSITION   # Moving between days
}

# ============================================================================
# SIGNALS
# ============================================================================
signal phase_changed(from_phase: TimePhase, to_phase: TimePhase)
signal day_started(day_number: int)
signal day_ended(day_number: int, results: Dictionary)
signal time_tick(current_time: float, phase: TimePhase)
signal countdown_warning(seconds_remaining: int)
signal game_speed_changed(speed: float)

# ============================================================================
# PROPERTIES
# ============================================================================
# Current time state
var current_day: int = 1
var current_phase: TimePhase = TimePhase.PLANNING
var phase_time_elapsed: float = 0.0
var total_game_time: float = 0.0

# Phase durations (in seconds)
var phase_durations: Dictionary = {
	TimePhase.PLANNING: 30.0,    # 30 seconds to plan
	TimePhase.MORNING: 120.0,    # 2 minutes of farming
	TimePhase.MIDDAY: 180.0,     # 3 minutes of farming  
	TimePhase.EVENING: 120.0,    # 2 minutes of farming
	TimePhase.NIGHT: 15.0,       # 15 seconds for results
	TimePhase.TRANSITION: 5.0    # 5 seconds between days
}

# Speed control
var game_speed: float = 3.0      # Normal speed
var max_speed: float = 3.0       # Maximum speed multiplier
var min_speed: float = 0.1       # Minimum speed (slow motion)
var is_paused: bool = false

# Game duration
var max_days: int = 15           # Complete 15 days to win
var target_week: int = 4         # Survive to Week 4

# Phase progression
var auto_advance: bool = true    # Automatically advance phases
var phase_warnings: Array[int] = [60, 30, 10, 5]  # Warning times in seconds

# System references  
var interaction_system: Node = null

# Multiplayer
var _mp_connected_bound: bool = false

const EV_COUNTDOWN_REQUEST: String = "time/countdown_request"

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "TimeManager"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	print("[TimeManager] Initializing as Autoload #5...")
	
	# Get references to other systems
	interaction_system = InteractionSystem
	
	if interaction_system:
		print("[TimeManager] InteractionSystem connected")
	
	# Connect to GameManager
	if GameManager:
		GameManager.register_system("TimeManager", self)
		GameManager.state_changed.connect(_on_game_state_changed)
		print("[TimeManager] Registered with GameManager")
	
	if get_tree().root.get_node_or_null("/root/DayNightCycle") == null:
		var dnc: DayNightCycle = preload("res://scripts/time/DayNightCycle.gd").new()
		get_tree().root.call_deferred("add_child", dnc)

	var ui := get_node_or_null("/root/UIManager")
	if ui and ui.has_method("register_overlay"):
		ui.register_overlay("countdown", "res://scenes/time/CountdownOverlay.tscn")

	# Set up time system
	_setup_time_system()
	_ensure_time_inputs()
	call_deferred("_register_ui_overlays")
	call_deferred("_connect_network_time_events")
	call_deferred("_spawn_daynightcycle_if_missing")
	call_deferred("_spawn_event_scheduler_if_missing")
	call_deferred("_spawn_difficulty_scaler_if_missing")
	if not is_connected("phase_changed", Callable(self, "_on_phase_local_changed")):
		phase_changed.connect(_on_phase_local_changed)
	print("[TimeManager] Initialization complete!")

func _setup_time_system() -> void:
	"""Initialize the time management system"""
	current_day = 1
	current_phase = TimePhase.PLANNING
	phase_time_elapsed = 0.0
	total_game_time = 0.0
	game_speed = 1.0
	is_paused = false
	
	print("[TimeManager] Time system configured - Day %d, %s phase" % [current_day, _phase_to_string(current_phase)])

# ============================================================================
# TIME PROCESSING
# ============================================================================
func _process(delta: float) -> void:
	if is_paused or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Only flow time during FARMING phases (MORNING/MIDDAY/EVENING)
	if not _is_farming_phase(current_phase):
		return

	var adjusted_delta: float = delta * game_speed
	phase_time_elapsed += adjusted_delta
	total_game_time += adjusted_delta

	time_tick.emit(phase_time_elapsed, current_phase)

	_check_phase_warnings()

	if auto_advance and _should_advance_phase():
		_advance_phase()

func _check_phase_warnings() -> void:
	# Warnings apply only while farming
	if not _is_farming_phase(current_phase):
		return
	var phase_duration: float = phase_durations[current_phase]
	var time_remaining: float = phase_duration - phase_time_elapsed
	for warning_time in phase_warnings:
		if time_remaining <= warning_time and time_remaining > warning_time - 1.0:
			countdown_warning.emit(warning_time)
			break

func _should_advance_phase() -> bool:
	# Never auto-advance from PLANNING
	if current_phase == TimePhase.PLANNING:
		return false
	var phase_duration: float = phase_durations[current_phase]
	return phase_time_elapsed >= phase_duration

# ============================================================================
# PHASE MANAGEMENT
# ============================================================================
func _register_ui_overlays() -> void:
	var ui = get_node_or_null("/root/UIManager")
	if ui == null:
		await get_tree().process_frame
		ui = get_node_or_null("/root/UIManager")
	if ui and ui.has_method("register_overlay"):
		ui.register_overlay("countdown", "res://scenes/time/CountdownOverlay.tscn")
		ui.register_overlay("phase_transition", "res://scenes/time/PhaseTransition.tscn")
		ui.register_overlay("time_display", "res://scenes/time/TimeDisplay.tscn")
		ui.register_overlay("calendar", "res://scenes/time/CalendarUI.tscn")

func _advance_phase() -> void:
	"""Advance to the next time phase"""
	var old_phase: TimePhase = current_phase
	var new_phase: TimePhase = _get_next_phase(current_phase)
	
	# Handle special phase transitions
	if current_phase == TimePhase.NIGHT and new_phase == TimePhase.TRANSITION:
		_end_day()
	elif current_phase == TimePhase.TRANSITION and new_phase == TimePhase.PLANNING:
		_start_new_day()
	
	# Change phase
	current_phase = new_phase
	phase_time_elapsed = 0.0
	
	print("[TimeManager] Phase change: %s → %s" % [_phase_to_string(old_phase), _phase_to_string(new_phase)])
	phase_changed.emit(old_phase, new_phase)
	
	# Handle phase-specific logic
	_on_phase_entered(new_phase)

func _get_next_phase(phase: TimePhase) -> TimePhase:
	"""Get the next phase in the daily cycle"""
	match phase:
		TimePhase.PLANNING:
			return TimePhase.MORNING
		TimePhase.MORNING:
			return TimePhase.MIDDAY
		TimePhase.MIDDAY:
			return TimePhase.EVENING
		TimePhase.EVENING:
			return TimePhase.NIGHT
		TimePhase.NIGHT:
			return TimePhase.TRANSITION
		TimePhase.TRANSITION:
			return TimePhase.PLANNING
		_:
			return TimePhase.PLANNING

func _on_phase_entered(phase: TimePhase) -> void:
	"""Handle logic when entering a specific phase"""
	match phase:
		TimePhase.PLANNING:
			print("[TimeManager] Planning phase - Review contracts and prepare")
			if interaction_system:
				interaction_system.set_input_mode("ui")
		
		TimePhase.MORNING:
			print("[TimeManager] Morning phase - Farming begins!")
			if interaction_system:
				interaction_system.set_input_mode("farm")
		
		TimePhase.MIDDAY:
			print("[TimeManager] Midday phase - Peak farming time")
			# TODO: Trigger random events
		
		TimePhase.EVENING:
			print("[TimeManager] Evening phase - Time running out")
			# TODO: Slower crop growth
		
		TimePhase.NIGHT:
			print("[TimeManager] Night phase - Processing results")
			if interaction_system:
				interaction_system.set_input_mode("disabled")
			_process_day_results()
		
		TimePhase.TRANSITION:
			print("[TimeManager] Transition phase - Preparing next day")

# ============================================================================
# PUBLIC API - DAY START
# ============================================================================
func start_day() -> void:
	if current_phase != TimePhase.PLANNING:
		return

	# Ensure runtime time nodes exist before starting the day so
	# EventScheduler can connect to DayNightCycle and receive early updates.
	_spawn_daynightcycle_if_missing()
	_spawn_event_scheduler_if_missing()
	if GameManager and GameManager.current_state != GameManager.GameState.PLAYING:
		GameManager.change_state(GameManager.GameState.PLAYING)
		await get_tree().process_frame
	var old_phase: TimePhase = current_phase
	current_phase = TimePhase.MORNING
	phase_time_elapsed = 0.0
	print("[TimeManager] Phase change: %s -> %s" % [_phase_to_string(old_phase), _phase_to_string(current_phase)])
	phase_changed.emit(old_phase, current_phase)
	_on_phase_entered(current_phase)

# ============================================================================
# DAY MANAGEMENT
# ============================================================================
func _start_new_day() -> void:
	"""Start a new day"""
	current_day += 1
	print("[TimeManager] Starting Day %d" % current_day)
	
	# Check win/lose conditions
	if current_day > max_days:
		_trigger_game_completion()
		return
	
	day_started.emit(current_day)
	
	# TODO: Generate new contracts
	# TODO: Reset daily resources
	# TODO: Apply overnight growth

func _end_day() -> void:
	print("[TimeManager] Ending Day %d" % current_day)
	var am: Node = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("day_end_bell")
	var day_results: Dictionary = _calculate_day_results()
	day_ended.emit(current_day, day_results)

func _process_day_results() -> void:
	"""Process and display the results of the day"""
	# TODO: Calculate contract completions
	# TODO: Calculate money earned
	# TODO: Update player stats
	# TODO: Apply crop growth overnight
	
	print("[TimeManager] Processing day results...")

func _calculate_day_results() -> Dictionary:
	"""Calculate the results for the completed day"""
	var results: Dictionary = {
		"day": current_day,
		"phase_completed": true,
		"money_earned": 0,
		"contracts_completed": 0,
		"crops_harvested": 0,
		"total_time": total_game_time
	}
	
	# TODO: Get actual results from other systems
	return results

# ============================================================================
# SPEED CONTROL
# ============================================================================
func set_game_speed(speed: float) -> void:
	"""Set the game speed multiplier"""
	var old_speed: float = game_speed
	game_speed = clamp(speed, min_speed, max_speed)
	
	if old_speed != game_speed:
		print("[TimeManager] Game speed changed: %.1fx" % game_speed)
		game_speed_changed.emit(game_speed)

func pause_time() -> void:
	"""Pause the time system"""
	is_paused = true
	print("[TimeManager] Time paused")

func resume_time() -> void:
	"""Resume the time system"""
	is_paused = false
	print("[TimeManager] Time resumed")

func toggle_pause() -> void:
	"""Toggle time pause state"""
	if is_paused:
		resume_time()
	else:
		pause_time()

# ============================================================================
# PHASE CONTROL
# ============================================================================
func _on_phase_local_changed(from_phase: int, to_phase: int) -> void:
	_play_phase_transition(from_phase, to_phase)
	if _is_host():
		_broadcast_phase_change(from_phase, to_phase)

func _play_phase_transition(from_phase: int, to_phase: int) -> void:
	var ui = get_node_or_null("/root/UIManager")
	if ui and ui.has_method("show_overlay"):
		ui.show_overlay("phase_transition")
	var overlay = get_node_or_null("/root/UIManager/UILayer/Overlays/PhaseTransition")
	if overlay and overlay.has_method("play_transition"):
		overlay.play_transition(from_phase, to_phase)

func _broadcast_phase_change(from_phase: int, to_phase: int) -> void:
	var nm = get_node_or_null("/root/NetworkManager")
	if nm and nm.has_method("send_event"):
		nm.send_event("time/phase_change", {"from": from_phase, "to": to_phase, "day": current_day})

func force_advance_phase() -> void:
	"""Manually advance to next phase (debug)"""
	print("[TimeManager] Forcing phase advancement")
	_advance_phase()

func set_phase(phase: TimePhase) -> void:
	"""Set specific phase (debug)"""
	current_phase = phase
	phase_time_elapsed = 0.0
	print("[TimeManager] Phase set to: %s" % _phase_to_string(phase))

func skip_to_next_day() -> void:
	"""Skip to the next day (debug)"""
	print("[TimeManager] Skipping to next day")
	_end_day()
	_start_new_day()
	current_phase = TimePhase.PLANNING
	phase_time_elapsed = 0.0

# ============================================================================
# WIN/LOSE CONDITIONS
# ============================================================================
func _trigger_game_completion() -> void:
	"""Handle game completion (win condition)"""
	print("[TimeManager] Game completed! Survived %d days" % max_days)
	
	if GameManager:
		var final_stats: Dictionary = {
			"days_survived": current_day - 1,
			"total_time": total_game_time,
			"completion": "victory"
		}
		GameManager.end_run("victory", final_stats)

func check_failure_conditions() -> bool:
	"""Check if any failure conditions are met"""
	# TODO: Check money bankruptcy
	# TODO: Check mandatory contract failures
	# TODO: Check player disconnections
	return false

# ============================================================================
# GAME STATE INTEGRATION
# ============================================================================
func _on_game_state_changed(from_state: int, to_state: int) -> void:
	match to_state:
		GameManager.GameState.PLAYING:
			resume_time()
			var ui = get_node_or_null("/root/UIManager")
			if ui and ui.has_method("show_overlay"):
				ui.show_overlay("time_display")
		GameManager.GameState.PAUSED:
			pause_time()
		GameManager.GameState.MENU, GameManager.GameState.LOBBY:
			pause_time()

# ============================================================================
# TIME QUERIES
# ============================================================================
func get_current_day() -> int:
	return current_day

func get_current_phase() -> TimePhase:
	return current_phase

func get_phase_progress() -> float:
	"""Get phase completion progress (0.0 to 1.0)"""
	var phase_duration: float = phase_durations[current_phase]
	return clamp(phase_time_elapsed / phase_duration, 0.0, 1.0)

func get_time_remaining_in_phase() -> float:
	"""Get seconds remaining in current phase"""
	var phase_duration: float = phase_durations[current_phase]
	return max(0.0, phase_duration - phase_time_elapsed)

func get_current_week() -> int:
	"""Get current week number (1-4)"""
	return ((current_day - 1) / 7) + 1

func get_day_in_week() -> int:
	"""Get day within current week (1-7)"""
	return ((current_day - 1) % 7) + 1

# ============================================================================
# NETWORK TIME EVENTS
# ============================================================================

# Call after ready
func _connect_network_time_events() -> void:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm:
		if not nm.is_connected("event_received", Callable(self, "_on_net_time_event")):
			nm.event_received.connect(_on_net_time_event)
		if not nm.is_connected("peer_connected", Callable(self, "_on_peer_connected_for_time")):
			nm.peer_connected.connect(_on_peer_connected_for_time)
		# Use the SceneTree multiplayer signal (NetworkManager doesn't expose its own)
		if not _mp_connected_bound:
			multiplayer.connected_to_server.connect(_on_connected_to_server_for_time)
			_mp_connected_bound = true
	else:
		call_deferred("_connect_network_time_events")

func _on_net_time_event(event_name: String, payload: Dictionary, from_peer: int) -> void:
	# Host handles snapshot requests and countdown requests; ignores others
	if _is_host():
		if event_name == "time/snapshot_request":
			send_time_snapshot_to(from_peer)
			return
		if event_name == EV_COUNTDOWN_REQUEST:
			var secs: int = int(payload.get("seconds", 10))
			_begin_countdown_host(secs)
			return
		return

	match event_name:
		"time/countdown_start":
			var secs2: int = int(payload.get("seconds", 10))
			_show_and_start_countdown(secs2)
		"time/countdown_cancel":
			_cancel_countdown_local()
		"time/countdown_finish":
			_finish_countdown_local()
		"time/phase_change":
			var from_phase_id: int = int(payload.get("from", TimeManager.TimePhase.PLANNING))
			var to_phase_id: int = int(payload.get("to", TimeManager.TimePhase.PLANNING))
			_play_phase_transition(from_phase_id, to_phase_id)
		"time/snapshot":
			apply_time_snapshot(payload, true)
		"sched/flash":
			var em := get_node_or_null("/root/EventManager")
			if em:
				em.emit_signal("flash_contract_available", {"at_hour": 12.0})
# scripts/managers/TimeManager.gd  (inside _on_net_time_event match)
# Inside _on_net_time_event match
		"sched/weather":
			var em2: Node = get_node_or_null("/root/EventManager")
			if em2:
				# End whatever weather the client currently has first
				if em2.has_method("end_active_weather_events"):
					em2.end_active_weather_events()

				var id_s: String = String(payload.get("id","sunny"))
				var wt: int = em2.WeatherType.SUNNY
				if id_s == "cloudy": wt = em2.WeatherType.CLOUDY
				elif id_s == "rain": wt = em2.WeatherType.RAINY
				elif id_s == "storm": wt = em2.WeatherType.STORMY
				elif id_s == "drought": wt = em2.WeatherType.DROUGHT
				elif id_s == "fog": wt = em2.WeatherType.FOG
				var dur: float = float(payload.get("dur", -1.0))
				if dur > 0.0 and em2.has_method("force_weather_change_with_duration"):
					em2.force_weather_change_with_duration(wt, dur)
				elif em2.has_method("force_weather_change"):
					em2.force_weather_change(wt)

		"sched/weather_end":
			var em3: Node = get_node_or_null("/root/EventManager")
			if em3 and em3.has_method("end_active_weather_events"):
				em3.end_active_weather_events()

	match event_name:
		"time/countdown_start":
			var secs: int = int(payload.get("seconds", 10))
			_show_and_start_countdown(secs)
		"time/countdown_cancel":
			_cancel_countdown_local()
		"time/countdown_finish":
			_finish_countdown_local()
		"time/phase_change":
			var from_phase: int = int(payload.get("from", TimeManager.TimePhase.PLANNING))
			var to_phase: int = int(payload.get("to", TimeManager.TimePhase.PLANNING))
			_play_phase_transition(from_phase, to_phase)
		"time/snapshot":
			# Apply immediately; UI will catch up on next tick
			apply_time_snapshot(payload, true)
		"sched/flash":
			var em := get_node_or_null("/root/EventManager")
			if em:
				em.emit_signal("flash_contract_available", {"at_hour": 12.0})
		"sched/weather":
			var em2 := get_node_or_null("/root/EventManager")
			if em2 and em2.has_method("force_weather_change"):
				var id_s: String = String(payload.get("id","sunny"))
				var wt: int = em2.WeatherType.SUNNY
				if id_s == "cloudy": wt = em2.WeatherType.CLOUDY
				elif id_s == "rain": wt = em2.WeatherType.RAINY
				elif id_s == "storm": wt = em2.WeatherType.STORMY
				elif id_s == "drought": wt = em2.WeatherType.DROUGHT
				elif id_s == "fog": wt = em2.WeatherType.FOG
				em2.force_weather_change(wt)

func _show_and_start_countdown(seconds: int) -> void:
	var ui = get_node_or_null("/root/UIManager")
	# Ensure overlay is registered on client (idempotent)
	if ui and ui.has_method("register_overlay"):
		ui.register_overlay("countdown", "res://scenes/time/CountdownOverlay.tscn")

	# Try show via UIManager
	var shown: bool = false
	if ui and ui.has_method("show_overlay"):
		shown = ui.show_overlay("countdown")

	# Fallback: instance directly if needed
	if not shown and ui and ui.has_node("UILayer/Overlays"):
		var ps: PackedScene = load("res://scenes/time/CountdownOverlay.tscn")
		if ps:
			var inst := ps.instantiate()
			ui.get_node("UILayer/Overlays").add_child(inst)
			shown = true

	# Start countdown locally (no broadcast from client)
	var ov = _get_countdown_overlay()
	if ov and ov.has_method("start_countdown"):
		ov.start_countdown(seconds, false)

func _cancel_countdown_local() -> void:
	var ov = _get_countdown_overlay()
	if ov and ov.has_method("cancel_countdown"):
		ov.cancel_countdown(false)

func _finish_countdown_local() -> void:
	var ov = _get_countdown_overlay()
	if ov:
		ov.hide()
	if TimeManager and TimeManager.has_method("start_day"):
		TimeManager.start_day()

func _get_countdown_overlay() -> Node:
	return get_node_or_null("/root/UIManager/UILayer/Overlays/CountdownOverlay")

func _is_host() -> bool:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm and "is_host" in nm:
		return bool(nm.is_host)
	return multiplayer.is_server()

func _broadcast(name: String, payload: Dictionary) -> void:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm and nm.has_method("send_event"):
		nm.send_event(name, payload)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _phase_to_string(phase: TimePhase) -> String:
	match phase:
		TimePhase.PLANNING: return "PLANNING"
		TimePhase.MORNING: return "MORNING"
		TimePhase.MIDDAY: return "MIDDAY"
		TimePhase.EVENING: return "EVENING"
		TimePhase.NIGHT: return "NIGHT"
		TimePhase.TRANSITION: return "TRANSITION"
		_: return "UNKNOWN"

func get_phase_color(phase: TimePhase) -> Color:
	"""Get color associated with time phase for UI"""
	match phase:
		TimePhase.PLANNING: return Color.CYAN
		TimePhase.MORNING: return Color.YELLOW
		TimePhase.MIDDAY: return Color.WHITE
		TimePhase.EVENING: return Color.ORANGE
		TimePhase.NIGHT: return Color.DARK_BLUE
		TimePhase.TRANSITION: return Color.PURPLE
		_: return Color.GRAY

# ============================================================================
# FARMING PHASE HELPERS
# ============================================================================
func _is_farming_phase(p: TimePhase) -> bool:
	return p == TimePhase.MORNING or p == TimePhase.MIDDAY or p == TimePhase.EVENING

func _ensure_time_inputs() -> void:
	if not InputMap.has_action("time_toggle_calendar"):
		InputMap.add_action("time_toggle_calendar")
	InputMap.action_erase_events("time_toggle_calendar")
	var ev := InputEventKey.new()
	ev.keycode = KEY_Y
	InputMap.action_add_event("time_toggle_calendar", ev)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("time_start_day"):
		if _is_host():
			# Host can open the countdown immediately
			if GameManager and GameManager.current_state != GameManager.GameState.PLAYING:
				GameManager.change_state(GameManager.GameState.PLAYING)
				await get_tree().process_frame
			_begin_countdown_host(10)
		else:
			# Client asks host to start the countdown
			var nm: Node = get_node_or_null("/root/NetworkManager")
			if nm and nm.has_method("send_event"):
				nm.send_event(EV_COUNTDOWN_REQUEST, {"seconds": 10})

func _begin_countdown_host(seconds: int) -> void:
	var ui: Node = get_node_or_null("/root/UIManager")
	var shown: bool = false
	if ui and ui.has_method("show_overlay"):
		shown = ui.show_overlay("countdown")
	var ov := get_node_or_null("/root/UIManager/UILayer/Overlays/CountdownOverlay")
	if ov and ov.has_method("start_countdown"):
		ov.start_countdown(seconds, true)  # host broadcasts
	elif not shown and has_method("start_day"):
		start_day()

func _spawn_event_scheduler_if_missing() -> void:
	if get_tree().root.get_node_or_null("EventScheduler") == null:
		var s := preload("res://scripts/events/EventScheduler.gd").new()
		s.name = "EventScheduler"
		get_tree().root.add_child(s)

# ============================================================================
# DIFFICULTY SCALER
# ============================================================================
func _spawn_difficulty_scaler_if_missing() -> void:
	if get_tree().root.get_node_or_null("DifficultyScaler") == null:
		var s := preload("res://scripts/time/DifficultyScaler.gd").new()
		s.name = "DifficultyScaler"
		get_tree().root.add_child(s)

# =================================================================
# SNAPSHOTS
# =================================================================

func build_time_snapshot() -> Dictionary:
	var d: int = current_day
	var p: int = current_phase
	var elapsed: float = phase_time_elapsed
	var duration: float = float(phase_durations.get(p, 1.0))
	var speed: float = game_speed
	var paused: bool = is_paused
	var percent: float = 0.0
	if duration > 0.0:
		percent = clamp(elapsed / duration, 0.0, 1.0)
	var dnc: Node = get_node_or_null("/root/DayNightCycle")
	var hour: float = 6.0
	if dnc and dnc.has_method("get_decimal_hour"):
		hour = float(dnc.get_decimal_hour())
	return {
		"day": d,
		"phase": p,
		"elapsed": elapsed,
		"duration": duration,
		"percent": percent,
		"speed": speed,
		"paused": paused,
		"hour": hour
	}

func apply_time_snapshot(snap: Dictionary, announce: bool = true) -> void:
	if snap.is_empty():
		return
	var new_day: int = int(snap.get("day", current_day))
	var new_phase: int = int(snap.get("phase", current_phase))
	var elapsed: float = float(snap.get("elapsed", 0.0))
	var duration: float = float(snap.get("duration", 1.0))
	var speed: float = float(snap.get("speed", game_speed))
	var paused: bool = bool(snap.get("paused", is_paused))
	var old_phase: int = current_phase

	current_day = new_day
	current_phase = new_phase
	phase_time_elapsed = clamp(elapsed, 0.0, duration)
	game_speed = speed
	is_paused = paused

	# Optional UI refresh
	if announce and old_phase != new_phase:
		phase_changed.emit(old_phase, new_phase)
		_on_phase_entered(new_phase)

func send_time_snapshot_to(peer_id: int) -> void:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm and nm.has_method("send_event"):
		nm.send_event("time/snapshot", build_time_snapshot(), peer_id)

func _on_peer_connected_for_time(peer_id: int) -> void:
	# Only the host responds with a snapshot
	if _is_host():
		send_time_snapshot_to(peer_id)

func _on_connected_to_server_for_time() -> void:
	# Client politely asks host for a snapshot (in case we missed the proactive send)
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm and nm.has_method("send_event"):
		nm.send_event("time/snapshot_request", {})


# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"current_day": current_day,
		"current_phase": _phase_to_string(current_phase),
		"phase_progress": get_phase_progress(),
		"time_remaining": get_time_remaining_in_phase(),
		"current_week": get_current_week(),
		"day_in_week": get_day_in_week(),
		"game_speed": game_speed,
		"is_paused": is_paused,
		"total_game_time": total_game_time,
		"interaction_system_connected": interaction_system != null
	}

func _spawn_daynightcycle_if_missing() -> void:
	if get_tree().root.get_node_or_null("DayNightCycle") == null:
		var dnc: DayNightCycle = preload("res://scripts/time/DayNightCycle.gd").new()
		dnc.name = "DayNightCycle"
		get_tree().root.add_child(dnc)
