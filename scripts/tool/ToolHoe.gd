extends Tool
class_name ToolHoe

func _init() -> void:
	id = "hoe"
	display_name = "Bronze Hoe"
	action_type = "till"
	stamina_cost = 5.0
	area = Vector2i(1, 1)
	range = 1
	params = {}
