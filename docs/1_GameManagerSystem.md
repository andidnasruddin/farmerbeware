res://
├── scenes/
│   ├── main/
│   │   ├── Main.tscn              # Root scene
│   │   ├── Boot.tscn              # Boot screen
│   │   └── GameController.tscn    # Game orchestrator
│   │
│   └── debug/
│       ├── DebugOverlay.tscn      # F3 overlay
│       ├── Console.tscn           # Command console
│       └── Profiler.tscn          # Performance
│
├── scripts/
│   ├── managers/
│   │   └── GameManager.gd         # Autoload #1 (FIRST!)
│   │
│   ├── core/
│   │   ├── GameState.gd           # State machine
│   │   ├── SceneManager.gd        # Scene loading
│   │   ├── ResourceManager.gd     # Money/resources
│   │   ├── PlayerManager.gd       # Player handling
│   │   └── InitializationManager.gd # Boot sequence
│   │
│   ├── flow/
│   │   ├── RunController.gd       # Run lifecycle
│   │   ├── DayController.gd       # Day flow
│   │   ├── WinLoseHandler.gd      # Conditions
│   │   └── TransitionManager.gd   # Transitions
│   │
│   ├── economy/
│   │   ├── MoneyManager.gd        # Shared money
│   │   ├── TransactionLogger.gd   # Transaction log
│   │   ├── EconomyBalancer.gd     # Balance testing
│   │   └── PriceCalculator.gd     # Dynamic prices
│   │
│   ├── debug/
│   │   ├── DebugConsole.gd        # Console commands
│   │   ├── DebugOverlay.gd        # Visual debug
│   │   ├── CheatManager.gd        # Dev cheats
│   │   └── Profiler.gd            # Performance
│   │
│   ├── error/
│   │   ├── ErrorHandler.gd        # Error catching
│   │   ├── CrashReporter.gd       # Crash dumps
│   │   ├── RecoveryManager.gd     # Recovery logic
│   │   └── Logger.gd              # Logging system
│   │
│   └── events/
│       ├── EventBus.gd            # Global events
│       ├── EventDispatcher.gd     # Event routing
│       └── EventQueue.gd          # Priority queue
│
├── resources/
│   ├── config/
│   │   ├── game_config.tres       # Core settings
│   │   ├── economy_config.tres    # Economy values
│   │   ├── debug_config.tres      # Debug settings
│   │   └── autoload_order.tres    # Load sequence
│   │
│   └── states/
│       ├── boot_state.tres
│       ├── menu_state.tres
│       ├── playing_state.tres
│       └── paused_state.tres
│
└── assets/
    └── debug/
        ├── fonts/
        │   └── debug_mono.ttf      # Debug font
        └── icons/
            └── debug_icons.png     # Debug UI
			
flowchart TB
    subgraph GameManagerCore ["🎯 GAME MANAGER CORE (The Orchestrator)"]
        subgraph GameManager ["Game Manager (Autoload #1 - FIRST!)"]
            CoreData["GameManager.gd<br/>---<br/>PROPERTIES:<br/>• current_state: GameState<br/>• active_players: Array[Player]<br/>• current_money: int (shared)<br/>• total_runtime: float<br/>• is_paused: bool<br/>• debug_mode: bool<br/>• current_scene: Node<br/>---<br/>SIGNALS:<br/>• state_changed(from, to)<br/>• money_changed(amount)<br/>• player_joined(player)<br/>• player_left(player)<br/>• game_over(reason)<br/>• run_started()<br/>• run_ended(stats)"]
            
            GameStates["GAME STATES:<br/>---<br/>BOOT: Loading resources<br/>MENU: Main menu active<br/>LOBBY: Multiplayer setup<br/>LOADING: Scene transition<br/>PLAYING: In farm scene<br/>PAUSED: Game paused<br/>RESULTS: Day/run results<br/>GAME_OVER: Run ended"]
        end

        subgraph SystemCoordination ["System Coordination"]
            InitOrder["AUTOLOAD ORDER:<br/>1. GameManager (orchestrator)<br/>2. GridValidator (validate first)<br/>3. GridManager (world grid)<br/>4. InteractionSystem (inputs)<br/>5. TimeManager (day/phases)<br/>6. EventManager (events)<br/>7. CropManager (crops)<br/>8. ContractManager (objectives)<br/>9. ProcessingManager (machines)<br/>10. NetworkManager (multiplayer)<br/>11. SaveManager (persistence)<br/>12. InnovationManager (meta)<br/>13. AudioManager (sounds)<br/>14. UIManager (interface)"]
            
            SystemDependencies["DEPENDENCIES:<br/>• Grid needs Validator<br/>• Interaction needs Grid<br/>• Crops need Grid+Time<br/>• Contracts need Time<br/>• Processing needs Grid<br/>• Network needs all<br/>• Save needs all<br/>• UI needs all"]
        end
    end

    subgraph ResourceManagement ["💰 RESOURCE MANAGEMENT"]
        MoneySystem["MONEY SYSTEM:<br/>• Shared pool (co-op)<br/>• Start: $1000<br/>• Min: $0 (can't go negative)<br/>• All players access<br/>• Host authoritative<br/>• Instant sync"]
        
        TransactionLog["TRANSACTIONS:<br/>• Log all changes<br/>• Source tracking<br/>• Timestamp<br/>• Rollback capable<br/>• Network sync<br/>• Save included"]
        
        EconomyBalance["ECONOMY:<br/>• Income: Contracts/Market<br/>• Costs: Seeds/Machines<br/>• Insurance: $1000<br/>• Repairs: $200-500<br/>• Upgrades: $400-1000<br/>• Land: $1000/plot"]
    end

    subgraph PlayerManagement ["👥 PLAYER MANAGEMENT"]
        PlayerPool["PLAYER POOL:<br/>• Max 4 players<br/>• Dynamic join/leave<br/>• AI takeover option<br/>• Character persistence<br/>• Tool ownership<br/>• Position tracking"]
        
        PlayerFactory["PLAYER CREATION:<br/>1. Receive join request<br/>2. Assign player ID<br/>3. Spawn at start<br/>4. Give starting tools<br/>5. Connect signals<br/>6. Sync to others"]
        
        PlayerCleanup["PLAYER REMOVAL:<br/>1. Disconnect signal<br/>2. Drop carried items<br/>3. Clear ownership<br/>4. Remove character<br/>5. Update UI<br/>6. Redistribute tools"]
    end

    subgraph SceneManagement ["🎬 SCENE MANAGEMENT"]
        SceneController["SCENE CONTROL:<br/>• Current scene ref<br/>• Transition state<br/>• Loading progress<br/>• Memory cleanup<br/>• Asset preload<br/>• Smooth transitions"]
        
        SceneFlow["SCENE FLOW:<br/>Boot → Menu → Lobby → Farm → Results → Menu<br/>---<br/>Each transition:<br/>1. Fade out<br/>2. Unload current<br/>3. Load new<br/>4. Initialize<br/>5. Fade in"]
        
        ScenePreloading["PRELOAD STRATEGY:<br/>• Menu: Always loaded<br/>• Farm: Load in lobby<br/>• UI: Persistent overlay<br/>• Audio: Never unload<br/>• Shaders: Compile early"]
    end

    subgraph GameFlow ["🎮 GAME FLOW CONTROL"]
        RunLifecycle["RUN LIFECYCLE:<br/>1. Initialize run<br/>2. Load farm scene<br/>3. Spawn players<br/>4. Start Day 1<br/>5. Game loop<br/>6. Check win/lose<br/>7. Calculate rewards<br/>8. Return to menu"]
        
        DayFlow["DAY FLOW:<br/>1. Planning phase<br/>2. Accept contracts<br/>3. Start countdown<br/>4. Farming phase<br/>5. Process results<br/>6. Save progress<br/>7. Next or end"]
        
        WinConditions["WIN CONDITIONS:<br/>• Survive 15 days<br/>• Complete Week 4<br/>• All 10 events<br/>• Special endings"]
        
        LoseConditions["LOSE CONDITIONS:<br/>• Flash contract fail<br/>• Mandatory fail<br/>• Bankruptcy<br/>• All quit"]
    end

    subgraph InitializationSequence ["🚀 INITIALIZATION SEQUENCE"]
        BootSequence["BOOT SEQUENCE:<br/>1. Check Steam API<br/>2. Load settings<br/>3. Init autoloads<br/>4. Precompile shaders<br/>5. Load main menu<br/>6. Check saves<br/>7. Ready for input"]
        
        FarmInitialize["FARM INIT:<br/>1. Load scene<br/>2. Generate grid<br/>3. Place buildings<br/>4. Spawn players<br/>5. Load contracts<br/>6. Start time<br/>7. Enable input"]
        
        ShutdownSequence["SHUTDOWN:<br/>1. Auto-save<br/>2. Upload stats<br/>3. Close network<br/>4. Free resources<br/>5. Steam cleanup<br/>6. Exit"]
    end

    subgraph DebugSystem ["🐛 DEBUG SYSTEM"]
        DebugCommands["DEBUG COMMANDS (F3):<br/>• Give money: /money 5000<br/>• Skip day: /nextday<br/>• Unlock all: /unlock<br/>• God mode: /god<br/>• Show grid: /grid<br/>• Network stats: /net"]
        
        DebugOverlay["DEBUG OVERLAY:<br/>• FPS counter<br/>• Memory usage<br/>• Network ping<br/>• System timers<br/>• Grid chemistry<br/>• State machine"]
        
        Cheats["DEV CHEATS:<br/>• F1: +$1000<br/>• F2: Complete contracts<br/>• F4: Skip to results<br/>• F5: Force save<br/>• F6: Crash test<br/>• F7: Network desync"]
    end

    subgraph ErrorHandling ["⚠️ ERROR RECOVERY"]
        ErrorTypes["ERROR TYPES:<br/>• Network timeout<br/>• Save corruption<br/>• Missing resources<br/>• State desync<br/>• Memory overflow<br/>• Shader compile fail"]
        
        RecoveryStrategy["RECOVERY:<br/>1. Log error details<br/>2. Capture state<br/>3. Attempt fix<br/>4. Fallback option<br/>5. Notify player<br/>6. Continue if possible"]
        
        CrashHandler["CRASH HANDLING:<br/>• Dump logs<br/>• Save state<br/>• Upload report<br/>• Quick restart<br/>• Restore save<br/>• Sorry message"]
    end

    subgraph PerformanceMonitor ["📊 PERFORMANCE MONITOR"]
        Metrics["METRICS:<br/>• Frame time<br/>• Draw calls<br/>• Physics bodies<br/>• Network traffic<br/>• Memory usage<br/>• CPU threads"]
        
        Optimization["AUTO-OPTIMIZE:<br/>• Reduce particles<br/>• Lower shadows<br/>• Cull distance<br/>• Batch draws<br/>• Compress textures<br/>• Limit sounds"]
        
        Profiling["PROFILING:<br/>• Frame profiler<br/>• Network monitor<br/>• Memory tracker<br/>• Bottleneck finder<br/>• Heat mapping"]
    end

    subgraph GlobalEvents ["📢 GLOBAL EVENT BUS"]
        EventBus["EVENT BUS:<br/>• Central dispatcher<br/>• Type-safe events<br/>• Priority queue<br/>• Async capable<br/>• Network aware<br/>• Debug logging"]
        
        CommonEvents["COMMON EVENTS:<br/>• game_started<br/>• day_changed<br/>• phase_changed<br/>• money_spent<br/>• contract_complete<br/>• player_action"]
        
        EventFlow["EVENT FLOW:<br/>1. System emits<br/>2. GameManager receives<br/>3. Validate event<br/>4. Queue by priority<br/>5. Process in order<br/>6. Dispatch to listeners"]
    end

    %% Connections
    CoreData --> GameStates
    InitOrder --> SystemDependencies
    
    MoneySystem --> TransactionLog --> EconomyBalance
    
    PlayerPool --> PlayerFactory --> PlayerCleanup
    
    SceneController --> SceneFlow --> ScenePreloading
    
    RunLifecycle --> DayFlow
    WinConditions & LoseConditions --> RunLifecycle
    
    BootSequence --> FarmInitialize --> ShutdownSequence
    
    DebugCommands --> DebugOverlay --> Cheats
    
    ErrorTypes --> RecoveryStrategy --> CrashHandler
    
    Metrics --> Optimization --> Profiling
    
    EventBus --> CommonEvents --> EventFlow
	
Implementation Priority:

GameManager.gd - MUST BE FIRST AUTOLOAD!
GameState.gd - State machine
InitializationManager.gd - Boot sequence
SceneManager.gd - Scene transitions
PlayerManager.gd - Player handling
ResourceManager.gd - Money system
RunController.gd - Game flow
EventBus.gd - Event system
ErrorHandler.gd - Error recovery
DebugConsole.gd - Debug tools

Key Implementation Notes:

GameManager MUST be Autoload #1 (orchestrates everything)
All other systems register with GameManager on _ready()
Central money pool for all players (shared economy)
State machine controls high-level flow
Scene transitions always go through GameManager
Event bus prevents tight coupling between systems
Debug system only in debug builds
Error recovery attempts to continue game
Performance monitor can auto-adjust quality

1. GameManager
2. GridValidator  
3. GridManager
4. InteractionSystem
5. TimeManager
6. EventManager
7. CropManager
8. AudioManager (if separate)
9. ContractManager
10. ProcessingManager
11. NetworkManager
12. SaveManager
13. InnovationManager
14. UIManager (next system)