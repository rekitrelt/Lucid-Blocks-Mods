extends "res://mods/qualiamods/mod_base.gd"

const MOD_ID: String = "NoFog"

func _init_mod(cfg: Dictionary) -> void:
	config = cfg
	ModLoader.add_hook(
		ModLoader.Hooks.GAME_PLAYABLE,
		_on_game_playable
	)

func _game_ready() -> void:
	_install_settings_patch()
	_apply_fog()

func _on_game_playable() -> void:
	_apply_fog()

func _install_settings_patch() -> void:
	if not is_instance_valid(Ref.environment):
		return

	Ref.save_file_manager.settings_updated.connect(_apply_fog)

func _on_config_changed(new_config: Dictionary) -> void:
	config = new_config
	_apply_fog()

func _apply_fog() -> void:
	if not is_instance_valid(Ref.environment):
		return

	if Ref.environment.environment == null:
		return

	var disable_fog: bool = get_cfg("disable_fog", true)
	
	Ref.environment.environment.fog_enabled = not disable_fog
	Ref.environment.environment.volumetric_fog_enabled = not disable_fog
