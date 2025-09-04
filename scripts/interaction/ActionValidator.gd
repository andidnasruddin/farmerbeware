extends RefCounted
class_name ActionValidator
# ActionValidator.gd - Runs permission checks via GridValidator

# Returns:
# {
#   "valid": bool,
#   "valid_positions": Array[Vector2i],
#   "reason": String
# }

func validate(tool_name: String, positions: Array[Vector2i], grid_validator: Node, player_id: int = 0) -> Dictionary:
	var result := {
		"valid": false,
		"valid_positions": [],
		"reason": ""
	}
	if grid_validator == null:
		result.reason = "no_validator"
		return result

	var ok_positions: Array[Vector2i] = []
	for p in positions:
		var v: Dictionary = grid_validator.validate_tool_action(p, tool_name, player_id)
		if v.get("valid", false):
			ok_positions.append(p)
		elif result.reason == "":
			result.reason = String(v.get("reason", "invalid"))

	result.valid = ok_positions.size() > 0
	result.valid_positions = ok_positions
	return result
