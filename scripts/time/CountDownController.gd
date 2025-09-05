extends Control
class_name CountdownController

signal countdown_started(seconds: int)
signal countdown_cancelled()
signal countdown_finished()

@export var start_seconds: int = 10
@export var auto_start: bool = false

var running: bool = false
var seconds_left: int = 0

var _label: Label = null
var _cancel_btn: Button = null

const EV_START: String = "time/countdown_start"
const EV_CANCEL: String = "time/countdown_cancel"
const EV_FINISH: String = "time/countdown_finish"

func _ready() -> void:
	name = "CountdownOverlay"
	mouse_filter = Control.MOUSE_FILTER_STOP
	if has_node("Dim"):
		$Dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = $Label as Label
	_cancel_btn = $CancelButton as Button
	_cancel_btn.z_index = 1
	_cancel_btn.focus_mode = Control.FOCUS_ALL
	_cancel_btn.pressed.connect(_on_cancel_pressed)
	hide()
	_ensure_inputs()

func _ensure_inputs() -> void:
	if not InputMap.has_action("time_cancel_countdown"):
		InputMap.add_action("time_cancel_countdown")
	InputMap.action_erase_events("time_cancel_countdown")
	var ev_c := InputEventKey.new(); ev_c.keycode = KEY_C
	InputMap.action_add_event("time_cancel_countdown", ev_c)
	var ev_esc := InputEventKey.new(); ev_esc.keycode = KEY_ESCAPE
	InputMap.action_add_event("time_cancel_countdown", ev_esc)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("time_cancel_countdown") and running:
		cancel_countdown(true)

func start_countdown(seconds: int = -1, broadcast: bool = false) -> void:
	if running:
		return
	seconds_left = (seconds if seconds > 0 else start_seconds)
	running = true
	_update_label()
	show()
	countdown_started.emit(seconds_left)
	if broadcast and _is_host():
		_broadcast(EV_START, {"seconds": seconds_left})
	_tick()

func cancel_countdown(broadcast: bool = false) -> void:
	if not running:
		return
	running = false
	hide()
	countdown_cancelled.emit()
	if broadcast and _is_host():
		_broadcast(EV_CANCEL, {})

func _tick() -> void:
	if not running:
		return
	_play_beep()
	await get_tree().create_timer(1.0).timeout
	if not running:
		return
	seconds_left -= 1
	if seconds_left <= 0:
		running = false
		hide()
		countdown_finished.emit()
		if _is_host():
			_broadcast(EV_FINISH, {})
			if TimeManager and TimeManager.has_method("start_day"):
				TimeManager.start_day()
	else:
		_update_label()
		_tick()

func _update_label() -> void:
	if _label:
		_label.text = str(max(seconds_left, 0))

func _play_beep() -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("countdown_beep")

func _on_cancel_pressed() -> void:
	cancel_countdown(true)

func _is_host() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	if nm and "is_host" in nm:
		return bool(nm.is_host)
	return multiplayer.is_server()

func _broadcast(name: String, payload: Dictionary) -> void:
	var nm = get_node_or_null("/root/NetworkManager")
	if nm and nm.has_method("send_event"):
		nm.send_event(name, payload)
