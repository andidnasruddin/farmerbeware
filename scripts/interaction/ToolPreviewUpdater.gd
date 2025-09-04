extends Node
class_name ToolPreviewUpdater
# Computes tool targets each physics frame and updates TileMapRenderer preview

@export var player_path: NodePath
@export var renderer_path: NodePath
@export var enabled: bool = true

var player: PlayerController = null
var renderer: Node = null
var grid_validator: Node = null
var target_calc: TargetCalculator = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	grid_validator = get_node_or_null("/root/GridValidator")
	target_calc = TargetCalculator.new()

	if player_path != NodePath():
		player = get_node(player_path) as PlayerController
	if renderer_path != NodePath():
		renderer = get_node(renderer_path)

	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if not enabled or player == null or grid_validator == null or renderer == null:
		_clear()
		return

	# Only hide when input is fully disabled
	if InteractionSystem and ("current_input_mode" in InteractionSystem):
		var mode: String = String(InteractionSystem.current_input_mode)
		if mode == "disabled":
			_clear()
			return

	# Compute origin and facing
	var origin: Vector2i = Vector2i.ZERO
	if grid_validator.has_method("world_to_grid"):
		origin = grid_validator.world_to_grid(player.global_position)

	var fx: int = 0
	if player.facing_direction.x > 0.1: fx = 1
	elif player.facing_direction.x < -0.1: fx = -1
	var fy: int = 0
	if player.facing_direction.y > 0.1: fy = 1
	elif player.facing_direction.y < -0.1: fy = -1
	var facing: Vector2i = Vector2i(fx, fy)
	if facing == Vector2i.ZERO:
		facing = Vector2i(1, 0)

	# Tool name must be present
	var tool_name: String = String(player.current_tool)
	if tool_name.is_empty():
		_clear()
		return

	# Targets at the tile in front
	var front: Vector2i = origin + facing
	var targets: Array[Vector2i] = target_calc.compute_positions(tool_name, front, facing)

	# Validate each target
	var val: Dictionary = {}
	for p in targets:
		var v: Dictionary = grid_validator.validate_tool_action(p, tool_name, player.player_id)
		val[p] = bool(v.get("valid", false))

	# update renderer
	if renderer and renderer.has_method("set_preview"):
		renderer.set_preview(targets, val)

func _clear() -> void:
	if renderer and renderer.has_method("clear_preview"):
		renderer.clear_preview()
