class_name Entity extends Node2D

var grid_position: Vector2i = Vector2.ZERO
var sprite: Sprite2D

var hp: int = 6
var moves: int = 1
var attack_power: int = 1

func _ready() -> void:
	if has_node("Sprite2D"):
		sprite = get_node("Sprite2D")

func _process(delta: float) -> void:
	pass

func animate_bump_in_direction(dir: Vector2i, mag: float = 2.0, t: float = 0.2) -> Signal:
	assert(sprite)
	var tween = create_tween()
	tween.tween_property(sprite, "offset", dir * mag, t / 2)
	tween.tween_property(sprite, "offset", Vector2.ZERO, t / 2)
	return tween.finished

func animate_move(pos: Vector2, t: float = 0.2) -> Signal:
	var tween = create_tween()
	tween.tween_property(self, "position", pos, t)
	return tween.finished

func move(dx: int, dy: int, grid: Grid, animate: bool = true) -> Signal:
	grid_position += Vector2i(dx, dy)
	var world_pos = grid.tile_pos_to_world_pos(grid_position)
	if sprite:
		world_pos += (sprite.get_rect().size / 2) * sprite.scale
	moves -= 1
	if animate:
		return animate_move(world_pos)
	else:
		return get_tree().create_timer(0.01).timeout

func bump_attack(dx: int, dy: int, grid: Grid, modulus: int, animate: bool = true) -> Signal:
	var offs = Vector2i(dx, dy)
	var entity_at_position: Entity = grid.get_entity(grid_position + offs)
	entity_at_position.take_damage(attack_power, modulus)
	moves -= 1
	if animate:
		return animate_bump_in_direction(offs, 2.0, 0.3)
	else:
		return get_tree().create_timer(0.01).timeout

func take_damage(dmg: int, modulus: int) -> void:
	hp = posmod(hp - dmg, modulus)

func place_immediate(x: int, y: int, grid: Grid) -> void:
	grid_position = Vector2i(x, y)
	var world_pos = grid.tile_pos_to_world_pos(grid_position)
	if sprite:
		world_pos += (sprite.get_rect().size / 2) * sprite.scale
	position = world_pos

func reset_moves() -> void:
	assert(false, "OVERRIDE reset_moves()")

func move_ok(dx: int, dy: int, grid: Grid, run: Run) -> bool:
	assert(false, "OVERRIDE move_ok()")
	return false

func attack_ok(dx: int, dy: int, grid: Grid, run: Run) -> bool:
	assert(false, "OVERRIDE attack_ok()")
	return false
