Farm Frenzy/
├── user:// (Runtime - Created during play)
│   ├── profile.dat                        # Main profile data
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
│   ├── settings.cfg                       # User settings
│   └── stats.dat                          # Global statistics
│
├── res:// (Project Files)
│   ├── project.godot                      # Project configuration
│   ├── icon.png                          # Game icon
│   ├── export_presets.cfg                # Export settings
│   │
│   ├── scenes/
│   │   ├── main/
│   │   │   ├── Main.tscn                 # Root scene
│   │   │   ├── Boot.tscn                 # Boot screen
│   │   │   └── GameController.tscn       # Game orchestrator
│   │   │
│   │   ├── game/
│   │   │   ├── Farm.tscn                 # Main gameplay scene
│   │   │   ├── GridSystem.tscn           # Grid foundation
│   │   │   └── Camera.tscn               # Camera controller
│   │   │
│   │   ├── player/
│   │   │   ├── Player.tscn               # Player character
│   │   │   ├── PlayerVisuals.tscn        # Sprite components
│   │   │   ├── ToolDisplay.tscn          # Tool visualization
│   │   │   └── CarryPosition.tscn        # Item hold point
│   │   │
│   │   ├── crops/
│   │   │   ├── base/
│   │   │   │   └── Crop.tscn             # Base crop scene
│   │   │   ├── tier1/
│   │   │   │   ├── Lettuce.tscn
│   │   │   │   ├── Corn.tscn
│   │   │   │   └── Wheat.tscn
│   │   │   ├── tier2/
│   │   │   │   ├── Tomato.tscn
│   │   │   │   └── Potato.tscn
│   │   │   ├── tier3/
│   │   │   │   ├── Pumpkin.tscn
│   │   │   │   └── Strawberry.tscn
│   │   │   └── tier4/
│   │   │       └── Watermelon.tscn
│   │   │
│   │   ├── machines/
│   │   │   ├── base/
│   │   │   │   ├── Machine.tscn
│   │   │   │   ├── Hopper.tscn
│   │   │   │   └── ConveyorBelt.tscn
│   │   │   ├── processing/
│   │   │   │   ├── Thresher.tscn
│   │   │   │   ├── Oven.tscn
│   │   │   │   ├── Press.tscn
│   │   │   │   ├── Mill.tscn
│   │   │   │   ├── Cutter.tscn
│   │   │   │   └── Processor.tscn
│   │   │   └── visual/
│   │   │       ├── MachineEffects.tscn
│   │   │       └── ConveyorVisuals.tscn
│   │   │
│   │   ├── minigames/
│   │   │   ├── base/
│   │   │   │   └── MiniGameBase.tscn
│   │   │   ├── games/
│   │   │   │   ├── RhythmGame.tscn
│   │   │   │   ├── TemperatureGame.tscn
│   │   │   │   ├── MashingGame.tscn
│   │   │   │   ├── RotationGame.tscn
│   │   │   │   └── PrecisionGame.tscn
│   │   │   └── coop/
│   │   │       ├── DualCrank.tscn
│   │   │       └── TempBalance.tscn
│   │   │
│   │   ├── contracts/
│   │   │   ├── ContractCard.tscn
│   │   │   ├── ContractBoard.tscn
│   │   │   ├── DeliveryBox.tscn
│   │   │   ├── DeliveryUI.tscn
│   │   │   ├── DeliveryTruck.tscn
│   │   │   └── FlashAlert.tscn
│   │   │
│   │   ├── time/
│   │   │   ├── TimeDisplay.tscn
│   │   │   ├── CountdownOverlay.tscn
│   │   │   ├── PhaseTransition.tscn
│   │   │   └── CalendarUI.tscn
│   │   │
│   │   ├── events/
│   │   │   ├── WeatherOverlay.tscn
│   │   │   ├── EventNotification.tscn
│   │   │   ├── NPCVisitor.tscn
│   │   │   └── DisasterEffect.tscn
│   │   │
│   │   ├── npcs/
│   │   │   ├── Baker.tscn
│   │   │   ├── Chef.tscn
│   │   │   ├── Mayor.tscn
│   │   │   ├── Merchant.tscn
│   │   │   └── Inspector.tscn
│   │   │
│   │   ├── network/
│   │   │   ├── Lobby.tscn
│   │   │   ├── ReadyZone.tscn
│   │   │   ├── CharacterCustom.tscn
│   │   │   └── NetworkUI.tscn
│   │   │
│   │   ├── chat/
│   │   │   ├── QuickChatWheel.tscn
│   │   │   ├── TextChatBox.tscn
│   │   │   ├── PingMarker.tscn
│   │   │   └── EmoteDisplay.tscn
│   │   │
│   │   ├── save/
│   │   │   ├── SaveMenu.tscn
│   │   │   ├── SaveSlotCard.tscn
│   │   │   └── CloudSyncUI.tscn
│   │   │
│   │   ├── innovation/
│   │   │   ├── InnovationTree.tscn
│   │   │   ├── TreeNode.tscn
│   │   │   ├── BranchView.tscn
│   │   │   └── RespecDialog.tscn
│   │   │
│   │   ├── ui/
│   │   │   ├── hud/
│   │   │   │   ├── HUD.tscn
│   │   │   │   ├── TopBar.tscn
│   │   │   │   ├── BottomBar.tscn
│   │   │   │   ├── ContractCards.tscn
│   │   │   │   └── NotificationArea.tscn
│   │   │   ├── menus/
│   │   │   │   ├── MainMenu.tscn
│   │   │   │   ├── PauseMenu.tscn
│   │   │   │   ├── SettingsMenu.tscn
│   │   │   │   ├── ComputerUI.tscn
│   │   │   │   └── ResultsScreen.tscn
│   │   │   ├── dialogs/
│   │   │   │   ├── ConfirmDialog.tscn
│   │   │   │   ├── ErrorDialog.tscn
│   │   │   │   ├── InfoDialog.tscn
│   │   │   │   └── NPCDialog.tscn
│   │   │   ├── components/
│   │   │   │   ├── Button.tscn
│   │   │   │   ├── Tooltip.tscn
│   │   │   │   ├── NumberCounter.tscn
│   │   │   │   └── ProgressBar.tscn
│   │   │   └── effects/
│   │   │       ├── ScreenShake.tscn
│   │   │       ├── ScreenFlash.tscn
│   │   │       └── Transitions.tscn
│   │   │
│   │   ├── market/
│   │   │   ├── WeekendMarket.tscn
│   │   │   ├── MarketCustomer.tscn
│   │   │   └── MarketCounter.tscn
│   │   │
│   │   ├── tools/
│   │   │   ├── ToolPreview.tscn
│   │   │   └── ToolEffects.tscn
│   │   │
│   │   ├── effects/
│   │   │   ├── WaterIndicator.tscn
│   │   │   ├── QualityStars.tscn
│   │   │   ├── CropParticles.tscn
│   │   │   └── EmoteWheel.tscn
│   │   │
│   │   ├── debug/
│   │   │   ├── GridDebugOverlay.tscn
│   │   │   ├── DebugOverlay.tscn
│   │   │   ├── Console.tscn
│   │   │   └── Profiler.tscn
│   │   │
│   │   ├── visual/
│   │   │   ├── TileMapRenderer.tscn
│   │   │   └── ChunkRenderer.tscn
│   │   │
│   │   ├── audio/
│   │   │   ├── MusicController.tscn
│   │   │   ├── SFXPool.tscn
│   │   │   └── AmbienceZone.tscn
│   │   │
│   │   ├── spectator/
│   │   │   └── SpectatorCamera.tscn
│   │   │
│   │   └── stats/
│   │       ├── StatisticsPanel.tscn
│   │       ├── AchievementList.tscn
│   │       └── RunHistory.tscn
│   │
│   ├── scripts/
│   │   ├── managers/ (AUTOLOADS - In order!)
│   │   │   ├── GameManager.gd            # Autoload #1
│   │   │   ├── GridValidator.gd          # Autoload #2
│   │   │   ├── GridManager.gd            # Autoload #3
│   │   │   ├── InteractionSystem.gd      # Autoload #4
│   │   │   ├── TimeManager.gd            # Autoload #5
│   │   │   ├── EventManager.gd           # Autoload #6
│   │   │   ├── CropManager.gd            # Autoload #7
│   │   │   ├── ContractManager.gd        # Autoload #8
│   │   │   ├── ProcessingManager.gd      # Autoload #9
│   │   │   ├── NetworkManager.gd         # Autoload #10
│   │   │   ├── SaveManager.gd            # Autoload #11
│   │   │   ├── InnovationManager.gd      # Autoload #12
│   │   │   ├── AudioManager.gd           # Autoload #13
│   │   │   └── UIManager.gd              # Autoload #14
│   │   │
│   │   ├── core/
│   │   │   ├── GameState.gd
│   │   │   ├── SceneManager.gd
│   │   │   ├── ResourceManager.gd
│   │   │   ├── PlayerManager.gd
│   │   │   └── InitializationManager.gd
│   │   │
│   │   ├── grid/
│   │   │   ├── FarmTileData.gd
│   │   │   ├── TileUpdate.gd
│   │   │   ├── ChunkManager.gd
│   │   │   ├── ChunkRenderer.gd
│   │   │   └── GridHelpers.gd
│   │   │
│   │   ├── chemistry/
│   │   │   ├── SoilChemistry.gd
│   │   │   ├── NPKManager.gd
│   │   │   ├── PHManager.gd
│   │   │   ├── WaterManager.gd
│   │   │   └── ContaminationManager.gd
│   │   │
│   │   ├── fence/
│   │   │   ├── FenceSystem.gd
│   │   │   ├── FenceValidator.gd
│   │   │   └── ExpansionManager.gd
│   │   │
│   │   ├── player/
│   │   │   ├── PlayerController.gd
│   │   │   ├── PlayerMovement.gd
│   │   │   ├── PlayerInventory.gd
│   │   │   ├── PlayerNetwork.gd
│   │   │   └── PlayerAnimator.gd
│   │   │
│   │   ├── interaction/
│   │   │   ├── ActionValidator.gd
│   │   │   ├── ActionHandlers.gd
│   │   │   ├── TargetCalculator.gd
│   │   │   └── InteractionQueue.gd
│   │   │
│   │   ├── tools/
│   │   │   ├── Tool.gd
│   │   │   ├── ToolHoe.gd
│   │   │   ├── ToolWateringCan.gd
│   │   │   ├── ToolSeedBag.gd
│   │   │   ├── ToolHarvester.gd
│   │   │   ├── ToolFertilizer.gd
│   │   │   └── ToolSoilTest.gd
│   │   │
│   │   ├── carry/
│   │   │   ├── CarrySystem.gd
│   │   │   ├── ThrowPhysics.gd
│   │   │   └── Item.gd
│   │   │
│   │   ├── crops/
│   │   │   ├── Crop.gd
│   │   │   ├── CropGrowth.gd
│   │   │   ├── CropQuality.gd
│   │   │   ├── CropWater.gd
│   │   │   ├── CropHarvest.gd
│   │   │   └── CropVisuals.gd
│   │   │
│   │   ├── quality/
│   │   │   ├── QualityCalculator.gd
│   │   │   ├── SoilQuality.gd
│   │   │   ├── WaterQuality.gd
│   │   │   └── CareQuality.gd
│   │   │
│   │   ├── disease/
│   │   │   ├── DiseaseManager.gd
│   │   │   ├── DiseaseTypes.gd
│   │   │   └── DiseaseSpread.gd
│   │   │
│   │   ├── special/
│   │   │   ├── GiantCropManager.gd
│   │   │   ├── SeasonalCrops.gd
│   │   │   └── MagicCrops.gd
│   │   │
│   │   ├── time/
│   │   │   ├── PhaseController.gd
│   │   │   ├── DayNightCycle.gd
│   │   │   ├── TimeDisplay.gd
│   │   │   ├── CountdownController.gd
│   │   │   └── DifficultyScaler.gd
│   │   │
│   │   ├── events/
│   │   │   ├── Event.gd
│   │   │   ├── WeatherEvent.gd
│   │   │   ├── StoryEvent.gd
│   │   │   ├── DisasterEvent.gd
│   │   │   ├── NPCEvent.gd
│   │   │   └── EventScheduler.gd
│   │   │
│   │   ├── weather/
│   │   │   ├── WeatherController.gd
│   │   │   ├── WeatherEffects.gd
│   │   │   ├── RainSystem.gd
│   │   │   ├── DroughtSystem.gd
│   │   │   └── StormSystem.gd
│   │   │
│   │   ├── npcs/
│   │   │   ├── NPCBase.gd
│   │   │   ├── NPCBaker.gd
│   │   │   ├── NPCChef.gd
│   │   │   ├── NPCMerchant.gd
│   │   │   └── NPCMayor.gd
│   │   │
│   │   ├── contracts/
│   │   │   ├── ContractData.gd
│   │   │   ├── ContractGenerator.gd
│   │   │   ├── ContractValidator.gd
│   │   │   ├── ContractTracker.gd
│   │   │   ├── FlashContract.gd
│   │   │   └── NPCContract.gd
│   │   │
│   │   ├── delivery/
│   │   │   ├── DeliveryBox.gd
│   │   │   ├── DeliveryUI.gd
│   │   │   ├── DeliveryTruck.gd
│   │   │   └── EscrowSystem.gd
│   │   │
│   │   ├── reputation/
│   │   │   ├── ReputationManager.gd
│   │   │   ├── ReputationEffects.gd
│   │   │   └── RelationshipTracker.gd
│   │   │
│   │   ├── market/
│   │   │   ├── WeekendMarket.gd
│   │   │   ├── MarketCustomer.gd
│   │   │   └── MarketScore.gd
│   │   │
│   │   ├── insurance/
│   │   │   └── InsuranceSystem.gd
│   │   │
│   │   ├── machines/
│   │   │   ├── Machine.gd
│   │   │   ├── Thresher.gd
│   │   │   ├── Oven.gd
│   │   │   ├── Press.gd
│   │   │   ├── Mill.gd
│   │   │   ├── Cutter.gd
│   │   │   └── Processor.gd
│   │   │
│   │   ├── processing/
│   │   │   ├── Recipe.gd
│   │   │   ├── RecipeValidator.gd
│   │   │   ├── QualityCalculator.gd
│   │   │   ├── ProcessingQueue.gd
│   │   │   └── OutputGenerator.gd
│   │   │
│   │   ├── minigames/
│   │   │   ├── MiniGame.gd
│   │   │   ├── RhythmGame.gd
│   │   │   ├── TemperatureGame.gd
│   │   │   ├── MashingGame.gd
│   │   │   ├── RotationGame.gd
│   │   │   └── PrecisionGame.gd
│   │   │
│   │   ├── conveyor/
│   │   │   ├── HopperSystem.gd
│   │   │   ├── ConveyorBelt.gd
│   │   │   ├── ItemTransport.gd
│   │   │   └── JamHandler.gd
│   │   │
│   │   ├── breakdown/
│   │   │   ├── BreakdownSystem.gd
│   │   │   ├── RepairManager.gd
│   │   │   └── MaintenanceTracker.gd
│   │   │
│   │   ├── upgrades/
│   │   │   ├── MachineUpgrades.gd
│   │   │   └── RecipeDiscovery.gd
│   │   │
│   │   ├── network/
│   │   │   ├── NetworkPeer.gd
│   │   │   ├── RPCHandler.gd
│   │   │   ├── StateSync.gd
│   │   │   ├── LobbyController.gd
│   │   │   ├── ReconnectionHandler.gd
│   │   │   └── LatencyTracker.gd
│   │   │
│   │   ├── sync/
│   │   │   ├── PositionSync.gd
│   │   │   ├── ActionValidator.gd
│   │   │   ├── StateReconciler.gd
│   │   │   ├── ConflictResolver.gd
│   │   │   └── InputBuffer.gd
│   │   │
│   │   ├── communication/
│   │   │   ├── QuickChat.gd
│   │   │   ├── TextChat.gd
│   │   │   ├── PingSystem.gd
│   │   │   ├── EmoteSystem.gd
│   │   │   └── ProfanityFilter.gd
│   │   │
│   │   ├── lobby/
│   │   │   ├── LobbyPlayer.gd
│   │   │   ├── ReadyZone.gd
│   │   │   ├── CharacterCustomizer.gd
│   │   │   └── LobbyCodeGenerator.gd
│   │   │
│   │   ├── security/
│   │   │   ├── ValidationRules.gd
│   │   │   ├── AntiCheat.gd
│   │   │   └── NetworkLogger.gd
│   │   │
│   │   ├── save/
│   │   │   ├── SaveSlot.gd
│   │   │   ├── SaveSerializer.gd
│   │   │   ├── SaveMigration.gd
│   │   │   ├── BackupManager.gd
│   │   │   ├── ChecksumValidator.gd
│   │   │   └── CloudSyncHandler.gd
│   │   │
│   │   ├── innovation/
│   │   │   ├── InnovationTree.gd
│   │   │   ├── InnovationNode.gd
│   │   │   ├── TreeBranch.gd
│   │   │   ├── RespecHandler.gd
│   │   │   └── IPCalculator.gd
│   │   │
│   │   ├── progression/
│   │   │   ├── UnlockManager.gd
│   │   │   ├── PrestigeSystem.gd
│   │   │   ├── NGPlusManager.gd
│   │   │   └── ChallengeManager.gd
│   │   │
│   │   ├── stats/
│   │   │   ├── StatisticsTracker.gd
│   │   │   ├── AchievementManager.gd
│   │   │   ├── RunRecorder.gd
│   │   │   └── SteamStats.gd
│   │   │
│   │   ├── flow/
│   │   │   ├── RunController.gd
│   │   │   ├── DayController.gd
│   │   │   ├── WinLoseHandler.gd
│   │   │   └── TransitionManager.gd
│   │   │
│   │   ├── economy/
│   │   │   ├── MoneyManager.gd
│   │   │   ├── TransactionLogger.gd
│   │   │   ├── EconomyBalancer.gd
│   │   │   └── PriceCalculator.gd
│   │   │
│   │   ├── debug/
│   │   │   ├── DebugConsole.gd
│   │   │   ├── DebugOverlay.gd
│   │   │   ├── CheatManager.gd
│   │   │   └── Profiler.gd
│   │   │
│   │   ├── error/
│   │   │   ├── ErrorHandler.gd
│   │   │   ├── CrashReporter.gd
│   │   │   ├── RecoveryManager.gd
│   │   │   └── Logger.gd
│   │   │
│   │   ├── events/
│   │   │   ├── EventBus.gd
│   │   │   ├── EventDispatcher.gd
│   │   │   └── EventQueue.gd
│   │   │
│   │   ├── audio/
│   │   │   ├── MusicController.gd
│   │   │   ├── SFXPlayer.gd
│   │   │   ├── AudioPool.gd
│   │   │   ├── PositionalAudio.gd
│   │   │   └── VolumeManager.gd
│   │   │
│   │   ├── ui/
│   │   │   ├── hud/
│   │   │   │   ├── HUDController.gd
│   │   │   │   ├── ClockDisplay.gd
│   │   │   │   ├── MoneyCounter.gd
│   │   │   │   ├── ToolSelector.gd
│   │   │   │   ├── ContractCard.gd
│   │   │   │   └── StaminaBar.gd
│   │   │   ├── menus/
│   │   │   │   ├── MainMenuController.gd
│   │   │   │   ├── PauseMenuController.gd
│   │   │   │   ├── SettingsController.gd
│   │   │   │   ├── ComputerController.gd
│   │   │   │   └── ResultsController.gd
│   │   │   ├── notifications/
│   │   │   │   ├── NotificationQueue.gd
│   │   │   │   ├── NotificationCard.gd
│   │   │   │   ├── FlashAlert.gd
│   │   │   │   └── Achievement.gd
│   │   │   ├── dialogs/
│   │   │   │   ├── DialogManager.gd
│   │   │   │   ├── DialogBox.gd
│   │   │   │   └── TooltipManager.gd
│   │   │   └── effects/
│   │   │       ├── UIAnimator.gd
│   │   │       ├── ScreenEffects.gd
│   │   │       ├── ParticleSpawner.gd
│   │   │       └── TransitionManager.gd
│   │   │
│   │   └── accessibility/
│   │       ├── UIScaler.gd
│   │       ├── ColorblindFilter.gd
│   │       └── InputRemapper.gd
│   │
│   ├── resources/
│   │   ├── tiles/
│   │   │   ├── default_tile.tres
│   │   │   ├── fertile_tile.tres
│   │   │   └── poor_tile.tres
│   │   │
│   │   ├── chemistry/
│   │   │   ├── fertilizers/
│   │   │   │   ├── organic_fertilizer.tres
│   │   │   │   ├── nitrogen_boost.tres
│   │   │   │   └── lime_treatment.tres
│   │   │   └── presets/
│   │   │       ├── desert_soil.tres
│   │   │       ├── volcanic_soil.tres
│   │   │       └── tundra_soil.tres
│   │   │
│   │   ├── tools/
│   │   │   ├── hoe_bronze.tres
│   │   │   ├── hoe_silver.tres
│   │   │   ├── hoe_gold.tres
│   │   │   ├── watering_can_basic.tres
│   │   │   ├── seed_bag.tres
│   │   │   └── harvester.tres
│   │   │
│   │   ├── player/
│   │   │   ├── player_stats.tres
│   │   │   ├── movement_config.tres
│   │   │   └── PlayerInfo.gd
│   │   │
│   │   ├── crops/
│   │   │   ├── tier1/
│   │   │   │   ├── lettuce.tres
│   │   │   │   ├── corn.tres
│   │   │   │   └── wheat.tres
│   │   │   ├── tier2/
│   │   │   │   ├── tomato.tres
│   │   │   │   └── potato.tres
│   │   │   ├── tier3/
│   │   │   │   ├── pumpkin.tres
│   │   │   │   └── strawberry.tres
│   │   │   └── special/
│   │   │       ├── golden_wheat.tres
│   │   │       └── crystal_berry.tres
│   │   │
│   │   ├── diseases/
│   │   │   ├── blight.tres
│   │   │   ├── root_rot.tres
│   │   │   └── pests.tres
│   │   │
│   │   ├── events/
│   │   │   ├── weather/
│   │   │   │   ├── sunny.tres
│   │   │   │   ├── rain.tres
│   │   │   │   ├── drought.tres
│   │   │   │   └── storm.tres
│   │   │   ├── story/
│   │   │   │   ├── mayors_birthday.tres
│   │   │   │   ├── harvest_festival.tres
│   │   │   │   └── [8 more events].tres
│   │   │   └── disasters/
│   │   │       ├── tornado.tres
│   │   │       ├── flood.tres
│   │   │       └── plague.tres
│   │   │
│   │   ├── schedules/
│   │   │   ├── week1_schedule.tres
│   │   │   ├── week2_schedule.tres
│   │   │   ├── week3_schedule.tres
│   │   │   └── week4_schedule.tres
│   │   │
│   │   ├── contracts/
│   │   │   ├── week1/
│   │   │   │   ├── basic_vegetables.tres
│   │   │   │   ├── simple_grain.tres
│   │   │   │   └── easy_mixed.tres
│   │   │   ├── week2/
│   │   │   │   ├── quality_produce.tres
│   │   │   │   ├── processed_goods.tres
│   │   │   │   └── timed_delivery.tres
│   │   │   ├── week3/
│   │   │   │   ├── complex_combo.tres
│   │   │   │   ├── perfect_quality.tres
│   │   │   │   └── bulk_order.tres
│   │   │   ├── week4/
│   │   │   │   ├── impossible_mix.tres
│   │   │   │   ├── extreme_time.tres
│   │   │   │   └── chaos_contract.tres
│   │   │   ├── flash/
│   │   │   │   ├── flash_templates.tres
│   │   │   │   └── flash_scaling.tres
│   │   │   └── events/
│   │   │       └── [10 event contracts].tres
│   │   │
│   │   ├── npcs/
│   │   │   ├── baker_data.tres
│   │   │   ├── chef_data.tres
│   │   │   ├── merchant_data.tres
│   │   │   └── mayor_data.tres
│   │   │
│   │   ├── recipes/
│   │   │   ├── basic/
│   │   │   │   ├── wheat_flour.tres
│   │   │   │   ├── flour_bread.tres
│   │   │   │   ├── potato_fries.tres
│   │   │   │   └── apple_juice.tres
│   │   │   ├── advanced/
│   │   │   │   ├── pizza.tres
│   │   │   │   ├── cake.tres
│   │   │   │   ├── loaded_fries.tres
│   │   │   │   └── smoothie.tres
│   │   │   └── special/
│   │   │       └── secret_recipes.tres
│   │   │
│   │   ├── machines/
│   │   │   ├── configs/
│   │   │   │   ├── thresher_config.tres
│   │   │   │   ├── oven_config.tres
│   │   │   │   └── [others].tres
│   │   │   └── upgrades/
│   │   │       ├── speed_boost.tres
│   │   │       └── quality_boost.tres
│   │   │
│   │   ├── minigames/
│   │   │   ├── rhythm_patterns.tres
│   │   │   ├── temperature_configs.tres
│   │   │   └── timing_windows.tres
│   │   │
│   │   ├── network/
│   │   │   ├── network_config.tres
│   │   │   ├── rpc_definitions.tres
│   │   │   └── validation_rules.tres
│   │   │
│   │   ├── chat/
│   │   │   ├── quick_phrases.tres
│   │   │   ├── profanity_list.tres
│   │   │   └── emote_list.tres
│   │   │
│   │   ├── save/
│   │   │   ├── save_config.tres
│   │   │   └── migration_rules.tres
│   │   │
│   │   ├── innovation/
│   │   │   ├── nodes/
│   │   │   │   ├── starting/
│   │   │   │   ├── efficiency/
│   │   │   │   ├── contracts/
│   │   │   │   └── machines/
│   │   │   └── tree_config.tres
│   │   │
│   │   ├── unlocks/
│   │   │   ├── crops/
│   │   │   ├── machines/
│   │   │   └── cosmetics/
│   │   │
│   │   ├── challenges/
│   │   │   ├── daily_template.tres
│   │   │   └── weekly_template.tres
│   │   │
│   │   ├── config/
│   │   │   ├── game_config.tres
│   │   │   ├── economy_config.tres
│   │   │   ├── debug_config.tres
│   │   │   └── autoload_order.tres
│   │   │
│   │   ├── states/
│   │   │   ├── boot_state.tres
│   │   │   ├── menu_state.tres
│   │   │   ├── playing_state.tres
│   │   │   └── paused_state.tres
│   │   │
│   │   ├── audio/
│   │   │   ├── buses/
│   │   │   │   └── audio_bus_layout.tres
│   │   │   ├── music/
│   │   │   │   └── [music files].ogg
│   │   │   └── sfx/
│   │   │       └── [sound effects].ogg
│   │   │
│   │   ├── ui/
│   │   │   ├── themes/
│   │   │   │   ├── default_theme.tres
│   │   │   │   ├── button_style.tres
│   │   │   │   └── panel_style.tres
│   │   │   └── fonts/
│   │   │       ├── title_font.tres
│   │   │       ├── body_font.tres
│   │   │       └── number_font.tres
│   │   │
│   │   └── settings/
│   │       ├── default_settings.tres
│   │       └── control_mappings.tres
│   │
│   └── assets/
│       ├── sprites/
│       │   ├── tiles/
│       │   ├── player/
│       │   ├── crops/
│       │   ├── machines/
│       │   ├── tools/
│       │   ├── ui/
│       │   ├── icons/
│       │   ├── npcs/
│       │   ├── weather/
│       │   ├── effects/
│       │   ├── indicators/
│       │   ├── diseases/
│       │   ├── conveyors/
│       │   ├── minigames/
│       │   ├── lobby/
│       │   ├── emotes/
│       │   ├── market/
│       │   └── debug/
│       │
│       ├── textures/
│       │   ├── tiles/
│       │   └── overlays/
│       │
│       ├── sounds/
│       │   ├── music/
│       │   ├── sfx/
│       │   ├── ui/
│       │   ├── tools/
│       │   ├── ambient/
│       │   ├── footsteps/
│       │   ├── growth/
│       │   ├── harvest/
│       │   ├── time/
│       │   ├── weather/
│       │   ├── events/
│       │   ├── contracts/
│       │   ├── delivery/
│       │   ├── market/
│       │   ├── machines/
│       │   ├── minigames/
│       │   ├── network/
│       │   ├── chat/
│       │   ├── save/
│       │   └── innovation/
│       │
│       ├── fonts/
│       │   ├── fredoka_one.ttf
│       │   ├── roboto_regular.ttf
│       │   ├── roboto_mono.ttf
│       │   └── debug_mono.ttf
│       │
│       └── shaders/
│           ├── soil_quality.gdshader
│           └── water_overlay.gdshader
│
└── addons/ (Optional - for plugins)
    └── [any third-party plugins]
	
File Count Summary:

Scenes: ~150 .tscn files
Scripts: ~250 .gd files
Resources: ~200 .tres files
Assets: ~500+ sprites/sounds
Total Project Files: ~1,100+ files