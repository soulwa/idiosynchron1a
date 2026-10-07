extends Node

var random_spells: Array = []

func _ready() -> void:
	random_spells = get_children()

func restrict_spells() -> void:
	#return
	random_spells = [
		preload("res://scenes/spells/spell_incadj.tscn").instantiate(),
		preload("res://scenes/spells/spell_decadj.tscn").instantiate(),
		preload("res://scenes/spells/spell_add_tile.tscn").instantiate(),
		preload("res://scenes/spells/spell_mul_tile.tscn").instantiate()
	]

func get_random_spell() -> Spell:
	var spells := random_spells.duplicate()
	spells.shuffle()
	var spell: Spell = spells[0].duplicate()
	spell.visible = true
	
	if spell.can_randomize_instance:
		spell.randomize_instance()
	return spell
