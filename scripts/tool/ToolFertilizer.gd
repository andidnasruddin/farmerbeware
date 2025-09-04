extends Tool
class_name ToolFertilizer

func _init() -> void:
	id = "fertilizer"
	display_name = "Fertilizer"
	action_type = "fertilize"
	stamina_cost = 3.0
	area = Vector2i(1, 1)
	range = 1
	params = {"npk_amount": 10}
