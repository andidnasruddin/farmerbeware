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