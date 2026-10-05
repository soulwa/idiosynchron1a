class_name ColorNumericText extends RichTextLabel

enum TypeOfText {
	Number,
	GameObject
}
@export var type_of_text: TypeOfText

func update_text(new_text: String) -> void:
	# TODO: add color to text based on what type it is, here.
	text = new_text
	
