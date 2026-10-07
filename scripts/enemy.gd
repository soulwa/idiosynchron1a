class_name Enemy extends Entity

var enemy_number: int = 0

var moves_to_reset = 0

var cant_move: bool = false

func _ready() -> void:
	super._ready()
	
	setup_properties_from_number(enemy_number)
	moves = moves_to_reset

func change_enemy_number(num: int) -> void:
	enemy_number = num
	setup_properties_from_number(enemy_number)

func setup_properties_from_number(number: int) -> void:
	hp = enemy_number
	attack_power = 1
	moves_to_reset = 1
	cant_move = false
	
	if enemy_number == 0:
		moves_to_reset = 0
	elif enemy_number == 1:
		pass
	elif enemy_number == 2:
		moves_to_reset = 2
	elif enemy_number == 3:
		attack_power = 3
	elif enemy_number == 4:
		moves_to_reset = 2
		attack_power = 2
	elif enemy_number == 5:
		cant_move = true
		attack_power = 5
	elif enemy_number == 6:
		moves_to_reset = 6
	elif enemy_number == 7:
		attack_power = 7
	else:
		moves_to_reset = enemy_number if (enemy_number % 2) == 0 else 1
		attack_power = 1 if (enemy_number % 2) == 0 else enemy_number
	
	if enemy_number < 10:
		$Sprite2D.show()
		$RichTextLabel.hide()
		var atlas = (sprite.texture) as AtlasTexture
		atlas.region.position.x = enemy_number * 7
	else:
		$Sprite2D.hide()
		$RichTextLabel.show()
		$RichTextLabel.text = str(enemy_number)

func move_ok(dx: int, dy: int, grid: Grid, run: Run) -> bool:
	var coords = grid_position + Vector2i(dx, dy)
	print(grid_position, " to ", coords)
	if grid.has_wall(coords):
		return false
	if grid.has_player(coords):
		return false
	if grid.has_enemy(coords):
		return false
	# don't allow inbounds TO outbounds movement, all else is fine.
	if grid.inbounds(grid_position) and not grid.inbounds(coords):
		return false
	return true

func animate_bump_in_direction(dir: Vector2i, mag: float = 2.0, t: float = 0.2) -> Signal:
	assert(sprite)
	var tween = create_tween()
	tween.tween_property(sprite, "offset", dir * mag, t / 2)
	tween.parallel().tween_property($RichTextLabel, "position", dir * mag, t / 2).as_relative()
	tween.tween_property(sprite, "offset", Vector2.ZERO, t / 2)
	tween.parallel().tween_property($RichTextLabel, "position", Vector2.ZERO, t / 2)
	return tween.finished

func attack_ok(dx: int, dy: int, grid: Grid, run: Run) -> bool:
	var coords = grid_position + Vector2i(dx, dy)
	if grid.has_player(coords):
		return true
	return true

func bump_attack(dx: int, dy: int, grid: Grid, ent: Entity, modulus: int, animate: bool = true) -> Signal:
	var sig := super.bump_attack(dx, dy, grid, ent, modulus, animate)
	return sig

func take_damage(dmg: int, modulus: int) -> void:
	super.take_damage(dmg, modulus)
	
	change_enemy_number(hp)
	setup_properties_from_number(enemy_number)
	(sprite.texture as AtlasTexture).region.position.x = enemy_number * 7
	
func reset_moves() -> void:
	moves = moves_to_reset

func _process(delta: float) -> void:
	pass
