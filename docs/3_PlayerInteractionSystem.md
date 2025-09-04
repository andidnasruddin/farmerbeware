res://
├── scenes/
│   ├── player/
│   │   ├── Player.tscn          # Main player scene
│   │   ├── PlayerVisuals.tscn   # Sprite components
│   │   ├── ToolDisplay.tscn     # Tool visualization
│   │   └── CarryPosition.tscn   # Item hold point
│   │
│   ├── tools/
│   │   ├── ToolPreview.tscn     # Grid preview
│   │   └── ToolEffects.tscn     # Particles
│   │
│   └── ui/
│       ├── StaminaBar.tscn
│       ├── ToolSelector.tscn
│       └── EmoteWheel.tscn
│
├── scripts/
│   ├── managers/
│   │   └── InteractionSystem.gd  # Autoload #3
│   │
│   ├── player/
│   │   ├── PlayerController.gd   # Main controller
│   │   ├── PlayerMovement.gd     # Physics
│   │   ├── PlayerInventory.gd    # Items/tools
│   │   ├── PlayerNetwork.gd      # Multiplayer
│   │   └── PlayerAnimator.gd     # Visuals
│   │
│   ├── interaction/
│   │   ├── ActionValidator.gd    # Permission checks
│   │   ├── ActionHandlers.gd     # Tool implementations
│   │   ├── TargetCalculator.gd   # Grid targeting
│   │   └── InteractionQueue.gd   # Input buffer
│   │
│   ├── tools/
│   │   ├── Tool.gd               # Base tool class
│   │   ├── ToolHoe.gd           # Till soil
│   │   ├── ToolWateringCan.gd   # Water tiles
│   │   ├── ToolSeedBag.gd       # Plant crops
│   │   ├── ToolHarvester.gd     # Collect crops
│   │   ├── ToolFertilizer.gd    # Apply NPK
│   │   └── ToolSoilTest.gd      # Check chemistry
│   │
│   └── carry/
│       ├── CarrySystem.gd        # Pickup/drop
│       ├── ThrowPhysics.gd       # Throwing
│       └── Item.gd               # Base item class
│
├── resources/
│   ├── tools/
│   │   ├── hoe_bronze.tres
│   │   ├── hoe_silver.tres
│   │   ├── hoe_gold.tres
│   │   ├── watering_can_basic.tres
│   │   ├── seed_bag.tres
│   │   └── harvester.tres
│   │
│   └── player/
│       ├── player_stats.tres     # Default stats
│       └── movement_config.tres  # Physics settings
│
└── assets/
    ├── sprites/
    │   ├── player/
    │   │   ├── farmer_idle_*.png  # 8 directions
    │   │   ├── farmer_walk_*.png
    │   │   ├── farmer_run_*.png
    │   │   ├── farmer_carry_*.png
    │   │   └── farmer_tool_*.png
    │   │
    │   ├── tools/
    │   │   ├── hoe_icon.png
    │   │   ├── water_can.png
    │   │   └── [other tools].png
    │   │
    │   └── effects/
    │       ├── dirt_particles.png
    │       ├── water_drops.png
    │       └── sweat_drops.png
    │
    └── sounds/
        ├── footsteps/
        │   ├── grass_walk.ogg
        │   ├── dirt_walk.ogg
        │   └── stone_walk.ogg
        │
        └── tools/
            ├── hoe_till.ogg
            ├── water_pour.ogg
            ├── plant_seed.ogg
            └── harvest_crop.ogg

flowchart TB
    subgraph PlayerCore ["👤 PLAYER SYSTEM CORE"]
        subgraph PlayerController ["Player Controller"]
            PlayerData["PlayerController.gd<br/>---<br/>PROPERTIES:<br/>• player_id: int (1-4)<br/>• player_name: String<br/>• position: Vector2<br/>• facing_direction: Vector2<br/>• current_tool: Tool<br/>• carried_item: Item<br/>• move_speed: float (300.0)<br/>• stamina: float (100.0)<br/>---<br/>SIGNALS:<br/>• tool_changed(tool)<br/>• item_picked_up(item)<br/>• action_performed(action, pos)"]
            
            PlayerStates["PLAYER STATES:<br/>• IDLE<br/>• MOVING<br/>• SPRINTING<br/>• CARRYING<br/>• USING_TOOL<br/>• IN_MINIGAME<br/>• THROWING"]
        end

        subgraph ToolSystem ["Tool System"]
            ToolRegistry["TOOL TYPES:<br/>---<br/>HOE: Till soil (1 tile)<br/>WATERING_CAN: Water (3x1 area)<br/>SEED_BAG: Plant crops<br/>HARVESTER: Collect crops<br/>FERTILIZER: Apply NPK<br/>SOIL_TEST: Check chemistry<br/>NONE: Interact only"]
            
            ToolProperties["Tool.gd (Resource)<br/>---<br/>• tool_name: String<br/>• action_time: float<br/>• range: int (tiles)<br/>• area: Vector2i<br/>• stamina_cost: float<br/>• level: int (1-3)<br/>• animation: String"]
            
            ToolUpgrades["UPGRADES (Innovation):<br/>• Bronze → Silver → Gold<br/>• Increased area<br/>• Reduced stamina<br/>• Faster action<br/>• Special effects"]
        end
    end

    subgraph InteractionSystem ["⚡ INTERACTION SYSTEM (Autoload #3)"]
        InteractionCore["InteractionSystem.gd<br/>---<br/>MANAGES:<br/>• Input routing<br/>• Tool actions<br/>• Object interactions<br/>• Validation pipeline<br/>• Network requests<br/>---<br/>SIGNALS:<br/>• action_requested(player, action)<br/>• action_validated(action)<br/>• action_completed(result)"]
        
        ActionPipeline["ACTION PIPELINE:<br/>1. Input capture (E key)<br/>2. Determine action type<br/>3. Calculate target<br/>4. Validate permissions<br/>5. Check resources<br/>6. Execute locally<br/>7. Network sync<br/>8. Apply feedback"]
        
        InteractionTargets["INTERACTION TARGETS:<br/>• Tiles (tool actions)<br/>• Machines (processing)<br/>• Computer (contracts)<br/>• Delivery Box (submit)<br/>• Other Players (co-op)<br/>• NPCs (dialogue)<br/>• Items (pickup)"]
    end

    subgraph MovementSystem ["🏃 MOVEMENT SYSTEM"]
        MovementPhysics["PHYSICS:<br/>• CharacterBody2D base<br/>• Collision shape: Capsule<br/>• Layer: PLAYER (2)<br/>• Acceleration: 2000<br/>• Friction: 2000<br/>• No diagonal speed boost"]
        
        SpeedModifiers["SPEED MODIFIERS:<br/>• Base: 300 px/sec<br/>• Sprint: 450 px/sec<br/>• Carrying: 150 px/sec<br/>• Heavy item: 100 px/sec<br/>• Path tiles: +25%<br/>• Mud: -33%"]
        
        StaminaSystem["STAMINA:<br/>• Max: 100<br/>• Sprint drain: 20/sec<br/>• Regen: 10/sec<br/>• Actions cost stamina<br/>• Empty = forced walk<br/>• Food restores"]
    end

    subgraph CarryThrowSystem ["📦 CARRY/THROW SYSTEM"]
        PickupMechanics["PICKUP RULES:<br/>• Range: 32 pixels<br/>• One item only<br/>• Auto-pickup option<br/>• Shows weight<br/>• Heavy = 2 players"]
        
        CarryPhysics["CARRY PHYSICS:<br/>• Item above head<br/>• Reduced speed<br/>• Can't use tools<br/>• Can throw<br/>• Drop on damage"]
        
        ThrowMechanics["THROW MECHANICS:<br/>• Right-click or Q<br/>• Force: 500 * direction<br/>• Arc trajectory<br/>• Damage on impact<br/>• Can hit players<br/>• Break fragile items"]
    end

    subgraph InputSystem ["🎮 INPUT HANDLING"]
        InputMapping["INPUT MAP:<br/>---<br/>MOVEMENT:<br/>• WASD / Arrows / Left Stick<br/>---<br/>ACTIONS:<br/>• E / Space: Primary<br/>• Q: Throw<br/>• Shift: Sprint<br/>• 1-7: Tool select<br/>• Tab: Inspect mode<br/>• F: Emote wheel"]
        
        InputBuffer["INPUT BUFFER:<br/>• 3 action queue<br/>• 100ms window<br/>• FIFO processing<br/>• Clear on success<br/>• Network prediction"]
        
        ControllerSupport["CONTROLLER:<br/>• Full gamepad support<br/>• Vibration feedback<br/>• Adaptive triggers (PS5)<br/>• Button prompts<br/>• Stick deadzone: 0.2"]
    end

    subgraph ToolActions ["🔧 TOOL ACTION HANDLERS"]
        TillAction["TILL (Hoe):<br/>• Target: EMPTY tile<br/>• Result: TILLED state<br/>• Time: 0.5 sec<br/>• Stamina: 5<br/>• Animation: 'till'<br/>• Sound: 'dirt_dig'"]
        
        WaterAction["WATER (Can):<br/>• Target: Any tile<br/>• Area: 3x1 (upgraded)<br/>• Water: +25 per tile<br/>• Uses: 5 → 0<br/>• Refill at water<br/>• Particle: droplets"]
        
        PlantAction["PLANT (Seeds):<br/>• Target: TILLED tile<br/>• Consume: 1 seed<br/>• Place crop node<br/>• Set growth timer<br/>• Track fertilizer<br/>• Play 'plant' sound"]
        
        HarvestAction["HARVEST (Tool):<br/>• Target: Ready crop<br/>• Check quality<br/>• Create item<br/>• Clear tile<br/>• Add to inventory<br/>• Particles: stars"]
    end

    subgraph NetworkSync ["🌐 MULTIPLAYER SYNC"]
        LocalPrediction["CLIENT PREDICTION:<br/>• Move immediately<br/>• Show tool preview<br/>• Play animations<br/>• Buffer inputs<br/>• Await confirmation"]
        
        AuthoritativeSync["HOST AUTHORITY:<br/>• Validate actions<br/>• Broadcast positions<br/>• Sync tool changes<br/>• Confirm pickups<br/>• Resolve conflicts"]
        
        PlayerRPCs["PLAYER RPCs:<br/>• update_position (unreliable)<br/>• sync_tool (reliable)<br/>• perform_action (reliable)<br/>• pickup_item (reliable)<br/>• throw_item (reliable)"]
    end

    subgraph VisualFeedback ["🎨 VISUAL FEEDBACK"]
        PlayerSprites["SPRITE SYSTEM:<br/>• 8-direction sprites<br/>• Tool overlays<br/>• Carry animations<br/>• Emote bubbles<br/>• Name tags<br/>• Status icons"]
        
        ActionPreviews["ACTION PREVIEW:<br/>• Grid highlight<br/>• Green = valid<br/>• Red = invalid<br/>• Area outline<br/>• Range indicator<br/>• Tool ghost"]
        
        ParticleEffects["PARTICLES:<br/>• Dirt (tilling)<br/>• Water drops<br/>• Sweat (stamina)<br/>• Stars (success)<br/>• Dust (running)<br/>• Steam (tired)"]
    end

    %% Connections
    PlayerData --> PlayerStates
    PlayerController --> ToolRegistry --> ToolProperties --> ToolUpgrades
    
    InteractionCore --> ActionPipeline --> InteractionTargets
    
    MovementPhysics --> SpeedModifiers --> StaminaSystem
    
    PickupMechanics --> CarryPhysics --> ThrowMechanics
    
    InputMapping --> InputBuffer --> ControllerSupport
    
    TillAction & WaterAction & PlantAction & HarvestAction --> InteractionCore
    
    LocalPrediction --> AuthoritativeSync --> PlayerRPCs
    
    PlayerSprites --> ActionPreviews --> ParticleEffects
	
Implementation Priority:

InteractionSystem.gd - Central routing (Autoload #3)
PlayerController.gd - Core player class
PlayerMovement.gd - Physics and input
Tool.gd - Base tool system
ActionHandlers.gd - Tool implementations
CarrySystem.gd - Pickup/throw
PlayerNetwork.gd - Multiplayer sync
PlayerAnimator.gd - Visual polish

Key Implementation Notes:

Players are CharacterBody2D for built-in physics
Tools are resources, not scenes (data-driven)
All actions go through InteractionSystem for validation
Input buffering prevents dropped inputs
Network uses client-prediction with host authority
Stamina limits sprint but not basic actions
Heavy items require 2 players (co-op mechanic)