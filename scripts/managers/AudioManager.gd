extends Node
# AudioManager.gd - AUTOLOAD #13
# Centralized audio: SFX/BGM control, volumes, mute, and simple state-driven playback.
# Dependencies: GameManager (state), EventManager (optional dispatch), SaveManager (optional persistence)

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
const MAX_SFX_PLAYERS: int = 12
const DEFAULT_BUS_MASTER: String = "Master"
const DEFAULT_BUS_MUSIC: String = "Music"
const DEFAULT_BUS_SFX: String = "SFX"

# ============================================================================
# DATA STRUCTURES
# ============================================================================
# registered_bgm: { id:String -> AudioStream }
# registered_sfx: { id:String -> AudioStream }
# volumes: { "Master": float(0..1), "Music": float, "SFX": float }
# mutes: { "Master": bool, "Music": bool, "SFX": bool }

# ============================================================================
# SIGNALS
# ============================================================================
signal bgm_changed(track_id: String)
signal sfx_played(sfx_id: String)
signal volume_changed(bus: String, value: float)
signal muted_changed(bus: String, muted: bool)

# ============================================================================
# PROPERTIES
# ============================================================================
var game_manager: Node = null
var event_manager: Node = null
var save_manager: Node = null

var registered_bgm: Dictionary = {}
var registered_sfx: Dictionary = {}

var bgm_player: AudioStreamPlayer = null
var sfx_players: Array[AudioStreamPlayer] = []

var music_bus_name: String = DEFAULT_BUS_MUSIC
var sfx_bus_name: String = DEFAULT_BUS_SFX

var volumes: Dictionary = {
	"Master": 1.0,
	"Music": 1.0,
	"SFX": 1.0
}
var mutes: Dictionary = {
	"Master": false,
	"Music": false,
	"SFX": false
}

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "AudioManager"
	print("[AudioManager] Initializing as Autoload #13...")

	# Connect systems
	game_manager = GameManager
	event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		event_manager = get_node_or_null("/root/EventBus")
	save_manager = get_node_or_null("/root/SaveManager")

	# Register with GameManager
	if game_manager and game_manager.has_method("register_system"):
		game_manager.register_system("AudioManager", self)
		if game_manager.has_signal("state_changed"):
			game_manager.state_changed.connect(_on_game_state_changed)
		print("[AudioManager] Registered with GameManager")

	# Resolve preferred buses (fallback to Master if missing)
	music_bus_name = _resolve_or_fallback_bus(DEFAULT_BUS_MUSIC)
	sfx_bus_name = _resolve_or_fallback_bus(DEFAULT_BUS_SFX)

	# Create players
	_init_bgm_player()
	_init_sfx_pool()

	# Apply default volumes/mutes
	_apply_all_bus_settings()

	print("[AudioManager] Initialization complete")

func _init_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = music_bus_name
	add_child(bgm_player)

func _init_sfx_pool() -> void:
	for i in MAX_SFX_PLAYERS:
#		Create a small pool of SFX players for concurrent sounds
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		p.bus = sfx_bus_name
		p.pitch_scale = 1.0
		p.volume_db = 0.0
		add_child(p)
		sfx_players.append(p)

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func register_bgm(id: String, stream: AudioStream) -> void:
	if id.is_empty() or stream == null:
		return
	registered_bgm[id] = stream

func register_sfx(id: String, stream: AudioStream) -> void:
	if id.is_empty() or stream == null:
		return
	registered_sfx[id] = stream

func play_bgm(id: String, restart_if_same: bool = false) -> bool:
	if not registered_bgm.has(id):
		print("[AudioManager] WARNING: BGM id not registered: ", id)
		return false

	var current_id := bgm_player.stream
	if current_id == registered_bgm[id] and not restart_if_same:
		return true

	bgm_player.stop()
	bgm_player.stream = registered_bgm[id]
	bgm_player.play()
	emit_signal("bgm_changed", id)
	return true

func stop_bgm() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func play_sfx(id: String, volume_scale: float = 1.0, pitch_scale: float = 1.0) -> bool:
	if not registered_sfx.has(id):
		print("[AudioManager] WARNING: SFX id not registered: ", id)
		return false

	var p := _find_free_sfx_player()
	if p == null:
		# Steal the first player if all busy (simple policy)
		p = sfx_players[0]
	p.stop()
	p.stream = registered_sfx[id]
	p.pitch_scale = clamp(pitch_scale, 0.5, 2.0)
	p.volume_db = linear_to_db(clamp(volume_scale, 0.0, 1.0))
	p.play()
	emit_signal("sfx_played", id)
	return true

# Volume/mute control (0..1 linear volumes)
func set_volume(bus: String, value: float) -> void:
	var v: float = clamp(value, 0.0, 1.0)
	volumes[bus] = v
	_apply_bus_volume(bus, v)
	emit_signal("volume_changed", bus, v)

func get_volume(bus: String) -> float:
	return float(volumes.get(bus, 1.0))

func set_muted(bus: String, muted: bool) -> void:
	mutes[bus] = muted
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)
	emit_signal("muted_changed", bus, muted)

func is_muted(bus: String) -> bool:
	return bool(mutes.get(bus, false))

# ============================================================================
# SYSTEM INTEGRATION
# ============================================================================
func _on_game_state_changed(from_state: int, to_state: int) -> void:
	# Simple state → BGM policy; only plays if a track is registered
	match to_state:
		GameManager.GameState.MENU:
			play_bgm("menu")
		GameManager.GameState.PLAYING:
			play_bgm("playing")
		GameManager.GameState.PAUSED:
			# Optional: keep playing; could duck volumes here
			pass
		_:
			# Other states: stop if desired
			pass

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _find_free_sfx_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return null

func _apply_all_bus_settings() -> void:
	for k in volumes.keys():
		_apply_bus_volume(String(k), float(volumes[k]))
	for k in mutes.keys():
		set_muted(String(k), bool(mutes[k]))

func _apply_bus_volume(bus: String, value: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var v: float = max(0.0001, value)
	AudioServer.set_bus_volume_db(idx, linear_to_db(v))

func _resolve_or_fallback_bus(preferred: String) -> String:
	var idx := AudioServer.get_bus_index(preferred)
	if idx >= 0:
		return preferred
	return DEFAULT_BUS_MASTER

# Persistence helpers for SaveManager
func export_audio_settings() -> Dictionary:
	return {
		"volumes": volumes.duplicate(true),
		"mutes": mutes.duplicate(true)
	}

func import_audio_settings(data: Dictionary) -> void:
	if "volumes" in data and typeof(data["volumes"]) == TYPE_DICTIONARY:
		var vols: Dictionary = data["volumes"]
		for k in vols.keys():
			volumes[String(k)] = float(vols[k])
	if "mutes" in data and typeof(data["mutes"]) == TYPE_DICTIONARY:
		var mts: Dictionary = data["mutes"]
		for k in mts.keys():
			mutes[String(k)] = bool(mts[k])
	_apply_all_bus_settings()

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"bgm_playing": bgm_player != null and bgm_player.playing,
		"bgm_bus": music_bus_name,
		"sfx_bus": sfx_bus_name,
		"registered_bgm": registered_bgm.keys(),
		"registered_sfx": registered_sfx.keys(),
		"volumes": volumes,
		"mutes": mutes
	}
