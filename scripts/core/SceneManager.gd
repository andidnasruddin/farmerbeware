extends Node
# SceneManager.gd - Handles loading and transitioning between scenes
# Used by GameManager to manage scene changes smoothly
class_name SceneManager

# ============================================================================
# SIGNALS
# ============================================================================
signal scene_loading_started(scene_path: String)
signal scene_loading_progress(progress: float)
signal scene_loading_completed(scene: Node)
signal scene_transition_started()
signal scene_transition_completed()

# ============================================================================
# PROPERTIES
# ============================================================================
var current_scene: Node = null
var current_scene_path: String = ""
var is_loading: bool = false
var is_transitioning: bool = false

# Fade overlay for smooth transitions
var fade_overlay: ColorRect = null
var fade_tween: Tween = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _init() -> void:
	name = "SceneManager"

func _ready() -> void:
	# Get reference to the current scene
	current_scene = get_tree().current_scene
	if current_scene:
		current_scene_path = current_scene.scene_file_path
	
	# Create fade overlay for transitions
	_create_fade_overlay()
	
	print("[SceneManager] Initialized - Current scene: %s" % current_scene_path)

# ============================================================================
# SCENE LOADING
# ============================================================================
func load_scene(scene_path: String, use_fade: bool = true) -> void:
	if is_loading or is_transitioning:
		print("[SceneManager] Already loading/transitioning, ignoring request")
		return
	
	print("[SceneManager] Loading scene: %s" % scene_path)
	is_loading = true
	scene_loading_started.emit(scene_path)
	
	if use_fade:
		await _fade_out()
	
	# Start loading the scene
	var loader: ResourceLoader = ResourceLoader
	var resource: Resource = loader.load(scene_path)
	
	if resource == null:
		print("[SceneManager] ERROR: Failed to load scene: %s" % scene_path)
		is_loading = false
		if use_fade:
			await _fade_in()
		return
	
	# Instantiate the new scene
	var new_scene: Node = resource.instantiate()
	if new_scene == null:
		print("[SceneManager] ERROR: Failed to instantiate scene: %s" % scene_path)
		is_loading = false
		if use_fade:
			await _fade_in()
		return
	
	# Switch to the new scene
	await _switch_scene(new_scene, scene_path)
	
	if use_fade:
		await _fade_in()
	
	is_loading = false
	scene_loading_completed.emit(new_scene)
	print("[SceneManager] Scene loaded successfully: %s" % scene_path)

# ============================================================================
# SCENE SWITCHING
# ============================================================================
func _switch_scene(new_scene: Node, scene_path: String) -> void:
	is_transitioning = true
	scene_transition_started.emit()
	
	# Remove the old scene
	if current_scene and current_scene != get_tree().current_scene:
		current_scene.queue_free()
	
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	
	# Add the new scene
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	
	# Update references
	current_scene = new_scene
	current_scene_path = scene_path
	
	# Wait a frame for the scene to initialize
	await get_tree().process_frame
	
	is_transitioning = false
	scene_transition_completed.emit()

# ============================================================================
# FADE TRANSITIONS
# ============================================================================
func _create_fade_overlay() -> void:
	fade_overlay = ColorRect.new()
	fade_overlay.name = "SceneFadeOverlay"
	fade_overlay.color = Color.BLACK
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.modulate.a = 0.0  # Start invisible
	
	# Make it cover the entire screen
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add to the scene tree (as a child of root so it stays during transitions)
	get_tree().root.add_child(fade_overlay)
	
	# Move to front so it renders on top
	fade_overlay.z_index = 1000

func _fade_out(duration: float = 0.3) -> void:
	if not fade_overlay:
		return
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_overlay.show()
	fade_tween.tween_property(fade_overlay, "modulate:a", 1.0, duration)
	await fade_tween.finished

func _fade_in(duration: float = 0.3) -> void:
	if not fade_overlay:
		return
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "modulate:a", 0.0, duration)
	await fade_tween.finished
	fade_overlay.hide()

# ============================================================================
# QUICK TRANSITIONS (for common scenes)
# ============================================================================
func goto_main_menu() -> void:
	# TODO: Set correct path when main menu scene is created
	var main_menu_path: String = "res://scenes/ui/menus/MainMenu.tscn"
	if ResourceLoader.exists(main_menu_path):
		load_scene(main_menu_path)
	else:
		print("[SceneManager] Main menu scene not found: %s" % main_menu_path)

func goto_farm() -> void:
	# TODO: Set correct path when farm scene is created  
	var farm_path: String = "res://scenes/game/Farm.tscn"
	if ResourceLoader.exists(farm_path):
		load_scene(farm_path)
	else:
		print("[SceneManager] Farm scene not found: %s" % farm_path)

func goto_lobby() -> void:
	# TODO: Set correct path when lobby scene is created
	var lobby_path: String = "res://scenes/network/Lobby.tscn"
	if ResourceLoader.exists(lobby_path):
		load_scene(lobby_path)
	else:
		print("[SceneManager] Lobby scene not found: %s" % lobby_path)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func get_current_scene_name() -> String:
	if current_scene:
		return current_scene.name
	return "Unknown"

func get_current_scene_path() -> String:
	return current_scene_path

func is_scene_loaded(scene_path: String) -> bool:
	return current_scene_path == scene_path

# ============================================================================
# CLEANUP
# ============================================================================
func _exit_tree() -> void:
	if fade_overlay:
		fade_overlay.queue_free()
	
	if fade_tween:
		fade_tween.kill()
