extends Control
func _ready() -> void:
	var v := UI.root(self)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var ic := TextureRect.new()
	ic.texture = load("res://assets/icon.svg")
	ic.custom_minimum_size = Vector2(256, 256)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(ic)
	v.add_child(UI.label("رحلة داخل الجسم", 64))
	v.add_child(UI.label("لعبة تعليمية لاستكشاف جسم الإنسان", 30))
	await get_tree().create_timer(1.5).timeout
	if Cloud.signed_in() or GameState.local_mode:
		GameState.go("res://scenes/menu.tscn")
	else:
		GameState.go("res://scenes/login.tscn")
