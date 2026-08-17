extends RefCounted

var console: CanvasLayer

func setup(console_instance: CanvasLayer) -> void:
	console = console_instance

func register(registry: RefCounted) -> void:
	registry.register(
		"clear",
		"Clear the console",
		"clear",
		_execute
	)


func _execute(_args: Array[String]) -> void:
	console.clear_output()
