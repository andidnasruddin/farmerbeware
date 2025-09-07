extends Node
class_name CropStagesTest
# CropStagesTest.gd - Test validation for Step 3 crop growth system components
# Tests CropStages functionality and integration with CropGrowth

func _ready() -> void:
	print("[CropStagesTest] Starting Step 3 validation tests...")
	_run_all_tests()

func _run_all_tests() -> void:
	"""Run comprehensive tests for Step 3 components"""
	print("[CropStagesTest] ===== STEP 3 VALIDATION TESTS =====")
	
	var total_tests: int = 0
	var passed_tests: int = 0
	
	# Test 1: CropStages creation and basic functionality
	if _test_crop_stages_creation():
		passed_tests += 1
	total_tests += 1
	
	# Test 2: Stage threshold functionality
	if _test_stage_thresholds():
		passed_tests += 1
	total_tests += 1
	
	# Test 3: Growth modifiers per stage
	if _test_stage_growth_modifiers():
		passed_tests += 1
	total_tests += 1
	
	# Test 4: Water requirements per stage
	if _test_stage_water_requirements():
		passed_tests += 1
	total_tests += 1
	
	# Test 5: Stage progression logic
	if _test_stage_progression():
		passed_tests += 1
	total_tests += 1
	
	# Test 6: Integration with existing CropData
	if _test_crop_data_integration():
		passed_tests += 1
	total_tests += 1
	
	# Print results
	print("[CropStagesTest] ===== TEST RESULTS =====")
	print("[CropStagesTest] Passed: %d/%d tests" % [passed_tests, total_tests])
	
	if passed_tests == total_tests:
		print("[CropStagesTest] ✅ ALL TESTS PASSED - Step 3 components working correctly!")
	else:
		print("[CropStagesTest] ❌ SOME TESTS FAILED - Step 3 needs attention")
	
	print("[CropStagesTest] ===========================")

# ============================================================================
# TEST IMPLEMENTATIONS
# ============================================================================

func _test_crop_stages_creation() -> bool:
	"""Test CropStages creation and initialization"""
	print("[CropStagesTest] Test 1: CropStages creation...")
	
	# Load a crop resource
	var lettuce_resource: CropData = load("res://resources/crops/tier1/lettuce.tres")
	if not lettuce_resource:
		print("[CropStagesTest] ❌ Failed to load lettuce resource")
		return false
	
	# Create CropStages
	var crop_stages: CropStages = CropStages.new(lettuce_resource)
	if not crop_stages:
		print("[CropStagesTest] ❌ Failed to create CropStages")
		return false
	
	# Check basic properties
	if crop_stages.crop_name != lettuce_resource.crop_name:
		print("[CropStagesTest] ❌ CropStages name mismatch")
		return false
	
	if crop_stages.total_growth_stages != lettuce_resource.growth_stages:
		print("[CropStagesTest] ❌ CropStages stage count mismatch")
		return false
	
	print("[CropStagesTest] ✅ CropStages creation test passed")
	return true

func _test_stage_thresholds() -> bool:
	"""Test stage threshold functionality"""
	print("[CropStagesTest] Test 2: Stage thresholds...")
	
	var lettuce_resource: CropData = load("res://resources/crops/tier1/lettuce.tres")
	var crop_stages: CropStages = CropStages.new(lettuce_resource)
	
	# Test threshold ordering
	var stages: Array = [
		CropStages.GrowthStage.SEED,
		CropStages.GrowthStage.SPROUT,
		CropStages.GrowthStage.YOUNG,
		CropStages.GrowthStage.MATURE
	]
	
	var prev_threshold: float = -1.0
	for stage in stages:
		var threshold: float = crop_stages.get_progress_for_stage(stage)
		if threshold <= prev_threshold:
			print("[CropStagesTest] ❌ Threshold ordering incorrect for stage %s" % CropStages.GrowthStage.keys()[stage])
			return false
		prev_threshold = threshold
	
	# Test progress-to-stage conversion
	if crop_stages.get_stage_for_progress(0.0) != CropStages.GrowthStage.SEED:
		print("[CropStagesTest] ❌ Progress 0.0 should return SEED")
		return false
	
	if crop_stages.get_stage_for_progress(1.0) != CropStages.GrowthStage.MATURE:
		print("[CropStagesTest] ❌ Progress 1.0 should return MATURE")
		return false
	
	print("[CropStagesTest] ✅ Stage thresholds test passed")
	return true

func _test_stage_growth_modifiers() -> bool:
	"""Test stage-specific growth modifiers"""
	print("[CropStagesTest] Test 3: Stage growth modifiers...")
	
	var lettuce_resource: CropData = load("res://resources/crops/tier1/lettuce.tres")
	var crop_stages: CropStages = CropStages.new(lettuce_resource)
	
	# Test that each stage has a growth modifier
	var stages: Array = [
		CropStages.GrowthStage.SEED,
		CropStages.GrowthStage.SPROUT,
		CropStages.GrowthStage.YOUNG,
		CropStages.GrowthStage.MATURE
	]
	
	for stage in stages:
		var modifier: float = crop_stages.get_growth_modifier(stage)
		if modifier <= 0.0 or modifier > 5.0:
			print("[CropStagesTest] ❌ Invalid growth modifier %.2f for stage %s" % [modifier, CropStages.GrowthStage.keys()[stage]])
			return false
	
	# Test that SPROUT stage has faster growth (as per default config)
	var sprout_modifier: float = crop_stages.get_growth_modifier(CropStages.GrowthStage.SPROUT)
	var seed_modifier: float = crop_stages.get_growth_modifier(CropStages.GrowthStage.SEED)
	
	if sprout_modifier <= seed_modifier:
		print("[CropStagesTest] ❌ SPROUT should have faster growth than SEED")
		return false
	
	print("[CropStagesTest] ✅ Stage growth modifiers test passed")
	return true

func _test_stage_water_requirements() -> bool:
	"""Test stage-specific water requirements"""
	print("[CropStagesTest] Test 4: Stage water requirements...")
	
	var lettuce_resource: CropData = load("res://resources/crops/tier1/lettuce.tres")
	var crop_stages: CropStages = CropStages.new(lettuce_resource)
	
	# Test that each stage has water requirements
	var stages: Array = [
		CropStages.GrowthStage.SEED,
		CropStages.GrowthStage.SPROUT,
		CropStages.GrowthStage.YOUNG,
		CropStages.GrowthStage.MATURE
	]
	
	for stage in stages:
		var water_req: float = crop_stages.get_water_requirement(stage)
		if water_req < 0.0 or water_req > 1.0:
			print("[CropStagesTest] ❌ Invalid water requirement %.2f for stage %s" % [water_req, CropStages.GrowthStage.keys()[stage]])
			return false
	
	# Test that SEED stage has higher water requirement (as per default config)
	var seed_water: float = crop_stages.get_water_requirement(CropStages.GrowthStage.SEED)
	var mature_water: float = crop_stages.get_water_requirement(CropStages.GrowthStage.MATURE)
	
	if seed_water <= mature_water:
		print("[CropStagesTest] ❌ SEED should have higher water requirement than MATURE")
		return false
	
	print("[CropStagesTest] ✅ Stage water requirements test passed")
	return true

func _test_stage_progression() -> bool:
	"""Test stage progression logic"""
	print("[CropStagesTest] Test 5: Stage progression logic...")
	
	var lettuce_resource: CropData = load("res://resources/crops/tier1/lettuce.tres")
	var crop_stages: CropStages = CropStages.new(lettuce_resource)
	
	# Test next stage progression
	if crop_stages.get_next_stage(CropStages.GrowthStage.SEED) != CropStages.GrowthStage.SPROUT:
		print("[CropStagesTest] ❌ SEED should advance to SPROUT")
		return false
	
	if crop_stages.get_next_stage(CropStages.GrowthStage.MATURE) != CropStages.GrowthStage.OVERRIPE:
		print("[CropStagesTest] ❌ MATURE should advance to OVERRIPE")
		return false
	
	# Test advancement conditions
	if not crop_stages.can_advance_from_stage(CropStages.GrowthStage.SEED, 0.3, 0.8):
		print("[CropStagesTest] ❌ Healthy seed with progress should be able to advance")
		return false
	
	if crop_stages.can_advance_from_stage(CropStages.GrowthStage.DEAD, 1.0, 1.0):
		print("[CropStagesTest] ❌ Dead crops should not advance")
		return false
	
	print("[CropStagesTest] ✅ Stage progression logic test passed")
	return true

func _test_crop_data_integration() -> bool:
	"""Test integration with existing CropData resources"""
	print("[CropStagesTest] Test 6: CropData integration...")
	
	# Test with all available crop resources
	var crop_paths: Array = [
		"res://resources/crops/tier1/lettuce.tres",
		"res://resources/crops/tier1/corn.tres",
		"res://resources/crops/tier1/wheat.tres"
	]
	
	for crop_path in crop_paths:
		var crop_resource: CropData = load(crop_path)
		if not crop_resource:
			print("[CropStagesTest] ❌ Failed to load crop resource: %s" % crop_path)
			return false
		
		var crop_stages: CropStages = CropStages.new(crop_resource)
		if not crop_stages:
			print("[CropStagesTest] ❌ Failed to create CropStages for: %s" % crop_path)
			return false
		
		# Validate configuration
		if not crop_stages.validate_custom_thresholds():
			print("[CropStagesTest] ❌ Invalid threshold configuration for: %s" % crop_path)
			return false
	
	print("[CropStagesTest] ✅ CropData integration test passed")
	return true

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
func print_crop_stages_info(crop_stages: CropStages) -> void:
	"""Print detailed information about CropStages configuration"""
	if not crop_stages:
		return
	
	print("[CropStagesTest] === CropStages Info for %s ===" % crop_stages.crop_name)
	crop_stages.print_stage_info()