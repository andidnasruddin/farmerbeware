res://
├── scenes/
│   ├── contracts/
│   │   ├── ContractCard.tscn      # UI card display
│   │   ├── ContractBoard.tscn     # Computer UI
│   │   ├── DeliveryBox.tscn       # Physical box
│   │   ├── DeliveryUI.tscn        # Delivery interface
│   │   ├── DeliveryTruck.tscn     # Animated truck
│   │   └── FlashAlert.tscn        # Flash contract UI
│   │
│   ├── npcs/
│   │   ├── NPCBaker.tscn
│   │   ├── NPCChef.tscn
│   │   ├── NPCMerchant.tscn
│   │   └── NPCMayor.tscn
│   │
│   └── market/
│       ├── WeekendMarket.tscn     # Market minigame
│       ├── MarketCustomer.tscn    # Customer NPCs
│       └── MarketCounter.tscn     # Serving area
│
├── scripts/
│   ├── managers/
│   │   └── ContractManager.gd     # Autoload #8
│   │
│   ├── contracts/
│   │   ├── ContractData.gd        # Resource class
│   │   ├── ContractGenerator.gd   # Daily generation
│   │   ├── ContractValidator.gd   # Item validation
│   │   ├── ContractTracker.gd     # Progress tracking
│   │   ├── FlashContract.gd       # Flash mechanics
│   │   └── NPCContract.gd         # NPC contracts
│   │
│   ├── delivery/
│   │   ├── DeliveryBox.gd         # Box mechanics
│   │   ├── DeliveryUI.gd          # Interface
│   │   ├── DeliveryTruck.gd       # Truck animation
│   │   └── EscrowSystem.gd        # Item holding
│   │
│   ├── reputation/
│   │   ├── ReputationManager.gd   # Rep tracking
│   │   ├── ReputationEffects.gd   # Apply modifiers
│   │   └── RelationshipTracker.gd # NPC hearts
│   │
│   ├── market/
│   │   ├── WeekendMarket.gd       # Market game
│   │   ├── MarketCustomer.gd      # Customer AI
│   │   └── MarketScore.gd         # Scoring
│   │
│   └── insurance/
│       └── InsuranceSystem.gd     # Failure prevention
│
├── resources/
│   ├── contracts/
│   │   ├── week1/
│   │   │   ├── basic_vegetables.tres
│   │   │   ├── simple_grain.tres
│   │   │   └── easy_mixed.tres
│   │   │
│   │   ├── week2/
│   │   │   ├── quality_produce.tres
│   │   │   ├── processed_goods.tres
│   │   │   └── timed_delivery.tres
│   │   │
│   │   ├── week3/
│   │   │   ├── complex_combo.tres
│   │   │   ├── perfect_quality.tres
│   │   │   └── bulk_order.tres
│   │   │
│   │   ├── week4/
│   │   │   ├── impossible_mix.tres
│   │   │   ├── extreme_time.tres
│   │   │   └── chaos_contract.tres
│   │   │
│   │   ├── flash/
│   │   │   ├── flash_templates.tres
│   │   │   └── flash_scaling.tres
│   │   │
│   │   └── events/
│   │       ├── mayors_birthday.tres
│   │       ├── harvest_festival.tres
│   │       └── [8 more events].tres
│   │
│   └── npcs/
│       ├── baker_data.tres
│       ├── chef_data.tres
│       ├── merchant_data.tres
│       └── mayor_data.tres
│
└── assets/
    ├── sprites/
    │   ├── ui/
    │   │   ├── contract_card.png
    │   │   ├── delivery_box.png
    │   │   ├── truck_sprite.png
    │   │   └── flash_alert.png
    │   │
    │   ├── icons/
    │   │   ├── contract_icons.png
    │   │   ├── quality_stars.png
    │   │   └── reputation_bar.png
    │   │
    │   └── market/
    │       ├── market_stall.png
    │       ├── customer_sprites.png
    │       └── counter.png
    │
    └── sounds/
        ├── contracts/
        │   ├── contract_accept.ogg
        │   ├── contract_complete.ogg
        │   ├── contract_fail.ogg
        │   └── flash_alarm.ogg
        │
        ├── delivery/
        │   ├── box_open.ogg
        │   ├── item_place.ogg
        │   └── truck_arrive.ogg
        │
        └── market/
            ├── customer_order.ogg
            ├── cash_register.ogg
            └── market_ambience.ogg
			
flowchart TB
    subgraph ContractCore ["📋 CONTRACT SYSTEM CORE"]
        subgraph ContractManager ["Contract Manager (Autoload #8)"]
            ManagerData["ContractManager.gd<br/>---<br/>PROPERTIES:<br/>• active_contracts: Array (max 3)<br/>• available_contracts: Array (5 daily)<br/>• flash_contract: Contract<br/>• npc_contracts: Array<br/>• reputation: int (0-100)<br/>• insurance_uses: int (max 2)<br/>• completed_today: Array<br/>---<br/>SIGNALS:<br/>• contract_available(contract)<br/>• contract_accepted(contract)<br/>• contract_completed(contract)<br/>• contract_failed(contract)<br/>• flash_contract_appeared(contract)<br/>• reputation_changed(value)<br/>• game_over(reason)"]
            
            ContractTypes["CONTRACT TYPES:<br/>---<br/>NORMAL: 3 mandatory daily<br/>FLASH: 12PM, MUST complete<br/>NPC: Optional same-day<br/>EVENT: Story contracts<br/>---<br/>All require exact amounts<br/>No partial credit<br/>Quality requirements strict"]
        end

        subgraph ContractData ["Contract Structure"]
            ContractResource["ContractData.gd (Resource)<br/>---<br/>IDENTITY:<br/>• contract_name: String<br/>• contract_id: String<br/>• client_name: String<br/>• difficulty: int (1-4)<br/>• type: ContractType<br/>• icon: Texture2D"]
            
            Requirements["REQUIREMENTS:<br/>• items: Array[ItemReq]<br/>• quantities: Array[int]<br/>• min_quality: Array[int]<br/>• fertilizer_type: String<br/>• is_processed: Array[bool]<br/>• deadline: float (seconds)<br/>• is_combo: bool"]
            
            Rewards["REWARDS:<br/>• base_payment: int<br/>• reputation_gain: int<br/>• reputation_loss: int<br/>• innovation_points: int<br/>• bonus_items: Array<br/>• perfect_bonus: float"]
        end
    end

    subgraph DeliverySystem ["📦 DELIVERY BOX SYSTEM"]
        DeliveryBox["DELIVERY BOX:<br/>• Single location<br/>• Holds all contracts<br/>• No retrieval allowed<br/>• Items in escrow<br/>• Visual feedback"]
        
        DeliveryUI["DELIVERY UI:<br/>• Shows active contracts<br/>• Item in hand preview<br/>• Quality indicator<br/>• Match visualization<br/>• 'Fulfill' buttons<br/>• 'Sell at 75%' option"]
        
        DeliveryTruck["TRUCK SCHEDULE:<br/>• 11:55 AM arrival<br/>• 12:00 PM pickup<br/>• 5:55 PM arrival<br/>• 6:00 PM pickup<br/>• Animation sequence<br/>• Collects escrow"]
        
        ValidationPipeline["VALIDATION:<br/>1. Check item type<br/>2. Verify quality ≥ min<br/>3. Check fertilizer<br/>4. Verify processed<br/>5. Add to escrow<br/>6. Update progress<br/>7. Cannot retrieve"]
    end

    subgraph FlashContracts ["⚡ FLASH CONTRACT SYSTEM"]
        FlashMechanics["FLASH MECHANICS:<br/>• Spawns at 12:00 PM<br/>• MANDATORY - cannot refuse<br/>• Full screen alert<br/>• Alarm sound<br/>• Same-day deadline<br/>• 2x normal difficulty<br/>• Override 3-limit"]
        
        FlashPenalties["FLASH PENALTIES:<br/>• MUST COMPLETE<br/>• -20 reputation<br/>• -$500 money<br/>• Major setback<br/>• Cannot insure<br/>• Screen effects<br/>• Panic music"]
        
        FlashWarning["WARNING SYSTEM:<br/>• 11:45 AM: 15s warning<br/>• 11:50 AM: Prepare alert<br/>• 11:55 AM: Final warning<br/>• 12:00 PM: FLASH APPEARS<br/>• UI takes over screen<br/>• Forces player attention"]
    end

    subgraph NPCContracts ["👥 NPC CONTRACT SYSTEM"]
        NPCTypes["NPC VISITORS:<br/>• Baker: Wheat/Flour/Bread<br/>• Chef: Quality vegetables<br/>• Farmer: Bulk crops<br/>• Merchant: Rare items<br/>• Mayor: Event contracts<br/>• Inspector: Bonuses"]
        
        NPCBehavior["NPC BEHAVIOR:<br/>• Random arrival times<br/>• Walk to farm center<br/>• Speech bubble appears<br/>• 30 second timer<br/>• Accept or decline<br/>• Leave after decision<br/>• Relationship tracking"]
        
        Relationships["RELATIONSHIPS:<br/>• 0-5 heart levels<br/>• Track per NPC<br/>• Better deals at higher<br/>• Exclusive contracts at max<br/>• Remember failures<br/>• Permanent progress"]
    end

    subgraph ReputationSystem ["⭐ REPUTATION SYSTEM"]
        RepLevels["REPUTATION TIERS:<br/>---<br/>0-20: Terrible (50% pay)<br/>21-40: Poor (75% pay)<br/>41-60: Normal (100% pay)<br/>61-80: Good (110% pay)<br/>81-100: Excellent (125% pay)"]
        
        RepChanges["REPUTATION CHANGES:<br/>• Complete: +2 to +5<br/>• Perfect quality: +1<br/>• All 3 daily: +5 bonus<br/>• Fail normal: -5<br/>• Fail flash: -20<br/>• Weekly decay: -5"]
        
        RepEffects["REPUTATION EFFECTS:<br/>• Payment multiplier<br/>• Contract availability<br/>• NPC visit frequency<br/>• Better contract terms<br/>• Weekend market prices<br/>• Special unlocks"]
    end

    subgraph DailyContracts ["📅 DAILY CONTRACT FLOW"]
        ComputerUI["COMPUTER UI:<br/>• Contract Board app<br/>• Shows 5 available<br/>• Detailed requirements<br/>• Payment preview<br/>• MUST pick 3<br/>• Accept buttons<br/>• Cancel option (-rep)"]
        
        ContractGeneration["GENERATION:<br/>• Based on week/day<br/>• Scaled to capacity<br/>• Mixed difficulties<br/>• Variety enforced<br/>• Story events added<br/>• NPC preferences"]
        
        ActiveTracking["ACTIVE TRACKING:<br/>• Progress bars<br/>• Time remaining<br/>• Items needed<br/>• Quality stars<br/>• Pulse when urgent<br/>• Red when critical"]
    end

    subgraph FailureSystem ["💀 FAILURE & INSURANCE"]
        FailureTypes["FAILURE TRIGGERS:<br/>• Time expired<br/>• Wrong quality<br/>• Wrong quantity<br/>• Flash not done<br/>• Mandatory ignored"]
        
        GameOver["GAME OVER:<br/>• Any mandatory fail<br/>• Return to lobby<br/>• Keep Innovation Pts<br/>• Lose run progress<br/>• Must restart"]
        
        Insurance["INSURANCE:<br/>• $1000 per use<br/>• Max 2 per run<br/>• Buy at computer<br/>• Prevents game over<br/>• -10 reputation<br/>• Once per week<br/>• Auto-triggers"]
    end

    subgraph WeekendMarket ["🏪 WEEKEND MARKET"]
        MarketMinigame["MARKET MINIGAME:<br/>• Overcooked-style<br/>• Customers at counter<br/>• Timed requests<br/>• Deliver items<br/>• Tips for speed<br/>• Reputation matters"]
        
        MarketSkip["SKIP OPTION:<br/>• Auto-sell all<br/>• Rep + random %<br/>• -10% value penalty<br/>• No tips earned<br/>• Instant complete<br/>• Still clears inventory"]
        
        MarketResults["RESULTS:<br/>• All items sold<br/>• Bonus for playing<br/>• Tips added<br/>• Rep bonus<br/>• Clear for Monday"]
    end

    subgraph EventContracts ["🎭 10 EVENT CONTRACTS"]
        EventList["STORY EVENTS:<br/>1. Mayor's Birthday (cake + party items)<br/>2. Harvest Festival (variety pack)<br/>3. School Lunch (bulk vegetables)<br/>4. Restaurant Opening (premium quality)<br/>5. Disaster Relief (quick response)<br/>6. Wedding Catering (perfect quality)<br/>7. Science Fair (unique crops)<br/>8. Hospital Donation (organic only)<br/>9. Town BBQ (processed goods)<br/>10. Winter Prep (preserved items)"]
        
        EventRewards["EVENT REWARDS:<br/>• Innovation Points (5-10)<br/>• Temporary buffs<br/>• Unique decorations<br/>• NPC friendship<br/>• Story progression<br/>• Special seeds<br/>• Achievements"]
    end

    %% Connections
    ManagerData --> ContractTypes
    ContractResource --> Requirements --> Rewards
    
    DeliveryBox --> DeliveryUI --> DeliveryTruck --> ValidationPipeline
    
    FlashMechanics --> FlashPenalties --> FlashWarning
    
    NPCTypes --> NPCBehavior --> Relationships
    
    RepLevels --> RepChanges --> RepEffects
    
    ComputerUI --> ContractGeneration --> ActiveTracking
    
    FailureTypes --> GameOver --> Insurance
    
    MarketMinigame --> MarketSkip --> MarketResults
    
    EventList --> EventRewards
	
Implementation Priority:

ContractManager.gd - Central system (Autoload #8)
ContractData.gd - Contract structure
ContractGenerator.gd - Daily generation
DeliveryBox.gd - Core delivery mechanic
ContractValidator.gd - Item validation
FlashContract.gd - Flash system (critical!)
ReputationManager.gd - Rep tracking
InsuranceSystem.gd - Failure prevention
WeekendMarket.gd - Market minigame

Key Implementation Notes:

Flash contracts are MANDATORY and cause major penalties
No partial credit - exact amounts only
Items in delivery box cannot be retrieved
3 daily contracts must be selected (not optional)
Reputation affects everything (prices, availability, NPCs)
Insurance auto-triggers on failure (if available)
Weekend market clears all inventory
Contract failure = game over (unless insured)