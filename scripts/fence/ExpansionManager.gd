extends Node
class_name ExpansionManager
# ExpansionManager.gd - Land expansion coordination (signals + validation)
# Dependencies: GridManager (required), FenceSystem (optional)

# ============================================================================
# SIGNALS
# ============================================================================
signal expansion_requested(target_size: Vector2i)
signal expansion_approved(target_size: Vector2i, estimated_cost: int)
signal expansion_rejected(target_size: Vector2i, reason: String)
signal expansion_completed(final_size: Vector2i)

# ============================================================================
# PROPERTIES
# ============================================================================
@export var max_size: Vector2i = Vector2i(100, 100)
var grid_manager: Node = null
var fence_system: Node = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "ExpansionManager"
	grid_manager = get_node_or_null("/root/GridManager")
	fence_system = get_node_or_null("/root/FenceSystem")
	if grid_manager == null:
		print("[ExpansionManager] WARNING: GridManager not found (expand disabled)")
	print("[ExpansionManager] Ready")

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func request_expand_to(new_size: Vector2i) -> bool:
	"""Validate and execute a grid expansion. Returns true if completed."""
	emit_signal("expansion_requested", new_size)

	if grid_manager == null:
		emit_signal("expansion_rejected", new_size, "no_grid_manager")
		return false

	# Clamp to maximum allowed
	var target: Vector2i = Vector2i(
		clamp(new_size.x, 1, max_size.x),
		clamp(new_size.y, 1, max_size.y)
	)

	# Check current size
	var current_size: Vector2i = new_size
	if "grid_size" in grid_manager:
		current_size = grid_manager.grid_size
	if target.x <= current_size.x and target.y <= current_size.y:
		emit_signal("expansion_rejected", new_size, "not_larger_than_current")
		return false

	# Placeholder cost (to be integrated with economy later)
	var estimated_cost: int = 0
	emit_signal("expansion_approved", target, estimated_cost)

	# Apply expansion via GridManager
	if grid_manager.has_method("expand_grid"):
		grid_manager.expand_grid(target)
	else:
		emit_signal("expansion_rejected", new_size, "expand_method_missing")
		return false

	# Sync fence if present
	if fence_system and fence_system.has_method("expand_to"):
		fence_system.expand_to(target)

	emit_signal("expansion_completed", target)
	print("[ExpansionManager] Expansion completed to %s" % [target])
	return true

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"max_size": max_size,
		"gm": grid_manager != null,
		"fence": fence_system != null
	}
