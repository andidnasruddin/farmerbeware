extends Control
class_name PhaseController

@export var fade_duration: float = 0.5

var _fade: ColorRect = null
var _label: Label = null
var _tween: Tween = null

func _ready() -> void:
	name = "PhaseTransition"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_fade = $Fade as ColorRect
	if has_node("PhaseLabel"):
		_label = $PhaseLabel as Label
	else:
		_label = null

	# Start hidden and fully transparent (color alpha = 0)
	hide()
	if _fade:
		var c: Color = _fade.color
		c.a = 0.0
		_fade.color = c

func play_transition(from_phase: int, to_phase: int) -> void:
	# Block input briefly during fade
	show()

	if _label:
		_label.text = _phase_to_string(to_phase)
		_label.z_index = 1

	# Reset color alpha to 0 before tween
	if _fade:
		var c: Color = _fade.color
		c.a = 0.0
		_fade.color = c

	# Kill any previous tween safely
	if is_instance_valid(_tween):
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(_fade, "color:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_interval(0.05)
	_tween.tween_property(_fade, "color:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished

	hide()

func _phase_to_string(p: int) -> String:
	match p:
		TimeManager.TimePhase.PLANNING: return "PLANNING"
		TimeManager.TimePhase.MORNING: return "MORNING"
		TimeManager.TimePhase.MIDDAY: return "MIDDAY"
		TimeManager.TimePhase.EVENING: return "EVENING"
		TimeManager.TimePhase.NIGHT: return "NIGHT"
		TimeManager.TimePhase.TRANSITION: return "TRANSITION"
		_: return "UNKNOWN"
