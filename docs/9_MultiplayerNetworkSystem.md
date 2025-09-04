res://
├── scenes/
│   ├── network/
│   │   ├── Lobby.tscn             # Lobby room
│   │   ├── ReadyZone.tscn         # Ready area
│   │   ├── CharacterCustom.tscn   # Character setup
│   │   └── NetworkUI.tscn         # Network HUD
│   │
│   ├── chat/
│   │   ├── QuickChatWheel.tscn    # 8-direction wheel
│   │   ├── TextChatBox.tscn       # Chat interface
│   │   ├── PingMarker.tscn        # World ping
│   │   └── EmoteDisplay.tscn      # Emote bubbles
│   │
│   └── spectator/
│       └── SpectatorCamera.tscn   # Free cam
│
├── scripts/
│   ├── managers/
│   │   └── NetworkManager.gd      # Autoload #10
│   │
│   ├── network/
│   │   ├── NetworkPeer.gd         # Peer management
│   │   ├── RPCHandler.gd          # RPC routing
│   │   ├── StateSync.gd           # State syncing
│   │   ├── LobbyController.gd     # Lobby logic
│   │   ├── ReconnectionHandler.gd # Reconnect system
│   │   └── LatencyTracker.gd      # Ping monitoring
│   │
│   ├── sync/
│   │   ├── PositionSync.gd        # Position interpolation
│   │   ├── ActionValidator.gd     # Host validation
│   │   ├── StateReconciler.gd     # Client reconciliation
│   │   ├── ConflictResolver.gd    # Conflict handling
│   │   └── InputBuffer.gd         # Input buffering
│   │
│   ├── communication/
│   │   ├── QuickChat.gd           # Chat wheel
│   │   ├── TextChat.gd            # Text chat
│   │   ├── PingSystem.gd          # Ping markers
│   │   ├── EmoteSystem.gd         # Emote handling
│   │   └── ProfanityFilter.gd     # Chat filtering
│   │
│   ├── lobby/
│   │   ├── LobbyPlayer.gd         # Lobby character
│   │   ├── ReadyZone.gd           # Ready detection
│   │   ├── CharacterCustomizer.gd # Customization
│   │   └── LobbyCodeGenerator.gd  # Code system
│   │
│   └── security/
│       ├── ValidationRules.gd     # Validation logic
│       ├── AntiCheat.gd           # Anti-grief
│       └── NetworkLogger.gd       # RPC logging
│
├── resources/
│   ├── network/
│   │   ├── network_config.tres    # Network settings
│   │   ├── rpc_definitions.tres   # RPC configs
│   │   └── validation_rules.tres  # Security rules
│   │
│   ├── chat/
│   │   ├── quick_phrases.tres     # Chat wheel text
│   │   ├── profanity_list.tres    # Filter words
│   │   └── emote_list.tres        # Available emotes
│   │
│   └── player/
│       ├── PlayerInfo.gd          # Player data class
│       └── default_player.tres    # Default settings
│
└── assets/
    ├── sprites/
    │   ├── ui/
    │   │   ├── connection_bars.png
    │   │   ├── host_crown.png
    │   │   ├── ping_marker.png
    │   │   └── chat_bubble.png
    │   │
    │   ├── lobby/
    │   │   ├── lobby_room.png
    │   │   ├── ready_zone.png
    │   │   └── character_station.png
    │   │
    │   └── emotes/
    │       ├── happy.png
    │       ├── sad.png
    │       ├── wave.png
    │       └── thumbs_up.png
    │
    └── sounds/
        ├── network/
        │   ├── player_join.ogg
        │   ├── player_leave.ogg
        │   ├── connection_lost.ogg
        │   └── ping_sound.ogg
        │
        └── chat/
            ├── message_send.ogg
            ├── message_receive.ogg
            └── ping_place.ogg
			
flowchart TB
    subgraph NetworkCore ["🌐 NETWORK SYSTEM CORE"]
        subgraph NetworkManager ["Network Manager (Autoload #10)"]
            ManagerData["NetworkManager.gd<br/>---<br/>PROPERTIES:<br/>• peer: MultiplayerPeer<br/>• network_mode: NetworkMode<br/>• player_info: Dictionary{id: PlayerInfo}<br/>• lobby_code: String (6 chars)<br/>• current_tick: int<br/>• ping_latencies: Dictionary<br/>• max_players: int (4)<br/>---<br/>SIGNALS:<br/>• player_connected(id, info)<br/>• player_disconnected(id)<br/>• lobby_created(code)<br/>• game_started()<br/>• connection_failed()"]
            
            NetworkModes["NETWORK MODES:<br/>• OFFLINE (single player)<br/>• HOST (P2P server)<br/>• CLIENT (P2P client)<br/>---<br/>Host is authoritative<br/>Clients predict locally"]
        end

        subgraph P2PArchitecture ["P2P Host-Client Model"]
            HostRole["HOST (Player 1):<br/>• Runs simulation<br/>• Validates all actions<br/>• Broadcasts state<br/>• Controls time<br/>• Manages saves<br/>• Handles NPCs/Events"]
            
            ClientRole["CLIENTS (Players 2-4):<br/>• Send input requests<br/>• Local prediction<br/>• Interpolate positions<br/>• Follow host state<br/>• No save access<br/>• Buffer inputs"]
            
            ConnectionFlow["CONNECTION:<br/>1. Host creates lobby<br/>2. Generate 6-char code<br/>3. Open port 7777<br/>4. Clients enter code<br/>5. Connect via IP<br/>6. Exchange player info"]
        end
    end

    subgraph LobbySystem ["🏠 LOBBY SYSTEM (Plate Up Style)"]
        LobbyScene["LOBBY SCENE:<br/>• 3D/2D room space<br/>• Players walk freely<br/>• Ready zone area<br/>• Character customization<br/>• Computer terminal<br/>• Innovation tree access"]
        
        ReadySystem["READY SYSTEM:<br/>• Walk to ready zone<br/>• Visual confirmation<br/>• Green checkmark<br/>• All must be ready<br/>• 3 second countdown<br/>• Load farm scene"]
        
        CharacterSetup["CHARACTER SETUP:<br/>• Color picker<br/>• Outfit selection (hats)<br/>• Name display<br/>• Saved preferences<br/>• Visible to all<br/>• Real-time sync"]
        
        LobbyCommunication["COMMUNICATION:<br/>• Text chat box<br/>• Quick chat wheel (8 phrases)<br/>• Ping markers<br/>• Emote wheel<br/>• Voice: Use Discord<br/>• Player list display"]
    end

    subgraph RPCSystem ["📡 RPC COMMUNICATION"]
        ReliableRPCs["RELIABLE RPCs (TCP-like):<br/>---<br/>• request_till_tile(pos)<br/>• request_plant_crop(pos, type)<br/>• request_purchase(item_id)<br/>• request_use_machine(id)<br/>• submit_contract_item(id, item)<br/>• sync_game_state(full_state)<br/>• player_disconnected(id)"]
        
        UnreliableRPCs["UNRELIABLE RPCs (UDP-like):<br/>---<br/>• update_position(pos, vel)<br/>• update_animation(state)<br/>• particle_effect(type, pos)<br/>• sound_trigger(sound_id)<br/>• emote_display(emote_id)<br/>• tool_preview(tiles)"]
        
        RPCFlow["RPC FLOW:<br/>1. Client action<br/>2. Local prediction<br/>3. Send to host<br/>4. Host validates<br/>5. Execute if valid<br/>6. Broadcast result<br/>7. Clients reconcile<br/>8. Smooth corrections"]
    end

    subgraph SyncSystem ["🔄 STATE SYNCHRONIZATION"]
        UpdateRates["UPDATE FREQUENCIES:<br/>• Position: 20-30 Hz<br/>• Actions: Instant<br/>• World state: On change<br/>• Full sync: Every 10s<br/>• Money/Contracts: Instant<br/>• Chemistry: 1 Hz batched"]
        
        Interpolation["INTERPOLATION:<br/>• Buffer 3 positions<br/>• Smooth between updates<br/>• Predict next position<br/>• Rubber-band on error<br/>• Hide network jitter<br/>• 100ms buffer"]
        
        ClientPrediction["CLIENT PREDICTION:<br/>• Move immediately<br/>• Show tool preview<br/>• Play animations<br/>• Queue for validation<br/>• Rollback if wrong<br/>• Feels responsive"]
        
        ConflictResolution["CONFLICTS:<br/>• Timestamp based<br/>• Lower ID wins ties<br/>• Host always wins<br/>• Force sync if needed<br/>• Log discrepancies"]
    end

    subgraph ReconnectionSystem ["🔌 RECONNECTION (5 MIN)"]
        DisconnectHandling["DISCONNECT:<br/>• Character freezes<br/>• 5 minute timer starts<br/>• Slot reserved<br/>• Others notified<br/>• Can continue playing"]
        
        ReconnectProcess["RECONNECT:<br/>• Use same lobby code<br/>• Rejoin at position<br/>• Restore player state<br/>• Sync current game<br/>• Resume control"]
        
        TimeoutHandling["TIMEOUT:<br/>• After 5 minutes<br/>• Slot released<br/>• Character removed<br/>• Items dropped<br/>• Game continues"]
        
        HostDisconnect["HOST DISCONNECT:<br/>• Session ends<br/>• All return to menu<br/>• Save if possible<br/>• No host migration<br/>• Standard behavior"]
    end

    subgraph LatencyManagement ["⚡ LATENCY & LAG"]
        PingMonitoring["PING MONITORING:<br/>• Check every 1s<br/>• Display as bars<br/>• Show exact ms<br/>• Green: <50ms<br/>• Yellow: 50-150ms<br/>• Red: >150ms"]
        
        HighPingHandling["HIGH PING (250ms+):<br/>• Warning to player<br/>• Warning to host<br/>• 30s to improve<br/>• Auto-kick if persists<br/>• Can rejoin if better"]
        
        InputBuffering["INPUT BUFFER:<br/>• Store 3 frames<br/>• Smooth jitter<br/>• 100ms window<br/>• FIFO processing<br/>• Never drop inputs<br/>• Helps up to 100ms lag"]
        
        Desync["DESYNC RECOVERY:<br/>• Host = truth<br/>• Auto-correct clients<br/>• Force sync every 10s<br/>• Smooth corrections<br/>• Log for debugging"]
    end

    subgraph QuickChat ["💬 QUICK CHAT SYSTEM"]
        ChatWheel["CHAT WHEEL (Right Click):<br/>• 'Need help!'<br/>• 'On my way!'<br/>• 'Good job!'<br/>• 'Watch out!'<br/>• 'Ready!'<br/>• 'Wait!'<br/>• 'Thanks!'<br/>• 'Sorry!'"]
        
        TextChat["TEXT CHAT:<br/>• 128 char limit<br/>• Profanity filter<br/>• Rate limiting<br/>• Chat history (20)<br/>• Timestamps<br/>• Color per player"]
        
        PingSystem["PING MARKERS:<br/>• Middle click to ping<br/>• Different colors/player<br/>• Context icons<br/>• 'Look here!'<br/>• Auto-expire 3s<br/>• Max 3 per player"]
    end

    subgraph NetworkUI ["🎯 NETWORK UI"]
        PlayerIndicators["PLAYER UI:<br/>• Connection bars (by name)<br/>• Host crown icon<br/>• Ping display (ms)<br/>• Disconnect timer<br/>• Ready checkmark<br/>• Voice indicator"]
        
        ScreenIndicators["SCREEN UI:<br/>• Top-right: Your ping<br/>• Lobby code display<br/>• Player count (3/4)<br/>• Network status icon<br/>• Packet loss warning"]
        
        Notifications["NETWORK ALERTS:<br/>• 'Player joined!'<br/>• 'Connection lost'<br/>• 'High ping warning'<br/>• 'Reconnecting...'<br/>• 'Session ending'"]
    end

    subgraph LateJoin ["🚪 LATE JOIN & SPECTATE"]
        LateJoinRules["LATE JOIN:<br/>• Can't join mid-day<br/>• Must wait for PLANNING<br/>• Spectate current day<br/>• Spawn next day<br/>• Full player rights<br/>• Share resources"]
        
        SpectatorMode["SPECTATOR:<br/>• Free camera movement<br/>• See all players<br/>• Can use chat<br/>• Can't interact<br/>• See all UI<br/>• Learn strategies"]
    end

    subgraph SecurityValidation ["🛡️ SECURITY & VALIDATION"]
        HostValidation["HOST VALIDATES:<br/>• Movement speed<br/>• Tool range<br/>• Money changes<br/>• Item spawning<br/>• Mini-game scores<br/>• Contract completion<br/>• Action cooldowns"]
        
        AntiGrief["ANTI-GRIEF:<br/>• Position bounds<br/>• Resource limits<br/>• State consistency<br/>• Kick bad actors<br/>• Log violations<br/>• Auto-ban repeat"]
        
        ErrorRecovery["ERROR RECOVERY:<br/>• Log all RPCs<br/>• Snapshot states<br/>• Rollback capability<br/>• Reconnect protocol<br/>• Graceful degradation"]
    end

    %% Connections
    ManagerData --> NetworkModes
    HostRole --> ClientRole --> ConnectionFlow
    
    LobbyScene --> ReadySystem & CharacterSetup --> LobbyCommunication
    
    ReliableRPCs & UnreliableRPCs --> RPCFlow
    
    UpdateRates --> Interpolation & ClientPrediction --> ConflictResolution
    
    DisconnectHandling --> ReconnectProcess & TimeoutHandling
    HostDisconnect --> DisconnectHandling
    
    PingMonitoring --> HighPingHandling --> InputBuffering --> Desync
    
    ChatWheel & TextChat & PingSystem --> QuickChat
    
    PlayerIndicators & ScreenIndicators & Notifications --> NetworkUI
    
    LateJoinRules --> SpectatorMode
    
    HostValidation --> AntiGrief --> ErrorRecovery
	
Implementation Priority:

NetworkManager.gd - Core networking (Autoload #10)
NetworkPeer.gd - Connection management
RPCHandler.gd - Message routing
LobbyController.gd - Lobby system
StateSync.gd - State synchronization
PositionSync.gd - Movement interpolation
ReconnectionHandler.gd - 5-min reconnect
QuickChat.gd - Communication system

Key Implementation Notes:

P2P with host authority (no dedicated servers)
Lobby code system (6 characters) for easy joining
5-minute reconnection window (character freezes)
Host disconnect ends session (no migration)
Position updates at 20-30Hz, unreliable
State changes use reliable RPCs
Client prediction with host validation
Ping limit: 250ms before kick
Late join only during PLANNING phase
Voice chat through Discord (not built-in)