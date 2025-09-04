extends Tool
class_name ToolSeedBag

func _init() -> void:
	id = "seed_bag"
	display_name = "Seed Bag"
	action_type = "plant"
	stamina_cost = 2.0
	area = Vector2i(1, 1)
	range = 1
	params = {"seed_id": "lettuce"}
