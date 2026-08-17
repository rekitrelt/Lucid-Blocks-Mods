extends "res://mods/qualiamods/mod_base.gd"


func _setup() -> void:
	log_info("Initialized")

var console_scene := preload("res://mods/CMDS/console/console.tscn")

func _game_ready() -> void:
	var console = console_scene.instantiate()
	get_tree().root.add_child(console)

func _cleanup() -> void:
	pass
