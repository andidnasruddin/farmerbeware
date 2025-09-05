extends Node2D
class_name PlayerAnimator
# Animated 8-direction sprites with auto-flip for east directions and frame support.
# Files under: res://assets/sprites/player/
#   farmer_{group}_{dir}.png                # single-frame fallback
#   farmer_{group}_{dir}_{frame}.png        # animated frames (0..N)
# group: idle, walk, run
# dir: n, ne, e, se, s, sw, w, nw (east dirs auto-flipped from west)

@export var player_path: NodePath
@export var use_8_dirs: bool = true
@export var auto_flip_east: bool = true

# Draw/scale settings
@export var tile_px: int = 64               # target visual size in pixels
@export var z_over_player: int = 10
@export var fallback_tint: Color = Color(0.2, 0.7, 1.0, 0.9)

# Animation speeds (frames per second)
@export var idle_fps: float = 0.0           # 0 = no animation
@export var walk_fps: float = 6.0
@export var run_fps: float = 10.0

# If run frames are missing, reuse walk
@export var allow_run_fallback: bool = true

var _player: PlayerController = null
var _sprite: Sprite2D = null

# Anim state
var _cur_group: String = ""
var _cur_dir: String = "s"
var _cur_flip: bool = false
var _frame: int = 0
var _frame_timer: float = 0.0

# Cache to avoid loading every frame: key -> Texture2D or null
var _tex_cache: Dictionary = {}     # "group|dir|frame" -> Texture2D
var _tex_exists_cache: Dictionary = {}  # "group|dir|frame" -> bool

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	_sprite = $Body as Sprite2D
	z_index = z_over_player

	if player_path != NodePath():
		_player = get_node(player_path) as PlayerController
	if _player == null:
		var n := get_tree().get_first_node_in_group("player")
		_player = n as PlayerController

	set_process(true)

func _process(delta: float) -> void:
	if _player == null or _sprite == null:
		return

	# Resolve group + facing dir
	var new_group := _resolve_group()
	var dir_info := _resolve_dir_and_flip(_player.facing_direction)
	var new_dir: String = dir_info.dir
	var new_flip: bool = dir_info.flip

	# If group or dir changes, reset animation frame
	if new_group != _cur_group or new_dir != _cur_dir:
		_cur_group = new_group
		_cur_dir = new_dir
		_cur_flip = new_flip
		_frame = 0
		_frame_timer = 0.0

	# Update frame timer
	var fps := _group_fps(_cur_group)
	if fps > 0.0:
		_frame_timer += delta
		var spf := 1.0 / fps
		while _frame_timer >= spf:
			_frame_timer -= spf
			_frame += 1
	else:
		# stick to frame 0 if no animation for this group
		_frame = 0
		_frame_timer = 0.0

	# Resolve texture for current frame (with fallbacks/flips)
	var flip_h: bool = _cur_flip
	var tex := _resolve_texture_for_frame(_cur_group, _cur_dir, _frame)
	if tex == null:
		# Try single-frame fallback
		tex = _resolve_texture_for_frame(_cur_group, _cur_dir, 0)
		_frame = 0
	# If missing run set, reuse walk
	if tex == null and _cur_group == "run" and allow_run_fallback:
		tex = _resolve_texture_for_frame("walk", _cur_dir, _frame)
		if tex == null:
			tex = _resolve_texture_for_frame("walk", _cur_dir, 0)
			_frame = 0

	# Apply (or clear) flipping
	_sprite.flip_h = flip_h

	# Draw texture (or fallback box), scaled to tile_px
	if tex and tex is Texture2D:
		_sprite.texture = tex
		_sprite.modulate = Color.WHITE
		# Scale to tile_px while preserving aspect
		var ts := tex.get_size()
		if ts.x > 0.0 and ts.y > 0.0:
			_sprite.scale = Vector2(tile_px / ts.x, tile_px / ts.y)
	else:
		# Fallback: colored box
		if _sprite.texture == null or not (_sprite.texture is ImageTexture):
			var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
			img.fill(Color.WHITE)
			_sprite.texture = ImageTexture.create_from_image(img)
		_sprite.modulate = fallback_tint
		_sprite.flip_h = false
		_sprite.scale = Vector2(16, 16) * (tile_px / 64.0)

func _group_fps(group: String) -> float:
	match group:
		"idle": return idle_fps
		"walk": return walk_fps
		"run": return run_fps
		_: return 0.0

func _resolve_group() -> String:
	# If you add "carry" art later, return "carry" when carried_item != null.
	if _player.carried_item != null:
		return "walk"  # or "carry"
	match _player.state:
		_player.PlayerState.SPRINTING: return "run"
		_player.PlayerState.MOVING:    return "walk"
		_:                             return "idle"

func _resolve_dir_and_flip(v: Vector2) -> Dictionary:
	var dir := _vector_to_dir(v, use_8_dirs)
	var flip := false
	if auto_flip_east:
		match dir:
			"e":  dir = "w";  flip = true
			"ne": dir = "nw"; flip = true
			"se": dir = "sw"; flip = true
			_:    flip = false
	return {"dir": dir, "flip": flip}

func _vector_to_dir(v: Vector2, eight: bool) -> String:
	if v.length() < 0.1:
		return "s"
	var a := atan2(v.y, v.x)
	var deg := rad_to_deg(a)
	if deg < 0.0: deg += 360.0
	if eight:
		if deg >= 337.5 or deg < 22.5:  return "e"
		elif deg < 67.5:  return "se"
		elif deg < 112.5: return "s"
		elif deg < 157.5: return "sw"
		elif deg < 202.5: return "w"
		elif deg < 247.5: return "nw"
		elif deg < 292.5: return "n"
		else:             return "ne"
	else:
		if abs(v.x) >= abs(v.y):
			return "e" if v.x >= 0.0 else "w"
		else:
			return "s" if v.y >= 0.0 else "n"

func _resolve_texture_for_frame(group: String, dir: String, frame_idx: int) -> Texture2D:
	# Try numbered frame first: farmer_{group}_{dir}_{frame}.png
	var key := "%s|%s|%d" % [group, dir, frame_idx]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var path := "res://assets/sprites/player/farmer_%s_%s_%d.png" % [group, dir, frame_idx]
	var tex := load(path)
	if tex and tex is Texture2D:
		_tex_cache[key] = tex
		return tex
	# Remember the miss
	_tex_cache[key] = null
	# Try single-frame fallback (no frame suffix)
	var key2 := "%s|%s|single" % [group, dir]
	if _tex_cache.has(key2):
		return _tex_cache[key2]
	var path2 := "res://assets/sprites/player/farmer_%s_%s.png" % [group, dir]
	var tex2 := load(path2)
	if tex2 and tex2 is Texture2D:
		_tex_cache[key2] = tex2
		return tex2
	_tex_cache[key2] = null
	return null
