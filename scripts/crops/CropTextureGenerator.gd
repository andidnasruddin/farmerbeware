@tool
extends EditorScript
class_name CropTextureGenerator
# CropTextureGenerator.gd - Utility to generate placeholder textures for crops
# Generates simple colored rectangles for different growth stages

# ============================================================================
# CONSTANTS
# ============================================================================
const TEXTURE_SIZE: Vector2i = Vector2i(32, 32)
const STAGE_COLORS: Array[Color] = [
	Color.BROWN,			# Seed - brown dot
	Color.GREEN * 0.6,		# Sprout - dark green
	Color.GREEN * 0.8,		# Young - medium green  
	Color.GREEN,			# Mature - bright green
	Color.ORANGE,			# Overripe - orange
	Color.GRAY				# Dead - gray
]

# ============================================================================
# MAIN GENERATION FUNCTIONS
# ============================================================================
func run() -> void:
	"""Generate placeholder textures for all crops"""
	print("[CropTextureGenerator] Starting texture generation...")
	
	# Create directories if they don't exist
	_ensure_directories()
	
	# Generate textures for each crop type
	generate_lettuce_textures()
	generate_corn_textures() 
	generate_wheat_textures()
	
	print("[CropTextureGenerator] Texture generation completed!")

func _ensure_directories() -> void:
	"""Create necessary directories for textures"""
	var dir: DirAccess = DirAccess.open("res://")
	
	if not dir.dir_exists("textures"):
		dir.make_dir("textures")
	if not dir.dir_exists("textures/crops"):
		dir.make_dir("textures/crops")
	if not dir.dir_exists("textures/crops/tier1"):
		dir.make_dir("textures/crops/tier1")

# ============================================================================
# SPECIFIC CROP TEXTURE GENERATION
# ============================================================================
func generate_lettuce_textures() -> void:
	"""Generate textures for lettuce crop"""
	print("[CropTextureGenerator] Generating lettuce textures...")
	
	var lettuce_colors: Array[Color] = [
		Color.BROWN,			# Seed
		Color.LIME_GREEN * 0.4,	# Sprout - light green
		Color.LIME_GREEN * 0.7,	# Young - brighter green
		Color.LIME_GREEN,		# Mature - full brightness
		Color.YELLOW,			# Overripe - yellowing
		Color.GRAY				# Dead
	]
	
	_generate_crop_textures("lettuce", lettuce_colors)

func generate_corn_textures() -> void:
	"""Generate textures for corn crop"""
	print("[CropTextureGenerator] Generating corn textures...")
	
	var corn_colors: Array[Color] = [
		Color.BROWN,			# Seed
		Color.FOREST_GREEN,		# Sprout - dark green
		Color.GREEN,			# Young - green stalk
		Color.GOLD,				# Mature - golden corn
		Color.DARK_ORANGE,		# Overripe - darker
		Color.GRAY				# Dead
	]
	
	_generate_crop_textures("corn", corn_colors)

func generate_wheat_textures() -> void:
	"""Generate textures for wheat crop"""
	print("[CropTextureGenerator] Generating wheat textures...")
	
	var wheat_colors: Array[Color] = [
		Color.BROWN,			# Seed
		Color.GREEN * 0.5,		# Sprout - muted green
		Color.GREEN * 0.8,		# Young - greener
		Color.WHEAT,			# Mature - wheat color
		Color.BROWN * 1.2,		# Overripe - brownish
		Color.GRAY				# Dead
	]
	
	_generate_crop_textures("wheat", wheat_colors)

# ============================================================================
# TEXTURE CREATION UTILITIES
# ============================================================================
func _generate_crop_textures(crop_name: String, colors: Array[Color]) -> void:
	"""Generate textures for a specific crop with given colors"""
	
	for stage_index in colors.size():
		var stage_name: String = _get_stage_name(stage_index)
		var filename: String = "res://textures/crops/tier1/%s_%s.png" % [crop_name, stage_name]
		
		var texture: ImageTexture = _create_colored_texture(colors[stage_index], crop_name, stage_index)
		_save_texture_as_png(texture, filename)
	
	print("[CropTextureGenerator] Generated %d textures for %s" % [colors.size(), crop_name])

func _create_colored_texture(color: Color, crop_name: String, stage: int) -> ImageTexture:
	"""Create a simple colored texture representing the crop stage"""
	var image: Image = Image.create(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	
	# Fill with base color
	image.fill(color)
	
	# Add some visual variety based on stage
	_add_stage_details(image, color, stage)
	
	# Create texture from image
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	return texture

func _add_stage_details(image: Image, base_color: Color, stage: int) -> void:
	"""Add visual details to distinguish different growth stages"""
	
	match stage:
		0: # Seed - small brown dot in center
			var center: Vector2i = TEXTURE_SIZE / 2
			_draw_circle(image, center, 3, Color.SADDLE_BROWN)
		
		1: # Sprout - small vertical line
			var center_x: int = TEXTURE_SIZE.x / 2
			for y in range(TEXTURE_SIZE.y / 2, TEXTURE_SIZE.y - 4):
				image.set_pixel(center_x, y, base_color.lightened(0.2))
		
		2: # Young - slightly larger, more defined
			var center: Vector2i = TEXTURE_SIZE / 2
			_draw_circle(image, center, 6, base_color.lightened(0.1))
		
		3: # Mature - full size, bright
			# Already filled with base color, add slight highlight
			var highlight_color: Color = base_color.lightened(0.3)
			for x in range(2, TEXTURE_SIZE.x - 2):
				for y in range(2, TEXTURE_SIZE.y - 2):
					if (x + y) % 4 == 0:  # Create pattern
						image.set_pixel(x, y, highlight_color)
		
		4: # Overripe - slightly darker edges
			var dark_color: Color = base_color.darkened(0.2)
			_draw_border(image, dark_color, 2)
		
		5: # Dead - very muted with spots
			for x in range(0, TEXTURE_SIZE.x, 4):
				for y in range(0, TEXTURE_SIZE.y, 4):
					image.set_pixel(x, y, Color.BLACK)

func _draw_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	"""Draw a circle on the image"""
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			if x >= 0 and x < TEXTURE_SIZE.x and y >= 0 and y < TEXTURE_SIZE.y:
				var distance: float = Vector2(x - center.x, y - center.y).length()
				if distance <= radius:
					image.set_pixel(x, y, color)

func _draw_border(image: Image, color: Color, thickness: int) -> void:
	"""Draw border around image"""
	for thickness_offset in thickness:
		# Top and bottom borders
		for x in range(TEXTURE_SIZE.x):
			image.set_pixel(x, thickness_offset, color)
			image.set_pixel(x, TEXTURE_SIZE.y - 1 - thickness_offset, color)
		
		# Left and right borders  
		for y in range(TEXTURE_SIZE.y):
			image.set_pixel(thickness_offset, y, color)
			image.set_pixel(TEXTURE_SIZE.x - 1 - thickness_offset, y, color)

func _save_texture_as_png(texture: ImageTexture, filepath: String) -> void:
	"""Save texture to disk as PNG"""
	var image: Image = texture.get_image()
	var error: Error = image.save_png(filepath)
	
	if error != OK:
		print("[CropTextureGenerator] ERROR saving texture to %s: %d" % [filepath, error])
	else:
		print("[CropTextureGenerator] Saved texture: %s" % filepath)

func _get_stage_name(stage_index: int) -> String:
	"""Get name for growth stage"""
	var stage_names: Array[String] = [
		"seed",
		"sprout", 
		"young",
		"mature",
		"overripe",
		"dead"
	]
	
	if stage_index < stage_names.size():
		return stage_names[stage_index]
	else:
		return "stage_%d" % stage_index

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func generate_single_color_texture(color: Color, filename: String) -> ImageTexture:
	"""Generate a simple single-color texture for testing"""
	var image: Image = Image.create(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	
	if not filename.is_empty():
		_save_texture_as_png(texture, filename)
	
	return texture

# ============================================================================
# EDITOR TESTING
# ============================================================================
func test_texture_generation() -> void:
	"""Test texture generation with a single example"""
	print("[CropTextureGenerator] Testing texture generation...")
	
	var test_texture: ImageTexture = generate_single_color_texture(
		Color.GREEN,
		"res://textures/crops/test_texture.png"
	)
	
	print("[CropTextureGenerator] Test texture created: %s" % test_texture)