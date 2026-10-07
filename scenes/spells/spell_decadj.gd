class_name SpellDecrementAdjacent extends Spell

func spell_name() -> String:
	return "dec"

func hover_text() -> String:
	return "decrement adjacent enemies"

func randomize_instance() -> void:
	return

func use(run: Run, grid: Grid) -> void:
	var pos := grid.player.grid_position
	var adjs := grid.tile_neighbors_ortho(pos)
	for adj in adjs:
		if grid.has_enemy_including_zero(adj):
			var enemy := grid.get_entity(adj)
			enemy.change_enemy_number(posmod(enemy.enemy_number - 1, run.modulus))
