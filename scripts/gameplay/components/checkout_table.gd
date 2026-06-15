extends Control
class_name CheckoutTable

signal product_hand_scan_requested(actor: ProductActor, contact_position: Vector2)
signal coupon_hand_scan_requested(actor: CouponActor, contact_position: Vector2)
signal register_checkout_requested()
signal actor_taken_from_product_area(actor: TableActor)
signal actor_trash_drop_requested(actor: TableActor)
signal actor_scale_drop_requested(actor: ProductActor)
signal actor_scale_removed(actor: ProductActor)

@export var product_scatter_view: ProductScatterView
@export var scanner_station: ScannerStation
@export var register_display: RegisterDisplay
@export var register_checkout_zone: RegisterCheckoutZone
@export var trash_zone: TrashZone
@export var scale_station: ScaleStation
@export var customer_hand_view: CustomerHandView
@export var vfx_container: Node2D
@export var coin_burst_scene: PackedScene

var _shake_tween: Tween
var _base_position: Vector2
var _is_actor_input_enabled: bool = true


func _ready() -> void:
	_base_position = position
	_validate_required_references()
	_connect_children()


func display_customer_objects(slots: Array[VisibleObjectSlot]) -> void:
	product_scatter_view.display_slots(slots)


func clear_visible_objects() -> void:
	product_scatter_view.clear_actors()


func show_scanned_product_amount(amount_cents: int) -> void:
	register_display.show_amount_cents(amount_cents)


func clear_scanned_product_amount() -> void:
	register_display.clear_amount()


func release_scale_actor(actor: TableActor) -> void:
	scale_station.release_actor(actor)


func set_customer_hand_state(customer_type: CustomerTypeResource, hand_stage_index: int, suspicion_percent: int) -> void:
	customer_hand_view.set_suspicion_state(customer_type, hand_stage_index, suspicion_percent)


func pulse_customer_hand() -> void:
	customer_hand_view.pulse_customer_hand()


func play_customer_caught_sound() -> void:
	customer_hand_view.play_caught_sound()


func play_successful_scan_feedback(actor: ProductActor, scan_count: int) -> void:
	scanner_station.play_success_feedback(scan_count)
	if actor != null:
		actor.refresh_product_state()
		actor.play_successful_scan_feedback(scan_count)
	if scan_count > 1:
		_play_table_jolt(scan_count)


func play_successful_weigh_feedback(actor: ProductActor, charge_count: int) -> void:
	scale_station.play_success_feedback()
	if actor != null:
		actor.refresh_product_state()
		actor.play_successful_scan_feedback(charge_count)
	if charge_count > 1:
		_play_table_jolt(charge_count)


func play_invalid_weigh_feedback(actor: ProductActor) -> void:
	scale_station.play_invalid_feedback()
	if actor != null:
		actor.play_reject_feedback()


func play_rejected_drop_feedback(actor: ProductActor) -> void:
	if actor != null:
		actor.play_reject_feedback()


func refresh_product_actor(actor: ProductActor) -> void:
	if actor != null:
		actor.refresh_product_state()


func play_sticker_apply_feedback(actor: ProductActor) -> void:
	if actor != null:
		actor.play_sticker_apply_feedback()


func find_product_actor_at_global_position(global_point: Vector2) -> ProductActor:
	var scale_actor: ProductActor = scale_station.get_current_actor()
	if scale_actor != null and scale_actor.contains_global_point(global_point):
		return scale_actor
	return product_scatter_view.find_product_actor_at(global_point)


func play_actor_finish_feedback(
	actor: TableActor,
	is_sale: bool,
	use_custom_coin_burst_position: bool = false,
	coin_burst_global_position: Vector2 = Vector2.ZERO
) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var finish_position: Vector2 = _get_actor_finish_position(actor, is_sale)
	var product_actor: ProductActor = actor as ProductActor
	if is_sale and product_actor != null and product_actor.product_instance != null:
		var burst_position: Vector2 = coin_burst_global_position if use_custom_coin_burst_position else finish_position
		_spawn_coin_burst(burst_position, _product_uses_bonus_coin_sound(product_actor.product_instance))
	actor.play_finish_feedback(finish_position, is_sale)


func _validate_required_references() -> void:
	if product_scatter_view == null:
		push_error("%s is missing required scene reference 'product_scatter_view'." % get_path())
	if scanner_station == null:
		push_error("%s is missing required scene reference 'scanner_station'." % get_path())
	if register_display == null:
		push_error("%s is missing required scene reference 'register_display'." % get_path())
	if register_checkout_zone == null:
		push_error("%s is missing required scene reference 'register_checkout_zone'." % get_path())
	if trash_zone == null:
		push_error("%s is missing required scene reference 'trash_zone'." % get_path())
	if scale_station == null:
		push_error("%s is missing required scene reference 'scale_station'." % get_path())
	if customer_hand_view == null:
		push_error("%s is missing required scene reference 'customer_hand_view'." % get_path())
	if coin_burst_scene == null:
		push_error("%s is missing required scene reference 'coin_burst_scene'." % get_path())


func _connect_children() -> void:
	if scanner_station != null:
		scanner_station.set_cursor_suppressed(false)
		scanner_station.scan_target_requested.connect(_on_scanner_station_scan_target_requested)
	if product_scatter_view != null:
		product_scatter_view.product_actor_spawned.connect(_on_product_actor_spawned)
		product_scatter_view.coupon_actor_spawned.connect(_on_coupon_actor_spawned)
	if register_checkout_zone != null:
		register_checkout_zone.checkout_requested.connect(_on_register_checkout_requested)
		register_checkout_zone.hover_changed.connect(_on_register_hover_changed)
	if trash_zone != null:
		trash_zone.actor_dropped.connect(_on_trash_zone_actor_dropped)
	if scale_station != null:
		scale_station.actor_dropped.connect(_on_scale_station_actor_dropped)
		scale_station.actor_removed.connect(_on_scale_station_actor_removed)


func _on_product_actor_spawned(actor: ProductActor, _slot_index: int) -> void:
	_connect_actor_drag_signals(actor)
	actor.set_interaction_enabled(_is_actor_input_enabled)


func _on_coupon_actor_spawned(actor: CouponActor, _slot_index: int) -> void:
	_connect_actor_drag_signals(actor)
	actor.set_interaction_enabled(_is_actor_input_enabled)


func _connect_actor_drag_signals(actor: TableActor) -> void:
	actor.drag_started.connect(_on_actor_drag_started)
	actor.drag_ended.connect(_on_actor_drag_ended)


func _on_actor_drag_started(actor: TableActor) -> void:
	if scanner_station != null:
		scanner_station.set_cursor_suppressed(true)
	if scale_station.has_actor(actor):
		scale_station.release_actor(actor)
	product_scatter_view.release_actor(actor)
	actor_taken_from_product_area.emit(actor)


func _on_actor_drag_ended(actor: TableActor, _drop_position: Vector2) -> void:
	if scanner_station != null:
		scanner_station.set_cursor_suppressed(false)
	_route_actor_drop(actor)


func _route_actor_drop(actor: TableActor) -> void:
	if scale_station.try_drop_actor(actor):
		return
	if trash_zone.try_drop_actor(actor):
		return


func _on_scanner_station_scan_target_requested(actor: TableActor, contact_position: Vector2) -> void:
	_route_scanner_target(actor, contact_position)


func _route_scanner_target(actor: TableActor, contact_position: Vector2) -> void:
	if scanner_station != null:
		scanner_station.set_cursor_suppressed(false)

	var product_actor: ProductActor = actor as ProductActor
	if product_actor != null:
		if product_actor.product_instance != null and not product_actor.product_instance.is_weighable():
			product_hand_scan_requested.emit(product_actor, contact_position)
		return

	var coupon_actor: CouponActor = actor as CouponActor
	if coupon_actor != null:
		coupon_hand_scan_requested.emit(coupon_actor, contact_position)


func _on_register_checkout_requested() -> void:
	register_checkout_requested.emit()


func _on_register_hover_changed(is_hovered: bool) -> void:
	if scanner_station != null:
		scanner_station.set_register_hovered(is_hovered)


func _on_trash_zone_actor_dropped(actor: TableActor) -> void:
	actor_trash_drop_requested.emit(actor)


func _on_scale_station_actor_dropped(actor: ProductActor) -> void:
	actor_scale_drop_requested.emit(actor)


func _on_scale_station_actor_removed(actor: ProductActor) -> void:
	actor_scale_removed.emit(actor)


func _spawn_coin_burst(burst_global_position: Vector2, use_bonus_sound: bool) -> void:
	if coin_burst_scene == null:
		return

	var vfx: CoinBurstVfx = coin_burst_scene.instantiate() as CoinBurstVfx
	if vfx == null:
		push_error("Configured coin_burst_scene does not instance a CoinBurstVfx.")
		return

	if vfx_container != null:
		vfx_container.add_child(vfx)
	else:
		add_child(vfx)
	vfx.play_at(burst_global_position, use_bonus_sound)


func _get_actor_finish_position(actor: TableActor, is_sale: bool) -> Vector2:
	var zone: Node2D = register_checkout_zone if is_sale else trash_zone
	if zone == null:
		return actor.global_position
	return register_checkout_zone.get_checkout_position() if is_sale else trash_zone.get_drop_position()


func _product_uses_bonus_coin_sound(product_instance: ProductInstance) -> bool:
	return product_instance.scan_count > 1 or not product_instance.applied_stickers.is_empty()


func _play_table_jolt(scan_count: int) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()

	var strength: float = minf(1.0 + float(scan_count - 2) * 0.35, 2.0)
	position = _base_position
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "position", _base_position + Vector2(-strength, 0.0), 0.025)
	_shake_tween.tween_property(self, "position", _base_position + Vector2(strength, 0.0), 0.035)
	_shake_tween.tween_property(self, "position", _base_position, 0.045) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
