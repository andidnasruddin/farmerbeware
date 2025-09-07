extends Resource
class_name CropData
# CropData.gd - Resource-based crop data structure
# Defines all crop properties for data-driven crop system
# Used by CropManager for crop lifecycle management

# ============================================================================
# ENUMS AND CONSTANTS
# ============================================================================
enum CropTier {
	TIER1 = 1,		# Easy crops - lettuce, corn, wheat
	TIER2 = 2,		# Medium crops - tomato, potato  
	TIER3 = 3,		# Hard crops - pumpkin, strawberry
	TIER4 = 4,		# Expert crops - watermelon
	SPECIAL = 5		# Special/magic crops
}

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

enum GrowthRequirement {
	NONE = 0,			# No special requirements
	HIGH_WATER = 1,		# Needs frequent watering
	GOOD_SOIL = 2,		# Needs high fertility
	STABLE_WEATHER = 4,	# Sensitive to weather changes
	CAREFUL_TIMING = 8	# Harvest timing critical
}

# ============================================================================
# EXPORTED PROPERTIES - Basic Info
# ============================================================================
@export_group("Basic Information")
@export var crop_name: String = "Unknown Crop"
@export var crop_type: CropType = CropType.LETTUCE
@export var crop_tier: CropTier = CropTier.TIER1
@export_multiline var description: String = "A basic crop."

# ============================================================================
# EXPORTED PROPERTIES - Growth Parameters
# ============================================================================
@export_group("Growth Parameters")
@export_range(10.0, 300.0) var base_growth_time: float = 60.0		# Seconds to mature
@export_range(1, 6) var growth_stages: int = 4						# Number of growth stages
@export_range(0.1, 3.0) var growth_variance: float = 0.2			# Random time variance
@export var multi_harvest: bool = false							# Can harvest multiple times
@export_range(1, 5) var harvest_cycles: int = 1					# Number of harvest cycles

# ============================================================================
# EXPORTED PROPERTIES - Requirements and Care
# ============================================================================
@export_group("Care Requirements")
@export_flags("High Water", "Good Soil", "Stable Weather", "Careful Timing") var special_requirements: int = 0
@export_range(0.1, 2.0) var water_consumption_rate: float = 0.5	# Water per second
@export_range(0.0, 1.0) var soil_fertility_min: float = 0.3		# Minimum soil fertility needed
@export_range(0.0, 1.0) var optimal_water_level: float = 0.7		# Optimal water level
@export_range(-0.5, 1.0) var weather_resistance: float = 0.0		# Weather effect resistance

# ============================================================================
# EXPORTED PROPERTIES - Value and Rewards
# ============================================================================
@export_group("Economic Values")
@export_range(1, 100) var base_value: int = 10						# Base sell value
@export_range(1, 10) var base_yield: int = 1						# Base harvest amount
@export_range(1.0, 3.0) var quality_multiplier_max: float = 2.0	# Max quality bonus
@export_range(0, 100) var seed_cost: int = 5						# Cost to buy seeds
@export_range(0.0, 1.0) var giant_crop_chance: float = 0.02		# Chance for giant crop

# ============================================================================
# EXPORTED PROPERTIES - Visual Properties
# ============================================================================
@export_group("Visual Properties")
@export var growth_stage_textures: Array[Texture2D] = []			# Textures for each growth stage
@export var mature_texture: Texture2D								# Final mature texture
@export var harvest_particles: PackedScene						# Harvest effect scene
@export var growth_sound: AudioStream							# Growth stage sound

# ============================================================================
# EXPORTED PROPERTIES - Special Properties
# ============================================================================
@export_group("Special Properties")
@export var can_become_giant: bool = true							# Can form 3x3 giant crops
@export var mutation_chance: float = 0.01							# Random mutation chance
@export var seasonal_bonus: bool = false							# Gets seasonal bonuses
@export var weather_immunity: bool = false							# Immune to weather effects
@export var disease_resistance: float = 1.0						# Disease resistance factor

# ============================================================================
# VALIDATION AND HELPER METHODS
# ============================================================================
func is_valid() -> bool:
	"""Validate crop data for completeness and consistency"""
	var is_data_valid: bool = true
	
	# Check basic properties
	if crop_name.is_empty():
		print("[CropData] Validation failed: crop_name is empty")
		is_data_valid = false
	
	if base_growth_time <= 0.0:
		print("[CropData] Validation failed: base_growth_time must be > 0")
		is_data_valid = false
	
	if growth_stages < 2:
		print("[CropData] Validation failed: growth_stages must be >= 2")
		is_data_valid = false
	
	if base_value <= 0:
		print("[CropData] Validation failed: base_value must be > 0")
		is_data_valid = false
	
	if base_yield <= 0:
		print("[CropData] Validation failed: base_yield must be > 0")
		is_data_valid = false
	
	# Check texture array size matches growth stages
	if growth_stage_textures.size() > 0 and growth_stage_textures.size() != growth_stages:
		print("[CropData] Warning: growth_stage_textures size (%d) doesn't match growth_stages (%d)" % [growth_stage_textures.size(), growth_stages])
	
	return is_data_valid

func get_growth_time_with_variance() -> float:
	"""Get randomized growth time including variance"""
	var variance_amount: float = base_growth_time * growth_variance
	var random_offset: float = randf_range(-variance_amount, variance_amount)
	return base_growth_time + random_offset

func get_stage_duration() -> float:
	"""Get duration for each growth stage"""
	return get_growth_time_with_variance() / float(growth_stages)

func has_requirement(requirement: GrowthRequirement) -> bool:
	"""Check if crop has specific growth requirement"""
	return (special_requirements & requirement) != 0

func get_tier_name() -> String:
	"""Get human-readable tier name"""
	match crop_tier:
		CropTier.TIER1: return "Tier 1 (Easy)"
		CropTier.TIER2: return "Tier 2 (Medium)"
		CropTier.TIER3: return "Tier 3 (Hard)"
		CropTier.TIER4: return "Tier 4 (Expert)"
		CropTier.SPECIAL: return "Special"
		_: return "Unknown"

func get_type_name() -> String:
	"""Get human-readable crop type name"""
	return CropType.keys()[crop_type] if crop_type < CropType.size() else "UNKNOWN"

func calculate_final_value(quality_factor: float = 1.0, quantity: int = 1) -> int:
	"""Calculate final crop value based on quality and quantity"""
	var base_total: int = base_value * base_yield * quantity
	var quality_bonus: float = clamp(quality_factor, 0.5, quality_multiplier_max)
	return int(base_total * quality_bonus)

func get_requirements_text() -> String:
	"""Get formatted text describing crop requirements"""
	var requirements: Array[String] = []
	
	if has_requirement(GrowthRequirement.HIGH_WATER):
		requirements.append("High Water")
	if has_requirement(GrowthRequirement.GOOD_SOIL):
		requirements.append("Good Soil") 
	if has_requirement(GrowthRequirement.STABLE_WEATHER):
		requirements.append("Stable Weather")
	if has_requirement(GrowthRequirement.CAREFUL_TIMING):
		requirements.append("Careful Timing")
	
	if requirements.is_empty():
		return "No special requirements"
	else:
		return "Requires: " + ", ".join(requirements)

# ============================================================================
# DEBUG METHODS
# ============================================================================
func get_debug_info() -> Dictionary:
	"""Get comprehensive debug information about this crop data"""
	return {
		"crop_name": crop_name,
		"crop_type": get_type_name(),
		"crop_tier": get_tier_name(),
		"base_growth_time": base_growth_time,
		"growth_stages": growth_stages,
		"base_value": base_value,
		"base_yield": base_yield,
		"requirements": get_requirements_text(),
		"multi_harvest": multi_harvest,
		"can_become_giant": can_become_giant,
		"is_valid": is_valid()
	}

func print_debug_info() -> void:
	"""Print comprehensive debug information"""
	print("[CropData] === %s Debug Info ===" % crop_name)
	var debug_data: Dictionary = get_debug_info()
	for key in debug_data:
		print("[CropData] %s: %s" % [key, debug_data[key]])
	print("[CropData] === End Debug Info ===")
