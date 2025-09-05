extends Node
# NetworkManager.gd - AUTOLOAD #10
# Handles hosting/joining/leaving sessions and basic event relay.
# Dependencies: GameManager (autoload #1), EventManager (global events)

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
const DEFAULT_PORT: int = 24565

# ============================================================================
# DATA STRUCTURES
# ============================================================================
# connected_peers: Array[int] of peer IDs (excludes self)

# ============================================================================
# SIGNALS
# ============================================================================
signal network_started(mode: String, endpoint: String)
signal network_stopped()
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connection_failed(reason: String)
signal server_disconnected()
signal event_received(event_name: String, payload: Dictionary, from_peer: int)

# ============================================================================
# PROPERTIES
# ============================================================================
var game_manager: Node = null
var event_manager: Node = null

var is_host: bool = false
var peer: MultiplayerPeer = null
var connected_peers: Array[int] = []

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "NetworkManager"
	print("[NetworkManager] Initializing as Autoload #10...")

	# Connect to systems
	game_manager = GameManager
	event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		event_manager = get_node_or_null("/root/EventBus")	# optional fallback

	# Register with GameManager
	if game_manager and game_manager.has_method("register_system"):
		game_manager.register_system("NetworkManager", self)
		print("[NetworkManager] Registered with GameManager")

	# Bind multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	_ensure_net_inputs()

	multiplayer.peer_connected.connect(func(id): print("[NET] peer_connected: ", id))
	multiplayer.peer_disconnected.connect(func(id): print("[NET] peer_disconnected: ", id))
	multiplayer.connected_to_server.connect(func(): print("[NET] connected_to_server"))
	multiplayer.connection_failed.connect(func(): print("[NET] connection_failed"))
	multiplayer.server_disconnected.connect(func(): print("[NET] server_disconnected"))

	print("[NetworkManager] Initialization complete")
	_ensure_net_inputs()

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func host(port: int) -> bool:
	if multiplayer.has_multiplayer_peer():
		leave()
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_server(port)
	if err != OK:
		print("[NET] Host failed: ", err)
		return false
	multiplayer.multiplayer_peer = enet
	is_host = true
	print("[NET] Hosting on port ", port)
	return true

func join(ip: String, port: int) -> bool:
	if multiplayer.has_multiplayer_peer():
		leave()
	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_client(ip, port)
	if err != OK:
		print("[NET] Join failed: ", err)
		return false
	multiplayer.multiplayer_peer = enet
	is_host = false
	print("[NET] Joining ", ip, ":", port)
	return true

func leave() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	multiplayer.multiplayer_peer = null
	is_host = false
	connected_peers.clear()
	print("[NET] Left session")

func send_event(event_name: String, payload: Dictionary = {}, target_peer_id: int = 0) -> void:
	"""Broadcast a small event to all peers (or a specific peer)."""
	if not multiplayer.has_multiplayer_peer():
		return
	if target_peer_id == 0:
		rpc("rpc_receive_event", event_name, payload)
	else:
		rpc_id(target_peer_id, "rpc_receive_event", event_name, payload)

@rpc("any_peer", "call_local")
func rpc_receive_event(event_name: String, payload: Dictionary) -> void:
	"""Receive a network event and rebroadcast on EventManager."""
	var from_peer: int = multiplayer.get_remote_sender_id()
	emit_signal("event_received", event_name, payload, from_peer)

	# Forward to EventManager if available
	if event_manager:
		if event_manager.has_method("emit"):
			event_manager.emit(event_name, payload)
		elif event_manager.has_method("dispatch"):
			event_manager.dispatch(event_name, payload)

# ============================================================================
# SYSTEM INTEGRATION
# ============================================================================
func _on_peer_connected(id: int) -> void:
	if id != multiplayer.get_unique_id():
		if not connected_peers.has(id):
			connected_peers.append(id)
	emit_signal("peer_connected", id)
	print("[NetworkManager] Peer connected: ", id)

func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)
	emit_signal("peer_disconnected", id)
	print("[NetworkManager] Peer disconnected: ", id)

func _on_connected_to_server() -> void:
	print("[NetworkManager] Connected to server")

func _on_connection_failed() -> void:
	emit_signal("connection_failed", "connection_failed")
	print("[NetworkManager] Connection failed")

func _on_server_disconnected() -> void:
	emit_signal("server_disconnected")
	print("[NetworkManager] Server disconnected")
	is_host = false

func _ensure_net_inputs() -> void:
	# Host (K)
	if not InputMap.has_action("net_host"):
		InputMap.add_action("net_host")
	InputMap.action_erase_events("net_host")
	var ev := InputEventKey.new(); ev.keycode = KEY_K
	InputMap.action_add_event("net_host", ev)

	# Join (L)
	if not InputMap.has_action("net_join"):
		InputMap.add_action("net_join")
	InputMap.action_erase_events("net_join")
	var ev2 := InputEventKey.new(); ev2.keycode = KEY_L
	InputMap.action_add_event("net_join", ev2)

	# Leave (F9) — unchanged
	if not InputMap.has_action("net_leave"):
		InputMap.add_action("net_leave")
	InputMap.action_erase_events("net_leave")
	var ev3 := InputEventKey.new(); ev3.keycode = KEY_F9
	InputMap.action_add_event("net_leave", ev3)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("net_host"):
		var ok := host(25252)
		print("[NET] host K -> ", ok)
	if event.is_action_pressed("net_join"):
		var ok := join("127.0.0.1", 25252)
		print("[NET] join L -> ", ok)
	if event.is_action_pressed("net_leave"):
		leave()
		print("[NET] leave F9")


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func get_peer_id() -> int:
	return multiplayer.get_unique_id()

func is_network_active() -> bool:
	return multiplayer.has_multiplayer_peer()



# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"is_host": is_host,
		"active": multiplayer.has_multiplayer_peer(),
		"self_id": multiplayer.get_unique_id(),
		"peers": connected_peers.size()
	}
