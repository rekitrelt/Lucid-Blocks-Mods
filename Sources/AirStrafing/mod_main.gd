extends "res://mods/qualiamods/mod_base.gd"

const MOD_ID: String = "air_strafe"

const PRE_SCRIPT = preload("res://mods/AirStrafing/air_strafe_pre.gd")

const POST_SCRIPT = preload("res://mods/AirStrafing/air_strafe_post.gd")

var pre_controller: Node = null
var post_controller: Node = null

func _init_mod(cfg: Dictionary) -> void:
	config = cfg

	ModLoader.add_hook(ModLoader.Hooks.GAME_PLAYABLE, _on_game_playable)

func _on_game_playable() -> void:
	if Ref.player == null:
		return

	if not is_instance_valid(Ref.player):
		return

	_install_controllers()

func _install_controllers() -> void:
	if is_instance_valid(pre_controller):
		return

	var accel_mult: float = get_cfg("accel_range", 0.5)

	var speed_mult: float = get_cfg("speed", 0.5)

	pre_controller = PRE_SCRIPT.new()
	pre_controller.name = "AirStrafePre"
	pre_controller.process_physics_priority = -100

	Ref.player.add_child(pre_controller)

	post_controller = POST_SCRIPT.new()
	post_controller.name = "AirStrafePost"

	post_controller.accel_mult = accel_mult
	post_controller.speed_mult = speed_mult
	post_controller.braking_on = get_cfg("braking", true)

	post_controller.process_physics_priority = 100

	Ref.player.add_child(post_controller)

func _on_config_changed(new_config: Dictionary) -> void:
	config = new_config

	var accel_mult: float = get_cfg("accel_range", 0.5)

	var speed_mult: float = get_cfg("speed",0.5)

	if is_instance_valid(post_controller):
		post_controller.accel_mult = accel_mult
		post_controller.speed_mult = speed_mult
