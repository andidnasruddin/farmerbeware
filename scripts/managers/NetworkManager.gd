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

	print("[NetworkManager] Initialization complete")

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func host(port: int = DEFAULT_PORT) -> bool:
	"""Host a server on the given port."""
	if multiplayer.has_multiplayer_peer():
		print("[NetworkManager] Already in a session; leave() first")
		return false

	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_server(port)
	if err != OK:
		print("[NetworkManager] Host failed: ", err)
		return false

	multiplayer.multiplayer_peer = enet
	peer = enet
	is_host = true
	connected_peers.clear()
	emit_signal("network_started", "host", "localhost:%d" % port)
	print("[NetworkManager] Hosting on port %d" % port)
	return true

func join(ip: String, port: int = DEFAULT_PORT) -> bool:
	"""Join a server at ip:port."""
	if multiplayer.has_multiplayer_peer():
		print("[NetworkManager] Already in a session; leave() first")
		return false

	var enet := ENetMultiplayerPeer.new()
	var err := enet.create_client(ip, port)
	if err != OK:
		print("[NetworkManager] Join failed: ", err)
		return false

	multiplayer.multiplayer_peer = enet
	peer = enet
	is_host = false
	connected_peers.clear()
	emit_signal("network_started", "client", "%s:%d" % [ip, port])
	print("[NetworkManager] Joining %s:%d" % [ip, port])
	return true

func leave() -> void:
	"""Leave current session (host or client)."""
	if not multiplayer.has_multiplayer_peer():
		return

	multiplayer.multiplayer_peer = null
	peer = null
	is_host = false
	connected_peers.clear()
	emit_signal("network_stopped")
	print("[NetworkManager] Left session")

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
