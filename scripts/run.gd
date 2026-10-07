class_name Run extends Node2D
# ie. a jogo

@onready var grid: Grid = $Grid

# stats and spells
var modulus: int = 7 # TODO (sam): should this be a more "global" thing?
var floor: int = 0
var score: int = 0
var player_spell_count: int = 7
var player_spells: Dictionary[int, Spell] = {}

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

var number_keys = [KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9]
var selected_spell = 0

var stored_number_key_event: int = -1

var used_spells_this_floor: Array[int] = []

@export var scenario_num: int = -1

var incadj := preload("res://scenes/spells/spell_incadj.tscn")

func _ready() -> void:
	if scenario_num < 0:
		first_floor()
	else:
		scenario_setup(scenario_num)

func scenario_setup(num: int) -> void:
	
	if num == 0:
		SpellDatabase.restrict_spells()
	
	grid.update_grid(modulus)
	grid.place_first_floor()
	
	#spawn_floor_enemies()
	#used_spells_this_floor.clear()
	#
	#var spell = SpellDatabase.get_random_spell()
	#learn_spell(0, spell, false)
	if num == 0:
		pass
	elif num == 1:
		floor = 4
		grid.spawn_enemy(0)
		learn_spell(0, preload("res://scenes/spells/spell_decadj.tscn").instantiate(), false)
	elif num == 2:
		floor = 6
		score = 6
		spawn_enemy_on_floor()
		spawn_enemy_on_floor()
		spawn_enemy_on_floor()
		learn_spell(0, preload("res://scenes/spells/spell_add_tile.tscn").instantiate(), false)
		learn_spell(1, preload("res://scenes/spells/spell_mul_tile.tscn").instantiate(), false)
		learn_spell(2, preload("res://scenes/spells/spell_decadj.tscn").instantiate(), false)
		learn_spell(3, incadj.instantiate(), false)
		learn_spell(4, incadj.instantiate(), false)
		learn_spell(5, preload("res://scenes/spells/spell_scoreadj.tscn").instantiate(), false)
	elif num == 3:
		spawn_enemy_on_floor()
		learn_spell(0, preload("res://scenes/spells/spell_incmod.tscn").instantiate(), false)
	elif num == 4:
		modulus = 100
		grid.clamp_stuff(modulus)
		clamp_run_stuff()
		spawn_enemy_with_number(99, grid.player.grid_position.x, grid.player.grid_position.y + 9)
	elif num == 5:
		floor = 2
		modulus = 1
		learn_spell(0, preload("res://scenes/spells/spell_decmod.tscn").instantiate(), false)
	elif num == 6:
		learn_spell(0, preload("res://scenes/spells/spell_inc_spell_target.tscn").instantiate(), false)
		learn_spell(1, preload("res://scenes/spells/spell_dec_spell_target.tscn").instantiate(), false)
		learn_spell(2, preload("res://scenes/spells/spell_incmod.tscn").instantiate(), false)
		learn_spell(3, preload("res://scenes/spells/spell_decmod.tscn").instantiate(), false)

func _input(event: InputEvent) -> void:
	if player_turn and not player_moving:
		if event is InputEventKey and not event.is_echo() and event.is_pressed():
			if event.physical_keycode in number_keys:
				stored_number_key_event = event.physical_keycode - 48

func clamp_run_stuff() -> void:
	score %= modulus
	floor %= modulus

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("confirm"):
			get_tree().reload_current_scene()
		return
	
	if player_turn:
		if not player_moving:
			try_pass_player_turn()
			
			if stored_number_key_event >= 0:
				if stored_number_key_event in player_spells:
					if stored_number_key_event not in used_spells_this_floor:
						use_spell_for_floor(stored_number_key_event)

				elif grid.has_spell(grid.player.grid_position):
					learn_spell(stored_number_key_event, grid.get_spell(grid.player.grid_position))
					grid.player.moves -= 1
				
				stored_number_key_event = -1
				
				try_pass_player_turn()
			
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
			
			if enemy_to_move.cant_move:
				var neighbors := grid.tile_neighbors_ortho(enemy_to_move.grid_position)
				var attack_happened := false
				for n in neighbors:
					if grid.has_player(n):
						enemy_attack(enemy_to_move, n.x - enemy_to_move.grid_position.x, n.y - enemy_to_move.grid_position.y)
						attack_happened = true
				if not attack_happened:
					enemy_to_move.moves = 0
			else:
				var next_spot: Vector2i
				if next_spot_on_path_to_move_to > len(current_enemy_path) - 1:
					print("path bad")
					next_spot = grid.tile_neighbors_ortho_inbounds(enemy_to_move.grid_position).filter(func (t): return not grid.has_enemy(t) and not grid.has_player(t)).pick_random()
				else:
					print("path ok")
					next_spot = current_enemy_path[next_spot_on_path_to_move_to]
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
					current_enemy_path = grid.a_star(enemy_priority_order[current_enemy_moving].grid_position, grid.player.grid_position)
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
	var target := grid.get_enemy(grid.player.grid_position + Vector2i(x, y))
	await grid.player.bump_attack(x, y, grid, target, modulus)
	player_moving = false
	try_pass_player_turn()

func use_spell_for_floor(slot: int) -> void:
	used_spells_this_floor.append(stored_number_key_event)
	$UI/Stats/Spells.get_child(stored_number_key_event).grey_spell()
	
	player_spells[stored_number_key_event].use(self, grid)

func refresh_spell_for_floor(slot: int) -> void:
	var idx := used_spells_this_floor.find(slot)
	if idx >= 0:
		used_spells_this_floor.remove_at(idx)
		$UI/Stats/Spells.get_child(slot).white_spell()

func refresh_all_spells() -> void:
	for sp in used_spells_this_floor:
		$UI/Stats/Spells.get_child(sp).white_spell()

	used_spells_this_floor.clear()

func learn_spell(slot: int, spell: Spell, remove_from_grid: bool = true) -> void:
	if remove_from_grid:
		grid.remove_spell_from_grid(spell)
	
	spell.visible = false
	
	$Spells.add_child(spell)
	player_spells[slot] = spell
	
	$UI/Stats/Spells.get_child(slot).add_spell(spell.spell_name(), spell.hover_text())

func update_spell(slot: int) -> void:
	var spell := player_spells[slot]
	$UI/Stats/Spells.get_child(slot).add_spell(spell.spell_name(), spell.hover_text())

func enemy_move(enemy: Entity, x: int, y: int) -> void:
	enemy_moving = true
	await enemy.move(x, y, grid)
	enemy_moving = false

func enemy_attack(enemy: Entity, x: int, y: int) -> void:
	enemy_moving = true
	var target := grid.get_player(enemy.grid_position + Vector2i(x, y))
	await enemy.bump_attack(x, y, grid, target, modulus)
	enemy_moving = false

func spawn_floor_enemies() -> void:
	# TODO: base this on some smarter scaling, in terms of what can appear where.
	for i in range(1, floor+2):
		grid.spawn_enemy(randi_range(1, 3))

func spawn_enemy_on_floor() -> void:
	# TODO: base this on some smarter scaling, in terms of what can appear where.
	grid.spawn_enemy(randi_range(1, 3))

func spawn_enemy_with_number(n: int, x: int, y: int) -> void:
	grid.spawn_enemy_at_pos(n % modulus, x, y)

func first_floor() -> void:
	grid.update_grid(modulus)
	grid.place_first_floor()
	spawn_floor_enemies()
	used_spells_this_floor.clear()
	
	var spell = SpellDatabase.get_random_spell()
	learn_spell(0, spell, false)

func next_floor(override: bool = false) -> void:
	# TODO (sam): play a little animation, suggest that we actually have changed floors.
	player_floor_moves[floor] = total_player_moves_this_floor
	
	if modulus == 0:
		return
	
	if override:
		floor = (floor + 1) % modulus
	
	total_player_moves_this_floor = player_floor_moves.get_or_add(floor, 0)
	total_floors_cleared_this_run += 1
	
	# some enemy cleanup.
	grid.remove_enemies()
	grid.place_next_floor()
	spawn_floor_enemies()
	
	if grid.player.moves == 0:
		pass_enemy_turn()
	
	refresh_all_spells()

func try_pass_player_turn() -> void:
	if grid.player.moves <= 0:
		total_player_turns_this_run += 1
		player_turn = false
	else:
		return
	
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
			
		current_enemy_path = grid.a_star(enemy_priority_order[current_enemy_moving].grid_position, grid.player.grid_position)
		while len(current_enemy_path) <= 1:
			current_enemy_moving += 1
			if current_enemy_moving >= len(enemy_priority_order):
				pass_enemy_turn()
				return
			current_enemy_path = grid.a_star(enemy_priority_order[current_enemy_moving].grid_position, grid.player.grid_position)

		
		
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
		
