extends SceneTree
# تشغيل: godot --headless --path . -s res://tests/run_tests.gd
func _scripts(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		_scripts(dir.path_join(sub), out)

func _init() -> void:
	var fails := 0
	# 1) ترجمة كل السكربتات (يلتقط أخطاء الصياغة والأنواع)
	var scripts: Array = []
	_scripts("res://scripts", scripts)
	for p in scripts:
		var sc = ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_IGNORE)
		if sc == null or not (sc is GDScript) or not (sc as GDScript).can_instantiate():
			print("FAIL script does not compile: ", p)
			fails += 1
	# 2) بيانات المراحل
	for i in range(1, 27):
		var f := FileAccess.open("res://data/levels/level_%02d.json" % i, FileAccess.READ)
		if not f:
			print("FAIL missing level ", i)
			fails += 1
			continue
		var j = JSON.parse_string(f.get_as_text())
		if not (j is Dictionary) or j.get("id") != i or (j.get("items", []) as Array).size() < 3 or (j.get("questions", []) as Array).is_empty():
			print("FAIL invalid level ", i)
			fails += 1
		elif i > 1 and not (j as Dictionary).has("puzzle"):
			print("FAIL no puzzle ", i)
			fails += 1
	# 3) ملفات القصة صالحة
	for sp in ["res://data/story_level1.json", "res://data/story_level5.json"]:
		var sf := FileAccess.open(sp, FileAccess.READ)
		if not sf or not (JSON.parse_string(sf.get_as_text()) is Dictionary):
			print("FAIL story file: ", sp)
			fails += 1
	# 4) المشاهد
	for s in ["splash", "login", "menu", "map", "level", "settings", "profile", "privacy", "account"]:
		if load("res://scenes/%s.tscn" % s) == null:
			print("FAIL scene ", s)
			fails += 1
	print("RESULT: ", "OK" if fails == 0 else "%d FAILURES" % fails)
	quit(1 if fails > 0 else 0)
