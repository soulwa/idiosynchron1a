extends Node

func get_random_spell() -> Spell:
	var spells := get_children()
	spells.shuffle()
	return spells[0].duplicate()
