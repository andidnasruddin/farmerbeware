extends RefCounted
class_name TargetCalculator
# TargetCalculator.gd - Computes grid target positions from tool + origin

# Simple area rules per doc:
# - hoe/seed_bag/harvester/fertilizer/soil_test: 1x1
# - watering_can: 3x1, oriented by facing

func compute_positions(tool_name: String, origin: Vector2i, facing: Vector2i = Vector2i(1, 0)) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	match tool_name:
		"watering_can":
			# 3x1 oriented with facing; default horizontal if unknown
			if abs(facing.x) >= abs(facing.y):
				# Horizontal row centered on origin
				out.append_array([origin + Vector2i(-1, 0), origin, origin + Vector2i(1, 0)])
			else:
				# Vertical column centered on origin
				out.append_array([origin + Vector2i(0, -1), origin, origin + Vector2i(0, 1)])
		_:
			out.append(origin)
	return out
