class_name Spell extends Entity

func spell_name() -> String:
	return "bad"

func hover_text() -> String:
	return "This is the base spell class!"

func use(run: Run, grid: Grid) -> void:
	return
