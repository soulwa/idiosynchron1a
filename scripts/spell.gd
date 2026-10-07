class_name Spell extends Entity

var can_randomize_instance: bool = false

func change_spell_target(offset: int, modulus: int) -> void:
	return

func spell_name() -> String:
	return "bad"

func hover_text() -> String:
	return "This is the base spell class!"

func randomize_instance() -> void:
	return

func use(run: Run, grid: Grid) -> void:
	return
