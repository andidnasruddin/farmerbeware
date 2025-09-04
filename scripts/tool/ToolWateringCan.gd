extends Tool
class_name ToolWateringCan

func _init() -> void:
	id = "watering_can"
	display_name = "Basic Watering Can"
	action_type = "water"
	stamina_cost = 3.0
	area = Vector2i(3, 1)   # 3×1 per doc
	range = 1
	uses_per_refill = 5
	params = {"water_add": 25}
