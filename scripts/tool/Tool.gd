extends Resource
class_name Tool
# Tool.gd - Data-driven tool definition (not a scene)

# ============================================================================
# PROPERTIES
# ============================================================================
@export var id: String = ""                  # "hoe", "watering_can", "seed_bag", ...
@export var display_name: String = ""        # "Bronze Hoe", "Basic Watering Can", etc.
@export var icon: Texture2D = null           # Optional UI icon
@export var action_type: String = ""         # "till", "water", "plant", "harvest", "fertilize", "test_soil"

# Cost and usage
@export var stamina_cost: float = 0.0        # Per action
@export var uses_per_refill: int = 0         # 0 if unlimited (used by watering can)

# Targeting (simple; detailed shapes handled later in TargetCalculator)
@export var area: Vector2i = Vector2i(1, 1)  # Width x Height (e.g., 3x1 for watering can)
@export var range: int = 1                   # Tiles from player center (used in preview/validation)

# Tool-specific extra parameters (flexible)
@export var params: Dictionary = {}          # e.g., {"water_add": 25, "seed_id": "lettuce"}

# ============================================================================
# HELPERS
# ============================================================================
func is_valid() -> bool:
	return not id.is_empty() and not action_type.is_empty()
