extends Control
class_name WeatherEffects

@export var fade_speed: float = 0.25
@export var rain_columns: int = 4
@export var rain_amount_per_column: int = 10

# At top
var _em: Node = null
var _am: Node = null
var _event_lock: bool = false
var _locked_type: int = -1

var _dark: ColorRect = null
var _fog: ColorRect = null
var _warm: ColorRect = null
var _rain: GPUParticles2D = null
var _flash: ColorRect = null
var _flash_tween: Tween = null
var _rain_layer: Node2D = null
var _rains: Array[GPUParticles2D] = []

func _ready() -> void:
	name = "WeatherOverlay"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dark = $Darken as ColorRect
	_fog = $FogTint as ColorRect
	_warm = $WarmTint as ColorRect
	_flash = $Flash as ColorRect

	_ensure_rain_layer()
	_rebuild_rain_emitters()	# creates emitters with emitting=false
	_hide_all()					# hard-off everything after building

	_em = get_node_or_null("/root/EventManager")
	_am = get_node_or_null("/root/AudioManager")

	if _em:
		# Drive visuals via event lifecycle; fallback to weather_changed
		_em.event_started.connect(_on_event_started)
		_em.event_ended.connect(_on_event_ended)
		_em.weather_changed.connect(_on_weather_changed)

func _on_event_started(event) -> void:
	if event == null or not ("event_type" in event):
		return
	if event.event_type != _em.EventType.WEATHER:
		return
	_event_lock = true
	_locked_type = int(event.weather_type)
	var intensity: float = 1.0
	if "weather_intensity" in _em:
		intensity = float(_em.weather_intensity)
	_apply_weather(_locked_type, intensity)

func _on_event_ended(event, _completed: bool) -> void:
	if event == null or not ("event_type" in event):
		return
	if event.event_type != _em.EventType.WEATHER:
		return
	_event_lock = false
	_locked_type = -1
	_hide_all()

func _ensure_rain_node() -> void:
	if _rain != null:
		return
	_rain = GPUParticles2D.new()
	_rain.name = "Rain"
	add_child(_rain)

func _ensure_rain_layer() -> void:
	if _rain_layer != null:
		return
	_rain_layer = Node2D.new()
	_rain_layer.name = "RainLayer"
	add_child(_rain_layer)

func _rebuild_rain_emitters() -> void:
	if _rain_layer == null:
		_ensure_rain_layer()
	for c in _rain_layer.get_children():
		c.queue_free()
	_rains.clear()

	var vp: Vector2 = get_viewport_rect().size
	var cols: int = max(8, int(round(vp.x / 48.0)))
	var spacing: float = vp.x / float(cols)

	for i in range(cols):
		var p: GPUParticles2D = GPUParticles2D.new()
		p.name = "Rain_%d" % i
		p.local_coords = false
		p.preprocess = 0.35
		p.amount = rain_amount_per_column
		p.position = Vector2(spacing * float(i), -10.0)
		p.emitting = false
		p.one_shot = false

		var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		mat.direction = Vector3(0, 1, 0)
		mat.spread = 6.0
		mat.gravity = Vector3(0, 2000, 0)
		mat.initial_velocity_min = 1300.0
		mat.initial_velocity_max = 1700.0
		p.process_material = mat

		var img: Image = Image.create(2, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		p.texture = ImageTexture.create_from_image(img)

		_rain_layer.add_child(p)
		_rains.append(p)

	_update_rain_visibility_rect()

func _update_rain_visibility_rect() -> void:
	var vp: Vector2 = get_viewport_rect().size
	for p in _rains:
		p.visibility_rect = Rect2(Vector2(-vp.x, -20.0), vp * 2.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild_rain_emitters()
		_hide_all()	# keep them OFF on rebuild

func _ensure_rain_defaults() -> void:
	if _rain == null:
		_ensure_rain_node()
	# Process material uses Vector3 for 2D particles in Godot 4.x
	if _rain.process_material == null:
		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3(0, 1, 0)			# fall down
		mat.spread = 8.0
		mat.gravity = Vector3(0, 2000, 0)
		mat.initial_velocity_min = 1300.0
		mat.initial_velocity_max = 1700.0
		_rain.process_material = mat
	# Visible texture (simple white strip) if none set
	if _rain.texture == null:
		var img := Image.create(2, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		var tex := ImageTexture.create_from_image(img)
		_rain.texture = tex
	# General defaults
	_rain.preprocess = 0.35
	_rain.local_coords = true					# points defined relative to node
	_rain.modulate = Color(1, 1, 1, 1)
	_rain.amount = 800
	_rain.emitting = false

func _layout_particles() -> void:
	if _rain == null:
		return
	var vp := get_viewport_rect().size
	# Place emitter at center-top; points defined in local space
	_rain.position = Vector2(vp.x * 0.5, 0.0)
	# Build a horizontal line of emission points just above the top
	var cols: int = 64
	var pts := PackedVector2Array()
	for i in cols:
		var x := (vp.x / float(cols - 1)) * float(i) - (vp.x * 0.5)
		pts.push_back(Vector2(x, -10.0))
	# Assign points (works regardless of emission_shape enum availability)
	_rain.emission_points = pts
	# Ensure particles remain visible while falling
	_rain.visibility_rect = Rect2(Vector2(-vp.x, -20.0), vp * 2.0)

func _emit_rain(on: bool, mult: float) -> void:
	for p in _rains:
		p.emitting = on
		p.amount = int(rain_amount_per_column * clamp(mult, 0.25, 3.0))

func _on_weather_changed(_old: int, new_weather: int) -> void:
	if _event_lock:
		return	# event controls visuals
	var intensity: float = 1.0
	if "weather_intensity" in _em:
		intensity = clamp(float(_em.weather_intensity), 0.0, 2.0)
	_apply_weather(new_weather, intensity)

func _apply_weather(w: int, intensity: float) -> void:
	_hide_all()

	match w:
		# SUNNY: clear
		_em.WeatherType.SUNNY:
			_stop_ambience()
		# CLOUDY: slight darken
		_em.WeatherType.CLOUDY:
			_fade_to(_dark, 0.15 * intensity)
			_stop_ambience()
		# RAINY: rain + moderate darken
		_em.WeatherType.RAINY:
			_fade_to(_dark, 0.25 * intensity)
			_emit_rain(true, 1.0 * intensity)
			_play_ambience("rain_loop")
		# STORMY: stronger darken + rain + occasional flash
		_em.WeatherType.STORMY:
			_fade_to(_dark, 0.4 * intensity)
			_emit_rain(true, 1.2 * intensity)
			_lightning_flash()
			_play_ambience("thunder")	# if registered; otherwise harmless
		# DROUGHT: warm tint
		_em.WeatherType.DROUGHT:
			_fade_to(_warm, 0.22 * intensity)
			_stop_ambience()
		# FOG: gray tint
		_em.WeatherType.FOG:
			_fade_to(_fog, 0.28 * intensity)
			_stop_ambience()
		_:
			_stop_ambience()

func _fade_to(node: ColorRect, target_a: float) -> void:
	if node == null:
		return
	var c: Color = node.color
	var start_a: float = c.a
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(node, "color:a", clamp(target_a, 0.0, 1.0), fade_speed)

func _lightning_flash() -> void:
	if _flash == null:
		return
	var c: Color = _flash.color
	c.a = 0.0
	_flash.color = c
	var t := create_tween()
	t.tween_property(_flash, "color:a", 0.7, 0.08)
	t.tween_property(_flash, "color:a", 0.0, 0.25)

func _hide_all() -> void:
	for p in _rains:
		p.emitting = false
	if _dark:
		var c := _dark.color; c.a = 0.0; _dark.color = c
	if _fog:
		var c2 := _fog.color; c2.a = 0.0; _fog.color = c2
	if _warm:
		var c3 := _warm.color; c3.a = 0.0; _warm.color = c3
	if _flash:
		var cf := _flash.color; cf.a = 0.0; _flash.color = cf

func _play_ambience(id: String) -> void:
	if _am and _am.has_method("play_bgm"):
		_am.play_bgm(id)	# optional; will warn if not registered

func _stop_ambience() -> void:
	if _am and _am.has_method("stop_bgm"):
		_am.stop_bgm()
