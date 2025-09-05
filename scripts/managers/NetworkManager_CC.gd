extends Node
# NetworkManager_CC.gd - CLAUDE CODE FIXED VERSION
# Fixed crash issues with F7/F8 keys and improved error handling
# Dependencies: GameManager (autoload #1), EventManager (global events)

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
const DEFAULT_PORT: int = 24565
const INPUT_DEBOUNCE_TIME: float = 0.5  # Prevent rapid key presses

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

# Input debouncing
var _last_input_time: float = 0.0
var _is_connecting: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "NetworkManager"
	print("[NetworkManager_CC] Initializing as Autoload #10 (CLAUDE CODE VERSION)...")

	# Wait one frame to ensure other autoloads are ready
	await get_tree().process_frame
	
	# Connect to systems with null checks
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("[NetworkManager_CC] WARNING: GameManager not found!")
	
	event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		event_manager = get_node_or_null("/root/EventBus")	# optional fallback

	# Register with GameManager safely
	if game_manager and game_manager.has_method("register_system"):
		game_manager.register_system("NetworkManager", self)
		print("[NetworkManager_CC] Registered with GameManager")

	# Bind multiplayer signals with error handling
	_setup_multiplayer_signals()
	_ensure_net_inputs()

	print("[NetworkManager_CC] Initialization complete")

func _setup_multiplayer_signals() -> void:
	"""Safely bind multiplayer signals with error handling"""
	if multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.disconnect(_on_peer_connected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)
	multiplayer.connection_failed.connect(_on_connection_failed)
	
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("[NetworkManager_CC] Multiplayer signals bound successfully")

# ============================================================================
# CORE FUNCTIONALITY - CRASH FIXES
# ============================================================================
func host(port: int) -> bool:
	if _is_connecting:
		print("[NET] Already connecting, ignoring host request")
		return false
	
	if not _is_port_valid(port):
		print("[NET] Invalid port: ", port)
		emit_signal("connection_failed", "invalid_port")
		return false
	
	_is_connecting = true
	
	# Clean shutdown existing connection
	if multiplayer.has_multiplayer_peer():
		print("[NET] Shutting down existing connection before hosting")
		leave()
		# Wait a frame to ensure cleanup
		await get_tree().process_frame
	
	var enet := ENetMultiplayerPeer.new()
	if not enet:
		print("[NET] Failed to create ENetMultiplayerPeer")
		_is_connecting = false
		emit_signal("connection_failed", "enet_creation_failed")
		return false
	
	var err := enet.create_server(port)
	if err != OK:
		print("[NET] Host failed with error: ", err, " (", _get_error_string(err), ")")
		_is_connecting = false
		emit_signal("connection_failed", "server_creation_failed")
		enet.close()
		return false
	
	# Apply peer safely
	multiplayer.multiplayer_peer = enet
	is_host = true
	peer = enet
	print("[NET] Successfully hosting on port ", port)
	emit_signal("network_started", "host", "0.0.0.0:" + str(port))
	_is_connecting = false
	return true

func join(ip: String, port: int) -> bool:
	if _is_connecting:
		print("[NET] Already connecting, ignoring join request")
		return false
	
	if not _is_ip_valid(ip) or not _is_port_valid(port):
		print("[NET] Invalid connection params: ", ip, ":", port)
		emit_signal("connection_failed", "invalid_params")
		return false
	
	_is_connecting = true
	
	# Clean shutdown existing connection
	if multiplayer.has_multiplayer_peer():
		print("[NET] Shutting down existing connection before joining")
		leave()
		# Wait a frame to ensure cleanup
		await get_tree().process_frame
	
	var enet := ENetMultiplayerPeer.new()
	if not enet:
		print("[NET] Failed to create ENetMultiplayerPeer")
		_is_connecting = false
		emit_signal("connection_failed", "enet_creation_failed")
		return false
	
	var err := enet.create_client(ip, port)
	if err != OK:
		print("[NET] Join failed with error: ", err, " (", _get_error_string(err), ")")
		_is_connecting = false
		emit_signal("connection_failed", "client_creation_failed")
		enet.close()
		return false
	
	# Apply peer safely
	multiplayer.multiplayer_peer = enet
	is_host = false
	peer = enet
	print("[NET] Attempting to join ", ip, ":", port)
	emit_signal("network_started", "client", ip + ":" + str(port))
	
	# Set a timeout for connection
	_start_connection_timeout()
	return true

func leave() -> void:
	"""Safely disconnect from network with proper cleanup"""
	_is_connecting = false
	
	if not multiplayer.has_multiplayer_peer():
		return
	
	# Notify before disconnecting
	emit_signal("network_stopped")
	
	# Clear state
	connected_peers.clear()
	is_host = false
	
	# Close peer connection
	if peer:
		peer.close()
		peer = null
	
	# Clear multiplayer peer
	multiplayer.multiplayer_peer = null
	
	print("[NET] Cleanly left session")

func _start_connection_timeout() -> void:
	"""Start a timeout timer for connection attempts"""
	await get_tree().create_timer(5.0).timeout
	if _is_connecting:
		print("[NET] Connection timeout")
		_is_connecting = false
		leave()
		emit_signal("connection_failed", "connection_timeout")

# ============================================================================
# VALIDATION HELPERS
# ============================================================================
func _is_port_valid(port: int) -> bool:
	return port > 1024 and port < 65535

func _is_ip_valid(ip: String) -> bool:
	if ip.is_empty():
		return false
	# Basic IP validation (accepts localhost and IPv4)
	if ip == "localhost" or ip == "127.0.0.1":
		return true
	# Simple IPv4 regex check
	var parts = ip.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		var num = part.to_int()
		if num < 0 or num > 255:
			return false
	return true

func _get_error_string(error_code: int) -> String:
	match error_code:
		OK: return "OK"
		ERR_BUSY: return "BUSY"
		ERR_UNAVAILABLE: return "UNAVAILABLE" 
		ERR_ALREADY_IN_USE: return "ALREADY_IN_USE"
		ERR_CANT_CONNECT: return "CANT_CONNECT"
		ERR_CANT_RESOLVE: return "CANT_RESOLVE"
		_: return "UNKNOWN_ERROR_" + str(error_code)

# ============================================================================
# INPUT HANDLING - DEBOUNCED
# ============================================================================
func _unhandled_input(event: InputEvent) -> void:
	var current_time = Time.get_unix_time_from_system()
	
	# Debounce rapid key presses
	if current_time - _last_input_time < INPUT_DEBOUNCE_TIME:
		return
	
	if event.is_action_pressed("net_host"):
		_last_input_time = current_time
		print("[NET] F7 pressed - attempting to host")
		_handle_host_async()
		
	elif event.is_action_pressed("net_join"):
		_last_input_time = current_time
		print("[NET] F8 pressed - attempting to join")
		_handle_join_async()
		
	elif event.is_action_pressed("net_leave"):
		_last_input_time = current_time
		print("[NET] F9 pressed - leaving")
		leave()
		print("[NET] leave F9")

func _handle_host_async() -> void:
	var ok := await host(25252)
	print("[NET] host F7 -> ", ok)

func _handle_join_async() -> void:
	var ok := await join("127.0.0.1", 25252)
	print("[NET] join F8 -> ", ok)

# ============================================================================
# RPC SYSTEM - SAFE
# ============================================================================
func send_event(event_name: String, payload: Dictionary = {}, target_peer_id: int = 0) -> void:
	"""Broadcast a small event to all peers (or a specific peer)."""
	if not multiplayer.has_multiplayer_peer():
		print("[NET] Cannot send event - no multiplayer peer")
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
# SYSTEM INTEGRATION - SAFE
# ============================================================================
func _on_peer_connected(id: int) -> void:
	if id != multiplayer.get_unique_id():
		if not connected_peers.has(id):
			connected_peers.append(id)
	emit_signal("peer_connected", id)
	print("[NetworkManager_CC] Peer connected: ", id)
	_is_connecting = false  # Connection successful

func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)
	emit_signal("peer_disconnected", id)
	print("[NetworkManager_CC] Peer disconnected: ", id)

func _on_connected_to_server() -> void:
	print("[NetworkManager_CC] Connected to server")
	_is_connecting = false

func _on_connection_failed() -> void:
	_is_connecting = false
	emit_signal("connection_failed", "connection_failed")
	print("[NetworkManager_CC] Connection failed")
	# Clean up failed connection
	leave()

func _on_server_disconnected() -> void:
	_is_connecting = false
	emit_signal("server_disconnected")
	print("[NetworkManager_CC] Server disconnected")
	# Clean up disconnected session
	leave()

func _ensure_net_inputs() -> void:
	"""Safely ensure network input actions exist"""
	if not InputMap.has_action("net_host"):
		InputMap.add_action("net_host")
		var ev := InputEventKey.new()
		ev.keycode = KEY_F7
		InputMap.action_add_event("net_host", ev)
		
	if not InputMap.has_action("net_join"):
		InputMap.add_action("net_join")
		var ev2 := InputEventKey.new()
		ev2.keycode = KEY_F8
		InputMap.action_add_event("net_join", ev2)
		
	if not InputMap.has_action("net_leave"):
		InputMap.add_action("net_leave")
		var ev3 := InputEventKey.new()
		ev3.keycode = KEY_F9
		InputMap.action_add_event("net_leave", ev3)
		
	print("[NetworkManager_CC] Network input actions configured")

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
		"active": is_network_active(),
		"self_id": get_peer_id(),
		"peers": connected_peers.size(),
		"connecting": _is_connecting,
		"version": "CLAUDE_CODE_FIXED"
	}
