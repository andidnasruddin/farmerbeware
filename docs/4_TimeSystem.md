res://
├── scenes/
│   ├── time/
│   │   ├── TimeDisplay.tscn       # Clock UI
│   │   ├── CountdownOverlay.tscn  # 10s countdown
│   │   ├── PhaseTransition.tscn   # Fade effects
│   │   └── CalendarUI.tscn        # Day/Week view
│   │
│   ├── events/
│   │   ├── WeatherOverlay.tscn    # Weather visuals
│   │   ├── EventNotification.tscn # Event popups
│   │   ├── NPCVisitor.tscn        # NPC base scene
│   │   └── DisasterEffect.tscn    # Disaster visuals
│   │
│   └── npcs/
│       ├── Baker.tscn
│       ├── Chef.tscn
│       ├── Mayor.tscn
│       └── Merchant.tscn
│
├── scripts/
│   ├── managers/
│   │   ├── TimeManager.gd         # Autoload #4
│   │   └── EventManager.gd        # Autoload #5
│   │
│   ├── time/
│   │   ├── PhaseController.gd     # Phase transitions
│   │   ├── DayNightCycle.gd       # Time progression
│   │   ├── TimeDisplay.gd         # UI updates
│   │   ├── CountdownController.gd # Countdown logic
│   │   └── DifficultyScaler.gd    # Scaling system
│   │
│   ├── events/
│   │   ├── Event.gd                # Base event class
│   │   ├── WeatherEvent.gd        # Weather system
│   │   ├── StoryEvent.gd          # Story triggers
│   │   ├── DisasterEvent.gd       # Disaster logic
│   │   ├── NPCEvent.gd            # NPC visits
│   │   └── EventScheduler.gd      # Timing logic
│   │
│   ├── weather/
│   │   ├── WeatherController.gd   # Weather manager
│   │   ├── WeatherEffects.gd      # Visual/audio
│   │   ├── RainSystem.gd          # Rain mechanics
│   │   ├── DroughtSystem.gd       # Drought mechanics
│   │   └── StormSystem.gd         # Storm damage
│   │
│   └── npcs/
│       ├── NPCBase.gd             # Base NPC class
│       ├── NPCBaker.gd            # Baker logic
│       ├── NPCChef.gd             # Chef logic
│       └── NPCMayor.gd            # Mayor logic
│
├── resources/
│   ├── events/
│   │   ├── weather/
│   │   │   ├── sunny.tres         # Weather configs
│   │   │   ├── rain.tres
│   │   │   ├── drought.tres
│   │   │   └── storm.tres
│   │   │
│   │   ├── story/
│   │   │   ├── mayors_birthday.tres
│   │   │   ├── harvest_festival.tres
│   │   │   └── [other events].tres
│   │   │
│   │   └── disasters/
│   │       ├── tornado.tres
│   │       ├── flood.tres
│   │       └── plague.tres
│   │
│   └── schedules/
│       ├── week1_schedule.tres    # Event timings
│       ├── week2_schedule.tres
│       ├── week3_schedule.tres
│       └── week4_schedule.tres
│
└── assets/
    ├── sprites/
    │   ├── ui/
    │   │   ├── clock_face.png
    │   │   ├── sun_icon.png
    │   │   └── countdown_numbers.png
    │   │
    │   ├── weather/
    │   │   ├── rain_drops.png
    │   │   ├── snow_flakes.png
    │   │   ├── storm_clouds.png
    │   │   └── sun_rays.png
    │   │
    │   └── npcs/
    │       ├── baker_sprite.png
    │       ├── chef_sprite.png
    │       └── mayor_sprite.png
    │
    └── sounds/
        ├── time/
        │   ├── tick_tock.ogg
        │   ├── phase_transition.ogg
        │   ├── countdown_beep.ogg
        │   └── day_end_bell.ogg
        │
        ├── weather/
        │   ├── rain_loop.ogg
        │   ├── thunder.ogg
        │   ├── wind_howl.ogg
        │   └── sunny_ambience.ogg
        │
        └── events/
            ├── npc_arrive.ogg
            ├── disaster_siren.ogg
            └── event_complete.ogg
			
flowchart TB
    subgraph TimeCore ["⏰ TIME SYSTEM CORE"]
        subgraph TimeManager ["Time Manager (Autoload #4)"]
            TimeData["TimeManager.gd<br/>---<br/>PROPERTIES:<br/>• current_phase: Phase<br/>• game_time: float (6.0-18.0)<br/>• day_timer: float<br/>• current_day: int (1-15)<br/>• current_week: int (1-4)<br/>• day_of_week: int (1-7)<br/>• time_scale: float (1.0)<br/>---<br/>SIGNALS:<br/>• phase_changed(from, to)<br/>• hour_passed(hour)<br/>• day_ended(day)<br/>• week_ended(week)<br/>• time_pressure(seconds)"]
            
            PhaseSystem["GAME PHASES:<br/>---<br/>PLANNING (∞ time):<br/>• Move machines<br/>• Accept contracts<br/>• Buy items<br/>• Time frozen at 6AM<br/>---<br/>COUNTDOWN (10s):<br/>• Final warning<br/>• Get in position<br/>• Can cancel<br/>---<br/>FARMING (10+ min):<br/>• 6AM → 6PM<br/>• All systems active<br/>• Real gameplay<br/>---<br/>RESULTS (∞ time):<br/>• Show statistics<br/>• Save game<br/>• Continue/End"]
        end

        subgraph DayStructure ["Day/Week Structure"]
            DayLengths["DAY LENGTHS BY WEEK:<br/>• Monday: 240s (4 min)<br/>• Tuesday: 300s (5 min)<br/>• Wednesday: 360s (6 min)<br/>• Thursday: 420s (7 min)<br/>• Friday: 480s (8 min)<br/>• Saturday: 300s (Market)<br/>• Sunday: 300s (Market)"]
            
            WeekProgression["WEEK PROGRESSION:<br/>• Week 1: Tutorial (easy)<br/>• Week 2: Normal<br/>• Week 3: Hard<br/>• Week 4: Extreme<br/>• 15 days total run<br/>• Difficulty scales"]
            
            TimeFlow["TIME FLOW:<br/>• 6AM start (dawn)<br/>• 12PM noon (events)<br/>• 6PM end (dusk)<br/>• 12 game hours<br/>• Variable real time"]
        end
    end

    subgraph EventSystem ["🎭 EVENT MANAGER (Autoload #5)"]
        EventCore["EventManager.gd<br/>---<br/>MANAGES:<br/>• Weather events<br/>• Story events<br/>• NPC visits<br/>• Disasters<br/>• Flash contracts<br/>• Seasonal changes<br/>---<br/>SIGNALS:<br/>• event_triggered(event)<br/>• weather_changed(type)<br/>• npc_arrived(npc)<br/>• disaster_warning(type)"]
        
        EventSchedule["EVENT SCHEDULE:<br/>• 8AM: Morning events<br/>• 12PM: Flash contract<br/>• 2PM: NPC visits<br/>• 4PM: Weather change<br/>• Random: Disasters<br/>• Scripted: Story"]
        
        EventQueue["EVENT QUEUE:<br/>• Priority sorting<br/>• Conflict resolution<br/>• Max 1 weather<br/>• Max 1 disaster<br/>• Multiple NPCs OK<br/>• Story overrides"]
    end

    subgraph WeatherEvents ["🌤️ WEATHER SYSTEM"]
        WeatherTypes["WEATHER TYPES:<br/>---<br/>SUNNY: Normal growth<br/>RAIN: Free water, +pH<br/>DROUGHT: 2x evaporation<br/>HEAT WAVE: +50% water need<br/>STORM: Crop damage risk<br/>FROST: Cold damage<br/>ACID RAIN: pH -0.5"]
        
        WeatherEffects["WEATHER EFFECTS:<br/>• Visual overlay<br/>• Audio ambience<br/>• Particle systems<br/>• Gameplay modifiers<br/>• Duration: 2-5 min<br/>• Warning: 30s before"]
        
        WeatherProbability["PROBABILITY BY WEEK:<br/>• Week 1: 70% sunny<br/>• Week 2: 50% sunny<br/>• Week 3: 30% sunny<br/>• Week 4: 10% sunny<br/>• Disasters increase"]
    end

    subgraph StoryEvents ["📖 STORY EVENTS"]
        EventContracts["EVENT CONTRACTS (10):<br/>1. Mayor's Birthday<br/>2. Harvest Festival<br/>3. School Lunch<br/>4. Restaurant Opening<br/>5. Disaster Relief<br/>6. Wedding Catering<br/>7. Science Fair<br/>8. Hospital Donation<br/>9. Town BBQ<br/>10. Winter Prep"]
        
        NPCVisitors["NPC VISITORS:<br/>• Baker (wheat/bread)<br/>• Chef (quality veggies)<br/>• Merchant (bulk orders)<br/>• Mayor (special events)<br/>• Inspector (bonuses)<br/>• Arrive randomly<br/>• 30s to accept"]
        
        EventRewards["EVENT REWARDS:<br/>• Innovation Points<br/>• Unique seeds<br/>• Temp buffs<br/>• Reputation bonus<br/>• Story progress<br/>• Achievements"]
    end

    subgraph DisasterEvents ["🌪️ DISASTERS"]
        DisasterTypes["DISASTER TYPES:<br/>• Tornado (destroy crops)<br/>• Flood (reset water)<br/>• Plague (spread disease)<br/>• Power Out (machines stop)<br/>• Market Crash (prices -50%)<br/>• Thieves (steal items)"]
        
        DisasterMitigation["MITIGATION:<br/>• Insurance (once/week)<br/>• Shelters (protect area)<br/>• Backup power<br/>• Pesticides<br/>• Security fence<br/>• Emergency supplies"]
        
        DisasterTiming["TIMING:<br/>• Week 1: None<br/>• Week 2: 10% chance<br/>• Week 3: 25% chance<br/>• Week 4: 40% chance<br/>• Warning: 60s<br/>• Duration: 30-60s"]
    end

    subgraph PhaseTransitions ["🔄 PHASE TRANSITIONS"]
        TransitionFlow["TRANSITION FLOW:<br/>---<br/>PLANNING → COUNTDOWN:<br/>• Computer 'Start Day'<br/>• 10 second timer<br/>• Can cancel<br/>---<br/>COUNTDOWN → FARMING:<br/>• Automatic at 0<br/>• Lock machines<br/>• Start time<br/>---<br/>FARMING → RESULTS:<br/>• 6PM reached<br/>• Or contract fail<br/>• Calculate score<br/>---<br/>RESULTS → PLANNING:<br/>• Click continue<br/>• Next day setup"]
        
        TransitionEffects["TRANSITION EFFECTS:<br/>• Fade to black (0.5s)<br/>• Reset positions<br/>• Clear buffers<br/>• Update UI<br/>• Play sound<br/>• Network sync"]
        
        TransitionValidation["VALIDATION:<br/>• All players ready?<br/>• State saved?<br/>• Network synced?<br/>• Resources loaded?<br/>• No active inputs?"]
    end

    subgraph TimeUI ["🎮 TIME UI ELEMENTS"]
        ClockDisplay["CLOCK DISPLAY:<br/>• Digital time (10:30 AM)<br/>• Sun position arc<br/>• Day counter<br/>• Week indicator<br/>• Phase name"]
        
        CountdownUI["COUNTDOWN UI:<br/>• Full screen overlay<br/>• Large numbers<br/>• Pulse effect<br/>• Cancel button<br/>• Audio countdown"]
        
        PressureIndicators["PRESSURE INDICATORS:<br/>• Last hour: Yellow clock<br/>• Last 30min: Orange pulse<br/>• Last 10min: Red flash<br/>• Last minute: Siren<br/>• Screen shake at 10s"]
    end

    subgraph DifficultyScaling ["📈 DIFFICULTY SCALING"]
        WeeklyScaling["WEEKLY SCALING:<br/>• Contract requirements +50%<br/>• Time pressure +20%<br/>• Event frequency +30%<br/>• Disaster chance +15%<br/>• Prices increase 25%<br/>• Quality demands up"]
        
        DynamicDifficulty["DYNAMIC ADJUST:<br/>• Track performance<br/>• Adjust next day<br/>• Never decrease<br/>• Cap at 200%<br/>• Assist mode: -20%"]
        
        EndgameChallenge["WEEK 4 CHAOS:<br/>• Multiple disasters<br/>• Impossible contracts<br/>• Constant events<br/>• No breaks<br/>• Pure survival<br/>• Innovation rewards"]
    end

    %% Connections
    TimeData --> PhaseSystem
    PhaseSystem --> DayLengths --> WeekProgression --> TimeFlow
    
    EventCore --> EventSchedule --> EventQueue
    
    WeatherTypes --> WeatherEffects --> WeatherProbability
    
    EventContracts --> NPCVisitors --> EventRewards
    
    DisasterTypes --> DisasterMitigation --> DisasterTiming
    
    TransitionFlow --> TransitionEffects --> TransitionValidation
    
    ClockDisplay & CountdownUI & PressureIndicators --> TimeUI
    
    WeeklyScaling --> DynamicDifficulty --> EndgameChallenge
	
Implementation Priority:

TimeManager.gd - Core time system (Autoload #4)
PhaseController.gd - Phase transitions
EventManager.gd - Event system (Autoload #5)
DayNightCycle.gd - Time progression
WeatherController.gd - Weather events
EventScheduler.gd - Event timing
DisasterEvent.gd - Disaster system
NPCBase.gd - NPC visitors

Key Implementation Notes:

Time only flows during FARMING phase
Planning phase has infinite time
Events scheduled by game hour (6-18)
Flash contract ALWAYS at 12PM
Weather lasts 2-5 minutes
Week 4 is intentionally overwhelming
All timers respect time_scale for debugging
Phase transitions require network sync