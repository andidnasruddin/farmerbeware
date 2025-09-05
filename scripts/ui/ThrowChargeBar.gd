extends Control
class_name ThrowChargeBar

@export var carry_system_path: NodePath

var _carry: CarrySystem = null
var _bar: ProgressBar = null

func _ready() -> void:
	visible = false
	_bar = $Bar as ProgressBar
	_bar.min_value = 0.0
	_bar.max_value = 1.0

	if carry_system_path != NodePath():
		_carry = get_node(carry_system_path) as CarrySystem
	if _carry:
		_carry.charge_started.connect(_on_charge_started)
		_carry.charge_changed.connect(_on_charge_changed)
		_carry.charge_released.connect(_on_charge_released)

func _on_charge_started() -> void:
	_bar.value = 0.0
	visible = true

func _on_charge_changed(ratio: float) -> void:
	_bar.value = ratio

func _on_charge_released(_force: float) -> void:
	visible = false
