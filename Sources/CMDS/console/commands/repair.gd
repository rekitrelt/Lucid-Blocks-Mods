extends RefCounted

var console: CanvasLayer

func setup(console_instance: CanvasLayer) -> void:
	console = console_instance

func register(registry: RefCounted) -> void:
	registry.register(
		"repair",
		"Repair the held item",
		"repair",
		_execute
	)

func _execute(args: Array[String]) -> void:
	var helditem = Ref.player.held_item
	helditem.item_state.durability = helditem.item.max_durability
	helditem.inventory.refresh.emit(helditem.inventory_index)
