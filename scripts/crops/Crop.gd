extends Node2D
class_name Crop
# Crop.gd - Individual crop controller
# Manages a single crop's lifecycle, visuals, and interactions
# Dependencies: CropData resource, CropManager

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
enum GrowthStage {
	SEED = 0,		# Just planted
	SPROUT = 1,		# Small shoots
	YOUNG = 2,		# Growing plant
	MATURE = 3,		# Ready to harvest
	OVERRIPE = 4,	# Past optimal harvest time
	DEAD = 5		# Died from neglect/disease
}

enum QualityLevel {
	POOR = 1,		# 50% value
	NORMAL = 2,		# 75% value  
	GOOD = 3,		# 100% value
	PERFECT = 4		# 150% value
}

# ============================================================================
# SIGNALS
# ============================================================================
signal stage_changed(old_stage: GrowthStage, new_stage: GrowthStage)
signal quality_changed(old_quality: QualityLevel, new_quality: QualityLevel)
signal needs_water()
signal ready_to_harvest()
signal crop_matured(crop: Crop)
signal crop_died(crop: Crop, reason: String)
signal crop_harvested(crop: Crop, yield_data: Dictionary)
signal visual_update_needed()

# ============================================================================
# PROPERTIES - Configuration
# ============================================================================
@export var crop_data: CropData = null
@export var grid_position: Vector2i = Vector2i.ZERO

# ============================================================================  
# PROPERTIES - State
# ============================================================================
var current_stage: GrowthStage = GrowthStage.SEED
var current_quality: QualityLevel = QualityLevel.NORMAL

# Growth tracking
var growth_progress: float = 0.0			# 0.0 to 1.0 overall progress
var stage_progress: float = 0.0				# 0.0 to 1.0 within current stage
var total_growth_time: float = 0.0			# Total time to maturity
var stage_durations: Array[float] = []		# Duration for each stage
var time_in_current_stage: float = 0.0		# Time spent in current stage

# Care and health
var water_level: float = 1.0				# 0.0 to 1.0
var health: float = 1.0						# 0.0 to 1.0
var care_quality: float = 1.0				# Overall care factor
var last_water_time: float = 0.0			# Last time watered
var fertilizer_bonus: float = 0.0			# Fertilizer effect

# Special states
var is_diseased: bool = false
var is_giant: bool = false
var is_mutated: bool = false
var times_harvested: int = 0
var harvest_ready_time: float = 0.0			# When crop became ready

# Environmental factors
var weather_effects: float = 1.0			# Weather growth modifier
var soil_quality_bonus: float = 0.0		# Soil condition bonus

# Component references
var crop_growth: CropGrowth = null
var crop_visuals: CropVisuals = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	"""Initialize the crop with data and components"""
	if not crop_data:
		print("[Crop] ERROR: No CropData assigned to crop at %s" % grid_position)
		return
	
	# Initialize growth system
	_initialize_growth_system()
	
	# Get component references
	crop_growth = get_node("CropGrowth") as CropGrowth
	crop_visuals = get_node("CropVisuals") as CropVisuals
	
	# Initialize components
	if crop_growth:
		crop_growth.initialize(self, crop_data)
	
	if crop_visuals:
		crop_visuals.initialize(self, crop_data)
	
	# Connect signals
	_connect_signals()
	
	print("[Crop] Initialized %s at %s" % [crop_data.crop_name, grid_position])

func _initialize_growth_system() -> void:
	"""Setup growth timing and stage durations"""
	if not crop_data:
		return
	
	# Get randomized growth time
	total_growth_time = crop_data.get_growth_time_with_variance()
	
	# Calculate stage durations
	stage_durations.clear()
	var stage_duration: float = total_growth_time / float(crop_data.growth_stages)
	
	for i in crop_data.growth_stages:
		stage_durations.append(stage_duration)
	
	# Initialize state
	current_stage = GrowthStage.SEED
	growth_progress = 0.0
	stage_progress = 0.0
	time_in_current_stage = 0.0
	
	print("[Crop] Growth system initialized - Total time: %.1fs, Stage duration: %.1fs" % [total_growth_time, stage_duration])

func _connect_signals() -> void:
	"""Connect internal signals for component communication"""
	# Connect to growth system
	if crop_growth:
		crop_growth.stage_advanced.connect(_on_stage_advanced)
		crop_growth.growth_updated.connect(_on_growth_updated)
	
	# Connect to visual system
	stage_changed.connect(_on_stage_changed_internal)
	quality_changed.connect(_on_quality_changed_internal)
	visual_update_needed.connect(_on_visual_update_needed)

# ============================================================================
# CORE FUNCTIONALITY - Growth Processing
# ============================================================================
func process_growth(delta: float) -> void:
	"""Process crop growth over time"""
	if not crop_data or current_stage == GrowthStage.DEAD or current_stage >= GrowthStage.MATURE:
		return
	
	# Calculate growth rate based on conditions
	var growth_rate: float = _calculate_growth_rate()
	
	# Apply growth
	var growth_delta: float = delta * growth_rate
	time_in_current_stage += growth_delta
	
	# Update progress within current stage
	if current_stage < stage_durations.size():
		stage_progress = clamp(time_in_current_stage / stage_durations[current_stage], 0.0, 1.0)
	
	# Check for stage advancement
	if stage_progress >= 1.0 and current_stage < GrowthStage.MATURE:
		_advance_to_next_stage()
	
	# Update overall progress
	_update_overall_progress()
	
	# Check for maturity
	if current_stage == GrowthStage.MATURE and not is_ready_to_harvest():
		_on_crop_matured()

func _calculate_growth_rate() -> float:
	"""Calculate current growth rate based on all conditions"""
	var base_rate: float = 1.0
	
	# Water effects
	if water_level < 0.3:
		base_rate *= 0.5  # Drought stress
	elif water_level > crop_data.optimal_water_level:
		base_rate *= 1.2  # Well watered
	
	# Health effects
	base_rate *= health
	
	# Weather effects
	base_rate *= weather_effects
	
	# Fertilizer bonus
	base_rate *= (1.0 + fertilizer_bonus)
	
	# Disease penalty
	if is_diseased:
		base_rate *= 0.6
	
	return clamp(base_rate, 0.1, 3.0)

func _advance_to_next_stage() -> void:
	"""Advance crop to the next growth stage"""
	var old_stage: GrowthStage = current_stage
	
	# Move to next stage  
	var next_stage_value: int = int(current_stage) + 1
	current_stage = next_stage_value as GrowthStage
	time_in_current_stage = 0.0
	stage_progress = 0.0
	
	# Emit signals
	stage_changed.emit(old_stage, current_stage)
	
	print("[Crop] %s advanced from %s to %s" % [crop_data.crop_name, GrowthStage.keys()[old_stage], GrowthStage.keys()[current_stage]])

func _update_overall_progress() -> void:
	"""Update overall growth progress (0.0 to 1.0)"""
	var stage_weight: float = 1.0 / float(crop_data.growth_stages)
	var stage_contribution: float = float(current_stage) * stage_weight
	var current_stage_contribution: float = stage_progress * stage_weight
	
	growth_progress = clamp(stage_contribution + current_stage_contribution, 0.0, 1.0)

# ============================================================================
# CARE SYSTEM - Water and Health
# ============================================================================
func water_crop(amount: float) -> bool:
	"""Apply water to the crop"""
	if current_stage == GrowthStage.DEAD:
		return false
	
	water_level = clamp(water_level + amount, 0.0, 1.0)
	last_water_time = Time.get_unix_time_from_system()
	
	# Health recovery from proper watering
	if water_level > 0.5:
		health = clamp(health + 0.1, 0.0, 1.0)
	
	print("[Crop] %s watered - Water level: %.2f" % [crop_data.crop_name, water_level])
	visual_update_needed.emit()
	
	return true

func apply_fertilizer(fertilizer_type: String, effectiveness: float) -> bool:
	"""Apply fertilizer to boost growth"""
	if current_stage == GrowthStage.DEAD:
		return false
	
	fertilizer_bonus = clamp(fertilizer_bonus + effectiveness, 0.0, 1.0)
	
	print("[Crop] %s fertilized with %s - Bonus: %.2f" % [crop_data.crop_name, fertilizer_type, fertilizer_bonus])
	return true

func process_water_consumption(delta: float) -> void:
	"""Process water consumption over time"""
	if current_stage == GrowthStage.DEAD:
		return
	
	# Consume water based on crop data
	var consumption: float = crop_data.water_consumption_rate * delta
	water_level = clamp(water_level - consumption, 0.0, 1.0)
	
	# Health effects from water level
	if water_level < 0.2:
		health = clamp(health - 0.05 * delta, 0.0, 1.0)
		if health <= 0.0:
			_die("drought")

# ============================================================================
# HARVEST SYSTEM
# ============================================================================
func is_ready_to_harvest() -> bool:
	"""Check if crop is ready for harvest"""
	return current_stage == GrowthStage.MATURE and health > 0.0

func can_harvest() -> bool:
	"""Check if crop can be harvested (includes overripe)"""
	return current_stage in [GrowthStage.MATURE, GrowthStage.OVERRIPE] and health > 0.0

func harvest() -> Dictionary:
	"""Harvest the crop and return yield data"""
	if not can_harvest():
		print("[Crop] Cannot harvest %s - not ready or dead" % crop_data.crop_name)
		return {}
	
	# Calculate harvest data
	var harvest_data: Dictionary = _calculate_harvest_yield()
	
	# Handle multi-harvest crops
	if crop_data.multi_harvest and times_harvested < crop_data.harvest_cycles:
		times_harvested += 1
		_reset_for_next_harvest()
	else:
		_prepare_for_removal()
	
	# Emit harvest signal
	crop_harvested.emit(self, harvest_data)
	
	print("[Crop] Harvested %s - Yield: %d, Quality: %s" % [
		crop_data.crop_name,
		harvest_data.get("quantity", 0),
		QualityLevel.keys()[harvest_data.get("quality", QualityLevel.NORMAL)]
	])
	
	return harvest_data

func _calculate_harvest_yield() -> Dictionary:
	"""Calculate harvest yield based on care quality and conditions"""
	var quality: QualityLevel = _calculate_final_quality()
	var base_quantity: int = crop_data.base_yield
	
	# Quality affects quantity
	var quantity_multiplier: float = 1.0
	match quality:
		QualityLevel.POOR: quantity_multiplier = 0.5
		QualityLevel.NORMAL: quantity_multiplier = 0.75
		QualityLevel.GOOD: quantity_multiplier = 1.0
		QualityLevel.PERFECT: quantity_multiplier = 1.5
	
	var final_quantity: int = max(1, int(base_quantity * quantity_multiplier))
	var final_value: int = crop_data.calculate_final_value(quantity_multiplier, final_quantity)
	
	return {
		"crop_name": crop_data.crop_name,
		"crop_type": crop_data.get_type_name(),
		"quantity": final_quantity,
		"quality": quality,
		"total_value": final_value,
		"is_giant": is_giant,
		"is_mutated": is_mutated,
		"harvest_cycle": times_harvested + 1
	}

func _calculate_final_quality() -> QualityLevel:
	"""Calculate final crop quality based on care factors"""
	var quality_score: float = 0.0
	
	# Health factor (40% of quality)
	quality_score += health * 0.4
	
	# Care quality factor (30% of quality)
	quality_score += care_quality * 0.3
	
	# Water management (20% of quality)
	var water_score: float = 1.0 - abs(water_level - crop_data.optimal_water_level)
	quality_score += water_score * 0.2
	
	# Random luck factor (10% of quality)
	quality_score += randf() * 0.1
	
	# Convert to quality enum
	if quality_score >= 0.9:
		return QualityLevel.PERFECT
	elif quality_score >= 0.7:
		return QualityLevel.GOOD
	elif quality_score >= 0.5:
		return QualityLevel.NORMAL
	else:
		return QualityLevel.POOR

# ============================================================================
# LIFECYCLE MANAGEMENT
# ============================================================================
func _reset_for_next_harvest() -> void:
	"""Reset crop state for next harvest cycle (multi-harvest crops)"""
	current_stage = GrowthStage.YOUNG
	growth_progress = 0.7  # Start at 70% for regrowth
	stage_progress = 0.0
	time_in_current_stage = 0.0
	
	# Slight quality improvement with each harvest
	care_quality = clamp(care_quality + 0.1, 0.0, 2.0)
	
	print("[Crop] %s reset for harvest cycle %d" % [crop_data.crop_name, times_harvested + 1])
	visual_update_needed.emit()

func _prepare_for_removal() -> void:
	"""Prepare crop for removal after final harvest"""
	current_stage = GrowthStage.DEAD
	print("[Crop] %s prepared for removal after harvest" % crop_data.crop_name)

func _die(reason: String) -> void:
	"""Handle crop death"""
	current_stage = GrowthStage.DEAD
	health = 0.0
	
	crop_died.emit(self, reason)
	visual_update_needed.emit()
	
	print("[Crop] %s died: %s" % [crop_data.crop_name, reason])

func is_dead() -> bool:
	"""Check if crop is dead"""
	return current_stage == GrowthStage.DEAD or health <= 0.0

# ============================================================================
# EVENT HANDLERS
# ============================================================================
func _on_stage_advanced(old_stage: int, new_stage: int) -> void:
	"""Handle stage advancement from growth component"""
	print("[Crop] Growth component advanced stage: %d -> %d" % [old_stage, new_stage])

func _on_growth_updated(progress: float) -> void:
	"""Handle growth progress updates"""
	visual_update_needed.emit()

func _on_stage_changed_internal(old_stage: GrowthStage, new_stage: GrowthStage) -> void:
	"""Handle internal stage changes"""
	# Trigger visual update
	visual_update_needed.emit()
	
	# Check for maturity
	if new_stage == GrowthStage.MATURE:
		harvest_ready_time = Time.get_unix_time_from_system()
		ready_to_harvest.emit()

func _on_quality_changed_internal(old_quality: QualityLevel, new_quality: QualityLevel) -> void:
	"""Handle quality changes"""
	print("[Crop] Quality changed: %s -> %s" % [QualityLevel.keys()[old_quality], QualityLevel.keys()[new_quality]])

func _on_visual_update_needed() -> void:
	"""Handle visual update requests"""
	if crop_visuals:
		crop_visuals.update_visual_state()

func _on_crop_matured() -> void:
	"""Handle crop reaching maturity"""
	crop_matured.emit(self)
	print("[Crop] %s has matured!" % crop_data.crop_name)

# ============================================================================
# WEATHER AND ENVIRONMENTAL EFFECTS
# ============================================================================
func apply_weather_effect(weather_type: int, effect_strength: float) -> void:
	"""Apply weather effects to the crop"""
	if current_stage == GrowthStage.DEAD:
		return
	
	# Apply resistance from crop data
	var actual_effect: float = effect_strength * (1.0 - crop_data.weather_resistance)
	weather_effects = clamp(weather_effects + actual_effect, 0.2, 2.0)
	
	print("[Crop] Weather effect applied to %s - New modifier: %.2f" % [crop_data.crop_name, weather_effects])

func apply_disease(disease_name: String, severity: float) -> bool:
	"""Apply disease to the crop"""
	if current_stage == GrowthStage.DEAD:
		return false
	
	# Check disease resistance
	var resistance_roll: float = randf()
	if resistance_roll < crop_data.disease_resistance:
		print("[Crop] %s resisted disease: %s" % [crop_data.crop_name, disease_name])
		return false
	
	is_diseased = true
	health = clamp(health - severity, 0.0, 1.0)
	
	if health <= 0.0:
		_die("disease: " + disease_name)
	
	visual_update_needed.emit()
	print("[Crop] %s contracted disease: %s (severity: %.2f)" % [crop_data.crop_name, disease_name, severity])
	
	return true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func get_growth_stage_name() -> String:
	"""Get human-readable growth stage name"""
	return GrowthStage.keys()[current_stage] if current_stage < GrowthStage.size() else "UNKNOWN"

func get_quality_name() -> String:
	"""Get human-readable quality name"""
	return QualityLevel.keys()[current_quality] if current_quality < QualityLevel.size() else "UNKNOWN"

func get_progress_percentage() -> int:
	"""Get growth progress as percentage"""
	return int(growth_progress * 100)

func needs_immediate_water() -> bool:
	"""Check if crop needs urgent watering"""
	return water_level < 0.3 and current_stage != GrowthStage.DEAD

func time_since_last_water() -> float:
	"""Get time since last watering in seconds"""
	return Time.get_unix_time_from_system() - last_water_time

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	"""Get comprehensive debug information"""
	return {
		"crop_name": crop_data.crop_name if crop_data else "No Data",
		"position": grid_position,
		"stage": get_growth_stage_name(),
		"progress": "%.1f%%" % (growth_progress * 100),
		"stage_progress": "%.1f%%" % (stage_progress * 100),
		"water_level": "%.2f" % water_level,
		"health": "%.2f" % health,
		"quality": get_quality_name(),
		"is_ready": is_ready_to_harvest(),
		"is_dead": is_dead(),
		"times_harvested": times_harvested,
		"weather_effects": weather_effects,
		"is_diseased": is_diseased,
		"is_giant": is_giant
	}

func print_debug_info() -> void:
	"""Print comprehensive debug information"""
	print("[Crop] === %s Debug Info ===" % crop_data.crop_name)
	var debug_data: Dictionary = get_debug_info()
	for key in debug_data:
		print("[Crop] %s: %s" % [key, debug_data[key]])
	print("[Crop] === End Debug Info ===")
