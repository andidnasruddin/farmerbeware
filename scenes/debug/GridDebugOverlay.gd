extends Node2D
class_name GridDebugOverlay
# GridDebugOverlay.gd - Shows fence rect, chunk grid, and hovered tile highlight

# ============================================================================
# PROPERTIES
# ============================================================================
@export var show_fence: bool = true
@export var show_chunks: bool = true
@export var show_hover: bool = true

# Debug logging (throttled)
@export var debug_logs: bool = false
@export var debug_log_interval: float = 1.0   # seconds between prints
var _last_debug_print_ms: int = 0

var grid_manager: Node = null
var grid_validator: Node = null

var preview_targets: Array[Vector2i] = []
var preview_valid: Dictionary = {}

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
	_debug_print("[GDO] _draw preview_count=%d" % preview_targets.size())

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

	# Preview overlay
	if preview_targets.size() > 0:
		var vcol: Color = Color(0.25, 0.85, 0.35, 0.45)
		var icol: Color = Color(0.90, 0.25, 0.25, 0.45)
		var ocol: Color = Color(0.95, 0.95, 0.95, 0.7)
		for p in preview_targets:
			var rect: Rect2 = Rect2(Vector2(p.x * tile_size, p.y * tile_size), Vector2(tile_size, tile_size))
			var ok: bool = bool(preview_valid.get(p, false))
			var col: Color = vcol if ok else icol
			draw_rect(rect, col, true)
			draw_rect(rect, ocol, false, 1.0, true)

func set_preview(targets: Array[Vector2i], validity: Dictionary) -> void:
	preview_targets = targets if targets != null else []
	preview_valid = validity if validity != null else {}
	_debug_print("[GDO] set_preview count=%d" % preview_targets.size())
	queue_redraw()

func clear_preview() -> void:
	preview_targets = []
	preview_valid = {}
	_debug_print("[GDO] clear_preview")
	queue_redraw()

func _debug_print(msg: String) -> void:
	if not debug_logs:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_debug_print_ms >= int(debug_log_interval * 1000.0):
		print(msg)
		_last_debug_print_ms = now
