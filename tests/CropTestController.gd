extends Node2D
class_name CropTestController
# CropTestController.gd - Test controller for crop system validation
# Tests Step 2 completion with visual feedback and growth mechanics

# ============================================================================
# PROPERTIES
# ============================================================================
@export var test_crop_data: CropData = null
@export var auto_start_test: bool = true
@export var test_position: Vector2 = Vector2(100, 100)

# Test instances
var test_crops: Array[Crop] = []
var crop_scene: PackedScene = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready() -> void:
	"""Initialize the crop test controller"""
	print("[CropTestController] Starting crop system tests...")
	
	# Load crop scene
	crop_scene = load("res://scenes/crops/base/Crop.tscn")
	if not crop_scene:
		print("[CropTestController] ERROR: Could not load Crop.tscn scene")
		return
	
	if auto_start_test:
		call_deferred("run_step2_tests")

# ============================================================================
# STEP 2 VALIDATION TESTS
# ============================================================================
func run_step2_tests() -> void:
	"""Run comprehensive Step 2 validation tests"""
	print("[CropTestController] === Running Step 2 Validation Tests ===")
	
	# Test 1: Create crop instances with all tier 1 crops
	test_crop_creation()
	
	# Test 2: Validate visual system integration
	test_visual_system()
	
	# Test 3: Test growth progression
	test_growth_system()
	
	# Test 4: Test component communication
	test_component_integration()
	
	print("[CropTestController] === Step 2 Tests Completed ===")

func test_crop_creation() -> void:
	"""Test creating crop instances with resource data"""
	print("[CropTestController] Test 1: Crop Creation")
	
	# Load all tier 1 crop resources
	var crop_resources: Array[CropData] = [
		load("res://resources/crops/tier1/lettuce.tres"),
		load("res://resources/crops/tier1/corn.tres"),
		load("res://resources/crops/tier1/wheat.tres")
	]
	
	var x_offset: float = 0
	for crop_resource in crop_resources:
		if crop_resource:
			var crop_instance: Crop = crop_scene.instantiate()
			crop_instance.crop_data = crop_resource
			crop_instance.position = Vector2(test_position.x + x_offset, test_position.y)
			crop_instance.grid_position = Vector2i(int(x_offset / 50), 0)
			
			add_child(crop_instance)
			test_crops.append(crop_instance)
			
			print("[CropTestController] Created %s crop at %s" % [crop_resource.crop_name, crop_instance.position])
			x_offset += 60
		else:
			print("[CropTestController] ERROR: Failed to load crop resource")
	
	print("[CropTestController] Created %d test crops" % test_crops.size())

func test_visual_system() -> void:
	"""Test visual system integration and texture loading"""
	print("[CropTestController] Test 2: Visual System")
	
	for crop in test_crops:
		if crop.crop_visuals:
			var debug_info: Dictionary = crop.crop_visuals.get_debug_info()
			print("[CropTestController] %s visuals: %s" % [crop.crop_data.crop_name, debug_info])
			
			# Test texture loading
			var texture_count: int = debug_info.get("loaded_textures", 0)
			if texture_count > 0:
				print("[CropTestController] ✅ %s has %d textures loaded" % [crop.crop_data.crop_name, texture_count])
			else:
				print("[CropTestController] ❌ %s has no textures loaded" % [crop.crop_data.crop_name])
		else:
			print("[CropTestController] ❌ %s missing CropVisuals component" % [crop.crop_data.crop_name])

func test_growth_system() -> void:
	"""Test growth progression and stage advancement"""
	print("[CropTestController] Test 3: Growth System")
	
	for crop in test_crops:
		# Test initial growth processing
		crop.process_growth(1.0)  # Process 1 second of growth
		
		var debug_info: Dictionary = crop.get_debug_info()
		print("[CropTestController] %s growth: Stage=%s, Progress=%s" % [
			crop.crop_data.crop_name,
			debug_info.get("stage", "Unknown"),
			debug_info.get("progress", "0%")
		])
		
		# Test water system
		var water_success: bool = crop.water_crop(0.3)
		if water_success:
			print("[CropTestController] ✅ %s watering successful" % [crop.crop_data.crop_name])
		else:
			print("[CropTestController] ❌ %s watering failed" % [crop.crop_data.crop_name])

func test_component_integration() -> void:
	"""Test integration between Crop, CropGrowth, and CropVisuals"""
	print("[CropTestController] Test 4: Component Integration")
	
	for crop in test_crops:
		var has_growth: bool = crop.crop_growth != null
		var has_visuals: bool = crop.crop_visuals != null
		var has_data: bool = crop.crop_data != null
		
		print("[CropTestController] %s components: Growth=%s, Visuals=%s, Data=%s" % [
			crop.crop_data.crop_name if has_data else "Unknown",
			"✅" if has_growth else "❌",
			"✅" if has_visuals else "❌", 
			"✅" if has_data else "❌"
		])
		
		# Test signal connections
		if has_growth and has_visuals:
			# Force visual update to test communication
			crop._on_visual_update_needed()
			print("[CropTestController] ✅ Component communication tested for %s" % [crop.crop_data.crop_name])

# ============================================================================
# ADVANCED TESTS
# ============================================================================
func test_accelerated_growth() -> void:
	"""Test accelerated growth to see full lifecycle"""
	print("[CropTestController] Advanced Test: Accelerated Growth")
	
	if test_crops.is_empty():
		print("[CropTestController] No crops available for accelerated growth test")
		return
	
	var test_crop: Crop = test_crops[0]
	print("[CropTestController] Starting accelerated growth for %s" % [test_crop.crop_data.crop_name])
	
	# Simulate rapid growth over multiple frames
	for i in range(100):
		test_crop.process_growth(0.5)  # 0.5 seconds per frame
		
		# Check if mature
		if test_crop.is_ready_to_harvest():
			print("[CropTestController] %s reached maturity after %d iterations" % [test_crop.crop_data.crop_name, i])
			break
	
	# Test harvest
	if test_crop.can_harvest():
		var harvest_data: Dictionary = test_crop.harvest()
		print("[CropTestController] Harvest data: %s" % harvest_data)

func test_visual_transitions() -> void:
	"""Test visual transitions between growth stages"""
	print("[CropTestController] Advanced Test: Visual Transitions")
	
	for crop in test_crops:
		if crop.crop_visuals:
			print("[CropTestController] Testing visual transitions for %s" % [crop.crop_data.crop_name])
			
			# Force progression through stages
			for stage_idx in range(4):
				crop.crop_visuals._advance_to_stage(stage_idx)
				await get_tree().create_timer(0.5).timeout  # Wait between transitions
			
			print("[CropTestController] Visual transitions completed for %s" % [crop.crop_data.crop_name])

# ============================================================================
# VALIDATION REPORTING
# ============================================================================
func generate_step2_validation_report() -> Dictionary:
	"""Generate comprehensive Step 2 validation report"""
	var report: Dictionary = {
		"step": 2,
		"title": "Base Crop Scene and Controller",
		"total_tests": 0,
		"passed_tests": 0,
		"failed_tests": 0,
		"test_results": [],
		"overall_status": "UNKNOWN"
	}
	
	# Test results from our validation
	var test_results: Array = []
	
	# Check crop creation
	var crops_created: int = test_crops.size()
	test_results.append({
		"test": "Crop Instance Creation",
		"expected": 3,
		"actual": crops_created,
		"status": "PASS" if crops_created >= 3 else "FAIL"
	})
	
	# Check visual system
	var crops_with_visuals: int = 0
	var crops_with_textures: int = 0
	
	for crop in test_crops:
		if crop.crop_visuals:
			crops_with_visuals += 1
			var debug_info: Dictionary = crop.crop_visuals.get_debug_info()
			if debug_info.get("loaded_textures", 0) > 0:
				crops_with_textures += 1
	
	test_results.append({
		"test": "Visual Component Integration", 
		"expected": 3,
		"actual": crops_with_visuals,
		"status": "PASS" if crops_with_visuals >= 3 else "FAIL"
	})
	
	test_results.append({
		"test": "Texture Loading",
		"expected": 3,
		"actual": crops_with_textures,
		"status": "PASS" if crops_with_textures >= 3 else "FAIL"
	})
	
	# Calculate totals
	report.test_results = test_results
	report.total_tests = test_results.size()
	
	for result in test_results:
		if result.status == "PASS":
			report.passed_tests += 1
		else:
			report.failed_tests += 1
	
	# Determine overall status
	var pass_rate: float = float(report.passed_tests) / float(report.total_tests)
	if pass_rate >= 1.0:
		report.overall_status = "COMPLETE"
	elif pass_rate >= 0.75:
		report.overall_status = "MOSTLY_COMPLETE"
	elif pass_rate >= 0.5:
		report.overall_status = "PARTIAL"
	else:
		report.overall_status = "FAILED"
	
	return report

func print_validation_report() -> void:
	"""Print the validation report to console"""
	var report: Dictionary = generate_step2_validation_report()
	
	print("[CropTestController] === STEP 2 VALIDATION REPORT ===")
	print("[CropTestController] Status: %s" % report.overall_status)
	print("[CropTestController] Tests: %d/%d passed (%d failed)" % [
		report.passed_tests,
		report.total_tests, 
		report.failed_tests
	])
	
	for result in report.test_results:
		var status_icon: String = "✅" if result.status == "PASS" else "❌"
		print("[CropTestController] %s %s: %d/%d" % [
			status_icon,
			result.test,
			result.actual,
			result.expected
		])
	
	print("[CropTestController] === END VALIDATION REPORT ===")

# ============================================================================
# INPUT HANDLING FOR MANUAL TESTING
# ============================================================================
func _input(event: InputEvent) -> void:
	"""Handle input for manual testing"""
	if event.is_action_pressed("ui_accept"):  # Space key
		run_step2_tests()
	elif event.is_action_pressed("ui_select"):  # Enter key
		test_accelerated_growth()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		print_validation_report()

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func clear_test_crops() -> void:
	"""Clear all test crops"""
	for crop in test_crops:
		if crop and is_instance_valid(crop):
			crop.queue_free()
	
	test_crops.clear()
	print("[CropTestController] Cleared all test crops")

func get_test_summary() -> String:
	"""Get a brief test summary"""
	return "Step 2 Test: %d crops created, visual system %s" % [
		test_crops.size(),
		"working" if test_crops.size() > 0 and test_crops[0].crop_visuals else "needs attention"
	]
