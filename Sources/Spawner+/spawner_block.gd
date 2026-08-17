extends "res://main/world/living_block/spawner_block/spawner_block.gd"

var spawn_rate_multiplier: float = 1.0

var canUpgrade = false

func can_currently_interact(interactor: Entity) -> bool:
	if is_instance_valid(interactor):
		if interactor.held_item == null:
			return true
		else:
			var heldItem = interactor.held_item
			var held_item_name = heldItem.item.display_name
			var holdingSpawner = held_item_name == "vermin vigil block"
			if not Ref.player.is_breaking_block:
				canUpgrade = true
			if holdingSpawner and Ref.player.is_breaking_block and canUpgrade:
				canUpgrade = false
				var indx = heldItem.inventory_index
				heldItem.item_state.count -= 1
				heldItem.inventory.refresh.emit(indx)
				if heldItem.item_state.count <= 0:
					heldItem.inventory.set_item(indx, null)
				_increase_spawn_rate()
				return true

	return super.can_currently_interact(interactor)

func _remove_item(item: HeldItem) -> void :
	var indx = item.inventory_index
	item.inventory.set_item(indx, null)

func before_breaking() -> void :
	spawn_rate_multiplier -= 1
	if spawn_rate_multiplier > 0:
		_give("vermin vigil block", spawn_rate_multiplier)

func _give(itemName: String, amount: int) -> void:
	var item_id: int = _resolve_itemID(itemName)

	if item_id <= -1:
		return

	var durability: int = -1

	var item_state := ItemState.new()

	item_state.id = item_id
	item_state.count = amount

	if durability <= -1:
		var maxdur: int = ItemMap.map(item_state.id).max_durability
		if maxdur != 0:
			item_state.durability = maxdur
	else:
		item_state.durability = durability

	Ref.player_inventory.accept(item_state)

	var item: Item = ItemMap.map(item_id)

func _resolve_itemID(value: String) -> int:
	for id in ItemMap.all_item_ids:
		var item: Item = ItemMap.map(id)
		var item_name: String = item.display_name.to_lower()

		if item_name == value.to_lower():
			return id

	return -1

func interact(interactor: Entity) -> void:
	if not can_currently_interact(interactor):
		return

	if interactor.held_item == null:
		_toggle_spawning()
		return

	super.interact(interactor)

func _increase_spawn_rate() -> void:
	# print("Spawner+", "increased spawn rate")
	# max_count = 8 * spawn_rate_multiplier
	spawn_rate_multiplier += 1.0

	_update_spawn_times()

	if spawning:
		spawn_timer.start(_get_spawn_delay())

	interact_sound.play()

static var _offset_cache: Dictionary = {}

static func _get_sorted_offsets(spawn_radius: float) -> Array[Vector3i]:
	var key: float = snappedf(spawn_radius, 0.01)

	if _offset_cache.has(key):
		return _offset_cache[key]

	var search_radius: int = int(ceil(spawn_radius))
	var radius_sq: int = int(ceil(spawn_radius * spawn_radius))

	var offsets: Array[Vector3i] = []

	for x in range(-search_radius, search_radius + 1):
		var xx := x * x
		for y in range(-search_radius, search_radius + 1):
			var yy := y * y
			for z in range(-search_radius, search_radius + 1):
				var zz := z * z
				if xx + yy + zz > radius_sq:
					continue
				offsets.append(Vector3i(x, y, z))

	offsets.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return a.length_squared() < b.length_squared()
	)

	_offset_cache[key] = offsets
	return offsets

@onready var mod_main = get_node("/root/ModLoader/Mod_Spawner+")

func attempt_spawn() -> void:
	if not spawning:
		return

	if not mod_main.replace_spawning:
		super.attempt_spawn()
		return

	if not is_instance_valid(spawn_scene):
		spawn_timer.start(_get_spawn_delay())
		return

	shape.force_shapecast_update()

	var entity_count: int = shape.get_collision_count()

	if entity_count >= max_count:
		spawn_timer.start(_get_spawn_delay())
		return

	var center: Vector3 = global_position + Vector3(0.5, 0.5, 0.5)
	var center_block: Vector3i = Vector3i(floor(center))

	var offsets: Array[Vector3i] = _get_sorted_offsets(spawn_radius)

	for offset in offsets:
		var spawn_block: Vector3i = center_block + offset
		var ground_block: Vector3i = spawn_block + Vector3i(0, -1, 0)

		if not Ref.world.is_position_loaded(spawn_block):
			continue

		if not Ref.world.is_position_loaded(ground_block):
			continue

		if Ref.world.is_block_solid_at(spawn_block):
			continue

		if not Ref.world.is_block_solid_at(ground_block):
			continue

		var spawn_position: Vector3 = (Vector3(spawn_block) + Vector3(0.5, 0.1, 0.5))

		var new_entity: Entity = spawn_scene.instantiate()

		if not is_instance_valid(new_entity):
			continue

		new_entity.global_position = spawn_position
		get_tree().root.add_child(new_entity)

		anim.play("spawn")

		spawn_timer.start(_get_spawn_delay())
		return

	spawn_timer.start(_get_spawn_delay())

func _spawn_timeout() -> void:
	print("Spawner TIMEOUT at ", Time.get_ticks_msec())
	attempt_spawn()

func _get_spawn_delay() -> float:
	var delay: float = (
		spawn_time_multiplier *
		randf_range(min_spawn_time, max_spawn_time)
	)

	print(
		"Spawner delay: ",
		delay,
		" | timer: ",
		spawn_timer.time_left
	)

	return delay

func _toggle_spawning() -> void:
	spawning = not spawning

	if spawning:
		if not is_instance_valid(spawn_scene):
			load_spawn()

		if not is_instance_valid(spawn_scene):
			spawning = false
			update_interface()
			return

		spawn_timer.start(_get_spawn_delay())
	else:
		spawn_timer.stop()

	interact_sound.play()
	update_interface()

func preserve_save(file: SaveFile, uuid: String) -> void:
	super.preserve_save(file, uuid)

	file.set_data(
		"node/%s/spawn_id" % uuid,
		spawn_id
	)

	file.set_data(
		"node/%s/spawn_rate_multiplier" % uuid,
		spawn_rate_multiplier
	)

func preserve_load(file: SaveFile, uuid: String) -> void:
	super.preserve_load(file, uuid)

	spawn_rate_multiplier = file.get_data(
		"node/%s/spawn_rate_multiplier" % uuid,
		1.0
	)

	_update_spawn_times()

	if spawning:
		if is_instance_valid(spawn_scene):
			spawn_timer.start(_get_spawn_delay())
	else:
		spawn_id = file.get_data(
			"node/%s/spawn_id" % uuid,
			0
		)

		if spawn_id != 0:
			load_spawn()

		spawn_timer.stop()
		update_interface()

func _update_spawn_times() -> void:
	min_spawn_time = 8.0 / (2.0 * spawn_rate_multiplier)
	max_spawn_time = 16.0 / (2.0 * spawn_rate_multiplier)

func load_spawn() -> void:
	if not ItemMap.id_to_resource.has(spawn_id):
		spawning = false
		spawn_scene = null
		return

	spawn_capsule = ItemMap.map(spawn_id) as Spawner

	if not is_instance_valid(spawn_capsule):
		spawning = false
		spawn_scene = null
		return

	if spawn_capsule.entity_path.is_empty():
		spawning = false
		spawn_scene = null
		return

	if not ResourceLoader.exists(spawn_capsule.entity_path):
		spawning = false
		spawn_scene = null
		return

	spawn_scene = load(spawn_capsule.entity_path)
	spawn_time_multiplier = spawn_capsule.spawn_time_multiplier

	if spawning:
		spawn_timer.start(_get_spawn_delay())
