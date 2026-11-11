extends SceneTree
# يلتقط لقطات حقيقية (يحتاج رسماً عبر Xvfb) ويحفظها في shots/ لرفعها كـ artifact.
var dir := ""

func _cap(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(dir + name + ".png")
		print("SHOT ", name, " ", img.get_size())

func _initialize() -> void:
	Engine.time_scale = 4.0
	dir = ProjectSettings.globalize_path("res://") + "shots/"
	DirAccess.make_dir_recursive_absolute(dir)
	await _shoot_level(1, false, "l1_2d")
	await _shoot_level(1, true, "l1_3d")
	await _shoot_preview()
	quit(0)

func _shoot_level(id: int, use3d: bool, tag: String) -> void:
	GameState.selected_level = id
	GameState.data["settings"]["use_3d"] = use3d
	GameState.data["story"] = {}
	var inst: Node = (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	var start := Time.get_ticks_msec()
	var got_dialogue := false
	var got_play := false
	var got_mid := false
	var got_quiz := false
	while float(Time.get_ticks_msec() - start) / 1000.0 < 90.0:
		await process_frame
		var phase := str(inst.get("phase"))
		var dlg = inst.get("dlg")
		if not got_dialogue and dlg != null and dlg.visible:
			got_dialogue = true
			for i in 20:
				await process_frame
			await _cap(tag + "_01_dialogue")
		if not got_play and phase == "play":
			got_play = true
			for i in 90:
				await process_frame
			await _cap(tag + "_02_play")
		if not got_mid and (inst.get("discovered") as Array).size() >= 3 and phase == "play":
			got_mid = true
			for i in 60:
				await process_frame
			await _cap(tag + "_03_midgame")
		if not got_quiz and phase == "quiz":
			got_quiz = true
			for i in 30:
				await process_frame
			await _cap(tag + "_04_quiz")
		if phase == "result":
			for i in 30:
				await process_frame
			await _cap(tag + "_05_end")
			break
		TestDriver.drive(inst)
	inst.queue_free()
	await process_frame

func _shoot_preview() -> void:
	var inst: Node = (load("res://scenes/hero3d_preview.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in 120:
		await process_frame
	await _cap("preview_idle")
	inst.hero.play("walk")
	for i in 40:
		await process_frame
	await _cap("preview_walk")
	inst.hero.play("joy")
	for i in 25:
		await process_frame
	await _cap("preview_joy")
	inst.queue_free()
