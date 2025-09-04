extends Node2D
class_name ChunkRenderer
# Draw 10x10 chunk grid and highlight dirty chunks briefly.
# Dependencies: GridManager (CHUNK_SIZE, tile_size, chunk_dirty, grid_expanded)

# ============================================================================
# PROPERTIES
# ============================================================================
@export var show_chunk_grid: bool = true
@export var highlight_seconds: float = 1.0

var grid_manager: Node = null
var tile_size: int = 64
var grid_size: Vector2i = Vector2i(10, 10)
var chunk_size: int = 10

var chunk_line := Color(0.30, 0.30, 0.32, 0.8)
var chunk_highlight := Color(1.0, 0.2, 0.2, 0.25)

# chunk_id(Vector2i) -> expire_time(float)
var _dirty_chunks: Dictionary = {}

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready() -> void:
	grid_manager = get_node_or_null("/root/GridManager")
	if grid_manager:
		if "tile_size" in grid_manager:
			tile_size = int(grid_manager.tile_size)
		if "grid_size" in grid_manager:
			grid_size = grid_manager.grid_size
		# Pull CHUNK_SIZE constant (fallback to 10)
		chunk_size = 10
		if "CHUNK_SIZE" in grid_manager:
			chunk_size = int(grid_manager.CHUNK_SIZE)

		if grid_manager.has_signal("chunk_dirty"):
			grid_manager.chunk_dirty.connect(_on_chunk_dirty)
		if grid_manager.has_signal("grid_expanded"):
			grid_manager.grid_expanded.connect(_on_grid_expanded)

	set_process(true)
	queue_redraw()

func _process(_delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	var changed := false
	for k in _dirty_chunks.keys():
		if now >= float(_dirty_chunks[k]):
			_dirty_chunks.erase(k)
			changed = true
	if changed:
		queue_redraw()

func _on_chunk_dirty(chunk_id: Vector2i) -> void:
	# Highlight a dirty chunk for highlight_seconds
	_dirty_chunks[chunk_id] = Time.get_unix_time_from_system() + highlight_seconds
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

	# Draw chunk grid
	if show_chunk_grid:
		for cx in range(0, grid_size.x, chunk_size):
			var xx := float(cx * tile_size)
			draw_line(Vector2(xx, 0), Vector2(xx, h), chunk_line, 2.0)
		for cy in range(0, grid_size.y, chunk_size):
			var yy := float(cy * tile_size)
			draw_line(Vector2(0, yy), Vector2(w, yy), chunk_line, 2.0)

	# Highlight dirty chunks
	for cid in _dirty_chunks.keys():
		var origin := Vector2(cid.x * chunk_size * tile_size, cid.y * chunk_size * tile_size)
		var size := Vector2(chunk_size * tile_size, chunk_size * tile_size)
		draw_rect(Rect2(origin, size), chunk_highlight, true)
