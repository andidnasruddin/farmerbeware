extends Node2D
class_name GridDebugOverlay
# GridDebugOverlay.gd - Shows fence rect, chunk grid, and hovered tile highlight

# ============================================================================
# PROPERTIES
# ============================================================================
@export var show_fence: bool = true
@export var show_chunks: bool = true
@export var show_hover: bool = true

var grid_manager: Node = null
var grid_validator: Node = null

var tile_size: int = 64
var grid_size: Vector2i = Vector2i(10, 10)
var chunk_size: int = 10

var fence_color := Color(0.95, 0.85, 0.20, 1.0)
var chunk_color := Color(0.10, 0.85, 0.85, 0.8)
var hover_color := Color(1.0, 1.0, 1.0, 0.25)

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready() -> void:
	grid_manager = get_node_or_null("/root/GridManager")
	grid_validator = get_node_or_null("/root/GridValidator")

	if grid_manager:
		if "tile_size" in grid_manager:
			tile_size = int(grid_manager.tile_size)
		if "grid_size" in grid_manager:
			grid_size = grid_manager.grid_size
		if "CHUNK_SIZE" in grid_manager:
			chunk_size = int(grid_manager.CHUNK_SIZE)
		if grid_manager.has_signal("grid_expanded"):
			grid_manager.grid_expanded.connect(_on_grid_expanded)

	set_process(true)
	queue_redraw()

func _process(_delta: float) -> void:
	# Redraw each frame for hover highlight responsiveness
	queue_redraw()

func _on_grid_expanded(new_size: Vector2i) -> void:
	grid_size = new_size
	queue_redraw()

# ============================================================================
# DRAW
# ============================================================================
func _draw() -> void:
	if grid_manager == null:
		return

	var w := grid_size.x * tile_size
	var h := grid_size.y * tile_size

	if show_chunks and chunk_size > 0:
		for cx in range(0, grid_size.x, chunk_size):
			var xx := float(cx * tile_size)
			draw_line(Vector2(xx, 0), Vector2(xx, h), chunk_color, 2.0)
		for cy in range(0, grid_size.y, chunk_size):
			var yy := float(cy * tile_size)
			draw_line(Vector2(0, yy), Vector2(w, yy), chunk_color, 2.0)

	if show_fence and grid_validator and ("fence_bounds" in grid_validator):
		var fb: Rect2i = grid_validator.fence_bounds
		var origin := Vector2(fb.position.x * tile_size, fb.position.y * tile_size)
		var size := Vector2(fb.size.x * tile_size, fb.size.y * tile_size)
		# Outline rectangle for fence
		draw_rect(Rect2(origin, size), fence_color, false, 3.0, true)

	if show_hover and grid_validator and grid_validator.has_method("world_to_grid"):
		var gp: Vector2i = grid_validator.world_to_grid(get_global_mouse_position())
		if gp.x >= 0 and gp.x < grid_size.x and gp.y >= 0 and gp.y < grid_size.y:
			var rect := Rect2(Vector2(gp.x * tile_size, gp.y * tile_size), Vector2(tile_size, tile_size))
			draw_rect(rect, hover_color, true)
