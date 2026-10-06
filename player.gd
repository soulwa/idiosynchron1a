class_name Player extends Entity

func _ready() -> void:
	super._ready()
	grid_position = Vector2.ONE

func _process(delta: float) -> void:
	super._process(delta)

func reset_moves() -> void:
	moves = 1

func move_ok(dx: int, dy: int, grid: Grid, run: Run) -> bool:
	var coords = grid_position + Vector2i(dx, dy)
	print(grid_position, " to ", coords)
	if grid.has_wall(coords):
		return false
	if grid.has_enemy(coords):
		return false
	# don't allow inbounds TO outbounds movement, all else is fine.
	if grid.inbounds(grid_position) and not grid.inbounds(coords):
		return false
	return true

func attack_ok(dx: int, dy: int, grid: Grid, run: Run) -> bool:
	var coords = grid_position + Vector2i(dx, dy)
	if grid.has_enemy(coords):
		return true
	return false
