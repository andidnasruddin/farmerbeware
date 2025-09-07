extends Node
class_name CropVisuals
# CropVisuals.gd - Component for managing crop visual representation and effects
# Handles growth stage textures, health indicators, and visual feedback
# Dependencies: CropData, Sprite2D nodes

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
const TEXTURE_TRANSITION_DURATION: float = 0.2
const HEALTH_INDICATOR_FADE_TIME: float = 1.0
const GROWTH_PARTICLE_DURATION: float = 0.5

enum VisualState {
	NORMAL,			# Standard appearance
	HEALTHY,		# Vibrant, well-cared appearance
	STRESSED,		# Wilted, needs attention
	DYING,			# Very poor health
	MATURE_READY	# Ready for harvest, special glow
}

# ============================================================================
# SIGNALS
# ============================================================================
signal texture_changed(old_texture: Texture2D, new_texture: Texture2D)
signal visual_state_changed(old_state: VisualState, new_state: VisualState)
signal growth_effect_played(effect_type: String)

# ============================================================================
# PROPERTIES
# ============================================================================
# Component references
var crop_controller: Node2D = null
var crop_data: CropData = null
var visuals_sprite: Sprite2D = null

# Visual state tracking
var current_visual_state: VisualState = VisualState.NORMAL
var current_stage_index: int = 0
var current_growth_progress: float = 0.0

# Texture management
var stage_textures: Array[Texture2D] = []
var current_texture: Texture2D = null
var placeholder_texture: Texture2D = null

# Visual effects
var health_tint: Color = Color.WHITE
var base_scale: Vector2 = Vector2.ONE
var current_scale: Vector2 = Vector2.ONE

# Animation tweening - using scene tweens not node tweens
var texture_tween: Tween = null
var scale_tween: Tween = null
var color_tween: Tween = null

# Effect containers (will be populated from crop scene)
var effects_container: Node2D = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func initialize(crop: Node2D, crop_resource: CropData) -> void:
	"""Initialize visuals component with crop reference"""
	crop_controller = crop
	crop_data = crop_resource
	
	if crop_controller:
		# Get visual nodes from parent crop scene
		visuals_sprite = crop_controller.get_node("Sprite2D") as Sprite2D
		effects_container = crop_controller.get_node("GrowthParticles") as GPUParticles2D
		
		# Check if we successfully got the required nodes
		if not visuals_sprite:
			print("[CropVisuals] WARNING: Could not find Sprite2D node")
		if not effects_container:
			print("[CropVisuals] WARNING: Could not find GrowthParticles node")
		
		print("[CropVisuals] Initializing visuals for %s" % crop_data.crop_name)
		
		# Set up visual parameters
		_setup_visual_parameters()
		
		# Initialize visual state
		_initialize_visuals()
	else:
		print("[CropVisuals] ERROR: No crop controller provided!")

func _setup_visual_parameters() -> void:
	"""Set up visual parameters from crop data"""
	if not crop_data:
		print("[CropVisuals] WARNING: No crop data available")
		return
	
	# Load stage textures from crop data
	stage_textures = crop_data.growth_stage_textures.duplicate()
	
	# Set base scale and other visual properties
	base_scale = Vector2.ONE
	current_scale = base_scale
	health_tint = Color.WHITE
	
	print("[CropVisuals] Loaded %d stage textures" % stage_textures.size())

func _initialize_visuals() -> void:
	"""Initialize visual representation"""
	if not visuals_sprite:
		print("[CropVisuals] ERROR: No visuals sprite available!")
		return
	
	# Create tweens for smooth transitions
	_create_tweens()
	
	# Set initial texture (seed stage)
	_set_stage_texture(0)
	
	# Set initial visual state
	_change_visual_state(VisualState.NORMAL)
	
	# Set initial sprite properties
	visuals_sprite.modulate = Color.WHITE
	visuals_sprite.scale = base_scale

func _create_tweens() -> void:
	"""Create Tween references for smooth visual transitions"""
	if texture_tween:
		texture_tween.kill()
	if scale_tween:
		scale_tween.kill()
	if color_tween:
		color_tween.kill()
	
	# Using create_tween() creates scene tweens, not node tweens
	texture_tween = create_tween()
	scale_tween = create_tween()  
	color_tween = create_tween()

# ============================================================================
# CORE FUNCTIONALITY
# ============================================================================
func update_growth(progress: float) -> void:
	"""Update visuals based on growth progress"""
	if not crop_data or stage_textures.is_empty():
		return
	
	current_growth_progress = progress
	
	# Calculate stage index based on progress
	var new_stage_index: int = int(progress * stage_textures.size())
	new_stage_index = clamp(new_stage_index, 0, stage_textures.size() - 1)
	
	# Update texture if stage changed
	if new_stage_index != current_stage_index:
		_advance_to_stage(new_stage_index)

func _advance_to_stage(stage_index: int) -> void:
	"""Advance to a specific growth stage with visual transition"""
	var old_stage: int = current_stage_index
	current_stage_index = stage_index
	
	print("[CropVisuals] Advancing to stage %d" % stage_index)
	
	# Set new texture with transition
	_set_stage_texture(stage_index)
	
	# Play growth effect
	_play_growth_effect()
	
	# Update scale slightly for visual feedback
	_animate_growth_pop()

func _set_stage_texture(stage_index: int) -> void:
	"""Set texture for specific growth stage"""
	if not visuals_sprite:
		return
	
	var old_texture: Texture2D = current_texture
	
	# Get texture for stage
	if stage_index < stage_textures.size():
		current_texture = stage_textures[stage_index]
	else:
		# Use mature texture if available
		if crop_data and crop_data.mature_texture:
			current_texture = crop_data.mature_texture
		elif not stage_textures.is_empty():
			current_texture = stage_textures[-1]  # Use last texture
	
	if current_texture:
		# Smooth texture transition
		if texture_tween:
			visuals_sprite.modulate.a = 0.7  # Fade slightly
			visuals_sprite.texture = current_texture
			
			texture_tween.tween_property(visuals_sprite, "modulate:a", 1.0, TEXTURE_TRANSITION_DURATION)
			texture_tween.tween_callback(_on_texture_transition_complete)
	else:
		print("[CropVisuals] No texture available for stage %d" % stage_index)
	
	texture_changed.emit(old_texture, current_texture)

func _on_texture_transition_complete() -> void:
	"""Called when texture transition animation completes"""
	# Ensure sprite is fully opaque
	if visuals_sprite:
		visuals_sprite.modulate.a = 1.0

func _animate_growth_pop() -> void:
	"""Animate small scale increase when advancing stages"""
	if not visuals_sprite or not scale_tween:
		return
	
	var pop_scale: Vector2 = current_scale * 1.1
	var pop_duration: float = 0.15
	
	scale_tween.tween_property(visuals_sprite, "scale", pop_scale, pop_duration * 0.5)
	scale_tween.tween_property(visuals_sprite, "scale", current_scale, pop_duration * 0.5)

func _play_growth_effect() -> void:
	"""Play visual effect for growth stage advancement"""
	# This would spawn particles, play sounds, etc.
	# For now just emit signal
	growth_effect_played.emit("stage_advance")
	
	print("[CropVisuals] Growth effect played: stage_advance")

# ============================================================================
# HEALTH AND STATE VISUALIZATION
# ============================================================================
func update_health_visual(health: float) -> void:
	"""Update visual appearance based on health level"""
	var new_state: VisualState
	
	if health >= 0.8:
		new_state = VisualState.HEALTHY
		health_tint = Color(1.0, 1.1, 1.0)  # Slight green tint
	elif health >= 0.5:
		new_state = VisualState.NORMAL
		health_tint = Color.WHITE
	elif health >= 0.2:
		new_state = VisualState.STRESSED
		health_tint = Color(1.0, 0.9, 0.8)  # Slightly yellow
	else:
		new_state = VisualState.DYING
		health_tint = Color(0.8, 0.7, 0.6)  # Brown/wilted
	
	if new_state != current_visual_state:
		_change_visual_state(new_state)
	
	# Apply health tint smoothly
	_animate_health_tint()

func _change_visual_state(new_state: VisualState) -> void:
	"""Change visual state with appropriate effects"""
	var old_state: VisualState = current_visual_state
	current_visual_state = new_state
	
	print("[CropVisuals] Visual state changed: %s → %s" % [
		VisualState.keys()[old_state],
		VisualState.keys()[new_state]
	])
	
	# Apply state-specific visual changes
	match new_state:
		VisualState.HEALTHY:
			current_scale = base_scale * 1.05  # Slightly larger
		VisualState.NORMAL:
			current_scale = base_scale
		VisualState.STRESSED:
			current_scale = base_scale * 0.95  # Slightly smaller
		VisualState.DYING:
			current_scale = base_scale * 0.9   # Noticeably smaller
		VisualState.MATURE_READY:
			current_scale = base_scale * 1.1   # Larger, ready for harvest
	
	# Animate scale change
	_animate_scale_change()
	
	visual_state_changed.emit(old_state, new_state)

func _animate_health_tint() -> void:
	"""Animate health-based color tinting"""
	if not visuals_sprite or not color_tween:
		return
	
	var target_color: Color = health_tint
	target_color.a = visuals_sprite.modulate.a  # Preserve alpha
	
	color_tween.tween_property(visuals_sprite, "modulate", target_color, HEALTH_INDICATOR_FADE_TIME)

func _animate_scale_change() -> void:
	"""Animate scale changes for visual states"""
	if not visuals_sprite or not scale_tween:
		return
	
	scale_tween.tween_property(visuals_sprite, "scale", current_scale, 0.3)

# ============================================================================
# SPECIAL VISUAL EFFECTS
# ============================================================================
func show_maturity_ready() -> void:
	"""Show visual indication that crop is ready for harvest"""
	_change_visual_state(VisualState.MATURE_READY)
	
	# Could add glow effect, pulsing, etc.
	_start_harvest_ready_effect()

func _start_harvest_ready_effect() -> void:
	"""Start harvest ready visual effect"""
	# This could pulse the sprite, add a glow, etc.
	if not visuals_sprite:
		return
	
	# Simple pulsing effect using scene tween
	var pulse_tween: Tween = create_tween()
	
	var pulse_scale: Vector2 = current_scale * 1.02
	pulse_tween.set_loops()
	pulse_tween.tween_property(visuals_sprite, "scale", pulse_scale, 0.8)
	pulse_tween.tween_property(visuals_sprite, "scale", current_scale, 0.8)

func show_water_effect(water_added: float) -> void:
	"""Show visual effect when crop is watered"""
	growth_effect_played.emit("watered")
	
	# Could spawn water droplet particles
	print("[CropVisuals] Water effect: %.1f%% added" % (water_added * 100.0))

func show_harvest_effect() -> void:
	"""Show visual effect when crop is harvested"""
	growth_effect_played.emit("harvested")
	
	# Animate crop disappearing
	_animate_harvest_removal()

func _animate_harvest_removal() -> void:
	"""Animate crop removal after harvest"""
	if not visuals_sprite or not scale_tween:
		return
	
	# Fade out and scale down
	scale_tween.parallel().tween_property(visuals_sprite, "scale", Vector2.ZERO, 0.4)
	color_tween.parallel().tween_property(visuals_sprite, "modulate:a", 0.0, 0.4)

func show_quality_preview(quality: int) -> void:
	"""Show quality preview (stars, color coding, etc.)"""
	var quality_color: Color
	
	match quality:
		1: quality_color = Color.GRAY      # Poor
		2: quality_color = Color.WHITE     # Normal
		3: quality_color = Color.GOLD      # Good
		4: quality_color = Color.MAGENTA   # Perfect
		_: quality_color = Color.WHITE
	
	# Tint sprite slightly with quality color
	if visuals_sprite:
		var tinted_color: Color = Color.WHITE.lerp(quality_color, 0.3)
		visuals_sprite.modulate = tinted_color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func get_current_texture() -> Texture2D:
	"""Get the currently displayed texture"""
	return current_texture

func get_visual_state() -> VisualState:
	"""Get current visual state"""
	return current_visual_state

func get_stage_index() -> int:
	"""Get current stage index"""
	return current_stage_index

func set_visibility(visible: bool) -> void:
	"""Set crop visibility"""
	if visuals_sprite:
		visuals_sprite.visible = visible

func force_texture_update() -> void:
	"""Force texture update based on current stage"""
	_set_stage_texture(current_stage_index)

func reset_visual_effects() -> void:
	"""Reset all visual effects to default state"""
	if visuals_sprite:
		visuals_sprite.modulate = Color.WHITE
		visuals_sprite.scale = base_scale
	
	current_visual_state = VisualState.NORMAL
	health_tint = Color.WHITE
	current_scale = base_scale

func update_visual_state() -> void:
	"""Update visual state based on current crop health and stage"""
	if not crop_controller:
		return
	
	# Update health visual based on crop's current health
	update_health_visual(crop_controller.health)
	
	# Update growth visuals based on growth progress
	update_growth(crop_controller.growth_progress)
	
	# Check if ready for harvest
	if crop_controller.is_ready_to_harvest():
		show_maturity_ready()

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	"""Get comprehensive debug information"""
	return {
		"current_visual_state": VisualState.keys()[current_visual_state],
		"current_stage_index": current_stage_index,
		"current_growth_progress": "%.1f%%" % (current_growth_progress * 100.0),
		"loaded_textures": stage_textures.size(),
		"current_texture_valid": current_texture != null,
		"health_tint": health_tint,
		"current_scale": current_scale,
		"base_scale": base_scale,
		"sprite_visible": visuals_sprite.visible if visuals_sprite else false,
		"sprite_modulate": visuals_sprite.modulate if visuals_sprite else Color.WHITE
	}

func print_debug_info() -> void:
	"""Print debug information to console"""
	print("[CropVisuals] === Visuals Debug Info ===")
	var debug_data: Dictionary = get_debug_info()
	for key in debug_data:
		print("[CropVisuals] %s: %s" % [key, debug_data[key]])
	print("[CropVisuals] === End Debug Info ===")

# Component cleanup
func cleanup() -> void:
	"""Clean up component resources"""
	# Clean up tweens
	if texture_tween:
		texture_tween.kill()
	if scale_tween:
		scale_tween.kill()
	if color_tween:
		color_tween.kill()
	
	print("[CropVisuals] Component cleaned up")
