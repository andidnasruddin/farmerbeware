extends RefCounted
class_name ChunkManager
# ChunkManager.gd - Chunk math + dirty tracking (no rendering)

# ============================================================================
# PROPERTIES
# ============================================================================
var chunk_size: int = 10
var grid_size: Vector2i = Vector2i.ZERO
var dirty_chunks: Dictionary = {}	# Vector2i -> true

# ============================================================================
# INITIALIZATION
# ============================================================================
func _init(c_size: int = 10, g_size: Vector2i = Vector2i.ZERO) -> void:
	chunk_size = max(1, c_size)
	grid_size = g_size

func set_config(c_size: int, g_size: Vector2i) -> void:
	chunk_size = max(1, c_size)
	grid_size = g_size
	dirty_chunks.clear()

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func get_chunk_id_for_pos(pos: Vector2i) -> Vector2i:
	return Vector2i(floori(pos.x / chunk_size), floori(pos.y / chunk_size))

func get_chunk_bounds(chunk_id: Vector2i) -> Rect2i:
	var origin: Vector2i = chunk_id * chunk_size
	var size: Vector2i = Vector2i(chunk_size, chunk_size)
	return Rect2i(origin, size)

func get_chunks_dimensions() -> Vector2i:
	# Number of chunks along each axis (ceil division)
	var w_chunks: int = int(ceil(float(grid_size.x) / float(chunk_size)))
	var h_chunks: int = int(ceil(float(grid_size.y) / float(chunk_size)))
	return Vector2i(w_chunks, h_chunks)

func mark_dirty_by_pos(pos: Vector2i) -> Vector2i:
	var cid: Vector2i = get_chunk_id_for_pos(pos)
	dirty_chunks[cid] = true
	return cid

func mark_chunk_dirty(chunk_id: Vector2i) -> void:
	dirty_chunks[chunk_id] = true

func clear_chunk_dirty(chunk_id: Vector2i) -> void:
	dirty_chunks.erase(chunk_id)

func clear_all_dirty() -> void:
	dirty_chunks.clear()

func is_chunk_dirty(chunk_id: Vector2i) -> bool:
	return dirty_chunks.has(chunk_id)

func get_dirty_chunks() -> Array[Vector2i]:
	var arr: Array[Vector2i] = []
	for k in dirty_chunks.keys():
		arr.append(k)
	return arr

func iterate_chunk_positions(chunk_id: Vector2i) -> Array[Vector2i]:
	# Returns grid positions within the chunk, clamped to grid_size
	var out: Array[Vector2i] = []
	var rect: Rect2i = get_chunk_bounds(chunk_id)
	var x0: int = rect.position.x
	var y0: int = rect.position.y
	var x1: int = min(x0 + rect.size.x - 1, grid_size.x - 1)
	var y1: int = min(y0 + rect.size.y - 1, grid_size.y - 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			out.append(Vector2i(x, y))
	return out

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"chunk_size": chunk_size,
		"grid_size": grid_size,
		"dirty_chunks": dirty_chunks.size(),
		"dims": get_chunks_dimensions()
	}
