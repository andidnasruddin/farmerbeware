extends RefCounted
# GameState.gd - Helper class for managing game state data
# This provides utilities and data structures for the state machine
class_name GameStateHelper

# ============================================================================
# STATE VALIDATION - Ensures state transitions are valid
# ============================================================================
static func is_valid_transition(from_state: int, to_state: int) -> bool:
	# Using int instead of GameManager.GameState to avoid circular dependency
	
	# Define valid transitions (from_state -> [valid_to_states])
	var valid_transitions: Dictionary = {
		0: [1],        # BOOT -> MENU
		1: [2, 6],     # MENU -> LOBBY or GAME_OVER
		2: [3, 1],     # LOBBY -> LOADING or back to MENU
		3: [4],        # LOADING -> PLAYING
		4: [5, 6, 7],  # PLAYING -> PAUSED, GAME_OVER, or RESULTS
		5: [4, 1],     # PAUSED -> PLAYING or MENU (quit)
		6: [1],        # RESULTS -> MENU
		7: [1]         # GAME_OVER -> MENU
	}
	
	return to_state in valid_transitions.get(from_state, [])

# ============================================================================
# STATE DATA - Information about each state
# ============================================================================
static func get_state_info(state: int) -> Dictionary:
	var state_data: Dictionary = {
		0: { # BOOT
			"name": "BOOT",
			"description": "Loading resources and initializing systems",
			"can_pause": false,
			"show_ui": false,
			"allow_input": false
		},
		1: { # MENU
			"name": "MENU", 
			"description": "Main menu is active",
			"can_pause": false,
			"show_ui": true,
			"allow_input": true
		},
		2: { # LOBBY
			"name": "LOBBY",
			"description": "Multiplayer setup and character selection", 
			"can_pause": false,
			"show_ui": true,
			"allow_input": true
		},
		3: { # LOADING
			"name": "LOADING",
			"description": "Transitioning between scenes",
			"can_pause": false,
			"show_ui": false,
			"allow_input": false
		},
		4: { # PLAYING
			"name": "PLAYING",
			"description": "In the farm scene, actively playing",
			"can_pause": true,
			"show_ui": true,
			"allow_input": true
		},
		5: { # PAUSED
			"name": "PAUSED", 
			"description": "Game is paused",
			"can_pause": false,
			"show_ui": true,
			"allow_input": true
		},
		6: { # RESULTS
			"name": "RESULTS",
			"description": "Showing day/run results",
			"can_pause": false,
			"show_ui": true,
			"allow_input": true
		},
		7: { # GAME_OVER
			"name": "GAME_OVER",
			"description": "Run ended, showing final stats",
			"can_pause": false,
			"show_ui": true,
			"allow_input": true
		}
	}
	
	return state_data.get(state, {
		"name": "UNKNOWN",
		"description": "Unknown state",
		"can_pause": false,
		"show_ui": false,
		"allow_input": false
	})

# ============================================================================
# STATE UTILITIES
# ============================================================================
static func state_to_string(state: int) -> String:
	return get_state_info(state)["name"]

static func can_pause_in_state(state: int) -> bool:
	return get_state_info(state)["can_pause"]

static func should_show_ui_in_state(state: int) -> bool:
	return get_state_info(state)["show_ui"]

static func allows_input_in_state(state: int) -> bool:
	return get_state_info(state)["allow_input"]
