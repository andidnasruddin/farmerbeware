extends Node
class_name NetworkHelper_CC
# NetworkHelper_CC.gd - CLAUDE CODE ADDITION
# Safe helper for network-InteractionSystem communication
# This prevents crashes when InteractionSystem is not ready

# ============================================================================
# SAFE INTERACTION SYSTEM INTERFACE
# ============================================================================

static func safely_request_network_action(peer_id: int, tool_name: String, grid_pos: Vector2i, facing: Vector2i) -> bool:
	"""Safely request an action through InteractionSystem with full error handling"""
	
	# Validate inputs
	if not _validate_network_action_params(peer_id, tool_name, grid_pos, facing):
		return false
	
	# Find InteractionSystem safely
	var interaction_system = _get_interaction_system()
	if not interaction_system:
		print("[NET_HELPER] InteractionSystem not available")
		return false
	
	# Check if the system is ready
	if not _is_interaction_system_ready(interaction_system):
		print("[NET_HELPER] InteractionSystem not ready yet")
		return false
	
	# Call the method safely
	if interaction_system.has_method("request_action_from_network"):
		interaction_system.request_action_from_network(peer_id, tool_name, grid_pos, facing)
		print("[NET_HELPER] Successfully routed network action: ", tool_name, " at ", grid_pos)
		return true
	else:
		print("[NET_HELPER] InteractionSystem missing request_action_from_network method")
		return false

static func _validate_network_action_params(peer_id: int, tool_name: String, grid_pos: Vector2i, facing: Vector2i) -> bool:
	"""Validate network action parameters"""
	if peer_id <= 0:
		print("[NET_HELPER] Invalid peer_id: ", peer_id)
		return false
	
	if tool_name.is_empty():
		print("[NET_HELPER] Empty tool_name")
		return false
	
	# Basic grid position validation (reasonable bounds)
	if abs(grid_pos.x) > 10000 or abs(grid_pos.y) > 10000:
		print("[NET_HELPER] Grid position out of reasonable bounds: ", grid_pos)
		return false
	
	# Basic facing validation
	if abs(facing.x) > 1 or abs(facing.y) > 1:
		print("[NET_HELPER] Invalid facing direction: ", facing)
		return false
	
	return true

static func _get_interaction_system() -> Node:
	"""Safely get InteractionSystem reference"""
	# Try multiple methods to find InteractionSystem
	
	# Method 1: Direct autoload path
	var system = Engine.get_singleton("InteractionSystem")
	if system:
		return system
	
	# Method 2: Node path from root
	var tree = Engine.get_main_loop()
	if tree and tree.has_method("get_node_or_null"):
		var scene_tree = tree as SceneTree
		if scene_tree and scene_tree.current_scene:
			system = scene_tree.get_first_node_in_group("interaction_system")
			if system:
				return system
	
	return null

static func _is_interaction_system_ready(interaction_system: Node) -> bool:
	"""Check if InteractionSystem is fully initialized"""
	if not interaction_system:
		return false
	
	# Check if it has the input_queue property (indicates initialization)
	if interaction_system.has_method("get") and interaction_system.get("input_queue"):
		return true
	
	# Check if it has required methods
	if not interaction_system.has_method("request_action_from_network"):
		print("[NET_HELPER] InteractionSystem missing required method")
		return false
	
	return true

# ============================================================================
# NETWORK STATE HELPERS
# ============================================================================

static func is_network_host() -> bool:
	"""Safely check if we are network host"""
	if Engine.get_singleton("NetworkManager"):
		var nm = Engine.get_singleton("NetworkManager")
		if nm.has_method("get") and nm.get("is_host"):
			return nm.is_host
	return false

static func is_network_active() -> bool:
	"""Safely check if network is active"""
	var mp = Engine.get_main_loop()
	if mp and mp.has_method("has_multiplayer_peer"):
		var scene_tree = mp as SceneTree
		if scene_tree and scene_tree.multiplayer:
			return scene_tree.multiplayer.has_multiplayer_peer()
	return false

static func get_network_peer_id() -> int:
	"""Safely get network peer ID"""
	var mp = Engine.get_main_loop()
	if mp and mp.has_method("get_unique_id"):
		var scene_tree = mp as SceneTree
		if scene_tree and scene_tree.multiplayer:
			return scene_tree.multiplayer.get_unique_id()
	return 0

# ============================================================================
# DEBUG HELPERS
# ============================================================================

static func get_debug_network_state() -> Dictionary:
	"""Get debug information about network state"""
	return {
		"is_host": is_network_host(),
		"is_active": is_network_active(),
		"peer_id": get_network_peer_id(),
		"interaction_system_available": _get_interaction_system() != null,
		"interaction_system_ready": _is_interaction_system_ready(_get_interaction_system()),
		"version": "CLAUDE_CODE_HELPER"
	}

static func log_debug_network_state() -> void:
	"""Log current network debug state"""
	var state = get_debug_network_state()
	print("[NET_HELPER] Network State: ", state)
