res://
├── user:// (Runtime - Created at runtime)
│   ├── profile.dat                # Main profile
│   ├── saves/
│   │   ├── slot_1.dat
│   │   ├── slot_1.bak
│   │   ├── slot_2.dat
│   │   ├── slot_2.bak
│   │   ├── slot_3.dat
│   │   ├── slot_3.bak
│   │   ├── slot_4.dat
│   │   ├── slot_4.bak
│   │   ├── slot_5.dat
│   │   └── slot_5.bak
│   ├── settings.cfg
│   └── stats.dat
│
├── scenes/
│   ├── save/
│   │   ├── SaveMenu.tscn          # Save slot selection
│   │   ├── SaveSlotCard.tscn      # Individual slot UI
│   │   └── CloudSyncUI.tscn       # Cloud sync status
│   │
│   ├── innovation/
│   │   ├── InnovationTree.tscn    # Full tree view
│   │   ├── TreeNode.tscn          # Individual upgrade
│   │   ├── BranchView.tscn        # Branch section
│   │   └── RespecDialog.tscn      # Respec confirmation
│   │
│   └── stats/
│       ├── StatisticsPanel.tscn   # Stats display
│       ├── AchievementList.tscn   # Achievement view
│       └── RunHistory.tscn        # Past runs
│
├── scripts/
│   ├── managers/
│   │   ├── SaveManager.gd         # Autoload #11
│   │   └── InnovationManager.gd   # Autoload #12
│   │
│   ├── save/
│   │   ├── SaveSlot.gd            # Save slot data
│   │   ├── SaveSerializer.gd      # Save/load logic
│   │   ├── SaveMigration.gd       # Version migration
│   │   ├── BackupManager.gd       # Backup rotation
│   │   ├── ChecksumValidator.gd   # Data integrity
│   │   └── CloudSyncHandler.gd    # Steam Cloud
│   │
│   ├── innovation/
│   │   ├── InnovationTree.gd      # Tree structure
│   │   ├── InnovationNode.gd      # Node logic
│   │   ├── TreeBranch.gd          # Branch management
│   │   ├── RespecHandler.gd       # Respec system
│   │   └── IPCalculator.gd        # Point calculations
│   │
│   ├── progression/
│   │   ├── UnlockManager.gd       # Permanent unlocks
│   │   ├── PrestigeSystem.gd      # Prestige logic
│   │   ├── NGPlusManager.gd       # NG+ modifiers
│   │   └── ChallengeManager.gd    # Daily/Weekly
│   │
│   └── stats/
│       ├── StatisticsTracker.gd   # Stats recording
│       ├── AchievementManager.gd  # Achievement logic
│       ├── RunRecorder.gd         # Run history
│       └── SteamStats.gd          # Steam integration
│
├── resources/
│   ├── save/
│   │   ├── save_config.tres       # Save settings
│   │   └── migration_rules.tres   # Version updates
│   │
│   ├── innovation/
│   │   ├── nodes/
│   │   │   ├── starting/
│   │   │   │   ├── extra_money.tres
│   │   │   │   └── bonus_seeds.tres
│   │   │   ├── efficiency/
│   │   │   │   ├── till_area.tres
│   │   │   │   └── water_area.tres
│   │   │   ├── contracts/
│   │   │   │   ├── extra_slot.tres
│   │   │   │   └── longer_time.tres
│   │   │   └── machines/
│   │   │       ├── faster_process.tres
│   │   │       └── quality_bonus.tres
│   │   │
│   │   └── tree_config.tres       # Tree structure
│   │
│   ├── unlocks/
│   │   ├── crops/
│   │   │   ├── golden_wheat.tres
│   │   │   └── crystal_berry.tres
│   │   ├── machines/
│   │   │   └── auto_thresher.tres
│   │   └── cosmetics/
│   │       └── hat_collection.tres
│   │
│   └── challenges/
│       ├── daily_template.tres
│       └── weekly_template.tres
│
└── assets/
    ├── sprites/
    │   ├── ui/
    │   │   ├── save_slot_bg.png
    │   │   ├── innovation_tree_bg.png
    │   │   ├── node_locked.png
    │   │   └── node_unlocked.png
    │   │
    │   └── icons/
    │       ├── innovation_points.png
    │       ├── achievement_badges.png
    │       └── prestige_stars.png
    │
    └── sounds/
        ├── save/
        │   ├── save_complete.ogg
        │   └── load_complete.ogg
        │
        └── innovation/
            ├── node_unlock.ogg
            ├── respec_confirm.ogg
            └── points_earned.ogg
			
flowchart TB
    subgraph SaveCore ["💾 SAVE SYSTEM CORE"]
        subgraph SaveManager ["Save Manager (Autoload #11)"]
            ManagerData["SaveManager.gd<br/>---<br/>PROPERTIES:<br/>• save_slots: Array[SaveSlot] (5 slots)<br/>• current_slot: int<br/>• auto_save_enabled: bool<br/>• backup_count: int (3)<br/>• save_version: String<br/>• cloud_sync: bool<br/>---<br/>SIGNALS:<br/>• save_started()<br/>• save_completed(success)<br/>• load_started()<br/>• load_completed(success)<br/>• save_corrupted(slot)"]
            
            SaveStructure["SAVE STRUCTURE:<br/>---<br/>ONE PROFILE (Steam Account)<br/>• 5 Save Slots (renameable)<br/>• Innovation Points (shared)<br/>• All Unlocks (shared)<br/>• Global Statistics<br/>• Settings (global)<br/>• Steam Cloud sync"]
        end

        subgraph SaveData ["Save Data Structure"]
            SaveSlot["SaveSlot.gd (Resource)<br/>---<br/>• slot_name: String<br/>• timestamp: String<br/>• play_time: float<br/>• current_day: int<br/>• current_week: int<br/>• money: int<br/>• checksum: String"]
            
            SavedState["SAVED STATE:<br/>• Every tile (NPK, pH, water)<br/>• All crops (stage, quality)<br/>• Machine positions/states<br/>• Inventory items<br/>• Building locations<br/>• Contract progress<br/>• Host position only (MP)"]
            
            SaveFormat["FILE FORMAT:<br/>• Plain text (JSON/tres)<br/>• Checksum validation<br/>• Version number<br/>• Timestamp<br/>• Compressed<br/>• Cloud compatible"]
        end
    end

    subgraph InnovationSystem ["⭐ INNOVATION POINTS (Meta-Progression)"]
        subgraph InnovationManager ["Innovation Manager (Autoload #12)"]
            IPCore["InnovationManager.gd<br/>---<br/>PROPERTIES:<br/>• current_points: int<br/>• spent_points: int<br/>• unlocked_nodes: Array<br/>• tree_state: Dictionary<br/>• respec_count: int<br/>---<br/>SIGNALS:<br/>• points_earned(amount)<br/>• node_unlocked(node)<br/>• respec_performed()<br/>• tree_updated()"]
            
            PointEarning["EARNING IP:<br/>• Per day survived: 1-3<br/>• Contract complete: 2<br/>• Perfect day: 5<br/>• Flash contract: 3<br/>• Story event: 5-10<br/>• Full 15-day run: 100<br/>• First discovery: 10"]
        end

        subgraph UpgradeTree ["Innovation Tree (4 Branches)"]
            StartingBranch["STARTING RESOURCES:<br/>• +$200 start money<br/>• +5 seeds day 1<br/>• Better tools<br/>• +15s planning<br/>• Free fertilizer<br/>• Extra watering can"]
            
            EfficiencyBranch["TOOL EFFICIENCY:<br/>• Till 2x1 area<br/>• Water 3x1 area<br/>• Harvest faster<br/>• No tool switch delay<br/>• Auto-tool select<br/>• Double carry"]
            
            ContractBranch["CONTRACT FLEX:<br/>• +1 active contract<br/>• +20% deadlines<br/>• +15% payments<br/>• Insurance cheaper<br/>• Rep decay -50%<br/>• Flash warning +30s"]
            
            MachineBranch["MACHINE POWER:<br/>• Process 20% faster<br/>• Quality +10%<br/>• Breakdown -50%<br/>• Auto-hoppers<br/>• Skip mini-games T1<br/>• Double output chance"]
        end

        subgraph RespecSystem ["Respec System"]
            RespecOptions["RESPEC OPTIONS:<br/>• Full reset: 50 IP<br/>• Single branch: 20 IP<br/>• Last node: Free<br/>• Keep points spent<br/>• Instant apply<br/>• Unlimited uses"]
        end
    end

    subgraph RogueliteLoop ["🔁 ROGUELITE STRUCTURE"]
        RunCycle["RUN CYCLE:<br/>1. Start Day 1, Week 1<br/>2. Apply innovations<br/>3. Play until failure<br/>4. Keep IP earned<br/>5. Return to menu<br/>6. Spend IP in tree<br/>7. Start new run"]
        
        WhatResets["ON FAILURE:<br/>---<br/>❌ RESETS:<br/>• All farm progress<br/>• Money to $1000<br/>• Contracts cleared<br/>• Day/Week counter<br/>---<br/>✅ KEEPS:<br/>• Innovation Points<br/>• Unlocked content<br/>• Statistics<br/>• Achievements"]
        
        NoSkipping["NO SHORTCUTS:<br/>• Always start Week 1<br/>• No checkpoint starts<br/>• Pure roguelite<br/>• Master full progression<br/>• Like Plate Up"]
    end

    subgraph UnlockSystem ["🔓 PERMANENT UNLOCKS"]
        CropUnlocks["CROP UNLOCKS (IP):<br/>• Golden Wheat (50 IP)<br/>• Crystal Berry (75 IP)<br/>• Phoenix Pepper (100 IP)<br/>• Rainbow Corn (125 IP)<br/>• Void Tomato (150 IP)<br/>• Account-wide"]
        
        MachineUnlocks["MACHINE UNLOCKS:<br/>• Auto-Thresher (60 IP)<br/>• Combo Oven (80 IP)<br/>• Master Press (100 IP)<br/>• Quantum Mill (120 IP)<br/>• Universal Processor (200 IP)"]
        
        CosmeticUnlocks["COSMETICS:<br/>• Hat collection<br/>• Character skins<br/>• Farm themes<br/>• Particle effects<br/>• Victory dances<br/>• Name plates"]
        
        PreviewSystem["PREVIEW SYSTEM:<br/>• Show locked items<br/>• Grayed out icons<br/>• IP cost displayed<br/>• 'Coming Soon' teaser<br/>• Motivates earning"]
    end

    subgraph SaveTiming ["⏰ SAVE TIMING"]
        AutoSave["AUTO-SAVE TRIGGERS:<br/>• End of day (6PM)<br/>• Phase transition<br/>• Contract complete<br/>• Major purchase<br/>• Before risky action<br/>• NEVER mid-day"]
        
        ManualSave["MANUAL SAVE:<br/>• Not allowed<br/>• No quick save (F5)<br/>• No save scumming<br/>• Checkpoint only<br/>• Roguelite integrity"]
        
        SaveBackup["BACKUP SYSTEM:<br/>• Keep 3 backups<br/>• Rotate on save<br/>• save.dat → save_1.bak<br/>• save_1.bak → save_2.bak<br/>• save_2.bak → save_3.bak"]
    end

    subgraph Statistics ["📊 STATISTICS TRACKING"]
        LifetimeStats["LIFETIME STATS:<br/>• Total days survived<br/>• Contracts completed<br/>• Money earned<br/>• Crops harvested<br/>• Perfect days<br/>• Co-op sessions<br/>• Machines used<br/>• Tiles farmed<br/>• Runs completed"]
        
        RunStats["PER-RUN STATS:<br/>• Best day reached<br/>• Peak money<br/>• Contracts/day<br/>• Average quality<br/>• Deaths by type<br/>• IP earned"]
        
        Achievements["STEAM ACHIEVEMENTS (50+):<br/>• First harvest<br/>• Perfect week<br/>• All crops grown<br/>• Max reputation<br/>• No insurance win<br/>• Co-op master<br/>• Speed runner"]
    end

    subgraph CloudSync ["☁️ STEAM CLOUD"]
        CloudData["CLOUD SYNC:<br/>• 100MB allocation<br/>• All saves + profile<br/>• Auto-sync on exit<br/>• Conflict resolution<br/>• Cross-computer<br/>• Version check"]
        
        ConflictResolution["CONFLICTS:<br/>• Newer wins<br/>• Local backup<br/>• User choice prompt<br/>• Never lose data<br/>• Log conflicts"]
        
        Migration["SAVE MIGRATION:<br/>• Auto-detect version<br/>• Run migration script<br/>• Update structure<br/>• Preserve progress<br/>• Legacy branch option"]
    end

    subgraph NGPlus ["➕ NEW GAME PLUS"]
        NGUnlock["NG+ UNLOCK:<br/>• Complete 15-day run<br/>• Or 3 completed runs<br/>• Account achievement<br/>• Permanent unlock"]
        
        NGModifiers["NG+ MODIFIERS:<br/>• Contracts 50% harder<br/>• Time -20% shorter<br/>• Prices +30% higher<br/>• New 'Overtime' events<br/>• Exclusive rewards<br/>• Stacks up to NG+5"]
        
        PrestigeSystem["PRESTIGE OPTION:<br/>• Reset all unlocks<br/>• Gain permanent:<br/>  +10% all earnings<br/>  +5% quality chance<br/>  +1 starting contract<br/>• Stack up to 5x"]
    end

    subgraph DailyChallenges ["🎯 DAILY/WEEKLY CHALLENGES"]
        DailyRuns["DAILY RUNS:<br/>• Fixed seed<br/>• Same for all players<br/>• Leaderboards<br/>• Small IP reward (5)<br/>• Participation bonus<br/>• 24 hour window"]
        
        WeeklyChallenges["WEEKLY CHALLENGES:<br/>• Special modifiers<br/>• Unique objectives<br/>• Bigger IP rewards (20)<br/>• Community goals<br/>• Seasonal themes"]
    end

    %% Connections
    ManagerData --> SaveStructure
    SaveSlot --> SavedState --> SaveFormat
    
    IPCore --> PointEarning
    StartingBranch & EfficiencyBranch & ContractBranch & MachineBranch --> RespecOptions
    
    RunCycle --> WhatResets --> NoSkipping
    
    CropUnlocks & MachineUnlocks & CosmeticUnlocks --> PreviewSystem
    
    AutoSave --> ManualSave --> SaveBackup
    
    LifetimeStats & RunStats --> Achievements
    
    CloudData --> ConflictResolution --> Migration
    
    NGUnlock --> NGModifiers --> PrestigeSystem
    
    DailyRuns & WeeklyChallenges --> IPCore
	
Implementation Priority:

SaveManager.gd - Core save system (Autoload #11)
InnovationManager.gd - Meta progression (Autoload #12)
SaveSerializer.gd - Save/load logic
InnovationTree.gd - Upgrade tree
ChecksumValidator.gd - Data integrity
CloudSyncHandler.gd - Steam Cloud
UnlockManager.gd - Permanent unlocks
StatisticsTracker.gd - Stats system

Key Implementation Notes:

ONE profile per Steam account (modern standard)
5 save slots, player-renameable
Saves ONLY at day end (no save scumming)
Innovation Points shared across all saves
Full reset on run failure (true roguelite)
No shortcuts - always start from Day 1
Plain text saves with checksum validation
3 rotating backups for safety
Respec available but costs IP
Steam Cloud sync essential