flowchart LR
    subgraph Implementation ["🔧 IMPLEMENTATION PATTERN"]
        GMScript["GameManager.gd:<br/>---<br/>var current_state: State<br/>var sub_states: Array<br/>var state_stack: Array<br/>var transition_queue: Array"]
        
        StateClass["State.gd (Base):<br/>---<br/>func _enter() → void<br/>func _exit() → void<br/>func _update(delta) → void<br/>func _handle_input(event) → void<br/>func can_transition_to(state) → bool"]
        
        StateInstances["Concrete States:<br/>---<br/>MenuState.gd<br/>LobbyState.gd<br/>PlayingState.gd<br/>PlanningState.gd<br/>FarmingState.gd<br/>Etc..."]
        
        TransitionManager["TransitionManager.gd:<br/>---<br/>func request_transition(to_state)<br/>func validate_transition()<br/>func execute_transition()<br/>func rollback_transition()"]
    end

    GMScript --> StateClass
    StateClass --> StateInstances
    GMScript --> TransitionManager
    TransitionManager --> StateInstances

flowchart TB
    subgraph StateMachine ["🎯 CORE STATE MACHINE"]
        subgraph PrimaryStates ["PRIMARY STATES (Exclusive)"]
            BOOT["BOOT<br/>• Loading resources<br/>• Checking saves<br/>• Steam API init"]
            
            MENU["MENU<br/>• Main menu active<br/>• Can access settings<br/>• Can view stats"]
            
            LOBBY["LOBBY<br/>• Players joining<br/>• Character customization<br/>• Ready checks<br/>• Host controls"]
            
            PLAYING["PLAYING<br/>• In farm scene<br/>• Game timer active<br/>• All systems running"]
            
            PAUSED["PAUSED<br/>• Time stopped<br/>• Pause menu shown<br/>• Input blocked<br/>• Network waiting"]
            
            RESULTS["RESULTS<br/>• Day/Run ended<br/>• Stats displayed<br/>• IP calculated<br/>• Save triggered"]
        end

        subgraph SubStates ["SUB-STATES (During PLAYING)"]
            PLANNING["PLANNING<br/>• Time stopped<br/>• Can move machines<br/>• Can use computer<br/>• No farming"]
            
            COUNTDOWN["COUNTDOWN<br/>• 10 second timer<br/>• UI countdown<br/>• Can cancel<br/>• Locks at 0"]
            
            FARMING["FARMING<br/>• Timer running<br/>• All actions enabled<br/>• Contracts active<br/>• Events trigger"]
            
            MINIGAME["MINIGAME<br/>• Player locked<br/>• Special input<br/>• Time continues<br/>• Others unaffected"]
            
            TRANSITION["TRANSITION<br/>• Between phases<br/>• Fade effects<br/>• Position reset<br/>• State cleanup"]
        end
    end

    subgraph StateTransitions ["🔄 TRANSITION RULES"]
        ValidTransitions["VALID TRANSITIONS:<br/>---<br/>BOOT → MENU (always)<br/>MENU → LOBBY (host/join)<br/>MENU → PLAYING (continue save)<br/>LOBBY → PLAYING (all ready)<br/>PLAYING ↔ PAUSED (pause key)<br/>PLAYING → RESULTS (day end/fail)<br/>RESULTS → MENU (run over)<br/>RESULTS → PLAYING (next day)"]
        
        SubTransitions["SUB-STATE TRANSITIONS:<br/>---<br/>PLAYING+PLANNING → COUNTDOWN<br/>COUNTDOWN → FARMING<br/>COUNTDOWN → PLANNING (cancel)<br/>FARMING → RESULTS (6PM)<br/>FARMING+any → MINIGAME<br/>MINIGAME → previous state<br/>Any → TRANSITION → Next"]
        
        GuardConditions["GUARD CONDITIONS:<br/>• Can't pause during MINIGAME<br/>• Can't LOBBY while PLAYING<br/>• Must save before MENU<br/>• Network must sync<br/>• Resources must unload"]
    end

    subgraph StateData ["📊 STATE DATA MANAGEMENT"]
        StateStack["State Stack:<br/>• Primary state (1)<br/>• Sub-state (0-2)<br/>• Previous state<br/>• Transition target<br/>• Transition progress"]
        
        StateMemory["State Memory:<br/>• Entry timestamp<br/>• State parameters<br/>• Pause reason<br/>• Error context<br/>• Network snapshot"]
        
        StatePersistence["Persistence Rules:<br/>• PLANNING: Save nothing<br/>• FARMING: Track all<br/>• PAUSED: Freeze state<br/>• MINIGAME: Buffer inputs<br/>• RESULTS: Compile stats"]
    end

    subgraph StateCallbacks ["📢 STATE CALLBACKS"]
        EntryCallbacks["ON ENTER:<br/>---<br/>MENU: Load UI, play music<br/>LOBBY: Open network<br/>PLAYING: Load farm<br/>PLANNING: Enable placement<br/>FARMING: Start timer<br/>MINIGAME: Lock player<br/>PAUSED: Show menu<br/>RESULTS: Calculate"]
        
        ExitCallbacks["ON EXIT:<br/>---<br/>MENU: Save settings<br/>LOBBY: Close connections<br/>PLAYING: Quick save<br/>PLANNING: Lock machines<br/>FARMING: Stop timer<br/>MINIGAME: Restore input<br/>PAUSED: Resume time<br/>RESULTS: Clear stats"]
        
        UpdateCallbacks["ON UPDATE (per frame):<br/>---<br/>FARMING: Tick timer<br/>COUNTDOWN: Update UI<br/>MINIGAME: Process input<br/>TRANSITION: Animate<br/>PAUSED: Check unpause<br/>LOBBY: Sync players"]
    end

    subgraph NetworkStateSync ["🌐 NETWORK STATE SYNC"]
        HostAuthority["HOST AUTHORITY:<br/>• Host controls primary state<br/>• Broadcasts transitions<br/>• Validates client requests<br/>• Forces sync on desync"]
        
        ClientStates["CLIENT HANDLING:<br/>• Follow host state<br/>• Local sub-states OK<br/>• Request transitions<br/>• Buffer during transition"]
        
        SyncProtocol["SYNC PROTOCOL:<br/>1. Host changes state<br/>2. Broadcast new state<br/>3. Wait confirmations<br/>4. Proceed or rollback<br/>5. Force sync if timeout"]
    end

    subgraph ErrorRecovery ["⚠️ ERROR STATE RECOVERY"]
        ErrorStates["ERROR SCENARIOS:<br/>• Invalid transition<br/>• Network desync<br/>• Resource missing<br/>• Save corrupted<br/>• Crash recovery"]
        
        RecoveryFlow["RECOVERY FLOW:<br/>1. Detect invalid state<br/>2. Log error context<br/>3. Attempt quick save<br/>4. Force to safe state<br/>5. Show error dialog<br/>6. Return to MENU"]
        
        SafeStates["SAFE STATES:<br/>• MENU (always safe)<br/>• PAUSED (if possible)<br/>• RESULTS (save first)<br/>Never: MINIGAME, COUNTDOWN"]
    end

    %% Flow connections
    BOOT --> MENU
    MENU --> LOBBY
    LOBBY --> PLAYING
    PLAYING --> PLANNING
    PLANNING --> COUNTDOWN
    COUNTDOWN --> FARMING
    FARMING --> RESULTS
    RESULTS --> MENU
    
    PLAYING <--> PAUSED
    FARMING --> MINIGAME
    MINIGAME --> FARMING
    
    ValidTransitions --> GuardConditions
    SubTransitions --> GuardConditions
    
    StateStack --> StateMemory --> StatePersistence
    
    EntryCallbacks --> StateStack
    ExitCallbacks --> StateStack
    UpdateCallbacks --> StateStack
    
    HostAuthority --> SyncProtocol
    ClientStates --> SyncProtocol
    
    ErrorStates --> RecoveryFlow --> SafeStates