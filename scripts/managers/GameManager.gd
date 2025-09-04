extends Node
# GameManager.gd - AUTOLOAD #1 (MUST BE FIRST!)
# The main orchestrator that manages all game systems and state
# class_name GameManager

# ============================================================================
# GAME STATES - These control the high-level flow of the game
# ============================================================================
enum GameState {
	BOOT,           # Loading resources and initializing systems
	MENU,           # Main menu is active
	LOBBY,          # Multiplayer setup and character selection
	LOADING,        # Transitioning between scenes
	PLAYING,        # In the farm scene, actively playing
	PAUSED,         # Game is paused (can still interact with UI)
	RESULTS,        # Showing day/run results
	GAME_OVER       # Run ended, showing final stats
}

# ============================================================================
# SIGNALS - Other systems can listen to these events
# ============================================================================
signal state_changed(from_state: GameState, to_state: GameState)
signal money_changed(new_amount: int, change: int)
signal player_joined(player_info: Dictionary)
signal player_left(player_info: Dictionary)
signal game_over(reason: String, final_stats: Dictionary)
signal run_started()
signal run_ended(stats: Dictionary)

# ============================================================================
# CORE PROPERTIES - The main data this manager tracks
# ============================================================================
@export var current_state: GameState = GameState.BOOT
@export var debug_mode: bool = false
@export var max_players: int = 4

# Player Management
var active_players: Array[Dictionary] = []
var player_count: int = 0

# Economy (Shared money pool for co-op)
var current_money: int = 1000  # Starting money
var min_money: int = 0         # Can't go below zero

# Runtime tracking
var total_runtime: float = 0.0
var is_paused: bool = false
var current_scene_path: String = ""
var current_scene: Node = null

# System references (will be set by other autoloads when they initialize)
var grid_manager: Node = null
var time_manager: Node = null
var network_manager: Node = null

# ============================================================================
# INITIALIZATION - Called when GameManager is loaded as autoload
# ============================================================================
func _ready() -> void:
	print("[GameManager] Initializing as Autoload #1...")
	
	# Set up this node
	name = "GameManager"
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep running even when paused
	
	# Enable debug mode in development
	if OS.is_debug_build():
		debug_mode = true
		print("[GameManager] Debug mode enabled")
	
	# Initialize the game state
	_change_state(GameState.BOOT)
	
	# Start the boot sequence
	_start_boot_sequence()
	
	print("[GameManager] Initialization complete!")

# ============================================================================
# BOOT SEQUENCE - Sets up the game when it first starts
# ============================================================================
func _start_boot_sequence() -> void:
	print("[GameManager] Starting boot sequence...")
	
	# Wait a frame to ensure all autoloads are ready
	await get_tree().process_frame
	
	# Initialize core systems
	_initialize_core_systems()
	
	# Load main menu after boot is complete
	await get_tree().create_timer(0.5).timeout  # Small delay for loading
	_change_state(GameState.MENU)
	
	print("[GameManager] Boot sequence complete!")

func _initialize_core_systems() -> void:
	print("[GameManager] Initializing core systems...")
	
	# Register with other systems (they'll call register_system when ready)
	print("[GameManager] Waiting for other autoloads to register...")

# ============================================================================
# STATE MANAGEMENT - Controls high-level game flow
# ============================================================================
func _change_state(new_state: GameState) -> void:
	var old_state: GameState = current_state
	
	if old_state == new_state:
		return  # No change needed
	
	print("[GameManager] State change: %s -> %s" % [_state_to_string(old_state), _state_to_string(new_state)])
	
	# Exit old state
	_exit_state(old_state)
	
	# Enter new state
	current_state = new_state
	_enter_state(new_state)
	
	# Notify all listeners
	state_changed.emit(old_state, new_state)

func _enter_state(state: GameState) -> void:
	match state:
		GameState.BOOT:
			print("[GameManager] Entering BOOT state")
		
		GameState.MENU:
			print("[GameManager] Entering MENU state")
			# TODO: Load main menu scene
		
		GameState.LOBBY:
			print("[GameManager] Entering LOBBY state")
			# TODO: Setup multiplayer lobby
		
		GameState.LOADING:
			print("[GameManager] Entering LOADING state")
		
		GameState.PLAYING:
			print("[GameManager] Entering PLAYING state")
			is_paused = false
		
		GameState.PAUSED:
			print("[GameManager] Entering PAUSED state")
			is_paused = true
			get_tree().paused = true
		
		GameState.RESULTS:
			print("[GameManager] Entering RESULTS state")
		
		GameState.GAME_OVER:
			print("[GameManager] Entering GAME_OVER state")

func _exit_state(state: GameState) -> void:
	match state:
		GameState.PAUSED:
			get_tree().paused = false
			is_paused = false

# ============================================================================
# MONEY SYSTEM - Shared economy for all players
# ============================================================================
func get_money() -> int:
	return current_money

func can_afford(amount: int) -> bool:
	return current_money >= amount

func spend_money(amount: int, reason: String = "") -> bool:
	if not can_afford(amount):
		print("[GameManager] Cannot afford %d money (have %d)" % [amount, current_money])
		return false
	
	var old_money: int = current_money
	current_money = max(min_money, current_money - amount)
	var actual_change: int = old_money - current_money
	
	print("[GameManager] Spent %d money for '%s' (remaining: %d)" % [actual_change, reason, current_money])
	money_changed.emit(current_money, -actual_change)
	
	return true

func add_money(amount: int, reason: String = "") -> void:
	var old_money: int = current_money
	current_money += amount
	var actual_change: int = current_money - old_money
	
	print("[GameManager] Gained %d money from '%s' (total: %d)" % [actual_change, reason, current_money])
	money_changed.emit(current_money, actual_change)

# ============================================================================
# PLAYER MANAGEMENT - Handle players joining and leaving
# ============================================================================
func get_player_count() -> int:
	return active_players.size()

func can_add_player() -> bool:
	return get_player_count() < max_players

func add_player(player_info: Dictionary) -> bool:
	if not can_add_player():
		print("[GameManager] Cannot add player - lobby full (%d/%d)" % [get_player_count(), max_players])
		return false
	
	# Assign unique player ID
	player_info["id"] = active_players.size()
	player_info["joined_at"] = Time.get_unix_time_from_system()
	
	active_players.append(player_info)
	player_count = active_players.size()
	
	print("[GameManager] Player joined: %s (total: %d)" % [player_info.get("name", "Unknown"), player_count])
	player_joined.emit(player_info)
	
	return true

func remove_player(player_id: int) -> void:
	for i in range(active_players.size()):
		if active_players[i]["id"] == player_id:
			var player_info: Dictionary = active_players[i]
			active_players.remove_at(i)
			player_count = active_players.size()
			
			print("[GameManager] Player left: %s (remaining: %d)" % [player_info.get("name", "Unknown"), player_count])
			player_left.emit(player_info)
			break

# ============================================================================
# SYSTEM REGISTRATION - Other autoloads register with GameManager
# ============================================================================
func register_system(system_name: String, system_node: Node) -> void:
	print("[GameManager] System registered: %s" % system_name)
	
	# Store references to key systems
	match system_name:
		"GridManager":
			grid_manager = system_node
		"TimeManager":
			time_manager = system_node
		"NetworkManager":
			network_manager = system_node

# ============================================================================
# PUBLIC API - Functions other systems can call
# ============================================================================
func change_state(new_state: GameState) -> void:
	_change_state(new_state)

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		_change_state(GameState.PAUSED)

func unpause_game() -> void:
	if current_state == GameState.PAUSED:
		_change_state(GameState.PLAYING)

func start_new_run() -> void:
	print("[GameManager] Starting new run...")
	current_money = 1000  # Reset starting money
	active_players.clear()
	player_count = 0
	
	_change_state(GameState.LOBBY)
	run_started.emit()

func end_run(reason: String = "completed", stats: Dictionary = {}) -> void:
	print("[GameManager] Run ended: %s" % reason)
	
	var final_stats: Dictionary = {
		"reason": reason,
		"runtime": total_runtime,
		"final_money": current_money,
		"players": active_players.size()
	}
	final_stats.merge(stats)
	
	_change_state(GameState.GAME_OVER)
	run_ended.emit(final_stats)
	game_over.emit(reason, final_stats)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _state_to_string(state: GameState) -> String:
	match state:
		GameState.BOOT: return "BOOT"
		GameState.MENU: return "MENU"
		GameState.LOBBY: return "LOBBY"
		GameState.LOADING: return "LOADING"
		GameState.PLAYING: return "PLAYING"
		GameState.PAUSED: return "PAUSED"
		GameState.RESULTS: return "RESULTS"
		GameState.GAME_OVER: return "GAME_OVER"
		_: return "UNKNOWN"

func _process(delta: float) -> void:
	total_runtime += delta
	
	# Debug shortcuts (only in debug mode)
	if debug_mode and Input.is_action_just_pressed("ui_accept"):
		if Input.is_key_pressed(KEY_SHIFT):
			# Shift+Enter = Add test money
			add_money(500, "debug cheat")

func get_debug_info() -> Dictionary:
	return {
		"state": _state_to_string(current_state),
		"money": current_money,
		"players": player_count,
		"runtime": total_runtime,
		"paused": is_paused
	}
