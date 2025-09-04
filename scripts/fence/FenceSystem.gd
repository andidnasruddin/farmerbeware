extends Node
class_name FenceSystem
# FenceSystem.gd - Boundary management for the farm fence
# Dependencies: GridManager (optional), GridValidator (optional)

# ============================================================================
# SIGNALS
# ============================================================================
signal fence_updated(bounds: Rect2i)

# ============================================================================
# PROPERTIES
# ============================================================================
@export var min_size: Vector2i = Vector2i(10, 10)
@export var max_size: Vector2i = Vector2i(100, 100)
var bounds: Rect2i = Rect2i(Vector2i.ZERO, Vector2i(10, 10))

var grid_manager: Node = null
var grid_validator: Node = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "FenceSystem"
	# Try to bind to singletons defensively
	grid_manager = get_node_or_null("/root/GridManager")
	grid_validator = get_node_or_null("/root/GridValidator")
	_sync_validator()
	print("[FenceSystem] Ready with bounds: pos=%s size=%s" % [bounds.position, bounds.size])

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func set_bounds(new_bounds: Rect2i) -> void:
	"""Set fence rectangle (clamped to min/max)."""
	var clamped: Rect2i = _clamp_bounds(new_bounds)
	if clamped == bounds:
		return
	bounds = clamped
	_sync_validator()
	emit_signal("fence_updated", bounds)
	print("[FenceSystem] Fence updated: pos=%s size=%s" % [bounds.position, bounds.size])

func expand_to(new_size: Vector2i) -> Rect2i:
	"""Expand fence to a new size (keep origin at 0,0)."""
	var clamped_size: Vector2i = Vector2i(
		clamp(new_size.x, min_size.x, max_size.x),
		clamp(new_size.y, min_size.y, max_size.y)
	)
	var new_rect: Rect2i = Rect2i(Vector2i.ZERO, clamped_size)
	set_bounds(new_rect)
	return bounds

func contains(pos: Vector2i) -> bool:
	return bounds.has_point(pos)

func get_bounds() -> Rect2i:
	return bounds

# ============================================================================
# SYSTEM INTEGRATION
# ============================================================================
func apply_to_grid_manager() -> void:
	"""Optional helper: update GridManager+Validator to match fence size."""
	if grid_manager and grid_manager.has_method("expand_grid"):
		grid_manager.expand_grid(bounds.size)
	_sync_validator()

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _clamp_bounds(rect: Rect2i) -> Rect2i:
	var pos: Vector2i = Vector2i.ZERO  # Fence origin fixed at (0,0) per doc
	var size: Vector2i = Vector2i(
		clamp(rect.size.x, min_size.x, max_size.x),
		clamp(rect.size.y, min_size.y, max_size.y)
	)
	return Rect2i(pos, size)

func _sync_validator() -> void:
	if grid_validator:
		if grid_validator.has_method("set_fence_bounds"):
			grid_validator.set_fence_bounds(bounds)

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"bounds": bounds,
		"min_size": min_size,
		"max_size": max_size,
		"gm": grid_manager != null,
		"validator": grid_validator != null
	}
