extends Node2D
class_name TileMapRenderer
# Draws tiles by state using simple colors (no textures yet)
# Dependencies: GridManager (tile_size, grid_size, tile_changed, grid_expanded)

# ============================================================================
# PROPERTIES
# ============================================================================
@export var draw_grid_lines: bool = true

var grid_manager: Node = null
var tile_size: int = 64
var grid_size: Vector2i = Vector2i(10, 10)

# Colors per state (tweak later)
var color_empty := Color(0.10, 0.10, 0.12, 1.0)
var color_tilled := Color(0.38, 0.28, 0.18, 1.0)
var color_watered := Color(0.25, 0.35, 0.75, 1.0)
var color_planted := Color(0.20, 0.55, 0.25, 1.0)
var color_blocked := Color(0.45, 0.45, 0.45, 1.0)
var color_fence := Color(0.80, 0.70, 0.15, 1.0)
var grid_line := Color(0.18, 0.18, 0.20, 1.0)

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
		if grid_manager.has_signal("tile_changed"):
			grid_manager.tile_changed.connect(_on_tile_changed)
		if grid_manager.has_signal("grid_expanded"):
			grid_manager.grid_expanded.connect(_on_grid_expanded)
		if grid_manager.has_signal("chunk_dirty"):
			# Redraw on chunk updates to reflect any state change
			grid_manager.chunk_dirty.connect(_on_chunk_dirty)
	queue_redraw()

func _on_tile_changed(_pos: Vector2i, _tile) -> void:
	queue_redraw()

func _on_grid_expanded(new_size: Vector2i) -> void:
	grid_size = new_size
	queue_redraw()

func _on_chunk_dirty(_chunk_id: Vector2i) -> void:
	queue_redraw()

# ============================================================================
# DRAW
# ============================================================================
func _draw() -> void:
	if grid_manager == null:
		return

	# Draw tiles
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var p: Vector2i = Vector2i(x, y)
			var rect := Rect2(Vector2(x * tile_size, y * tile_size), Vector2(tile_size, tile_size))
			var col := _get_tile_color(p)
			draw_rect(rect, col, true)

	# Grid lines
	if draw_grid_lines:
		for x in range(grid_size.x + 1):
			var xx := float(x * tile_size)
			draw_line(Vector2(xx, 0), Vector2(xx, grid_size.y * tile_size), grid_line, 1.0)
		for y in range(grid_size.y + 1):
			var yy := float(y * tile_size)
			draw_line(Vector2(0, yy), Vector2(grid_size.x * tile_size, yy), grid_line, 1.0)

func _get_tile_color(pos: Vector2i) -> Color:
	# Avoid creating tiles: only query if it exists; else EMPTY color
	var state := FarmTileData.TileState.EMPTY
	if grid_manager.has_method("has_tile") and grid_manager.has_method("get_tile"):
		if grid_manager.has_tile(pos):
			var t: FarmTileData = grid_manager.get_tile(pos)
			if t:
				state = int(t.state)

	match state:
		FarmTileData.TileState.TILLED:
			return color_tilled
		FarmTileData.TileState.WATERED:
			return color_watered
		FarmTileData.TileState.PLANTED:
			return color_planted
		FarmTileData.TileState.BLOCKED:
			return color_blocked
		FarmTileData.TileState.FENCE:
			return color_fence
		_:
			return color_empty

# ============================================================================
# HELPERS
# ============================================================================
func grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * tile_size, pos.y * tile_size)

func world_to_grid(world: Vector2) -> Vector2i:
	return Vector2i(int(world.x / tile_size), int(world.y / tile_size))
