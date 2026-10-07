class_name Grid extends Node2D

# TODO: maybe these can just be colors?
@export var zero_texture: Texture2D
@export var odd_texture: Texture2D
@export var even_texture: Texture2D

# TODO: do we want to have walls? whole tile walls, or edges?
# edges feels better, but maybe more 868 style play? but, ranged attack there..
# tomorrow: walls + move player around, and enemy spawning, first thing.
var gridsize: int = 0 # this is what actually operates on the grid.

# things that are on the grid
@onready var player: Entity = $Entities/Player
var enemies: Array[Enemy] = []
var exit: Entity

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("product"):
		$TileSums.hide()
		$TileProducts.show()
	elif event.is_action_released("product"):
		$TileProducts.hide()
	elif event.is_action_pressed("sum"):
		$TileProducts.hide()
		$TileSums.show()
	elif event.is_action_released("sum"):
		$TileSums.hide()


func update_grid(modulus: int) -> void:
	for child in $GridNumbers.get_children():
		child.visible = false
		child.queue_free()
	for child in $Tiles.get_children():
		child.visible = false
		child.queue_free()
	for child in $TileProducts.get_children():
		if child is not ColorRect:
			child.visible = false
			child.queue_free()
	for child in $TileSums.get_children():
		if child is not ColorRect:
			child.visible = false
			child.queue_free()
	
	# col of numbers
	for i in range(0, modulus):
		var num: RichTextLabel = preload("res://scenes/grid_number.tscn").instantiate()
		num.text = str(i)
		
		$GridNumbers.add_child(num)
		num.position = $TopLeftColNums.position + Vector2.DOWN * 7 * i
	
	# row of numbers
	for i in range(0, modulus):
		var num: RichTextLabel = preload("res://scenes/grid_number.tscn").instantiate()
		num.text = str(i)
		
		$GridNumbers.add_child(num)
		num.position = $TopLeftRowNums.position + Vector2.RIGHT * 7 * i
	
	# tiles themselves
	# TODO: special case for mod 0
	for row in range(0, modulus):
		for col in range(0, modulus):
			var underlying_value = (row * col) % modulus
			var sprite = Sprite2D.new()
			sprite.centered = false
			if row == 0 or col == 0:
				sprite.texture = zero_texture
			elif row % 2 == col % 2:
				sprite.texture = even_texture
			else:
				sprite.texture = odd_texture
			$Tiles.add_child(sprite)
			sprite.position = $TopLeftTiles.position + Vector2.RIGHT * 7 * row + Vector2.DOWN * 7 * col
			
			var prod: RichTextLabel = preload("res://scenes/grid_number.tscn").instantiate()
			prod.text = str((row * col) % modulus)
			$TileProducts.add_child(prod)
			prod.position = $TopLeftTiles.position + Vector2.RIGHT * 7 * row + Vector2.DOWN * 7 * col + Vector2.ONE + Vector2.RIGHT
			
			var sum: RichTextLabel = preload("res://scenes/grid_number.tscn").instantiate()
			sum.text = str((row + col) % modulus)
			$TileSums.add_child(sum)
			sum.position = $TopLeftTiles.position + Vector2.RIGHT * 7 * row + Vector2.DOWN * 7 * col + Vector2.ONE+ Vector2.RIGHT
	
	
	gridsize = modulus

func clamp_stuff(modulus: int) -> void:
	update_grid(modulus)
	for enemy in enemies:
		enemy.change_enemy_number(enemy.enemy_number % modulus)
	player.hp %= modulus

func place_first_floor() -> void:
	var corners = [Vector2i(0, 0), Vector2i(0, 6), Vector2i(6, 0), Vector2i(6, 6)]
	var player_corner = corners.pick_random()
	player.place_immediate(player_corner.x, player_corner.y, self)
	
	# TODO (sam): if we have walls maybe change the way this works.
	exit = preload("res://scenes/exit.tscn").instantiate()
	$Entities.add_child(exit)
	$Entities.move_child(exit, 0)
	var exit_corner = abs(Vector2i(6, 6) - player_corner)
	exit.place_immediate(exit_corner.x, exit_corner.y, self)
	
	for i in range(0, 2):
		var spell: Entity = SpellDatabase.get_random_spell()
		$Entities/Spells.add_child(spell)
		
		var pos = pick_random_tile_unoccupied()
		spell.place_immediate(pos.x, pos.y, self)
	
func place_next_floor() -> void:
	exit.queue_free()
	exit.visible = false
	exit.place_immediate(-1000, -1000, self)
	
	exit = preload("res://scenes/exit.tscn").instantiate()
	$Entities.add_child(exit)
	$Entities.move_child(exit, 0)
	var exit_corner = abs(Vector2i(6, 6) - player.grid_position)
	exit.place_immediate(exit_corner.x, exit_corner.y, self)
	
	for spell in $Entities/Spells.get_children():
		spell.visible = false
		spell.queue_free()
		spell.place_immediate(-1000, -1000, self)
	
	for i in range(0, 2):
		var spell: Entity = SpellDatabase.get_random_spell()
		$Entities/Spells.add_child(spell)
		
		var pos = pick_random_tile_unoccupied()
		spell.place_immediate(pos.x, pos.y, self)

func spawn_enemy(enemy_number: int) -> void:
	# 1. find an available tile (away from player?)
	var spawnpos := pick_random_tile_unoccupied()
	# 2. TODO place a little spawn marker there
	# 3. spawn marker will manage itself? or we tick it in the game.
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.enemy_number = enemy_number
	$Entities/Enemies.add_child(enemy)
	enemy.place_immediate(spawnpos.x, spawnpos.y, self)
	
	enemies.append(enemy)

func spawn_enemy_at_pos(enemy_number: int, x: int, y: int) -> void:
	# 2. TODO place a little spawn marker there
	# 3. spawn marker will manage itself? or we tick it in the game.
	var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
	enemy.enemy_number = enemy_number
	$Entities/Enemies.add_child(enemy)
	enemy.place_immediate(x, y, self)
	
	enemies.append(enemy)

func remove_enemies() -> void:
	for enemy in enemies:
		enemy.queue_free()
	enemies = []

func pick_random_tile() -> Vector2i:
	return Vector2i(randi_range(0, gridsize - 1), randi_range(0, gridsize - 1))

# rejection sample will probabilistically terminate
func pick_random_tile_unoccupied() -> Vector2i:
	var coords = pick_random_tile()
	while has_wall(coords) or has_player(coords) or has_enemy(coords):
		coords = pick_random_tile()
	return coords

func pick_random_unoccupied_tile_with_distance_from_another(other: Vector2i, dist: int) -> Vector2i:
	for i in range(10):
		var x := randi_range(0, 3)
		var y := 4 - x
		x *= 1 if randf() > 0.5 else -1
		y *= 1 if randf() > 0.5 else -1
		var candidate := other + Vector2i(x, y)
		if not has_wall(candidate) and not has_player(candidate) and not has_enemy(candidate):
			return candidate
	
	return pick_random_tile_unoccupied()

func tiles_that_have_sum_n(n: int, m: int) -> Array[Vector2i]:
	var sums: Array[Vector2i] = []
	for i in range(0, n + 1):
		var sum = Vector2i(i, posmod(n - i, m))
		sums.append(sum)
		if sum != Vector2i(sum.y, sum.x):
			sums.append(Vector2i(sum.y, sum.x))
	return sums

func tiles_that_have_product_n(n: int, m: int) -> Array[Vector2i]:
	for i in range(0, n + 1):
		pass
	return []

# FIXME: add all entities once we have them.
func get_entity(coords: Vector2i) -> Entity:
	var ents = enemies + [player] + [exit]
	for ent in ents:
		if ent.grid_position == coords:
			return ent
	return null

func get_player(coords: Vector2i) -> Entity:
	if player.grid_position != coords:
		return null
	return player

func get_spell(coords: Vector2i) -> Spell:
	for spell: Spell in $Entities/Spells.get_children():
		if spell.grid_position == coords:
			return spell
	return null

func remove_spell_from_grid(spell: Spell) -> void:
	$Entities/Spells.remove_child(spell) 

func tile_neighbors_ortho(tile: Vector2i) -> Array[Vector2i]:
	return [tile + Vector2i.LEFT, tile + Vector2i.RIGHT, tile + Vector2i.UP, tile + Vector2i.DOWN]

func tile_neighbors_ortho_inbounds(tile: Vector2i) -> Array[Vector2i]:
	return tile_neighbors_ortho(tile).filter(inbounds)

# FIXME: handle partial paths.
func a_star(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	# referred to https://www.redblobgames.com/pathfinding/a-star/implementation.html#python-astar
	var frontier := PriorityQueue.new()
	var path := []
	
	# manhattan dist heuristic
	var heuristic := func(a: Vector2i, b: Vector2i) -> int: return abs(a.x - b.x) + abs(a.y - b.y)
	var came_from: Dictionary[Vector2i, Vector2i] = {}
	var cost_so_far: Dictionary[Vector2i, float] = {}
	
	var start := Time.get_ticks_usec()
	frontier.push(from, 0)
	came_from[from] = from
	cost_so_far[from] = 0
	var steps := 0
	while not frontier.is_empty():
		steps += 1
		
		var cur = frontier.pop()
		if cur == to:
			break
		
		var neighbors := tile_neighbors_ortho_inbounds(cur)
		neighbors = neighbors.filter(func(n): return not has_enemy(n))
		neighbors.shuffle()
		
		for next in neighbors:
			var new_cost: float = cost_so_far[cur] + 1 # TODO (sam): this is where walls would come into play?
			if next not in cost_so_far or new_cost < cost_so_far[next]:
				cost_so_far[next] = new_cost
				var priority = new_cost + heuristic.call(next, to)
				frontier.push(next, priority)
				came_from[next] = cur
		
	print("a-star took ", (Time.get_ticks_usec() - start) / 1000.0, " ms")
	
	# FIXME: if we failed to find a path not sure what to do
	var node := to
	if to not in came_from:
		node = came_from.keys()[-1]
		
	while node != from:
		path.push_front(node)
		node = came_from[node]
	path.push_front(node)
	
	return path


func inbounds(coords: Vector2i) -> bool:
	return coords.x >= 0 and coords.y >= 0 and coords.x < (gridsize) and coords.y < (gridsize)

func has_spell(coords: Vector2i) -> bool:
	for spell: Spell in $Entities/Spells.get_children():
		if spell.grid_position == coords:
			return true
	return false

func has_player(coords: Vector2i) -> bool:
	return coords == player.grid_position

func has_exit(coords: Vector2i) -> bool:
	return coords == exit.grid_position

func has_wall(coords: Vector2i) -> bool:
	return false

func get_enemy(coords: Vector2i) -> Enemy:
	for enemy: Enemy in $Entities/Enemies.get_children():
		if enemy.grid_position == coords and enemy.enemy_number != 0:
			return enemy
	return null

func has_enemy(coords: Vector2i) -> bool:
	for enemy: Enemy in $Entities/Enemies.get_children():
		if enemy.grid_position == coords and enemy.enemy_number != 0:
			return true
	return false
	
func has_enemy_including_zero(coords: Vector2i) -> bool:
	for enemy: Enemy in $Entities/Enemies.get_children():
		if enemy.grid_position == coords:
			return true
	return false

func tile_pos_to_world_pos(coords: Vector2i) -> Vector2:
	return $TopLeftTiles.position + Vector2.RIGHT * 7 * (coords.x) + Vector2.DOWN * 7 * (coords.y)
