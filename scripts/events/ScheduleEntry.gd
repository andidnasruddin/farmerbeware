extends Resource
class_name ScheduleEntry

@export var hour: float = 12.0
@export var event_type: String = "CONTRACT"	# WEATHER | CONTRACT | NPC | DISASTER
@export var id: String = "flash"			# e.g., sunny|rain|merchant|flash
@export var chance: float = 1.0				# 0.0 .. 1.0
