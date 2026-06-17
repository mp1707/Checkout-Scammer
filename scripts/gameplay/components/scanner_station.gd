extends Node2D
class_name ScannerStation

signal scan_target_requested(actor: TableActor, contact_position: Vector2)

@export var hit_area: Area2D
@export var scanner_cursor_root: Node2D
@export var scanner_sprite: Sprite2D
@export var laser_cursor_sprite: AnimatedSprite2D
@export var beep_player: AudioStreamPlayer2D
@export var animation_player: AnimationPlayer

const SCANNER_CURSOR_Z_INDEX: int = 2000
const CURSOR_DEFAULT_ANIMATION: StringName = &"red_cross"
const CURSOR_FRUIT_ANIMATION: StringName = &"blue_chevron"
const CURSOR_SCANNING_ANIMATION: StringName = &"red_cross_laser"
const CURSOR_REGISTER_ANIMATION: StringName = &"green_checkmark"
const SCAN_MOUSE_BUTTON: MouseButton = MOUSE_BUTTON_RIGHT
const SCAN_HOLD_DURATION_SECONDS: float = 1.5

var _is_cursor_suppressed: bool = false
var _is_register_hovered: bool = false
var _is_mouse_inside_window: bool = true
var _scan_locked_actors: Array[TableActor] = []
var _pending_scan_actor: TableActor
var _pending_scan_elapsed_seconds: float = 0.0
var _pending_scan_contact_position: Vector2 = Vector2.ZERO
var _cursor_tween: Tween


func _ready() -> void:
	_validate_required_references()
	if scanner_cursor_root != null:
		scanner_cursor_root.z_index = SCANNER_CURSOR_Z_INDEX
		scanner_cursor_root.visible = true
	_hide_os_cursor()
	_update_scanner_cursor(get_viewport().get_mouse_position().round())
	_refresh_scanner_visuals()


func set_cursor_suppressed(is_suppressed: bool) -> void:
	_is_cursor_suppressed = is_suppressed
	_refresh_scanner_visuals()


func set_register_hovered(is_hovered: bool) -> void:
	_is_register_hovered = is_hovered
	_refresh_scanner_visuals()


func get_cursor_hotspot_global_position() -> Vector2:
	if hit_area != null:
		return hit_area.global_position
	return global_position


func flash() -> void:
	if animation_player != null and animation_player.has_animation("flash"):
		animation_player.play("flash")


func play_success_feedback(scan_count: int) -> void:
	_play_beep(scan_count)
	_pulse_laser_cursor(scan_count)
	flash()


func _process(delta: float) -> void:
	_update_scanner_cursor(get_viewport().get_mouse_position().round())
	_update_hold_scan_state(delta)
	_refresh_scanner_visuals()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_MOUSE_ENTER:
			_is_mouse_inside_window = true
			_hide_os_cursor()
		NOTIFICATION_WM_MOUSE_EXIT:
			_is_mouse_inside_window = false
			_show_os_cursor()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if _is_mouse_inside_window:
				_hide_os_cursor()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_show_os_cursor()


func _exit_tree() -> void:
	_show_os_cursor()


func _find_actor_from_area(area: Area2D) -> TableActor:
	if area == null:
		return null

	var node: Node = area
	while node != null:
		var actor: TableActor = node as TableActor
		if actor != null:
			return actor
		node = node.get_parent()

	return null


func _find_topmost_pointer_actor() -> TableActor:
	if hit_area == null:
		return null

	return _find_topmost_actor(_find_pointer_actors())


func _find_pointer_actors() -> Array[TableActor]:
	var actors: Array[TableActor] = []
	if hit_area == null:
		return actors

	for area: Area2D in hit_area.get_overlapping_areas():
		var actor: TableActor = _find_actor_from_area(area)
		if actor == null or actors.has(actor):
			continue
		actors.append(actor)

	return actors


func _find_topmost_actor(actors: Array[TableActor]) -> TableActor:
	var top_actor: TableActor = null
	for actor: TableActor in actors:
		if top_actor == null or _actor_is_above(actor, top_actor):
			top_actor = actor

	return top_actor


func _actor_is_above(candidate: TableActor, current: TableActor) -> bool:
	if candidate.z_index != current.z_index:
		return candidate.z_index > current.z_index
	return candidate.get_index() > current.get_index()


func _update_scanner_cursor(global_mouse_position: Vector2) -> void:
	if scanner_cursor_root != null:
		scanner_cursor_root.global_position = global_mouse_position


func _update_hold_scan_state(delta: float) -> void:
	if not Input.is_mouse_button_pressed(SCAN_MOUSE_BUTTON) or _is_cursor_suppressed:
		_cancel_pending_scan()
		_scan_locked_actors.clear()
		return

	var pointer_actors: Array[TableActor] = _find_pointer_actors()
	_prune_scan_locked_actors(pointer_actors)

	var target_actor: TableActor = _find_topmost_actor(pointer_actors)
	if _pending_scan_actor != null:
		_update_pending_scan(delta, target_actor)
		return

	if target_actor == null:
		return
	if _scan_locked_actors.has(target_actor):
		return
	if not _can_begin_hold_scan(target_actor):
		return

	_begin_pending_scan(target_actor)


func _prune_scan_locked_actors(pointer_actors: Array[TableActor]) -> void:
	for index: int in range(_scan_locked_actors.size() - 1, -1, -1):
		var actor: TableActor = _scan_locked_actors[index]
		if actor == null or not is_instance_valid(actor):
			_scan_locked_actors.remove_at(index)
			continue
		if not pointer_actors.has(actor) and not _hit_area_overlaps_actor(actor):
			_scan_locked_actors.remove_at(index)


func _begin_pending_scan(actor: TableActor) -> void:
	_pending_scan_actor = actor
	_pending_scan_elapsed_seconds = 0.0
	_pending_scan_contact_position = get_cursor_hotspot_global_position()
	actor.show_loading_progress(0.0)


func _update_pending_scan(delta: float, target_actor: TableActor) -> void:
	if _pending_scan_actor == null or not is_instance_valid(_pending_scan_actor):
		_cancel_pending_scan()
		return
	if target_actor != _pending_scan_actor:
		_cancel_pending_scan()
		return

	_pending_scan_elapsed_seconds += delta
	_pending_scan_actor.show_loading_progress(
		_pending_scan_elapsed_seconds / SCAN_HOLD_DURATION_SECONDS
	)
	if _pending_scan_elapsed_seconds < SCAN_HOLD_DURATION_SECONDS:
		return

	_complete_pending_scan()


func _complete_pending_scan() -> void:
	var completed_actor: TableActor = _pending_scan_actor
	var completed_contact_position: Vector2 = _pending_scan_contact_position
	_clear_pending_scan_visual()
	_pending_scan_actor = null
	_pending_scan_elapsed_seconds = 0.0
	_pending_scan_contact_position = Vector2.ZERO
	if completed_actor == null or not is_instance_valid(completed_actor):
		return

	_scan_locked_actors.append(completed_actor)
	scan_target_requested.emit(completed_actor, completed_contact_position)


func _cancel_pending_scan() -> void:
	_clear_pending_scan_visual()
	_pending_scan_actor = null
	_pending_scan_elapsed_seconds = 0.0
	_pending_scan_contact_position = Vector2.ZERO


func _clear_pending_scan_visual() -> void:
	if _pending_scan_actor != null and is_instance_valid(_pending_scan_actor):
		_pending_scan_actor.hide_loading_progress()


func _can_begin_hold_scan(actor: TableActor) -> bool:
	var product_actor: ProductActor = actor as ProductActor
	if product_actor != null:
		return product_actor.product_instance != null and not product_actor.product_instance.is_weighable()

	return actor is CouponActor


func _hit_area_overlaps_actor(actor: TableActor) -> bool:
	if actor == null or hit_area == null:
		return false

	for child: Node in hit_area.get_children():
		var collision_shape: CollisionShape2D = child as CollisionShape2D
		if collision_shape == null or collision_shape.disabled or collision_shape.shape == null:
			continue

		var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
		if rectangle_shape != null:
			var global_size: Vector2 = Vector2(
				rectangle_shape.size.x * absf(collision_shape.global_scale.x),
				rectangle_shape.size.y * absf(collision_shape.global_scale.y)
			)
			if actor.overlaps_global_rect(collision_shape.global_position, global_size):
				return true

	return false


func _refresh_scanner_visuals() -> void:
	if laser_cursor_sprite == null:
		return

	laser_cursor_sprite.visible = not _is_cursor_suppressed
	var cursor_animation: StringName = _get_cursor_animation()
	if laser_cursor_sprite.animation != cursor_animation or not laser_cursor_sprite.is_playing():
		laser_cursor_sprite.play(cursor_animation)


func _get_cursor_animation() -> StringName:
	if _is_register_hovered:
		return CURSOR_REGISTER_ANIMATION
	if Input.is_mouse_button_pressed(SCAN_MOUSE_BUTTON):
		return CURSOR_SCANNING_ANIMATION
	if _is_hovering_weighable_product():
		return CURSOR_FRUIT_ANIMATION
	return CURSOR_DEFAULT_ANIMATION


func _is_hovering_weighable_product() -> bool:
	var product_actor: ProductActor = _find_topmost_pointer_actor() as ProductActor
	return product_actor != null and product_actor.product_instance != null and product_actor.product_instance.is_weighable()


func _play_beep(scan_count: int) -> void:
	if beep_player == null:
		return

	beep_player.pitch_scale = 1.0 + minf(float(maxi(scan_count - 1, 0)) * 0.08, 0.42)
	beep_player.stop()
	beep_player.play()


func _pulse_laser_cursor(scan_count: int) -> void:
	if laser_cursor_sprite == null:
		return

	if _cursor_tween != null and _cursor_tween.is_valid():
		_cursor_tween.kill()

	var flash_scale: float = 1.0 + minf(float(maxi(scan_count - 1, 0)) * 0.08, 0.24)
	laser_cursor_sprite.scale = Vector2.ONE * flash_scale
	_cursor_tween = create_tween()
	_cursor_tween.tween_property(laser_cursor_sprite, "scale", Vector2.ONE, 0.09) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)


func _hide_os_cursor() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _show_os_cursor() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _validate_required_references() -> void:
	if scanner_cursor_root == null:
		push_error("%s is missing required scene reference 'scanner_cursor_root'." % get_path())
	if scanner_sprite == null:
		push_error("%s is missing required scene reference 'scanner_sprite'." % get_path())
	if laser_cursor_sprite == null:
		push_error("%s is missing required scene reference 'laser_cursor_sprite'." % get_path())
	if hit_area == null:
		push_error("%s is missing required scene reference 'hit_area'." % get_path())
	_validate_cursor_animations()


func _validate_cursor_animations() -> void:
	if laser_cursor_sprite == null or laser_cursor_sprite.sprite_frames == null:
		return

	var required_animations: Array[StringName] = [
		CURSOR_DEFAULT_ANIMATION,
		CURSOR_FRUIT_ANIMATION,
		CURSOR_SCANNING_ANIMATION,
		CURSOR_REGISTER_ANIMATION,
	]
	for animation_name: StringName in required_animations:
		if not laser_cursor_sprite.sprite_frames.has_animation(animation_name):
			push_error("%s is missing laser cursor animation '%s'." % [get_path(), animation_name])
