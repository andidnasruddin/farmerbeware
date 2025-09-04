# Godot GameManager Coding Style Guide

This style guide defines the coding standards used in the Farm Frenzy GameManager system. It emphasizes clarity, maintainability, and robust system integration.

## Core Philosophy

### 1. **Clarity Over Cleverness**
- Code should be immediately understandable by someone with zero programming experience
- Every complex operation gets explanatory comments
- Function names describe exactly what they do

### 2. **Single Responsibility Principle**
- Each class/function does exactly one thing well
- Managers handle one game system (Grid, Time, Events, etc.)
- Functions are small and focused

### 3. **Defensive Programming**
- Always check for null references before using them
- Validate inputs and handle edge cases
- Provide fallback behavior when things go wrong

## File Structure

### Header Template
```gdscript
extends Node
# FileName.gd - AUTOLOAD #X (if applicable)
# Brief description of what this system manages
# Dependencies: List other systems this depends on
```

### Section Organization
Every script follows this exact structure:

```gdscript
# ============================================================================
# ENUMS AND CONSTANTS (if needed)
# ============================================================================

# ============================================================================  
# DATA STRUCTURES (custom classes)
# ============================================================================

# ============================================================================
# SIGNALS
# ============================================================================

# ============================================================================
# PROPERTIES
# ============================================================================

# ============================================================================
# INITIALIZATION
# ============================================================================

# ============================================================================
# CORE FUNCTIONALITY (main system logic)
# ============================================================================

# ============================================================================
# SYSTEM INTEGRATION (connections to other managers)
# ============================================================================

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# ============================================================================
# DEBUG
# ============================================================================
```

## Naming Conventions

### Variables
- **snake_case** for all variables
- **Descriptive names**: `current_player_count` not `cnt`
- **Boolean prefixes**: `is_paused`, `has_connection`, `can_afford`
- **Collections**: Plurals like `active_players`, `pending_actions`

### Functions
- **snake_case** with action verbs
- **Public API**: `get_money()`, `add_player()`, `start_game()`
- **Private helpers**: `_calculate_quality()`, `_process_events()`
- **Event handlers**: `_on_player_joined()`, `_on_time_tick()`

### Constants and Enums
- **SCREAMING_SNAKE_CASE** for constants
- **PascalCase** for enum names: `GameState`, `CropType`
- **SCREAMING_SNAKE_CASE** for enum values: `PLAYING`, `MATURE`

### Signals
- **snake_case** with descriptive names
- **Past tense for events**: `player_joined`, `crop_harvested`
- **Present for states**: `state_changing`, `money_spending`

## Type Hints

### Always Use Type Hints
```gdscript
# Variables
var player_count: int = 0
var current_money: float = 1000.0
var active_players: Array[Dictionary] = []
var grid_data: Dictionary = {}

# Functions
func get_player_count() -> int:
    return active_players.size()

func add_money(amount: int, reason: String = "") -> void:
    current_money += amount
```

### Complex Types
```gdscript
# Custom classes
var player_data: PlayerManager.PlayerData = null

# Node references
var grid_manager: Node = null
var time_manager: Node = null

# Dictionaries with structure comments
var tile_data: Dictionary = {}  # Vector2i -> FarmTile
```

## Documentation Standards

### Section Headers
```gdscript
# ============================================================================
# SECTION NAME - Brief description of what this section contains
# ============================================================================
```

### Function Documentation
```gdscript
func calculate_crop_yield(crop_type: String, quality: float) -> int:
    """Calculate final yield for a harvested crop
    
    Args:
        crop_type: Type of crop being harvested
        quality: Quality factor (0.0 to 2.0)
        
    Returns:
        Final yield amount after quality modifiers
    """
    var base_yield: int = _get_base_yield(crop_type)
    return int(base_yield * quality)
```

### Inline Comments
```gdscript
# Check cooldown to prevent action spam
if current_time - last_action_time < input_cooldown:
    return

# Apply weather effects to all active crops
for position in active_crops:
    var crop: CropData = active_crops[position]
    crop.weather_effects = weather_multiplier  # Store for growth calculations
```

## System Integration Patterns

### Autoload Registration
```gdscript
func _ready() -> void:
    name = "SystemName"
    print("[SystemName] Initializing as Autoload #X...")
    
    # Get references to other systems
    other_system = OtherSystem
    if other_system:
        print("[SystemName] OtherSystem connected")
        other_system.some_signal.connect(_on_signal_received)
    else:
        print("[SystemName] WARNING: OtherSystem not found!")
    
    # Register with GameManager
    if GameManager:
        GameManager.register_system("SystemName", self)
        print("[SystemName] Registered with GameManager")
    
    print("[SystemName] Initialization complete!")
```

### Signal Connections
```gdscript
# Connect to other systems during _ready()
time_manager.day_started.connect(_on_day_started)
grid_manager.crop_planted.connect(_on_crop_planted)

# Signal handler naming convention
func _on_day_started(day_number: int) -> void:
    """Handle when a new day begins"""
    print("[SystemName] Processing new day: %d" % day_number)
```

## Error Handling

### Null Checking
```gdscript
func get_player_data(player_id: int) -> PlayerData:
    if not player_id in players:
        print("[PlayerManager] WARNING: Player %d not found" % player_id)
        return null
    
    return players[player_id]
```

### Validation
```gdscript
func spend_money(amount: int) -> bool:
    if amount <= 0:
        print("[GameManager] Invalid amount: %d" % amount)
        return false
        
    if current_money < amount:
        print("[GameManager] Insufficient funds: need %d, have %d" % [amount, current_money])
        return false
    
    current_money -= amount
    return true
```

### Fallback Behavior
```gdscript
func get_weather_multiplier(weather_type: int) -> float:
    match weather_type:
        0: return 1.2  # SUNNY
        1: return 1.0  # CLOUDY  
        2: return 0.9  # RAINY
        _: return 1.0  # Default fallback
```

## Debug Support

### Debug Info Function (Every Manager)
```gdscript
func get_debug_info() -> Dictionary:
    return {
        "primary_state": current_state,
        "key_metrics": some_important_value,
        "connection_status": other_system != null,
        "performance_data": processing_time
    }
```

### Debug Commands
```gdscript
func force_state_change(new_state: GameState) -> void:
    """Force state change (debug only)"""
    print("[SystemName] Debug: Forcing state to %s" % new_state)
    _change_state(new_state)
```

### Logging Standards
```gdscript
# Initialization
print("[SystemName] Initializing...")

# State changes  
print("[SystemName] State changed: %s → %s" % [old_state, new_state])

# Errors
print("[SystemName] ERROR: %s" % error_message)

# Warnings
print("[SystemName] WARNING: %s" % warning_message)

# Success actions
print("[SystemName] Action completed: %s" % action_description)
```

## Performance Considerations

### Object Pooling Hint
```gdscript
# Reuse objects instead of creating new ones
var particle_pool: Array[Particle] = []

func get_particle() -> Particle:
    if particle_pool.is_empty():
        return Particle.new()
    else:
        return particle_pool.pop_back()
```

### Efficient Collections
```gdscript
# Use appropriate collection types
var position_lookup: Dictionary = {}     # O(1) lookup by key
var ordered_events: Array[Event] = []    # O(1) append, ordered iteration  
var unique_items: Dictionary = {}        # Set-like behavior
```

## Testing and Validation

### Testable Functions
```gdscript
# Pure functions are easier to test
func calculate_damage(attack: int, defense: int) -> int:
    return max(1, attack - defense)  # Always deal at least 1 damage

# Avoid hidden dependencies
func process_player_action(action: PlayerAction, grid: GridManager) -> bool:
    # Explicitly pass dependencies instead of using globals
```

### Simulation Support
```gdscript
func simulate_day(day_number: int) -> Dictionary:
    """Simulate a complete day for testing"""
    _start_day(day_number)
    _process_day_events()
    return _calculate_day_results()
```

## Integration with Godot

### Node Lifecycle
```gdscript
func _ready() -> void:
    # System initialization
    
func _process(delta: float) -> void:
    # Only if system needs per-frame updates
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    
func _exit_tree() -> void:
    # Cleanup resources
```

### Scene Management
```gdscript
# Use proper resource loading
var scene_resource: PackedScene = load("res://path/to/scene.tscn")
var instance: Node = scene_resource.instantiate()

# Handle scene transitions
func change_scene(scene_path: String) -> void:
    await fade_out()
    get_tree().change_scene_to_file(scene_path)
    await fade_in()
```

## Example: Complete Function

```gdscript
func process_crop_harvest(position: Vector2i, player_id: int) -> Dictionary:
    """Process harvesting a crop at the specified position
    
    Args:
        position: Grid position of the crop
        player_id: ID of the player harvesting
        
    Returns:
        Dictionary with harvest results: {success: bool, yield: int, quality: String}
    """
    var result: Dictionary = {"success": false, "yield": 0, "quality": "none"}
    
    # Validation: Check if position is valid
    if not _is_valid_grid_position(position):
        print("[CropManager] Invalid harvest position: %s" % position)
        return result
    
    # Get crop data
    var crop: CropData = active_crops.get(position, null)
    if not crop:
        print("[CropManager] No crop at position %s" % position)
        return result
    
    # Check if crop is harvestable
    if not crop.is_harvestable():
        print("[CropManager] Crop not ready for harvest at %s" % position)
        return result
    
    # Calculate yield based on quality
    var base_yield: int = _get_base_yield(crop.crop_type)
    var quality_multiplier: float = _get_quality_multiplier(crop.quality)
    var final_yield: int = int(base_yield * quality_multiplier)
    
    # Remove crop from tracking
    active_crops.erase(position)
    
    # Prepare success result
    result["success"] = true
    result["yield"] = final_yield
    result["quality"] = CropQuality.keys()[crop.quality]
    
    # Log success
    print("[CropManager] Harvested %d %s at %s (quality: %s)" % [
        final_yield,
        CropType.keys()[crop.crop_type],
        position,
        result["quality"]
    ])
    
    # Emit signal for other systems
    crop_harvested.emit(position, crop, final_yield)
    
    return result
```

## Key Benefits of This Style

1. **Readable by Beginners**: Someone new to programming can understand what's happening
2. **Maintainable**: Easy to modify and extend systems
3. **Debuggable**: Comprehensive logging and debug functions
4. **Robust**: Handles errors gracefully and validates inputs
5. **Integrated**: Systems communicate clearly with each other
6. **Testable**: Functions can be tested in isolation
7. **Professional**: Code quality suitable for commercial projects

This style prioritizes **human understanding** over code brevity. Every line serves a clear purpose and is documented accordingly.