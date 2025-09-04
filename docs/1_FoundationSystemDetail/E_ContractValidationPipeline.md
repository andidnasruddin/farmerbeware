flowchart LR
    subgraph Implementation ["🔧 IMPLEMENTATION STRUCTURE"]
        ContractValidator["ContractValidator.gd:<br/>---<br/>func validate_item(item, contract) -> bool<br/>func check_quality(item, min) -> bool<br/>func check_special_requirements(item, contract) -> bool<br/>func calculate_value(item, contract) -> int"]
        
        DeliveryBox["DeliveryBox.gd:<br/>---<br/>var escrow_items: Dictionary<br/>var pending_contracts: Array<br/>---<br/>func open_ui(player)<br/>func submit_item(contract_id, item)<br/>func process_pickup()<br/>func calculate_payments()"]
        
        ContractTracker["ContractTracker.gd:<br/>---<br/>func update_progress(contract)<br/>func check_completion(contract)<br/>func trigger_failure(contract)<br/>func apply_insurance()<br/>func end_run(reason)"]
        
        ContractUI["ContractUI.gd:<br/>---<br/>func show_delivery_options(item)<br/>func update_progress_bars()<br/>func flash_warning(contract)<br/>func show_completion_effects()"]
    end

    DeliveryBox --> ContractValidator
    ContractValidator --> ContractTracker
    ContractTracker --> ContractUI
    ContractUI --> DeliveryBox
	
flowchart TB
    subgraph ContractStructure ["📋 CONTRACT DATA STRUCTURE"]
        subgraph ContractTypes ["Contract Categories"]
            NormalContract["NORMAL CONTRACTS:<br/>• Max 3 active<br/>• 1-3 day deadline<br/>• Choose from 5 daily<br/>• Can cancel (penalty)<br/>• Various difficulties"]
            
            FlashContract["FLASH CONTRACT:<br/>• MANDATORY at 12PM<br/>• Same-day deadline<br/>• Cannot refuse<br/>• 2x reward<br/>• Heavy penalties"]
            
            NPCContract["NPC CONTRACTS:<br/>• Random visitors<br/>• Same-day deadline<br/>• Can decline<br/>• Doesn't count to 3<br/>• Relationship bonus"]
            
            EventContract["EVENT CONTRACTS:<br/>• Story-driven<br/>• Special requirements<br/>• Innovation Points<br/>• Unique rewards<br/>• Can fail"]
        end

        subgraph RequirementData ["Requirement Structure"]
            ItemRequirement["ITEM REQUIREMENT:<br/>• item_type: String<br/>• quantity_needed: int<br/>• quantity_delivered: int<br/>• min_quality: int (0-4)<br/>• fertilizer_type: String<br/>• is_processed: bool"]
            
            ContractState["CONTRACT STATE:<br/>• is_active: bool<br/>• time_remaining: float<br/>• completion_percent: float<br/>• items_validated: Array<br/>• payment_pending: int"]
        end
    end

    subgraph DeliveryFlow ["📦 DELIVERY BOX INTERACTION"]
        subgraph ItemSubmission ["Item Submission"]
            ApproachBox["APPROACH BOX:<br/>• Player near delivery<br/>• Has item in hand<br/>• Press E to interact<br/>• Opens UI"]
            
            DeliveryUI["DELIVERY UI:<br/>• Shows active contracts<br/>• Item preview panel<br/>• Quality indicator<br/>• Match indicators<br/>• 'Fulfill' buttons<br/>• 'Sell at 75%' option"]
            
            ItemValidation["VALIDATE ITEM:<br/>• Check type match<br/>• Check quality ≥ min<br/>• Check fertilizer type<br/>• Check processed state<br/>• Show accept/reject"]
        end

        subgraph ContractMatching ["Contract Matching"]
            PriorityOrder["PRIORITY ORDER:<br/>1. Flash contract<br/>2. Expiring soon<br/>3. NPC contracts<br/>4. Normal contracts<br/>5. Higher payment"]
            
            MultiMatch["MULTI-MATCH:<br/>• Item fits multiple?<br/>• Show all options<br/>• Player chooses<br/>• Or auto-assign"]
            
            PartialFulfill["PARTIAL FULFILLMENT:<br/>• Accept any amount<br/>• Update progress<br/>• Hold in escrow<br/>• Can't retrieve"]
        end
    end

    subgraph ValidationPipeline ["✅ VALIDATION PIPELINE"]
        subgraph StageOne ["Stage 1: Item Validation"]
            TypeCheck["TYPE CHECK:<br/>• Exact match required<br/>• 'tomato' = 'tomato'<br/>• No substitutions<br/>• Case sensitive"]
            
            QualityCheck["QUALITY CHECK:<br/>• Calculate item quality<br/>• Compare to minimum<br/>• 0=Bad to 4=Perfect<br/>• Must meet or exceed"]
            
            SpecialCheck["SPECIAL CHECKS:<br/>• Organic vs Synthetic<br/>• Processing state<br/>• Freshness (if applicable)<br/>• Special variants"]
        end

        subgraph StageTwo ["Stage 2: Quantity Tracking"]
            AddToContract["ADD TO CONTRACT:<br/>• Increment delivered<br/>• Update progress %<br/>• Store item reference<br/>• Calculate value"]
            
            CheckCompletion["CHECK COMPLETION:<br/>• All requirements met?<br/>• All quantities filled?<br/>• All qualities satisfied?<br/>• Mark as complete"]
            
            EscrowItems["ESCROW ITEMS:<br/>• Hold until pickup<br/>• Cannot retrieve<br/>• Destroyed on pickup<br/>• Value calculated"]
        end

        subgraph StageThree ["Stage 3: Completion"]
            TruckPickup["TRUCK PICKUP:<br/>• 12PM & 6PM daily<br/>• Collects all escrow<br/>• Validates contracts<br/>• Pays completion"]
            
            PaymentCalc["PAYMENT CALCULATION:<br/>• Base payment<br/>• Quality bonus<br/>• Time bonus<br/>• Reputation multiplier<br/>• Flash multiplier"]
            
            ReputationUpdate["REPUTATION UPDATE:<br/>• Success: +2-5<br/>• Perfect quality: +1<br/>• Failure: -5 to -20<br/>• Update immediately"]
        end
    end

    subgraph FailureHandling ["💀 FAILURE CASCADE"]
        subgraph FailureTriggers ["Failure Triggers"]
            TimeExpired["TIME EXPIRED:<br/>• Deadline passed<br/>• No items delivered<br/>• Instant failure<br/>• Cannot recover"]
            
            MandatoryFail["MANDATORY FAIL:<br/>• Flash not completed<br/>• Day 1 contract ignored<br/>• Critical story fail"]
            
            InsufficientQuality["QUALITY FAIL:<br/>• All items too low<br/>• Cannot meet minimum<br/>• Last minute discovery"]
        end

        subgraph FailureConsequences ["Consequences"]
            NormalFail["NORMAL CONTRACT:<br/>• -5 reputation<br/>• No payment<br/>• Warning message<br/>• Can continue"]
            
            FlashFail["FLASH FAILURE:<br/>• -20 reputation<br/>• -$500 penalty<br/>• Major setback<br/>• Screen shake"]
            
            RunEnd["RUN ENDING:<br/>• GAME OVER<br/>• Return to lobby<br/>• Keep Innovation Pts<br/>• Show failure cause"]
        end

        subgraph Insurance ["Insurance System"]
            InsuranceUse["INSURANCE USE:<br/>• Prevents game over<br/>• Once per week<br/>• Max 2 per run<br/>• $1000 cost<br/>• -10 reputation"]
            
            InsuranceCheck["CHECK INSURANCE:<br/>• Has uses left?<br/>• Auto-trigger<br/>• Show notification<br/>• Continue run"]
        end
    end

    subgraph NetworkValidation ["🌐 NETWORK SYNC"]
        ClientRequest["CLIENT REQUEST:<br/>• submit_item(contract_id, item)<br/>• Includes quality data<br/>• Timestamp included<br/>• Awaits response"]
        
        HostValidation["HOST VALIDATES:<br/>• Verify item exists<br/>• Check requirements<br/>• Update contract<br/>• Calculate payment<br/>• Broadcast result"]
        
        SyncState["SYNC STATE:<br/>• All see same progress<br/>• Shared contract list<br/>• Unified reputation<br/>• Same money pool"]
    end

    subgraph EdgeCases ["⚠️ SPECIAL CASES"]
        OverDelivery["OVER-DELIVERY:<br/>• Extra items ignored<br/>• No bonus payment<br/>• Can't retrieve<br/>• Wasted resources"]
        
        WrongContract["WRONG CONTRACT:<br/>• Delivered to wrong one<br/>• Cannot undo<br/>• Items lost<br/>• Player mistake"]
        
        LastMinute["LAST MINUTE:<br/>• <30 seconds left<br/>• UI flashing red<br/>• Siren sound<br/>• Panic mode<br/>• Rush to deliver"]
        
        SimultaneousComplete["SIMULTANEOUS:<br/>• Multiple complete at once<br/>• Process in order<br/>• Stack bonuses<br/>• Chain particles"]
    end

    %% Flow connections
    ApproachBox --> DeliveryUI --> ItemValidation
    ItemValidation --> PriorityOrder
    PriorityOrder --> MultiMatch --> PartialFulfill
    
    PartialFulfill --> TypeCheck
    TypeCheck --> QualityCheck --> SpecialCheck
    
    SpecialCheck --> AddToContract
    AddToContract --> CheckCompletion --> EscrowItems
    
    EscrowItems --> TruckPickup
    TruckPickup --> PaymentCalc --> ReputationUpdate
    
    TimeExpired --> NormalFail
    MandatoryFail --> FlashFail
    FlashFail --> RunEnd
    RunEnd --> InsuranceCheck
    InsuranceCheck --> InsuranceUse
    
    ClientRequest --> HostValidation --> SyncState