res://
├── scenes/
│   ├── crops/
│   │   ├── base/
│   │   │   └── Crop.tscn          # Base crop scene
│   │   │
│   │   ├── tier1/
│   │   │   ├── Lettuce.tscn
│   │   │   ├── Corn.tscn
│   │   │   └── Wheat.tscn
│   │   │
│   │   ├── tier2/
│   │   │   ├── Tomato.tscn
│   │   │   └── Potato.tscn
│   │   │
│   │   ├── tier3/
│   │   │   ├── Pumpkin.tscn
│   │   │   └── Strawberry.tscn
│   │   │
│   │   └── tier4/
│   │       └── Watermelon.tscn
│   │
│   └── effects/
│       ├── WaterIndicator.tscn
│       ├── QualityStars.tscn
│       └── CropParticles.tscn
│
├── scripts/
│   ├── managers/
│   │   └── CropManager.gd         # Autoload #6
│   │
│   ├── crops/
│   │   ├── Crop.gd                # Base crop controller
│   │   ├── CropGrowth.gd          # Growth logic
│   │   ├── CropQuality.gd         # Quality calculator
│   │   ├── CropWater.gd           # Water management
│   │   ├── CropHarvest.gd         # Harvest logic
│   │   └── CropVisuals.gd         # Visual updates
│   │
│   ├── quality/
│   │   ├── QualityCalculator.gd   # Main quality system
│   │   ├── SoilQuality.gd         # Soil contribution
│   │   ├── WaterQuality.gd        # Water contribution
│   │   └── CareQuality.gd         # Care contribution
│   │
│   ├── disease/
│   │   ├── DiseaseManager.gd      # Disease system
│   │   ├── DiseaseTypes.gd        # Disease definitions
│   │   └── DiseaseSpread.gd       # Spread mechanics
│   │
│   └── special/
│       ├── GiantCropManager.gd    # 3x3 formations
│       ├── SeasonalCrops.gd       # Event crops
│       └── MagicCrops.gd          # Unlockable crops
│
├── resources/
│   ├── crops/
│   │   ├── tier1/
│   │   │   ├── lettuce.tres       # CropData resource
│   │   │   ├── corn.tres
│   │   │   └── wheat.tres
│   │   │
│   │   ├── tier2/
│   │   │   ├── tomato.tres
│   │   │   └── potato.tres
│   │   │
│   │   ├── tier3/
│   │   │   ├── pumpkin.tres
│   │   │   └── strawberry.tres
│   │   │
│   │   └── special/
│   │       ├── golden_wheat.tres
│   │       └── crystal_berry.tres
│   │
│   └── diseases/
│       ├── blight.tres
│       ├── root_rot.tres
│       └── pests.tres
│
└── assets/
    ├── sprites/
    │   ├── crops/
    │   │   ├── lettuce/
    │   │   │   ├── stage_0.png    # Seed
    │   │   │   ├── stage_1.png    # Sprout
    │   │   │   ├── stage_2.png    # Growing
    │   │   │   ├── stage_3.png    # Flowering
    │   │   │   ├── stage_4.png    # Ready
    │   │   │   └── stage_5.png    # Overripe
    │   │   │
    │   │   └── [other crops]/
    │   │
    │   ├── indicators/
    │   │   ├── water_drop.png
    │   │   ├── quality_star.png
    │   │   └── ready_glow.png
    │   │
    │   └── diseases/
    │       ├── blight_overlay.png
    │       └── pest_damage.png
    │
    └── sounds/
        ├── growth/
        │   ├── plant_seed.ogg
        │   ├── stage_up.ogg
        │   └── ready_ding.ogg
        │
        └── harvest/
            ├── harvest_normal.ogg
            ├── harvest_perfect.ogg
            └── crop_die.ogg

flowchart TB
    subgraph CropCore ["🌾 CROP SYSTEM CORE"]
        subgraph CropManager ["Crop Manager (Autoload #6)"]
            ManagerData["CropManager.gd<br/>---<br/>PROPERTIES:<br/>• all_crops: Dictionary{Vector2i: Crop}<br/>• crop_scenes: Dictionary{String: PackedScene}<br/>• growth_timers: Array[Crop]<br/>• quality_calculator: QualityCalc<br/>• harvest_stats: Dictionary<br/>---<br/>SIGNALS:<br/>• crop_planted(pos, type)<br/>• crop_grown(pos, stage)<br/>• crop_ready(pos)<br/>• crop_harvested(pos, quality)<br/>• crop_died(pos)"]
            
            CropRegistry["CROP REGISTRY:<br/>• Lettuce (Tier 1, 30s)<br/>• Corn (Tier 1, 60s)<br/>• Wheat (Tier 1, 60s)<br/>• Tomato (Tier 2, 90s)<br/>• Potato (Tier 2, 90s)<br/>• Pumpkin (Tier 3, 180s)<br/>• Strawberry (Tier 3, 120s)<br/>• Watermelon (Tier 4, 240s)"]
        end

        subgraph CropData ["Crop Data Structure"]
            CropResource["CropData.gd (Resource)<br/>---<br/>IDENTITY:<br/>• crop_name: String<br/>• crop_id: String<br/>• tier: int (1-4)<br/>• icon: Texture2D<br/>• description: String"]
            
            GrowthData["GROWTH DATA:<br/>• growth_time: float<br/>• stage_times: Array[float]<br/>• growth_textures: Array[Texture2D]<br/>• water_intervals: Array[float]<br/>• water_window: float (15s)<br/>• overripe_time: float (30s)<br/>• death_time: float (60s)"]
            
            Requirements["REQUIREMENTS:<br/>• water_needs: int (1-4)<br/>• nitrogen_consumption: float<br/>• phosphorus_consumption: float<br/>• potassium_consumption: float<br/>• optimal_ph: float (6.0-7.5)<br/>• ph_tolerance: float (±1.0)<br/>• min_temperature: float<br/>• max_temperature: float"]
            
            ValueData["VALUE DATA:<br/>• base_value: int<br/>• quality_multipliers: Array[float]<br/>• processed_value: float (2x)<br/>• market_demand: float<br/>• special_properties: Array[String]"]
        end
    end

    subgraph GrowthSystem ["🌱 GROWTH SYSTEM"]
        GrowthStages["GROWTH STAGES:<br/>---<br/>0: SEED (0-20%)<br/>1: SPROUTING (20-40%)<br/>2: GROWING (40-60%)<br/>3: FLOWERING (60-80%)<br/>4: READY (80-100%)<br/>5: OVERRIPE (100%+30s)<br/>6: DEAD (overripe+60s)"]
        
        GrowthModifiers["GROWTH MODIFIERS:<br/>• Watered: +20% speed<br/>• Fertilized: +15% speed<br/>• Perfect NPK: +10% speed<br/>• Wrong pH: -30% speed<br/>• No water: -50% speed<br/>• Disease: -40% speed<br/>• Weather events: ±25%"]
        
        MultiHarvest["MULTI-HARVEST CROPS:<br/>• Tomatoes: 3 harvests<br/>• Strawberries: 4 harvests<br/>• Regrow at 70% progress<br/>• Quality improves each time<br/>• Eventually exhausts"]
    end

    subgraph QualitySystem ["⭐ QUALITY DETERMINATION"]
        QualityFactors["QUALITY FACTORS:<br/>---<br/>SOIL (40% weight):<br/>• NPK levels<br/>• pH match<br/>• Organic matter<br/>• No contamination<br/>---<br/>WATER (30% weight):<br/>• Timing accuracy<br/>• Never dried out<br/>• Not overwatered<br/>---<br/>CARE (20% weight):<br/>• Fertilizer type<br/>• Disease prevention<br/>• Harvest timing<br/>---<br/>LUCK (10% weight):<br/>• Weather bonus<br/>• Random events"]
        
        QualityTiers["QUALITY TIERS:<br/>---<br/>0: DEAD (0 value)<br/>1: BAD (25% value)<br/>2: NORMAL (50% value)<br/>3: GOOD (75% value)<br/>4: GREAT (100% value)<br/>5: PERFECT (150% value)"]
        
        OrganicBonus["ORGANIC BONUS:<br/>• Organic fertilizer only<br/>• No pesticides<br/>• +1 quality tier<br/>• Special market price<br/>• Contract requirement"]
    end

    subgraph WateringSystem ["💧 WATERING MECHANICS"]
        WaterNeeds["WATER REQUIREMENTS:<br/>• Check water_intervals<br/>• Show indicator at need<br/>• 15 second window<br/>• Miss = quality penalty<br/>• Visual wilting"]
        
        WaterMechanics["WATER APPLICATION:<br/>• +25 water per action<br/>• Area: 1x1 (base) or 3x1<br/>• Sprinkler: 5x5 auto<br/>• Rain: free water<br/>• Overwater damage"]
        
        MoisturePhysics["MOISTURE PHYSICS:<br/>• Evaporation: -5/minute<br/>• Heat wave: -10/minute<br/>• Rain: +50 instant<br/>• Retention by soil type<br/>• Visual: soil darkness"]
    end

    subgraph HarvestSystem ["🌾 HARVEST MECHANICS"]
        HarvestWindow["HARVEST TIMING:<br/>• Ready indicator (glow)<br/>• Optimal: 100% growth<br/>• Early: -1 quality<br/>• Perfect: first 10 sec<br/>• Overripe: -1 per 30s"]
        
        HarvestProcess["HARVEST PROCESS:<br/>1. Check if ready<br/>2. Calculate quality<br/>3. Apply tool bonus<br/>4. Create item drop<br/>5. Clear/regrow tile<br/>6. Update statistics<br/>7. Check contracts"]
        
        BulkHarvest["BULK HARVEST:<br/>• Upgraded harvester<br/>• 3x3 area<br/>• Queue animations<br/>• Batch quality calc<br/>• Single network sync"]
    end

    subgraph CropNode ["🎮 CROP NODE SCENE"]
        CropScene["Crop.gd (Node2D)<br/>---<br/>PROPERTIES:<br/>• crop_data: CropData<br/>• growth_progress: float<br/>• current_stage: int<br/>• quality: int<br/>• water_count: int<br/>• is_watered: bool<br/>• is_ready: bool<br/>• times_harvested: int"]
        
        CropComponents["COMPONENTS:<br/>• Sprite2D (growth visuals)<br/>• ProgressBar (debug)<br/>• WaterIndicator (icon)<br/>• QualityStars (preview)<br/>• Area2D (interaction)<br/>• CPUParticles2D (effects)"]
        
        CropSignals["SIGNALS:<br/>• stage_changed(stage)<br/>• needs_water()<br/>• ready_to_harvest()<br/>• quality_changed(quality)<br/>• crop_died()"]
    end

    subgraph DiseaseSystem ["🦠 DISEASE & PESTS"]
        DiseaseTypes["DISEASES:<br/>• Blight (spreads 3x3)<br/>• Root rot (water damage)<br/>• Pests (random attack)<br/>• Frost damage (cold)<br/>• Heat stress (drought)"]
        
        DiseasePrevention["PREVENTION:<br/>• Crop rotation<br/>• Pesticides (-quality)<br/>• Organic methods<br/>• Quarantine zones<br/>• Resistant varieties"]
        
        DiseaseSpread["SPREAD MECHANICS:<br/>• 5% base chance<br/>• Adjacent tiles +10%<br/>• Same crop +15%<br/>• Contaminated -2 quality<br/>• Can kill crops"]
    end

    subgraph SpecialCrops ["🌟 SPECIAL MECHANICS"]
        SeasonalCrops["SEASONAL CROPS:<br/>• Some only in events<br/>• Holiday specials<br/>• Limited time seeds<br/>• Premium prices<br/>• Unique visuals"]
        
        GiantCrops["GIANT CROPS:<br/>• 3x3 formation<br/>• Same crop type<br/>• Perfect quality<br/>• Rare chance (1%)<br/>• 10x value"]
        
        MagicCrops["MAGIC CROPS (Unlocks):<br/>• Golden wheat<br/>• Crystal berries<br/>• Phoenix peppers<br/>• Special properties<br/>• Innovation unlocks"]
    end

    %% Connections
    ManagerData --> CropRegistry
    CropResource --> GrowthData & Requirements & ValueData
    
    GrowthStages --> GrowthModifiers --> MultiHarvest
    
    QualityFactors --> QualityTiers --> OrganicBonus
    
    WaterNeeds --> WaterMechanics --> MoisturePhysics
    
    HarvestWindow --> HarvestProcess --> BulkHarvest
    
    CropScene --> CropComponents --> CropSignals
    
    DiseaseTypes --> DiseasePrevention --> DiseaseSpread
    
    SeasonalCrops & GiantCrops & MagicCrops --> CropRegistry
	
Implementation Priority:

CropManager.gd - Central management (Autoload #6)
CropData.gd - Resource structure
Crop.gd - Base crop node
CropGrowth.gd - Growth mechanics
QualityCalculator.gd - Quality system
CropWater.gd - Water requirements
DiseaseManager.gd - Disease system
GiantCropManager.gd - Special features

Key Implementation Notes:

Crops are Node2D scenes instantiated at grid positions
Growth is float 0.0-1.0, stages determined by thresholds
Quality calculated on harvest, not during growth
Water timing windows are strict (15 seconds)
Multi-harvest crops regrow from 70% progress
Disease spreads to adjacent tiles of same crop
Giant crops require 3x3 perfect quality formation
All timings affected by global time scale