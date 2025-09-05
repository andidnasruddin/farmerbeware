extends Control
class_name StaminaBar

@export var player_path: NodePath
@export var max_stamina_fallback: float = 100.0

var _player: PlayerController = null
var _bar: ProgressBar = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	_bar = $Bar as ProgressBar
	# Locate player
	if player_path != NodePath():
		_player = get_node(player_path) as PlayerController
	if _player == null:
		var n := get_tree().get_first_node_in_group("player")
		_player = n as PlayerController
	# Init bar
	_bar.min_value = 0.0
	var maxv: float = max_stamina_fallback
	if _player and _player.stats:
		maxv = float(_player.stats.stamina_max)
	_bar.max_value = maxv
	_update_bar()

func _process(_delta: float) -> void:
	_update_bar()

func _update_bar() -> void:
	if _player == null:
		return
	var maxv: float = _bar.max_value
	if _player.stats:
		maxv = float(_player.stats.stamina_max)
	_bar.max_value = maxv
	_bar.value = clamp(_player.stamina, 0.0, maxv)
