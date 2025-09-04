extends Tool
class_name ToolHarvester

func _init() -> void:
	id = "harvester"
	display_name = "Harvester"
	action_type = "harvest"
	stamina_cost = 4.0
	area = Vector2i(1, 1)
	range = 1
	params = {}
