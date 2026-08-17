extends RefCounted

var console: CanvasLayer

func setup(console_instance: CanvasLayer) -> void:
	console = console_instance

func register(registry: RefCounted) -> void:
	registry.register(
		"time",
		"Set world time-scale",
		"time <multiplier>",
		_execute
	)

func _execute(args: Array[String]) -> void:
	if args.size() != 1:
		console.print_line("[color=red]Usage: time <multiplier>[/color]")
		return

	if (not _is_number(args[0])):
		console.print_line("[color=red]Multiplier must be a number.[/color]")
		return

	var timescale: float = args[0].to_float()

	console.print_line("[color=green]Set world time-scale to (%s)[/color]" % [timescale])

	Ref.sun.set_time_scale(timescale)


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
