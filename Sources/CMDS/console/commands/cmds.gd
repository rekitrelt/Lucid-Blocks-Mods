extends RefCounted

var console: CanvasLayer

func setup(console_instance: CanvasLayer) -> void:
	console = console_instance

func register(registry: RefCounted) -> void:
	registry.register(
		"cmds",
		"List available commands",
		"cmds",
		_execute
	)

func _execute(_args: Array[String]) -> void:
	console.print_line("[color=yellow]Available commands:[/color]")

	for command_name in console.get_command_names():
		var command: Dictionary = console.get_command(command_name)

		if command.is_empty():
			continue

		var description: String = command["description"]
		var usage: String = command["usage"]

		console.print_line("  [color=cyan]%s[/color] - %s" % [usage, description])
