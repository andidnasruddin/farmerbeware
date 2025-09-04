flowchart LR
    subgraph CodeStructure ["🔧 CODE IMPLEMENTATION"]
        TileClass["FarmTileData.gd:<br/>---<br/>signal value_changed(property, old, new)<br/>signal state_changed(old_state, new_state)<br/>---<br/>func set_nitrogen(value: float)<br/>func apply_fertilizer(n, p, k)<br/>func update_chemistry(delta)<br/>func can_plant() -> bool"]
        
        GridManager["GridManager.gd:<br/>---<br/>var grid_data: Dictionary<br/>var dirty_tiles: Array<br/>var update_queue: Array<br/>---<br/>func update_tile(pos, property, value)<br/>func batch_update_tiles()<br/>func process_chemistry_tick()"]
        
        UpdateManager["TileUpdateManager.gd:<br/>---<br/>var immediate_queue: Array<br/>var deferred_queue: Array<br/>var periodic_timers: Dictionary<br/>---<br/>func queue_update(tile, priority)<br/>func process_updates(delta)<br/>func validate_update(tile, change)"]
    end

    TileClass --> UpdateManager
    UpdateManager --> GridManager
    GridManager --> TileClass
	
flowchart TB
    subgraph TileDataStructure ["📦 TILE DATA STRUCTURE"]
        subgraph CoreData ["Core Tile Properties"]
            TileInstance["FarmTileData Instance<br/>---<br/>IDENTITY:<br/>• position: Vector2i<br/>• state: TileState<br/>• is_fenced: bool<br/>• biome_type: String"]
            
            ChemistryData["CHEMISTRY DATA:<br/>• nitrogen: float (0-100)<br/>• phosphorus: float (0-100)<br/>• potassium: float (0-100)<br/>• ph_level: float (3.0-9.0)<br/>• water_content: float (0-100)<br/>• organic_matter: float (0-100)"]
            
            CropReference["CROP REFERENCE:<br/>• has_crop: bool<br/>• crop_node: Node<br/>• crop_id: String<br/>• plant_time: float<br/>• fertilizer_type: String"]
            
            HistoryData["HISTORY DATA:<br/>• previous_crops: Array[3]<br/>• same_crop_count: int<br/>• last_harvest_time: float<br/>• fallow_days: int<br/>• total_harvests: int"]
        end

        subgraph UpdateOrder ["🔄 UPDATE PRIORITY ORDER"]
            Priority1["1️⃣ IMMEDIATE (0ms):<br/>• State changes (till/plant)<br/>• Machine placement<br/>• Fence updates"]
            
            Priority2["2️⃣ FAST (next frame):<br/>• Water changes<br/>• Visual updates<br/>• Player feedback"]
            
            Priority3["3️⃣ PERIODIC (per second):<br/>• NPK depletion<br/>• Water evaporation<br/>• pH drift"]
            
            Priority4["4️⃣ SLOW (per minute):<br/>• Organic matter<br/>• Soil compaction<br/>• History updates"]
        end
    end

    subgraph DataFlow ["📊 DATA UPDATE FLOW"]
        subgraph InputSources ["Input Sources"]
            PlayerAction["PLAYER ACTIONS:<br/>• Till (state change)<br/>• Plant (crop ref)<br/>• Water (+25 water)<br/>• Fertilize (+NPK)<br/>• Harvest (clear crop)"]
            
            SystemUpdates["SYSTEM UPDATES:<br/>• Time tick (depletion)<br/>• Weather (water/pH)<br/>• Events (disasters)<br/>• Crop consumption"]
            
            NetworkUpdates["NETWORK SYNC:<br/>• Host broadcasts<br/>• State corrections<br/>• Batch updates"]
        end

        subgraph ValidationLayer ["✅ VALIDATION LAYER"]
            PreValidation["PRE-VALIDATION:<br/>• Is position valid?<br/>• Is action allowed?<br/>• Has permission?<br/>• In correct phase?"]
            
            ValueClamping["VALUE CLAMPING:<br/>• NPK: clamp(0, 100)<br/>• pH: clamp(3.0, 9.0)<br/>• Water: clamp(0, 100)<br/>• Never negative<br/>• Never overflow"]
            
            StateConsistency["STATE CONSISTENCY:<br/>• Can't plant if not tilled<br/>• Can't till if has crop<br/>• Can't water if blocked<br/>• Machine blocks all"]
        end

        subgraph ProcessingPipeline ["⚙️ PROCESSING PIPELINE"]
            Step1["STEP 1: Receive Change<br/>• Source identified<br/>• Change type logged<br/>• Old value stored"]
            
            Step2["STEP 2: Validate<br/>• Check permissions<br/>• Verify ranges<br/>• Test state rules"]
            
            Step3["STEP 3: Calculate<br/>• Apply formulas<br/>• Consider modifiers<br/>• Combine effects"]
            
            Step4["STEP 4: Apply<br/>• Update values<br/>• Set dirty flag<br/>• Queue renders"]
            
            Step5["STEP 5: Propagate<br/>• Emit signals<br/>• Trigger renders<br/>• Network sync"]
        end
    end

    subgraph RenderPipeline ["🎨 RENDER UPDATE PIPELINE"]
        DirtyFlags["DIRTY FLAGS:<br/>• visual_dirty: bool<br/>• network_dirty: bool<br/>• save_dirty: bool<br/>• last_update: float"]
        
        BatchingSystem["BATCHING SYSTEM:<br/>• Collect changes/frame<br/>• Group by chunk (10x10)<br/>• Single render call<br/>• Reduce draw calls"]
        
        VisualLayers["VISUAL UPDATE LAYERS:<br/>1. Base tile (soil type)<br/>2. State overlay (tilled)<br/>3. Moisture (dark/crack)<br/>4. Quality indicators<br/>5. Debug info (F3)"]
        
        LODSystem["LOD SYSTEM:<br/>• Close: All details<br/>• Medium: State only<br/>• Far: Base only<br/>• Off-screen: Skip"]
    end

    subgraph NetworkSync ["🌐 NETWORK SYNCHRONIZATION"]
        SyncStrategy["SYNC STRATEGY:<br/>• State: Reliable, instant<br/>• Chemistry: Batch per second<br/>• History: On change only<br/>• Visual: Local predict"]
        
        ConflictResolution["CONFLICT RESOLUTION:<br/>• Host always wins<br/>• Client predicts<br/>• Rollback on conflict<br/>• Log discrepancies"]
        
        BandwidthOptimize["BANDWIDTH OPTIMIZATION:<br/>• Delta compression<br/>• Only send changes<br/>• Chunk updates (10x10)<br/>• Priority by distance"]
    end

    subgraph MemoryOptimization ["💾 MEMORY OPTIMIZATION"]
        DataPacking["DATA PACKING:<br/>• Pack bools into flags<br/>• Use int8 for small values<br/>• Compress floats<br/>• Pool identical tiles"]
        
        ChunkSystem["CHUNK SYSTEM (10x10):<br/>• Load nearby chunks<br/>• Unload distant chunks<br/>• Stream on demand<br/>• Cache frequent"]
        
        MemoryLimits["MEMORY LIMITS:<br/>• 100x100 max grid<br/>• ~10KB per tile<br/>• ~100MB total<br/>• Swap to disk if needed"]
    end

    subgraph SaveSerialization ["💾 SAVE SERIALIZATION"]
        SaveFormat["SAVE FORMAT:<br/>• Skip default values<br/>• Compress sequences<br/>• Dictionary format<br/>• Version tagged"]
        
        SaveData["WHAT TO SAVE:<br/>• Non-default states<br/>• All chemistry<br/>• Crop references<br/>• Full history<br/>• Timestamps"]
        
        LoadProcess["LOAD PROCESS:<br/>1. Create default grid<br/>2. Apply saved changes<br/>3. Validate integrity<br/>4. Reconstruct refs<br/>5. Trigger renders"]
    end

    %% Flow connections
    PlayerAction --> PreValidation
    SystemUpdates --> PreValidation
    NetworkUpdates --> PreValidation
    
    PreValidation --> ValueClamping --> StateConsistency
    
    StateConsistency --> Step1 --> Step2 --> Step3 --> Step4 --> Step5
    
    Step5 --> DirtyFlags
    DirtyFlags --> BatchingSystem
    BatchingSystem --> VisualLayers
    VisualLayers --> LODSystem
    
    Step5 --> SyncStrategy
    SyncStrategy --> ConflictResolution
    ConflictResolution --> BandwidthOptimize
    
    TileInstance --> ChemistryData
    ChemistryData --> CropReference
    CropReference --> HistoryData
    
    Priority1 --> Priority2 --> Priority3 --> Priority4
    
    DataPacking --> ChunkSystem --> MemoryLimits
    SaveFormat --> SaveData --> LoadProcess