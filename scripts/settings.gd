extends Control
func _ready() -> void:
	var v := UI.root(self)
	v.add_child(UI.label("الإعدادات", 48))
	v.add_child(UI.label("الموسيقى", 30))
	v.add_child(_slider("music"))
	v.add_child(UI.label("المؤثرات الصوتية", 30))
	v.add_child(_slider("sfx"))
	v.add_child(UI.button("الحساب وإدارة البيانات", func(): GameState.go("res://scenes/account.tscn"), Color("#2a9d8f")))
	v.add_child(UI.button("سياسة الخصوصية وشروط الاستخدام", func(): GameState.go("res://scenes/privacy.tscn"), Color("#6c63ff")))
	UI.back_button(v)

func _slider(key: String) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0; s.max_value = 1.0; s.step = 0.05
	s.custom_minimum_size = Vector2(0, 60)
	s.value = GameState.data["settings"].get(key, 1.0)
	s.value_changed.connect(func(val):
		GameState.data["settings"][key] = val
		GameState.apply_audio())
	s.drag_ended.connect(func(_c):
		GameState.save_local()
		Cloud.push_async())
	return s
