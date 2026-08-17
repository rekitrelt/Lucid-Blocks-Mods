extends "res://mods/qualiamods/mod_base.gd"

const MOD_ID: String = "Apotheon"

var FusionTimer: Timer
var FusionButton: TextureButton

var fusion_button_connected: bool = false

var fusion_snapshot: Array[ItemState] = []
var fusion_result_snapshot: Array[ItemState] = []

var restore_pending: bool = false
var craft_move_pending: bool = false

var RecipeRestore: bool = true
var CraftMove: bool = true

func _init_mod(cfg: Dictionary) -> void:
	config = cfg
	ModLoader.add_hook(ModLoader.Hooks.GAME_PLAYABLE, _on_game_playable)

func _on_game_playable() -> void:
	_apply_mod()

func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root == null:
		return null

	if root.name == node_name:
		return root

	for child in root.get_children():
		var result := _find_node_by_name(child, node_name)

		if result != null:
			return result

	return null

func _apply_mod() -> void:
	var ui: Node = get_tree().root.get_node_or_null("Main/UI")

	if ui == null:
		return

	RecipeRestore = get_cfg("Recipe-Restore", true)

	CraftMove = get_cfg("Craft-Move", true)

	if not is_instance_valid(FusionTimer):
		FusionTimer = _find_node_by_name(ui, "FusionTimer")

	if is_instance_valid(FusionTimer):
		FusionTimer.wait_time = (0.001 if get_cfg("No-Cooldown", true) else 0.85)

	if not is_instance_valid(FusionButton):
		FusionButton = _find_node_by_name(ui, "FusionButton")

	if not is_instance_valid(FusionButton):
		return

	if not fusion_button_connected:
		FusionButton.pressed.connect(_on_fusion_button_pressed)
		fusion_button_connected = true

func _on_fusion_button_pressed() -> void:
	var shift_click: bool = Input.is_key_pressed(KEY_SHIFT)

	if RecipeRestore:
		restore_pending = true
		_snapshot_fusion_source()

	if CraftMove and shift_click:
		craft_move_pending = true
	
	if restore_pending or craft_move_pending:
		_after_fusion()

func _after_fusion() -> void:
	if not restore_pending and not craft_move_pending:
		return

	var result: Inventory = Ref.player_fusion_result

	if not is_instance_valid(result):
		restore_pending = false
		craft_move_pending = false
		return

	await result.item_slot_changed

	if restore_pending:
		while not _fusion_source_changed_from_snapshot():
			await get_tree().process_frame

		restore_pending = false
		_restore_fusion_source()

	if craft_move_pending:
		craft_move_pending = false
		await get_tree().process_frame
		_move_fusion_result()

func _fusion_source_changed_from_snapshot() -> bool:
	var fusion: Inventory = Ref.player_fusion_source

	if not is_instance_valid(fusion):
		return false

	if fusion.items.size() != fusion_snapshot.size():
		return true

	for i in range(fusion_snapshot.size()):
		var current: ItemState = fusion.items[i]
		var snapshot: ItemState = fusion_snapshot[i]

		if current == null and snapshot == null:
			continue

		if current == null or snapshot == null:
			return true

		if current.id != snapshot.id:
			return true

		if current.count != snapshot.count:
			return true

		if current.durability != snapshot.durability:
			return true

	return false

func _move_fusion_result() -> void:
	var result: Inventory = Ref.player_fusion_result

	if not is_instance_valid(result):
		return

	if result.widget == null:
		return

	for i in range(result.capacity):
		var item: ItemState = result.items[i]

		if item == null:
			continue

		if item.count <= 0:
			continue

		var slot_node: Node = result.widget.get_child(i)

		if not slot_node is InventorySlot:
			continue

		var slot: InventorySlot = slot_node

		InventorySlot.transfer_stack(
			slot,
			false
		)

		return

func _snapshot_fusion_source() -> void:
	fusion_snapshot.clear()

	var fusion: Inventory = Ref.player_fusion_source

	if not is_instance_valid(fusion):
		return

	for item in fusion.items:
		if item == null:
			fusion_snapshot.append(null)
			continue

		var copy := ItemState.new()

		copy.id = item.id
		copy.count = item.count
		copy.durability = item.durability
		copy.position = item.position

		fusion_snapshot.append(copy)

func _restore_fusion_source() -> void:
	var fusion: Inventory = Ref.player_fusion_source
	var inventory: Inventory = Ref.player_inventory
	var hotbar: Inventory = Ref.player_hotbar

	if not is_instance_valid(fusion):
		return

	if not is_instance_valid(inventory):
		return

	if not is_instance_valid(hotbar):
		return

	for slot_index in range(fusion_snapshot.size()):
		var snapshot: ItemState = fusion_snapshot[slot_index]

		if snapshot == null:
			continue

		var amount_needed: int = snapshot.count

		var replacement: ItemState = _take_replacement(inventory, snapshot.id, amount_needed)

		if replacement == null:
			replacement = _take_replacement(hotbar, snapshot.id, amount_needed)

		if replacement == null:
			continue

		fusion.set_item(slot_index, replacement)

	fusion_snapshot.clear()

func _take_replacement(inventory: Inventory, item_id: int, amount: int) -> ItemState:
	for i in range(inventory.capacity):
		var item: ItemState = inventory.items[i]

		if item == null:
			continue

		if item.id != item_id:
			continue

		var take_amount: int = min(item.count, amount)

		var replacement := ItemState.new()

		replacement.id = item.id
		replacement.count = take_amount
		replacement.durability = item.durability
		replacement.position = item.position

		inventory.change_amount(i, -take_amount)

		return replacement

	return null
