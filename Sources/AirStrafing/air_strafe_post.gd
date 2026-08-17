extends Node

const MOD_ID: String = "air_strafe"

const AIR_STRAFE_ACCEL_BASE: float = 440.0
const AIR_STRAFE_SPEED_BASE: float = 1.6

var accel_mult: float = 0.5
var speed_mult: float = 0.5

var braking_on: bool = true

var previous_grappling: bool = false

func _physics_process(delta: float) -> void:
	var player: Node = get_parent()

	if (
		not is_instance_valid(player)
		or not is_instance_valid(Ref.player)
		or player != Ref.player
		or player.disabled
		or not Ref.world.is_position_loaded(player.global_position)
	):
		return

	var pre: Node = get_parent().get_node_or_null("AirStrafePre")

	if pre == null:
		return

	if pre.saved_air_accel_valid:
		player.air_accel = pre.saved_air_accel
		pre.saved_air_accel_valid = false

	if pre.saved_movement_velocity_valid:
		player.movement_velocity.x = pre.saved_movement_velocity.x
		player.movement_velocity.z = pre.saved_movement_velocity.z

		pre.saved_movement_velocity_valid = false

	if not pre.airborne:
		previous_grappling = pre.is_grappling
		return

	if not pre.local_movement_enabled:
		previous_grappling = pre.is_grappling
		return

	if braking_on:
		var braking: bool = false
		var basis: Basis = player.get_node("%RotationPivot").global_transform.basis
		var forward: Vector3 = basis * Vector3.FORWARD
		var right: Vector3 = basis * Vector3.RIGHT

		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()

		var brake_amount: float = AIR_STRAFE_ACCEL_BASE * accel_mult * delta

		if Input.is_action_pressed("up") and Input.is_action_pressed("down"):
			var speed: float = player.movement_velocity.dot(forward)
			player.movement_velocity += forward * (move_toward(speed, 0.0, brake_amount) - speed)
			braking = true

		if Input.is_action_pressed("left") and Input.is_action_pressed("right"):
			var speed: float = player.movement_velocity.dot(right)
			player.movement_velocity += right * (move_toward(speed, 0.0, brake_amount) - speed)
			braking = true

		if braking:
			if previous_grappling and not pre.is_grappling:
				player.movement_velocity.x = player.velocity.x
				player.movement_velocity.z = player.velocity.z

			previous_grappling = pre.is_grappling
			return

	var input: Vector2 = Input.get_vector("left", "right", "up", "down")

	var movement_dir: Vector3 = (player.get_node("%RotationPivot").global_transform.basis * Vector3(input.x, 0.0, input.y))

	if movement_dir.length_squared() > 0.0001:
		var air_strafe_speed: float = (AIR_STRAFE_SPEED_BASE * speed_mult)
		var air_strafe_accel: float = (AIR_STRAFE_ACCEL_BASE * accel_mult)
		air_accelerate(
			player,
			delta,
			movement_dir.normalized(),
			air_strafe_speed,
			air_strafe_accel
		)

	if previous_grappling and not pre.is_grappling:
		player.movement_velocity.x = player.velocity.x
		player.movement_velocity.z = player.velocity.z

	previous_grappling = pre.is_grappling


func air_accelerate(
	player: Node,
	delta: float,
	wish_dir: Vector3,
	wish_speed: float,
	accel: float
) -> void:
	var current_speed: float = (
		player.movement_velocity.x * wish_dir.x
		+ player.movement_velocity.z * wish_dir.z
	)

	var add_speed: float = (
		wish_speed - current_speed
	)

	if add_speed <= 0.0:
		return

	var accel_speed: float = min(
		accel * wish_speed * delta,
		add_speed
	)

	player.movement_velocity.x += (
		accel_speed * wish_dir.x
	)

	player.movement_velocity.z += (
		accel_speed * wish_dir.z
	)
