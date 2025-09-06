extends Node
class_name EventScheduler

signal schedule_loaded(week: int, count: int)
signal entry_fired(entry: Dictionary)

var time_manager: Node = null
var day_night_cycle: Node = null
var event_manager: Node = null
var network_manager: Node = null

var todays_entries: Array = []
var fired_ids: Dictionary = {}
var _connected_time: bool = false
var _last_hour: float = 6.0

# scripts/events/EventScheduler.gd

func _ready() -> void:
	name = "EventScheduler"
	time_manager = TimeManager
	day_night_cycle = get_node_or_null("/root/DayNightCycle")
	event_manager = get_node_or_null("/root/EventManager")
	network_manager = get_node_or_null("/root/NetworkManager")

	if time_manager:
		time_manager.day_started.connect(_on_day_started)
		time_manager.phase_changed.connect(_on_phase_changed)

	_connect_time_updates()

	# Update calendar when it’s opened later
	var ui := get_node_or_null("/root/UIManager")
	if ui and not ui.is_connected("overlay_shown", Callable(self, "_on_ui_overlay_shown")):
		ui.overlay_shown.connect(_on_ui_overlay_shown)

	call_deferred("_initial_load")

func _on_ui_overlay_shown(id: String) -> void:
	if id == "calendar":
		_update_calendar_list()

func _initial_load() -> void:
	if time_manager and todays_entries.is_empty():
		_load_schedule_for_week(time_manager.get_current_week())

func _connect_time_updates() -> void:
	if day_night_cycle and day_night_cycle.has_signal("time_updated") and not _connected_time:
		day_night_cycle.time_updated.connect(_on_time_updated)
		_connected_time = true
	else:
#		Retry until DayNightCycle is spawned
		call_deferred("_connect_time_updates")

func _on_day_started(_day: int) -> void:
	_last_hour = 6.0
	_load_schedule_for_week(time_manager.get_current_week())

func _on_phase_changed(_from: int, to: int) -> void:
	if to == TimeManager.TimePhase.MORNING and todays_entries.is_empty():
		_last_hour = 6.0
		_load_schedule_for_week(time_manager.get_current_week())

func _load_schedule_for_week(week: int) -> void:
	var path: String = _schedule_path_for_week(week)
	todays_entries.clear()
	fired_ids.clear()

	var res: Resource = load(path)
	if res == null:
		print("[EventScheduler] No schedule resource at: ", path)
		schedule_loaded.emit(week, 0)
		_update_calendar_list()
		return

	# Typed schedule support (EventSchedule + ScheduleEntry)
	if res is EventSchedule:
		var es: EventSchedule = res
		for s in es.entries:
			todays_entries.append({
				"hour": s.hour,
				"type": s.event_type,
				"id": s.id,
				"chance": s.chance
			})
	else:
		# Plain .tres with: [resource] events = [ { ... }, ... ]
		var raw: Array = (res.get("events") as Array)
		if raw != null:
			for e in raw:
				if e is Dictionary:
					todays_entries.append(e)

	# Guarantee Flash Contract at 12:00
	var has_flash: bool = false
	for e in todays_entries:
		if String(e.get("type","")) == "CONTRACT" and String(e.get("id","")) == "flash":
			has_flash = true; break
	if not has_flash:
		todays_entries.append({ "hour": 12.0, "type": "CONTRACT", "id": "flash", "chance": 1.0 })

	# Sort by hour
	todays_entries.sort_custom(func(a, b) -> bool:
		return float(a.get("hour", 0.0)) < float(b.get("hour", 0.0))
	)

	print("[EventScheduler] Loaded week ", week, " entries=", todays_entries.size(), " from ", path)
	for e in todays_entries:
		print("  - ", e)

	schedule_loaded.emit(week, todays_entries.size())
	_update_calendar_list()

func _schedule_path_for_week(week: int) -> String:
	match week:
		1: return "res://resources/schedules/week1_schedule.tres"
		2: return "res://resources/schedules/week2_schedule.tres"
		3: return "res://resources/schedules/week3_schedule.tres"
		4: return "res://resources/schedules/week4_schedule.tres"
		_: return "res://resources/schedules/week1_schedule.tres"

func _on_time_updated(_h: int, _m: int, percent: float) -> void:
	# Gate only when a session exists; offline acts as host
	var nm: Node = get_node_or_null("/root/NetworkManager")
	if nm and not nm.is_network_active() and nm.has_method("host"):
		nm.host(25252)  # quick local host for the test
		return

	if todays_entries.is_empty():
		return

	var cur_hour: float = _current_hour_from_percent(percent)
	var eps: float = 0.0005

	for e in todays_entries:
		var id_s: String = String(e.get("id",""))
		if fired_ids.get(id_s, false):
			continue
		var target: float = float(e.get("hour", 0.0))
		# Fire only when we cross the boundary prev < target <= current
		if (_last_hour + eps) < target and (cur_hour + eps) >= target:
			_try_fire_entry(e)
	_last_hour = cur_hour

func _current_hour_from_percent(percent: float) -> float:
	var start_h: float = 6.0
	var end_h: float = 18.0
	if day_night_cycle and "start_hour" in day_night_cycle:
		start_h = float(day_night_cycle.start_hour)
	if day_night_cycle and "end_hour" in day_night_cycle:
		end_h = float(day_night_cycle.end_hour)
	return lerp(start_h, end_h, clamp(percent, 0.0, 1.0))


func _try_fire_entry(entry: Dictionary) -> void:
	var id_s: String = String(entry.get("id",""))
	var t_s: String = String(entry.get("type",""))
	var p: float = clamp(float(entry.get("chance", 1.0)), 0.0, 1.0)
	if randf() > p:
		print("[EventScheduler] Skipped ", t_s, ":", id_s, " (chance ", p, ")")
		fired_ids[id_s] = true
		return

	print("[EventScheduler] Firing ", t_s, ":", id_s)
	_fire_entry(entry)
	fired_ids[id_s] = true
	entry_fired.emit(entry)
	_update_calendar_list()

# scripts/events/EventScheduler.gd
func _fire_entry(entry: Dictionary) -> void:
	var t: String = String(entry.get("type",""))
	var id_s: String = String(entry.get("id",""))
	match t:
		"WEATHER":
			var wt: int = _weather_from_string(id_s)
			var dur: float = randf_range(120.0, 300.0)  # 2–5 minutes
			if event_manager and event_manager.has_method("force_weather_change_with_duration"):
				event_manager.force_weather_change_with_duration(wt, dur)
			elif event_manager and event_manager.has_method("force_weather_change"):
				event_manager.force_weather_change(wt)
			_broadcast("sched/weather", {"id": id_s, "dur": dur})
		"CONTRACT":
			if id_s == "flash":
				_fire_flash_contract()
				_broadcast("sched/flash", {})
		"NPC":
			_broadcast("sched/npc", {"id": id_s})
		"DISASTER":
			_broadcast("sched/disaster", {"id": id_s})
		_:
			pass

func _fire_weather(id_s: String) -> void:
	if event_manager == null:
		return
	var wt: int = _weather_from_string(id_s)
	if event_manager.has_method("force_weather_change"):
		event_manager.force_weather_change(wt)

func _weather_from_string(id_s: String) -> int:
	if not event_manager:
		return 0
	if id_s == "sunny": return event_manager.WeatherType.SUNNY
	if id_s == "cloudy": return event_manager.WeatherType.CLOUDY
	if id_s == "rain": return event_manager.WeatherType.RAINY
	if id_s == "storm": return event_manager.WeatherType.STORMY
	if id_s == "drought": return event_manager.WeatherType.DROUGHT
	if id_s == "fog": return event_manager.WeatherType.FOG
	return event_manager.WeatherType.SUNNY

func _fire_flash_contract() -> void:
	if event_manager:
		print("[EventScheduler] Flash Contract available @ 12:00")
		event_manager.emit_signal("flash_contract_available", {"at_hour": 12.0})

# Add/keep this helper in scripts/events/EventScheduler.gd

func _update_calendar_list() -> void:
	var cal = get_node_or_null("/root/UIManager/UILayer/Overlays/CalendarUI")
	if cal == null or not cal.has_method("set_today_schedule"):
		return
	var display: Array = []
	for e in todays_entries:
		var hour: float = float(e.get("hour", 0.0))
		var line := {
			"time": _fmt_hour(hour),
			"title": _entry_title(e),
			"fired": bool(fired_ids.get(String(e.get("id","")), false))
		}
		display.append(line)
	cal.set_today_schedule(display)

func _fmt_hour(h: float) -> String:
	var ih: int = int(floor(h))
	var mins: int = int(round((h - float(ih)) * 60.0))
	var am: bool = ih < 12
	var h12: int = ih % 12
	if h12 == 0: h12 = 12
	return "%d:%02d %s" % [h12, mins, "AM" if am else "PM"]

func _entry_title(e: Dictionary) -> String:
	var t: String = String(e.get("type",""))
	var id_s: String = String(e.get("id",""))
	match t:
		"WEATHER": return "Weather: " + id_s.capitalize()
		"CONTRACT":
			if id_s == "flash": return "Flash Contract"
			return "Contract: " + id_s.capitalize()
		"NPC": return "NPC: " + id_s.capitalize()
		"DISASTER": return "Disaster: " + id_s.capitalize()
		_: return id_s

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
	if network_manager and network_manager.has_method("send_event"):
		network_manager.send_event(name, payload)
