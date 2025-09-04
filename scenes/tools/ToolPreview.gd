extends Node2D
class_name ToolPreview
# ToolPreview.gd - Live grid highlight for current tool area (green = valid, red = invalid)

@export var enabled: bool = true
@export var player_path: NodePath

var player: PlayerController = null
var grid_manager: Node = null
var grid_validator: Node = null
var target_calc: TargetCalculator = null

var tile_size: int = 64
var valid_color := Color(0.25, 0.85, 0.35, 0.6)
var invalid_color := Color(0.90, 0.25, 0.25, 0.6)
var outline := Color(0.95, 0.95, 0.95, 0.6)

var _last_targets: Array[Vector2i] = []
var _last_val: Dictionary = {}   # Vector2i -> bool

func _ready() -> void:
	grid_manager = get_node_or_null("/root/GridManager")
	grid_validator = get_node_or_null("/root/GridValidator")
	if grid_manager and "tile_size" in grid_manager:
		tile_size = int(grid_manager.tile_size)
	target_calc = TargetCalculator.new()

	if player_path != NodePath():
		player = get_node(player_path) as PlayerController

	# Keep preview updating while the tree is paused (MENU)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	z_index = 200   # ensure it draws above tile/chunk renderers
	set_process(true)

func _process(_delta: float) -> void:
	if not enabled:
		_last_targets = []
		_last_val = {}
		queue_redraw()
		return

	# Hide preview when InteractionSystem is not in "farm" mode (optional)
	var is_farm: bool = true
	# Hide only when input is disabled, allow both 'farm' and 'ui'
	if InteractionSystem:
		var mode: String = String(InteractionSystem.current_input_mode)
		if mode == "disabled":
			_last_targets = []
			_last_val = {}
			queue_redraw()
			return

	if player == null or grid_validator == null or target_calc == null:
		_last_targets = []
		_last_val = {}
		queue_redraw()
		return

	# Compute origin (tile in front of player) + facing
	var origin: Vector2i = Vector2i.ZERO
	if grid_validator.has_method("world_to_grid"):
		origin = grid_validator.world_to_grid(player.global_position)

	var fx: int
	if player.facing_direction.x > 0.1:
		fx = 1
	elif player.facing_direction.x < -0.1:
		fx = -1
	else:
		fx = 0

	var fy: int
	if player.facing_direction.y > 0.1:
		fy = 1
	elif player.facing_direction.y < -0.1:
		fy = -1
	else:
		fy = 0

	var facing_vi: Vector2i = Vector2i(fx, fy)
	if facing_vi == Vector2i.ZERO:
		facing_vi = Vector2i(1, 0)

	var tool_name: String = String(player.current_tool)
	if tool_name.is_empty():
		_last_targets = []
		_last_val = {}
		queue_redraw()
		return

	# Targets (use the tile in front for clarity)
	var front: Vector2i = origin + facing_vi
	var targets: Array[Vector2i] = target_calc.compute_positions(tool_name, front, facing_vi)
	_last_targets = targets

	# Validate each target
	var val: Dictionary = {}
	for p in targets:
		var v: Dictionary = grid_validator.validate_tool_action(p, tool_name, player.player_id)
		val[p] = bool(v.get("valid", false))
	_last_val = val

	queue_redraw()

func _draw() -> void:
	if _last_targets.is_empty():
		return

	for p in _last_targets:
		var at: bool = bool(_last_val.get(p, false))
		var col: Color = valid_color if at else invalid_color
		var rect: Rect2 = Rect2(Vector2(p.x * tile_size, p.y * tile_size), Vector2(tile_size, tile_size))
		# Fill
		draw_rect(rect, col, true)
		# Outline
		draw_rect(rect, outline, false, 1.0, true)

func refresh_from_player(p: PlayerController) -> void:
	# Don’t rely on player_path; use provided player
	player = p
	# Reuse existing single update logic
	# (Call the body of your _process just once)
	if not enabled or grid_validator == null or target_calc == null:
		_last_targets = []
		_last_val = {}
		queue_redraw()
		return

	var origin: Vector2i = Vector2i.ZERO
	if grid_validator.has_method("world_to_grid"):
		origin = grid_validator.world_to_grid(player.global_position)

	var fx: int = (player.facing_direction.x > 0.1) ? 1 : ((player.facing_direction.x < -0.1) ? -1 : 0)
	var fy: int = (player.facing_direction.y > 0.1) ? 1 : ((player.facing_direction.y < -0.1) ? -1 : 0)
	var facing_vi: Vector2i = Vector2i(fx, fy)
	if facing_vi == Vector2i.ZERO:
		facing_vi = Vector2i(1, 0)

	var tool_name: String = String(player.current_tool)
	if tool_name.is_empty():
		_last_targets = []
		_last_val = {}
		queue_redraw()
		return

	var front: Vector2i = origin + facing_vi
	var targets: Array[Vector2i] = target_calc.compute_positions(tool_name, front, facing_vi)
	_last_targets = targets

	var val: Dictionary = {}
	for ppos in targets:
		var v: Dictionary = grid_validator.validate_tool_action(ppos, tool_name, player.player_id)
		val[ppos] = bool(v.get("valid", false))
	_last_val = val

	queue_redraw()
