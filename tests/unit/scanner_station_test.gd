extends "res://tests/checkout_test_base.gd"
class_name ScannerStationTest


class PointRejectingActor:
	extends TableActor

	func contains_global_point(_global_point: Vector2) -> bool:
		return false


class ScanSignalCapture:
	extends RefCounted

	var count: int = 0
	var actor: TableActor

	func on_scan_target_requested(scanned_actor: TableActor, _contact_position: Vector2) -> void:
		count += 1
		actor = scanned_actor


class ScaleSignalCapture:
	extends RefCounted

	var count: int = 0
	var actor: ProductActor

	func on_actor_dropped(dropped_actor: ProductActor) -> void:
		count += 1
		actor = dropped_actor


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_scanner_controls_use_right_scan_and_left_drag()
	_test_scan_lock_survives_while_actor_still_overlaps()
	_test_scan_lock_survives_physics_overlap_gap_at_hitbox_edge()
	_test_hold_scan_completes_after_duration()
	_test_hold_scan_cancels_when_target_is_interrupted()
	_test_scale_station_completes_pending_weighing_after_duration()
	_test_scale_station_cancels_pending_weighing_on_release()
	_finish_suite("Scanner station tests")


func _test_scanner_controls_use_right_scan_and_left_drag() -> void:
	_expect_equal_int(
		int(MOUSE_BUTTON_RIGHT),
		int(ScannerStation.SCAN_MOUSE_BUTTON),
		"ScannerStation uses right mouse button for scanning"
	)
	_expect_equal_int(
		int(MOUSE_BUTTON_LEFT),
		int(TableActor.DRAG_MOUSE_BUTTON),
		"TableActor uses left mouse button for dragging products and coupons"
	)
	_expect_equal_int(
		int(MOUSE_BUTTON_RIGHT),
		int(RegisterCheckoutZone.CHECKOUT_MOUSE_BUTTON),
		"RegisterCheckoutZone uses the scanner button for checkout"
	)


func _test_scan_lock_survives_while_actor_still_overlaps() -> void:
	var scanner_station: ScannerStation = ScannerStation.new()
	var actor: PointRejectingActor = PointRejectingActor.new()
	var overlapping_actors: Array[TableActor] = [actor]
	var empty_overlaps: Array[TableActor] = []

	scanner_station._scan_locked_actors.append(actor)
	scanner_station._prune_scan_locked_actors(overlapping_actors)
	_expect_equal_int(
		1,
		scanner_station._scan_locked_actors.size(),
		"ScannerStation keeps a held-scan lock while the actor still overlaps the scanner hitbox"
	)

	scanner_station._prune_scan_locked_actors(empty_overlaps)
	_expect_equal_int(
		0,
		scanner_station._scan_locked_actors.size(),
		"ScannerStation releases a held-scan lock after the actor leaves the scanner hitbox"
	)

	actor.free()
	scanner_station.free()


func _test_scan_lock_survives_physics_overlap_gap_at_hitbox_edge() -> void:
	var scanner_station: ScannerStation = ScannerStation.new()
	var scanner_hit_area: Area2D = Area2D.new()
	var scanner_collision_shape: CollisionShape2D = CollisionShape2D.new()
	var scanner_shape: RectangleShape2D = RectangleShape2D.new()
	scanner_shape.size = Vector2(12.0, 12.0)
	scanner_collision_shape.shape = scanner_shape
	scanner_hit_area.add_child(scanner_collision_shape)
	get_root().add_child(scanner_hit_area)
	scanner_station.hit_area = scanner_hit_area

	var actor: TableActor = _create_rect_actor(Vector2.ZERO, Vector2(20.0, 20.0))
	get_root().add_child(actor)
	scanner_hit_area.global_position = Vector2(15.0, 0.0)
	scanner_hit_area.force_update_transform()
	actor.force_update_transform()
	var empty_overlaps: Array[TableActor] = []

	_expect_false(
		actor.contains_global_point(scanner_hit_area.global_position),
		"Test setup keeps scanner hotspot outside the actor center-point hit check"
	)
	_expect_true(
		scanner_station._hit_area_overlaps_actor(actor),
		"Test setup still overlaps the actor with the scanner hitbox"
	)

	scanner_station._scan_locked_actors.append(actor)
	scanner_station._prune_scan_locked_actors(empty_overlaps)
	_expect_equal_int(
		1,
		scanner_station._scan_locked_actors.size(),
		"ScannerStation keeps a held-scan lock during a temporary physics overlap gap at the hitbox edge"
	)

	scanner_hit_area.global_position = Vector2(30.0, 0.0)
	scanner_hit_area.force_update_transform()
	scanner_station._prune_scan_locked_actors(empty_overlaps)
	_expect_equal_int(
		0,
		scanner_station._scan_locked_actors.size(),
		"ScannerStation releases a held-scan lock after the scanner hitbox fully leaves the actor"
	)

	actor.free()
	scanner_hit_area.free()
	scanner_station.free()


func _test_hold_scan_completes_after_duration() -> void:
	var scanner_station: ScannerStation = ScannerStation.new()
	var actor: TableActor = _create_rect_actor(Vector2.ZERO, Vector2(20.0, 20.0))
	var loading_circle: Sprite2D = Sprite2D.new()
	actor.add_child(loading_circle)
	actor.loading_circle_sprite = loading_circle

	var capture: ScanSignalCapture = ScanSignalCapture.new()
	scanner_station.scan_target_requested.connect(capture.on_scan_target_requested)

	scanner_station._begin_pending_scan(actor)
	scanner_station._update_pending_scan(ScannerStation.SCAN_HOLD_DURATION_SECONDS * 0.51, actor)
	_expect_equal_int(0, capture.count, "Hold scan waits before emitting")
	_expect_true(loading_circle.visible, "Hold scan shows loading circle while pending")

	scanner_station._update_pending_scan(ScannerStation.SCAN_HOLD_DURATION_SECONDS * 0.5, actor)
	_expect_equal_int(1, capture.count, "Hold scan emits once after the full duration")
	_expect_true(capture.actor == actor, "Hold scan emits the pending actor")
	_expect_false(loading_circle.visible, "Hold scan hides loading circle after completion")
	_expect_equal_int(1, scanner_station._scan_locked_actors.size(), "Hold scan locks the completed actor until it leaves")

	actor.free()
	scanner_station.free()


func _test_hold_scan_cancels_when_target_is_interrupted() -> void:
	var scanner_station: ScannerStation = ScannerStation.new()
	var actor: TableActor = _create_rect_actor(Vector2.ZERO, Vector2(20.0, 20.0))
	var loading_circle: Sprite2D = Sprite2D.new()
	actor.add_child(loading_circle)
	actor.loading_circle_sprite = loading_circle

	var capture: ScanSignalCapture = ScanSignalCapture.new()
	scanner_station.scan_target_requested.connect(capture.on_scan_target_requested)

	scanner_station._begin_pending_scan(actor)
	scanner_station._update_pending_scan(ScannerStation.SCAN_HOLD_DURATION_SECONDS * 0.5, null)
	_expect_equal_int(0, capture.count, "Interrupted hold scan does not emit")
	_expect_true(scanner_station._pending_scan_actor == null, "Interrupted hold scan clears pending actor")
	_expect_false(loading_circle.visible, "Interrupted hold scan hides loading circle")

	actor.free()
	scanner_station.free()


func _test_scale_station_completes_pending_weighing_after_duration() -> void:
	var scale_station: ScaleStation = ScaleStation.new()
	var actor: ProductActor = ProductActor.new()
	var loading_circle: Sprite2D = Sprite2D.new()
	actor.add_child(loading_circle)
	actor.loading_circle_sprite = loading_circle
	scale_station._current_actor = actor

	var capture: ScaleSignalCapture = ScaleSignalCapture.new()
	scale_station.actor_dropped.connect(capture.on_actor_dropped)

	scale_station._begin_pending_weighing(actor)
	scale_station._process(ScaleStation.WEIGH_HOLD_DURATION_SECONDS * 0.51)
	_expect_equal_int(0, capture.count, "Pending weighing waits before emitting")
	_expect_true(loading_circle.visible, "Pending weighing shows loading circle")

	scale_station._process(ScaleStation.WEIGH_HOLD_DURATION_SECONDS * 0.5)
	_expect_equal_int(1, capture.count, "Pending weighing emits once after the full duration")
	_expect_true(capture.actor == actor, "Pending weighing emits the weighed actor")
	_expect_false(loading_circle.visible, "Pending weighing hides loading circle after completion")

	actor.free()
	scale_station.free()


func _test_scale_station_cancels_pending_weighing_on_release() -> void:
	var scale_station: ScaleStation = ScaleStation.new()
	var actor: ProductActor = ProductActor.new()
	var loading_circle: Sprite2D = Sprite2D.new()
	actor.add_child(loading_circle)
	actor.loading_circle_sprite = loading_circle
	scale_station._current_actor = actor

	var capture: ScaleSignalCapture = ScaleSignalCapture.new()
	scale_station.actor_dropped.connect(capture.on_actor_dropped)

	scale_station._begin_pending_weighing(actor)
	scale_station.release_actor(actor)
	scale_station._process(ScaleStation.WEIGH_HOLD_DURATION_SECONDS)
	_expect_equal_int(0, capture.count, "Released pending weighing does not emit")
	_expect_false(loading_circle.visible, "Released pending weighing hides loading circle")
	_expect_true(scale_station.get_current_actor() == null, "Released pending weighing clears current actor")

	actor.free()
	scale_station.free()


func _create_rect_actor(global_actor_position: Vector2, shape_size: Vector2) -> TableActor:
	var actor: TableActor = TableActor.new()
	var interaction_area: Area2D = Area2D.new()
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()
	rectangle_shape.size = shape_size
	collision_shape.shape = rectangle_shape
	interaction_area.add_child(collision_shape)
	actor.add_child(interaction_area)
	actor.interaction_area = interaction_area
	actor.global_position = global_actor_position
	return actor
