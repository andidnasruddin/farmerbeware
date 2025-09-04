flowchart LR
    subgraph Implementation ["🔧 IMPLEMENTATION CODE"]
        PhaseManager["PhaseManager.gd:<br/>---<br/>signal phase_changed(from, to)<br/>signal transition_started()<br/>signal transition_completed()<br/>---<br/>var current_phase: Phase<br/>var transition_queue: Array<br/>---<br/>func request_transition(to_phase)<br/>func can_transition() -> bool<br/>func execute_transition()"]
        
        PhaseStates["Phase States:<br/>---<br/>PlanningPhase.gd<br/>CountdownPhase.gd<br/>FarmingPhase.gd<br/>ResultsPhase.gd<br/>---<br/>Each implements:<br/>_enter() / _exit()<br/>_update(delta)<br/>_can_exit() -> bool"]
        
        TransitionEffects["TransitionEffect.gd:<br/>---<br/>func fade_out(duration)<br/>func fade_in(duration)<br/>func reset_player_positions()<br/>func clear_screen_effects()<br/>func play_transition_sound()"]
        
        PhaseUI["PhaseUI.gd:<br/>---<br/>func show_planning_ui()<br/>func show_countdown(time)<br/>func show_farming_ui()<br/>func show_results(data)<br/>func animate_transition()"]
    end

    PhaseManager --> PhaseStates
    PhaseManager --> TransitionEffects
    PhaseStates --> PhaseUI
    TransitionEffects --> PhaseUI
	
flowchart TB
    subgraph PhaseStructure ["🌅 PHASE STRUCTURE"]
        subgraph PhaseDefinitions ["Phase Types"]
            PLANNING["PLANNING PHASE<br/>---<br/>• Duration: Indefinite<br/>• Time stopped (eternal 6AM)<br/>• Can move machines<br/>• Can use computer<br/>• No crop growth<br/>• No contracts active"]
            
            COUNTDOWN["COUNTDOWN PHASE<br/>---<br/>• Duration: 10 seconds<br/>• UI countdown overlay<br/>• Can cancel at computer<br/>• Players get in position<br/>• Final preparations<br/>• Locks at 0"]
            
            FARMING["FARMING PHASE<br/>---<br/>• Duration: 10+ minutes<br/>• Time flows (6AM→6PM)<br/>• All systems active<br/>• Contracts ticking<br/>• Events trigger<br/>• Flash contracts appear"]
            
            RESULTS["RESULTS PHASE<br/>---<br/>• Duration: Until ready<br/>• Show day statistics<br/>• Calculate earnings<br/>• Save game (host)<br/>• Innovation points<br/>• Next/End buttons"]
        end

        subgraph PhaseData ["Phase State Data"]
            PhaseContext["PHASE CONTEXT:<br/>• current_phase: Phase<br/>• phase_start_time: float<br/>• phase_duration: float<br/>• can_transition: bool<br/>• transition_target: Phase<br/>• transition_progress: float"]
            
            PhaseFlags["PHASE FLAGS:<br/>• is_transitioning: bool<br/>• countdown_active: bool<br/>• countdown_cancelable: bool<br/>• force_transition: bool<br/>• all_players_ready: bool"]
        end
    end

    subgraph TransitionTriggers ["🔄 TRANSITION TRIGGERS"]
        subgraph PlanningExits ["Planning → Next"]
            ComputerStart["COMPUTER START:<br/>• Player interacts<br/>• Presses 'Start Day'<br/>• Begins countdown<br/>• Shows warning<br/>• Notifies all players"]
            
            ForceStart["FORCE START (Host):<br/>• Host override<br/>• Skip countdown<br/>• Instant farming<br/>• Emergency option"]
        end

        subgraph CountdownExits ["Countdown → Next"]
            CountdownComplete["COUNTDOWN END:<br/>• 10 seconds elapsed<br/>• Auto-transition<br/>• Cannot cancel<br/>• Force to farming"]
            
            CountdownCancel["COUNTDOWN CANCEL:<br/>• Computer interaction<br/>• Within 9 seconds<br/>• Return to planning<br/>• Reset countdown"]
        end

        subgraph FarmingExits ["Farming → Next"]
            DayComplete["DAY COMPLETE:<br/>• 6:00 PM reached<br/>• Time expired<br/>• Auto-transition<br/>• Force save"]
            
            ContractFail["CONTRACT FAIL:<br/>• Mandatory fail<br/>• Instant end<br/>• Show failure<br/>• Run over"]
            
            HostEnd["HOST FORCE END:<br/>• Manual end day<br/>• Emergency option<br/>• Skip to results"]
        end

        subgraph ResultsExits ["Results → Next"]
            NextDay["NEXT DAY:<br/>• Day < 15<br/>• Click continue<br/>• Back to planning<br/>• Reset time"]
            
            RunEnd["RUN END:<br/>• Day 15 complete<br/>• Or failure<br/>• Return to menu<br/>• Show final stats"]
        end
    end

    subgraph TransitionProcess ["⚡ TRANSITION PROCESS"]
        subgraph PreTransition ["Pre-Transition"]
            ValidateTransition["VALIDATE:<br/>• Can transition now?<br/>• All conditions met?<br/>• Network ready?<br/>• Resources saved?"]
            
            PrepareTransition["PREPARE:<br/>• Lock inputs<br/>• Stop actions<br/>• Save state<br/>• Notify players<br/>• Start fade"]
        end

        subgraph DuringTransition ["During Transition"]
            FadeOut["FADE OUT (0.5s):<br/>• Screen to black<br/>• Audio fade<br/>• Disable input<br/>• Hide UI"]
            
            StateSwitch["STATE SWITCH:<br/>• Change phase<br/>• Reset positions<br/>• Clear buffers<br/>• Load new UI<br/>• Update systems"]
            
            FadeIn["FADE IN (0.5s):<br/>• Black to clear<br/>• Audio fade in<br/>• Enable input<br/>• Show new UI"]
        end

        subgraph PostTransition ["Post-Transition"]
            InitializePhase["INITIALIZE:<br/>• Start timers<br/>• Enable systems<br/>• Spawn events<br/>• Update HUD<br/>• Unlock input"]
            
            ConfirmSync["CONFIRM SYNC:<br/>• Check all players<br/>• Verify state<br/>• Force sync if needed<br/>• Log transition"]
        end
    end

    subgraph SystemChanges ["🎮 SYSTEM CHANGES PER PHASE"]
        subgraph PlanningActive ["Planning Active Systems"]
            PlanningOn["✅ ENABLED:<br/>• Machine placement<br/>• Computer UI<br/>• Building movement<br/>• Innovation tree<br/>• Contract viewing"]
            
            PlanningOff["❌ DISABLED:<br/>• Crop growth<br/>• Time progression<br/>• Contract timers<br/>• Weather events<br/>• NPCs"]
        end

        subgraph FarmingActive ["Farming Active Systems"]
            FarmingOn["✅ ENABLED:<br/>• All tools<br/>• Crop growth<br/>• Time flow<br/>• Contracts<br/>• Events<br/>• Processing"]
            
            FarmingOff["❌ DISABLED:<br/>• Machine placement<br/>• Building movement<br/>• Innovation spending<br/>• Save menu"]
        end

        subgraph UIChanges ["UI Changes"]
            PlanningUI["PLANNING UI:<br/>• 'Press E to start'<br/>• No timer<br/>• Machine ghosts<br/>• Grid visible<br/>• Relaxed music"]
            
            CountdownUI["COUNTDOWN UI:<br/>• Large timer<br/>• 'GET READY!'<br/>• Pulse effect<br/>• Warning sounds<br/>• Cancel prompt"]
            
            FarmingUI["FARMING UI:<br/>• Clock visible<br/>• Contract cards<br/>• Tool indicator<br/>• Money display<br/>• Intense music"]
            
            ResultsUI["RESULTS UI:<br/>• Statistics panel<br/>• Money earned<br/>• Contracts status<br/>• IP gained<br/>• Continue button"]
        end
    end

    subgraph NetworkSync ["🌐 NETWORK SYNCHRONIZATION"]
        HostControl["HOST CONTROLS:<br/>• Phase transitions<br/>• Countdown start<br/>• Force transitions<br/>• Save triggers<br/>• Time flow"]
        
        ClientSync["CLIENT SYNC:<br/>• Follow host phase<br/>• Request transitions<br/>• Local UI only<br/>• Wait for host<br/>• Buffer inputs"]
        
        TransitionPacket["TRANSITION RPC:<br/>{<br/>  from_phase: Phase,<br/>  to_phase: Phase,<br/>  duration: float,<br/>  forced: bool,<br/>  timestamp: int<br/>}"]
        
        SyncProtocol["SYNC PROTOCOL:<br/>1. Host decides transition<br/>2. Broadcast to all<br/>3. Clients acknowledge<br/>4. Wait for all ACK<br/>5. Execute transition<br/>6. Confirm completion"]
    end

    subgraph EdgeCases ["⚠️ EDGE CASES"]
        DisconnectDuring["DISCONNECT DURING:<br/>• Pause transition<br/>• Wait 5 minutes<br/>• Continue if timeout<br/>• Skip if non-critical"]
        
        FailedTransition["FAILED TRANSITION:<br/>• Log error<br/>• Force to safe phase<br/>• Planning = safe<br/>• Results = safe<br/>• Notify players"]
        
        QuickTransitions["RAPID TRANSITIONS:<br/>• Minimum 1s between<br/>• Queue if too fast<br/>• Prevent spam<br/>• Smooth experience"]
    end

    %% Flow connections
    PLANNING --> ComputerStart --> COUNTDOWN
    COUNTDOWN --> CountdownComplete --> FARMING
    COUNTDOWN --> CountdownCancel --> PLANNING
    FARMING --> DayComplete --> RESULTS
    FARMING --> ContractFail --> RESULTS
    RESULTS --> NextDay --> PLANNING
    RESULTS --> RunEnd
    
    ValidateTransition --> PrepareTransition
    PrepareTransition --> FadeOut
    FadeOut --> StateSwitch
    StateSwitch --> FadeIn
    FadeIn --> InitializePhase
    InitializePhase --> ConfirmSync
    
    PlanningOn -.-> PlanningUI
    FarmingOn -.-> FarmingUI
    CountdownUI -.-> CountdownComplete
    
    HostControl --> TransitionPacket
    TransitionPacket --> ClientSync
    ClientSync --> SyncProtocol