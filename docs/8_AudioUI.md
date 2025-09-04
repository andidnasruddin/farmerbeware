Implementation Priority:

UIManager.gd - UI orchestration (Autoload #14)
AudioManager.gd - Audio system (Autoload #13)
HUDController.gd - Main HUD
MainMenuController.gd - Entry point
NotificationQueue.gd - Notifications
MusicController.gd - Dynamic music
SettingsController.gd - Settings menu
ScreenEffects.gd - Visual polish
TooltipManager.gd - Tooltips
UIScaler.gd - Responsive UI

Key Implementation Notes:

UI uses CanvasLayers for proper ordering
HUD always visible during gameplay
Audio buses for grouped volume control
Music has crossfading layers based on game state
Notifications queue and auto-dismiss
All UI scales with resolution
Settings persist between sessions
Sound pooling prevents audio overflow
Accessibility options from day 1
Consistent visual language throughout

res://
├── scenes/
│   ├── ui/
│   │   ├── hud/
│   │   │   ├── HUD.tscn           # Main HUD container
│   │   │   ├── TopBar.tscn        # Clock, money, weather
│   │   │   ├── BottomBar.tscn     # Tools, stamina
│   │   │   ├── ContractCards.tscn # Left side contracts
│   │   │   └── NotificationArea.tscn # Right notifications
│   │   │
│   │   ├── menus/
│   │   │   ├── MainMenu.tscn      # Title screen
│   │   │   ├── PauseMenu.tscn     # ESC menu
│   │   │   ├── SettingsMenu.tscn  # All settings
│   │   │   ├── ComputerUI.tscn    # Farm computer
│   │   │   └── ResultsScreen.tscn # Day/run results
│   │   │
│   │   ├── dialogs/
│   │   │   ├── ConfirmDialog.tscn # Yes/no prompts
│   │   │   ├── ErrorDialog.tscn   # Error display
│   │   │   ├── InfoDialog.tscn    # Information
│   │   │   └── NPCDialog.tscn     # NPC speech
│   │   │
│   │   ├── components/
│   │   │   ├── Button.tscn        # Styled button
│   │   │   ├── Tooltip.tscn       # Hover tooltip
│   │   │   ├── NumberCounter.tscn # Animated numbers
│   │   │   └── ProgressBar.tscn   # Styled progress
│   │   │
│   │   └── effects/
│   │       ├── ScreenShake.tscn   # Shake effect
│   │       ├── ScreenFlash.tscn   # Flash effect
│   │       └── Transitions.tscn   # Fade/slide
│   │
│   └── audio/
│       ├── MusicController.tscn   # Music layers
│       ├── SFXPool.tscn          # Sound pool
│       └── AmbienceZone.tscn     # 3D ambience
│
├── scripts/
│   ├── managers/
│   │   ├── AudioManager.gd        # Autoload #13
│   │   └── UIManager.gd           # Autoload #14
│   │
│   ├── audio/
│   │   ├── MusicController.gd     # Dynamic music
│   │   ├── SFXPlayer.gd           # Sound effects
│   │   ├── AudioPool.gd          # Voice pooling
│   │   ├── PositionalAudio.gd    # 3D audio
│   │   └── VolumeManager.gd      # Volume control
│   │
│   ├── ui/
│   │   ├── hud/
│   │   │   ├── HUDController.gd   # HUD management
│   │   │   ├── ClockDisplay.gd    # Time display
│   │   │   ├── MoneyCounter.gd    # Money animation
│   │   │   ├── ToolSelector.gd    # Tool UI
│   │   │   └── ContractCard.gd    # Contract display
│   │   │
│   │   ├── menus/
│   │   │   ├── MainMenuController.gd
│   │   │   ├── PauseMenuController.gd
│   │   │   ├── SettingsController.gd
│   │   │   ├── ComputerController.gd
│   │   │   └── ResultsController.gd
│   │   │
│   │   ├── notifications/
│   │   │   ├── NotificationQueue.gd # Queue system
│   │   │   ├── NotificationCard.gd  # Individual notif
│   │   │   ├── FlashAlert.gd       # Fullscreen alert
│   │   │   └── Achievement.gd      # Achievement popup
│   │   │
│   │   ├── dialogs/
│   │   │   ├── DialogManager.gd    # Dialog stack
│   │   │   ├── DialogBox.gd        # Base dialog
│   │   │   └── TooltipManager.gd   # Tooltip system
│   │   │
│   │   └── effects/
│   │       ├── UIAnimator.gd       # UI animations
│   │       ├── ScreenEffects.gd    # Screen effects
│   │       ├── ParticleSpawner.gd  # UI particles
│   │       └── TransitionManager.gd # Scene transitions
│   │
│   └── accessibility/
│       ├── UIScaler.gd            # UI scaling
│       ├── ColorblindFilter.gd   # Color modes
│       └── InputRemapper.gd       # Key rebinding
│
├── resources/
│   ├── audio/
│   │   ├── buses/
│   │   │   └── audio_bus_layout.tres
│   │   │
│   │   ├── music/
│   │   │   ├── menu_theme.ogg
│   │   │   ├── planning_ambient.ogg
│   │   │   ├── farming_base.ogg
│   │   │   ├── farming_drums.ogg
│   │   │   ├── farming_tension.ogg
│   │   │   └── results_victory.ogg
│   │   │
│   │   └── sfx/
│   │       ├── ui/
│   │       │   ├── button_click.ogg
│   │       │   ├── button_hover.ogg
│   │       │   └── notification.ogg
│   │       ├── tools/
│   │       │   └── [tool sounds].ogg
│   │       └── ambient/
│   │           └── [ambient sounds].ogg
│   │
│   ├── ui/
│   │   ├── themes/
│   │   │   ├── default_theme.tres
│   │   │   ├── button_style.tres
│   │   │   └── panel_style.tres
│   │   │
│   │   └── fonts/
│   │       ├── title_font.tres
│   │       ├── body_font.tres
│   │       └── number_font.tres
│   │
│   └── settings/
│       ├── default_settings.tres
│       └── control_mappings.tres
│
└── assets/
    ├── sprites/
    │   ├── ui/
    │   │   ├── backgrounds/
    │   │   │   ├── main_menu_bg.png
    │   │   │   └── pause_overlay.png
    │   │   ├── buttons/
    │   │   │   ├── button_normal.png
    │   │   │   ├── button_hover.png
    │   │   │   └── button_pressed.png
    │   │   ├── icons/
    │   │   │   ├── tool_icons.png
    │   │   │   ├── weather_icons.png
    │   │   │   └── contract_icons.png
    │   │   └── panels/
    │   │       ├── panel_bg.png
    │   │       └── notification_bg.png
    │   │
    │   └── effects/
    │       ├── particles/
    │       │   ├── sparkle.png
    │       │   └── confetti.png
    │       └── transitions/
    │           └── fade_gradient.png
    │
    └── fonts/
        ├── fredoka_one.ttf         # Main title font
        ├── roboto_regular.ttf      # Body text
        └── roboto_mono.ttf         # Numbers/debug

flowchart TB
    subgraph AudioCore ["🔊 AUDIO SYSTEM CORE"]
        subgraph AudioManager ["Audio Manager (Autoload #13)"]
            AudioData["AudioManager.gd<br/>---<br/>PROPERTIES:<br/>• master_volume: float<br/>• sfx_volume: float<br/>• music_volume: float<br/>• current_music: AudioStream<br/>• sound_pool: Dictionary<br/>• music_layers: Array[AudioStreamPlayer]<br/>• ambience_tracks: Array<br/>---<br/>SIGNALS:<br/>• music_changed(track)<br/>• sound_played(sound)<br/>• volume_changed(bus, value)<br/>• music_layer_toggled(layer)"]
            
            AudioBuses["AUDIO BUSES:<br/>---<br/>Master (0)<br/>├── Music (-10db)<br/>│   ├── Menu Music<br/>│   ├── Planning Music<br/>│   └── Action Music<br/>├── SFX (-5db)<br/>│   ├── Tools<br/>│   ├── UI<br/>│   └── Ambient<br/>└── Voice (future)"]
        end

        subgraph MusicSystem ["Dynamic Music"]
            LayeredMusic["LAYERED TRACKS:<br/>• Base (always playing)<br/>• Drums (action phase)<br/>• Tension (low time)<br/>• Danger (disasters)<br/>• Success (good streak)<br/>• Crossfade smooth"]
            
            MusicStates["MUSIC BY PHASE:<br/>---<br/>MENU: Calm piano<br/>PLANNING: Soft ambient<br/>COUNTDOWN: Building drums<br/>FARMING: Full mix<br/>LASTMINUTE: Intense<br/>RESULTS: Victory/Defeat"]
            
            DynamicIntensity["DYNAMIC INTENSITY:<br/>• Time remaining<br/>• Contract urgency<br/>• Flash contract active<br/>• Player performance<br/>• Smooth transitions<br/>• Never jarring"]
        end

        subgraph SoundEffects ["Sound Effect System"]
            SFXCategories["SFX CATEGORIES:<br/>---<br/>TOOLS: Till, water, harvest<br/>UI: Click, hover, confirm<br/>SUCCESS: Ding, chime, flourish<br/>FAILURE: Buzz, crash, whomp<br/>AMBIENT: Wind, birds, machines<br/>SPECIAL: Flash alarm, truck"]
            
            SoundPooling["SOUND POOLING:<br/>• 32 max voices<br/>• Priority system<br/>• Distance culling<br/>• Variation pitch (±10%)<br/>• No doubling<br/>• Cleanup old"]
            
            PositionalAudio["3D AUDIO:<br/>• Distance falloff<br/>• Stereo panning<br/>• Reverb zones<br/>• Occlusion (buildings)<br/>• Player-relative<br/>• Max range: 1000px"]
        end
    end

    subgraph UICore ["🎮 UI SYSTEM CORE"]
        subgraph UIManager ["UI Manager (Autoload #14)"]
            UIData["UIManager.gd<br/>---<br/>PROPERTIES:<br/>• active_menus: Array[Control]<br/>• hud_visible: bool<br/>• notification_queue: Array<br/>• dialog_stack: Array<br/>• ui_scale: float<br/>• safe_margins: Rect2<br/>---<br/>SIGNALS:<br/>• menu_opened(menu)<br/>• menu_closed(menu)<br/>• notification_shown(notif)<br/>• dialog_confirmed(dialog)"]
            
            UILayers["UI LAYERS (CanvasLayers):<br/>---<br/>0: World (gameplay)<br/>1: HUD (always visible)<br/>2: Menus (pause game)<br/>3: Dialogs (priority)<br/>4: Notifications (top)<br/>5: Debug (F3 overlay)<br/>6: Transitions (fades)"]
        end

        subgraph HUDSystem ["HUD (Heads-Up Display)"]
            TopBar["TOP BAR:<br/>• Clock (time/day)<br/>• Money counter<br/>• Weather indicator<br/>• Network status<br/>• Phase indicator<br/>• IP display"]
            
            BottomBar["BOTTOM BAR:<br/>• Tool selector (1-7)<br/>• Selected tool icon<br/>• Stamina bar<br/>• Carry indicator<br/>• Quick chat (hold V)<br/>• Emote wheel (hold F)"]
            
            SideElements["SIDE ELEMENTS:<br/>---<br/>LEFT: Contract cards<br/>• Progress bars<br/>• Time remaining<br/>• Flash warnings<br/>---<br/>RIGHT: Notifications<br/>• Sliding cards<br/>• Auto-dismiss 5s"]
        end
    end

    subgraph MenuSystems ["📋 MENU SYSTEMS"]
        MainMenu["MAIN MENU:<br/>• Title screen<br/>• Play button<br/>• Innovations<br/>• Settings<br/>• Statistics<br/>• Credits<br/>• Quit"]
        
        PauseMenu["PAUSE MENU (ESC):<br/>• Resume<br/>• Settings<br/>• Save & Exit<br/>• Vote to abandon<br/>• Darkened BG<br/>• Time stopped"]
        
        ComputerUI["COMPUTER UI:<br/>• Contract Board<br/>• Store (seeds/upgrades)<br/>• Insurance<br/>• Weather forecast<br/>• Market prices<br/>• Land purchase<br/>• START DAY button"]
        
        DeliveryUI["DELIVERY BOX UI:<br/>• Active contracts list<br/>• Item in hand preview<br/>• Quality match indicator<br/>• Submit buttons<br/>• Escrow display<br/>• Can't retrieve warning"]
    end

    subgraph NotificationSystem ["💬 NOTIFICATION SYSTEM"]
        NotificationTypes["NOTIFICATION TYPES:<br/>• Success (green, top)<br/>• Warning (yellow, side)<br/>• Error (red, shake)<br/>• Info (blue, subtle)<br/>• Flash (full screen)<br/>• Achievement (special)"]
        
        NotificationQueue["QUEUE SYSTEM:<br/>• Max 3 visible<br/>• Stack vertically<br/>• Slide in from right<br/>• 5 second display<br/>• Click to dismiss<br/>• Priority sorting"]
        
        SpecialAlerts["SPECIAL ALERTS:<br/>• Flash contract (fullscreen)<br/>• Low time (screen edge)<br/>• Disaster (screen shake)<br/>• Perfect day (confetti)<br/>• Game over (fade out)"]
    end

    subgraph VisualFeedback ["✨ VISUAL FEEDBACK"]
        ScreenEffects["SCREEN EFFECTS:<br/>• Shake (damage/fail)<br/>• Flash (success)<br/>• Vignette (danger)<br/>• Blur (pause)<br/>• Chromatic (disaster)<br/>• Fade (transitions)"]
        
        UIAnimations["UI ANIMATIONS:<br/>• Button hover scale<br/>• Press squish<br/>• Slide transitions<br/>• Number counting<br/>• Bar filling<br/>• Card flipping"]
        
        ParticleUI["UI PARTICLES:<br/>• Money earned (+$)<br/>• Quality stars<br/>• Success sparkles<br/>• Click ripples<br/>• Hover glow<br/>• Trail effects"]
    end

    subgraph Accessibility ["♿ ACCESSIBILITY"]
        VisualOptions["VISUAL OPTIONS:<br/>• UI scale (75-150%)<br/>• Colorblind modes<br/>• High contrast<br/>• Reduce motion<br/>• Larger text<br/>• Icon labels"]
        
        AudioOptions["AUDIO OPTIONS:<br/>• Subtitles (future)<br/>• Visual sound cues<br/>• Mono audio<br/>• Volume sliders<br/>• Mute individual"]
        
        InputOptions["INPUT OPTIONS:<br/>• Rebind keys<br/>• Hold to press toggle<br/>• One-handed mode<br/>• Controller vibration<br/>• Mouse sensitivity"]
    end

    subgraph ResponsiveUI ["📱 RESPONSIVE DESIGN"]
        ScreenSizes["SCREEN SUPPORT:<br/>• 720p minimum<br/>• 1080p standard<br/>• 1440p enhanced<br/>• 4K ready<br/>• 16:9, 16:10, 21:9<br/>• Safe zones"]
        
        UIScaling["SCALING STRATEGY:<br/>• Anchor presets<br/>• Margin containers<br/>• Viewport stretch<br/>• Font scaling<br/>• Icon sizes<br/>• Touch targets"]
        
        PlatformUI["PLATFORM SPECIFIC:<br/>• PC: Mouse hover<br/>• Steam Deck: Touch<br/>• Controller: Focus<br/>• Different prompts<br/>• Adapted layouts"]
    end

    subgraph DialogSystem ["💭 DIALOG & TOOLTIPS"]
        DialogBoxes["DIALOG BOXES:<br/>• Confirmation dialogs<br/>• Error messages<br/>• Tutorial hints<br/>• NPC speech<br/>• Modal backdrop<br/>• Queue if multiple"]
        
        TooltipSystem["TOOLTIPS:<br/>• Hover 0.5s delay<br/>• Item descriptions<br/>• Cost breakdowns<br/>• Stat explanations<br/>• Control hints<br/>• Smart positioning"]
        
        TutorialOverlays["TUTORIAL:<br/>• First-run hints<br/>• Highlight elements<br/>• Step-by-step<br/>• Skip option<br/>• Remember dismissed"]
    end

    subgraph SettingsMenu ["⚙️ SETTINGS"]
        GameSettings["GAME SETTINGS:<br/>• Difficulty assist<br/>• Auto-save toggle<br/>• Tutorial hints<br/>• Screen shake<br/>• Quick chat filter"]
        
        VideoSettings["VIDEO SETTINGS:<br/>• Resolution<br/>• Fullscreen<br/>• VSync<br/>• Quality preset<br/>• Shadow quality<br/>• Anti-aliasing"]
        
        AudioSettings["AUDIO SETTINGS:<br/>• Master volume<br/>• Music volume<br/>• SFX volume<br/>• UI sounds<br/>• Ambience volume"]
        
        ControlSettings["CONTROL SETTINGS:<br/>• View bindings<br/>• Rebind keys<br/>• Controller setup<br/>• Sensitivity<br/>• Invert axes"]
    end

    subgraph Polish ["🎨 POLISH ELEMENTS"]
        JuiceElements["JUICE & FEEL:<br/>• Smooth transitions<br/>• Easing curves<br/>• Bounce effects<br/>• Micro-animations<br/>• Hover states<br/>• Press feedback"]
        
        Consistency["CONSISTENCY:<br/>• Color palette<br/>• Font hierarchy<br/>• Icon style<br/>• Button shapes<br/>• Spacing rules<br/>• Sound language"]
        
        Delight["DELIGHT DETAILS:<br/>• Logo animation<br/>• Loading spinner<br/>• Success confetti<br/>• Easter eggs<br/>• Idle animations<br/>• Hidden sounds"]
    end

    %% Connections
    AudioData --> AudioBuses
    LayeredMusic --> MusicStates --> DynamicIntensity
    SFXCategories --> SoundPooling --> PositionalAudio
    
    UIData --> UILayers
    TopBar & BottomBar & SideElements --> HUDSystem
    
    MainMenu & PauseMenu & ComputerUI & DeliveryUI --> MenuSystems
    
    NotificationTypes --> NotificationQueue --> SpecialAlerts
    
    ScreenEffects & UIAnimations & ParticleUI --> VisualFeedback
    
    VisualOptions & AudioOptions & InputOptions --> Accessibility
    
    ScreenSizes --> UIScaling --> PlatformUI
    
    DialogBoxes & TooltipSystem & TutorialOverlays --> DialogSystem
    
    GameSettings & VideoSettings & AudioSettings & ControlSettings --> SettingsMenu
    
    JuiceElements & Consistency & Delight --> Polish