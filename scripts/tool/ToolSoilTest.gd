extends Tool
class_name ToolSoilTest

func _init() -> void:
	id = "soil_test"
	display_name = "Soil Tester"
	action_type = "test_soil"
	stamina_cost = 0.0
	area = Vector2i(1, 1)
	range = 1
	params = {}
