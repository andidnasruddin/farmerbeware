extends Node
class_name CropGrowth
# CropGrowth.gd - Growth timing and logic component
# Handles crop growth progression, stage transitions, and timing
# Dependencies: CropData resource, CropStages resource, parent Crop controller

# ============================================================================
# SIGNALS
# ============================================================================
signal stage_advanced(old_stage: int, new_stage: int)
signal growth_updated(progress: float)
signal growth_completed()
signal growth_stunted(reason: String)

# ============================================================================
# PROPERTIES
# ============================================================================
var parent_crop: Crop = null
var crop_data: CropData = null
var crop_stages: CropStages = null

# Growth timing
var growth_timer: float = 0.0
var stage_timer: float = 0.0
var stage_duration: float = 0.0
var total_growth_time: float = 0.0
var variance_applied: bool = false

# Growth modifiers
var base_growth_rate: float = 1.0
var current_growth_rate: float = 1.0
var accumulated_bonuses: float = 0.0
var accumulated_penalties: float = 0.0

# Stage tracking
var current_stage_index: int = 0
var max_stages: int = 4
var stage_thresholds: Array[float] = []

# Processing control
var is_processing_growth: bool = true
var last_update_time: float = 0.0
var update_interval: float = 0.1  # Update 10 times per second

# ============================================================================
# INITIALIZATION
# ============================================================================
func initialize(crop_controller: Crop, crop_resource: CropData) -> void:
	"""Initialize growth system with crop data"""
	if not crop_controller or not crop_resource:
		print("[CropGrowth] ERROR: Invalid initialization parameters")
		return
	
	parent_crop = crop_controller
	crop_data = crop_resource
	
	# Initialize CropStages system
	crop_stages = CropStages.new(crop_data)
	
	# Setup growth timing
	_setup_growth_timing()
	_setup_stage_thresholds()
	
	# Connect to parent crop signals if available
	_connect_parent_signals()
	
	print("[CropGrowth] Initialized for %s - Total time: %.1fs" % [crop_data.crop_name, total_growth_time])

func _setup_growth_timing() -> void:
	"""Calculate growth timing with variance"""
	if not crop_data:
		return
	
	# Get base growth time with variance applied once
	if not variance_applied:
		total_growth_time = crop_data.get_growth_time_with_variance()
		variance_applied = true
	
	max_stages = crop_data.growth_stages
	stage_duration = total_growth_time / float(max_stages)
	
	# Reset timers
	growth_timer = 0.0
	stage_timer = 0.0
	current_stage_index = 0

func _setup_stage_thresholds() -> void:
	"""Setup progress thresholds for each growth stage using CropStages"""
	stage_thresholds.clear()
	
	if crop_stages:
		# Use CropStages system for precise threshold management
		var stages: Array = [
			CropStages.GrowthStage.SEED,
			CropStages.GrowthStage.SPROUT,
			CropStages.GrowthStage.YOUNG,
			CropStages.GrowthStage.MATURE
		]
		
		for stage in stages:
			var threshold: float = crop_stages.get_progress_for_stage(stage)
			stage_thresholds.append(threshold)
		
		print("[CropGrowth] Stage thresholds from CropStages: %s" % str(stage_thresholds))
	else:
		# Fallback to default thresholds
		for i in max_stages:
			var threshold: float = float(i + 1) / float(max_stages)
			stage_thresholds.append(threshold)
		
		print("[CropGrowth] Default stage thresholds: %s" % str(stage_thresholds))

func _connect_parent_signals() -> void:
	"""Connect to parent crop signals for environmental updates"""
	if not parent_crop:
		return
	
	# Note: Parent crop will handle most environmental effects
	# This component focuses purely on growth timing and progression

# ============================================================================
# CORE FUNCTIONALITY - Growth Processing
# ============================================================================
func _process(delta: float) -> void:
	"""Process growth timing and stage progression"""
	if not is_processing_growth or not crop_data or not parent_crop:
		return
	
	# Only update at intervals for performance
	var current_time: float = Time.get_unix_time_from_system()
	if current_time - last_update_time < update_interval:
		return
	
	var actual_delta: float = current_time - last_update_time
	last_update_time = current_time
	
	# Process growth if not at final stage
	if current_stage_index < max_stages:
		_process_growth_timing(actual_delta)

func _process_growth_timing(delta: float) -> void:
	"""Process growth timing with environmental factors"""
	# Calculate current growth rate from parent crop
	current_growth_rate = _calculate_effective_growth_rate()
	
	# Apply growth rate to timers
	var effective_delta: float = delta * current_growth_rate
	growth_timer += effective_delta
	stage_timer += effective_delta
	
	# Calculate current progress
	var overall_progress: float = clamp(growth_timer / total_growth_time, 0.0, 1.0)
	
	# Check for stage advancement
	_check_stage_advancement(overall_progress)
	
	# Emit growth update
	growth_updated.emit(overall_progress)
	
	# Check for completion
	if overall_progress >= 1.0:
		_on_growth_completed()

func _calculate_effective_growth_rate() -> float:
	"""Calculate effective growth rate based on all factors"""
	if not parent_crop:
		return base_growth_rate
	
	var effective_rate: float = base_growth_rate
	
	# Apply stage-specific growth modifier from CropStages
	if crop_stages:
		var current_crop_stage: CropStages.GrowthStage = _get_current_crop_stage()
		var stage_modifier: float = crop_stages.get_growth_modifier(current_crop_stage)
		effective_rate *= stage_modifier
	
	# Get modifiers from parent crop
	var water_modifier: float = _get_water_growth_modifier()
	var health_modifier: float = parent_crop.health
	var weather_modifier: float = parent_crop.weather_effects
	var fertilizer_modifier: float = 1.0 + parent_crop.fertilizer_bonus
	
	# Apply all modifiers
	effective_rate *= water_modifier
	effective_rate *= health_modifier
	effective_rate *= weather_modifier
	effective_rate *= fertilizer_modifier
	
	# Apply disease penalty
	if parent_crop.is_diseased:
		effective_rate *= 0.6
	
	# Apply accumulated bonuses and penalties
	effective_rate += accumulated_bonuses
	effective_rate -= accumulated_penalties
	
	return clamp(effective_rate, 0.1, 3.0)

func _get_current_crop_stage() -> CropStages.GrowthStage:
	"""Get current crop stage in CropStages enum format"""
	if not crop_stages:
		return CropStages.GrowthStage.SEED
	
	var progress: float = get_current_progress()
	return crop_stages.get_stage_for_progress(progress)

func _get_water_growth_modifier() -> float:
	"""Calculate growth modifier based on water level and stage-specific requirements"""
	if not parent_crop or not crop_data:
		return 1.0
	
	var water_level: float = parent_crop.water_level
	var optimal_level: float = crop_data.optimal_water_level
	
	# Get stage-specific water requirement from CropStages
	var stage_water_requirement: float = optimal_level
	if crop_stages:
		var current_crop_stage: CropStages.GrowthStage = _get_current_crop_stage()
		stage_water_requirement = crop_stages.get_water_requirement(current_crop_stage)
	
	# Calculate water modifier curve based on stage requirements
	var water_deviation: float = abs(water_level - stage_water_requirement)
	
	if water_level < 0.2:
		return 0.3  # Severe drought stress
	elif water_level < 0.4:
		return 0.7  # Mild drought stress
	elif water_deviation <= 0.1:
		return 1.3  # Optimal watering bonus for stage
	elif water_level > 0.9:
		return 0.8  # Overwatering penalty
	else:
		return 1.0  # Normal growth

func _check_stage_advancement(overall_progress: float) -> void:
	"""Check if crop should advance to next growth stage"""
	# Determine target stage based on overall progress
	var target_stage: int = _get_target_stage_for_progress(overall_progress)
	
	# Advance stages if needed
	while current_stage_index < target_stage and current_stage_index < max_stages - 1:
		_advance_stage()

func _get_target_stage_for_progress(progress: float) -> int:
	"""Get target stage index for given progress"""
	for i in stage_thresholds.size():
		if progress < stage_thresholds[i]:
			return i
	
	return max_stages - 1

func _advance_stage() -> void:
	"""Advance to the next growth stage"""
	var old_stage: int = current_stage_index
	current_stage_index = min(current_stage_index + 1, max_stages - 1)
	stage_timer = 0.0
	
	# Emit stage advancement signal
	stage_advanced.emit(old_stage, current_stage_index)
	
	print("[CropGrowth] %s advanced from stage %d to %d" % [crop_data.crop_name, old_stage, current_stage_index])

func _on_growth_completed() -> void:
	"""Handle growth completion"""
	is_processing_growth = false
	growth_completed.emit()
	
	print("[CropGrowth] %s completed growth" % crop_data.crop_name)

# ============================================================================
# GROWTH MODIFIERS AND EFFECTS
# ============================================================================
func apply_growth_bonus(bonus_amount: float, duration: float = -1.0) -> void:
	"""Apply temporary or permanent growth bonus"""
	accumulated_bonuses = clamp(accumulated_bonuses + bonus_amount, 0.0, 2.0)
	
	# If duration is specified, schedule removal
	if duration > 0.0:
		var timer: SceneTreeTimer = get_tree().create_timer(duration)
		timer.timeout.connect(_remove_growth_bonus.bind(bonus_amount))
	
	print("[CropGrowth] Growth bonus applied: +%.2f" % bonus_amount)

func apply_growth_penalty(penalty_amount: float, duration: float = -1.0) -> void:
	"""Apply temporary or permanent growth penalty"""
	accumulated_penalties = clamp(accumulated_penalties + penalty_amount, 0.0, 2.0)
	
	# If duration is specified, schedule removal
	if duration > 0.0:
		var timer: SceneTreeTimer = get_tree().create_timer(duration)
		timer.timeout.connect(_remove_growth_penalty.bind(penalty_amount))
	
	print("[CropGrowth] Growth penalty applied: -%.2f" % penalty_amount)

func _remove_growth_bonus(bonus_amount: float) -> void:
	"""Remove temporary growth bonus"""
	accumulated_bonuses = clamp(accumulated_bonuses - bonus_amount, 0.0, 2.0)
	print("[CropGrowth] Growth bonus removed: -%.2f" % bonus_amount)

func _remove_growth_penalty(penalty_amount: float) -> void:
	"""Remove temporary growth penalty"""
	accumulated_penalties = clamp(accumulated_penalties - penalty_amount, 0.0, 2.0)
	print("[CropGrowth] Growth penalty removed: +%.2f" % penalty_amount)

func stunt_growth(reason: String, duration: float) -> void:
	"""Temporarily halt growth progression"""
	is_processing_growth = false
	growth_stunted.emit(reason)
	
	# Resume growth after duration
	var timer: SceneTreeTimer = get_tree().create_timer(duration)
	timer.timeout.connect(_resume_growth)
	
	print("[CropGrowth] Growth stunted for %.1fs: %s" % [duration, reason])

func _resume_growth() -> void:
	"""Resume growth progression after stunting"""
	is_processing_growth = true
	print("[CropGrowth] Growth resumed")

func accelerate_growth(multiplier: float, duration: float) -> void:
	"""Temporarily accelerate growth"""
	apply_growth_bonus(multiplier - 1.0, duration)
	print("[CropGrowth] Growth accelerated by %.1fx for %.1fs" % [multiplier, duration])

# ============================================================================
# WEATHER AND ENVIRONMENTAL EFFECTS
# ============================================================================
func apply_weather_effect(weather_type: int, effect_strength: float) -> void:
	"""Apply weather-specific growth effects"""
	match weather_type:
		0:  # SUNNY
			if effect_strength > 0:
				apply_growth_bonus(0.2, 60.0)  # 1 minute sunny bonus
		1:  # RAINY  
			if effect_strength > 0:
				# Rain provides water but may reduce growth slightly
				apply_growth_penalty(0.1, 30.0)
		2:  # STORM
			if effect_strength > 0:
				stunt_growth("storm", 15.0)  # 15 second stunt
		_:
			print("[CropGrowth] Unknown weather type: %d" % weather_type)

func apply_seasonal_effect(season_multiplier: float) -> void:
	"""Apply seasonal growth modifier"""
	base_growth_rate = clamp(season_multiplier, 0.5, 2.0)
	print("[CropGrowth] Seasonal modifier applied: %.2f" % season_multiplier)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func get_current_progress() -> float:
	"""Get current overall growth progress (0.0 to 1.0)"""
	if total_growth_time <= 0.0:
		return 0.0
	
	return clamp(growth_timer / total_growth_time, 0.0, 1.0)

func get_stage_progress() -> float:
	"""Get progress within current stage (0.0 to 1.0)"""
	if stage_duration <= 0.0:
		return 0.0
	
	return clamp(stage_timer / stage_duration, 0.0, 1.0)

func get_time_remaining() -> float:
	"""Get estimated time remaining to maturity"""
	var remaining_progress: float = 1.0 - get_current_progress()
	var estimated_rate: float = max(current_growth_rate, 0.1)
	
	return (remaining_progress * total_growth_time) / estimated_rate

func get_stage_name() -> String:
	"""Get current growth stage name"""
	var stage_names: Array[String] = ["SEED", "SPROUT", "YOUNG", "MATURE"]
	
	if current_stage_index < stage_names.size():
		return stage_names[current_stage_index]
	else:
		return "MATURE"

func is_mature() -> bool:
	"""Check if crop has reached maturity"""
	return current_stage_index >= max_stages - 1 and get_current_progress() >= 1.0

func reset_growth() -> void:
	"""Reset growth system (for multi-harvest crops)"""
	growth_timer = total_growth_time * 0.7  # Start at 70% for regrowth
	stage_timer = 0.0
	current_stage_index = 2  # Start at YOUNG stage
	is_processing_growth = true
	
	print("[CropGrowth] Growth reset for next harvest cycle")

# ============================================================================
# DEBUG
# ============================================================================
func get_debug_info() -> Dictionary:
	"""Get comprehensive debug information"""
	return {
		"crop_name": crop_data.crop_name if crop_data else "No Data",
		"current_stage": get_stage_name(),
		"stage_index": current_stage_index,
		"overall_progress": "%.1f%%" % (get_current_progress() * 100),
		"stage_progress": "%.1f%%" % (get_stage_progress() * 100),
		"growth_timer": "%.1fs" % growth_timer,
		"total_time": "%.1fs" % total_growth_time,
		"time_remaining": "%.1fs" % get_time_remaining(),
		"growth_rate": "%.2fx" % current_growth_rate,
		"bonuses": accumulated_bonuses,
		"penalties": accumulated_penalties,
		"is_processing": is_processing_growth,
		"is_mature": is_mature()
	}

func print_debug_info() -> void:
	"""Print comprehensive debug information"""
	print("[CropGrowth] === Growth Debug Info ===")
	var debug_data: Dictionary = get_debug_info()
	for key in debug_data:
		print("[CropGrowth] %s: %s" % [key, debug_data[key]])
	print("[CropGrowth] === End Debug Info ===")
