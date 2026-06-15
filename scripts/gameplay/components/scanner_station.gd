extends Node2D
class_name ScannerStation

signal scan_target_requested(actor: TableActor, contact_position: Vector2)

@export var theme_resource: CheckoutThemeResource = preload("res://content/ui/checkout_theme.tres")
@export var hit_area: Area2D
@export var scanner_cursor_root: Node2D
@export var scanner_sprite: Sprite2D
@export var crosshair_root: Node2D
@export var beam: CanvasItem
@export var beep_player: AudioStreamPlayer2D
@export var animation_player: AnimationPlayer

const CROSSHAIR_IDLE_ALPHA: float = 0.46
const CROSSHAIR_SCANNING_ALPHA: float = 0.82
const SCANNER_CURSOR_Z_INDEX: int = 2000

var _is_crosshair_suppressed: bool = false
var _is_register_hovered: bool = false
var _is_scan_beam_flashing: bool = false
var _is_mouse_inside_window: bool = true
var _held_scan_actor: TableActor
var _crosshair_tween: Tween
var _beam_tween: Tween


func _ready() -> void:
	_validate_required_references()
	_apply_theme()
	if scanner_cursor_root != null:
		scanner_cursor_root.z_index = SCANNER_CURSOR_Z_INDEX
		scanner_cursor_root.visible = true
	_hide_os_cursor()
	_update_scanner_cursor(get_viewport().get_mouse_position().round())
	_refresh_scanner_visuals()


func set_crosshair_suppressed(is_suppressed: bool) -> void:
	_is_crosshair_suppressed = is_suppressed
	_refresh_scanner_visuals()


func set_register_hovered(is_hovered: bool) -> void:
	_is_register_hovered = is_hovered
	_refresh_scanner_visuals()


func get_crosshair_global_position() -> Vector2:
	if hit_area != null:
		return hit_area.global_position
	if crosshair_root != null:
		return crosshair_root.global_position
	return global_position


func flash() -> void:
	if animation_player != null and animation_player.has_animation("flash"):
		animation_player.play("flash")


func play_success_feedback(scan_count: int) -> void:
	_play_beep(scan_count)
	_flash_scan_beam()
	_pulse_crosshair(scan_count)
	flash()


func _process(_delta: float) -> void:
	_update_scanner_cursor(get_viewport().get_mouse_position().round())
	_update_hold_scan_state()
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

	var top_actor: TableActor = null
	for area: Area2D in hit_area.get_overlapping_areas():
		var actor: TableActor = _find_actor_from_area(area)
		if actor == null:
			continue
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


func _update_hold_scan_state() -> void:
	if _held_scan_actor != null and not is_instance_valid(_held_scan_actor):
		_held_scan_actor = null

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or _is_crosshair_suppressed:
		_held_scan_actor = null
		return

	var target_actor: TableActor = _find_topmost_pointer_actor()
	if target_actor == null:
		_held_scan_actor = null
		return
	if target_actor == _held_scan_actor:
		return

	_held_scan_actor = target_actor
	scan_target_requested.emit(target_actor, get_crosshair_global_position())


func _refresh_scanner_visuals() -> void:
	var crosshair_color: Color = _get_crosshair_color()
	if crosshair_root != null:
		var final_crosshair_color: Color = crosshair_color
		final_crosshair_color.a = CROSSHAIR_SCANNING_ALPHA if _is_scan_beam_flashing else CROSSHAIR_IDLE_ALPHA
		crosshair_root.visible = not _is_crosshair_suppressed
		crosshair_root.modulate = final_crosshair_color

	if beam != null:
		beam.visible = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _is_crosshair_suppressed
		beam.modulate = _get_beam_color()


func _get_crosshair_color() -> Color:
	if _is_register_hovered:
		return theme_resource.scanner_register_beam_color if theme_resource != null else Color(0.117647, 0.435294, 0.313725, 1.0)
	if _is_hovering_weighable_product():
		return theme_resource.scanner_fruit_hover_color if theme_resource != null else Color(0.133333, 0.588235, 0.952941, 1.0)
	return theme_resource.scanner_beam_color if theme_resource != null else Color(1.0, 0.0, 0.25098, 1.0)


func _get_beam_color() -> Color:
	return _get_crosshair_color()


func _is_hovering_weighable_product() -> bool:
	var product_actor: ProductActor = _find_topmost_pointer_actor() as ProductActor
	return product_actor != null and product_actor.product_instance != null and product_actor.product_instance.is_weighable()


func _flash_scan_beam() -> void:
	_is_scan_beam_flashing = true
	if _beam_tween != null and _beam_tween.is_valid():
		_beam_tween.kill()
	_beam_tween = create_tween()
	_beam_tween.tween_interval(0.10)
	_beam_tween.tween_callback(_end_scan_beam_flash)
	_refresh_scanner_visuals()


func _end_scan_beam_flash() -> void:
	_is_scan_beam_flashing = false
	_refresh_scanner_visuals()


func _play_beep(scan_count: int) -> void:
	if beep_player == null:
		return

	beep_player.pitch_scale = 1.0 + minf(float(maxi(scan_count - 1, 0)) * 0.08, 0.42)
	beep_player.stop()
	beep_player.play()


func _pulse_crosshair(scan_count: int) -> void:
	if crosshair_root == null:
		return

	if _crosshair_tween != null and _crosshair_tween.is_valid():
		_crosshair_tween.kill()

	var flash_scale: float = 1.0 + minf(float(maxi(scan_count - 1, 0)) * 0.08, 0.24)
	crosshair_root.scale = Vector2.ONE * flash_scale
	_crosshair_tween = create_tween()
	_crosshair_tween.tween_property(crosshair_root, "scale", Vector2.ONE, 0.09) \
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
	if crosshair_root == null:
		push_error("%s is missing required scene reference 'crosshair_root'." % get_path())
	if beam == null:
		push_error("%s is missing required scene reference 'beam'." % get_path())
	if hit_area == null:
		push_error("%s is missing required scene reference 'hit_area'." % get_path())


func _apply_theme() -> void:
	if theme_resource == null:
		return
	if beam != null:
		beam.modulate = theme_resource.scanner_beam_color
	if crosshair_root != null:
		crosshair_root.modulate = theme_resource.scanner_beam_color
