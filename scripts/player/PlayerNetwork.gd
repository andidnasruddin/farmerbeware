extends Node
class_name PlayerNetwork

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
	print("[NET] PlayerNetwork ready; my_id=", multiplayer.get_unique_id())
	process_mode = Node.PROCESS_MODE_INHERIT

	if player_path != NodePath():
		_player = get_node(player_path) as PlayerController
	if _player == null:
		var n := get_tree().get_first_node_in_group("player")
		_player = n as PlayerController

	if _player and _player.has_node("CarrySystem"):
		_carry = _player.get_node("CarrySystem") as CarrySystem

	if _player:
		_player.tool_changed.connect(_on_tool_changed)

	# Client will mark itself connected here
	multiplayer.connected_to_server.connect(func():
		_connected = true
		print("[NET Client] connected_to_server")
	)

	# Host does not need _connected; it is always authoritative when a peer joins
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	# No network → single player
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return

	# Only clients send upstream, and only after connected_to_server fired.
	if multiplayer.is_server():
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
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
	# Clients inform host; host applies in rpc_sync_tool
	if not multiplayer.is_server() and _connected:
		rpc_sync_tool.rpc_id(SERVER_ID, tool_name)

# ======================================================================
# RPCs (host authority)
# ======================================================================

@rpc("any_peer", "unreliable")
func rpc_update_position(pos: Vector2, facing: Vector2) -> void:
	# Host receives client updates; defer applying to mapped avatar (to avoid overwriting local player)
	if multiplayer.is_server():
		var from := multiplayer.get_remote_sender_id()
		print("[NET Host] recv pos from peer=", from, " pos=", pos)

@rpc("any_peer")
func rpc_sync_tool(tool_name: String) -> void:
	# Host receives tool sync; defer applying until peer→avatar mapping exists
	if multiplayer.is_server():
		var from := multiplayer.get_remote_sender_id()
		print("[NET Host] tool from peer=", from, " tool=", tool_name)

@rpc("any_peer")
func rpc_perform_action(tool_name: String, grid_pos: Vector2i, facing: Vector2i) -> void:
	if multiplayer.is_server():
		var sender := multiplayer.get_remote_sender_id()
		print("[NET Host] action from peer=", sender, " tool=", tool_name, " at=", grid_pos)
		if InteractionSystem and InteractionSystem.has_method("request_action_from_network"):
			InteractionSystem.request_action_from_network(sender, tool_name, grid_pos, facing)

@rpc("any_peer")
func rpc_pickup_item(item_path: String) -> void:
	if multiplayer.is_server() and _carry:
		var item := get_node_or_null(item_path) as Item
		if item:
			_carry._try_pickup()

@rpc("any_peer")
func rpc_throw_item(dir: Vector2) -> void:
	if multiplayer.is_server() and _carry:
		_carry._do_throw()

# ======================================================================
# Public helpers
# ======================================================================

func request_network_action(tool_name: String, grid_pos: Vector2i, facing: Vector2i) -> void:
	# Call from PlayerController when in MP (clients ask host)
	if not multiplayer or not multiplayer.has_multiplayer_peer():
		return
	if not multiplayer.is_server() and _connected:
		rpc_perform_action.rpc_id(SERVER_ID, tool_name, grid_pos, facing)
