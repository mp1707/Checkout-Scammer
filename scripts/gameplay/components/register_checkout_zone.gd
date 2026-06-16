extends Area2D
class_name RegisterCheckoutZone

signal checkout_requested()
signal hover_changed(is_hovered: bool)

@export var checkout_anchor: Marker2D

const CHECKOUT_MOUSE_BUTTON: MouseButton = MOUSE_BUTTON_RIGHT

var _is_hovered: bool = false


func _ready() -> void:
	if checkout_anchor == null:
		push_error("%s is missing required scene reference 'checkout_anchor'." % get_path())
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)


func get_checkout_position() -> Vector2:
	if checkout_anchor != null:
		return checkout_anchor.global_position
	return global_position


func _on_mouse_entered() -> void:
	_set_hovered(true)


func _on_mouse_exited() -> void:
	_set_hovered(false)


func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event == null:
		return
	if mouse_button_event.button_index != CHECKOUT_MOUSE_BUTTON or not mouse_button_event.pressed:
		return

	checkout_requested.emit()
	get_viewport().set_input_as_handled()


func _set_hovered(is_hovered: bool) -> void:
	if _is_hovered == is_hovered:
		return
	_is_hovered = is_hovered
	hover_changed.emit(_is_hovered)
