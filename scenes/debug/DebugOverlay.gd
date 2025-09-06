extends Control
class_name DebugOverlay

@export var refresh_hz: float = 4.0

var _readout: Label = null
var _accum: float = 0.0

func _ready() -> void:
	name = "DebugOverlay"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_readout = $Readout as Label
	if _readout:
		_readout.text = "Debug initializing..."
	_update_now()

func _process(delta: float) -> void:
	_accum += delta
	var period: float = 1.0 / max(refresh_hz, 0.25)
	if _accum >= period:
		_accum = 0.0
		_update_now()

func _update_now() -> void:
	var lines: Array[String] = []

	var gm: Node = get_node_or_null("/root/GameManager")
	var tm: Node = get_node_or_null("/root/TimeManager")
	var dnc: Node = get_node_or_null("/root/DayNightCycle")
	var em: Node = get_node_or_null("/root/EventManager")
	var es: Node = get_node_or_null("/root/EventScheduler")
	var ds: Node = get_node_or_null("/root/DifficultyScaler")
	var nm: Node = get_node_or_null("/root/NetworkManager")

	# Header
	lines.append("FPS: %d" % int(Engine.get_frames_per_second()))

	# Game
	if gm:
		var state_s: String = "?"
		if "current_state" in gm and "GameState" in gm:
			var st: int = int(gm.current_state)
			var keys: Array = gm.GameState.keys()
			if st >= 0 and st < keys.size():
				state_s = String(keys[st])
		var money: int = 0
		if "current_money" in gm:
			money = int(gm.current_money)
		lines.append("Game: %s  $%d" % [state_s, money])

	# Time
	if tm:
		var day: int = 0
		if "current_day" in tm:
			day = int(tm.current_day)
		var phase_id: int = 0
		if "current_phase" in tm:
			phase_id = int(tm.current_phase)
		var phase_s: String = _phase_to_string(phase_id)
		var prog: float = 0.0
		if tm.has_method("get_phase_progress"):
			prog = float(tm.get_phase_progress())
		lines.append("Time: Day %d  Phase %s  (%.0f%%)" % [day, phase_s, prog * 100.0])

	if dnc and dnc.has_method("get_time_string"):
		lines.append("Clock: %s" % String(dnc.get_time_string()))

	# Weather
	if em:
		var wt: int = 0
		if "current_weather" in em:
			wt = int(em.current_weather)
		var w_s: String = _weather_to_string(em, wt)
		var active_cnt: int = 0
		if "active_events" in em:
			active_cnt = int(em.active_events.size())
		lines.append("Weather: %s  (active events: %d)" % [w_s, active_cnt])

	# Scheduler (next few entries)
	if es:
		var next_s: String = _next_events_summary(es, dnc)
		lines.append("Scheduler: %s" % next_s)

	# Difficulty
	if ds:
		var w: int = 0
		if "current_week" in ds:
			w = int(ds.current_week)
		var dyn: float = 0.0
		if "_dyn_bonus" in ds:
			dyn = float(ds._dyn_bonus)
		var assist: bool = false
		if "assist_mode" in ds:
			assist = bool(ds.assist_mode)
		lines.append("Difficulty: week=%d dyn=%.2f assist=%s" % [w, dyn, str(assist)])

	# Network
	if nm:
		var active: bool = false
		if nm.has_method("is_network_active"):
			active = bool(nm.is_network_active())
		var host: bool = false
		if "is_host" in nm:
			host = bool(nm.is_host)
		var peers: int = 0
		if "connected_peers" in nm:
			peers = int(nm.connected_peers.size())
		lines.append("Net: active=%s host=%s peers=%d" % [str(active), str(host), peers])

	if _readout:
		_readout.text = "\n".join(lines)

func _phase_to_string(id: int) -> String:
	match id:
		TimeManager.TimePhase.PLANNING: return "PLANNING"
		TimeManager.TimePhase.MORNING: return "MORNING"
		TimeManager.TimePhase.MIDDAY: return "MIDDAY"
		TimeManager.TimePhase.EVENING: return "EVENING"
		TimeManager.TimePhase.NIGHT: return "NIGHT"
		TimeManager.TimePhase.TRANSITION: return "TRANSITION"
		_: return "?"

func _weather_to_string(em: Node, wt: int) -> String:
	if not em: return "UNKNOWN"
	if wt == em.WeatherType.SUNNY: return "SUNNY"
	if wt == em.WeatherType.CLOUDY: return "CLOUDY"
	if wt == em.WeatherType.RAINY: return "RAINY"
	if wt == em.WeatherType.STORMY: return "STORMY"
	if wt == em.WeatherType.DROUGHT: return "DROUGHT"
	if wt == em.WeatherType.FOG: return "FOG"
	return "UNKNOWN"

func _next_events_summary(es: Node, dnc: Node) -> String:
	var entries_var = es.get("todays_entries")
	if not (entries_var is Array):
		return "none"
	var entries: Array = entries_var as Array
	if entries.size() == 0:
		return "none"

	var cur_h: float = 0.0
	if dnc and dnc.has_method("get_decimal_hour"):
		cur_h = float(dnc.get_decimal_hour())

	var nexts: Array[String] = []
	var taken: int = 0
	for e in entries:
		if not (e is Dictionary):
			continue
		var h: float = float(e.get("hour", 0.0))
		if h >= cur_h:
			var t_s: String = _fmt_hour(h)
			var id_s: String = String(e.get("id",""))
			var ty_s: String = String(e.get("type",""))
			var label: String = id_s if id_s != "" else ty_s
			nexts.append("%s %s" % [t_s, label])
			taken += 1
			if taken >= 3:
				break

	if nexts.size() == 0:
		return "none"
	return ", ".join(nexts)

func _fmt_hour(h: float) -> String:
	var ih: int = int(floor(h))
	var mins: int = int(round((h - float(ih)) * 60.0))
	var am: bool = ih < 12
	var h12: int = ih % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, mins, "AM" if am else "PM"]
