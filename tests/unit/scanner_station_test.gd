extends "res://tests/checkout_test_base.gd"
class_name ScannerStationTest


class PointRejectingActor:
	extends TableActor

	func contains_global_point(_global_point: Vector2) -> bool:
		return false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_scanner_controls_use_right_scan_and_left_drag()
	_test_scan_lock_survives_while_actor_still_overlaps()
	_test_scan_lock_survives_physics_overlap_gap_at_hitbox_edge()
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
