# Grid System Completion Summary

## Overview
This document summarizes the implemented Grid System per `2_GridSystem.md`, including file locations, responsibilities, signals/APIs, and where to make changes.

---

## 📋 Autoloads and Order

### Core Autoloads (unchanged)
- **Autoload #2:** `GridValidator`
- **Autoload #3:** `GridManager`
- All other autoloads remain as previously set (1–14)

---

## 🏗️ Core Data

### FarmTile Resource
**Path:** `res://scripts/grid/FarmTileData.gd`  
**Type:** Resource (replaces inner class approach)

#### Identity and State
```gdscript
@export var position: Vector2i
@export var chunk_id: Vector2i
@export var grid_index: int
@export var is_fenced: bool
@export var state: int = TileState.EMPTY
```

#### Tile Contents
```gdscript
@export var crop: Dictionary
@export var machine: Dictionary
@export var item: Dictionary

func has_crop() -> bool
func has_machine() -> bool
func is_empty() -> bool
```

#### Chemistry Properties (stubs)
```gdscript
@export var nitrogen: float
@export var phosphorus: float
@export var potassium: float
@export var ph_level: float
@export var water_content: float      # 0..100 scale
@export var organic_matter: float
@export var fertilizer_type: String
@export var contamination_level: float
```

#### History Tracking
```gdscript
@export var previous_crops: Array[String]
@export var last_harvest_quality: int
@export var same_crop_count: int
@export var fallow_days: int
@export var total_harvests: int
```

#### Serialization
```gdscript
to_dict() -> Dictionary
from_dict(data: Dictionary) -> void  # includes legacy migration
```

---

## 🌐 Grid Manager

**Path:** `res://scripts/managers/GridManager.gd`

### Constants and Defaults
```gdscript
const DEFAULT_GRID_SIZE := Vector2i(10, 10)
const MAX_GRID_SIZE := Vector2i(100, 100)
const CHUNK_SIZE := 10
var fence_bounds: Rect2i = Rect2i(Vector2i.ZERO, DEFAULT_GRID_SIZE)
```

### Dependencies
- `grid_validator: Node`
- `chunk_manager: ChunkManager`
- `soil_chemistry: SoilChemistry`

### Core Data
```gdscript
var grid_data: Dictionary            # Vector2i -> FarmTileData
var dirty_tiles: Array[Vector2i]
var update_queue: Array[TileUpdate]  # batched tile updates
```

### Signals
```gdscript
signal tile_changed(position: Vector2i, tile: FarmTileData)
signal grid_expanded(new_size: Vector2i)
signal chunk_dirty(chunk_pos: Vector2i)
signal crop_planted(position: Vector2i, crop_type: String)
signal crop_harvested(position: Vector2i, crop_type: String, yield_amount: int)
signal machine_placed(position: Vector2i, machine_type: String)
signal machine_removed(position: Vector2i, machine_type: String)
```

### Public API

#### Tile Operations
- `get_tile(pos) -> FarmTileData`
- `set_tile(pos, tile) -> bool`
- `has_tile(pos) -> bool`
- `remove_tile(pos) -> bool`

#### Farming Actions
- `till_soil(pos, player_id) -> bool`
- `water_tile(pos, amount_0_1, player_id) -> bool`
- `plant_crop(pos, crop_type, player_id) -> bool`
- `harvest_crop(pos, player_id) -> Dictionary`
- `place_machine(pos, machine_type, player_id) -> bool`

#### Grid Management
- `expand_grid(new_size: Vector2i) -> void`
- `serialize_grid() -> Dictionary` (version: 2)
- `deserialize_grid(data: Dictionary) -> void`
- `is_chunk_dirty(chunk_id: Vector2i) -> bool`

### Batching System (new)
- Enqueue once per tile change via `_enqueue_tile_update(pos, TileUpdate.UpdateType.*)`
- Processed end-of-frame in `_process(_delta)`
- Emits `tile_changed` per affected position

---

## 🔧 Helper Classes

### GridHelpers
**Path:** `res://scripts/grid/GridHelpers.gd`

**Utilities:**
- `grid_to_index(pos, width) -> int`
- `index_to_grid(index, width) -> Vector2i`
- `grid_to_chunk(pos, chunk_size) -> Vector2i`
- `chunk_to_bounds(chunk_id, chunk_size) -> Rect2i`
- `neighbors4(pos) -> Array[Vector2i]`
- `neighbors8(pos) -> Array[Vector2i]`

### TileUpdate (batching unit)
**Path:** `res://scripts/grid/TileUpdate.gd`

```gdscript
enum UpdateType { STATE, CHEMISTRY, WATER, FERTILIZER, CONTAMINATION, RESET }
var position: Vector2i
var update_type: int
var payload: Dictionary
var priority: int
```

---

## ✅ Validation System

### GridValidator
**Path:** `res://scripts/managers/GridValidator.gd`

#### Fence Support
```gdscript
var fence_bounds: Rect2i
set_fence_bounds(bounds: Rect2i)
is_fenced(pos) -> bool
is_within_farm_bounds(pos) -> bool  # uses fence if set; else grid bounds
```

#### New API
- `can_place_at(pos, size) -> bool` - bounds only
- `get_area_tiles(pos, size) -> Array[Vector2i]`
- `check_adjacency_rules(pos, type) -> bool` - stub returns true
- `world_to_grid(world_pos) -> Vector2i`
- `grid_to_world(grid_pos) -> Vector2`

---

## 🗺️ Chunking System

### ChunkManager
**Path:** `res://scripts/grid/ChunkManager.gd`

**Responsibilities:**
- `get_chunk_id_for_pos(pos) -> Vector2i`
- `get_chunk_bounds(chunk_id) -> Rect2i`
- `mark_dirty_by_pos(pos) -> chunk_id`
- `get_dirty_chunks() -> Array[Vector2i]`
- `iterate_chunk_positions(chunk_id) -> Array[Vector2i]`
- `set_config(chunk_size, grid_size)`

---

## 🧪 Chemistry System (Stubs)

**Path:** `res://scripts/chemistry/`

| File | Purpose |
|------|---------|
| `SoilChemistry.gd` | Orchestrator; clamp, evaluate quality (stub) |
| `NPKManager.gd` | NPK index, apply fertilizer (stub) |
| `PHManager.gd` | pH factor and adjust (stub) |
| `WaterManager.gd` | Evaporation/irrigate (stub; no-op by default) |
| `ContaminationManager.gd` | Factor=1.0 (stub) |

GridManager holds a `SoilChemistry` instance; not yet affecting gameplay.

---

## 🚧 Fence & Expansion

### FenceSystem
**Path:** `res://scripts/fence/FenceSystem.gd`

```gdscript
@export var min_size = Vector2i(10, 10)
@export var max_size = Vector2i(100, 100)
var bounds: Rect2i

set_bounds(new_bounds)
expand_to(new_size)
apply_to_grid_manager()  # optional: syncs grid size to fence
signal fence_updated(bounds)
```

### FenceValidator
**Path:** `res://scripts/fence/FenceValidator.gd`

**Stateless Helpers:**
- `is_inside(bounds, pos) -> bool`
- `is_on_edge(bounds, pos) -> bool`
- `clamp_to_bounds(bounds, pos) -> Vector2i`
- `rect_tiles(bounds) -> Array[Vector2i]`

### ExpansionManager
**Path:** `res://scripts/fence/ExpansionManager.gd`

```gdscript
request_expand_to(new_size) -> bool
signal expansion_requested
signal expansion_approved
signal expansion_rejected
signal expansion_completed
```

---

## 🎨 Visual System

### TileMapRenderer
- **Path:** `res://scenes/visual/TileMapRenderer.gd`
- **Scene:** `res://scenes/visual/TileMapRenderer.tscn`

**Responsibilities:**
- Draw tiles by `FarmTileData.TileState` using solid colors
- Subscribe to: `grid_expanded`, `tile_changed`, `chunk_dirty`
- Methods: `_get_tile_color(pos)`, `grid_to_world`, `world_to_grid`

### ChunkRenderer
- **Path:** `res://scenes/visual/ChunkRenderer.gd`
- **Scene:** `res://scenes/visual/ChunkRenderer.tscn`

**Responsibilities:**
- Draw `CHUNK_SIZE` grid lines
- Highlight dirty chunks for `highlight_seconds`
- Subscribe to: `chunk_dirty`, `grid_expanded`

### GridDebugOverlay
- **Path:** `res://scenes/debug/GridDebugOverlay.gd`

**Features:**
- Show fence rectangle outline
- Draw chunk grid lines
- Hover highlight over tile under mouse

```gdscript
@export show_fence
@export show_chunks
@export show_hover
```

---

## 🎬 Grid System Scene

**Path:** `res://scenes/game/GridSystem.tscn`

**Scene Composition (top to bottom for layering):**
1. `TileMapRenderer`
2. `ChunkRenderer`
3. `GridDebugOverlay` (optional)

---

## 💾 Serialization

**GridManager:**
- `serialize_grid()` returns version: 2
- `deserialize_grid()`:
  - Reconfigures fence and ChunkManager
  - Updates GridValidator size + fence
  - Handles legacy fields via `FarmTileData.from_dict`:
    - `water_level` → `water_content` (×100)
    - `fertility` → `organic_matter` (scaled)
    - Derives state if missing

---

## 🔧 How to Extend/Change

| Component | How to Modify |
|-----------|--------------|
| **Tile visuals** | Adjust colors or replace with textures in `TileMapRenderer._get_tile_color` |
| **Chunk overlay** | Tweak `highlight_seconds` or colors in `ChunkRenderer` |
| **Fence rect** | Use `FenceSystem.set_bounds()` or `expand_to(new_size)`; call `apply_to_grid_manager()` |
| **Batch updates** | Extend `TileUpdate.UpdateType` and enqueue through `_enqueue_tile_update` |
| **Chemistry** | Change `WaterManager.EVAP_RATE_PER_SEC`, or call `SoilChemistry.process_batch()` |
| **Validator** | Implement real `check_adjacency_rules()` when crop rotation rules arrive |

---

## ✔️ Quick Sanity Checklist

### Tilling/Watering/Planting/Harvesting
- ✅ Tile color changes immediately
- ✅ Only the affected chunk flashes

### Expanding grid (e.g., 20×20)
- ✅ Fence and visual layers update
- ✅ Validator allows (19,19) and rejects (20,20)

### Serialization
- ✅ Roundtrip retains tile count and states

### Debug overlay
- ✅ Fence outline draws
- ✅ Hover shows tile under cursor



res://
├── scenes/
│   ├── game/
│   │   └── GridSystem.tscn
│   ├── debug/
│   │   └── GridDebugOverlay.tscn
│   └── visual/
│       ├── TileMapRenderer.tscn
│       └── ChunkRenderer.tscn
│
├── scripts/
│   ├── managers/
│   │   ├── GridValidator.gd    # Autoload #1
│   │   └── GridManager.gd      # Autoload #2
│   │
│   ├── grid/
│   │   ├── FarmTileData.gd     # Resource class
│   │   ├── TileUpdate.gd       # Update request class
│   │   ├── ChunkManager.gd     # Chunk operations
│   │   ├── ChunkRenderer.gd    # Visual rendering
│   │   └── GridHelpers.gd      # Static utilities
│   │
│   ├── chemistry/
│   │   ├── SoilChemistry.gd    # Chemistry calculations
│   │   ├── NPKManager.gd       # Nutrient system
│   │   ├── PHManager.gd        # pH calculations
│   │   ├── WaterManager.gd     # Water/moisture
│   │   └── ContaminationManager.gd
│   │
│   └── fence/
│       ├── FenceSystem.gd      # Fence mechanics
│       ├── FenceValidator.gd   # Boundary checks
│       └── ExpansionManager.gd # Land purchases
│
├── resources/
│   ├── tiles/
│   │   ├── default_tile.tres   # Base FarmTileData
│   │   ├── fertile_tile.tres   # High quality preset
│   │   └── poor_tile.tres      # Low quality preset
│   │
│   └── chemistry/
│       ├── fertilizers/
│       │   ├── organic_fertilizer.tres
│       │   ├── nitrogen_boost.tres
│       │   └── lime_treatment.tres
│       └── presets/
│           ├── desert_soil.tres
│           ├── volcanic_soil.tres
│           └── tundra_soil.tres
│
└── assets/
    ├── textures/
    │   ├── tiles/
    │   │   ├── tile_empty.png
    │   │   ├── tile_tilled.png
    │   │   ├── tile_wet.png
    │   │   └── tile_fence.png
    │   └── overlays/
    │       ├── grid_lines.png
    │       ├── selection.png
    │       └── contamination.png
    └── shaders/
        ├── soil_quality.gdshader
        └── water_overlay.gdshader

flowchart TB
    subgraph GridCore ["🌍 GRID SYSTEM CORE"]
        subgraph GridManager ["Grid Manager (Autoload #2)"]
            GridData["GridManager.gd<br/>---<br/>PROPERTIES:<br/>• grid_size: Vector2i (10x10 to 100x100)<br/>• grid_data: Dictionary{Vector2i: FarmTileData}<br/>• dirty_chunks: Dictionary{Vector2i: bool}<br/>• fence_bounds: Rect2i<br/>• update_queue: Array[TileUpdate]<br/>---<br/>SIGNALS:<br/>• tile_changed(pos, tile)<br/>• grid_expanded(new_size)<br/>• chunk_dirty(chunk_pos)"]
            
            GridValidator["GridValidator.gd (Autoload #1)<br/>---<br/>VALIDATION:<br/>• is_valid_position(pos) → bool<br/>• is_fenced(pos) → bool<br/>• can_place_at(pos, size) → bool<br/>• get_area_tiles(pos, size) → Array<br/>• check_adjacency_rules(pos, type) → bool"]
        end

        subgraph TileData ["Tile Data Structure"]
            FarmTile["FarmTileData.gd (Resource)<br/>---<br/>IDENTITY:<br/>• position: Vector2i<br/>• chunk_id: Vector2i<br/>• state: TileState<br/>• is_fenced: bool<br/>• grid_index: int"]
            
            TileState["TILE STATES:<br/>• EMPTY (default)<br/>• TILLED<br/>• PLANTED<br/>• WATERED<br/>• BLOCKED (machine/building)<br/>• PATH<br/>• FENCE"]
            
            TileChemistry["SOIL CHEMISTRY:<br/>• nitrogen: float (0-100)<br/>• phosphorus: float (0-100)<br/>• potassium: float (0-100)<br/>• ph_level: float (3.0-9.0)<br/>• water_content: float (0-100)<br/>• organic_matter: float (0-100)<br/>• fertilizer_type: String"]
            
            TileHistory["TILE HISTORY:<br/>• previous_crops: Array[String] (last 3)<br/>• last_harvest_quality: int<br/>• same_crop_count: int<br/>• fallow_days: int<br/>• total_harvests: int<br/>• contamination_level: float"]
        end
    end

    subgraph CoordinateSystems ["📐 COORDINATE SYSTEMS"]
        WorldCoords["WORLD COORDINATES:<br/>• Pixel-based (1920x1080)<br/>• Origin: top-left<br/>• For rendering"]
        
        GridCoords["GRID COORDINATES:<br/>• Tile-based (Vector2i)<br/>• Origin: (0,0)<br/>• For logic"]
        
        ChunkCoords["CHUNK COORDINATES:<br/>• 10x10 tile groups<br/>• For optimization<br/>• Batch rendering"]
        
        Conversions["CONVERSIONS:<br/>• world_to_grid(Vector2) → Vector2i<br/>• grid_to_world(Vector2i) → Vector2<br/>• grid_to_chunk(Vector2i) → Vector2i<br/>• get_neighbors(Vector2i, diagonal) → Array"]
    end

    subgraph UpdatePipeline ["🔄 UPDATE PIPELINE"]
        UpdatePriorities["UPDATE PRIORITIES:<br/>---<br/>IMMEDIATE (0ms):<br/>• State changes<br/>• Machine placement<br/>• Fence updates<br/>---<br/>FAST (next frame):<br/>• Water changes<br/>• Visual updates<br/>---<br/>PERIODIC (1 sec):<br/>• NPK depletion<br/>• pH drift<br/>• Evaporation<br/>---<br/>SLOW (1 min):<br/>• Organic matter<br/>• Contamination"]
        
        BatchSystem["BATCH PROCESSING:<br/>• Collect updates per frame<br/>• Group by chunk<br/>• Sort by priority<br/>• Execute in order<br/>• Single render pass"]
        
        DirtyTracking["DIRTY TRACKING:<br/>• Mark modified chunks<br/>• Queue for rendering<br/>• Network sync flags<br/>• Save flags"]
    end

    subgraph ChemistrySystem ["🧪 SOIL CHEMISTRY ENGINE"]
        NPKSystem["NPK MANAGEMENT:<br/>• Depletion per crop type<br/>• Fertilizer application<br/>• Natural regeneration<br/>• Crop rotation bonus<br/>• Deficiency penalties"]
        
        PHBalance["PH BALANCE:<br/>• Acid rain events (-0.5)<br/>• Lime application (+1.0)<br/>• Natural drift to 7.0<br/>• Crop preferences<br/>• Quality impact"]
        
        WaterSystem["WATER SYSTEM:<br/>• Evaporation rate<br/>• Saturation point<br/>• Drought stress<br/>• Overwater damage<br/>• Moisture retention"]
        
        Contamination["CONTAMINATION:<br/>• Chemical runoff<br/>• Disease spread<br/>• Quarantine zones<br/>• Cleanup methods<br/>• Prevention buffers"]
    end

    subgraph RenderingSystem ["🎨 RENDERING SYSTEM"]
        TileMapLayers["TILEMAP LAYERS:<br/>0: Base terrain<br/>1: Tilled overlay<br/>2: Moisture<br/>3: Grid lines<br/>4: Fence<br/>5: Selection<br/>6: Debug info"]
        
        ChunkRenderer["ChunkRenderer.gd<br/>• Renders 10x10 chunks<br/>• Culls off-screen<br/>• Batches draw calls<br/>• LOD system<br/>• Update only dirty"]
        
        VisualIndicators["VISUAL INDICATORS:<br/>• Soil quality (color)<br/>• Water level (darkness)<br/>• NPK bars (debug)<br/>• pH color shift<br/>• Contamination fog"]
    end

    subgraph FenceSystem ["🚧 FENCE SYSTEM"]
        FenceMechanics["FENCE RULES:<br/>• 10x10 starting area<br/>• Must be continuous<br/>• Cannot be moved<br/>• Blocks outsiders<br/>• Gate for entry"]
        
        Expansion["EXPANSION:<br/>• Buy adjacent plots<br/>• $1000 per 10x10<br/>• Auto-extends fence<br/>• Maximum 100x100<br/>• Permanent purchase"]
        
        FenceValidation["VALIDATION:<br/>• Check continuity<br/>• Verify ownership<br/>• Block invalid placements<br/>• Update pathfinding<br/>• Sync multiplayer"]
    end

    subgraph Optimization ["⚡ OPTIMIZATION"]
        MemoryManagement["MEMORY (100x100 grid):<br/>• ~10KB per tile<br/>• ~100MB total<br/>• Chunk streaming<br/>• Compress defaults<br/>• Pool tile objects"]
        
        PerformanceTargets["PERFORMANCE:<br/>• 60 FPS target<br/>• <2ms update time<br/>• <5ms render time<br/>• Batch operations<br/>• Multithread chemistry"]
        
        NetworkOptimization["NETWORK:<br/>• Delta compression<br/>• Chunk-based sync<br/>• Priority by distance<br/>• Throttle updates<br/>• Reliable for state"]
    end

    %% Connections
    GridData --> FarmTile
    FarmTile --> TileState & TileChemistry & TileHistory
    
    WorldCoords <--> GridCoords <--> ChunkCoords
    GridCoords --> Conversions
    
    UpdatePriorities --> BatchSystem --> DirtyTracking
    
    NPKSystem & PHBalance & WaterSystem & Contamination --> TileChemistry
    
    TileMapLayers --> ChunkRenderer --> VisualIndicators
    
    FenceMechanics --> Expansion --> FenceValidation
    
    MemoryManagement --> PerformanceTargets --> NetworkOptimization
	
Implementation Priority:

GridValidator.gd - Must be first autoload, validates everything
GridManager.gd - Core grid operations
FarmTileData.gd - Data structure
ChunkManager.gd - Performance optimization
SoilChemistry.gd - Chemistry calculations
FenceSystem.gd - Boundary management
ChunkRenderer.gd - Visual representation

Key Implementation Notes:

Grid starts at 10x10, expands to 100x100 max
Fence is permanent boundary, cannot be moved
Chemistry updates in batches for performance
Chunks are 10x10 tiles for optimization
All positions use Vector2i for grid coordinates
Autoload order critical: Validator MUST be first

---

Implementation Decisions and Updates (Agreed)

- Autoload Order (clarification):
  - GameManager = Autoload #1 (global orchestrator)
  - GridValidator = Autoload #2 (validates everything)
  - GridManager = Autoload #3 (core grid operations)
  - Note: Any references in this file to GridValidator as “Autoload #1” and GridManager as “Autoload #2” should be read as #2 and #3 respectively.

- FarmTile as Resource:
  - Use `res://scripts/grid/FarmTileData.gd` (Resource) for each tile.
  - Remove any inner tile class usage in GridManager; store and serialize tiles via Resource instances.
  - Include identity, chemistry, and history fields as outlined in this document; chemistry calculations are stubbed initially.

- GridManager Defaults and Signals:
  - Constants: `DEFAULT_GRID_SIZE = Vector2i(10, 10)`, `MAX_GRID_SIZE = Vector2i(100, 100)`, `CHUNK_SIZE = 10`.
  - Signals: ensure these exist and are emitted appropriately:
    - `tile_changed(pos: Vector2i, tile)`
    - `grid_expanded(new_size: Vector2i)`
    - `chunk_dirty(chunk_pos: Vector2i)`
  - Dirty structures:
    - `dirty_chunks: Dictionary` mapping `Vector2i -> bool` (mark-only approach for now)
    - `update_queue: Array[TileUpdate]` for batched updates
  - Fence bounds: `fence_bounds: Rect2i = Rect2i(Vector2i.ZERO, DEFAULT_GRID_SIZE)` maintained by GridManager.
  - Expansion API:
    - `expand_grid(new_size: Vector2i) -> void` should cap to `MAX_GRID_SIZE`, update `grid_size`, update `fence_bounds`, call `GridValidator.set_grid_size(new_size)`, and emit `grid_expanded(new_size)`.
  - Backward‑compatible gameplay API: keep `till_soil`, `plant_crop`, `water_tile`, `harvest_crop` public APIs; update internals to work with `FarmTileData`.

- Chunking:
  - Use 10x10 tile chunks (`CHUNK_SIZE = 10`).
  - Add helpers to compute chunk coordinates from grid positions and mark chunks dirty whenever a tile changes.
  - No multithreaded chemistry yet; focus on correct dirty tracking and batch processing plumbing.

- GridValidator APIs (additions with safe defaults):
  - `is_fenced(pos: Vector2i) -> bool`
    - Returns whether a position lies within the current `fence_bounds` managed by GridManager (stub allowed initially).
  - `can_place_at(pos: Vector2i, size: Vector2i) -> bool`
    - Returns false if any tile in `get_area_tiles(pos, size)` is invalid; true otherwise.
  - `get_area_tiles(pos: Vector2i, size: Vector2i) -> Array[Vector2i]`
    - Returns the list of tiles covering the rectangular area from `pos` with `size` width/height.
  - `check_adjacency_rules(pos: Vector2i, type: String) -> bool`
    - Stub for crop rotation / adjacency rules; return true for now.

- Chemistry (stub first):
  - Create `SoilChemistry.gd` with function placeholders; wire fields on `FarmTileData` but defer heavy calculations.

- Visuals (defer):
  - Defer `TileMapRenderer.tscn` and `ChunkRenderer.tscn` integration until the data layer and dirty chunk signaling are verified.

- Testing:
  - Existing `Z_test.gd` interactions (till/plant/water/harvest) remain valid and should continue to work.
