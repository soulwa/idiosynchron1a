class_name SpellIncrementSpellTarget extends Spell

func spell_name() -> String:
	return "sp+"

func hover_text() -> String:
	return "add 1 to target of spell @ tile prod"

func use(run: Run, grid: Grid) -> void:
	var pos := grid.player.grid_position
	var val := (pos.x * pos.y) % run.modulus
	if val in run.player_spells:
		run.player_spells[val].change_spell_target(1, run.modulus)
		run.update_spell(val)
