extends RefCounted

var console: CanvasLayer

func setup(console_instance: CanvasLayer) -> void:
	console = console_instance

func register(registry: RefCounted) -> void:
	registry.register(
		"xp",
		"Give XP to the player",
		"xp <amount>",
		_execute
	)

func _execute(args: Array[String]) -> void:
	if args.size() != 1:
		console.print_line("[color=red]Usage: xp <amount>[/color]")
		return

	if (not _is_number(args[0])):
		console.print_line("[color=red]Amount must be a number.[/color]")
		return

	var tiamana: float = args[0].to_float()

	console.print_line("[color=green]Giving player (%s) tiamana[/color]" % [tiamana])

	Ref.player.get_node("%Level").give_tiamana(tiamana, Level.TiamanaSource.NONE)


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
