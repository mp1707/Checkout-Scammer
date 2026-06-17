extends TableActor
class_name CouponActor

@export var coupon_sprite: Sprite2D

var coupon_instance: CouponInstance


func _ready() -> void:
	super()
	if coupon_sprite == null:
		push_error("%s is missing required scene reference 'coupon_sprite'." % get_path())
	if loading_circle_sprite == null:
		push_error("%s is missing required scene reference 'loading_circle_sprite'." % get_path())
	_refresh_coupon_id()


func set_coupon_instance(initial_coupon_instance: CouponInstance) -> void:
	coupon_instance = initial_coupon_instance
	_refresh_coupon_id()


func _refresh_coupon_id() -> void:
	if coupon_instance == null:
		actor_id = ""
		return

	actor_id = coupon_instance.instance_id
