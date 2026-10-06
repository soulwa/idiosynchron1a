class_name Run extends Node2D
# ie. a jogo

@onready var grid: Grid = $Grid

# stats and spells
var modulus: int = 7 # TODO (sam): should this be a more "global" thing?
var floor: int = 0
var score: int = 0
var player_spell_count: int = 7
var player_spells: Dictionary[int, Object] = {}

# secret global things?
var total_floors_cleared_this_run: int = 0
var total_player_moves_this_run: int = 0
var total_player_turns_this_run: int = 0

var total_player_moves_this_floor: int = 0
var player_floor_moves: Dictionary[int, int] = {}

# level state
var player_turn: bool = true
var player_moving: bool = false

var enemy_moving: bool = false
var enemy_priority_order: Array[Enemy] = []
var current_enemy_path: PackedVector2Array = []
var next_spot_on_path_to_move_to: int = 1
var current_enemy_moving: int = 0

var game_over = false

func _ready() -> void:
	first_floor()

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("confirm"):
			get_tree().reload_current_scene()
		return
	
	if player_turn:
		if not player_moving:
			# player move - poll for input, and take action (animate?)
			if Input.is_action_just_pressed("left"):
				if grid.player.attack_ok(-1, 0, grid, self):
					player_attack(-1, 0)
				elif grid.player.move_ok(-1, 0, grid, self):
					player_move(-1, 0)
				else:
					grid.player.animate_bump_in_direction(Vector2(-1, 0), 0.5, 0.05)
			elif Input.is_action_just_pressed("right"):
				if grid.player.attack_ok(1, 0, grid, self):
					player_attack(1, 0)
				elif grid.player.move_ok(1, 0, grid, self):
					player_move(1, 0)
				else:
					grid.player.animate_bump_in_direction(Vector2(1, 0), 0.5, 0.05)
			elif Input.is_action_just_pressed("up"):
				if grid.player.attack_ok(0, -1, grid, self):
					player_attack(0, -1)
				elif grid.player.move_ok(0, -1, grid, self):
					player_move(0, -1)
				else:
					grid.player.animate_bump_in_direction(Vector2(0, -1), 0.5, 0.05)
			elif Input.is_action_just_pressed("down"):
				if grid.player.attack_ok(0, 1, grid, self):
					player_attack(0, 1)
				elif grid.player.move_ok(0, 1, grid, self):
					player_move(0, 1)
				else:
					grid.player.animate_bump_in_direction(Vector2(0, 1), 0.5, 0.05)

			if grid.has_exit(grid.player.grid_position):
				next_floor()
	else:
		if not enemy_moving:
			var enemy_to_move := enemy_priority_order[current_enemy_moving]
			var next_spot: Vector2i = current_enemy_path[next_spot_on_path_to_move_to]
			var dmove: Vector2i = next_spot - enemy_to_move.grid_position
			if grid.has_player(next_spot):
				enemy_attack(enemy_to_move, dmove.x, dmove.y)
			else:
				enemy_move(enemy_to_move, dmove.x, dmove.y)
				next_spot_on_path_to_move_to += 1
			if enemy_to_move.moves <= 0:
				current_enemy_moving += 1
				if current_enemy_moving >= len(enemy_priority_order):
					pass_enemy_turn()
				else:
					current_enemy_path = grid.astar(enemy_priority_order[current_enemy_moving].grid_position, grid.player.grid_position)
					next_spot_on_path_to_move_to = 1
	
	# update the UI
	$UI/Stats/Modulus/Value.update_text(modulus)
	$UI/Stats/Floor/Value.update_text(floor)
	$UI/Stats/Health/Value.update_text(grid.player.hp)
	$UI/Stats/Moves/Value.update_text(grid.player.moves)
	$UI/Stats/Score/Value.update_text(score)

func player_move(x: int, y: int) -> void:
	player_moving = true
	total_player_moves_this_run += 1
	total_player_moves_this_floor += 1
	await grid.player.move(x, y, grid)
	player_moving = false
	try_pass_player_turn()

func player_attack(x: int, y: int) -> void:
	player_moving = true
	total_player_moves_this_run += 1
	total_player_moves_this_floor += 1
	await grid.player.bump_attack(x, y, grid, modulus)
	player_moving = false
	try_pass_player_turn()

func enemy_move(enemy: Entity, x: int, y: int) -> void:
	enemy_moving = true
	await enemy.move(x, y, grid)
	enemy_moving = false

func enemy_attack(enemy: Entity, x: int, y: int) -> void:
	enemy_moving = true
	await enemy.bump_attack(x, y, grid, modulus)
	enemy_moving = false

func spawn_floor_enemies() -> void:
	# TODO: base this on some smarter scaling, in terms of what can appear where.
	for i in range(1, floor+2):
		grid.spawn_enemy(randi_range(1, 4))

func spawn_enemy_on_floor() -> void:
	# TODO: base this on some smarter scaling, in terms of what can appear where.
	grid.spawn_enemy(randi_range(1, 4))

func first_floor() -> void:
	grid.update_grid(7)
	grid.place_objects()
	spawn_floor_enemies()

func next_floor() -> void:
	# TODO (sam): play a little animation, suggest that we actually have changed floors.
	player_floor_moves[floor] = total_player_moves_this_floor
	
	floor = (floor + 1) % modulus
	
	total_player_moves_this_floor = player_floor_moves.get_or_add(floor, 0)
	total_floors_cleared_this_run += 1
	
	# some enemy cleanup.
	grid.remove_enemies()
	grid.place_next_floor()
	spawn_floor_enemies()
	
	if grid.player.moves == 0:
		pass_enemy_turn()

func try_pass_player_turn() -> void:
	if grid.player.moves <= 0:
		total_player_turns_this_run += 1
		player_turn = false
	
	if not grid.enemies.is_empty():
		for enemy in grid.enemies:
			if enemy and not enemy.is_queued_for_deletion():
				enemy.reset_moves()
		
		enemy_moving = false
		enemy_priority_order = grid.enemies.duplicate(false)
		# TODO: not stable sort? maybe thats okay.
		enemy_priority_order.sort_custom(func(a: Enemy, b: Enemy): return a.enemy_number < b.enemy_number)
		
		# skip all 0 enemies.
		current_enemy_moving = 0
		while enemy_priority_order[current_enemy_moving].moves <= 0:
			current_enemy_moving += 1
			if current_enemy_moving >= len(enemy_priority_order):
				pass_enemy_turn()
				return
			
		current_enemy_path = grid.astar(enemy_priority_order[current_enemy_moving].grid_position, grid.player.grid_position)
		print(current_enemy_path)
		next_spot_on_path_to_move_to = 1
	else:
		pass_enemy_turn()

func pass_enemy_turn() -> void:
	# TODO: condition.
	player_turn = true
	grid.player.reset_moves()
	
	if grid.player.hp == 0:
		game_over = true
		
		await get_tree().create_timer(1.0).timeout
		grid.player.hide()
		grid.modulate.a = 0.5
		$UI/GameOver.show()
		
