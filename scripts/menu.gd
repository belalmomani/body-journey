extends Control
func _ready() -> void:
	var v := UI.root(self)
	var g := TextureRect.new()
	g.texture = load("res://assets/characters/guide.svg")
	g.custom_minimum_size = Vector2(0, 220)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(g)
	v.add_child(UI.label("رحلة داخل الجسم", 56))
	var cur := int(GameState.data["current_level"])
	var started: bool = GameState.data["completed"].size() > 0
	v.add_child(UI.button(("استكمال الرحلة (مرحلة %d)" % cur) if started else "ابدأ اللعب", func():
		GameState.selected_level = cur
		GameState.go("res://scenes/level.tscn")))
	v.add_child(UI.button("خريطة الجسم والمراحل", func(): GameState.go("res://scenes/map.tscn"), Color("#2a9d8f")))
	v.add_child(UI.button("ملفي والإنجازات", func(): GameState.go("res://scenes/profile.tscn"), Color("#6c63ff")))
	v.add_child(UI.button("الإعدادات", func(): GameState.go("res://scenes/settings.tscn"), Color("#f4a261")))
	v.add_child(UI.label("النجوم: %d" % int(GameState.data["total_stars"]), 30))
