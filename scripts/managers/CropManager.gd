extends Node
# CropManager.gd - AUTOLOAD #7
# Manages crop growth, quality, diseases, and special crop mechanics
# Dependencies: GridManager, TimeManager, EventManager

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
enum CropType {
	# Tier 1 - Easy crops
	LETTUCE,
	CORN,
	WHEAT,
	
	# Tier 2 - Medium crops
	TOMATO,
	POTATO,
	
	# Tier 3 - Hard crops
	PUMPKIN,
	STRAWBERRY,
	
	# Tier 4 - Expert crops
	WATERMELON,
	
	# Special crops
	GOLDEN_WHEAT,
	CRYSTAL_BERRY
}

enum GrowthStage {
	SEED,           # Just planted
	SPROUT,         # Small green shoots
	YOUNG,          # Growing but not mature
	MATURE,         # Ready to harvest
	OVERRIPE,       # Past prime, lower quality
	DEAD            # Died from neglect/disease
}

enum CropQuality {
	POOR = 1,       # 50% base value
	NORMAL = 2,     # 100% base value  
	GOOD = 3,       # 150% base value
	PERFECT = 4     # 200% base value
}

# ============================================================================
# DATA STRUCTURES
# ============================================================================
class CropData:
	var crop_type: CropType
	var position: Vector2i
	var growth_stage: GrowthStage = GrowthStage.SEED
	var quality: CropQuality = CropQuality.NORMAL
	
	# Growth timing
	var planted_time: float = 0.0
	var stage_start_time: float = 0.0
	var maturity_time: float = 60.0      # Base time to mature in seconds
	var growth_progress: float = 0.0     # 0.0 to 1.0 within current stage
	
	# Health and care
	var health: float = 1.0              # 0.0 to 1.0
	var water_level: float = 1.0         # 0.0 to 1.0
	var fertilizer_level: float = 0.0    # 0.0 to 1.0
	var care_quality: float = 1.0        # Overall care factor
	
	# Environmental factors
	var soil_fertility: float = 0.7      # From tile
	var weather_effects: float = 1.0     # From weather events
	var disease_resistance: float = 1.0  # Disease immunity
	
	# Special properties
	var is_giant: bool = false           # Can become giant crop
	var is_mutated: bool = false         # Random mutations
	var special_traits: Array[String] = []
	
	func _init(c_type: CropType, pos: Vector2i) -> void:
		crop_type = c_type
		position = pos
		planted_time = Time.get_unix_time_from_system()
		stage_start_time = planted_time
		maturity_time = _get_base_maturity_time(c_type)
	
	func get_age() -> float:
		return Time.get_unix_time_from_system() - planted_time
	
	func get_stage_age() -> float:
		return Time.get_unix_time_from_system() - stage_start_time
	
	func is_mature() -> bool:
		return growth_stage == GrowthStage.MATURE
	
	func is_harvestable() -> bool:
		return growth_stage in [GrowthStage.MATURE, GrowthStage.OVERRIPE]
	
	func _get_base_maturity_time(c_type: CropType) -> float:
		match c_type:
			CropType.LETTUCE: return 30.0     # Fast growing
			CropType.CORN: return 45.0       # Medium
			CropType.WHEAT: return 40.0      # Medium  
			CropType.TOMATO: return 60.0     # Slower
			CropType.POTATO: return 50.0     # Medium-slow
			CropType.PUMPKIN: return 90.0    # Very slow
			CropType.STRAWBERRY: return 70.0 # Slow
			CropType.WATERMELON: return 120.0 # Very slow
			_: return 60.0

# ============================================================================
# SIGNALS
# ============================================================================
signal crop_growth_stage_changed(position: Vector2i, crop: CropData, old_stage: GrowthStage, new_stage: GrowthStage)
signal crop_quality_changed(position: Vector2i, crop: CropData, old_quality: CropQuality, new_quality: CropQuality)
signal crop_matured(position: Vector2i, crop: CropData)
signal crop_died(position: Vector2i, crop: CropData, reason: String)
signal giant_crop_formed(position: Vector2i, crop: CropData)
signal crop_mutated(position: Vector2i, crop: CropData, mutation: String)

# ============================================================================
# PROPERTIES
# ============================================================================
# System references
var grid_manager: Node = null
var time_manager: Node = null
var event_manager: Node = null

# Crop tracking
var active_crops: Dictionary = {}        # Vector2i -> CropData
var crop_growth_multiplier: float = 1.0 # Global growth speed
var quality_bonus: float = 0.0          # Global quality bonus

# Growth parameters
var growth_stages_per_crop: int = 4      # SEED -> SPROUT -> YOUNG -> MATURE
var overripe_decay_time: float = 30.0   # Time before overripe becomes dead
var water_consumption_rate: float = 0.1 # Per second
var fertilizer_decay_rate: float = 0.05 # Per second

# Quality thresholds
var care_quality_thresholds: Dictionary = {
	CropQuality.POOR: 0.3,
	CropQuality.NORMAL: 0.6,
	CropQuality.GOOD: 0.8,
	CropQuality.PERFECT: 0.95
}

# Special crop chances
var giant_crop_chance: float = 0.05      # 5% for perfect care
var mutation_chance: float = 0.01        # 1% random mutations

# Processing control
var processing_timer: float = 0.0
var processing_interval: float = 1.0     # Process crops every second

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	name = "CropManager"
	print("[CropManager] Initializing as Autoload #7...")
	
	# Get system references
	grid_manager = GridManager
	time_manager = TimeManager
	event_manager = EventManager
	
	# Connect to GridManager signals
	if grid_manager:
		print("[CropManager] GridManager connected")
		grid_manager.crop_planted.connect(_on_crop_planted)
		grid_manager.crop_harvested.connect(_on_crop_harvested)
	else:
		print("[CropManager] WARNING: GridManager not found!")
	
	# Connect to TimeManager signals
	if time_manager:
		print("[CropManager] TimeManager connected")
		time_manager.time_tick.connect(_on_time_tick)
		time_manager.phase_changed.connect(_on_phase_changed)
	else:
		print("[CropManager] WARNING: TimeManager not found!")
	
	# Connect to EventManager signals
	if event_manager:
		print("[CropManager] EventManager connected")
		event_manager.weather_changed.connect(_on_weather_changed)
	else:
		print("[CropManager] WARNING: EventManager not found!")
	
	# Initialize crop system
	_initialize_crop_system()
	
	# Register with GameManager
	if GameManager:
		GameManager.register_system("CropManager", self)
		print("[CropManager] Registered with GameManager")
	
	print("[CropManager] Initialization complete!")

func _initialize_crop_system() -> void:
	"""Initialize the crop management system"""
	active_crops.clear()
	crop_growth_multiplier = 1.0
	quality_bonus = 0.0
	processing_timer = 0.0
	
	print("[CropManager] Crop system initialized")

# ============================================================================
# CORE FUNCTIONALITY - Processing Loop
# ============================================================================
func _process(delta: float) -> void:
	"""Main processing loop for crop updates"""
	# Only process during gameplay
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	# Only process crops if we have any
	if active_crops.is_empty():
		return
	
	# Update processing timer
	processing_timer += delta
	
	# Process crops at fixed intervals for consistency
	if processing_timer >= processing_interval:
		_process_all_crops()
		processing_timer = 0.0

func _process_all_crops() -> void:
	"""Process growth and care for all active crops"""
	for position in active_crops:
		var crop: CropData = active_crops[position]
		_process_crop_growth(crop)
		_process_crop_care(crop)
		_check_crop_conditions(crop)

func _process_crop_growth(crop: CropData) -> void:
	"""Process growth for a single crop"""
	if crop.growth_stage == GrowthStage.DEAD:
		return
	
	# Calculate growth rate based on all conditions
	var growth_rate: float = _calculate_growth_rate(crop)
	
	# Update growth progress (processing_interval seconds of growth)
	var growth_increment: float = (growth_rate * processing_interval) / crop.maturity_time
	crop.growth_progress += growth_increment
	
	# Check for stage advancement
	var stage_duration: float = 1.0 / growth_stages_per_crop
	if crop.growth_progress >= stage_duration:
		_advance_growth_stage(crop)

func _process_crop_care(crop: CropData) -> void:
	"""Process crop care requirements"""
	# Water consumption over time
	crop.water_level -= water_consumption_rate * processing_interval
	crop.water_level = max(0.0, crop.water_level)
	
	# Fertilizer decay over time
	crop.fertilizer_level -= fertilizer_decay_rate * processing_interval
	crop.fertilizer_level = max(0.0, crop.fertilizer_level)
	
	# Update overall care quality
	crop.care_quality = _calculate_care_quality(crop)
	
	# Health effects based on care
	if crop.water_level < 0.2:  # Drought stress
		crop.health -= 0.1 * processing_interval
	elif crop.water_level > 0.8:  # Well watered
		crop.health += 0.05 * processing_interval
	
	crop.health = clamp(crop.health, 0.0, 1.0)

# ============================================================================
# CROP LIFECYCLE MANAGEMENT
# ============================================================================
func _on_crop_planted(position: Vector2i, crop_type: String) -> void:
	"""Handle when a crop is planted in GridManager"""
	var crop_enum: CropType = _string_to_crop_type(crop_type)
	var crop_data: CropData = CropData.new(crop_enum, position)
	
	# Get soil conditions from GridManager
	if grid_manager:
		var tile: GridManager.FarmTile = grid_manager.get_tile(position)
		if tile:
			crop_data.water_level = tile.water_level
			crop_data.soil_fertility = tile.fertility
	
	# Store crop data for tracking
	active_crops[position] = crop_data
	
	print("[CropManager] Crop registered: %s at %s" % [crop_type, position])

func _on_crop_harvested(position: Vector2i, crop_type: String, yield_amount: int) -> void:
	"""Handle when a crop is harvested"""
	if not position in active_crops:
		print("[CropManager] WARNING: Harvested crop not in tracking: %s" % position)
		return
	
	var crop_data: CropData = active_crops[position]
	
	# Calculate final quality and yield
	var final_quality: CropQuality = _calculate_final_quality(crop_data)
	var quality_multiplier: float = _get_quality_multiplier(final_quality)
	var final_yield: int = int(yield_amount * quality_multiplier)
	
	print("[CropManager] Crop harvested: %s quality %s (yield: %d)" % [
		crop_type, 
		CropQuality.keys()[final_quality],
		final_yield
	])
	
	# Remove from tracking
	active_crops.erase(position)

func _advance_growth_stage(crop: CropData) -> void:
	"""Advance crop to next growth stage"""
	var old_stage: GrowthStage = crop.growth_stage
	var new_stage: GrowthStage = _get_next_growth_stage(crop.growth_stage)
	
	crop.growth_stage = new_stage
	crop.stage_start_time = Time.get_unix_time_from_system()
	crop.growth_progress = 0.0
	
	print("[CropManager] Crop at %s: %s → %s" % [
		crop.position,
		GrowthStage.keys()[old_stage],
		GrowthStage.keys()[new_stage]
	])
	
	crop_growth_stage_changed.emit(crop.position, crop, old_stage, new_stage)
	
	# Special handling for maturity
	if new_stage == GrowthStage.MATURE:
		_on_crop_matured(crop)

func _get_next_growth_stage(current_stage: GrowthStage) -> GrowthStage:
	"""Get the next growth stage in the lifecycle"""
	match current_stage:
		GrowthStage.SEED: return GrowthStage.SPROUT
		GrowthStage.SPROUT: return GrowthStage.YOUNG
		GrowthStage.YOUNG: return GrowthStage.MATURE
		GrowthStage.MATURE: return GrowthStage.OVERRIPE
		GrowthStage.OVERRIPE: return GrowthStage.DEAD
		_: return GrowthStage.DEAD

func _on_crop_matured(crop: CropData) -> void:
	"""Handle crop reaching maturity"""
	# Calculate final quality based on care
	crop.quality = _calculate_crop_quality(crop)
	
	# Check for special crop formation
	_check_giant_crop_formation(crop)
	_check_crop_mutation(crop)
	
	crop_matured.emit(crop.position, crop)
	print("[CropManager] Crop matured at %s - Quality: %s" % [
		crop.position,
		CropQuality.keys()[crop.quality]
	])

# ============================================================================
# QUALITY CALCULATION SYSTEM
# ============================================================================
func _calculate_care_quality(crop: CropData) -> float:
	"""Calculate overall care quality for a crop"""
	# Weight different care factors
	var water_factor: float = crop.water_level
	var fertilizer_factor: float = min(crop.fertilizer_level, 1.0)
	var health_factor: float = crop.health
	var soil_factor: float = crop.soil_fertility
	
	# Weighted average of care factors
	var care_quality: float = (
		water_factor * 0.4 +       # Water is most important
		fertilizer_factor * 0.2 +  # Fertilizer helps
		health_factor * 0.3 +      # Health is critical
		soil_factor * 0.1          # Soil provides base
	)
	
	return clamp(care_quality, 0.0, 1.0)

func _calculate_growth_rate(crop: CropData) -> float:
	"""Calculate growth rate based on all factors"""
	var base_rate: float = 1.0
	
	# Care factor (good care = faster growth)
	var care_factor: float = crop.care_quality
	
	# Weather factor (from weather events)
	var weather_factor: float = crop.weather_effects
	
	# Global multiplier (from time phases, etc.)
	var global_factor: float = crop_growth_multiplier
	
	# Combined rate
	var final_rate: float = base_rate * care_factor * weather_factor * global_factor
	
	return max(0.1, final_rate)  # Minimum 10% growth rate

func _calculate_crop_quality(crop: CropData) -> CropQuality:
	"""Calculate final crop quality based on care throughout growth"""
	var care_score: float = crop.care_quality + quality_bonus
	
	# Determine quality tier based on thresholds
	if care_score >= care_quality_thresholds[CropQuality.PERFECT]:
		return CropQuality.PERFECT
	elif care_score >= care_quality_thresholds[CropQuality.GOOD]:
		return CropQuality.GOOD
	elif care_score >= care_quality_thresholds[CropQuality.NORMAL]:
		return CropQuality.NORMAL
	else:
		return CropQuality.POOR

func _calculate_final_quality(crop: CropData) -> CropQuality:
	"""Calculate final quality at harvest time"""
	# Start with base quality from care
	var base_quality: CropQuality = _calculate_crop_quality(crop)
	
	# Adjust for harvest timing
	if crop.growth_stage == GrowthStage.OVERRIPE:
		# Reduce quality for overripe crops
		var reduced_quality: int = max(CropQuality.POOR, base_quality - 1)
		return reduced_quality
	
	return base_quality

func _get_quality_multiplier(quality: CropQuality) -> float:
	"""Get value multiplier for crop quality"""
	match quality:
		CropQuality.POOR: return 0.5
		CropQuality.NORMAL: return 1.0
		CropQuality.GOOD: return 1.5
		CropQuality.PERFECT: return 2.0
		_: return 1.0

# ============================================================================
# CROP CONDITION MONITORING
# ============================================================================
func _check_crop_conditions(crop: CropData) -> void:
	"""Check crop conditions and handle death/problems"""
	# Death from poor health
	if crop.health <= 0.0:
		_kill_crop(crop, "poor_health")
		return
	
	# Death from being overripe too long
	if crop.growth_stage == GrowthStage.OVERRIPE:
		var overripe_time: float = crop.get_stage_age()
		if overripe_time > overripe_decay_time:
			_kill_crop(crop, "overripe_decay")
			return

func _kill_crop(crop: CropData, reason: String) -> void:
	"""Kill a crop and handle cleanup"""
	crop.growth_stage = GrowthStage.DEAD
	crop.health = 0.0
	
	crop_died.emit(crop.position, crop, reason)
	print("[CropManager] Crop died at %s - Reason: %s" % [crop.position, reason])
	
	# TODO: Coordinate with GridManager to remove dead crop visually

# ============================================================================
# SPECIAL CROP MECHANICS
# ============================================================================
func _check_giant_crop_formation(crop: CropData) -> void:
	"""Check if crop should become giant"""
	# Only perfect care crops can become giant
	if crop.care_quality >= 0.9 and randf() < giant_crop_chance:
		crop.is_giant = true
		crop.special_traits.append("giant")
		giant_crop_formed.emit(crop.position, crop)
		print("[CropManager] Giant crop formed at %s!" % crop.position)

func _check_crop_mutation(crop: CropData) -> void:
	"""Check for random crop mutations"""
	if randf() < mutation_chance:
		var possible_mutations: Array[String] = [
			"fast_growth", "disease_resistant", "double_yield", "colorful", "glowing"
		]
		var mutation: String = possible_mutations[randi() % possible_mutations.size()]
		
		crop.is_mutated = true
		crop.special_traits.append(mutation)
		crop_mutated.emit(crop.position, crop, mutation)
		print("[CropManager] Crop mutated at %s: %s" % [crop.position, mutation])

# ============================================================================
# SYSTEM INTEGRATION - Event Handlers
# ============================================================================
func _on_weather_changed(old_weather: int, new_weather: int) -> void:
	"""Handle weather changes affecting all crops"""
	var weather_multiplier: float = _get_weather_growth_multiplier(new_weather)
	
	# Apply weather effects to all active crops
	for position in active_crops:
		var crop: CropData = active_crops[position]
		crop.weather_effects = weather_multiplier
	
	print("[CropManager] Weather effects applied - Growth multiplier: %.1f" % weather_multiplier)

func _get_weather_growth_multiplier(weather_type: int) -> float:
	"""Get growth multiplier for weather type"""
	# Map EventManager weather types to growth effects
	match weather_type:
		0: return 1.2  # SUNNY - faster growth
		1: return 1.0  # CLOUDY - normal
		2: return 0.9  # RAINY - slower growth but auto-water
		3: return 0.7  # STORMY - much slower, dangerous
		4: return 0.6  # DROUGHT - very slow growth
		5: return 0.8  # FOG - reduced growth
		_: return 1.0  # Default

func _on_phase_changed(from_phase: int, to_phase: int) -> void:
	"""Handle time phase changes"""
	# Night phase accelerates growth (plants grow at night)
	if to_phase == TimeManager.TimePhase.NIGHT:
		crop_growth_multiplier = 2.0  # Overnight growth boost
		print("[CropManager] Night phase - accelerated growth (2.0x)")
	else:
		crop_growth_multiplier = 1.0

func _on_time_tick(current_time: float, phase: int) -> void:
	"""Handle time system ticks"""
	# This is called frequently, so we don't process here
	# Instead we use our own _process() loop for consistent timing
	pass

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func _string_to_crop_type(crop_string: String) -> CropType:
	"""Convert string to CropType enum"""
	match crop_string.to_lower():
		"lettuce": return CropType.LETTUCE
		"corn": return CropType.CORN
		"wheat": return CropType.WHEAT
		"tomato": return CropType.TOMATO
		"potato": return CropType.POTATO
		"pumpkin": return CropType.PUMPKIN
		"strawberry": return CropType.STRAWBERRY
		"watermelon": return CropType.WATERMELON
		"golden_wheat": return CropType.GOLDEN_WHEAT
		"crystal_berry": return CropType.CRYSTAL_BERRY
		_: 
			print("[CropManager] Unknown crop type: %s, defaulting to lettuce" % crop_string)
			return CropType.LETTUCE

func get_crop_at_position(position: Vector2i) -> CropData:
	"""Get crop data at specific position"""
	return active_crops.get(position, null)

func get_all_crops() -> Array[CropData]:
	"""Get all active crops"""
	var crops: Array[CropData] = []
	for crop in active_crops.values():
		crops.append(crop)
	return crops

func get_crops_by_stage(stage: GrowthStage) -> Array[CropData]:
	"""Get all crops at a specific growth stage"""
	var filtered_crops: Array[CropData] = []
	for crop in active_crops.values():
		if crop.growth_stage == stage:
			filtered_crops.append(crop)
	return filtered_crops

func get_mature_crops() -> Array[CropData]:
	"""Get all harvestable crops"""
	var mature_crops: Array[CropData] = []
	for crop in active_crops.values():
		if crop.is_harvestable():
			mature_crops.append(crop)
	return mature_crops

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	"""Get comprehensive debug information"""
	var mature_count: int = get_crops_by_stage(GrowthStage.MATURE).size()
	var dead_count: int = get_crops_by_stage(GrowthStage.DEAD).size()
	var giant_count: int = 0
	var mutated_count: int = 0
	
	# Count special crops
	for crop in active_crops.values():
		if crop.is_giant:
			giant_count += 1
		if crop.is_mutated:
			mutated_count += 1
	
	return {
		"total_crops": active_crops.size(),
		"mature_crops": mature_count,
		"dead_crops": dead_count,
		"giant_crops": giant_count,
		"mutated_crops": mutated_count,
		"growth_multiplier": crop_growth_multiplier,
		"quality_bonus": quality_bonus,
		"processing_interval": processing_interval,
		"grid_manager_connected": grid_manager != null,
		"time_manager_connected": time_manager != null,
		"event_manager_connected": event_manager != null
	}

func force_crop_maturation(position: Vector2i) -> bool:
	"""Force a crop to mature instantly (debug)"""
	var crop: CropData = get_crop_at_position(position)
	if not crop:
		print("[CropManager] No crop at position %s to mature" % position)
		return false
	
	crop.growth_stage = GrowthStage.MATURE
	crop.stage_start_time = Time.get_unix_time_from_system()
	_on_crop_matured(crop)
	print("[CropManager] Debug: Forced maturation at %s" % position)
	return true

func simulate_crop_growth(time_seconds: float) -> void:
	"""Simulate crop growth over time (debug)"""
	print("[CropManager] Simulating %.1f seconds of growth..." % time_seconds)
	
	var simulation_steps: int = int(time_seconds / processing_interval)
	for i in simulation_steps:
		_process_all_crops()
	
	print("[CropManager] Growth simulation complete")
