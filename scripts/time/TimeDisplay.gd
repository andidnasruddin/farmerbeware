extends Control
class_name TimeDisplay

@export var warn_1h: float = 60.0
@export var warn_30m: float = 30.0
@export var warn_10m: float = 10.0
@export var warn_1m: float = 1.0

var _clock: Label = null
var _phase: Label = null
var _dayweek: Label = null
var _sun: ProgressBar = null
var _dnc: Node = null
var _accum: float = 0.0

func _ready() -> void:
	name = "TimeDisplay"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_clock = $Bar/ClockLabel as Label
	_phase = $Bar/PhaseLabel as Label
	_dayweek = $Bar/DayWeekLabel as Label
	_sun = $SunProgress as ProgressBar

	_init_sun()

	# Get the DayNightCycle autoload instance and connect
	_dnc = get_node_or_null("/root/DayNightCycle")
	if _dnc and _dnc.has_signal("time_updated"):
		_dnc.time_updated.connect(_on_time_updated)

	# Connect TimeManager signals
	if TimeManager:
		TimeManager.phase_changed.connect(_on_phase_changed)
		TimeManager.day_started.connect(_on_day_started)

	# Initial UI fill
	_refresh_phase_text(TimeManager.get_current_phase())
	_refresh_dayweek()
	_refresh_time_label()
	_apply_pressure_colors()

func _init_sun() -> void:
	if _sun:
		_sun.min_value = 0.0
		_sun.max_value = 100.0
		_sun.value = 0.0

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= 0.2:
		_accum = 0.0
		_refresh_time_label()
		if _dnc and _sun and _dnc.has_method("get_time_percent"):
			_sun.value = clamp(float(_dnc.get_time_percent()) * 100.0, 0.0, 100.0)
		_apply_pressure_colors()

func _on_time_updated(_h: int, _m: int, percent: float) -> void:
	_refresh_time_label()
	if _sun:
		_sun.value = clamp(percent * 100.0, 0.0, 100.0)
	_apply_pressure_colors()

func _on_phase_changed(_from: int, to: int) -> void:
	_refresh_phase_text(to)
	_apply_pressure_colors()

func _on_day_started(_day: int) -> void:
	_refresh_dayweek()
	_apply_pressure_colors()

func _refresh_time_label() -> void:
	if not _clock:
		return
	if _dnc and _dnc.has_method("get_time_string"):
		_clock.text = _dnc.get_time_string()

func _refresh_phase_text(phase: int) -> void:
	if not _phase:
		return
	var name: String = "UNKNOWN"
	match phase:
		TimeManager.TimePhase.PLANNING: name = "PLANNING"
		TimeManager.TimePhase.MORNING: name = "MORNING"
		TimeManager.TimePhase.MIDDAY: name = "MIDDAY"
		TimeManager.TimePhase.EVENING: name = "EVENING"
		TimeManager.TimePhase.NIGHT: name = "NIGHT"
		TimeManager.TimePhase.TRANSITION: name = "TRANSITION"
		_: name = "UNKNOWN"
	_phase.text = name

func _refresh_dayweek() -> void:
	if not _dayweek:
		return
	var day: int = TimeManager.get_current_day()
	var week: int = TimeManager.get_current_week()
	_dayweek.text = "Day %d · Week %d" % [day, week]

func _apply_pressure_colors() -> void:
	if not _phase_is_farming(TimeManager.get_current_phase()):
		_set_color_normal()
		return
	var remaining: float = TimeManager.get_time_remaining_in_phase()
	var remaining_min: float = remaining / 60.0
	if remaining_min <= warn_1m:
#		red
		_set_color(Color(1, 0.2, 0.2))
	elif remaining_min <= warn_10m:
#		orange
		_set_color(Color(1, 0.5, 0.2))
	elif remaining_min <= warn_30m:
#		yellow
		_set_color(Color(1, 0.8, 0.2))
	elif remaining_min <= warn_1h:
#		near-normal
		_set_color(Color(1, 1, 1))
	else:
		_set_color_normal()

func _set_color(c: Color) -> void:
	if _clock: _clock.modulate = c
	if _phase: _phase.modulate = c
	if _dayweek: _dayweek.modulate = c

func _set_color_normal() -> void:
	_set_color(Color(1, 1, 1))

func _phase_is_farming(p: int) -> bool:
	return p == TimeManager.TimePhase.MORNING or p == TimeManager.TimePhase.MIDDAY or p == TimeManager.TimePhase.EVENING
