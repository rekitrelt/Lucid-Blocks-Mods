extends RefCounted

var console: CanvasLayer

func setup(console_instance: CanvasLayer) -> void:
	console = console_instance

func register(registry: RefCounted) -> void:
	registry.register(
		"tp",
		"Teleport the player",
		"tp <x> <y> <z>",
		_execute
	)

func _execute(args: Array[String]) -> void:
	if args.size() != 3:
		console.print_line("[color=red]Usage: tp <x> <y> <z>[/color]")
		return

	if (
		not _is_number(args[0])
		or not _is_number(args[1])
		or not _is_number(args[2])
	):
		console.print_line("[color=red]Coordinates must be numbers.[/color]")
		return

	var x: float = args[0].to_float()
	var y: float = args[1].to_float()
	var z: float = args[2].to_float()

	console.print_line("[color=green]Teleporting to (%s, %s, %s)[/color]" % [x,y,z])

	Ref.player.global_position = Vector3(x, y, z)


func _is_number(value: String) -> bool:
	if value.is_empty():
		return false

	var start := 0

	if value[0] == "-" or value[0] == "+":
		start = 1

	var decimal_count := 0
	var digit_count := 0

	for i in range(start, value.length()):
		var character := value[i]

		if character == ".":
			decimal_count += 1

			if decimal_count > 1:
				return false

			continue

		if character < "0" or character > "9":
			return false

		digit_count += 1

	return digit_count > 0
