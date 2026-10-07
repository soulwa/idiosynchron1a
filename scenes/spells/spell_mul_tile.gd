class_name SpellMultiplyTile extends Spell

func spell_name() -> String:
	return "*t+"

func hover_text() -> String:
	return "multiply enemies by tile sum value"

func randomize_instance() -> void:
	return

func use(run: Run, grid: Grid) -> void:
	var pos := grid.player.grid_position
	var val := (pos.x + pos.y) % run.modulus
	for enemy: Enemy in grid.enemies:
		enemy.change_enemy_number((enemy.enemy_number * val) % run.modulus)
