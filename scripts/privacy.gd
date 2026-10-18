extends Control
func _ready() -> void:
	var v := UI.root(self)
	v.add_child(UI.label("سياسة الخصوصية وشروط الاستخدام", 38))
	var s := UI.scroll(v)
	var f := FileAccess.open("res://data/privacy_ar.txt", FileAccess.READ)
	var l := UI.label(f.get_as_text() if f else "تعذّر تحميل النص.", 26)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(l)
	UI.back_button(v, "res://scenes/settings.tscn")
