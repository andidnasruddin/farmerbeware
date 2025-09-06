extends Node
# EventManager.gd - AUTOLOAD #6  
# Manages weather, story events, disasters, and dynamic world occurrences
# Creates a living, reactive farm world

# ============================================================================
# EVENT TYPES
# ============================================================================
enum EventType {
	WEATHER,        # Rain, drought, storms
	STORY,          # Mayor visits, festivals
	DISASTER,       # Tornado, flood, pest invasion
	NPC,            # Merchant visits, inspector arrives
	CONTRACT,       # Flash contracts, urgent deliveries
	RANDOM          # Crop mutations, lucky finds
}

enum WeatherType {
	SUNNY,          # Normal conditions, +growth
	CLOUDY,         # Neutral conditions
	RAINY,          # Auto-watering, +fertility
	STORMY,         # Dangerous, possible damage
	DROUGHT,        # Rapid water loss, stress
	FOG             # Reduced visibility, slower actions
}

# ============================================================================
# EVENT DATA STRUCTURE
# ============================================================================
class GameEvent:
	var id: String = ""
	var event_type: EventType
	var title: String = ""
	var description: String = ""
	var weather_type: WeatherType = WeatherType.SUNNY
	
	# Timing
	var duration: float = 60.0        # How long it lasts
	var start_time: float = 0.0       # When it started
	var can_interrupt: bool = false   # Can be interrupted by other events
	
	# Effects
	var effects: Dictionary = {}      # Various game effects
	var requirements: Dictionary = {} # Requirements to trigger
	var rewards: Dictionary = {}      # Rewards for completion
	
	# State
	var is_active: bool = false
	var is_completed: bool = false
	var completion_progress: float = 0.0
	
	func _init(e_id: String = "", e_type: EventType = EventType.RANDOM) -> void:
		id = e_id if not e_id.is_empty() else "event_" + str(Time.get_unix_time_from_system())
		event_type = e_type
		start_time = Time.get_unix_time_from_system()
	
	func get_elapsed_time() -> float:
		return Time.get_unix_time_from_system() - start_time
	
	func get_remaining_time() -> float:
		return max(0.0, duration - get_elapsed_time())
	
	func is_expired() -> bool:
		return get_elapsed_time() >= duration

# ============================================================================
# SIGNALS
# ============================================================================
signal event_started(event: GameEvent)
signal event_ended(event: GameEvent, completed: bool)
signal weather_changed(old_weather: WeatherType, new_weather: WeatherType)
signal disaster_warning(event: GameEvent, warning_time: float)
signal npc_arrived(npc_type: String, event: GameEvent)
signal flash_contract_available(contract_data: Dictionary)

# ============================================================================
# PROPERTIES
# ============================================================================
# System references
var time_manager: Node = null
var grid_manager: Node = null
var interaction_system: Node = null

# Event state
var active_events: Array[GameEvent] = []
var event_queue: Array[GameEvent] = []
var event_history: Array[GameEvent] = []
var max_concurrent_events: int = 3

# Weather system
var current_weather: WeatherType = WeatherType.SUNNY
var weather_intensity: float = 1.0      # 0.0 to 2.0
var weather_change_cooldown: float = 120.0  # Min 2 minutes between weather changes
var last_weather_change: float = 0.0

# Event probabilities (per day)
var event_probabilities: Dictionary = {
	EventType.WEATHER: 0.8,    # 80% chance of weather event per day
	EventType.STORY: 0.3,      # 30% chance of story event
	EventType.DISASTER: 0.1,   # 10% chance of disaster
	EventType.NPC: 0.4,        # 40% chance of NPC visit
	EventType.CONTRACT: 0.6,   # 60% chance of flash contract
	EventType.RANDOM: 0.2      # 20% chance of random event
}

# Story progression
var current_story_week: int = 1
var completed_story_events: Array[String] = []

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "EventManager"
	print("[EventManager] Initializing as Autoload #6...")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	
	# Get system references
	time_manager = TimeManager
	grid_manager = GridManager
	interaction_system = InteractionSystem
	
	if time_manager:
		print("[EventManager] TimeManager connected")
		time_manager.day_started.connect(_on_day_started)
		time_manager.phase_changed.connect(_on_phase_changed)
	
	if grid_manager:
		print("[EventManager] GridManager connected")
	
	if interaction_system:
		print("[EventManager] InteractionSystem connected")
	
	# Initialize event system
	_initialize_event_system()
	
	# Register with GameManager
	if GameManager:
		GameManager.register_system("EventManager", self)
		GameManager.state_changed.connect(_on_game_state_changed)
		print("[EventManager] Registered with GameManager")
	
	print("[EventManager] Initialization complete!")

func _initialize_event_system() -> void:
	"""Initialize the event management system"""
	current_weather = WeatherType.SUNNY
	weather_intensity = 1.0
	last_weather_change = Time.get_unix_time_from_system()
	
	# Start with a welcome event
	var welcome_event: GameEvent = _create_welcome_event()
	_queue_event(welcome_event)
	
	print("[EventManager] Event system initialized - Current weather: %s" % _weather_to_string(current_weather))

# ============================================================================
# EVENT PROCESSING
# ============================================================================
func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	_update_active_events(delta)
	_process_event_queue()
	if _is_host():
		_check_random_events()

func _update_active_events(delta: float) -> void:
	"""Update all active events"""
	for i in range(active_events.size() - 1, -1, -1):
		var event: GameEvent = active_events[i]
		
		# Check if event should end
		if event.is_expired():
			_end_event(event, false)  # Expired without completion
		else:
			# Apply ongoing effects
			_apply_event_effects(event, delta)

func _process_event_queue() -> void:
	"""Process queued events and start them if possible"""
	if event_queue.is_empty():
		return
	
	# Check if we can start new events
	if active_events.size() >= max_concurrent_events:
		return
	
	# Start the next event in queue
	var next_event: GameEvent = event_queue.pop_front()
	_start_event(next_event)

func _check_random_events() -> void:
	"""Check if random events should be triggered"""
	# Only check once per phase to avoid spam
	if not time_manager:
		return
	
	var phase_progress: float = time_manager.get_phase_progress()
	if phase_progress < 0.1:  # Only check at start of phase
		return
	
	# Weather change check
	_check_weather_change()

# ============================================================================
# EVENT LIFECYCLE
# ============================================================================
func _is_host() -> bool:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	# Single-player/offline → act as host
	if nm == null:
		return true
	if nm.has_method("is_network_active") and not nm.is_network_active():
		return true
	# Session active → use NetworkManager flag
	if "is_host" in nm:
		return bool(nm.is_host)
	return multiplayer.is_server()


func _broadcast(name: String, payload: Dictionary) -> void:
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm and nm.has_method("send_event"):
		nm.send_event(name, payload)

func _queue_event(event: GameEvent) -> void:
	"""Add an event to the queue"""
	event_queue.append(event)
	print("[EventManager] Event queued: %s" % event.title)

func _start_event(event: GameEvent) -> void:
	"""Start an active event"""
	event.is_active = true
	event.start_time = Time.get_unix_time_from_system()
	active_events.append(event)
	
	print("[EventManager] Event started: %s (duration: %.0fs)" % [event.title, event.duration])
	event_started.emit(event)
	
	# Apply initial effects
	_apply_event_start_effects(event)

func _end_event(event: GameEvent, completed: bool = false) -> void:
	event.is_active = false
	event.is_completed = completed

	var index: int = active_events.find(event)
	if index >= 0:
		active_events.remove_at(index)

	event_history.append(event)
	print("[EventManager] Event ended: %s (completed: %s)" % [event.title, completed])
	event_ended.emit(event, completed)
	_apply_event_end_effects(event, completed)

	# Host notifies clients to hard-stop visuals if they drift
	if event.event_type == EventType.WEATHER and _is_host():
		_broadcast("sched/weather_end", {})

# ============================================================================
# WEATHER SYSTEM
# ============================================================================
func _check_weather_change() -> void:
	"""Check if weather should change"""
	var current_time: float = Time.get_unix_time_from_system()
	if current_time - last_weather_change < weather_change_cooldown:
		return
	
	# Random chance to change weather based on current conditions
	var change_probability: float = _get_weather_change_probability()
	if randf() > change_probability:
		return
	
	var new_weather: WeatherType = _generate_weather_transition()
	if new_weather != current_weather:
		_change_weather(new_weather)

func _get_weather_change_probability() -> float:
	"""Get probability of weather changing based on current conditions"""
	match current_weather:
		WeatherType.SUNNY: return 0.3
		WeatherType.CLOUDY: return 0.5  
		WeatherType.RAINY: return 0.4
		WeatherType.STORMY: return 0.7   # Storms usually don't last long
		WeatherType.DROUGHT: return 0.2  # Droughts persist
		WeatherType.FOG: return 0.6      # Fog burns off
		_: return 0.3

func _generate_weather_transition() -> WeatherType:
	"""Generate a new weather type based on current weather"""
	var possible_weather: Array[WeatherType] = []
	
	match current_weather:
		WeatherType.SUNNY:
			possible_weather = [WeatherType.CLOUDY, WeatherType.RAINY, WeatherType.FOG]
		WeatherType.CLOUDY:
			possible_weather = [WeatherType.SUNNY, WeatherType.RAINY, WeatherType.STORMY]
		WeatherType.RAINY:
			possible_weather = [WeatherType.CLOUDY, WeatherType.STORMY, WeatherType.SUNNY]
		WeatherType.STORMY:
			possible_weather = [WeatherType.RAINY, WeatherType.CLOUDY]
		WeatherType.DROUGHT:
			possible_weather = [WeatherType.SUNNY, WeatherType.CLOUDY]
		WeatherType.FOG:
			possible_weather = [WeatherType.SUNNY, WeatherType.CLOUDY]
	
	if possible_weather.is_empty():
		return WeatherType.SUNNY
	
	return possible_weather[randi() % possible_weather.size()]

func _change_weather(new_weather: WeatherType) -> void:
	"""Change the current weather"""
	var old_weather: WeatherType = current_weather
	current_weather = new_weather
	weather_intensity = randf_range(0.5, 1.5)
	last_weather_change = Time.get_unix_time_from_system()
	
	print("[EventManager] Weather changed: %s → %s (intensity: %.1f)" % [
		_weather_to_string(old_weather),
		_weather_to_string(new_weather),
		weather_intensity
	])
	
	weather_changed.emit(old_weather, new_weather)
	
	# Create weather event
	var weather_event: GameEvent = _create_weather_event(new_weather)
	_queue_event(weather_event)

# Add this near your other public helpers in scripts/managers/EventManager.gd

func force_weather_change_with_duration(new_weather: WeatherType, duration: float) -> void:
	_change_weather_with_duration(new_weather, duration)

func _change_weather_with_duration(new_weather: WeatherType, duration: float) -> void:
	var old_weather: WeatherType = current_weather
	current_weather = new_weather
	weather_intensity = randf_range(0.5, 1.5)
	last_weather_change = Time.get_unix_time_from_system()

	print("[EventManager] Weather changed (sync): %s -> %s (intensity: %.1f, dur: %.0fs)" % [
		_weather_to_string(old_weather),
		_weather_to_string(new_weather),
		weather_intensity,
		duration
	])

	weather_changed.emit(old_weather, new_weather)

	var weather_event: GameEvent = _create_weather_event(new_weather)
	weather_event.duration = max(1.0, duration)

	# Start immediately if we have capacity; otherwise queue
	if active_events.size() < max_concurrent_events:
		_start_event(weather_event)
	else:
		_queue_event(weather_event)


func end_active_weather_events() -> void:
	for i in range(active_events.size() - 1, -1, -1):
		var e: GameEvent = active_events[i]
		if e.event_type == EventType.WEATHER:
			_end_event(e, true)

# Snapshot of active weather state. Returns { "type": int, "remaining": float }
func get_active_weather_snapshot() -> Dictionary:
	var snap: Dictionary = {"type": int(current_weather), "remaining": -1.0}
	for e in active_events:
		if e and e.event_type == EventType.WEATHER and bool(e.is_active):
			var rem: float = 0.0
			if e.has_method("get_remaining_time"):
				rem = float(e.get_remaining_time())
			snap["type"] = int(e.weather_type)
			snap["remaining"] = rem
			break
	return snap

# ============================================================================
# EVENT CREATION FACTORIES
# ============================================================================
func _create_welcome_event() -> GameEvent:
	"""Create the welcome/tutorial event"""
	var event: GameEvent = GameEvent.new("welcome", EventType.STORY)
	event.title = "Welcome to Farm Frenzy!"
	event.description = "A new farming adventure begins. Plant crops, complete contracts, and survive 15 days!"
	event.duration = 20.0
	event.can_interrupt = true
	return event

func _create_weather_event(weather: WeatherType) -> GameEvent:
	"""Create a weather event"""
	var event: GameEvent = GameEvent.new("weather_" + _weather_to_string(weather).to_lower(), EventType.WEATHER)
	event.weather_type = weather
	event.duration = randf_range(120.0, 300.0)	# 2–5 minutes
	
	match weather:
		WeatherType.SUNNY:
			event.title = "Sunny Weather"
			event.description = "Perfect farming conditions! Crops grow faster."
			event.effects = {"crop_growth_multiplier": 1.2}
		
		WeatherType.CLOUDY:
			event.title = "Cloudy Sky"
			event.description = "Overcast conditions. Normal farming weather."
			event.effects = {}
		
		WeatherType.RAINY:
			event.title = "Rainfall"
			event.description = "Rain waters all crops automatically!"
			event.effects = {"auto_water": true, "fertility_bonus": 0.1}
		
		WeatherType.STORMY:
			event.title = "Thunderstorm"
			event.description = "Dangerous conditions! Take shelter to avoid damage."
			event.effects = {"movement_speed": 0.7, "damage_risk": 0.1}
		
		WeatherType.DROUGHT:
			event.title = "Drought"
			event.description = "Extremely dry conditions. Crops lose water quickly!"
			event.effects = {"water_loss_multiplier": 2.0, "crop_stress": 0.2}
		
		WeatherType.FOG:
			event.title = "Heavy Fog"
			event.description = "Limited visibility makes farming more difficult."
			event.effects = {"visibility_reduced": true, "action_speed": 0.8}
	
	return event

func _create_story_event(day: int) -> GameEvent:
	"""Create a story event based on current day"""
	var event: GameEvent = GameEvent.new("story_day" + str(day), EventType.STORY)
	event.duration = 45.0
	
	# Different story events for different days
	if day == 3:
		event.title = "Mayor's Visit"
		event.description = "The mayor stops by to check on your progress!"
		event.effects = {"reputation_bonus": 50}
	elif day == 7:
		event.title = "Weekly Market"
		event.description = "The weekend market opens with special prices!"
		event.effects = {"sell_price_multiplier": 1.5}
	elif day == 10:
		event.title = "Inspector Arrival"
		event.description = "A food inspector wants to check your quality standards."
		event.effects = {"quality_requirements_increased": true}
	
	return event

# ============================================================================
# EVENT EFFECTS
# ============================================================================
func _apply_event_start_effects(event: GameEvent) -> void:
	"""Apply effects when an event starts"""
	# Weather-specific effects
	if event.event_type == EventType.WEATHER:
		_apply_weather_effects(event.weather_type, true)

func _apply_event_effects(event: GameEvent, delta: float) -> void:
	"""Apply ongoing effects during an event"""
	# TODO: Apply continuous effects like auto-watering, growth bonuses, etc.
	pass

func _apply_event_end_effects(event: GameEvent, completed: bool) -> void:
	"""Apply effects when an event ends"""
	if event.event_type == EventType.WEATHER:
		_apply_weather_effects(event.weather_type, false)  # Remove effects

func _apply_weather_effects(weather: WeatherType, applying: bool) -> void:
	"""Apply or remove weather effects"""
	# TODO: Coordinate with GridManager and other systems
	print("[EventManager] %s weather effects for: %s" % ["Applying" if applying else "Removing", _weather_to_string(weather)])

# ============================================================================
# TIME INTEGRATION
# ============================================================================
func _on_day_started(day: int) -> void:
	"""Handle new day - generate day-specific events"""
	print("[EventManager] Processing events for Day %d" % day)
	
	# Generate story events for specific days
	if day in [3, 7, 10, 14]:
		var story_event: GameEvent = _create_story_event(day)
		_queue_event(story_event)
	
	# Roll for random daily events
	_roll_daily_events()

func _on_phase_changed(from_phase: int, to_phase: int) -> void:
	"""Handle time phase changes"""
	# Some events might be phase-specific
	if to_phase == TimeManager.TimePhase.EVENING:
		# Chance for evening events (NPC visits, etc.)
		if randf() < 0.3:  # 30% chance
			_create_evening_event()

func _roll_daily_events() -> void:
	"""Roll for various random daily events"""
	for event_type in event_probabilities:
		var probability: float = event_probabilities[event_type]
		if randf() < probability:
			_create_random_event_of_type(event_type)

func _create_random_event_of_type(event_type: EventType) -> void:
	"""Create a random event of the specified type"""
	# TODO: Implement specific event creation for each type
	print("[EventManager] Would create random %s event" % EventType.keys()[event_type])

func _create_evening_event() -> void:
	"""Create an evening-specific event"""
	var event: GameEvent = GameEvent.new("evening_visitor", EventType.NPC)
	event.title = "Evening Visitor"
	event.description = "A traveling merchant arrives as the sun sets."
	event.duration = 60.0
	_queue_event(event)

# ============================================================================
# STATE MANAGEMENT
# ============================================================================
func _on_game_state_changed(from_state: int, to_state: int) -> void:
	"""Handle game state changes"""
	match to_state:
		GameManager.GameState.PLAYING:
			# Resume event processing
			pass
		GameManager.GameState.PAUSED:
			# Pause events but don't end them
			pass
		GameManager.GameState.MENU:
			# End all active events
			_end_all_events()

func _end_all_events() -> void:
	"""End all active events (when leaving game)"""
	for event in active_events.duplicate():
		_end_event(event, false)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _weather_to_string(weather: WeatherType) -> String:
	match weather:
		WeatherType.SUNNY: return "SUNNY"
		WeatherType.CLOUDY: return "CLOUDY"
		WeatherType.RAINY: return "RAINY"
		WeatherType.STORMY: return "STORMY"
		WeatherType.DROUGHT: return "DROUGHT"
		WeatherType.FOG: return "FOG"
		_: return "UNKNOWN"

func get_current_weather() -> WeatherType:
	return current_weather

func get_active_events() -> Array[GameEvent]:
	return active_events.duplicate()

func get_events_of_type(event_type: EventType) -> Array[GameEvent]:
	var filtered_events: Array[GameEvent] = []
	for event in active_events:
		if event.event_type == event_type:
			filtered_events.append(event)
	return filtered_events

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"current_weather": _weather_to_string(current_weather),
		"weather_intensity": weather_intensity,
		"active_events": active_events.size(),
		"queued_events": event_queue.size(),
		"event_history": event_history.size(),
		"time_manager_connected": time_manager != null,
		"last_weather_change": last_weather_change
	}

func force_weather_change(weather: WeatherType) -> void:
	"""Force weather change (debug)"""
	_change_weather(weather)

func trigger_test_event() -> void:
	"""Trigger a test event (debug)"""
	var test_event: GameEvent = GameEvent.new("test", EventType.RANDOM)
	test_event.title = "Test Event"
	test_event.description = "This is a test event for debugging."
	test_event.duration = 10.0
	_queue_event(test_event)
