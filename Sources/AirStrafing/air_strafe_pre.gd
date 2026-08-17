extends Node

const MOD_ID: String = "air_strafe"

var saved_movement_velocity: Vector3 = Vector3.ZERO
var saved_movement_velocity_valid: bool = false

var saved_air_accel: float = 0.0
var saved_air_accel_valid: bool = false

var airborne: bool = false
var local_movement_enabled: bool = false
var will_jump: bool = false
var is_grappling: bool = false

func _physics_process(_delta: float) -> void:
	var player: Node = get_parent()

	if (
		not is_instance_valid(player)
		or not is_instance_valid(Ref.player)
		or player != Ref.player
		or player.disabled
		or not Ref.world.is_position_loaded(player.global_position)
	):
		return

	local_movement_enabled = (
		player.movement_enabled
		and MouseHandler.fully_captured
	)

	will_jump = (
		local_movement_enabled
		and player.is_on_floor()
		and player.is_action_pressed_safe("jump")
	)

	is_grappling = (
		is_instance_valid(player.held_item)
		and player.held_item is HeldRope
		and player.held_item in player.rope_velocities
	)

	airborne = (
		(not player.is_on_floor() or will_jump)
		and not player.is_crouching
		and not player.flying
		and not is_grappling
	)

	saved_movement_velocity = player.movement_velocity
	saved_movement_velocity_valid = true

	saved_air_accel = player.air_accel
	saved_air_accel_valid = true

	if airborne:
		saved_movement_velocity = player.movement_velocity
		saved_movement_velocity_valid = true
		player.air_accel = 0.0
	else:
		saved_movement_velocity_valid = false
