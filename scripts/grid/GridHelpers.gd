extends RefCounted
class_name GridHelpers
# GridHelpers.gd - Static utilities for grid/chunk math and neighbors

# ============================================================================
# STATIC HELPERS
# ============================================================================
static func grid_to_index(pos: Vector2i, width: int) -> int:
	# Convert 2D grid coordinate to 1D index
	return pos.y * width + pos.x

static func index_to_grid(index: int, width: int) -> Vector2i:
	# Convert 1D index back to 2D grid coordinate
	var x: int = index % width
	var y: int = index / width
	return Vector2i(x, y)

static func grid_to_chunk(pos: Vector2i, chunk_size: int) -> Vector2i:
	# Floor-div each axis to get chunk coordinate
	return Vector2i(floori(pos.x / chunk_size), floori(pos.y / chunk_size))

static func chunk_to_bounds(chunk_id: Vector2i, chunk_size: int) -> Rect2i:
	# Rect covering the chunk in grid coords
	var origin: Vector2i = chunk_id * chunk_size
	var size: Vector2i = Vector2i(chunk_size, chunk_size)
	return Rect2i(origin, size)

static func clamp_to_bounds(pos: Vector2i, rect: Rect2i) -> Vector2i:
	var x: int = clamp(pos.x, rect.position.x, rect.position.x + rect.size.x - 1)
	var y: int = clamp(pos.y, rect.position.y, rect.position.y + rect.size.y - 1)
	return Vector2i(x, y)

static func neighbors4(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1),
	]

static func neighbors8(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(1, 0),
		pos + Vector2i(-1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(0, -1),
		pos + Vector2i(1, 1),
		pos + Vector2i(-1, 1),
		pos + Vector2i(1, -1),
		pos + Vector2i(-1, -1),
	]
