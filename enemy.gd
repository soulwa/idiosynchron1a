class_name Enemy extends Entity

var enemy_number: int = 0

func _ready() -> void:
	super._ready()
	
	moves = enemy_number
	hp = enemy_number
	var atlas = (sprite.texture) as AtlasTexture
	atlas.region.position.x = enemy_number * 7

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

func attack_ok(dx: int, dy: int, grid: Grid, run: Run) -> bool:
	var coords = grid_position + Vector2i(dx, dy)
	if grid.has_player(coords):
		return true
	return true

func take_damage(dmg: int, modulus: int) -> void:
	super.take_damage(dmg, modulus)
	enemy_number = hp
	(sprite.texture as AtlasTexture).region.position.x = enemy_number * 7
	
func reset_moves() -> void:
	moves = enemy_number

func _process(delta: float) -> void:
	pass
