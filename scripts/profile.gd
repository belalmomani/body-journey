extends Control
func _ready() -> void:
	var v := UI.root(self)
	v.add_child(UI.label("ملف اللاعب", 48))
	var d: Dictionary = GameState.data
	v.add_child(UI.label("الاسم: %s" % (d["name"] if d["name"] != "" else "لاعب"), 32))
	v.add_child(UI.label("النجوم: %d  |  النقاط: %d  |  المراحل المنجزة: %d/26" % [d["total_stars"], d["total_score"], d["completed"].size()], 28))
	v.add_child(UI.label("الإنجازات", 40))
	var s := UI.scroll(v)
	for a in GameState.achievements():
		s.add_child(UI.label("%s %s — %s" % ["✔" if a["done"] else "✘", a["title"], a["desc"]], 28, Color("#2a9d8f") if a["done"] else Color("#8d99ae")))
	UI.back_button(v)
