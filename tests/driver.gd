class_name TestDriver
extends RefCounted
# سائق آلي يدفع مراحل القصة للأمام في CI: يُكمل الحوار، ينقل اللاعب إلى أهداف المهمة، يتخطى الأسئلة.
static func drive(inst: Node) -> void:
	var dlg = inst.get("dlg")
	if dlg != null and dlg.visible:
		dlg._next()
		return
	var phase := str(inst.get("phase"))
	if phase == "play":
		var targets: Array = inst.get("mission_targets")
		for it in inst.get("items"):
			if bool(it["got"]) or not bool(it.get("active", true)):
				continue
			if targets.is_empty() or targets.has(it["name"]):
				inst.set("ppos", (it["node"] as Node2D).position)
				break
		inst.set("hearts", 3)
	elif phase == "quiz":
		var qp = inst.get("qpanel")
		if qp != null and is_instance_valid(qp):
			if qp.allow_skip:
				qp.skip_pressed.emit()
			elif qp.done:
				qp.next_pressed.emit()
			elif qp.buttons.size() > 0:
				qp._on_chosen(qp.buttons[0])
