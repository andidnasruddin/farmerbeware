flowchart LR
    subgraph Implementation ["🔧 IMPLEMENTATION STRUCTURE"]
        ToolAction["ToolActionPipeline.gd:<br/>---<br/>var action_buffer: Array<br/>var current_action: Action<br/>var rollback_stack: Array<br/>---<br/>func queue_action(action)<br/>func process_action_queue()<br/>func execute_action(action)<br/>func rollback_action()"]
        
        ToolHandlers["ToolHandlers.gd:<br/>---<br/>func handle_hoe(tile, player)<br/>func handle_seeds(tile, player)<br/>func handle_water(tile, player)<br/>func handle_harvest(tile, player)<br/>func handle_fertilizer(tile, player)"]
        
        ActionValidator["ActionValidator.gd:<br/>---<br/>func can_perform(action) -> bool<br/>func check_resources(action) -> bool<br/>func check_permissions(action) -> bool<br/>func check_grid_state(action) -> bool"]
        
        FeedbackManager["FeedbackManager.gd:<br/>---<br/>func show_preview(tiles, valid)<br/>func play_action_sound(action)<br/>func spawn_particles(action)<br/>func update_ui(action)"]
    end

    ToolAction --> ActionValidator
    ActionValidator --> ToolHandlers
    ToolHandlers --> FeedbackManager
    FeedbackManager --> ToolAction
	
flowchart TB
    subgraph InputLayer ["🎮 INPUT CAPTURE LAYER"]
        subgraph InputSources ["Input Sources"]
            KeyPress["KEYBOARD/GAMEPAD:<br/>• E key (action)<br/>• 1-5 (tool select)<br/>• Shift (modifier)<br/>• Tab (inspect mode)"]
            
            MouseInput["MOUSE INPUT:<br/>• Right click (throw)<br/>• Hover (preview)<br/>• Wheel (tool cycle)"]
            
            NetworkInput["NETWORK RPC:<br/>• Remote player action<br/>• Validated by host<br/>• Includes timestamp"]
        end

        subgraph InputBuffer ["Input Buffering"]
            BufferQueue["ACTION BUFFER:<br/>• Size: 3 actions<br/>• FIFO processing<br/>• 100ms window<br/>• Clear on success"]
            
            InputValidation["EARLY VALIDATION:<br/>• Is key mapped?<br/>• Is action allowed?<br/>• In correct state?<br/>• Not in cooldown?"]
            
            CooldownSystem["COOLDOWNS:<br/>• Global: 0.2s<br/>• Per tool varies<br/>• Network buffer: 0.1s<br/>• Animation lock"]
        end
    end

    subgraph ToolRouting ["🔧 TOOL ROUTING LAYER"]
        subgraph ToolRegistry ["Tool Registry"]
            ToolTypes["REGISTERED TOOLS:<br/>---<br/>HOE: Till soil<br/>WATERING_CAN: Add water<br/>SEED_BAG: Plant crop<br/>HARVESTER: Collect crop<br/>FERTILIZER: Add NPK<br/>NONE: Interact only"]
            
            ToolProperties["TOOL PROPERTIES:<br/>• action_time: float<br/>• range: int (tiles)<br/>• area: Vector2i<br/>• uses_remaining: int<br/>• quality_bonus: float"]
            
            ToolState["TOOL STATE:<br/>• current_tool: Tool<br/>• tool_level: int<br/>• is_upgraded: bool<br/>• animation_playing: bool"]
        end

        subgraph ActionResolver ["Action Resolution"]
            ActionType["DETERMINE ACTION:<br/>1. Check current tool<br/>2. Get target tile<br/>3. Check tile state<br/>4. Find valid action<br/>5. Route to handler"]
            
            TargetCalculation["TARGET CALCULATION:<br/>• Player position<br/>• Facing direction<br/>• Tool range<br/>• Area of effect<br/>• Grid alignment"]
            
            HandlerMap["ACTION HANDLERS:<br/>Tool + State = Handler<br/>---<br/>Hoe + Empty → till_soil()<br/>Hoe + Tilled → nothing<br/>Seeds + Tilled → plant_crop()<br/>Water + Any → water_tile()<br/>Harvest + Ready → harvest_crop()"]
        end
    end

    subgraph ExecutionLayer ["⚡ EXECUTION LAYER"]
        subgraph PreExecution ["Pre-Execution Checks"]
            PermissionCheck["PERMISSIONS:<br/>• Correct game phase?<br/>• Player has authority?<br/>• Not blocked by other?<br/>• Resources available?"]
            
            ResourceCheck["RESOURCE CHECK:<br/>• Seeds in inventory?<br/>• Water in can?<br/>• Fertilizer count?<br/>• Money for action?"]
            
            GridValidation["GRID VALIDATION:<br/>• Tile exists?<br/>• Not fenced?<br/>• State compatible?<br/>• No conflicts?"]
        end

        subgraph Execution ["Action Execution"]
            BeginAction["BEGIN ACTION:<br/>• Lock player input<br/>• Start animation<br/>• Play sound<br/>• Show particles"]
            
            ModifyState["MODIFY STATE:<br/>• Update tile data<br/>• Consume resources<br/>• Apply effects<br/>• Log changes"]
            
            CompleteAction["COMPLETE ACTION:<br/>• Unlock input<br/>• Emit signals<br/>• Update UI<br/>• Network sync"]
        end

        subgraph Rollback ["Rollback System"]
            RollbackTriggers["ROLLBACK TRIGGERS:<br/>• Network reject<br/>• Validation fail<br/>• State conflict<br/>• Resource missing"]
            
            RollbackProcess["ROLLBACK PROCESS:<br/>1. Stop animation<br/>2. Restore state<br/>3. Refund resources<br/>4. Show error<br/>5. Clear buffers"]
        end
    end

    subgraph FeedbackLayer ["🎨 FEEDBACK LAYER"]
        subgraph VisualFeedback ["Visual Feedback"]
            PreviewSystem["PREVIEW (Pre-action):<br/>• Grid highlight<br/>• Green = valid<br/>• Red = invalid<br/>• Area outline<br/>• Ghost tile"]
            
            ActionVisuals["ACTION VISUALS:<br/>• Tool animation<br/>• Tile transformation<br/>• Particle effects<br/>• UI updates<br/>• Progress bars"]
            
            ResultVisuals["RESULT VISUALS:<br/>• Success particles<br/>• Quality stars<br/>• Number popups<br/>• State change<br/>• Completion flash"]
        end

        subgraph AudioFeedback ["Audio Feedback"]
            SoundLayers["SOUND LAYERS:<br/>• Tool swing (start)<br/>• Impact (contact)<br/>• Process (during)<br/>• Success (complete)<br/>• Error (fail)"]
            
            SoundVariation["VARIATIONS:<br/>• Random pitch (±10%)<br/>• Volume by distance<br/>• Material-based<br/>• Quality-based<br/>• Upgrade sounds"]
        end
    end

    subgraph NetworkLayer ["🌐 NETWORK SYNC LAYER"]
        subgraph LocalPrediction ["Client Prediction"]
            PredictAction["PREDICT LOCALLY:<br/>• Show immediate feedback<br/>• Update visual state<br/>• Queue for confirmation<br/>• Continue playing"]
            
            ConfirmAction["AWAIT CONFIRMATION:<br/>• Send RPC to host<br/>• Include timestamp<br/>• Wait for response<br/>• Max 250ms timeout"]
            
            Reconciliation["RECONCILIATION:<br/>• Host validates<br/>• Send result to all<br/>• Correct if wrong<br/>• Smooth interpolation"]
        end

        subgraph HostValidation ["Host Validation"]
            ValidateRequest["VALIDATE REQUEST:<br/>• Check timestamp<br/>• Verify resources<br/>• Test grid state<br/>• Apply if valid"]
            
            BroadcastResult["BROADCAST RESULT:<br/>• Send to all clients<br/>• Include final state<br/>• Reliable RPC<br/>• Order guaranteed"]
        end
    end

    subgraph SpecialCases ["⚠️ SPECIAL CASES"]
        AreaTools["AREA EFFECT TOOLS:<br/>• Calculate all tiles<br/>• Validate each<br/>• Batch execute<br/>• Single network sync<br/>• Grouped feedback"]
        
        ChainActions["CHAIN ACTIONS:<br/>• Queue allowed<br/>• Same tool only<br/>• 3 action max<br/>• Cancel on error<br/>• Batch network"]
        
        CoopActions["COOP ACTIONS:<br/>• Two-player lift<br/>• Synchronized start<br/>• Both must confirm<br/>• Shared cooldown<br/>• Split feedback"]
    end

    %% Flow connections
    KeyPress --> BufferQueue
    MouseInput --> BufferQueue
    NetworkInput --> BufferQueue
    
    BufferQueue --> InputValidation --> CooldownSystem
    
    CooldownSystem --> ActionType
    ActionType --> TargetCalculation --> HandlerMap
    
    HandlerMap --> PermissionCheck
    PermissionCheck --> ResourceCheck --> GridValidation
    
    GridValidation --> BeginAction
    BeginAction --> ModifyState --> CompleteAction
    
    ModifyState --> RollbackTriggers
    RollbackTriggers --> RollbackProcess
    
    BeginAction --> PreviewSystem & ActionVisuals & SoundLayers
    CompleteAction --> ResultVisuals
    
    CompleteAction --> PredictAction
    PredictAction --> ConfirmAction --> Reconciliation
    
    ConfirmAction --> ValidateRequest
    ValidateRequest --> BroadcastResult
    BroadcastResult --> Reconciliation
	
