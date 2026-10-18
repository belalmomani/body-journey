extends SceneTree
# تشغيل: godot --headless -s tests/run_tests.gd
func _init() -> void:
	var fails := 0
	for i in range(1, 27):
		var f := FileAccess.open("res://data/levels/level_%02d.json" % i, FileAccess.READ)
		if not f: print("FAIL missing level ", i); fails += 1; continue
		var j = JSON.parse_string(f.get_as_text())
		if not (j is Dictionary) or j.get("id") != i or (j.get("items", []) as Array).size() < 3 or (j.get("questions", []) as Array).is_empty():
			print("FAIL invalid level ", i); fails += 1
	for i in range(2, 27):
		var g := FileAccess.open("res://data/levels/level_%02d.json" % i, FileAccess.READ)
		if not (JSON.parse_string(g.get_as_text()) as Dictionary).has("puzzle"): print("FAIL no puzzle ", i); fails += 1
	for s in ["splash","login","menu","map","level","settings","profile","privacy","account"]:
		if load("res://scenes/%s.tscn" % s) == null: print("FAIL scene ", s); fails += 1
	print("RESULT: ", "OK" if fails == 0 else "%d FAILURES" % fails)
	quit(1 if fails > 0 else 0)
