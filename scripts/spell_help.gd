class_name SpellHelp extends Control

var latest_requester: Node = null

func request_spell_view(requester: Node, spell_name: String, spell_hint: String) -> void:
	latest_requester = requester
	show()
	$SpellName.text = spell_name
	$SpellHint.text = spell_hint
	return

func revoke_spell_view(requester: Node) -> void:
	if requester == latest_requester:
		latest_requester = null
		hide()
