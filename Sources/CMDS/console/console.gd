extends CanvasLayer

const COMMAND_REGISTRY_SCRIPT = preload("res://mods/CMDS/console/command_registry.gd")

const COMMANDS_PATH := "res://mods/CMDS/console/commands"

@onready var panel: PanelContainer = $ConsolePanel
@onready var output: RichTextLabel = $ConsolePanel/Margin/VBox/Output
@onready var suggestions: ItemList = $ConsolePanel/Margin/VBox/Suggestions
@onready var input: LineEdit = $ConsolePanel/Margin/VBox/InputRow/Input

var registry: RefCounted

var console_open: bool = false

var command_history: Array[String] = []
var history_index: int = -1

var completion_matches: Array[String] = []
var completion_index: int = 0
var completion_active: bool = false
var suppress_completion_reset: bool = false

var completion_base: String = ""

var command_objects: Array[RefCounted] = []

func _ready() -> void:
	registry = COMMAND_REGISTRY_SCRIPT.new()

	_register_commands()

	panel.visible = false
	suggestions.visible = false

	input.text_changed.connect(_on_input_changed)
	input.gui_input.connect(_on_input_gui_input)

	_print_line("[color=gray]Type 'help' for commands[/color]")

func _input(event: InputEvent) -> void:
	if console_open:
		return

	if event is InputEventKey:
		if not event.pressed or event.echo:
			return

		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_SEMICOLON:
			var state: int = Ref.game_menu.state
			
			if state == GameMenu.DEFAULT:
				Ref.game_menu.open_pause()
				_open_console()
				get_viewport().set_input_as_handled()
			elif state == GameMenu.PAUSE:
				Ref.game_menu.close_pause()
				_close_console()


func _register_commands() -> void:
	var directory: DirAccess = DirAccess.open(COMMANDS_PATH)

	if directory == null:
		push_error("Console: Failed to open commands directory: " + COMMANDS_PATH)
		return

	var files: Array[String] = []

	directory.list_dir_begin()

	while true:
		var file_name: String = directory.get_next()

		if file_name.is_empty():
			break

		if directory.current_is_dir():
			continue

		if file_name.ends_with(".gd"):
			files.append(file_name)

	directory.list_dir_end()

	files.sort()

	for file_name in files:
		var script_path: String = COMMANDS_PATH + "/" + file_name
		var command_script: Variant = load(script_path)

		if command_script == null:
			push_error("Console: Failed to load command: " + script_path)
			continue

		if not command_script is Script:
			continue

		_register_command(command_script)

func _register_command(command_script: Script) -> void:
	var command: RefCounted = command_script.new()

	command.setup(self)
	command.register(registry)

	command_objects.append(command)

func print_line(text: String) -> void:
	_print_line(text)

func clear_output() -> void:
	output.clear()

func get_command_names() -> Array[String]:
	return registry.get_command_names()

func get_command(command_name: String) -> Dictionary:
	return registry.get_command(command_name)

func _open_console() -> void:
	console_open = true
	panel.visible = true

	input.grab_focus()
	input.caret_column = input.text.length()

	_clear_suggestions()

func _close_console() -> void:
	console_open = false
	panel.visible = false

	input.release_focus()

	_clear_suggestions()

func _on_input_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_ESCAPE:
			_close_console()
			get_viewport().set_input_as_handled()

		KEY_ENTER, KEY_KP_ENTER:
			_execute_command(input.text)
			input.clear()
			_clear_suggestions()
			get_viewport().set_input_as_handled()

		KEY_UP:
			_history_up()
			get_viewport().set_input_as_handled()

		KEY_DOWN:
			_history_down()
			get_viewport().set_input_as_handled()

		KEY_TAB:
			_complete_input()
			get_viewport().set_input_as_handled()

func _on_input_changed(_new_text: String) -> void:
	if suppress_completion_reset:
		_update_suggestions()
		return

	completion_matches.clear()
	completion_index = 0
	completion_base = ""
	completion_active = false

	history_index = -1
	_update_suggestions()

func _execute_command(text: String) -> void:
	text = text.strip_edges()

	if text.is_empty():
		return

	_add_history(text)

	_print_line("[color=gray]>[/color] " + text)

	var parts: PackedStringArray = text.split(" ", false)

	if parts.is_empty():
		return

	var command_name: String = parts[0].to_lower()
	var args: Array[String] = []

	for i in range(1, parts.size()):
		args.append(parts[i])

	var command: Dictionary = registry.get_command(command_name)

	if command.is_empty():
		_print_line("[color=red]Unknown command: %s[/color]" % command_name)
		return

	var callback: Callable = command["callback"]

	if not callback.is_valid():
		_print_line("[color=red]Command has no valid callback[/color]")
		return

	callback.call(args)

func _add_history(text: String) -> void:
	if text.is_empty():
		return

	if not command_history.is_empty():
		if command_history[0] == text:
			history_index = -1
			return

	command_history.push_front(text)

	if command_history.size() > 100:
		command_history.resize(100)

	history_index = -1

func _history_up() -> void:
	if command_history.is_empty():
		return

	completion_active = false

	if history_index < command_history.size() - 1:
		history_index += 1

	input.text = command_history[history_index]
	input.caret_column = input.text.length()

	_update_suggestions()

func _history_down() -> void:
	if command_history.is_empty():
		return

	completion_active = false

	if history_index > 0:
		history_index -= 1

		input.text = command_history[history_index]
		input.caret_column = input.text.length()
	else:
		history_index = -1
		input.clear()

	_update_suggestions()

func _complete_input() -> void:
	if not completion_active:
		completion_base = input.text

		completion_matches = registry.get_completions(completion_base)

		if completion_matches.is_empty():
			completion_base = ""
			return

		completion_index = 0
		completion_active = true

		_apply_completion(completion_matches[completion_index])
		return

	if completion_matches.is_empty():
		completion_active = false
		return

	completion_index += 1

	if completion_index >= completion_matches.size():
		completion_index = 0

	_apply_completion(completion_matches[completion_index])

func _apply_completion(completion: String) -> void:
	var parts: PackedStringArray = completion_base.split(" ", false)

	if parts.is_empty():
		return

	suppress_completion_reset = true

	if parts.size() == 1:
		input.text = completion
	else:
		parts[parts.size() - 1] = completion
		input.text = " ".join(parts)

	input.caret_column = input.text.length()

	suppress_completion_reset = false

	_update_suggestions()

func _update_suggestions() -> void:
	if not console_open:
		return

	var text: String = input.text.strip_edges()
	var parts: PackedStringArray = text.split(" ", false)

	suggestions.clear()

	if parts.is_empty():
		var command_names: Array[String] = registry.get_command_names()

		for command_name in command_names:
			var command: Dictionary = registry.get_command(command_name)

			if command.is_empty():
				continue

			var description: String = command["description"]

			suggestions.add_item("%s - %s" % [
				command_name,
				description
			])

		suggestions.visible = suggestions.item_count > 0
		return

	var command_name: String = parts[0].to_lower()
	var command: Dictionary = registry.get_command(command_name)

	if command.is_empty():
		var command_matches: Array[String] = registry.get_completions(text)

		for name in command_matches:
			var completion_command: Dictionary = (registry.get_command(name))

			if completion_command.is_empty():
				continue

			suggestions.add_item("%s - %s" % [
				name,
				completion_command["description"]
			])

		suggestions.visible = suggestions.item_count > 0
		return

	var usage: String = command["usage"]

	suggestions.add_item(_build_usage_preview(usage, parts))

	if parts.size() >= 2 and not completion_active:
		var matches: Array[String] = registry.get_completions(text)

		for match in matches:
			suggestions.add_item(match)

	elif completion_active:
		for match in completion_matches:
			suggestions.add_item(match)

	suggestions.visible = suggestions.item_count > 0

func _build_usage_preview(
	usage: String,
	parts: PackedStringArray
) -> String:
	if parts.is_empty():
		return usage

	var usage_parts: PackedStringArray = usage.split(" ", false)

	var result: Array[String] = []

	for i in range(usage_parts.size()):
		if i < parts.size():
			result.append(parts[i])
		else:
			result.append(usage_parts[i])

	return " ".join(result)

func _clear_suggestions() -> void:
	completion_matches.clear()
	completion_index = 0
	completion_base = ""
	completion_active = false

	suggestions.clear()
	suggestions.visible = false

func _print_line(text: String) -> void:
	output.append_text(text + "\n")

	await get_tree().process_frame

	output.scroll_to_line(output.get_line_count() - 1)
