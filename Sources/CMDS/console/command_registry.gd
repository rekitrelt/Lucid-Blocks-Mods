extends RefCounted

var commands: Dictionary = {}


func register(
	command_name: String,
	description: String,
	usage: String,
	callback: Callable,
	completion: Callable = Callable()
) -> void:
	commands[command_name.to_lower()] = {
		"name": command_name.to_lower(),
		"description": description,
		"usage": usage,
		"callback": callback,
		"completion": completion
	}


func unregister(command_name: String) -> void:
	commands.erase(command_name.to_lower())


func has_command(command_name: String) -> bool:
	return commands.has(command_name.to_lower())


func get_command(command_name: String) -> Dictionary:
	return commands.get(command_name.to_lower(), {})


func get_command_names() -> Array[String]:
	var result: Array[String] = []

	for command_name in commands:
		result.append(command_name)

	result.sort()

	return result


func get_completions(text: String) -> Array[String]:
	var result: Array[String] = []

	var stripped: String = text.strip_edges()

	if stripped.is_empty():
		return get_command_names()

	var parts: PackedStringArray = stripped.split(" ", false)

	if parts.is_empty():
		return result

	var command_name: String = parts[0].to_lower()

	if parts.size() == 1 and not stripped.ends_with(" "):
		for name in commands:
			if name.begins_with(command_name):
				result.append(name)

		result.sort()
		return result

	if not commands.has(command_name):
		return result

	var command: Dictionary = commands[command_name]
	var completion: Callable = command.get("completion", Callable())

	if not completion.is_valid():
		return result

	return completion.call(parts)

func get_usage(command_name: String) -> String:
	var command: Dictionary = get_command(command_name)

	if command.is_empty():
		return ""

	return command["usage"]

func get_completion_command(text: String) -> String:
	var stripped: String = text.strip_edges()

	if stripped.is_empty():
		return ""

	var parts: PackedStringArray = stripped.split(" ", false)

	if parts.is_empty():
		return ""

	return parts[0].to_lower()
