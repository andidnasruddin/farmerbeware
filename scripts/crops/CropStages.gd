extends Resource
class_name CropStages
# CropStages.gd - Stage threshold definitions and configuration
# Defines growth stage progression thresholds and transition logic
# Dependencies: CropData resource class

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
enum GrowthStage {
	SEED = 0,		# Just planted, no visible growth
	SPROUT = 1,		# First green shoots visible
	YOUNG = 2,		# Small but growing plant
	MATURE = 3,		# Ready for harvest
	OVERRIPE = 4,	# Past optimal harvest time
	DEAD = 5		# Plant has died
}

# Stage progression thresholds (0.0 to 1.0 progress values)
const STAGE_THRESHOLDS: Dictionary = {
	GrowthStage.SEED: 0.0,		# Start
	GrowthStage.SPROUT: 0.25,	# 25% progress
	GrowthStage.YOUNG: 0.5,		# 50% progress  
	GrowthStage.MATURE: 0.85,	# 85% progress
	GrowthStage.OVERRIPE: 1.0,	# 100% progress
	GrowthStage.DEAD: -1.0		# Special case - health based
}

# Stage duration weights (relative timing for each stage)
const STAGE_DURATIONS: Dictionary = {
	GrowthStage.SEED: 0.15,		# 15% of total time
	GrowthStage.SPROUT: 0.25,	# 25% of total time
	GrowthStage.YOUNG: 0.35,	# 35% of total time
	GrowthStage.MATURE: 0.25,	# 25% of total time (harvest window)
	GrowthStage.OVERRIPE: 0.0,	# No set duration - depends on neglect
	GrowthStage.DEAD: 0.0		# Permanent state
}

# ============================================================================
# PROPERTIES
# ============================================================================
@export var crop_name: String = ""
@export var total_growth_stages: int = 4
@export var custom_thresholds: Dictionary = {}
@export var stage_transition_effects: Dictionary = {}

# Stage-specific requirements and modifiers
@export var stage_water_requirements: Dictionary = {}
@export var stage_growth_modifiers: Dictionary = {}
@export var stage_health_effects: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================
func _init(crop_data: CropData = null) -> void:
	"""Initialize stage configuration from crop data"""
	if crop_data:
		crop_name = crop_data.crop_name
		total_growth_stages = crop_data.growth_stages
		_setup_default_configuration()

func _setup_default_configuration() -> void:
	"""Setup default stage configuration"""
	# Initialize stage-specific requirements
	stage_water_requirements = {
		GrowthStage.SEED: 0.8,		# Seeds need high moisture
		GrowthStage.SPROUT: 0.7,	# Sprouts need consistent water
		GrowthStage.YOUNG: 0.6,		# Growing plants need regular water
		GrowthStage.MATURE: 0.5,	# Mature plants are more drought tolerant
		GrowthStage.OVERRIPE: 0.4,	# Overripe plants need less water
		GrowthStage.DEAD: 0.0		# Dead plants don't need water
	}
	
	# Growth rate modifiers per stage
	stage_growth_modifiers = {
		GrowthStage.SEED: 0.8,		# Slow initial growth
		GrowthStage.SPROUT: 1.2,	# Rapid sprouting
		GrowthStage.YOUNG: 1.0,		# Normal growth
		GrowthStage.MATURE: 0.3,	# Slow final maturation
		GrowthStage.OVERRIPE: 0.0,	# No further growth
		GrowthStage.DEAD: 0.0		# Dead plants don't grow
	}
	
	# Health effects per stage
	stage_health_effects = {
		GrowthStage.SEED: {"vulnerability": 0.8, "recovery": 0.5},
		GrowthStage.SPROUT: {"vulnerability": 0.6, "recovery": 0.7},
		GrowthStage.YOUNG: {"vulnerability": 0.4, "recovery": 0.9},
		GrowthStage.MATURE: {"vulnerability": 0.3, "recovery": 1.0},
		GrowthStage.OVERRIPE: {"vulnerability": 0.7, "recovery": 0.3},
		GrowthStage.DEAD: {"vulnerability": 1.0, "recovery": 0.0}
	}

# ============================================================================
# CORE FUNCTIONALITY - Stage Logic
# ============================================================================
func get_stage_for_progress(progress: float) -> GrowthStage:
	"""Get appropriate growth stage for given progress (0.0 to 1.0)"""
	progress = clamp(progress, 0.0, 1.0)
	
	# Check custom thresholds first
	if not custom_thresholds.is_empty():
		return _get_stage_from_custom_thresholds(progress)
	
	# Use default thresholds
	if progress >= STAGE_THRESHOLDS[GrowthStage.MATURE]:
		return GrowthStage.MATURE
	elif progress >= STAGE_THRESHOLDS[GrowthStage.YOUNG]:
		return GrowthStage.YOUNG
	elif progress >= STAGE_THRESHOLDS[GrowthStage.SPROUT]:
		return GrowthStage.SPROUT
	else:
		return GrowthStage.SEED

func _get_stage_from_custom_thresholds(progress: float) -> GrowthStage:
	"""Get stage using custom threshold configuration"""
	var stages_ordered: Array = [
		GrowthStage.MATURE,
		GrowthStage.YOUNG, 
		GrowthStage.SPROUT,
		GrowthStage.SEED
	]
	
	for stage in stages_ordered:
		var threshold: float = custom_thresholds.get(stage, STAGE_THRESHOLDS[stage])
		if progress >= threshold:
			return stage
	
	return GrowthStage.SEED

func get_progress_for_stage(stage: GrowthStage) -> float:
	"""Get minimum progress required for stage"""
	if custom_thresholds.has(stage):
		return custom_thresholds[stage]
	
	return STAGE_THRESHOLDS.get(stage, 0.0)

func get_next_stage(current_stage: GrowthStage) -> GrowthStage:
	"""Get the next logical growth stage"""
	match current_stage:
		GrowthStage.SEED:
			return GrowthStage.SPROUT
		GrowthStage.SPROUT:
			return GrowthStage.YOUNG
		GrowthStage.YOUNG:
			return GrowthStage.MATURE
		GrowthStage.MATURE:
			return GrowthStage.OVERRIPE
		GrowthStage.OVERRIPE:
			return GrowthStage.DEAD
		GrowthStage.DEAD:
			return GrowthStage.DEAD  # Stay dead
		_:
			return GrowthStage.SEED

func get_previous_stage(current_stage: GrowthStage) -> GrowthStage:
	"""Get the previous growth stage (for regression scenarios)"""
	match current_stage:
		GrowthStage.DEAD:
			return GrowthStage.OVERRIPE
		GrowthStage.OVERRIPE:
			return GrowthStage.MATURE
		GrowthStage.MATURE:
			return GrowthStage.YOUNG
		GrowthStage.YOUNG:
			return GrowthStage.SPROUT
		GrowthStage.SPROUT:
			return GrowthStage.SEED
		GrowthStage.SEED:
			return GrowthStage.SEED  # Can't go below seed
		_:
			return GrowthStage.SEED

# ============================================================================
# STAGE REQUIREMENTS AND MODIFIERS
# ============================================================================
func get_water_requirement(stage: GrowthStage) -> float:
	"""Get water requirement for specific stage"""
	return stage_water_requirements.get(stage, 0.6)

func get_growth_modifier(stage: GrowthStage) -> float:
	"""Get growth rate modifier for specific stage"""
	return stage_growth_modifiers.get(stage, 1.0)

func get_health_vulnerability(stage: GrowthStage) -> float:
	"""Get health vulnerability multiplier for stage"""
	var health_data: Dictionary = stage_health_effects.get(stage, {})
	return health_data.get("vulnerability", 0.5)

func get_health_recovery_rate(stage: GrowthStage) -> float:
	"""Get health recovery rate modifier for stage"""
	var health_data: Dictionary = stage_health_effects.get(stage, {})
	return health_data.get("recovery", 0.8)

# ============================================================================
# STAGE TRANSITIONS
# ============================================================================
func can_advance_from_stage(current_stage: GrowthStage, progress: float, health: float) -> bool:
	"""Check if crop can advance from current stage"""
	# Dead crops can't advance
	if current_stage == GrowthStage.DEAD:
		return false
	
	# Check if progress threshold is met
	var next_stage: GrowthStage = get_next_stage(current_stage)
	var required_progress: float = get_progress_for_stage(next_stage)
	
	if progress < required_progress:
		return false
	
	# Check health requirements for advancement
	var min_health: float = _get_advancement_health_requirement(current_stage)
	if health < min_health:
		return false
	
	return true

func _get_advancement_health_requirement(from_stage: GrowthStage) -> float:
	"""Get minimum health required to advance from stage"""
	match from_stage:
		GrowthStage.SEED:
			return 0.3  # Seeds are fragile but can sprout with low health
		GrowthStage.SPROUT:
			return 0.4  # Sprouts need reasonable health to grow
		GrowthStage.YOUNG:
			return 0.5  # Young plants need good health to mature
		GrowthStage.MATURE:
			return 0.0  # Mature plants will overripe regardless of health
		_:
			return 0.0

func should_regress_stage(current_stage: GrowthStage, health: float, water_level: float) -> bool:
	"""Check if crop should regress to previous stage due to poor care"""
	# Only certain stages can regress
	if current_stage in [GrowthStage.SEED, GrowthStage.DEAD]:
		return false
	
	# Check for severe neglect conditions
	var critical_health: float = 0.2
	var critical_water: float = 0.1
	
	# Severe neglect triggers regression
	if health <= critical_health and water_level <= critical_water:
		return true
	
	return false

func should_die(current_stage: GrowthStage, health: float, neglect_time: float) -> bool:
	"""Check if crop should die based on conditions"""
	# Already dead
	if current_stage == GrowthStage.DEAD:
		return false
	
	# Health-based death
	if health <= 0.0:
		return true
	
	# Neglect-based death (overripe crops die faster)
	var death_threshold: float = 120.0  # 2 minutes base
	if current_stage == GrowthStage.OVERRIPE:
		death_threshold = 60.0  # 1 minute for overripe
	
	if neglect_time > death_threshold and health < 0.3:
		return true
	
	return false

# ============================================================================
# STAGE TIMING
# ============================================================================
func get_stage_duration_weight(stage: GrowthStage) -> float:
	"""Get relative duration weight for stage"""
	return STAGE_DURATIONS.get(stage, 0.25)

func calculate_stage_duration(stage: GrowthStage, total_growth_time: float) -> float:
	"""Calculate actual duration for a stage"""
	var weight: float = get_stage_duration_weight(stage)
	return total_growth_time * weight

func get_stage_timing_info(total_growth_time: float) -> Dictionary:
	"""Get comprehensive timing information for all stages"""
	var timing: Dictionary = {}
	var cumulative_time: float = 0.0
	
	var ordered_stages: Array = [
		GrowthStage.SEED,
		GrowthStage.SPROUT,
		GrowthStage.YOUNG,
		GrowthStage.MATURE
	]
	
	for stage in ordered_stages:
		var duration: float = calculate_stage_duration(stage, total_growth_time)
		var start_time: float = cumulative_time
		var end_time: float = cumulative_time + duration
		
		timing[stage] = {
			"start_time": start_time,
			"end_time": end_time,
			"duration": duration,
			"progress_start": start_time / total_growth_time,
			"progress_end": end_time / total_growth_time
		}
		
		cumulative_time += duration
	
	return timing

# ============================================================================
# VALIDATION AND UTILITIES
# ============================================================================
func is_valid_stage(stage: GrowthStage) -> bool:
	"""Check if stage is valid"""
	return stage in GrowthStage.values()

func get_stage_name(stage: GrowthStage) -> String:
	"""Get human-readable stage name"""
	return GrowthStage.keys()[stage] if is_valid_stage(stage) else "UNKNOWN"

func get_stage_description(stage: GrowthStage) -> String:
	"""Get detailed description of growth stage"""
	match stage:
		GrowthStage.SEED:
			return "Planted seed with no visible growth yet"
		GrowthStage.SPROUT:
			return "First green shoots emerging from soil"
		GrowthStage.YOUNG:
			return "Small plant growing but not yet mature"
		GrowthStage.MATURE:
			return "Fully grown plant ready for harvest"
		GrowthStage.OVERRIPE:
			return "Past optimal harvest time, quality declining"
		GrowthStage.DEAD:
			return "Plant has died and needs to be removed"
		_:
			return "Unknown growth stage"

func validate_custom_thresholds() -> bool:
	"""Validate custom threshold configuration"""
	if custom_thresholds.is_empty():
		return true
	
	# Check that thresholds are in ascending order
	var prev_threshold: float = -1.0
	var ordered_stages: Array = [
		GrowthStage.SEED,
		GrowthStage.SPROUT,
		GrowthStage.YOUNG,
		GrowthStage.MATURE
	]
	
	for stage in ordered_stages:
		if custom_thresholds.has(stage):
			var threshold: float = custom_thresholds[stage]
			if threshold <= prev_threshold:
				print("[CropStages] ERROR: Invalid threshold order for stage %s" % get_stage_name(stage))
				return false
			prev_threshold = threshold
	
	return true

# ============================================================================
# DEBUG AND INFORMATION
# ============================================================================
func get_debug_info() -> Dictionary:
	"""Get comprehensive debug information"""
	return {
		"crop_name": crop_name,
		"total_stages": total_growth_stages,
		"has_custom_thresholds": not custom_thresholds.is_empty(),
		"custom_thresholds": custom_thresholds,
		"default_thresholds": STAGE_THRESHOLDS,
		"stage_durations": STAGE_DURATIONS,
		"water_requirements": stage_water_requirements,
		"growth_modifiers": stage_growth_modifiers,
		"validation_passed": validate_custom_thresholds()
	}

func print_stage_info() -> void:
	"""Print detailed stage configuration information"""
	print("[CropStages] === Stage Configuration for %s ===" % crop_name)
	print("[CropStages] Total stages: %d" % total_growth_stages)
	
	for stage in GrowthStage.values():
		var stage_name: String = get_stage_name(stage)
		var threshold: float = get_progress_for_stage(stage)
		var water_req: float = get_water_requirement(stage)
		var growth_mod: float = get_growth_modifier(stage)
		
		print("[CropStages] %s: threshold=%.2f, water=%.2f, growth=%.2f" % [
			stage_name, threshold, water_req, growth_mod
		])
	
	print("[CropStages] === End Stage Configuration ===")
