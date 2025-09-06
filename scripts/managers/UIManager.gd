extends Node
# UIManager.gd - AUTOLOAD #14
# Manages UI screens, overlays, popups, and input mode routing.
# Dependencies: GameManager (state-driven screens), EventManager (optional dispatch), SaveManager (optional)

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
enum InputMode { UI, GAME }

# ============================================================================
# DATA STRUCTURES
# ============================================================================
# screen_paths: { id:String -> scene_path:String }
# overlay_paths: { id:String -> scene_path:String }
# active_overlays: { id:String -> Control }
# popup_stack: Array[Control]

# ============================================================================
# SIGNALS
# ============================================================================
signal screen_changed(from_id: String, to_id: String)
signal screen_shown(id: String)
signal screen_hidden(id: String)
signal overlay_shown(id: String)
signal overlay_hidden(id: String)
signal popup_opened(path: String)
signal popup_closed(path: String)
signal input_mode_changed(mode: int)

# ============================================================================
# PROPERTIES
# ============================================================================
var game_manager: Node = null
var event_manager: Node = null
var save_manager: Node = null

var ui_layer: CanvasLayer = null
var screen_root: Control = null
var overlay_root: Control = null
var popup_root: Control = null

var screen_paths: Dictionary = {}	# id -> path
var overlay_paths: Dictionary = {}	# id -> path

var current_screen_id: String = ""
var current_screen_node: Control = null

var active_overlays: Dictionary = {}	# id -> Control
var popup_stack: Array[Control] = []

var current_input_mode: int = InputMode.UI

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "UIManager"
	print("[UIManager] Initializing as Autoload #14...")

	# Connect systems
	game_manager = GameManager
	event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		event_manager = get_node_or_null("/root/EventBus")
	save_manager = get_node_or_null("/root/SaveManager")

	# Register with GameManager
	if game_manager and game_manager.has_method("register_system"):
		game_manager.register_system("UIManager", self)
		if game_manager.has_signal("state_changed"):
			game_manager.state_changed.connect(_on_game_state_changed)
		print("[UIManager] Registered with GameManager")

	_init_ui_roots()
	_register_default_overlays()
	print("[UIManager] Initialization complete")

func _init_ui_roots() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	add_child(ui_layer)

	screen_root = Control.new()
	screen_root.name = "Screens"
	screen_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(screen_root)

	overlay_root = Control.new()
	overlay_root.name = "Overlays"
	overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(overlay_root)

	popup_root = Control.new()
	popup_root.name = "Popups"
	popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(popup_root)

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func register_screen(id: String, scene_path: String) -> void:
	if id.is_empty() or scene_path.is_empty():
		return
	screen_paths[id] = scene_path

func register_overlay(id: String, scene_path: String) -> void:
	if id.is_empty() or scene_path.is_empty():
		return
	overlay_paths[id] = scene_path

func show_screen(id: String) -> bool:
	if id == current_screen_id:
		return true
	if not screen_paths.has(id):
		print("[UIManager] WARNING: No screen registered for id: ", id)
		return false

	var from_id: String = current_screen_id
	_hide_current_screen()

	var path: String = String(screen_paths.get(id, ""))
	var ps: PackedScene = load(path) as PackedScene
	if ps == null:
		print("[UIManager] ERROR: Failed to load screen: ", path)
		return false

	var inst: Node = ps.instantiate()
	var ui: Control = inst as Control
	if ui == null:
		inst.queue_free()
		print("[UIManager] ERROR: Screen is not a Control: ", path)
		return false

	screen_root.add_child(ui)
	current_screen_node = ui
	current_screen_id = id

	emit_signal("screen_shown", id)
	emit_signal("screen_changed", from_id, id)
	_emit_event("ui_screen_changed", {"from": from_id, "to": id})
	return true

func hide_screen(id: String) -> void:
	if id != current_screen_id:
		return
	_hide_current_screen()

func _hide_current_screen() -> void:
	if current_screen_node != null:
		var old_id: String = current_screen_id
		current_screen_node.queue_free()
		current_screen_node = null
		current_screen_id = ""
		emit_signal("screen_hidden", old_id)

func show_overlay(id: String) -> bool:
	if active_overlays.has(id):
		return true
	if not overlay_paths.has(id):
		print("[UIManager] WARNING: No overlay registered for id: ", id)
		return false

	var path: String = String(overlay_paths.get(id, ""))
	var ps: PackedScene = load(path) as PackedScene
	if ps == null:
		print("[UIManager] ERROR: Failed to load overlay: ", path)
		return false

	var inst: Node = ps.instantiate()
	var ui: Control = inst as Control
	if ui == null:
		inst.queue_free()
		print("[UIManager] ERROR: Overlay is not a Control: ", path)
		return false

	overlay_root.add_child(ui)
	active_overlays[id] = ui
	emit_signal("overlay_shown", id)
	_emit_event("ui_overlay_shown", {"id": id})
	return true

func hide_overlay(id: String) -> void:
	if not active_overlays.has(id):
		return
	var ui: Control = active_overlays[id]
	if ui:
		ui.queue_free()
	active_overlays.erase(id)
	emit_signal("overlay_hidden", id)
	_emit_event("ui_overlay_hidden", {"id": id})

func hide_all_overlays() -> void:
	var to_remove: Array[String] = []
	for k in active_overlays.keys():
		to_remove.append(String(k))
	for id in to_remove:
		hide_overlay(id)

func push_popup(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	var ps: PackedScene = load(scene_path) as PackedScene
	if ps == null:
		print("[UIManager] ERROR: Failed to load popup: ", scene_path)
		return false

	var inst: Node = ps.instantiate()
	var ui: Control = inst as Control
	if ui == null:
		inst.queue_free()
		print("[UIManager] ERROR: Popup is not a Control: ", scene_path)
		return false

	popup_root.add_child(ui)
	popup_stack.append(ui)
	emit_signal("popup_opened", scene_path)
	_emit_event("ui_popup_opened", {"path": scene_path})
	return true

func pop_popup() -> void:
	if popup_stack.is_empty():
		return
	var top: Control = popup_stack.pop_back()
	if top:
		var path: String = top.scene_file_path
		top.queue_free()
		emit_signal("popup_closed", path)
		_emit_event("ui_popup_closed", {"path": path})

func clear_popups() -> void:
	while not popup_stack.is_empty():
		pop_popup()

func set_input_mode(mode: int) -> void:
	if mode == current_input_mode:
		return
	current_input_mode = mode
	emit_signal("input_mode_changed", mode)
	_emit_event("ui_input_mode", {"mode": mode})

# ============================================================================
# SYSTEM INTEGRATION
# ============================================================================
func _on_game_state_changed(from_state: int, to_state: int) -> void:
	match to_state:
		GameManager.GameState.MENU:
			show_screen_if_registered("menu")
			hide_all_overlays()
			clear_popups()
			set_input_mode(InputMode.UI)

		GameManager.GameState.PLAYING:
			show_screen_if_registered("hud")	# Only if you have a HUD screen
			hide_overlay_if_active("pause")
			show_overlay_if_registered("time_display")
			show_overlay_if_registered("weather_overlay")
			set_input_mode(InputMode.GAME)

		GameManager.GameState.PAUSED:
			show_overlay_if_registered("pause")
			set_input_mode(InputMode.UI)

		GameManager.GameState.LOADING:
			show_overlay_if_registered("loading")
			set_input_mode(InputMode.UI)

		GameManager.GameState.RESULTS:
			show_screen_if_registered("results")
			set_input_mode(InputMode.UI)

		GameManager.GameState.GAME_OVER:
			show_screen_if_registered("game_over")
			hide_all_overlays()
			clear_popups()
			set_input_mode(InputMode.UI)

		_:
			pass

func _register_default_overlays() -> void:
	register_overlay("countdown", "res://scenes/time/CountdownOverlay.tscn")
	register_overlay("phase_transition", "res://scenes/time/PhaseTransition.tscn")
	register_overlay("time_display", "res://scenes/time/TimeDisplay.tscn")
	register_overlay("calendar", "res://scenes/time/CalendarUI.tscn")
	register_overlay("weather_overlay", "res://scenes/events/WeatherOverlay.tscn")
	register_overlay("debug_overlay", "res://scenes/debug/DebugOverlay.tscn")

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _emit_event(event_name: String, payload: Dictionary) -> void:
	if event_manager == null:
		return
	if event_manager.has_method("emit"):
		event_manager.emit(event_name, payload)
	elif event_manager.has_method("dispatch"):
		event_manager.dispatch(event_name, payload)

func show_overlay_if_registered(id: String) -> void:
	if overlay_paths.has(id):
		show_overlay(id)

func hide_overlay_if_active(id: String) -> void:
	if active_overlays.has(id):
		hide_overlay(id)

func show_screen_if_registered(id: String) -> void:
	if screen_paths.has(id):
		show_screen(id)

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	return {
		"current_screen": current_screen_id,
		"overlays": active_overlays.keys(),
		"popups": popup_stack.size(),
		"input_mode": current_input_mode
	}
