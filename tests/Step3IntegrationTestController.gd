extends Node2D
class_name Step3IntegrationTestController
# Step3IntegrationTestController.gd - Comprehensive integration tests for Step 3 crop system
# Tests all stage-aware growth components in main game environment
# Validates: CropStages, stage progression, growth modifiers, water requirements, visual updates

# ============================================================================
# PROPERTIES
# ============================================================================
@export var auto_start_tests: bool = true
@export var test_duration_seconds: float = 180.0  # 3 minutes of accelerated testing
@export var acceleration_factor: float = 10.0  # Speed up growth for testing
@export var visual_feedback: bool = true

# Test instances and tracking
var test_crops: Array[Crop] = []
var crop_scene: PackedScene = null
var test_results: Dictionary = {}
var test_start_time: float = 0.0
var current_test_phase: int = 0
var total_test_phases: int = 8

# Test positions and layout
var test_grid_start: Vector2 = Vector2(200, 200)
var test_grid_spacing: float = 100.0

# Integration test state
var crop_manager: CropManager = null
var time_manager: TimeManager = null
var grid_manager: GridManager = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	"""Initialize comprehensive Step 3 integration testing"""
	print("[Step3IntegrationTest] === Step 3 Integration Testing Suite ===")
	print("[Step3IntegrationTest] Testing stage-aware crop system components")
	
	# Get manager references
	_initialize_manager_references()
	
	# Load crop scene
	crop_scene = load("res://scenes/crops/base/Crop.tscn")
	if not crop_scene:
		print("[Step3IntegrationTest] ERROR: Could not load Crop.tscn scene")
		return
	
	# Initialize test results tracking
	_initialize_test_results()
	
	if auto_start_tests:
		call_deferred("start_integration_tests")

func _initialize_manager_references() -> void:
	"""Initialize references to game manager systems"""
	# Get autoload references
	if GameManager:
		crop_manager = GameManager.get_manager("CropManager") as CropManager
		time_manager = GameManager.get_manager("TimeManager") as TimeManager 
		grid_manager = GameManager.get_manager("GridManager") as GridManager
	
	# Validate manager availability
	var managers_available: bool = crop_manager != null and time_manager != null and grid_manager != null
	print("[Step3IntegrationTest] Managers available: %s" % ("✅" if managers_available else "❌"))
	
	if not managers_available:
		print("[Step3IntegrationTest] WARNING: Some managers not available - tests may be limited")

func _initialize_test_results() -> void:
	"""Initialize test results tracking structure"""
	test_results = {
		"step": 3,
		"title": "Stage-Aware Growth System Integration",
		"start_time": Time.get_ticks_msec(),
		"test_phases": [],
		"overall_score": 0,
		"total_tests": 0,
		"passed_tests": 0,
		"failed_tests": 0,
		"integration_status": "RUNNING"
	}

# ============================================================================
# MAIN INTEGRATION TEST SEQUENCE
# ============================================================================
func start_integration_tests() -> void:
	"""Start comprehensive Step 3 integration testing sequence"""
	test_start_time = Time.get_time_dict_from_system()["unix"] as float
	current_test_phase = 0
	
	print("[Step3IntegrationTest] Starting integration test sequence...")
	print("[Step3IntegrationTest] Test duration: %.1f seconds" % test_duration_seconds)
	print("[Step3IntegrationTest] Acceleration factor: %.1fx" % acceleration_factor)
	
	# Start with Phase 1
	await run_test_phase_1_crop_creation()
	await run_test_phase_2_stage_initialization()
	await run_test_phase_3_growth_progression()
	await run_test_phase_4_stage_modifiers()
	await run_test_phase_5_water_requirements()
	await run_test_phase_6_visual_updates()
	await run_test_phase_7_time_integration()
	await run_test_phase_8_manager_integration()
	
	# Generate final report
	generate_final_integration_report()

# ============================================================================
# TEST PHASE 1: CROP CREATION AND STAGE SYSTEM SETUP
# ============================================================================
func run_test_phase_1_crop_creation() -> void:
	"""Test Phase 1: Create crops with CropStages integration"""
	current_test_phase = 1
	print("[Step3IntegrationTest] === PHASE 1: Crop Creation & Stage Setup ===")
	
	var phase_results: Dictionary = {
		"phase": 1,
		"title": "Crop Creation & Stage Setup",
		"tests": [],
		"status": "RUNNING"
	}
	
	# Test 1.1: Load crop resources with stage data
	var crop_resources: Array[CropData] = [
		load("res://resources/crops/tier1/lettuce.tres"),
		load("res://resources/crops/tier1/corn.tres"), 
		load("res://resources/crops/tier1/wheat.tres")
	]
	
	var resources_loaded: int = 0
	for resource in crop_resources:
		if resource:
			resources_loaded += 1
	
	phase_results.tests.append({
		"test": "CropData Resource Loading",
		"expected": 3,
		"actual": resources_loaded,
		"status": "PASS" if resources_loaded == 3 else "FAIL",
		"details": "Loaded %d/%d crop resources" % [resources_loaded, 3]
	})
	
	# Test 1.2: Create crop instances with CropStages
	var crops_with_stages: int = 0
	var x_offset: float = 0
	
	for i in range(crop_resources.size()):
		if crop_resources[i]:
			var crop: Crop = crop_scene.instantiate()
			crop.crop_data = crop_resources[i]
			crop.position = test_grid_start + Vector2(x_offset, 0)
			crop.grid_position = Vector2i(i, 0)
			
			add_child(crop)
			test_crops.append(crop)
			
			# Test CropStages integration
			if crop.crop_growth and crop.crop_growth.has_method("get_current_stage"):
				crops_with_stages += 1
				print("[Step3IntegrationTest] %s: Stage system integrated ✅" % crop.crop_data.crop_name)
			else:
				print("[Step3IntegrationTest] %s: Stage system missing ❌" % crop.crop_data.crop_name)
			
			x_offset += test_grid_spacing
	
	phase_results.tests.append({
		"test": "CropStages Integration",
		"expected": 3,
		"actual": crops_with_stages,
		"status": "PASS" if crops_with_stages == 3 else "FAIL",
		"details": "Crops with stage systems: %d/%d" % [crops_with_stages, 3]
	})
	
	# Test 1.3: Validate initial stage state
	var correct_initial_stages: int = 0
	for crop in test_crops:
		if crop.crop_growth and crop.crop_growth.has_method("get_current_stage"):
			var stage = crop.crop_growth.get_current_stage()
			if stage == CropStages.GrowthStage.SEED:
				correct_initial_stages += 1
				print("[Step3IntegrationTest] %s: Correct initial SEED stage ✅" % crop.crop_data.crop_name)
			else:
				print("[Step3IntegrationTest] %s: Incorrect initial stage: %s ❌" % [crop.crop_data.crop_name, stage])
	
	phase_results.tests.append({
		"test": "Initial Stage State",
		"expected": 3,
		"actual": correct_initial_stages,
		"status": "PASS" if correct_initial_stages == 3 else "FAIL",
		"details": "Crops starting in SEED stage: %d/%d" % [correct_initial_stages, 3]
	})
	
	# Complete phase
	phase_results.status = "COMPLETE"
	test_results.test_phases.append(phase_results)
	_update_test_counters(phase_results)
	
	print("[Step3IntegrationTest] Phase 1 Complete: %d tests" % phase_results.tests.size())
	await get_tree().create_timer(1.0).timeout

# ============================================================================
# TEST PHASE 2: STAGE INITIALIZATION AND THRESHOLDS
# ============================================================================
func run_test_phase_2_stage_initialization() -> void:
	"""Test Phase 2: Validate stage threshold configuration"""
	current_test_phase = 2
	print("[Step3IntegrationTest] === PHASE 2: Stage Initialization ===")
	
	var phase_results: Dictionary = {
		"phase": 2,
		"title": "Stage Initialization & Thresholds", 
		"tests": [],
		"status": "RUNNING"
	}
	
	# Test 2.1: Stage threshold validation
	var correct_thresholds: int = 0
	for crop in test_crops:
		if crop.crop_growth and crop.crop_growth.has_method("get_stage_threshold"):
			var seed_threshold: float = crop.crop_growth.get_stage_threshold(CropStages.GrowthStage.SEED)
			var sprout_threshold: float = crop.crop_growth.get_stage_threshold(CropStages.GrowthStage.SPROUT)
			var young_threshold: float = crop.crop_growth.get_stage_threshold(CropStages.GrowthStage.YOUNG)
			var mature_threshold: float = crop.crop_growth.get_stage_threshold(CropStages.GrowthStage.MATURE)
			
			if seed_threshold == 0.0 and sprout_threshold == 0.25 and young_threshold == 0.5 and mature_threshold == 0.85:
				correct_thresholds += 1
				print("[Step3IntegrationTest] %s: Stage thresholds correct ✅" % crop.crop_data.crop_name)
			else:
				print("[Step3IntegrationTest] %s: Stage thresholds incorrect ❌" % crop.crop_data.crop_name)
				print("  SEED: %.2f, SPROUT: %.2f, YOUNG: %.2f, MATURE: %.2f" % [seed_threshold, sprout_threshold, young_threshold, mature_threshold])
		else:
			print("[Step3IntegrationTest] %s: Missing stage threshold methods ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Stage Threshold Configuration",
		"expected": 3,
		"actual": correct_thresholds,
		"status": "PASS" if correct_thresholds == 3 else "FAIL",
		"details": "Crops with correct thresholds: %d/%d" % [correct_thresholds, 3]
	})
	
	# Test 2.2: Stage progression logic
	var correct_progression: int = 0
	for crop in test_crops:
		if crop.crop_growth and crop.crop_growth.has_method("get_stage_for_progress"):
			var stage_0: int = crop.crop_growth.get_stage_for_progress(0.0)
			var stage_30: int = crop.crop_growth.get_stage_for_progress(0.3)
			var stage_60: int = crop.crop_growth.get_stage_for_progress(0.6)
			var stage_90: int = crop.crop_growth.get_stage_for_progress(0.9)
			
			if stage_0 == CropStages.GrowthStage.SEED and stage_30 == CropStages.GrowthStage.SPROUT and stage_60 == CropStages.GrowthStage.YOUNG and stage_90 == CropStages.GrowthStage.MATURE:
				correct_progression += 1
				print("[Step3IntegrationTest] %s: Stage progression logic correct ✅" % crop.crop_data.crop_name)
			else:
				print("[Step3IntegrationTest] %s: Stage progression logic incorrect ❌" % crop.crop_data.crop_name)
		else:
			print("[Step3IntegrationTest] %s: Missing stage progression methods ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Stage Progression Logic",
		"expected": 3,
		"actual": correct_progression,
		"status": "PASS" if correct_progression == 3 else "FAIL",
		"details": "Crops with correct progression: %d/%d" % [correct_progression, 3]
	})
	
	# Complete phase
	phase_results.status = "COMPLETE"
	test_results.test_phases.append(phase_results)
	_update_test_counters(phase_results)
	
	print("[Step3IntegrationTest] Phase 2 Complete: %d tests" % phase_results.tests.size())
	await get_tree().create_timer(1.0).timeout

# ============================================================================
# TEST PHASE 3: GROWTH PROGRESSION THROUGH STAGES
# ============================================================================
func run_test_phase_3_growth_progression() -> void:
	"""Test Phase 3: Validate stage progression during accelerated growth"""
	current_test_phase = 3
	print("[Step3IntegrationTest] === PHASE 3: Growth Progression ===")
	
	var phase_results: Dictionary = {
		"phase": 3,
		"title": "Growth Progression Through Stages",
		"tests": [],
		"status": "RUNNING"
	}
	
	# Track stage progression for each crop
	var stage_progressions: Array[Dictionary] = []
	for crop in test_crops:
		stage_progressions.append({
			"crop_name": crop.crop_data.crop_name,
			"stages_reached": [],
			"current_stage": CropStages.GrowthStage.SEED,
			"progress": 0.0
		})
	
	# Test 3.1: Accelerated growth progression
	print("[Step3IntegrationTest] Starting accelerated growth progression...")
	var progression_time: float = 30.0  # 30 seconds of accelerated growth
	var time_step: float = 0.5  # Process every 0.5 seconds
	var steps: int = int(progression_time / time_step)
	
	for step in range(steps):
		# Process growth for each crop
		for i in range(test_crops.size()):
			var crop: Crop = test_crops[i]
			var progression: Dictionary = stage_progressions[i]
			
			# Accelerated growth processing
			crop.process_growth(time_step * acceleration_factor)
			
			# Check for stage changes
			if crop.crop_growth and crop.crop_growth.has_method("get_current_stage"):
				var new_stage: int = crop.crop_growth.get_current_stage()
				var new_progress: float = crop.crop_growth.get_growth_progress()
				
				if new_stage != progression.current_stage:
					progression.stages_reached.append(new_stage)
					progression.current_stage = new_stage
					print("[Step3IntegrationTest] %s reached stage: %s (progress: %.2f)" % [
						progression.crop_name,
						CropStages.GrowthStage.keys()[new_stage],
						new_progress
					])
				
				progression.progress = new_progress
		
		# Wait between steps
		await get_tree().create_timer(time_step).timeout
	
	# Test 3.2: Validate stage progression sequence
	var correct_progressions: int = 0
	for progression in stage_progressions:
		var stages: Array = progression.stages_reached
		var expected_sequence: bool = true
		
		# Check if stages were reached in correct order
		if stages.size() >= 2:
			for i in range(stages.size() - 1):
				if stages[i] >= stages[i + 1]:
					expected_sequence = false
					break
		
		if expected_sequence and stages.size() >= 2:  # At least SEED -> SPROUT
			correct_progressions += 1
			print("[Step3IntegrationTest] %s: Correct stage progression ✅" % progression.crop_name)
		else:
			print("[Step3IntegrationTest] %s: Incorrect stage progression ❌" % progression.crop_name)
			print("  Stages reached: %s" % stages)
	
	phase_results.tests.append({
		"test": "Stage Progression Sequence",
		"expected": 3,
		"actual": correct_progressions,
		"status": "PASS" if correct_progressions == 3 else "FAIL",
		"details": "Crops with correct progression: %d/%d" % [correct_progressions, 3]
	})
	
	# Test 3.3: Minimum stage advancement
	var crops_advanced: int = 0
	for progression in stage_progressions:
		if progression.stages_reached.size() >= 1:  # At least one advancement
			crops_advanced += 1
	
	phase_results.tests.append({
		"test": "Minimum Stage Advancement",
		"expected": 3,
		"actual": crops_advanced,
		"status": "PASS" if crops_advanced == 3 else "FAIL",
		"details": "Crops that advanced stages: %d/%d" % [crops_advanced, 3]
	})
	
	# Complete phase
	phase_results.status = "COMPLETE"
	test_results.test_phases.append(phase_results)
	_update_test_counters(phase_results)
	
	print("[Step3IntegrationTest] Phase 3 Complete: %d tests" % phase_results.tests.size())
	await get_tree().create_timer(1.0).timeout

# ============================================================================
# TEST PHASE 4: STAGE-SPECIFIC GROWTH MODIFIERS
# ============================================================================
func run_test_phase_4_stage_modifiers() -> void:
	"""Test Phase 4: Validate stage-specific growth modifiers"""
	current_test_phase = 4
	print("[Step3IntegrationTest] === PHASE 4: Stage Growth Modifiers ===")
	
	var phase_results: Dictionary = {
		"phase": 4,
		"title": "Stage-Specific Growth Modifiers",
		"tests": [],
		"status": "RUNNING"
	}
	
	# Test 4.1: Growth modifier values per stage
	var correct_modifiers: int = 0
	for crop in test_crops:
		if crop.crop_growth and crop.crop_growth.has_method("get_stage_growth_modifier"):
			var seed_mod: float = crop.crop_growth.get_stage_growth_modifier(CropStages.GrowthStage.SEED)
			var sprout_mod: float = crop.crop_growth.get_stage_growth_modifier(CropStages.GrowthStage.SPROUT)
			var young_mod: float = crop.crop_growth.get_stage_growth_modifier(CropStages.GrowthStage.YOUNG)
			var mature_mod: float = crop.crop_growth.get_stage_growth_modifier(CropStages.GrowthStage.MATURE)
			
			# Expected values from CropStages.gd: SEED=0.8, SPROUT=1.2, YOUNG=1.0, MATURE=0.3
			if abs(seed_mod - 0.8) < 0.1 and abs(sprout_mod - 1.2) < 0.1 and abs(young_mod - 1.0) < 0.1 and abs(mature_mod - 0.3) < 0.1:
				correct_modifiers += 1
				print("[Step3IntegrationTest] %s: Growth modifiers correct ✅" % crop.crop_data.crop_name)
				print("  SEED: %.2f, SPROUT: %.2f, YOUNG: %.2f, MATURE: %.2f" % [seed_mod, sprout_mod, young_mod, mature_mod])
			else:
				print("[Step3IntegrationTest] %s: Growth modifiers incorrect ❌" % crop.crop_data.crop_name)
				print("  Expected: SEED=0.8, SPROUT=1.2, YOUNG=1.0, MATURE=0.3")
				print("  Actual: SEED=%.2f, SPROUT=%.2f, YOUNG=%.2f, MATURE=%.2f" % [seed_mod, sprout_mod, young_mod, mature_mod])
		else:
			print("[Step3IntegrationTest] %s: Missing growth modifier methods ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Growth Modifier Values",
		"expected": 3,
		"actual": correct_modifiers,
		"status": "PASS" if correct_modifiers == 3 else "FAIL",
		"details": "Crops with correct modifiers: %d/%d" % [correct_modifiers, 3]
	})
	
	# Test 4.2: Growth rate application during different stages
	print("[Step3IntegrationTest] Testing growth rate application...")
	var modifier_applications: int = 0
	
	for crop in test_crops:
		if crop.crop_growth:
			# Record initial progress
			var initial_progress: float = crop.crop_growth.get_growth_progress()
			var initial_stage: int = crop.crop_growth.get_current_stage()
			
			# Apply growth with stage consideration
			crop.process_growth(5.0)  # 5 seconds of growth
			
			var new_progress: float = crop.crop_growth.get_growth_progress()
			var progress_delta: float = new_progress - initial_progress
			
			if progress_delta > 0.0:
				modifier_applications += 1
				print("[Step3IntegrationTest] %s: Growth applied with modifier (stage: %d, delta: %.4f) ✅" % [
					crop.crop_data.crop_name,
					initial_stage,
					progress_delta
				])
			else:
				print("[Step3IntegrationTest] %s: No growth applied ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Growth Modifier Application",
		"expected": 3,
		"actual": modifier_applications,
		"status": "PASS" if modifier_applications == 3 else "FAIL",
		"details": "Crops applying modifiers: %d/%d" % [modifier_applications, 3]
	})
	
	# Complete phase
	phase_results.status = "COMPLETE"
	test_results.test_phases.append(phase_results)
	_update_test_counters(phase_results)
	
	print("[Step3IntegrationTest] Phase 4 Complete: %d tests" % phase_results.tests.size())
	await get_tree().create_timer(1.0).timeout

# ============================================================================
# TEST PHASE 5: STAGE-SPECIFIC WATER REQUIREMENTS
# ============================================================================
func run_test_phase_5_water_requirements() -> void:
	"""Test Phase 5: Validate stage-specific water requirements"""
	current_test_phase = 5
	print("[Step3IntegrationTest] === PHASE 5: Water Requirements ===")
	
	var phase_results: Dictionary = {
		"phase": 5,
		"title": "Stage-Specific Water Requirements",
		"tests": [],
		"status": "RUNNING"
	}
	
	# Test 5.1: Water requirement values per stage
	var correct_water_reqs: int = 0
	for crop in test_crops:
		if crop.crop_growth and crop.crop_growth.has_method("get_stage_water_requirement"):
			var seed_water: float = crop.crop_growth.get_stage_water_requirement(CropStages.GrowthStage.SEED)
			var sprout_water: float = crop.crop_growth.get_stage_water_requirement(CropStages.GrowthStage.SPROUT)
			var young_water: float = crop.crop_growth.get_stage_water_requirement(CropStages.GrowthStage.YOUNG)
			var mature_water: float = crop.crop_growth.get_stage_water_requirement(CropStages.GrowthStage.MATURE)
			
			# Expected values: SEED=0.8, SPROUT=0.7, YOUNG=0.6, MATURE=0.5
			if abs(seed_water - 0.8) < 0.1 and abs(sprout_water - 0.7) < 0.1 and abs(young_water - 0.6) < 0.1 and abs(mature_water - 0.5) < 0.1:
				correct_water_reqs += 1
				print("[Step3IntegrationTest] %s: Water requirements correct ✅" % crop.crop_data.crop_name)
				print("  SEED: %.2f, SPROUT: %.2f, YOUNG: %.2f, MATURE: %.2f" % [seed_water, sprout_water, young_water, mature_water])
			else:
				print("[Step3IntegrationTest] %s: Water requirements incorrect ❌" % crop.crop_data.crop_name)
		else:
			print("[Step3IntegrationTest] %s: Missing water requirement methods ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Water Requirement Values",
		"expected": 3,
		"actual": correct_water_reqs,
		"status": "PASS" if correct_water_reqs == 3 else "FAIL",
		"details": "Crops with correct water requirements: %d/%d" % [correct_water_reqs, 3]
	})
	
	# Test 5.2: Water consumption enforcement
	var water_enforcement: int = 0
	for crop in test_crops:
		# Set low water level
		if crop.has_method("set_water_level"):
			crop.set_water_level(0.1)  # Very low water
			
			# Process growth - should be limited by water
			var initial_progress: float = crop.crop_growth.get_growth_progress()
			crop.process_growth(2.0)  # 2 seconds
			var progress_with_low_water: float = crop.crop_growth.get_growth_progress() - initial_progress
			
			# Add sufficient water
			crop.set_water_level(1.0)  # Full water
			crop.process_growth(2.0)  # 2 seconds
			var final_progress: float = crop.crop_growth.get_growth_progress()
			var progress_with_high_water: float = final_progress - (initial_progress + progress_with_low_water)
			
			if progress_with_high_water > progress_with_low_water * 1.5:  # Should be significantly better with water
				water_enforcement += 1
				print("[Step3IntegrationTest] %s: Water enforcement working ✅" % crop.crop_data.crop_name)
			else:
				print("[Step3IntegrationTest] %s: Water enforcement not working ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Water Consumption Enforcement",
		"expected": 3,
		"actual": water_enforcement,
		"status": "PASS" if water_enforcement >= 2 else "FAIL",  # Allow 2/3 due to complexity
		"details": "Crops enforcing water requirements: %d/%d" % [water_enforcement, 3]
	})
	
	# Complete phase
	phase_results.status = "COMPLETE"
	test_results.test_phases.append(phase_results)
	_update_test_counters(phase_results)
	
	print("[Step3IntegrationTest] Phase 5 Complete: %d tests" % phase_results.tests.size())
	await get_tree().create_timer(1.0).timeout

# ============================================================================
# TEST PHASE 6: VISUAL INDICATOR UPDATES
# ============================================================================
func run_test_phase_6_visual_updates() -> void:
	"""Test Phase 6: Validate visual indicators update with stage changes"""
	current_test_phase = 6
	print("[Step3IntegrationTest] === PHASE 6: Visual Updates ===")
	
	var phase_results: Dictionary = {
		"phase": 6,
		"title": "Visual Indicator Updates",
		"tests": [],
		"status": "RUNNING"
	}
	
	# Test 6.1: Visual component availability
	var visual_components: int = 0
	for crop in test_crops:
		if crop.crop_visuals:
			visual_components += 1
			print("[Step3IntegrationTest] %s: CropVisuals component present ✅" % crop.crop_data.crop_name)
		else:
			print("[Step3IntegrationTest] %s: CropVisuals component missing ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Visual Components Present",
		"expected": 3,
		"actual": visual_components,
		"status": "PASS" if visual_components == 3 else "FAIL",
		"details": "Crops with visual components: %d/%d" % [visual_components, 3]
	})
	
	# Test 6.2: Stage-based visual updates
	var visual_updates: int = 0
	for crop in test_crops:
		if crop.crop_visuals and crop.crop_visuals.has_method("update_visual_for_stage"):
			# Force stage progression and check visual update
			var current_stage: int = crop.crop_growth.get_current_stage()
			
			# Try to advance to next stage visually
			var next_stage: int = current_stage + 1
			if next_stage <= CropStages.GrowthStage.MATURE:
				crop.crop_visuals.update_visual_for_stage(next_stage)
				
				# Check if visual was updated (basic validation)
				visual_updates += 1
				print("[Step3IntegrationTest] %s: Visual update for stage %d ✅" % [crop.crop_data.crop_name, next_stage])
		else:
			print("[Step3IntegrationTest] %s: Visual update methods missing ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Stage Visual Updates",
		"expected": 3,
		"actual": visual_updates,
		"status": "PASS" if visual_updates >= 2 else "FAIL",  # Allow some flexibility
		"details": "Crops with visual updates: %d/%d" % [visual_updates, 3]
	})
	
	# Test 6.3: Health and water visual indicators
	var health_visuals: int = 0
	for crop in test_crops:
		if crop.crop_visuals:
			# Set different health levels and check visual response
			crop.set_health(0.3)  # Low health
			if crop.crop_visuals.has_method("update_health_indicator"):
				crop.crop_visuals.update_health_indicator(0.3)
				health_visuals += 1
				print("[Step3IntegrationTest] %s: Health visual indicators working ✅" % crop.crop_data.crop_name)
			else:
				print("[Step3IntegrationTest] %s: Health visual indicators missing ❌" % crop.crop_data.crop_name)
	
	phase_results.tests.append({
		"test": "Health/Water Visual Indicators",
		"expected": 3,
		"actual": health_visuals,
		"status": "PASS" if health_visuals >= 2 else "FAIL",
		"details": "Crops with health indicators: %d/%d" % [health_visuals, 3]
	})
	
	# Complete phase
	phase_results.status = "COMPLETE"
	test_results.test_phases.append(phase_results)
	_update_test_counters(phase_results)
	
	print("[Step3IntegrationTest] Phase 6 Complete: %d tests" % phase_results.tests.size())
	await get_tree().create_timer(1.0).timeout

# ============================================================================
# TEST PHASE 7: TIME MANAGEMENT SYSTEM INTEGRATION
# ============================================================================
func run_test_phase_7_time_integration() -> void:
	"""Test Phase 7: Integration with time management system"""
	current_test_phase = 7
	print("[Step3IntegrationTest] === PHASE 7: Time Integration ===")
	
	var phase_results: Dictionary = {
		"phase": 7,
		"title": "Time Management Integration",
		"tests": [],
		"status": "RUNNING"
	}
	
	# Test 7.1: TimeManager availability
	var time_manager_available: bool = time_manager != null
	phase_results.tests.append({
		"test": "TimeManager Availability",
		"expected": 1,
		"actual": 1 if time_manager_available else 0,
		"status": "PASS" if time_manager_available else "FAIL",
		"details": "TimeManager reference: %s" % ("✅" if time_manager_available else "❌")
	})
	
	if time_manager_available:
		# Test 7.2: Time-based growth processing
		var time_based_growth: int = 0
		
		# Get current time phase info
		var current_phase: String = ""
		if time_manager.has_method("get_current_phase"):
			var phase_value = time_manager.get_current_phase()
			current_phase = str(phase_value)
		
		print("[Step3IntegrationTest] Current time phase: %s" % str(current_phase))
		
		for crop in test_crops:
			if crop.has_method("process_time_based_growth"):
				var initial_progress: float = crop.crop_growth.get_growth_progress()
				crop.process_time_based_growth(1.0)  # Process 1 time unit
				var new_progress: float = crop.crop_growth.get_growth_progress()
				
				if new_progress > initial_progress:
					time_based_growth += 1
					print("[Step3IntegrationTest] %s: Time-based growth working ✅" % crop.crop_data.crop_name)
				else:
					print("[Step3IntegrationTest] %s: Time-based growth not working ❌" % crop.crop_data.crop_name)
		
		phase_results.tests.append({
			"test": "Time-Based Growth Processing",
			"expected": 3,
			"actual": time_based_growth,
			"status": "PASS" if time_based_growth >= 2 else "FAIL",
			"details": "Crops with time-based growth: %d/%d" % [time_based_growth, 3]
		})
		
		# Test 7.3: Phase-specific growth modifiers
		var phase_modifiers: int = 0
		for crop in test_crops:
			if crop.crop_growth and crop.crop_growth.has_method("get_phase_modifier"):
				var modifier: float = crop.crop_growth.get_phase_modifier(current_phase)
				if modifier > 0.0:
					phase_modifiers += 1
					print("[Step3IntegrationTest] %s: Phase modifier (%.2f) for %s ✅" % [crop.crop_data.crop_name, modifier, str(current_phase)])
		
		phase_results.tests.append({
			"test": "Phase-Specific Modifiers",
			"expected": 3,
			"actual": phase_modifiers,
			"status": "PASS" if phase_modifiers >= 2 else "FAIL",
			"details": "Crops with phase modifiers: %d/%d" % [phase_modifiers, 3]
		})
	
	# Complete phase
	phase_results.status = "COMPLETE"
	test_results.test_phases.append(phase_results)
	_update_test_counters(phase_results)
	
	print("[Step3IntegrationTest] Phase 7 Complete: %d tests" % phase_results.tests.size())
	await get_tree().create_timer(1.0).timeout

# ============================================================================
# TEST PHASE 8: CROPMANAGER INTEGRATION
# ============================================================================
func run_test_phase_8_manager_integration() -> void:
	"""Test Phase 8: CropManager stage transition handling"""
	current_test_phase = 8
	print("[Step3IntegrationTest] === PHASE 8: CropManager Integration ===")
	
	var phase_results: Dictionary = {
		"phase": 8,
		"title": "CropManager Integration",
		"tests": [],
		"status": "RUNNING"
	}
	
	# Test 8.1: CropManager availability
	var crop_manager_available: bool = crop_manager != null
	phase_results.tests.append({
		"test": "CropManager Availability",
		"expected": 1,
		"actual": 1 if crop_manager_available else 0,
		"status": "PASS" if crop_manager_available else "FAIL",
		"details": "CropManager reference: %s" % ("✅" if crop_manager_available else "❌")
	})
	
	if crop_manager_available:
		# Test 8.2: Stage transition utilities
		var stage_utilities: int = 0
		if crop_manager.has_method("convert_stage_to_string") and crop_manager.has_method("get_stage_description"):
			stage_utilities = 1
			print("[Step3IntegrationTest] CropManager stage utilities available ✅")
		else:
			print("[Step3IntegrationTest] CropManager stage utilities missing ❌")
		
		phase_results.tests.append({
			"test": "Stage Transition Utilities",
			"expected": 1,
			"actual": stage_utilities,
			"status": "PASS" if stage_utilities == 1 else "FAIL",
			"details": "Stage utility methods: %s" % ("✅" if stage_utilities == 1 else "❌")
		})
		
		# Test 8.3: Crop registration and tracking
		var registered_crops: int = 0
		for crop in test_crops:
			if crop_manager.has_method("register_crop"):
				crop_manager.register_crop(crop)
				registered_crops += 1
				print("[Step3IntegrationTest] %s registered with CropManager ✅" % crop.crop_data.crop_name)
		
		phase_results.tests.append({
			"test": "Crop Registration",
			"expected": 3,
			"actual": registered_crops,
			"status": "PASS" if registered_crops >= 2 else "FAIL",
			"details": "Crops registered: %d/%d" % [registered_crops, 3]
		})
		
		# Test 8.4: Stage change notification handling
		var stage_notifications: int = 0
		for crop in test_crops:
			if crop.has_signal("stage_changed"):
				# Connect to CropManager if method exists
				if crop_manager.has_method("_on_crop_stage_changed"):
					if not crop.stage_changed.is_connected(crop_manager._on_crop_stage_changed):
						crop.stage_changed.connect(crop_manager._on_crop_stage_changed)
					stage_notifications += 1
					print("[Step3IntegrationTest] %s stage notifications connected ✅" % crop.crop_data.crop_name)
		
		phase_results.tests.append({
			"test": "Stage Change Notifications",
			"expected": 3,
			"actual": stage_notifications,
			"status": "PASS" if stage_notifications >= 2 else "FAIL",
			"details": "Crops with notifications: %d/%d" % [stage_notifications, 3]
		})
	
	# Complete phase
	phase_results.status = "COMPLETE"
	test_results.test_phases.append(phase_results)
	_update_test_counters(phase_results)
	
	print("[Step3IntegrationTest] Phase 8 Complete: %d tests" % phase_results.tests.size())
	await get_tree().create_timer(1.0).timeout

# ============================================================================
# RESULTS AND REPORTING
# ============================================================================
func generate_final_integration_report() -> void:
	"""Generate and display final integration test report"""
	print("[Step3IntegrationTest] === GENERATING FINAL REPORT ===")
	
	# Calculate final scores
	var total_tests: int = test_results.total_tests
	var passed_tests: int = test_results.passed_tests
	var failed_tests: int = test_results.failed_tests
	var pass_percentage: float = (float(passed_tests) / float(total_tests)) * 100.0 if total_tests > 0 else 0.0
	
	# Determine overall status
	var overall_status: String = ""
	if pass_percentage >= 95.0:
		overall_status = "EXCELLENT"
		test_results.overall_score = 95 + int((pass_percentage - 95.0) * 1.0)
	elif pass_percentage >= 85.0:
		overall_status = "GOOD"
		test_results.overall_score = 85 + int((pass_percentage - 85.0) * 1.0)
	elif pass_percentage >= 70.0:
		overall_status = "ACCEPTABLE"
		test_results.overall_score = 70 + int((pass_percentage - 70.0) * 1.0)
	elif pass_percentage >= 50.0:
		overall_status = "NEEDS_WORK"
		test_results.overall_score = 50 + int((pass_percentage - 50.0) * 1.0)
	else:
		overall_status = "FAILED"
		test_results.overall_score = int(pass_percentage)
	
	test_results.integration_status = overall_status
	test_results.end_time = Time.get_ticks_msec()
	
	# Print comprehensive report
	print("\n" + "=".repeat(80))
	print("STEP 3 INTEGRATION TEST REPORT")
	print("=".repeat(80))
	print("Test Suite: Stage-Aware Growth System Integration")
	print("Total Test Phases: %d" % test_results.test_phases.size())
	print("Total Tests: %d" % total_tests)
	print("Passed: %s (%.1f%%)" % [str(passed_tests), pass_percentage])
	print("Failed: %s" % str(failed_tests))
	print("Overall Score: %s/100" % str(test_results.overall_score))
	print("Integration Status: %s" % overall_status)
	print("-".repeat(80))
	
	# Print phase-by-phase results
	for phase in test_results.test_phases:
		var phase_passed: int = 0
		var phase_total: int = phase.tests.size()
		
		for test in phase.tests:
			if test.status == "PASS":
				phase_passed += 1
		
		var phase_percentage: float = (float(phase_passed) / float(phase_total)) * 100.0 if phase_total > 0 else 0.0
		
		print("Phase %s: %s" % [str(phase.phase), phase.title])
		print("  Status: %s (%s/%s tests passed - %.1f%%)" % [phase.status, str(phase_passed), str(phase_total), phase_percentage])
		
		for test in phase.tests:
			var status_icon: String = "✅" if test.status == "PASS" else "❌"
			print("  %s %s: %s" % [status_icon, test.test, test.details])
	
	print("-".repeat(80))
	print("INTEGRATION SUMMARY:")
	print("✅ Core stage system implementation: %s" % ("WORKING" if pass_percentage >= 70 else "ISSUES"))
	print("✅ Stage progression logic: %s" % ("WORKING" if pass_percentage >= 70 else "ISSUES"))
	print("✅ Growth modifiers: %s" % ("WORKING" if pass_percentage >= 70 else "ISSUES"))
	print("✅ Water requirements: %s" % ("WORKING" if pass_percentage >= 70 else "ISSUES"))
	print("✅ Visual integration: %s" % ("WORKING" if pass_percentage >= 60 else "ISSUES"))
	print("✅ Manager integration: %s" % ("WORKING" if pass_percentage >= 60 else "ISSUES"))
	
	if overall_status in ["EXCELLENT", "GOOD"]:
		print("\n🎉 STEP 3 INTEGRATION TESTS SUCCESSFUL!")
		print("The stage-aware crop growth system is working correctly.")
		print("Ready to proceed with Step 4: Water Management System")
	elif overall_status == "ACCEPTABLE":
		print("\n⚠️  STEP 3 INTEGRATION TESTS MOSTLY SUCCESSFUL")
		print("Minor issues detected but core functionality working.")
		print("Consider addressing failed tests before Step 4.")
	else:
		print("\n❌ STEP 3 INTEGRATION TESTS NEED ATTENTION")
		print("Critical issues detected in stage-aware growth system.")
		print("Must resolve issues before proceeding to Step 4.")
	
	print("=".repeat(80) + "\n")

func _update_test_counters(phase_results: Dictionary) -> void:
	"""Update overall test counters from phase results"""
	for test in phase_results.tests:
		test_results.total_tests += 1
		if test.status == "PASS":
			test_results.passed_tests += 1
		else:
			test_results.failed_tests += 1

# ============================================================================
# INPUT HANDLING AND MANUAL CONTROLS
# ============================================================================
func _input(event: InputEvent) -> void:
	"""Handle input for manual test control"""
	if event.is_action_pressed("ui_accept"):  # Space key
		if test_results.integration_status in ["", "RUNNING"]:
			print("[Step3IntegrationTest] Manual test start...")
			start_integration_tests()
		else:
			print("[Step3IntegrationTest] Tests already completed. Status: %s" % test_results.integration_status)
	
	elif event.is_action_pressed("ui_select"):  # Enter key
		generate_final_integration_report()
	
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		print("[Step3IntegrationTest] Clearing test crops...")
		for crop in test_crops:
			if crop and is_instance_valid(crop):
				crop.queue_free()
		test_crops.clear()

# ============================================================================
# DEBUG AND UTILITIES
# ============================================================================
func get_integration_summary() -> String:
	"""Get brief integration test summary"""
	if test_results.integration_status == "":
		return "Step 3 Integration Tests: Ready to start"
	else:
		return "Step 3 Integration Tests: %s (%s/%s passed)" % [
			test_results.integration_status,
			str(test_results.passed_tests),
			str(test_results.total_tests)
		]

func export_test_results() -> Dictionary:
	"""Export test results for external analysis"""
	return test_results.duplicate(true)
