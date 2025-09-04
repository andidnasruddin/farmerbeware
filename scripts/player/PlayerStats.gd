extends Resource
class_name PlayerStats
# PlayerStats.gd - Default player stats for stamina and tool costs

# ============================================================================
# PROPERTIES
# ============================================================================
@export var stamina_max: float = 100.0
@export var stamina_recovery_per_sec: float = 10.0
@export var sprint_stamina_cost_per_sec: float = 15.0

# Movement modifiers
@export var carry_speed_multiplier: float = 0.75
@export var sprint_enabled: bool = true

# Tool stamina costs (per action)
@export var tool_stamina_costs: Dictionary = {
	"hoe": 5.0,
	"watering_can": 3.0,
	"seed_bag": 2.0,
	"harvester": 4.0,
	"fertilizer": 3.0,
	"soil_test": 0.0
}
