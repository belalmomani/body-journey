extends Control
# محرك مرحلة عام. عالم اللعب من Node2D/Sprite2D (لا يتأثر باتجاه الواجهة RTL)، والواجهة في CanvasLayer.
const SPEED := 460.0
const BUILD := "v7"
const ITEM_TEX := {
	"النواة": "res://assets/cell/nucleus.png",
	"الميتوكوندريا": "res://assets/cell/mito.png",
	"الريبوسوم": "res://assets/cell/ribo.png",
	"الغشاء": "res://assets/cell/membrane.png",
	"الشبكة الإندوبلازمية": "res://assets/cell/er.png",
	"جهاز جولجي": "res://assets/cell/golgi.png",
}
var lv := {}
var phase := "intro"   # intro | play | quiz | puzzle | result
var world: Node2D
var player: Sprite2D
var idle_tex: Texture2D
var run_frames: Array = []
var act_tex: Texture2D
var act_t := 0.0
var toast: Control
var qpanel: QuestionPanel
var ppos := Vector2(360, 1000)
var target := Vector2(360, 1000)
var items: Array = []
var hazards: Array = []
var hearts := 3
var score := 0
var inv := 0.0
var t := 0.0
var run_t := 0.0
var hud: Label
var overlay: Control
var ui_layer: CanvasLayer
var qi := 0
var qok := 0
var pmiss := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	set_anchors_preset(Control.PRESET_FULL_RECT)
	lv = GameState.levels.get(GameState.selected_level, {})
	var src := "json"
	if lv.is_empty():
		lv = _fallback()
		src = "fallback"
	rng.seed = GameState.selected_level * 7919
	var bg := TextureRect.new()
	bg.texture = load("res://assets/backgrounds/bg_cell_deep.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color.WHITE if GameState.selected_level == 1 else Color(lv.get("color", "#ffffff")).lerp(Color.WHITE, 0.6)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	world = Node2D.new()
	add_child(world)
	var tex_item: Texture2D = load("res://assets/characters/item.svg")
	for nm in lv.get("items", []):
		var n := Node2D.new()
		n.position = _free_spot()
		var halo := Sprite2D.new()
		halo.texture = tex_item
		halo.scale = Vector2.ONE * (180.0 / 128.0)
		halo.modulate = Color(1, 0.9, 0.2, 0.5)
		n.add_child(halo)
		var body := Sprite2D.new()
		var bt: Texture2D = tex_item
		var bs := 110.0
		if ITEM_TEX.has(nm):
			bt = load(ITEM_TEX[nm])
			bs = 140.0
		body.texture = bt
		body.scale = Vector2.ONE * (bs / maxf(bt.get_width(), bt.get_height()))
		n.add_child(body)
		var l := UI.label(nm, 24)
		l.size = Vector2(200, 32)
		l.position = Vector2(-100, bs * 0.5 + 8.0)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_outline_color", Color("#3b1a5a"))
		l.add_theme_constant_override("outline_size", 8)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.add_child(l)
		world.add_child(n)
		items.append({"node": n, "name": nm, "got": false, "halo": halo, "base": n.position})
	var germ_tex: Array = [load("res://assets/enemies/virus.png"), load("res://assets/enemies/bact.png")]
	for i in int(lv.get("hazards", 2)):
		var h := Sprite2D.new()
		var gt: Texture2D = germ_tex[i % 2]
		h.texture = gt
		h.set_meta("s", 120.0 / maxf(gt.get_width(), gt.get_height()))
		h.scale = Vector2.ONE * float(h.get_meta("s"))
		h.position = _free_spot()
		world.add_child(h)
		var sp := 110.0 + 25.0 * int(lv.get("difficulty", 1))
		hazards.append({"node": h, "vel": Vector2.from_angle(rng.randf() * TAU) * sp})
	idle_tex = load("res://assets/characters/hero/hero_idle.png")
	act_tex = load("res://assets/characters/hero/hero_interact.png")
	run_frames = [load("res://assets/characters/hero/hero_run.png"), load("res://assets/characters/hero/hero_walk.png")]
	player = Sprite2D.new()
	_set_player_tex(idle_tex)
	player.position = ppos
	world.add_child(player)
	# --- واجهة ---
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	var bar := ColorRect.new()
	bar.color = Color(1, 1, 1, 0.8)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 100.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(bar)
	hud = UI.label("", 28)
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_top = 14.0
	hud.offset_bottom = 94.0
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hud)
	var dbg := Label.new()
	dbg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	dbg.text = "build %s | items:%d | src:%s" % [BUILD, items.size(), src]
	dbg.anchor_top = 1.0
	dbg.anchor_bottom = 1.0
	dbg.offset_left = 10.0
	dbg.offset_right = 600.0
	dbg.offset_top = -40.0
	dbg.offset_bottom = -6.0
	dbg.add_theme_font_size_override("font_size", 22)
	dbg.add_theme_color_override("font_color", Color("#c0392b"))
	dbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(dbg)
	overlay = Control.new()
	overlay.layout_direction = Control.LAYOUT_DIRECTION_RTL
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(overlay)
	_update_hud()
	_show_intro()

func _free_spot() -> Vector2:
	for k in 40:
		var p := Vector2(rng.randf_range(110, 610), rng.randf_range(260, 900))
		var ok := true
		for it in items:
			if (it["node"] as Node2D).position.distance_to(p) < 140.0:
				ok = false
		if ok:
			return p
	return Vector2(360, 600)

func _update_hud() -> void:
	var got := 0
	for it in items:
		if it["got"]:
			got += 1
	hud.text = "%s  |  الأرواح: %d  |  جمعت: %d/%d  |  النقاط: %d" % [lv.get("title", ""), hearts, got, items.size(), score]

# ---------- لوحات ----------
func _panel(title: String, body: String) -> VBoxContainer:
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 40)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 160)
	overlay.add_child(m)
	var bgp := PanelContainer.new()
	bgp.add_theme_stylebox_override("panel", UI.holo_style())
	m.add_child(bgp)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	bgp.add_child(v)
	v.add_child(UI.glow_label(title, 44))
	if body != "":
		v.add_child(UI.glow_label(body, 30))
	return v

func _close_panel() -> void:
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_intro() -> void:
	phase = "intro"
	var v := _panel(lv.get("title", ""), lv.get("dialogue", "") + "\n\n" + lv.get("intro", ""))
	var g := TextureRect.new()
	g.texture = load("res://assets/characters/hero/hero_idle.png")
	g.custom_minimum_size = Vector2(0, 220)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(g)
	v.move_child(g, 0)
	GameState.speak(lv.get("intro", ""))
	v.add_child(UI.button("هيا نبدأ", func():
		_close_panel()
		phase = "play"))
	v.add_child(UI.button("الخريطة", func(): GameState.go("res://scenes/map.tscn"), Color("#8d99ae")))

# ---------- اللعب ----------
func _input(e: InputEvent) -> void:
	if phase != "play":
		return
	var pos := Vector2.ZERO
	var hit := false
	if e is InputEventMouseButton:
		var mb: InputEventMouseButton = e
		hit = mb.pressed
		pos = mb.position
	elif e is InputEventMouseMotion:
		var mm: InputEventMouseMotion = e
		hit = (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		pos = mm.position
	if hit:
		var vp := get_viewport_rect().size
		target = Vector2(clampf(pos.x, 40.0, vp.x - 40.0), clampf(pos.y, 150.0, vp.y - 40.0))

func _process(delta: float) -> void:
	t += delta
	if phase != "play":
		return
	AdManager.add_play_time(delta)
	act_t = maxf(0.0, act_t - delta)
	var d := target - ppos
	var moving := d.length() > 8.0
	var bob := 2.0 * sin(t * 3.0)
	if moving:
		ppos += d.normalized() * minf(SPEED * delta, d.length())
		run_t += delta
		_set_player_tex(act_tex if act_t > 0.0 else run_frames[int(run_t * 9.0) % 2])
		if absf(d.x) > 6.0:
			player.flip_h = d.x < 0.0
		player.rotation = 0.07 * (-1.0 if player.flip_h else 1.0)
		bob = -4.0 * absf(sin(run_t * 20.0))
	else:
		_set_player_tex(act_tex if act_t > 0.0 else idle_tex)
		player.rotation = 0.0
	player.position = ppos + Vector2(0.0, bob)
	inv = maxf(0.0, inv - delta)
	player.modulate.a = 0.4 if (inv > 0.0 and int(t * 10) % 2 == 0) else 1.0
	var vp := get_viewport_rect().size
	for h in hazards:
		var n: Sprite2D = h["node"]
		var vel: Vector2 = h["vel"]
		n.position += vel * delta
		if n.position.x < 50.0 or n.position.x > vp.x - 50.0:
			vel.x = -vel.x
			n.position.x = clampf(n.position.x, 50.0, vp.x - 50.0)
		if n.position.y < 160.0 or n.position.y > vp.y - 60.0:
			vel.y = -vel.y
			n.position.y = clampf(n.position.y, 160.0, vp.y - 60.0)
		h["vel"] = vel
		n.rotation = 0.15 * sin(t * 3.0 + n.position.x)
		n.scale = Vector2.ONE * float(n.get_meta("s")) * (1.0 + 0.06 * sin(t * 6.0 + n.position.x))
		if inv <= 0.0 and n.position.distance_to(ppos) < 70.0:
			hearts -= 1
			inv = 1.5
			GameState.sfx("hit")
			target = ppos
			_update_hud()
			if hearts <= 0:
				_fail()
				return
	var all := true
	for it in items:
		if not it["got"]:
			all = false
			var nn: Node2D = it["node"]
			nn.position.y = float(it["base"].y) + 7.0 * sin(t * 3.0 + float(it["base"].x))
			var hl: Sprite2D = it["halo"]
			hl.modulate.a = 0.35 + 0.25 * sin(t * 5.0)
			hl.scale = Vector2.ONE * (180.0 / 128.0) * (1.0 + 0.08 * sin(t * 5.0))
			if nn.position.distance_to(ppos) < 100.0:
				it["got"] = true
				_pop(nn)
				score += 100
				GameState.sfx("collect")
				act_t = 0.6
				_toast_fact(it["name"])
				_update_hud()
	if all and not items.is_empty():
		_after_collect()

func _pop(n: Node2D) -> void:
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector2(1.9, 1.9), 0.25)
	tw.parallel().tween_property(n, "modulate:a", 0.0, 0.25)

func _fail() -> void:
	phase = "result"
	GameState.sfx("fail")
	GameState.record_attempt(GameState.selected_level)
	var v := _panel("حاول مرة أخرى!", "لا بأس، الجراثيم سريعة. تقدمك السابق محفوظ.")
	v.add_child(UI.button("إعادة المحاولة", func(): GameState.go("res://scenes/level.tscn")))
	v.add_child(UI.button("الخريطة", func(): GameState.go("res://scenes/map.tscn"), Color("#8d99ae")))

# ---------- الأسئلة ----------
func _start_quiz() -> void:
	phase = "quiz"
	qi = 0
	qok = 0
	for h in hazards:
		(h["node"] as Node2D).visible = false
	var vp := get_viewport_rect().size
	ppos = Vector2(vp.x * 0.5, vp.y * 0.36 - 150.0)   # الشخصية تبقى ظاهرة فوق لوحة السؤال
	player.position = ppos
	player.flip_h = false
	player.rotation = 0.0
	_set_player_tex(idle_tex)
	_ask()

func _ask() -> void:
	var qs: Array = lv.get("questions", [])
	if qi >= qs.size():
		_finish()
		return
	var q: Dictionary = qs[qi]
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	player.rotation = 0.0
	_set_player_tex(idle_tex)
	qpanel = QuestionPanel.new()
	qpanel.set_anchors_preset(Control.PRESET_FULL_RECT)
	qpanel.anchor_top = 0.36
	qpanel.offset_left = 24.0
	qpanel.offset_right = -24.0
	qpanel.offset_top = 0.0
	qpanel.offset_bottom = -30.0
	overlay.add_child(qpanel)
	qpanel.build(q, qi, qs.size(), score, GameState.selected_level)
	qpanel.answered.connect(_on_answered)
	qpanel.next_pressed.connect(func():
		qi += 1
		_ask())
	GameState.speak(str(q["q"]))

func _on_answered(ok: bool, _q: Dictionary) -> void:
	if ok:
		qok += 1
		score += 200
		GameState.sfx("collect")
	else:
		GameState.sfx("hit")
	_update_hud()
	qpanel.set_score(score)
	_hero_react(ok)

func _hero_react(ok: bool) -> void:
	_set_player_tex(act_tex if ok else idle_tex)
	var tw := create_tween()
	if ok:
		tw.tween_property(player, "position:y", ppos.y - 40.0, 0.18)
		tw.tween_property(player, "position:y", ppos.y, 0.18)
	else:
		tw.tween_property(player, "rotation", 0.12, 0.12)
		tw.tween_property(player, "rotation", -0.12, 0.12)
		tw.tween_property(player, "rotation", 0.0, 0.12)

func _finish() -> void:
	phase = "result"
	var total: int = lv.get("questions", []).size()
	var stars := 1 + (1 if hearts >= 2 else 0) + (1 if qok == total and pmiss <= 2 else 0)
	score += hearts * 50
	GameState.complete_level(GameState.selected_level, stars, score)
	GameState.sfx("win")
	var v := _panel("نجحت!", "النجوم: %d من 3\nالنقاط: %d" % [stars, score])
	var id := GameState.selected_level
	if id < GameState.LEVEL_COUNT:
		v.add_child(UI.button("المرحلة التالية", func():
			GameState.selected_level = id + 1
			AdManager.maybe_show(func(): GameState.go("res://scenes/level.tscn"))))
	v.add_child(UI.button("إعادة المرحلة", func(): GameState.go("res://scenes/level.tscn"), Color("#2a9d8f")))
	v.add_child(UI.button("الخريطة", func(): AdManager.maybe_show(func(): GameState.go("res://scenes/map.tscn")), Color("#8d99ae")))

# ---------- الألغاز ----------
func _after_collect() -> void:
	if lv.has("puzzle"):
		_start_puzzle()
	else:
		_start_quiz()

func _start_puzzle() -> void:
	phase = "puzzle"
	for h in hazards:
		(h["node"] as Node2D).visible = false
	var p: Dictionary = lv["puzzle"]
	match p["type"]:
		"order": _puz_order(p)
		"match": _puz_match(p)
		"sort": _puz_sort(p)
		_: _start_quiz()

func _puzzle_done() -> void:
	score += 150
	GameState.sfx("win")
	var v := _panel("أحسنت، حللت اللغز!", "")
	v.add_child(UI.button("التالي", _start_quiz))

func _wrong() -> void:
	pmiss += 1
	GameState.sfx("hit")

func _puz_order(p: Dictionary) -> void:
	var v := _panel(p["title"], "المس الخطوات بالترتيب الصحيح")
	var steps: Array = p["steps"]
	var idx := [0]
	var shuffled := steps.duplicate()
	shuffled.shuffle()
	for s in shuffled:
		var b := UI.button(s, func(): pass, Color("#6c63ff"))
		b.pressed.connect(func():
			if s == steps[idx[0]]:
				idx[0] += 1
				b.disabled = true
				b.text = "%d) %s" % [idx[0], s]
				GameState.sfx("collect")
				if idx[0] >= steps.size():
					_puzzle_done()
			else:
				_wrong())
		v.add_child(b)

func _puz_match(p: Dictionary) -> void:
	var v := _panel(p["title"], "المس عنصراً ثم ما يناسبه")
	var pairs: Array = p["pairs"]
	var lefts: Array = pairs.map(func(x): return x[0])
	var rights: Array = pairs.map(func(x): return x[1])
	lefts.shuffle()
	rights.shuffle()
	var sel := {"l": ""}
	var left_btns := {}
	var done := [0]
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	var lc := VBoxContainer.new()
	var rc := VBoxContainer.new()
	for c in [lc, rc]:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.add_theme_constant_override("separation", 12)
		cols.add_child(c)
	v.add_child(cols)
	for l in lefts:
		var lb := UI.button(l, func(): pass, Color("#2a9d8f"))
		lb.add_theme_font_size_override("font_size", 28)
		lb.pressed.connect(func(): sel["l"] = l)
		left_btns[l] = lb
		lc.add_child(lb)
	for r in rights:
		var rb := UI.button(r, func(): pass, Color("#f4a261"))
		rb.add_theme_font_size_override("font_size", 24)
		rb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rb.pressed.connect(func():
			if sel["l"] == "":
				return
			var ok := false
			for pr in pairs:
				if pr[0] == sel["l"] and pr[1] == r:
					ok = true
			if ok:
				(left_btns[sel["l"]] as Button).disabled = true
				rb.disabled = true
				sel["l"] = ""
				done[0] += 1
				GameState.sfx("collect")
				if done[0] >= pairs.size():
					_puzzle_done()
			else:
				_wrong())
		rc.add_child(rb)

func _puz_sort(p: Dictionary) -> void:
	var its: Array = p["items"].duplicate()
	its.shuffle()
	_sort_next(p, its, [0])

func _sort_next(p: Dictionary, its: Array, i: Array) -> void:
	if i[0] >= its.size():
		_puzzle_done()
		return
	var it: Array = its[i[0]]
	var v := _panel(p["title"], "(%d/%d)  %s" % [i[0] + 1, its.size(), it[0]])
	for k in p["bins"].size():
		var cb := func():
			if k == int(it[1]):
				i[0] += 1
				GameState.sfx("collect")
				_sort_next(p, its, i)
			else:
				_wrong()
		v.add_child(UI.button(p["bins"][k], cb, Color("#6c63ff")))

func _fallback() -> Dictionary:
	return {"id": GameState.selected_level, "title": "الخلية", "color": "#7fd6c2",
		"background": "res://assets/backgrounds/bg_default.svg",
		"intro": "اجمع العناصر المضيئة، وابتعد عن الجراثيم، ثم أجب عن السؤال.",
		"dialogue": "أهلاً! أنا رائد، مستكشف الجسم.",
		"items": ["النواة", "الميتوكوندريا", "الريبوسوم", "الغشاء"], "hazards": 2, "difficulty": 1,
		"questions": [{"q": "أي جزء هو مركز التحكم في الخلية؟", "answer": "النواة", "wrong": ["الغشاء", "الماء"]}]}

func _set_player_tex(tex: Texture2D) -> void:
	player.texture = tex
	var k := 230.0 / idle_tex.get_height()
	player.scale = Vector2.ONE * k
	player.offset = Vector2(0.0, (idle_tex.get_height() - tex.get_height()) / 2.0)

func _toast_fact(nm: String) -> void:
	var f: Dictionary = lv.get("facts", {})
	if not f.has(nm):
		return
	_toast(str(f[nm]))
	GameState.speak(str(f[nm]))

func _toast(text: String) -> void:
	if toast and is_instance_valid(toast):
		toast.queue_free()
	var pc := PanelContainer.new()
	pc.layout_direction = Control.LAYOUT_DIRECTION_RTL
	pc.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pc.offset_top = -240.0
	pc.offset_bottom = -70.0
	pc.offset_left = 30.0
	pc.offset_right = -30.0
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.05, 0.25, 0.88)
	sb.set_corner_radius_all(24)
	sb.set_content_margin_all(16)
	pc.add_theme_stylebox_override("panel", sb)
	var l := UI.label(text, 28, Color.WHITE)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(l)
	ui_layer.add_child(pc)
	toast = pc
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(pc.queue_free)
