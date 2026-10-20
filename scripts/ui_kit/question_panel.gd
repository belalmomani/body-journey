class_name QuestionPanel
extends PanelContainer
# لوحة سؤال «هولوغرافية» قابلة لإعادة الاستخدام في كل المراحل.
signal answered(ok: bool, q: Dictionary)
signal next_pressed
const TINTS := [Color("#7fe3ff"), Color("#b69cff"), Color("#ffd27f"), Color("#8dffb0")]
var q := {}
var done := false
var buttons: Array = []
var score_label: Label
var feedback_box: VBoxContainer
var title_label: Label
var expl_label: Label
var is_last := false

func build(question: Dictionary, idx: int, total: int, score: int, level_id: int) -> void:
	q = question
	is_last = idx >= total - 1
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	add_theme_stylebox_override("panel", UI.holo_style())
	var decor := ThemeDecor.new()
	decor.mode = _decor_mode(level_id)
	add_child(decor)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 16)
	scroll.add_child(v)
	# الترويسة: (يسار) النقاط، (وسط) شريط التقدم، (يمين) رقم السؤال
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	score_label = UI.glow_label("النقاط: %d" % score, 26, Color("#ffe27a"))
	head.add_child(score_label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = float(total)
	bar.value = float(idx + 1)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 22)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(1, 1, 1, 0.15)
	sbg.set_corner_radius_all(11)
	var sfill := StyleBoxFlat.new()
	sfill.bg_color = Color("#7fe3ff")
	sfill.set_corner_radius_all(11)
	bar.add_theme_stylebox_override("background", sbg)
	bar.add_theme_stylebox_override("fill", sfill)
	head.add_child(bar)
	head.add_child(UI.glow_label("سؤال %d من %d" % [idx + 1, total], 26))
	v.add_child(head)
	v.add_child(UI.glow_label(str(q["q"]), 38))
	var opts: Array = [q["answer"]] + q["wrong"]
	opts.shuffle()
	for i in opts.size():
		var b := AnswerButton.new()
		b.setup(str(opts[i]), TINTS[i % TINTS.size()])
		b.chosen.connect(_on_chosen)
		v.add_child(b)
		buttons.append(b)
	feedback_box = VBoxContainer.new()
	feedback_box.visible = false
	feedback_box.add_theme_constant_override("separation", 12)
	title_label = UI.glow_label("", 32)
	expl_label = UI.glow_label("", 28, Color("#dff6ff"))
	feedback_box.add_child(title_label)
	feedback_box.add_child(expl_label)
	feedback_box.add_child(UI.button("إنهاء الاختبار" if is_last else "السؤال التالي", func(): next_pressed.emit(), Color("#2a9d8f")))
	v.add_child(feedback_box)

func set_score(n: int) -> void:
	score_label.text = "النقاط: %d" % n

func _on_chosen(btn: AnswerButton) -> void:
	if done:
		return
	done = true   # يمنع احتساب الإجابة أكثر من مرة
	var correct := str(q["answer"])
	var ok := btn.answer_text == correct
	for b in buttons:
		var ab: AnswerButton = b
		if ab == btn:
			ab.reveal("ok" if ok else "bad")
		elif ab.answer_text == correct:
			ab.reveal("ok")
		else:
			ab.reveal("dim")
	title_label.text = "أحسنت! اكتشفت المعلومة الصحيحة!" if ok else "محاولة جيدة! لنتعرف إلى الإجابة الصحيحة."
	title_label.add_theme_color_override("font_color", Color("#9dffb8") if ok else Color("#ffd59a"))
	var ex := str(q.get("explain", ""))
	if not ok:
		ex = "الإجابة الصحيحة: %s\n%s" % [correct, ex]
	expl_label.text = ex.strip_edges()
	feedback_box.visible = true
	answered.emit(ok, q)

func _decor_mode(id: int) -> String:
	if id == 5 or id == 6:
		return "blood"
	if id == 7:
		return "heart"
	if id == 9 or id == 10:
		return "nerve"
	if id == 3 or id == 18 or id == 21 or id == 22:
		return "shield"
	return "bubbles"
