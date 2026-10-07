class_name SpellScoreAdjacent extends Spell

func spell_name() -> String:
	return "sco"

func hover_text() -> String:
	return "score adjacent enemies"

func randomize_instance() -> void:
	return

func use(run: Run, grid: Grid) -> void:
	var pos := grid.player.grid_position
	var adjs := grid.tile_neighbors_ortho(pos)
	for adj in adjs:
		if grid.has_enemy_including_zero(adj):
			var enemy := grid.get_entity(adj)
			run.score += enemy.enemy_number
	run.score %= run.modulus
