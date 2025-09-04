extends Node2D
class_name PreviewLayer
# Shows preview tiles using Sprite2D quads so it always renders on top

@export var tile_size: int = 64
@export var alpha: float = 0.45

var _pool: Array[Sprite2D] = []
var _tex: Texture2D = null

func _ready() -> void:
	# Draw on top and keep updating even when paused (e.g., MENU)
	z_index = 300
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# Create a 1x1 white texture to tint/scale
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_tex = ImageTexture.create_from_image(img)

func clear_preview() -> void:
	for s in _pool:
		s.visible = false

func set_preview(targets: Array[Vector2i], validity: Dictionary) -> void:
	if targets == null or targets.is_empty():
		clear_preview()
		return

	# Ensure enough sprites
	while _pool.size() < targets.size():
		var s := Sprite2D.new()
		s.texture = _tex
		s.z_index = 300
		add_child(s)
		_pool.append(s)

	# Show needed, hide the rest
	for i in range(_pool.size()):
		var s := _pool[i]
		if i < targets.size():
			var p: Vector2i = targets[i]
			# Center sprite on tile; scale 1x1 tex to tile_size
			s.position = Vector2((p.x + 0.5) * tile_size, (p.y + 0.5) * tile_size)
			s.scale = Vector2(tile_size, tile_size)
			var ok: bool = bool(validity.get(p, true))
			var col: Color = (Color(0.25, 0.85, 0.35, alpha) if ok else Color(0.90, 0.25, 0.25, alpha))
			s.modulate = col
			s.visible = true
		else:
			s.visible = false
