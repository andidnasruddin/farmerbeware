extends Node

# Fast durations for quick test; adjust if needed
@export var morning_s: float = 30.0
@export var midday_s: float = 20.0
@export var evening_s: float = 20.0

var _planning_percent_before: float = -1.0
var _planning_percent_after_1s: float = -1.0

# Farming total seconds (your test exports)
var total_farming_s: float = morning_s + midday_s + evening_s
var sec_per_hour: float = total_farming_s / 12.0  # 12 in‑game hours → FARMING total

func _ready() -> void:
	print("=== TIME SYSTEM TEST: START ===")
	await get_tree().process_frame

	# 1) Planning should not tick
	_planning_percent_before = _get_time_percent()
	await get_tree().create_timer(1.0).timeout
	_planning_percent_after_1s = _get_time_percent()
	assert(_planning_percent_before == _planning_percent_after_1s, "Planning should not advance time_percent")

	# 2) Speed up phases (test-only)
	_set_fast_phase_durations(morning_s, midday_s, evening_s)

	# 3) Start day (bypass countdown to keep test simple)
	print("TEST: Starting day via TimeManager.start_day()")
	TimeManager.start_day()

	# Ensure runtime singletons are spawned and connected
	await _wait_for_runtime_nodes()

	# Start day
	TimeManager.start_day()

	# Wait a bit into the morning and then for Rain to actually be set by the scheduler
	await _wait_until_hour(6.10)
	var rain_started: bool = await _wait_until_weather(get_node("/root/EventManager").WeatherType.RAINY, 4.0)
	assert(rain_started, "Should be raining shortly after 6.1")

	# Then Sunny should override shortly after 6.2
	await _wait_until_hour(6.20)
	var sunny_now: bool = await _wait_until_weather(get_node("/root/EventManager").WeatherType.SUNNY, 4.0)
	assert(sunny_now, "Rain should have stopped after 6.2 (Sunny)")

	print("=== TIME SYSTEM TEST: PASS ===")
	# Comment this if you want to keep the scene running
	get_tree().quit()

func _wait_until_weather(wt: int, timeout_s: float = 3.0) -> bool:
	var t: float = 0.0
	while t < timeout_s:
		if _is_weather(wt):
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return false


func _await_weather_started(target_wt: int, timeout_s: float = 2.0) -> void:
	var em: Node = get_node_or_null("/root/EventManager")
	if em == null:
		return
	var elapsed: float = 0.0
	while elapsed < timeout_s:
		if em.has_method("get_events_of_type"):
			var arr: Array = em.get_events_of_type(em.EventType.WEATHER)
			for e in arr:
				if e and ("weather_type" in e) and bool(e.is_active):
					if int(e.weather_type) == target_wt:
						return
		await get_tree().process_frame
		elapsed += get_process_delta_time()

func _get_time_percent() -> float:
	var dnc := get_node_or_null("/root/DayNightCycle")
	if dnc and dnc.has_method("get_time_percent"):
		return float(dnc.get_time_percent())
	return 0.0

func _set_fast_phase_durations(morning: float, midday: float, evening: float) -> void:
	var d: Dictionary = TimeManager.phase_durations
	d[TimeManager.TimePhase.MORNING] = morning
	d[TimeManager.TimePhase.MIDDAY] = midday
	d[TimeManager.TimePhase.EVENING] = evening
	TimeManager.phase_durations = d

func _wait_until(cond: Callable, timeout_s: float = 3.0) -> bool:
	var t: float = 0.0
	while t < timeout_s:
		if bool(cond.call()):
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return false


func _wait_until_hour(target: float) -> void:
	while true:
		var dnc: Node = get_node_or_null("/root/DayNightCycle")
		if dnc and dnc.has_method("get_decimal_hour"):
			var h: float = float(dnc.get_decimal_hour())
			if h >= target:
				return
		await get_tree().process_frame

func _is_raining() -> bool:
	var em: Node = get_node_or_null("/root/EventManager")
	if em == null:
		return false
	# Read the authoritative weather
	var cur: int = int(em.current_weather)
	return cur == em.WeatherType.RAINY or cur == em.WeatherType.STORMY

func _wait_for_runtime_nodes() -> void:
	while get_node_or_null("/root/DayNightCycle") == null or get_node_or_null("/root/EventScheduler") == null:
		await get_tree().process_frame

func _is_weather(wt: int) -> bool:
	var em: Node = get_node_or_null("/root/EventManager")
	return em != null and int(em.current_weather) == wt
