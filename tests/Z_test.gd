extends Node

func _ready() -> void:
	# Give autoloads time to initialize and register
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("=== Z_TEST: AUTOLOAD PRESENCE ===")
	_test_presence("GameManager")
	_test_presence("GridValidator")
	_test_presence("GridManager")
	_test_presence("InteractionSystem")
	_test_presence("TimeManager")
	_test_presence("EventManager")
	_test_presence("CropManager")
	_test_presence("ContractManager")
	_test_presence("ProcessingManager")
	_test_presence("NetworkManager")
	_test_presence("SaveManager")
	_test_presence("InnovationManager")
	_test_presence("AudioManager")
	_test_presence("UIManager")
	
	print("\n=== Z_TEST: DEBUG INFO SNAPSHOT ===")
	_try_print_debug("GameManager")
	_try_print_debug("GridManager")
	_try_print_debug("TimeManager")
	_try_print_debug("EventManager")
	_try_print_debug("CropManager")
	_try_print_debug("ContractManager")
	_try_print_debug("ProcessingManager")
	_try_print_debug("NetworkManager")
	_try_print_debug("SaveManager")
	_try_print_debug("InnovationManager")
	_try_print_debug("AudioManager")
	_try_print_debug("UIManager")
	
	print("\n=== Z_TEST: CONTRACT MANAGER (Autoload #8) ===")
	await _test_contract_manager()
	
	print("\n=== Z_TEST: PROCESSING MANAGER (Autoload #9) ===")
	await _test_processing_manager()
	
	print("\n=== Z_TEST: NETWORK MANAGER (Autoload #10) ===")
	await _test_network_manager()
	
	print("\n=== Z_TEST: SAVE MANAGER (Autoload #11) ===")
	_test_save_manager()
	
	print("\n=== Z_TEST: INNOVATION MANAGER (Autoload #12) ===")
	_test_innovation_manager()
	
	print("\n=== Z_TEST: AUDIO MANAGER (Autoload #13) ===")
	_test_audio_manager()
	
	print("\n=== Z_TEST: UI MANAGER (Autoload #14) ===")
	_test_ui_manager()
	
	print("\n=== Z_TEST: COMPLETE ===")


# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
func _S(name: String) -> Node:
	return get_node_or_null("/root/" + name)

func _test_presence(name: String) -> void:
	var obj: Node = _S(name)
	if obj:
		var n: String = ""
		if "name" in obj:
			n = String(obj.name)
		print("- ", name, ": OK (", n, ")")
	else:
		print("- ", name, ": MISSING")

func _try_print_debug(name: String) -> void:
	var obj: Node = _S(name)
	if obj and obj.has_method("get_debug_info"):
		var info: Dictionary = obj.get_debug_info()
		print(name, " debug: ", info)
	else:
		print(name, " debug: (no get_debug_info)")


# -----------------------------------------------------------------------------
# ContractManager test
# -----------------------------------------------------------------------------
func _test_contract_manager() -> void:
	var cm: Node = _S("ContractManager")
	if not cm:
		print("ContractManager not available")
		return
	
	# Day 1 contracts
	if cm.has_method("refresh_contracts_for_day"):
		cm.refresh_contracts_for_day(1)
	
	var contracts: Array = []
	if cm.has_method("get_active_contracts"):
		contracts = cm.get_active_contracts()
	print("Active contracts: ", contracts.size())
	for c in contracts:
		var title: String = String(c.get("title", ""))
		var reward: int = int(c.get("reward", 0))
		var exp_day: int = int(c.get("expires_on", 0))
		print("- ", title, " ($", reward, ", expires day ", exp_day, ")")
	
	if contracts.size() > 0:
		var first: Dictionary = contracts[0]
		var cid: int = int(first.get("id", -1))
		var accepted: bool = false
		if cm.has_method("accept_contract"):
			accepted = cm.accept_contract(cid)
		print("Accepted '", first.get('title',''), "': ", accepted)
		
		if accepted and cm.has_method("submit_delivery"):
			var delivered: bool = cm.submit_delivery(cid, {})
			print("Submitted delivery (placeholder): ", delivered)


# -----------------------------------------------------------------------------
# ProcessingManager test
# -----------------------------------------------------------------------------
func _test_processing_manager() -> void:
	var pm: Node = _S("ProcessingManager")
	if not pm:
		print("ProcessingManager not available")
		return
	
	# Quick recipe to avoid long waits
	if pm.has_method("add_recipe"):
		pm.add_recipe("z_quick", {
			"inputs": {"wheat": 1},
			"outputs": {"flour": 1},
			"duration": 1.0
		})
	
	var mid: String = "mill_test_z"
	var registered: bool = pm.register_machine(mid, "mill", Vector2i(0, 0))
	print("Machine registered: ", registered)
	var inputs_added: bool = pm.add_item_to_machine(mid, "wheat", 1, true)
	print("Inputs added: ", inputs_added)
	
	# Force PLAYING so processing updates tick
	var gm: Node = _S("GameManager")
	var had_game_state: bool = gm != null and ("current_state" in gm) and ("GameState" in gm)
	var prev_state: int = -1
	if had_game_state:
		prev_state = int(gm.current_state)
		gm.current_state = gm.GameState.PLAYING
	
	var started: bool = pm.start_processing(mid, "z_quick")
	print("Processing started: ", started)
	if not started:
		if had_game_state and prev_state != -1:
			gm.current_state = prev_state
		return
	
	await get_tree().create_timer(1.3).timeout
	
	var machines: Dictionary = pm.machines
	if mid in machines:
		var outputs: Dictionary = machines[mid]["inventory"]["outputs"]
		print("Machine outputs: ", outputs)
	else:
		print("Machine not found after processing")
	
	if had_game_state and prev_state != -1:
		gm.current_state = prev_state


# -----------------------------------------------------------------------------
# NetworkManager test
# -----------------------------------------------------------------------------
func _test_network_manager() -> void:
	var nm: Node = _S("NetworkManager")
	if not nm:
		print("NetworkManager not available")
		return
	
	# Clean slate then host
	if nm.has_method("leave"):
		nm.leave()
	await get_tree().create_timer(0.1).timeout
	
	var started: bool = false
	if nm.has_method("host"):
		started = nm.host(25252)
	print("Host started: ", started)
	if not started:
		return
	
	# Observe incoming network events (including local call_local)
	if nm.has_signal("event_received"):
		if not nm.is_connected("event_received", Callable(self, "_on_net_event")):
			nm.event_received.connect(_on_net_event)
	
	# Send a local event
	if nm.has_method("send_event"):
		nm.send_event("z_test_ping", {"msg": "hello"})
	await get_tree().create_timer(0.2).timeout
	
	nm.leave()
	if nm.has_method("is_network_active"):
		print("Left session. Active: ", nm.is_network_active())
	else:
		print("Left session.")


func _on_net_event(event_name: String, payload: Dictionary, from_peer: int) -> void:
	print("[NET EVENT] ", event_name, " from ", from_peer, ": ", payload)


# -----------------------------------------------------------------------------
# SaveManager test
# -----------------------------------------------------------------------------
func _test_save_manager() -> void:
	var sm: Node = _S("SaveManager")
	if not sm:
		print("SaveManager not available")
		return
	
	var ok: bool = false
	if sm.has_method("quick_save"):
		ok = sm.quick_save()
	print("Quick save: ", ok)
	
	var files: Array = []
	if sm.has_method("list_saves"):
		files = sm.list_saves()
	print("Saves: ", files)
	
	var loaded: bool = false
	if sm.has_method("quick_load"):
		loaded = sm.quick_load()
	print("Quick load: ", loaded)


# -----------------------------------------------------------------------------
# InnovationManager test
# -----------------------------------------------------------------------------
func _test_innovation_manager() -> void:
	var im: Node = _S("InnovationManager")
	if not im:
		print("InnovationManager not available")
		return
	
	if im.has_method("get_debug_info"):
		print("Before XP: ", im.get_debug_info())
	if im.has_method("add_xp"):
		im.add_xp(175, "z_test")
	var u1: bool = false
	var u2: bool = false
	if im.has_method("unlock"):
		u1 = im.unlock("economy_1")
		u2 = im.unlock("processing_1")
	print("Unlock results: ", u1, ", ", u2)
	if im.has_method("apply_run_modifiers"):
		im.apply_run_modifiers()
	if im.has_method("get_debug_info"):
		print("After XP+Unlocks: ", im.get_debug_info())
	
	# Export/import roundtrip
	var meta: Dictionary = {}
	if im.has_method("export_meta_state"):
		meta = im.export_meta_state()
	if im.has_method("reset_meta"):
		im.reset_meta()
	var reimported: bool = false
	if im.has_method("import_meta_state"):
		reimported = im.import_meta_state(meta)
	print("Meta reimported: ", reimported)
	if im.has_method("get_debug_info"):
		print("Now: ", im.get_debug_info())


# -----------------------------------------------------------------------------
# AudioManager test
# -----------------------------------------------------------------------------
func _test_audio_manager() -> void:
	var am: Node = _S("AudioManager")
	if not am:
		print("AudioManager not available")
		return
	
	if am.has_method("set_volume"):
		am.set_volume("Master", 0.8)
		am.set_volume("Music", 0.6)
		am.set_volume("SFX", 0.9)
	if am.has_method("set_muted"):
		am.set_muted("Music", false)
	
	# Attempt to play unregistered tracks (should warn but not crash)
	var ok_bgm: bool = false
	var ok_sfx: bool = false
	if am.has_method("play_bgm"):
		ok_bgm = am.play_bgm("menu")
	if am.has_method("play_sfx"):
		ok_sfx = am.play_sfx("click")
	print("Play bgm/menu: ", ok_bgm, " | Play sfx/click: ", ok_sfx)
	if am.has_method("get_debug_info"):
		print("Audio debug: ", am.get_debug_info())


# -----------------------------------------------------------------------------
# UIManager test
# -----------------------------------------------------------------------------
func _test_ui_manager() -> void:
	var ui: Node = _S("UIManager")
	if not ui:
		print("UIManager not available")
		return
	
	# 0 = UI (per UIManager enum InputMode { UI, GAME })
	if ui.has_method("set_input_mode"):
		ui.set_input_mode(0)
	if ui.has_method("get_debug_info"):
		print("UI after set UI mode: ", ui.get_debug_info())
	# If you later register screens/overlays, you can test show/hide here:
	# ui.register_screen("menu", "res://scenes/main/Menu.tscn")
	# ui.show_screen("menu")
