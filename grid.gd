class_name Grid extends Node2D

# TODO: maybe these can just be colors?
@export var zero_texture: Texture2D
@export var odd_texture: Texture2D
@export var even_texture: Texture2D

var gridsize: int = 0

func _ready() -> void:
	update_grid(7)
	
func update_grid(modulus: int) -> void:
	# col of numbers
	for i in range(0, modulus):
		var num: RichTextLabel = preload("res://grid_number.tscn").instantiate()
		num.text = str(i)
		
		$GridNumbers.add_child(num)
		num.position = $TopLeftColNums.position + Vector2.DOWN * 7 * i
	
	# row of numbers
	for i in range(0, modulus):
		var num: RichTextLabel = preload("res://grid_number.tscn").instantiate()
		num.text = str(i)
		
		$GridNumbers.add_child(num)
		num.position = $TopLeftRowNums.position + Vector2.RIGHT * 7 * i
	
	# tiles themselves
	# TODO: special case for mod 0
	for row in range(0, modulus):
		for col in range(0, modulus):
			var underlying_value = (row * col) % modulus
			var sprite = Sprite2D.new()
			sprite.centered = false
			if row == 0 or col == 0:
				sprite.texture = zero_texture
			elif row % 2 == col % 2:
				sprite.texture = even_texture
			else:
				sprite.texture = odd_texture
			$Tiles.add_child(sprite)
			sprite.position = $TopLeftTiles.position + Vector2.RIGHT * 7 * row + Vector2.DOWN * 7 * col
	
	gridsize = 7
