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
var game_speed: float = 1.0      # Normal speed
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

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "TimeManager"
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
	
	# Set up time system
	_setup_time_system()
	
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
	
	# Apply game speed
	var adjusted_delta: float = delta * game_speed
	
	# Update timers
	phase_time_elapsed += adjusted_delta
	total_game_time += adjusted_delta
	
	# Emit time tick for other systems
	time_tick.emit(phase_time_elapsed, current_phase)
	
	# Check for phase warnings
	_check_phase_warnings()
	
	# Check for phase advancement
	if auto_advance and _should_advance_phase():
		_advance_phase()

func _check_phase_warnings() -> void:
	"""Check if we should emit countdown warnings"""
	var phase_duration: float = phase_durations[current_phase]
	var time_remaining: float = phase_duration - phase_time_elapsed
	
	for warning_time in phase_warnings:
		if time_remaining <= warning_time and time_remaining > warning_time - 1.0:
			countdown_warning.emit(warning_time)
			break

func _should_advance_phase() -> bool:
	"""Check if current phase should advance to the next"""
	var phase_duration: float = phase_durations[current_phase]
	return phase_time_elapsed >= phase_duration

# ============================================================================
# PHASE MANAGEMENT
# ============================================================================
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
	"""End the current day and calculate results"""
	print("[TimeManager] Ending Day %d" % current_day)
	
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
# PHASE CONTROL (for testing/debugging)
# ============================================================================
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
	"""Handle GameManager state changes"""
	match to_state:
		GameManager.GameState.PLAYING:
			resume_time()
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
