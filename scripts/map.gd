extends Control
func _ready() -> void:
	var v := UI.root(self)
	v.add_child(UI.label("خريطة الجسم", 48))
	var s := UI.scroll(v)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(grid)
	for i in range(1, GameState.LEVEL_COUNT + 1):
		var lv: Dictionary = GameState.levels.get(i, {})
		var st := GameState.stars_of(i)
		var b := UI.button("%d. %s\n%s" % [i, lv.get("title", "؟"), "★".repeat(st) + "☆".repeat(3 - st)],
			func():
				GameState.selected_level = i
				GameState.go("res://scenes/level.tscn"), Color(lv.get("color", "#ff7a59")).darkened(0.35))
		b.custom_minimum_size = Vector2(0, 130)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 28)
		b.disabled = not GameState.is_unlocked(i)
		grid.add_child(b)
	UI.back_button(v)
