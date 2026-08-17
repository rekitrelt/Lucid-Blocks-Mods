extends "res://mods/qualiamods/mod_base.gd"

const MOD_ID := "spawner_toggle"
const REPLACEMENT_SCENE := preload("res://mods/Spawner+/spawner_block.tscn")
var replace_spawning = false

func _init_mod(cfg: Dictionary) -> void:
	config = cfg
	replace_spawning = get_cfg("new_valid_logic", false)

func _on_config_changed(new_config: Dictionary) -> void:
	config = new_config
	replace_spawning = get_cfg("new_valid_logic", false)

func _game_ready() -> void:
	_replace_spawner_scene()

func _replace_spawner_scene() -> void:
	var replaced := 0

	for id in ItemMap.all_item_ids:
		var item: Item = ItemMap.map(id)

		if item is Block:
			if item.living_block_path == "":
				continue

			if not item.living_block_path.contains("spawner_block/spawner_block.tscn"):
				continue

			item.living_block_scene = REPLACEMENT_SCENE
			replaced += 1

	ModLoader.log_mod(MOD_ID, "Replaced %d spawner block scene(s)." % replaced)
