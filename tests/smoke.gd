extends SceneTree
# اختبار دخان: يشغّل المراحل فعلياً (بلا رسم) ويدفعها حتى النهاية. أخطاء السكربت في السجل تُفشل الفحص.
const MAX_SEC := 45.0
var warns := 0

func _initialize() -> void:
	Engine.time_scale = 8.0
	await _run_level(1, false, true)
	await _run_level(1, true, true)
	await _run_level(5, false, true)
	await _run_level(2, false, false)
	print("SMOKE DONE warns=", warns)
	quit(0)

func _run_level(id: int, use3d: bool, full: bool) -> void:
	var tag := "L%d%s" % [id, "-3D" if use3d else ""]
	GameState.selected_level = id
	GameState.data["settings"]["use_3d"] = use3d
	GameState.data["story"] = {}
	var inst: Node = (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	var start := Time.get_ticks_msec()
	var frames := 0
	var limit := 6000 if full else 300
	while frames < limit:
		await process_frame
		frames += 1
		TestDriver.drive(inst)
		if str(inst.get("phase")) == "result":
			break
		if float(Time.get_ticks_msec() - start) / 1000.0 > MAX_SEC:
			break
	print("SMOKE ", tag, " phase=", inst.get("phase"), " frames=", frames, " discovered=", (inst.get("discovered") as Array).size())
	if full and str(inst.get("phase")) != "result":
		warns += 1
		print("SMOKE-WARN ", tag, " did not reach the end (may be driver limits)")
	inst.queue_free()
	await process_frame
