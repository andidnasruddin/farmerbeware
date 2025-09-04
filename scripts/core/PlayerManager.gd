extends Node
# PlayerManager.gd - Manages individual player data and state
# Handles player creation, tools, positions, and stats
class_name PlayerManager

# ============================================================================
# PLAYER DATA STRUCTURE
# ============================================================================
class PlayerData:
	var id: int = -1
	var name: String = "Player"
	var color: Color = Color.WHITE
	var is_local: bool = false
	var is_host: bool = false
	
	# Game state
	var position: Vector2 = Vector2.ZERO
	var current_tool: String = "hoe"
	var carried_item: String = ""
	var stamina: float = 100.0
	var max_stamina: float = 100.0
	
	# Stats
	var crops_planted: int = 0
	var crops_harvested: int = 0
	var money_earned: int = 0
	var contracts_completed: int = 0
	
	# Network state
	var last_seen: float = 0.0
	var ping: int = 0
	
	func _init(player_id: int = -1, player_name: String = "Player") -> void:
		id = player_id
		name = player_name
		last_seen = Time.get_unix_time_from_system()
	
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"color": color,
			"is_local": is_local,
			"is_host": is_host,
			"position": position,
			"current_tool": current_tool,
			"carried_item": carried_item,
			"stamina": stamina,
			"max_stamina": max_stamina,
			"crops_planted": crops_planted,
			"crops_harvested": crops_harvested,
			"money_earned": money_earned,
			"contracts_completed": contracts_completed,
			"ping": ping
		}
	
	func from_dict(data: Dictionary) -> void:
		id = data.get("id", -1)
		name = data.get("name", "Player")
		color = data.get("color", Color.WHITE)
		is_local = data.get("is_local", false)
		is_host = data.get("is_host", false)
		position = data.get("position", Vector2.ZERO)
		current_tool = data.get("current_tool", "hoe")
		carried_item = data.get("carried_item", "")
		stamina = data.get("stamina", 100.0)
		max_stamina = data.get("max_stamina", 100.0)
		crops_planted = data.get("crops_planted", 0)
		crops_harvested = data.get("crops_harvested", 0)
		money_earned = data.get("money_earned", 0)
		contracts_completed = data.get("contracts_completed", 0)
		ping = data.get("ping", 0)

# ============================================================================
# SIGNALS
# ============================================================================
signal player_data_changed(player_id: int, property: String, value: Variant)
signal player_stats_updated(player_id: int, stats: Dictionary)

# ============================================================================
# PROPERTIES
# ============================================================================
var players: Dictionary = {}  # player_id -> PlayerData
var local_player_id: int = -1
var max_players: int = 4

# Default player colors
var player_colors: Array[Color] = [
	Color.BLUE,      # Player 1
	Color.RED,       # Player 2  
	Color.GREEN,     # Player 3
	Color.YELLOW     # Player 4
]

# Available tools
var available_tools: Array[String] = [
	"hoe", "watering_can", "seed_bag", "harvester", "fertilizer", "soil_test"
]

# ============================================================================
# INITIALIZATION
# ============================================================================
func _init() -> void:
	name = "PlayerManager"

func _ready() -> void:
	print("[PlayerManager] Initialized")

# ============================================================================
# PLAYER CREATION AND REMOVAL
# ============================================================================
func create_player(player_id: int, player_name: String = "", is_local_player: bool = false) -> PlayerData:
	if player_id in players:
		print("[PlayerManager] Player %d already exists" % player_id)
		return players[player_id]
	
	if players.size() >= max_players:
		print("[PlayerManager] Cannot create player - max players reached (%d)" % max_players)
		return null
	
	# Generate name if not provided
	if player_name.is_empty():
		player_name = "Player %d" % (player_id + 1)
	
	# Create player data
	var player_data: PlayerData = PlayerData.new(player_id, player_name)
	player_data.is_local = is_local_player
	player_data.color = player_colors[player_id % player_colors.size()]
	
	# Set as host if this is the first player
	if players.is_empty():
		player_data.is_host = true
	
	# Store player
	players[player_id] = player_data
	
	# Set local player reference
	if is_local_player:
		local_player_id = player_id
	
	print("[PlayerManager] Created player: %s (ID: %d, Local: %s)" % [player_name, player_id, is_local_player])
	return player_data

func remove_player(player_id: int) -> bool:
	if not player_id in players:
		print("[PlayerManager] Cannot remove player %d - doesn't exist" % player_id)
		return false
	
	var player_data: PlayerData = players[player_id]
	players.erase(player_id)
	
	print("[PlayerManager] Removed player: %s (ID: %d)" % [player_data.name, player_id])
	
	# If local player was removed, clear reference
	if player_id == local_player_id:
		local_player_id = -1
	
	return true

# ============================================================================
# PLAYER DATA ACCESS
# ============================================================================
func get_player(player_id: int) -> PlayerData:
	return players.get(player_id, null)

func get_local_player() -> PlayerData:
	if local_player_id != -1:
		return get_player(local_player_id)
	return null

func get_all_players() -> Array[PlayerData]:
	var player_list: Array[PlayerData] = []
	for player_data in players.values():
		player_list.append(player_data)
	return player_list

func get_player_count() -> int:
	return players.size()

func has_player(player_id: int) -> bool:
	return player_id in players

# ============================================================================
# PLAYER STATE UPDATES
# ============================================================================
func update_player_position(player_id: int, new_position: Vector2) -> void:
	var player_data: PlayerData = get_player(player_id)
	if not player_data:
		return
	
	player_data.position = new_position
	player_data.last_seen = Time.get_unix_time_from_system()
	player_data_changed.emit(player_id, "position", new_position)

func update_player_tool(player_id: int, tool: String) -> void:
	var player_data: PlayerData = get_player(player_id)
	if not player_data:
		return
	
	if tool in available_tools:
		player_data.current_tool = tool
		player_data_changed.emit(player_id, "current_tool", tool)
		print("[PlayerManager] Player %d switched to tool: %s" % [player_id, tool])

func update_player_carried_item(player_id: int, item: String) -> void:
	var player_data: PlayerData = get_player(player_id)
	if not player_data:
		return
	
	player_data.carried_item = item
	player_data_changed.emit(player_id, "carried_item", item)

func update_player_stamina(player_id: int, stamina: float) -> void:
	var player_data: PlayerData = get_player(player_id)
	if not player_data:
		return
	
	player_data.stamina = clamp(stamina, 0.0, player_data.max_stamina)
	player_data_changed.emit(player_id, "stamina", player_data.stamina)

# ============================================================================
# PLAYER STATS
# ============================================================================
func add_crop_planted(player_id: int, amount: int = 1) -> void:
	var player_data: PlayerData = get_player(player_id)
	if not player_data:
		return
	
	player_data.crops_planted += amount
	player_stats_updated.emit(player_id, {"crops_planted": player_data.crops_planted})

func add_crop_harvested(player_id: int, amount: int = 1) -> void:
	var player_data: PlayerData = get_player(player_id)
	if not player_data:
		return
	
	player_data.crops_harvested += amount
	player_stats_updated.emit(player_id, {"crops_harvested": player_data.crops_harvested})

func add_money_earned(player_id: int, amount: int) -> void:
	var player_data: PlayerData = get_player(player_id)
	if not player_data:
		return
	
	player_data.money_earned += amount
	player_stats_updated.emit(player_id, {"money_earned": player_data.money_earned})

func add_contract_completed(player_id: int) -> void:
	var player_data: PlayerData = get_player(player_id)
	if not player_data:
		return
	
	player_data.contracts_completed += 1
	player_stats_updated.emit(player_id, {"contracts_completed": player_data.contracts_completed})

# ============================================================================
# SERIALIZATION (for save/load and networking)
# ============================================================================
func serialize_all_players() -> Dictionary:
	var data: Dictionary = {}
	for player_id in players:
		data[str(player_id)] = players[player_id].to_dict()
	return data

func deserialize_all_players(data: Dictionary) -> void:
	players.clear()
	for player_id_str in data:
		var player_id: int = player_id_str.to_int()
		var player_data: PlayerData = PlayerData.new()
		player_data.from_dict(data[player_id_str])
		players[player_id] = player_data

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func get_next_available_id() -> int:
	for i in range(max_players):
		if not i in players:
			return i
	return -1  # No available slots

func get_host_player() -> PlayerData:
	for player_data in players.values():
		if player_data.is_host:
			return player_data
	return null

func reset_all_players() -> void:
	players.clear()
	local_player_id = -1
	print("[PlayerManager] All players reset")
