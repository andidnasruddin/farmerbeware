extends RefCounted
class_name FenceValidator
# FenceValidator.gd - Boundary helper utilities (stateless)

# ============================================================================
# CORE HELPERS
# ============================================================================
static func is_inside(bounds: Rect2i, pos: Vector2i) -> bool:
	return bounds.has_point(pos)

static func is_on_edge(bounds: Rect2i, pos: Vector2i) -> bool:
	if not bounds.has_point(pos):
		return false
	var min_x: int = bounds.position.x
	var min_y: int = bounds.position.y
	var max_x: int = bounds.position.x + bounds.size.x - 1
	var max_y: int = bounds.position.y + bounds.size.y - 1
	return pos.x == min_x or pos.x == max_x or pos.y == min_y or pos.y == max_y

static func clamp_to_bounds(bounds: Rect2i, pos: Vector2i) -> Vector2i:
	var x: int = clamp(pos.x, bounds.position.x, bounds.position.x + bounds.size.x - 1)
	var y: int = clamp(pos.y, bounds.position.y, bounds.position.y + bounds.size.y - 1)
	return Vector2i(x, y)

static func rect_tiles(bounds: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(bounds.position.y, bounds.position.y + bounds.size.y):
		for x in range(bounds.position.x, bounds.position.x + bounds.size.x):
			out.append(Vector2i(x, y))
	return out
