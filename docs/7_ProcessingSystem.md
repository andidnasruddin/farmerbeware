res://
├── scenes/
│   ├── machines/
│   │   ├── base/
│   │   │   ├── Machine.tscn       # Base machine scene
│   │   │   ├── Hopper.tscn        # Hopper component
│   │   │   └── ConveyorBelt.tscn  # Belt segment
│   │   │
│   │   ├── processing/
│   │   │   ├── Thresher.tscn
│   │   │   ├── Oven.tscn
│   │   │   ├── Press.tscn
│   │   │   ├── Mill.tscn
│   │   │   ├── Cutter.tscn
│   │   │   └── Processor.tscn
│   │   │
│   │   └── visual/
│   │       ├── MachineEffects.tscn
│   │       └── ConveyorVisuals.tscn
│   │
│   ├── minigames/
│   │   ├── base/
│   │   │   └── MiniGameBase.tscn
│   │   │
│   │   ├── games/
│   │   │   ├── RhythmGame.tscn    # Thresher
│   │   │   ├── TemperatureGame.tscn # Oven
│   │   │   ├── MashingGame.tscn   # Press
│   │   │   ├── RotationGame.tscn  # Mill
│   │   │   └── PrecisionGame.tscn # Cutter
│   │   │
│   │   └── coop/
│   │       ├── DualCrank.tscn
│   │       └── TempBalance.tscn
│   │
│   └── ui/
│       ├── MachineUI.tscn         # Machine interface
│       ├── RepairMenu.tscn        # Computer repair
│       └── RecipeBook.tscn        # Discovered recipes
│
├── scripts/
│   ├── managers/
│   │   └── ProcessingManager.gd   # Autoload #9
│   │
│   ├── machines/
│   │   ├── Machine.gd             # Base machine class
│   │   ├── Thresher.gd
│   │   ├── Oven.gd
│   │   ├── Press.gd
│   │   ├── Mill.gd
│   │   ├── Cutter.gd
│   │   └── Processor.gd
│   │
│   ├── processing/
│   │   ├── Recipe.gd              # Recipe resource
│   │   ├── RecipeValidator.gd    # Recipe checking
│   │   ├── QualityCalculator.gd  # Quality math
│   │   ├── ProcessingQueue.gd    # Queue management
│   │   └── OutputGenerator.gd    # Create outputs
│   │
│   ├── minigames/
│   │   ├── MiniGame.gd           # Base minigame
│   │   ├── RhythmGame.gd
│   │   ├── TemperatureGame.gd
│   │   ├── MashingGame.gd
│   │   ├── RotationGame.gd
│   │   └── PrecisionGame.gd
│   │
│   ├── conveyor/
│   │   ├── HopperSystem.gd       # Hopper mechanics
│   │   ├── ConveyorBelt.gd       # Belt logic
│   │   ├── ItemTransport.gd      # Item movement
│   │   └── JamHandler.gd         # Jam clearing
│   │
│   ├── breakdown/
│   │   ├── BreakdownSystem.gd    # Breakdown logic
│   │   ├── RepairManager.gd      # Repair mechanics
│   │   └── MaintenanceTracker.gd # Maintenance
│   │
│   └── upgrades/
│       ├── MachineUpgrades.gd    # Upgrade system
│       └── RecipeDiscovery.gd    # Discovery tracking
│
├── resources/
│   ├── recipes/
│   │   ├── basic/
│   │   │   ├── wheat_flour.tres
│   │   │   ├── flour_bread.tres
│   │   │   ├── potato_fries.tres
│   │   │   └── apple_juice.tres
│   │   │
│   │   ├── advanced/
│   │   │   ├── pizza.tres
│   │   │   ├── cake.tres
│   │   │   ├── loaded_fries.tres
│   │   │   └── smoothie.tres
│   │   │
│   │   └── special/
│   │       └── secret_recipes.tres
│   │
│   ├── machines/
│   │   ├── configs/
│   │   │   ├── thresher_config.tres
│   │   │   ├── oven_config.tres
│   │   │   └── [others].tres
│   │   │
│   │   └── upgrades/
│   │       ├── speed_boost.tres
│   │       └── quality_boost.tres
│   │
│   └── minigames/
│       ├── rhythm_patterns.tres
│       ├── temperature_configs.tres
│       └── timing_windows.tres
│
└── assets/
    ├── sprites/
    │   ├── machines/
    │   │   ├── thresher/
    │   │   │   ├── idle.png
    │   │   │   ├── processing.png
    │   │   │   └── broken.png
    │   │   └── [other machines]/
    │   │
    │   ├── conveyors/
    │   │   ├── belt_straight.png
    │   │   ├── belt_corner.png
    │   │   └── hopper.png
    │   │
    │   └── minigames/
    │       ├── rhythm_notes.png
    │       ├── temperature_gauge.png
    │       └── pressure_bar.png
    │
    └── sounds/
        ├── machines/
        │   ├── thresher_loop.ogg
        │   ├── oven_heat.ogg
        │   ├── press_squeeze.ogg
        │   └── breakdown_alarm.ogg
        │
        └── minigames/
            ├── rhythm_hit.ogg
            ├── temp_warning.ogg
            └── success_chime.ogg'

flowchart TB
    subgraph ProcessingCore ["⚙️ PROCESSING SYSTEM CORE"]
        subgraph ProcessingManager ["Processing Manager (Autoload #9)"]
            ManagerData["ProcessingManager.gd<br/>---<br/>PROPERTIES:<br/>• all_machines: Array[Machine]<br/>• all_recipes: Dictionary{String: Recipe}<br/>• processing_stats: Dictionary<br/>• unlocked_machines: Array<br/>• machine_breakdown_chance: float<br/>---<br/>SIGNALS:<br/>• machine_placed(machine)<br/>• processing_started(machine)<br/>• processing_complete(machine, output)<br/>• machine_broken(machine)<br/>• recipe_discovered(recipe)"]
            
            MachineTypes["LAUNCH MACHINES:<br/>---<br/>THRESHER (2x2): Grain→Flour<br/>OVEN (2x3): Flour→Bread<br/>PRESS (2x2): Fruit→Juice<br/>MILL (3x3): Advanced grinding<br/>CUTTER (2x2): Potato→Fries<br/>PROCESSOR (4x4): Universal"]
        end

        subgraph MachineBase ["Machine Structure"]
            MachineClass["Machine.gd (Base)<br/>---<br/>PROPERTIES:<br/>• machine_name: String<br/>• size: Vector2i<br/>• processing_time: float<br/>• input_slots: int<br/>• output_slots: int<br/>• is_broken: bool<br/>• is_processing: bool<br/>• quality_multiplier: float<br/>---<br/>SIGNALS:<br/>• item_inserted(item)<br/>• processing_complete(output)<br/>• machine_jammed()<br/>• repair_needed()"]
            
            RecipeSystem["Recipe.gd (Resource)<br/>---<br/>• inputs: Array[String]<br/>• input_quantities: Array[int]<br/>• outputs: Array[String]<br/>• output_ratio: Vector2 (1:1 to 1:3)<br/>• process_time: float<br/>• required_machine: MachineType<br/>• discovered: bool"]
        end
    end

    subgraph MiniGameSystem ["🎮 MINI-GAME SYSTEM"]
        MiniGameBase["MINI-GAME BASE:<br/>• Duration: 5-15 seconds<br/>• Score: 0-100<br/>• Each machine unique<br/>• Affects output ratio<br/>• Affects process speed<br/>• Practice mode available"]
        
        GameTypes["MINI-GAME TYPES:<br/>---<br/>RHYTHM (Thresher):<br/>• 4-lane highway<br/>• WASD keys<br/>• Hit timing windows<br/>---<br/>TEMPERATURE (Oven):<br/>• Keep in target zone<br/>• Heat/Cool controls<br/>• Drift mechanics<br/>---<br/>MASHING (Press):<br/>• Alternate Q/E<br/>• Fill pressure bar<br/>• Fatigue system"]
        
        MoreGames["MORE GAMES:<br/>---<br/>ROTATION (Mill):<br/>• Mouse circles<br/>• Match RPM gauge<br/>• Consistent speed<br/>---<br/>PRECISION (Cutter):<br/>• Timing windows<br/>• Multiple cuts<br/>• Combo system"]
        
        ScoreToOutput["SCORE → OUTPUT:<br/>• 0-25%: Fail (1:1)<br/>• 26-50%: Poor (1:1.5)<br/>• 51-75%: Good (1:2)<br/>• 76-99%: Great (1:2.5)<br/>• 100%: Perfect (1:3)<br/>• Speed bonus: -20% time"]
    end

    subgraph HopperSystem ["📥 HOPPER & CONVEYOR"]
        InputHopper["INPUT HOPPER:<br/>• 5 item queue<br/>• Auto-feeds machine<br/>• Visual stack<br/>• Can get jammed<br/>• Clear with mini-game"]
        
        OutputHopper["OUTPUT HOPPER:<br/>• 10 item capacity<br/>• Auto-ejects when full<br/>• Quality sorted<br/>• Connect to conveyors<br/>• Visual feedback"]
        
        ConveyorBelts["CONVEYORS:<br/>• 1 tile wide<br/>• Directional flow<br/>• 2 items/second<br/>• Can split/merge<br/>• Connect to storage<br/>• Visual items moving"]
        
        JamMechanics["JAM MECHANICS:<br/>• 5% chance per use<br/>• Machine stops<br/>• Quick button mash<br/>• 5 second clear<br/>• Increases by week"]
    end

    subgraph QualityProcessing ["⭐ QUALITY CALCULATION"]
        InputQuality["INPUT QUALITY:<br/>• Bad: 0.5x multiplier<br/>• Normal: 1.0x<br/>• Good: 1.5x<br/>• Great: 2.0x<br/>• Perfect: 2.5x"]
        
        MiniGameScore["MINI-GAME IMPACT:<br/>• Fail: 0.5x quality<br/>• Poor: 0.75x<br/>• Good: 1.0x<br/>• Great: 1.25x<br/>• Perfect: 1.5x"]
        
        FinalQuality["FINAL QUALITY:<br/>Formula:<br/>Output = Input × MiniScore × MachineBonus<br/>---<br/>Rounded to nearest tier<br/>Capped at Perfect"]
        
        MixingRules["MIXING QUALITY:<br/>• Average all inputs<br/>• Round down<br/>• Variety bonus: +0.5<br/>• Same type: No bonus"]
    end

    subgraph MachinePlacement ["🏗️ MACHINE PLACEMENT"]
        PlacementRules["PLACEMENT RULES:<br/>• Planning phase only<br/>• Check grid space<br/>• No overlap<br/>• Must be accessible<br/>• Power not required<br/>• Can be moved"]
        
        InteractionSide["INTERACTION:<br/>• Front side only<br/>• Shows indicator<br/>• Range: 32 pixels<br/>• E to interact<br/>• Hold for hoppers"]
        
        VisualStates["VISUAL STATES:<br/>• IDLE: Gray, no steam<br/>• LOADING: Yellow pulse<br/>• PROCESSING: Green, steam<br/>• COMPLETE: Blue sparkle<br/>• BROKEN: Red, smoke<br/>• JAMMED: Orange shake"]
    end

    subgraph BreakdownSystem ["🔧 BREAKDOWN & REPAIR"]
        BreakdownMechanics["BREAKDOWN:<br/>• 5% base chance<br/>• +5% per week<br/>• Warning smoke<br/>• Sudden stop<br/>• Red alert"]
        
        RepairProcess["REPAIR PROCESS:<br/>1. Go to Computer<br/>2. Open Maintenance<br/>3. Select machine<br/>4. Pay $200-500<br/>5. Mechanic in 30s<br/>6. Fixed in 10s"]
        
        Prevention["PREVENTION:<br/>• Daily checkup: $100<br/>• Insurance: $500/day<br/>• Spare parts: Instant<br/>• Upgrades reduce rate"]
    end

    subgraph RecipeDiscovery ["📖 RECIPE DISCOVERY"]
        KnownRecipes["KNOWN RECIPES:<br/>• Wheat → Flour<br/>• Flour → Bread<br/>• Potato → Fries<br/>• Tomato → Sauce<br/>• Apple → Juice<br/>• Corn → Meal"]
        
        HiddenRecipes["DISCOVERABLE:<br/>• Flour+Tomato+Cheese → Pizza<br/>• Flour+Sugar+Eggs → Cake<br/>• Potato+Cheese → Loaded Fries<br/>• Mixed Fruits → Smoothie<br/>• Veggies+Stock → Soup"]
        
        DiscoveryRewards["DISCOVERY BONUS:<br/>• First time: 2x value<br/>• Recipe saved<br/>• Innovation Point<br/>• Reputation +5<br/>• Achievement"]
    end

    subgraph UpgradeSystem ["⬆️ MACHINE UPGRADES"]
        RunUpgrades["IN-RUN UPGRADES ($):<br/>• Speed Boost: -25% time ($500)<br/>• Quality+: +10% quality ($750)<br/>• Hopper+: +5 slots ($400)<br/>• Jam Resist: -50% jams ($600)<br/>• Batch Mode: 2x input ($1000)"]
        
        InnovationUpgrades["PERMANENT (IP):<br/>• Auto-Process Tier 1 (Skip easy)<br/>• Auto-Process Tier 2 (Skip all)<br/>• Efficiency: -20% all times<br/>• Quality Master: +15% quality<br/>• No Breakdowns"]
        
        MachineTiers["MACHINE TIERS:<br/>• Bronze: Normal<br/>• Silver: +25% all stats<br/>• Gold: +50% all stats<br/>• Diamond: Double output"]
    end

    subgraph CoopMiniGames ["👥 CO-OP MINI-GAMES"]
        DualCrank["DUAL CRANK (Mill):<br/>• Both rotate together<br/>• Match speeds<br/>• Sync indicator<br/>• Bonus for harmony"]
        
        TempBalance["TEMP BALANCE (Oven):<br/>• P1: Heating<br/>• P2: Cooling<br/>• Maintain target<br/>• Communication key"]
        
        TimingChain["TIMING CHAIN:<br/>• Sequential inputs<br/>• Color-coded turns<br/>• Perfect timing bonus<br/>• Better output"]
    end

    %% Connections
    ManagerData --> MachineTypes
    MachineClass --> RecipeSystem
    
    MiniGameBase --> GameTypes --> MoreGames --> ScoreToOutput
    
    InputHopper --> ConveyorBelts --> OutputHopper
    ConveyorBelts --> JamMechanics
    
    InputQuality --> MiniGameScore --> FinalQuality --> MixingRules
    
    PlacementRules --> InteractionSide --> VisualStates
    
    BreakdownMechanics --> RepairProcess --> Prevention
    
    KnownRecipes --> HiddenRecipes --> DiscoveryRewards
    
    RunUpgrades --> InnovationUpgrades --> MachineTiers
    
    DualCrank & TempBalance & TimingChain --> MiniGameBase
	
Implementation Priority:

ProcessingManager.gd - Central system (Autoload #9)
Machine.gd - Base machine class
Recipe.gd - Recipe system
MiniGame.gd - Base minigame
TemperatureGame.gd - First minigame
HopperSystem.gd - Input/output
QualityCalculator.gd - Quality math
BreakdownSystem.gd - Machine failures

Key Implementation Notes:

Machines can only be placed during PLANNING phase
Each machine has a unique mini-game
Quality = Input × MiniScore × MachineBonus
Mini-game score directly affects output ratio (1:1 to 1:3)
Hoppers auto-feed but can jam (5% + week modifier)
Breakdown chance increases each week
Recipe discovery gives permanent bonuses
Co-op mini-games optional but give better output