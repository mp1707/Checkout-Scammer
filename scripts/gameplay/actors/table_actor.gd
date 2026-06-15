extends Node2D
class_name TableActor

## Shared base for draggable checkout-table objects (products, coupons).
## Owns drag input, slot bookkeeping and the finish-fly animation so zones,
## scanner and controllers can work against one typed API.

signal drag_started(actor: TableActor)
signal drag_moved(actor: TableActor, previous_position: Vector2, current_position: Vector2, movement_delta: Vector2)
signal drag_ended(actor: TableActor, drop_position: Vector2)

const Z_LAYER_IDLE: int = 0
const Z_LAYER_ON_SCALE: int = 40
const Z_LAYER_DRAGGED: int = 100
const Z_LAYER_FINISHING: int = 120

@export var interaction_area: Area2D

var actor_id: String = ""
var slot_index: int = -1
var is_held: bool = false
var movement_direction: Vector2 = Vector2.ZERO

var _finish_tween: Tween


func _ready() -> void:
	if interaction_area == null:
		push_error("%s is missing required scene reference 'interaction_area'." % get_path())
		return
	if not interaction_area.input_event.is_connected(_on_interaction_area_input_event):
		interaction_area.input_event.connect(_on_interaction_area_input_event)


func get_contact_area() -> Area2D:
	return interaction_area


func set_interaction_enabled(is_enabled: bool) -> void:
	if interaction_area != null:
		interaction_area.input_pickable = is_enabled


func contains_global_point(global_point: Vector2) -> bool:
	if interaction_area == null:
		return false

	for child: Node in interaction_area.get_children():
		var collision_shape: CollisionShape2D = child as CollisionShape2D
		if collision_shape == null or collision_shape.disabled or collision_shape.shape == null:
			continue
		if _collision_shape_contains_global_point(collision_shape, global_point):
			return true

	return false


func play_finish_feedback(target_global_position: Vector2, is_sale: bool) -> void:
	_play_finish_fly(
		target_global_position,
		0.16 if is_sale else 0.11,
		Vector2(0.40, 0.40) if is_sale else Vector2(0.60, 0.60)
	)


func _unhandled_input(event: InputEvent) -> void:
	if not is_held:
		return

	var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if motion_event != null:
		_update_drag_position(motion_event.position.round())
		get_viewport().set_input_as_handled()
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event != null:
		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT and not mouse_button_event.pressed:
			_end_drag(mouse_button_event.position.round())
			get_viewport().set_input_as_handled()
			return
		if mouse_button_event.pressed:
			_handle_secondary_press(mouse_button_event)


## Override for additional pressed-button handling while dragging (e.g. rotation).
func _handle_secondary_press(_mouse_button_event: InputEventMouseButton) -> void:
	pass


func _collision_shape_contains_global_point(collision_shape: CollisionShape2D, global_point: Vector2) -> bool:
	var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
	if rectangle_shape != null:
		var local_point: Vector2 = collision_shape.to_local(global_point)
		var half_size: Vector2 = rectangle_shape.size * 0.5
		return absf(local_point.x) <= half_size.x and absf(local_point.y) <= half_size.y

	var circle_shape: CircleShape2D = collision_shape.shape as CircleShape2D
	if circle_shape != null:
		return collision_shape.to_local(global_point).length() <= circle_shape.radius

	return false


## Override to reset subclass drag state when the finish animation starts.
func _on_finish_started() -> void:
	pass


func _play_finish_fly(target_global_position: Vector2, finish_duration: float, target_scale: Vector2) -> void:
	is_held = false
	_on_finish_started()
	if interaction_area != null:
		interaction_area.input_pickable = false
		interaction_area.set_deferred("monitorable", false)
		interaction_area.set_deferred("monitoring", false)

	if _finish_tween != null and _finish_tween.is_valid():
		_finish_tween.kill()

	z_index = Z_LAYER_FINISHING
	_finish_tween = create_tween()
	_finish_tween.set_parallel(true)
	_finish_tween.tween_property(self, "global_position", target_global_position.round(), finish_duration) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	_finish_tween.tween_property(self, "scale", target_scale, finish_duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	_finish_tween.tween_property(self, "modulate:a", 0.0, finish_duration)
	_finish_tween.set_parallel(false)
	_finish_tween.tween_callback(queue_free)


func _on_interaction_area_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null:
		return
	if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
		get_viewport().set_input_as_handled()
		return
	if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
		_start_drag(mouse_button_event.position.round())
		get_viewport().set_input_as_handled()


func _start_drag(pointer_position: Vector2) -> void:
	is_held = true
	z_index = Z_LAYER_DRAGGED
	_update_drag_position(pointer_position)
	drag_started.emit(self)


func _update_drag_position(next_global_position: Vector2) -> void:
	var previous_position: Vector2 = global_position
	global_position = next_global_position
	var movement_delta: Vector2 = global_position - previous_position
	movement_direction = Vector2.ZERO
	if movement_delta.length_squared() > 0.0:
		movement_direction = movement_delta.normalized()
	drag_moved.emit(self, previous_position, global_position, movement_delta)


func _end_drag(drop_position: Vector2) -> void:
	is_held = false
	z_index = Z_LAYER_IDLE
	_update_drag_position(drop_position)
	drag_ended.emit(self, global_position)
