extends Control
class_name ToolSelector

@export var player_path: NodePath

var _player: PlayerController = null
var _label: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	_label = $HBox/ToolName as Label
	# Find player
	if player_path != NodePath():
		_player = get_node(player_path) as PlayerController
	if _player == null:
		var n := get_tree().get_first_node_in_group("player")
		_player = n as PlayerController
	# Try listen to changes
	if _player:
		_player.tool_changed.connect(_on_player_tool_changed)
	_on_player_tool_changed(_player.current_tool)

func _on_player_tool_changed(tool_name: String) -> void:
	if _label == null:
		return
	_label.text = "Tool: %s" % tool_name.capitalize()
