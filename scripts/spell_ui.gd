class_name SpellUI extends Control

var spell_help_ui: SpellHelp

@export var number: int = 0
var spell_name: String = "NONE"
var spell_hint: String = "NONE"
var active: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	spell_help_ui = get_parent().get_parent().get_parent().get_node("SpellHelp")
	
	$SpellNum.text = str(number)
	$SpellName.text = "[color=#7a7a7a]???[/color]"

func add_spell(nom: String, hint: String) -> void:
	spell_name = nom
	spell_hint = hint
	active = true
	
	$SpellName.clear()
	$SpellName.text = ""
	
	$SpellName.push_color(Color.WHITE)
	$SpellName.add_text(spell_name)
	$SpellName.pop()

func _on_mouse_entered() -> void:
	if active:
		spell_help_ui.request_spell_view(self, spell_name, spell_hint)

func _on_mouse_exited() -> void:
	if active:
		spell_help_ui.revoke_spell_view(self)
