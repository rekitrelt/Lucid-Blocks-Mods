extends RefCounted

var console: CanvasLayer

func setup(console_instance: CanvasLayer) -> void:
	console = console_instance

func register(registry: RefCounted) -> void:
	registry.register(
		"give",
		"Give an item",
		"give <id|name> [amount] [durability]",
		_execute,
		_complete
	)

func _execute(args: Array[String]) -> void:
	if args.is_empty():
		console.print_line("[color=red]Usage: give <id|name> [amount] [durability][/color]")
		return

	var item_id: int = _resolve_item(args[0])

	if item_id == -1:
		console.print_line("[color=red]Unknown item: %s[/color]" % args[0])
		return

	var amount: int = 1

	if args.size() >= 2:
		if not _is_integer(args[1]):
			console.print_line("[color=red]Amount must be a number.[/color]")
			return

		amount = args[1].to_int()

		if amount <= 0:
			console.print_line("[color=red]Amount must be greater than 0.[/color]")
			return

	var durability: int = -1

	if args.size() >= 3:
		if not _is_integer(args[2]):
			console.print_line("[color=red]Durability must be a number.[/color]")
			return

		durability = args[2].to_int()

	var item_state := ItemState.new()

	item_state.id = item_id
	item_state.count = amount

	if durability == -1:
		var maxdur: int = ItemMap.map(item_state.id).max_durability
		if maxdur != 0:
			item_state.durability = maxdur
	else:
		item_state.durability = durability

	Ref.player_inventory.accept(item_state)

	var item: Item = ItemMap.map(item_id)

	console.print_line("[color=green]Gave %s x%d[/color]" % [item.display_name, amount])

func _resolve_item(value: String) -> int:
	if _is_integer(value):
		var id: int = value.to_int()

		if ItemMap.id_to_resource.has(id):
			return id

		return -1

	var search: String = _normalize_name(value)

	for id in ItemMap.all_item_ids:
		var item: Item = ItemMap.map(id)
		var item_name: String = _normalize_name(item.display_name)

		if item_name == search:
			return id

	return -1

func _complete(parts: PackedStringArray) -> Array[String]:
	var result: Array[String] = []

	if parts.size() <= 1:
		return result

	if parts.size() > 2:
		return result

	var search: String = parts[1].to_lower()

	for id in ItemMap.all_item_ids:
		var item: Item = ItemMap.map(id)
		var name: String = item.display_name.to_lower().replace(" ", "_")

		if name.contains(search):
			result.append(name)

	result.sort_custom(
		func(a: String, b: String) -> bool:
			var a_prefix: bool = a.begins_with(search)
			var b_prefix: bool = b.begins_with(search)

			if a_prefix != b_prefix:
				return a_prefix

			var a_position: int = a.find(search)
			var b_position: int = b.find(search)

			if a_position != b_position:
				return a_position < b_position

			return a.naturalnocasecmp_to(b) < 0
	)

	return result

func _normalize_name(value: String) -> String:
	var result: String = value.strip_edges().to_lower()

	result = result.replace(" ", "_")

	while result.contains("__"):
		result = result.replace("__", "_")

	return result


func _is_integer(value: String) -> bool:
	if value.is_empty():
		return false

	var start: int = 0

	if value[0] == "-" or value[0] == "+":
		start = 1

	if start >= value.length():
		return false

	for i in range(start, value.length()):
		var character: String = value[i]

		if character < "0" or character > "9":
			return false

	return true
