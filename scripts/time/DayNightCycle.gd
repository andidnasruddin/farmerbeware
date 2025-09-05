extends Node
class_name DayNightCycle

signal time_updated(hour: int, minute: int, percent: float)

var start_hour: float = 6.0
var end_hour: float = 18.0
var current_hour: float = 6.0

func _ready() -> void:
	name = "DayNightCycle"
	if TimeManager:
		TimeManager.time_tick.connect(_on_time_tick)
		TimeManager.day_started.connect(_on_day_started)
		TimeManager.phase_changed.connect(_on_phase_changed)
	_emit_time()

func _on_day_started(_day: int) -> void:
	current_hour = start_hour
	_emit_time()

func _on_phase_changed(_from: int, to: int) -> void:
	if not _is_farming_phase(to):
		return
	_emit_time()

func _on_time_tick(_elapsed: float, _phase: int) -> void:
	if not _is_farming_phase(TimeManager.get_current_phase()):
		return
	var p: float = _get_farming_progress()
	current_hour = lerp(start_hour, end_hour, p)
	_emit_time()

func _is_farming_phase(p: int) -> bool:
	return p == TimeManager.TimePhase.MORNING or p == TimeManager.TimePhase.MIDDAY or p == TimeManager.TimePhase.EVENING

func _get_farming_progress() -> float:
	var d: Dictionary = TimeManager.phase_durations
	var morning: float = float(d[TimeManager.TimePhase.MORNING])
	var midday: float = float(d[TimeManager.TimePhase.MIDDAY])
	var evening: float = float(d[TimeManager.TimePhase.EVENING])
	var total: float = morning + midday + evening

	var elapsed: float = 0.0
	match TimeManager.get_current_phase():
		TimeManager.TimePhase.MORNING:
			elapsed = TimeManager.phase_time_elapsed
		TimeManager.TimePhase.MIDDAY:
			elapsed = morning + TimeManager.phase_time_elapsed
		TimeManager.TimePhase.EVENING:
			elapsed = morning + midday + TimeManager.phase_time_elapsed
		_:
			elapsed = 0.0

	return clamp(elapsed / max(total, 0.001), 0.0, 1.0)

func get_hour() -> int:
	return int(floor(current_hour)) % 24

func get_minute() -> int:
	var ih: int = int(floor(current_hour))
	var frac: float = current_hour - float(ih)
	var mins: int = int(floor(frac * 60.0 + 1e-6))  # floor, tiny bias
	return clamp(mins, 0, 59)

func get_decimal_hour() -> float:
	return current_hour

func get_time_string() -> String:
	var h: int = int(floor(current_hour)) % 24
	var m: int = get_minute()
	# Carry if rounding pushed to 60 (defensive, should not happen with floor)
	if m >= 60:
		m = 0
		h = (h + 1) % 24
	var am: bool = h < 12
	var h12: int = h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, "AM" if am else "PM"]

func get_time_percent() -> float:
	return clamp((current_hour - start_hour) / max(end_hour - start_hour, 0.001), 0.0, 1.0)

func _emit_time() -> void:
	time_updated.emit(get_hour(), get_minute(), get_time_percent())

func get_debug_info() -> Dictionary:
	return {
		"hour": get_hour(),
		"minute": get_minute(),
		"percent": get_time_percent()
	}
