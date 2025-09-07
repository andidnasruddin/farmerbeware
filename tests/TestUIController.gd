extends Control
class_name TestUIController
# TestUIController.gd - UI controller for displaying Step 3 integration test progress

@onready var test_title_label: Label = $InfoContainer/TestTitleLabel
@onready var test_status_label: Label = $InfoContainer/TestStatusLabel

var integration_controller: Step3IntegrationTestController = null

func _ready() -> void:
	# Find the integration test controller
	integration_controller = get_node("../../IntegrationTestController") as Step3IntegrationTestController
	if integration_controller:
		print("[TestUIController] Connected to integration test controller")
	else:
		print("[TestUIController] Could not find integration test controller")

func _process(_delta: float) -> void:
	if integration_controller:
		update_display()

func update_display() -> void:
	var summary: String = integration_controller.get_integration_summary()
	test_status_label.text = summary + "\nPress SPACE to start tests, ENTER for report, ESC to clear"