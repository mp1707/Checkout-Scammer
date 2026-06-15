extends TableActor
class_name ProductActor

signal rotation_changed(actor: ProductActor, rotation_degrees: float)

const ROTATION_STEP_DEGREES: float = 15.0

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var product_sprite: Sprite2D
@export var shadow_sprite: Sprite2D
@export var sprite_root: Node2D
@export var sticker_layer: Node2D
@export var count_label: Label
@export var collision_shape: CollisionShape2D
@export var animation_player: AnimationPlayer
@export var sticker_apply_player: AudioStreamPlayer2D
@export var sticker_visual_scene: PackedScene = preload("res://scenes/gameplay/stickers/sticker_visual.tscn")

var product_instance: ProductInstance

var _base_collision_size: Vector2 = Vector2(32.0, 32.0)
var _is_collision_size_cached: bool = false
var _base_visual_scale: Vector2 = Vector2.ONE
var _feedback_tween: Tween
var _reject_tween: Tween


func _ready() -> void:
	super()
	_validate_required_references()
	_cache_base_collision_size()
	if product_instance != null and product_instance.variant != null:
		_refresh_product_visuals()
	_apply_shadow_theme()
	_apply_count_label_theme()
	_refresh_count_label()


func set_product_instance(initial_product_instance: ProductInstance) -> void:
	product_instance = initial_product_instance
	if product_instance == null:
		actor_id = ""
		_set_product_texture(null)
		_refresh_count_label()
		return

	actor_id = product_instance.instance_id
	if product_instance.variant != null:
		_refresh_product_visuals()


func refresh_product_state() -> void:
	_refresh_product_visuals()


func play_sticker_apply_feedback() -> void:
	if sticker_apply_player == null:
		return

	sticker_apply_player.stop()
	sticker_apply_player.play()


func contains_global_point(global_point: Vector2) -> bool:
	if collision_shape == null or collision_shape.shape == null:
		return false
	return _collision_shape_contains_global_point(collision_shape, global_point)


func play_successful_scan_feedback(scan_count: int) -> void:
	_refresh_count_label()
	if animation_player != null and animation_player.has_animation("scan_success"):
		animation_player.play("scan_success")
		return

	_play_scan_wobble(maxi(scan_count, 1))


func play_reject_feedback() -> void:
	if _reject_tween != null and _reject_tween.is_valid():
		_reject_tween.kill()
	if sprite_root == null:
		return

	var base_position: Vector2 = sprite_root.position
	_reject_tween = create_tween()
	_reject_tween.tween_property(sprite_root, "position", base_position + Vector2(-2.0, 0.0), 0.035)
	_reject_tween.tween_property(sprite_root, "position", base_position + Vector2(2.0, 0.0), 0.045)
	_reject_tween.tween_property(sprite_root, "position", base_position, 0.055) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)


func play_finish_feedback(target_global_position: Vector2, is_sale: bool) -> void:
	_play_finish_fly(
		target_global_position,
		0.18 if is_sale else 0.12,
		Vector2(0.35, 0.35) if is_sale else Vector2(0.55, 0.55)
	)


func _on_finish_started() -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()


func _handle_secondary_press(mouse_button_event: InputEventMouseButton) -> void:
	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		rotation_degrees -= ROTATION_STEP_DEGREES
	elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		rotation_degrees += ROTATION_STEP_DEGREES
	else:
		return
	rotation_changed.emit(self, rotation_degrees)
	get_viewport().set_input_as_handled()


func _validate_required_references() -> void:
	if product_sprite == null:
		push_error("%s is missing required scene reference 'product_sprite'." % get_path())
	if sprite_root == null:
		push_error("%s is missing required scene reference 'sprite_root'." % get_path())
	if count_label == null:
		push_error("%s is missing required scene reference 'count_label'." % get_path())
	if collision_shape == null:
		push_error("%s is missing required scene reference 'collision_shape'." % get_path())


## Reads the authored collision size from the scene exactly once, before the
## shape is replaced by scaled copies in _apply_product_scale.
func _cache_base_collision_size() -> void:
	if _is_collision_size_cached or collision_shape == null:
		return
	var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle_shape != null:
		_base_collision_size = rectangle_shape.size
	_is_collision_size_cached = true


func _set_product_texture(product_texture: Texture2D) -> void:
	if product_sprite != null:
		product_sprite.texture = product_texture
	if shadow_sprite != null:
		shadow_sprite.texture = product_texture


func _refresh_product_visuals() -> void:
	if product_instance == null or product_instance.variant == null:
		_set_product_texture(null)
		_apply_product_scale(1.0)
		_refresh_sticker_visuals()
		return

	_set_product_texture(product_instance.variant.texture)
	_apply_product_scale(product_instance.get_visual_scale())
	_refresh_sticker_visuals()
	_refresh_count_label()


func _apply_product_scale(visual_scale: float) -> void:
	_cache_base_collision_size()
	_base_visual_scale = Vector2.ONE * maxf(visual_scale, 0.1)
	if sprite_root != null:
		sprite_root.scale = _base_visual_scale
	if shadow_sprite != null:
		shadow_sprite.scale = _base_visual_scale
	if collision_shape != null:
		var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
		rectangle_shape.size = _base_collision_size * _base_visual_scale
		collision_shape.shape = rectangle_shape


func _refresh_sticker_visuals() -> void:
	if sticker_layer == null:
		return

	for child: Node in sticker_layer.get_children():
		child.queue_free()
	if product_instance == null or sticker_visual_scene == null:
		return

	var sticker_index: int = 0
	for sticker_instance: StickerInstance in product_instance.applied_stickers:
		if sticker_instance == null or sticker_instance.sticker == null:
			continue
		var sticker_sprite: Sprite2D = sticker_visual_scene.instantiate() as Sprite2D
		if sticker_sprite == null:
			push_error("Configured sticker_visual_scene does not instance a Sprite2D.")
			return
		sticker_sprite.texture = sticker_instance.sticker.texture
		sticker_sprite.position = Vector2(8.0 + float(sticker_index * 3), -8.0 + float(sticker_index * 2))
		sticker_layer.add_child(sticker_sprite)
		sticker_index += 1


func _play_scan_wobble(scan_count: int) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()

	var wobble_strength: float = minf(0.10 + float(scan_count - 1) * 0.025, 0.18)
	var squash_scale: Vector2 = Vector2(1.0 + wobble_strength, 1.0 - wobble_strength)
	var stretch_scale: Vector2 = Vector2(1.0 - wobble_strength * 0.55, 1.0 + wobble_strength * 0.55)

	if sprite_root == null:
		return

	sprite_root.scale = _base_visual_scale * squash_scale
	_feedback_tween = create_tween()
	_feedback_tween.set_parallel(true)
	_feedback_tween.tween_property(sprite_root, "scale", _base_visual_scale * stretch_scale, 0.045)
	_feedback_tween.tween_property(sprite_root, "scale", _base_visual_scale, 0.09).set_delay(0.045) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	_feedback_tween.set_parallel(false)


func _apply_shadow_theme() -> void:
	if shadow_sprite == null or theme_resource == null:
		return
	shadow_sprite.modulate = theme_resource.shadow_color


func _apply_count_label_theme() -> void:
	if count_label == null or theme_resource == null:
		return
	if theme_resource.bold_font != null:
		count_label.add_theme_font_override("font", theme_resource.bold_font)
	elif theme_resource.font != null:
		count_label.add_theme_font_override("font", theme_resource.font)
	count_label.add_theme_font_size_override("font_size", theme_resource.font_size_small)
	count_label.add_theme_color_override("font_color", theme_resource.text_color)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _refresh_count_label() -> void:
	if count_label == null:
		return
	var count: int = product_instance.scan_count if product_instance != null else 0
	count_label.visible = count > 0
	count_label.text = str(count) if count > 0 else ""
