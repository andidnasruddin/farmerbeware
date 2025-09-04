extends Node
class_name PlayerInventory
# PlayerInventory.gd - Holds tool resources and manages selection

# ============================================================================
# SIGNALS
# ============================================================================
signal current_tool_changed(tool: Tool, index: int)

# ============================================================================
# PROPERTIES
# ============================================================================
@export var tools: Array[Tool] = []          # Assign in the Inspector
@export var current_index: int = 0

# ============================================================================
# API
# ============================================================================
func get_current_tool() -> Tool:
	if tools.is_empty():
		return null
	current_index = clamp(current_index, 0, tools.size() - 1)
	return tools[current_index]

func select_index(i: int) -> bool:
	if tools.is_empty():
		return false
	if i < 0 or i >= tools.size():
		return false
	if i == current_index:
		return true
	current_index = i
	current_tool_changed.emit(get_current_tool(), current_index)
	return true

func select_hotkey(slot_1_to_7: int) -> bool:
	# Maps 1..7 to 0..6
	return select_index(slot_1_to_7 - 1)

func select_by_id(tool_id: String) -> bool:
	for i in tools.size():
		var t := tools[i]
		if t and t.id == tool_id:
			return select_index(i)
	return false

func add_tool(tool: Tool) -> void:
	if tool:
		tools.append(tool)
		if tools.size() == 1:
			select_index(0)

func remove_current() -> void:
	if tools.is_empty():
		return
	tools.remove_at(current_index)
	current_index = clamp(current_index, 0, tools.size() - 1)
	current_tool_changed.emit(get_current_tool(), current_index)
