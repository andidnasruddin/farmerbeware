extends Node
class_name InteractionQueue
# InteractionQueue.gd - 3-slot FIFO action buffer with 100ms window

@export var max_size: int = 3
@export var window_ms: int = 100

var _queue: Array[Dictionary] = []

func enqueue(action_type: String, data: Dictionary = {}) -> bool:
	# data should include: { pos: Vector2i, tool: String, player_id: int }
	if _queue.size() >= max_size:
		return false
	var entry := {
		"type": action_type,
		"data": data,
		"ts": Time.get_ticks_msec()
	}
	_queue.append(entry)
	return true

func clear() -> void:
	_queue.clear()

func is_empty() -> bool:
	return _queue.is_empty()

func drain_to(processor: Callable) -> void:
	# Calls processor(entry) per item; on first success, clears queue.
	# Discards expired entries (> window_ms).
	if _queue.is_empty():
		return
	var now := Time.get_ticks_msec()
	var kept: Array[Dictionary] = []
	for entry in _queue:
		var age := now - int(entry["ts"])
		if age > window_ms:
			continue
		var ok := false
		if processor.is_valid():
			ok = bool(processor.call(entry))
		if ok:
			# Clear queue on success
			_queue.clear()
			return
		kept.append(entry)
	_queue = kept
