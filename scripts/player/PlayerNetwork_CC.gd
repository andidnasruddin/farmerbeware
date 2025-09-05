extends Node
class_name PlayerNetwork_CC
# PlayerNetwork_CC.gd - CLAUDE CODE FIXED VERSION
# Same functionality as PlayerNetwork.gd but with crash protection

@export var player_path: NodePath
@export var net_update_hz: int = 12
@export var min_send_delta_px: float = 1.0

const SERVER_ID: int = 1

var _player: PlayerController = null
var _carry: CarrySystem = null

var _accum: float = 0.0
var _last_sent_pos: Vector2 = Vector2.INF
var _last_sent_facing: Vector2 = Vector2.ZERO
var _last_tool: String = ""
var _connected: bool = false   # client-side: becomes true on connected_to_server

func _ready() -> void:
	print("[NET] PlayerNetwork ready; my_id=", _safe_get_unique_id())
	process_mode = Node.PROCESS_MODE_INHERIT

	# SAFE VERSION: Original logic with null checks
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as PlayerController  # Added get_node_or_null
	if _player == null:
		# SAFE VERSION: Check if tree exists before calling get_first_node_in_group
		if get_tree():
			var n := get_tree().get_first_node_in_group("player")
			_player = n as PlayerController

	# SAFE VERSION: Added has_node check
	if _player and _player.has_node("CarrySystem"):
		_carry = _player.get_node("CarrySystem") as CarrySystem

	# SAFE VERSION: Added signal connection safety
	if _player:
		if _player.has_signal("tool_changed") and not _player.tool_changed.is_connected(_on_tool_changed):
			_player.tool_changed.connect(_on_tool_changed)

	# Client will mark itself connected here
	# SAFE VERSION: Check multiplayer exists
	if multiplayer and multiplayer.connected_to_server:
		multiplayer.connected_to_server.connect(func():
			_connected = true
			print("[NET Client] connected_to_server")
		)

	# Host does not need _connected; it is always authoritative when a peer joins
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	# No network → single player
	# SAFE VERSION: Use safe multiplayer checks
	if not _safe_has_multiplayer_peer():
		return

	# Only clients send upstream, and only after connected_to_server fired.
	if _safe_is_server():
		return
	if not _connected:
		return

	_accum += delta
	var step := 1.0 / float(max(1, net_update_hz))
	if _accum >= step:
		_accum = 0.0
		_send_position_if_changed()

func _send_position_if_changed() -> void:
	if _player == null:
		return

	var pos: Vector2 = _player.global_position
	var facing: Vector2 = _player.facing_direction

	if _last_sent_pos.is_finite():
		if pos.distance_to(_last_sent_pos) < min_send_delta_px and facing.is_equal_approx(_last_sent_facing):
			return

	_last_sent_pos = pos
	_last_sent_facing = facing

	# Clients send to host
	print("[NET Client] sent pos=", pos, " facing=", facing, " -> host")
	rpc_update_position.rpc_id(SERVER_ID, pos, facing)

func _on_tool_changed(tool_name: String) -> void:
	_last_tool = tool_name
	# SAFE VERSION: Use safe multiplayer checks
	if not _safe_has_multiplayer_peer():
		return
	# Clients inform host; host applies in rpc_sync_tool
	if not _safe_is_server() and _connected:
		rpc_sync_tool.rpc_id(SERVER_ID, tool_name)

# SAFE VERSION: Helper functions for multiplayer safety
func _safe_get_unique_id() -> int:
	if multiplayer:
		return multiplayer.get_unique_id()
	return 0

func _safe_has_multiplayer_peer() -> bool:
	return multiplayer and multiplayer.has_multiplayer_peer()

func _safe_is_server() -> bool:
	return multiplayer and multiplayer.is_server()

func _safe_get_remote_sender_id() -> int:
	if multiplayer:
		return multiplayer.get_remote_sender_id()
	return 0

# ======================================================================
# RPCs (host authority) - SAME AS ORIGINAL BUT WITH SAFETY
# ======================================================================

@rpc("any_peer", "unreliable")
func rpc_update_position(pos: Vector2, facing: Vector2) -> void:
	# Host receives client updates; apply authoritative state
	# SAFE VERSION: Use safe server check
	if _safe_is_server():
		var from := _safe_get_remote_sender_id()
		print("[NET Host] recv pos from peer=", from, " pos=", pos)
		if _player:
			_player.global_position = pos
			if facing.length() > 0.1:
				_player.facing_direction = facing.normalized()

@rpc("any_peer")
func rpc_sync_tool(tool_name: String) -> void:
	# SAFE VERSION: Use safe server check
	if _safe_is_server():
		if _player:
			_player.current_tool = tool_name
			# SAFE VERSION: Check signal exists before emitting
			if _player.has_signal("tool_changed"):
				_player.tool_changed.emit(tool_name)

@rpc("any_peer")
func rpc_perform_action(tool_name: String, grid_pos: Vector2i, facing: Vector2i) -> void:
	# SAFE VERSION: Use safe server check
	if _safe_is_server():
		var sender := _safe_get_remote_sender_id()
		print("[NET Host] action from peer=", sender, " tool=", tool_name, " at=", grid_pos)
		# SAFE VERSION: Added null check and method existence check
		if InteractionSystem and InteractionSystem.has_method("request_action_from_network"):
			InteractionSystem.request_action_from_network(sender, tool_name, grid_pos, facing)

@rpc("any_peer")
func rpc_pickup_item(item_path: String) -> void:
	# SAFE VERSION: Use safe server check
	if _safe_is_server() and _carry:
		var item := get_node_or_null(item_path) as Item
		if item:
			# SAFE VERSION: Check method exists before calling
			if _carry.has_method("_try_pickup"):
				_carry._try_pickup()

@rpc("any_peer")
func rpc_throw_item(dir: Vector2) -> void:
	# SAFE VERSION: Use safe server check
	if _safe_is_server() and _carry:
		# SAFE VERSION: Check method exists before calling
		if _carry.has_method("_do_throw"):
			_carry._do_throw()

# ======================================================================
# Public helpers - SAME AS ORIGINAL BUT WITH SAFETY
# ======================================================================

func request_network_action(tool_name: String, grid_pos: Vector2i, facing: Vector2i) -> void:
	# Call from PlayerController when in MP (clients ask host)
	# SAFE VERSION: Use safe multiplayer checks
	if not _safe_has_multiplayer_peer():
		return
	if not _safe_is_server() and _connected:
		rpc_perform_action.rpc_id(SERVER_ID, tool_name, grid_pos, facing)
