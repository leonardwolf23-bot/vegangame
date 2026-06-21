extends Node2D
## Animiertes Gebäude-Overlay: idle standardmäßig, working nur bei Produktion.


@export var idle_anim: StringName = &"idle"
@export var working_anim: StringName = &"working"
@export var working_duration: float = 3.0

var _anchor: Vector2i = Vector2i.ZERO
var _anim: AnimatedSprite2D
var _working_timer: float = 0.0
var _is_working: bool = false


func _ready() -> void:
	y_sort_enabled = true
	_anim = get_node_or_null(^"AnimatedSprite2D") as AnimatedSprite2D
	if not _anim:
		push_error("BuildingVisual: AnimatedSprite2D fehlt.")
		return
	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_play_idle()


func setup(anchor: Vector2i, building: Dictionary, world_pos: Vector2) -> void:
	_anchor = anchor
	global_position = world_pos

	idle_anim = BuildingCatalog.get_anim_idle(building)
	working_anim = BuildingCatalog.get_anim_working(building)
	working_duration = BuildingCatalog.get_anim_work_duration(building)

	var frames: SpriteFrames = BuildingCatalog.get_sprite_frames(building)
	if frames and _anim:
		_anim.sprite_frames = frames
		_play_idle()
	elif _anim and not _anim.sprite_frames:
		push_warning(
			"BuildingVisual (%s): Keine SpriteFrames — Animation unsichtbar bis zugewiesen."
			% building.get("id", "gebäude")
		)


func get_anchor() -> Vector2i:
	return _anchor


func play_production() -> void:
	_working_timer = working_duration
	if _is_working:
		return
	_is_working = true
	_play_working()


func _process(delta: float) -> void:
	z_index = int(global_position.y)
	if not _is_working:
		return
	_working_timer -= delta
	if _working_timer <= 0.0:
		_is_working = false
		_play_idle()


func _play_idle() -> void:
	if not _anim or not _anim.sprite_frames:
		return
	if _anim.sprite_frames.has_animation(idle_anim):
		if _anim.animation != idle_anim or not _anim.is_playing():
			_anim.play(idle_anim)
		return
	var names := _anim.sprite_frames.get_animation_names()
	if not names.is_empty():
		_anim.play(names[0])


func _play_working() -> void:
	if not _anim or not _anim.sprite_frames:
		return
	if _anim.sprite_frames.has_animation(working_anim):
		_anim.play(working_anim)
		return
	push_warning("BuildingVisual: Animation '%s' fehlt, bleibe bei idle." % working_anim)
	_play_idle()
