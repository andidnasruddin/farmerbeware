extends RefCounted
class_name ActionHandlers
# ActionHandlers.gd - Tool implementations calling GridManager

# Returns:
# { "success": bool, "details": Dictionary, "reason": String }

func perform(action_type: String, tool_name: String, positions: Array[Vector2i], grid_manager: Node, params: Dictionary = {}, player_id: int = 0) -> Dictionary:
	match action_type:
		"till": return _do_till(positions, grid_manager, player_id)
		"water": return _do_water(positions, grid_manager, params, player_id)
		"plant": return _do_plant(positions, grid_manager, params, player_id)
		"harvest": return _do_harvest(positions, grid_manager, player_id)
		"fertilize": return _do_fertilize(positions, grid_manager, params)
		"test_soil": return _do_test_soil(positions, grid_manager)
		_: return {"success": false, "reason": "unknown_action"}

func _do_till(positions: Array[Vector2i], gm: Node, pid: int) -> Dictionary:
	var count := 0
	for p in positions:
		if gm.till_soil(p, pid):
			count += 1
	return {"success": count > 0, "details": {"tiled": count}}

func _do_water(positions: Array[Vector2i], gm: Node, params: Dictionary, pid: int) -> Dictionary:
	var add_percent: float = float(params.get("water_add", 25))	# 0..100
	var amount_0_1: float = clamp(add_percent / 100.0, 0.0, 1.0)
	var count := 0
	for p in positions:
		if gm.water_tile(p, amount_0_1, pid):
			count += 1
	return {"success": count > 0, "details": {"watered": count}}

func _do_plant(positions: Array[Vector2i], gm: Node, params: Dictionary, pid: int) -> Dictionary:
	var seed_id: String = String(params.get("seed_id", "lettuce"))
	var planted := 0
	for p in positions:
		if gm.plant_crop(p, seed_id, pid):
			planted += 1
	return {"success": planted > 0, "details": {"planted": planted, "crop": seed_id}}

func _do_harvest(positions: Array[Vector2i], gm: Node, pid: int) -> Dictionary:
	var total_yield := 0
	var harvested := 0
	for p in positions:
		var r: Dictionary = gm.harvest_crop(p, pid)
		if r.get("success", false):
			harvested += 1
			total_yield += int(r.get("yield", 0))
	return {"success": harvested > 0, "details": {"harvested": harvested, "total_yield": total_yield}}

func _do_fertilize(positions: Array[Vector2i], gm: Node, params: Dictionary) -> Dictionary:
	var amount: float = float(params.get("npk_amount", 10))	# 0..100 scale used as delta
	var applied := 0
	for p in positions:
		var tile = gm.get_tile(p)
		if tile:
			# Apply a simple, balanced fertilizer via SoilChemistry if present
			if "soil_chemistry" in gm and gm.soil_chemistry != null:
				gm.soil_chemistry.apply_fertilizer(tile, "balanced", amount)
			# Nudge GridManager to publish updates
			gm.set_tile(p, tile)
			applied += 1
	return {"success": applied > 0, "details": {"fertilized": applied}}

func _do_test_soil(positions: Array[Vector2i], gm: Node) -> Dictionary:
	if positions.is_empty():
		return {"success": false, "reason": "no_target"}
	var p: Vector2i = positions[0]
	var tile = gm.get_tile(p)
	if tile == null:
		return {"success": false, "reason": "no_tile"}
	return {"success": true, "details": {"pos": p, "tile_info": tile.to_dict()}}
