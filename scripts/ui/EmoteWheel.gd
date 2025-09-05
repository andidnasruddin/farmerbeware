extends Control
class_name EmoteWheel

@export var close_on_click: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = false
	set_process(true)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("emote_wheel"):
		visible = not visible

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if close_on_click and event is InputEventMouseButton and event.pressed:
		visible = false
