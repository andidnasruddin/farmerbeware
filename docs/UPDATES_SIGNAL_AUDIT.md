# Signal Audit - Cross-Manager Connections

This document audits all signal connections between our autoload managers to ensure they're correct and prevent runtime errors.

## **SIGNAL DEFINITIONS BY MANAGER**

### 🎯 **GameManager (Autoload #1)**
```gdscript
signal state_changed(from_state: GameState, to_state: GameState)
signal money_changed(new_amount: int, change: int) 
signal player_joined(player_info: Dictionary)
signal player_left(player_info: Dictionary)
signal game_over(reason: String, final_stats: Dictionary)
signal run_started()
signal run_ended(stats: Dictionary)
```

### 🔍 **GridValidator (Autoload #2)**
```gdscript
signal validation_failed(position: Vector2i, reason: String)
signal validation_passed(position: Vector2i, action: String)
```

### 🏗️ **GridManager (Autoload #3)**
```gdscript
signal tile_changed(position: Vector2i, tile: FarmTile)
signal crop_planted(position: Vector2i, crop_type: String)
signal crop_harvested(position: Vector2i, crop_type: String, yield_amount: int)  # ⭐ KEY SIGNAL
signal machine_placed(position: Vector2i, machine_type: String)
signal machine_removed(position: Vector2i, machine_type: String)
signal grid_updated()
```

### 🎮 **InteractionSystem (Autoload #4)**
```gdscript
signal action_requested(action: PlayerAction)
signal action_validated(action: PlayerAction)
signal action_executed(action: PlayerAction, result: Dictionary)
signal action_failed(action: PlayerAction, reason: String)
signal input_mode_changed(mode: String)
```

### ⏰ **TimeManager (Autoload #5)**
```gdscript
signal phase_changed(from_phase: TimePhase, to_phase: TimePhase)
signal day_started(day_number: int)
signal day_ended(day_number: int, results: Dictionary)
signal time_tick(current_time: float, phase: TimePhase)
signal countdown_warning(seconds_remaining: int)
signal game_speed_changed(speed: float)
```

### 🌦️ **EventManager (Autoload #6)**
```gdscript
signal event_started(event: GameEvent)
signal event_ended(event: GameEvent, completed: bool)
signal weather_changed(old_weather: WeatherType, new_weather: WeatherType)  # ⭐ KEY SIGNAL
signal disaster_warning(event: GameEvent, warning_time: float)
signal npc_arrived(npc_type: String, event: GameEvent)
signal flash_contract_available(contract_data: Dictionary)
```

### 🌱 **CropManager (Autoload #7)**
```gdscript
signal crop_growth_stage_changed(position: Vector2i, crop: CropData, old_stage: GrowthStage, new_stage: GrowthStage)
signal crop_quality_changed(position: Vector2i, crop: CropData, old_quality: CropQuality, new_quality: CropQuality)
signal crop_matured(position: Vector2i, crop: CropData)  # ⭐ KEY SIGNAL
signal crop_died(position: Vector2i, crop: CropData, reason: String)
signal giant_crop_formed(position: Vector2i, crop: CropData)
signal crop_mutated(position: Vector2i, crop: CropData, mutation: String)
```

### 📋 **ContractManager (Autoload #8)**
```gdscript
signal contract_available(contract: ContractData)
signal contract_accepted(contract: ContractData)
signal contract_completed(contract: ContractData, early: bool)
signal contract_failed(contract: ContractData, reason: String)
signal flash_contract_spawned(contract: ContractData)
signal delivery_progress_updated(contract: ContractData, progress: float)
signal payment_received(amount: int, bonus: int, source: String)
```

## **CROSS-MANAGER SIGNAL CONNECTIONS**

### 🔍 **GridValidator → Nobody**
- No outgoing connections (validation is queried, not signaled)

### 🏗️ **GridManager → Nobody** 
- No outgoing connections currently (signals available for UI/effects)

### 🎮 **InteractionSystem Connections:**
```gdscript
# LISTENS TO:
GameManager.state_changed → _on_game_state_changed()
# STATUS: ✅ CORRECT
```

### ⏰ **TimeManager Connections:**
```gdscript
# LISTENS TO:
GameManager.state_changed → _on_game_state_changed()  
# STATUS: ✅ CORRECT
```

### 🌦️ **EventManager Connections:**
```gdscript
# LISTENS TO:
TimeManager.day_started → _on_day_started()
TimeManager.phase_changed → _on_phase_changed()
GameManager.state_changed → _on_game_state_changed()
# STATUS: ✅ CORRECT
```

### 🌱 **CropManager Connections:**
```gdscript
# LISTENS TO:
GridManager.crop_planted → _on_crop_planted()      # ✅ CORRECT
GridManager.crop_harvested → _on_crop_harvested()  # ✅ CORRECT  
TimeManager.time_tick → _on_time_tick()            # ✅ CORRECT
TimeManager.phase_changed → _on_phase_changed()    # ✅ CORRECT
EventManager.weather_changed → _on_weather_changed() # ✅ CORRECT
```

### 📋 **ContractManager Connections:**
```gdscript
# LISTENS TO:
TimeManager.day_started → _on_day_started()        # ✅ CORRECT
TimeManager.phase_changed → _on_phase_changed()    # ✅ CORRECT
GridManager.crop_harvested → _on_crop_harvested()  # ✅ FIXED
CropManager.crop_matured → _on_crop_matured()      # ✅ ADDED
EventManager.event_started → _on_event_started()   # ✅ CORRECT
GameManager.state_changed → _on_game_state_changed() # ✅ CORRECT
```

## **COMMON SIGNAL CONNECTION ERRORS**

### ❌ **Wrong Manager**
```gdscript
# WRONG: Trying to connect to signal on wrong manager
crop_manager.crop_harvested.connect(...)  # crop_harvested is on GridManager!

# CORRECT:
grid_manager.crop_harvested.connect(...)  # ✅
```

### ❌ **Signal Doesn't Exist**
```gdscript
# WRONG: Signal not defined in target manager
time_manager.crop_ready.connect(...)  # TimeManager doesn't have crop_ready signal!

# CORRECT: Check the actual signal name
crop_manager.crop_matured.connect(...)  # ✅
```

### ❌ **Parameter Mismatch**
```gdscript
# WRONG: Handler expects different parameters than signal provides
func _on_weather_changed(weather: String) -> void:  # Signal passes two ints!

# CORRECT: Match the signal signature
func _on_weather_changed(old_weather: int, new_weather: int) -> void:  # ✅
```

### ❌ **Missing Null Checks**
```gdscript
# WRONG: Not checking if manager exists
time_manager.day_started.connect(_on_day_started)  # Crash if time_manager is null!

# CORRECT: Always check first
if time_manager:
    time_manager.day_started.connect(_on_day_started)  # ✅
```

## **SIGNAL CONNECTION VERIFICATION CHECKLIST**

For each signal connection, verify:

1. **✅ Target Manager Exists**: `if manager_name:`
2. **✅ Signal Exists**: Check the signal definitions above
3. **✅ Correct Manager**: Make sure signal is on the right manager
4. **✅ Parameter Match**: Handler parameters match signal parameters
5. **✅ Handler Exists**: The `_on_signal_name()` function is defined
6. **✅ Error Handling**: Connection is inside null check

## **TESTING SIGNAL CONNECTIONS**

Add this debug function to any manager to verify connections:

```gdscript
func debug_signal_connections() -> void:
    """Debug function to verify signal connections"""
    print("[%s] Signal connections:" % name)
    
    # List all connected signals
    for signal_name in get_signal_list():
        var signal_obj = get(signal_name.name)
        if signal_obj.get_connections().size() > 0:
            print("  %s: %d connections" % [signal_name.name, signal_obj.get_connections().size()])
        else:
            print("  %s: no connections" % signal_name.name)
```

## **SIGNAL FLOW DIAGRAM**

```
GameManager (state_changed)
    ↓
    ├── InteractionSystem (input mode changes)
    ├── TimeManager (pause/resume)
    ├── EventManager (event processing)
    └── ContractManager (contract processing)

TimeManager (day_started, phase_changed)
    ↓
    ├── EventManager (daily events, phase events)
    ├── CropManager (growth speed changes)
    └── ContractManager (new contracts, phase logic)

EventManager (weather_changed)
    ↓
    └── CropManager (weather effects on growth)

GridManager (crop_planted, crop_harvested)
    ↓
    ├── CropManager (register crops, track harvests)
    └── ContractManager (fulfill contracts)

CropManager (crop_matured)
    ↓
    └── ContractManager (harvest notifications)
```

## **BEST PRACTICES**

1. **Document Signal Purpose**: Every signal should have a clear purpose
2. **Consistent Naming**: Use past tense for completed events (`crop_harvested`)
3. **Meaningful Parameters**: Include all data listeners might need
4. **Null Safety**: Always check manager existence before connecting
5. **Error Handling**: Handle connection failures gracefully
6. **Performance**: Don't emit signals every frame unless necessary
7. **Debugging**: Include signal emission in debug logs when troubleshooting

This audit ensures our signal system is robust and prevents runtime connection errors!