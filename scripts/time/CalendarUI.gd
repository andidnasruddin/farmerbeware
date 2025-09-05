extends Control
class_name CalendarUI

@export var highlight_color: Color = Color(1, 0.85, 0.25)
@export var normal_color: Color = Color(1, 1, 1)

var _title: Label = null
var _grid: GridContainer = null
var _schedule_title: Label = null
var _schedule_list: VBoxContainer = null

var _day_labels: Array[Label] = []
var _day_names: PackedStringArray = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

func _ready() -> void:
	name = "CalendarUI"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_title = $Header/TitleLabel as Label
	_grid = $WeekGrid as GridContainer
	_schedule_title = $ScheduleBox/ScheduleTitle as Label
	_schedule_list = $ScheduleBox/ScheduleList as VBoxContainer

	_build_week_grid()
	_refresh_week()
	_refresh_schedule([])

	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
		TimeManager.phase_changed.connect(_on_phase_changed)

func _build_week_grid() -> void:
	if _grid == null:
		return
	_grid.columns = 7
	_day_labels.clear()
	_clear_container(_grid)
	for i in range(7):
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lbl.text = _day_names[i]
		_grid.add_child(lbl)
		_day_labels.append(lbl)

func _on_day_started(_day: int) -> void:
	_refresh_week()
	_refresh_schedule([])

func _on_phase_changed(_from: int, _to: int) -> void:
	pass

func _refresh_week() -> void:
	if _title:
		_title.text = "Week %d" % TimeManager.get_current_week()
	var today_idx: int = TimeManager.get_day_in_week() - 1
	for i in range(_day_labels.size()):
		var lbl: Label = _day_labels[i]
		if lbl == null:
			continue
		var name: String = _day_names[i]
		var mark: String = " •" if i == today_idx else ""
		lbl.text = "%s%s" % [name, mark]
		lbl.add_theme_color_override("font_color", highlight_color if i == today_idx else normal_color)

func _refresh_schedule(entries: Array) -> void:
	if _schedule_title:
		_schedule_title.text = "Today's Schedule"
	if _schedule_list == null:
		return
	_clear_container(_schedule_list)
	for e in entries:
		var line := HBoxContainer.new()
		var t := Label.new()
		var title := Label.new()
		t.text = String(e.get("time", "—"))
		title.text = String(e.get("title", ""))
		t.custom_minimum_size = Vector2(72, 0)
		line.add_child(t)
		line.add_child(title)
		_schedule_list.add_child(line)

func _clear_container(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

# Add to scripts/time/CalendarUI.gd

func set_today_schedule(entries: Array) -> void:
	# entries: [{ "time": String, "title": String, "fired": bool }, ...]
	if _schedule_title:
		_schedule_title.text = "Today's Schedule"
	if _schedule_list == null:
		return
	_clear_container(_schedule_list)
	for e in entries:
		var line := HBoxContainer.new()
		var t := Label.new()
		var title := Label.new()
		t.text = String(e.get("time", "—"))
		title.text = String(e.get("title", ""))
		t.custom_minimum_size = Vector2(72, 0)
		# Style fired entries slightly dimmer
		if bool(e.get("fired", false)):
			t.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
			title.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		line.add_child(t)
		line.add_child(title)
		_schedule_list.add_child(line)

func _fmt_hour(h: float) -> String:
	var ih: int = int(floor(h))
	var mins: int = int(round((h - float(ih)) * 60.0))
	var am: bool = ih < 12
	var h12: int = ih % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, mins, "AM" if am else "PM"]

func _entry_title(e: Dictionary) -> String:
	var t: String = String(e.get("type",""))
	var id_s: String = String(e.get("id",""))
	match t:
		"WEATHER": return "Weather: " + id_s.capitalize()
		"CONTRACT":
			if id_s == "flash":
				return "Flash Contract"
			return "Contract: " + id_s.capitalize()
		"NPC": return "NPC: " + id_s.capitalize()
		"DISASTER": return "Disaster: " + id_s.capitalize()
		_: return id_s
