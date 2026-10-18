extends Control
# محرك مرحلة عام يُدار بالكامل من ملف JSON للمرحلة.
const SPEED := 460.0
var lv := {}
var phase := "intro"   # intro | play | quiz | result
var player: TextureRect
var ppos := Vector2(360, 1050)
var target := Vector2(360, 1050)
var items: Array = []     # {node, name, got}
var hazards: Array = []   # {node, vel}
var hearts := 3
var score := 0
var inv := 0.0
var t := 0.0
var hud: Label
var panel: VBoxContainer
var overlay: Control
var qi := 0
var qok := 0
var pmiss := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	set_anchors_preset(Control.PRESET_FULL_RECT)
	lv = GameState.levels.get(GameState.selected_level, {})
	rng.seed = GameState.selected_level * 7919
	var bg := TextureRect.new()
	bg.texture = load(lv.get("background", "res://assets/backgrounds/bg_default.svg"))
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(lv.get("color", "#ffffff")).lightened(0.4)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var tex_item = load("res://assets/characters/item.svg")
	for nm in lv.get("items", []):
		var n := Control.new()
		n.size = Vector2(110, 110)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tr := TextureRect.new()
		tr.texture = tex_item
		tr.size = Vector2(110, 110)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.add_child(tr)
		var l := UI.label(nm, 22)
		l.size = Vector2(170, 30)
		l.position = Vector2(-30, 112)
		n.add_child(l)
		n.position = _free_spot() - n.size / 2
		add_child(n)
		items.append({"node": n, "name": nm, "got": false})
	var tex_h = load("res://assets/characters/germ.svg")
	for i in int(lv.get("hazards", 2)):
		var h := TextureRect.new()
		h.texture = tex_h
		h.size = Vector2(100, 100)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.position = _free_spot() - h.size / 2
		add_child(h)
		var sp := 110.0 + 25.0 * int(lv.get("difficulty", 1))
		hazards.append({"node": h, "vel": Vector2.from_angle(rng.randf() * TAU) * sp})
	player = TextureRect.new()
	player.texture = load("res://assets/characters/player.svg")
	player.size = Vector2(120, 120)
	player.pivot_offset = player.size / 2
	player.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.position = ppos - player.size / 2
	add_child(player)
	hud = UI.label("", 30)
	hud.position = Vector2(20, 16)
	hud.size = Vector2(680, 90)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_update_hud()
	_show_intro()

func _free_spot() -> Vector2:
	for k in 40:
		var p := Vector2(rng.randf_range(100, 620), rng.randf_range(260, 880))
		var ok := true
		for it in items:
			if (it["node"].position + Vector2(55, 55)).distance_to(p) < 150: ok = false
		if ok: return p
	return Vector2(360, 600)

func _update_hud() -> void:
	var got := 0
	for it in items:
		if it["got"]: got += 1
	hud.text = "%s   |   الأرواح: %d   |   جمعت: %d/%d   |   النقاط: %d" % [lv.get("title", ""), hearts, got, items.size(), score]

# ---------- لوحات ----------
func _panel(title: String, body: String) -> VBoxContainer:
	for c in overlay.get_children(): c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]: m.add_theme_constant_override("margin_" + s, 40)
	for s in ["top", "bottom"]: m.add_theme_constant_override("margin_" + s, 220)
	overlay.add_child(m)
	var bgp := PanelContainer.new()
	m.add_child(bgp)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	bgp.add_child(v)
	v.add_child(UI.label(title, 44))
	if body != "": v.add_child(UI.label(body, 30))
	return v

func _close_panel() -> void:
	for c in overlay.get_children(): c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_intro() -> void:
	phase = "intro"
	var v := _panel(lv.get("title", ""), lv.get("dialogue", "") + "\n\n" + lv.get("intro", ""))
	GameState.speak(lv.get("intro", ""))
	v.add_child(UI.button("هيا نبدأ", func():
		_close_panel(); phase = "play"))
	v.add_child(UI.button("الخريطة", func(): GameState.go("res://scenes/map.tscn"), Color("#8d99ae")))

# ---------- اللعب ----------
func _input(e: InputEvent) -> void:
	if phase != "play": return
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		target = Vector2(clampf(e.position.x, 60, 660), clampf(e.position.y, 160, 1220))

func _process(delta: float) -> void:
	if phase != "play": return
	t += delta
	AdManager.add_play_time(delta)
	var d := target - ppos
	var moving := d.length() > 6.0
	if moving: ppos += d.normalized() * minf(SPEED * delta, d.length())
	player.position = ppos - player.size / 2
	player.scale = Vector2.ONE * (1.0 + (0.06 if moving else 0.03) * sin(t * (14.0 if moving else 4.0)))
	player.rotation = 0.12 * sin(t * 10.0) if moving else 0.0
	inv = maxf(0.0, inv - delta)
	player.modulate.a = 0.4 if (inv > 0.0 and int(t * 10) % 2 == 0) else 1.0
	for h in hazards:
		var n: Control = h["node"]
		n.position += h["vel"] * delta
		var vel: Vector2 = h["vel"]
		if n.position.x < 0 or n.position.x > 620:
			vel.x = -vel.x
			n.position.x = clampf(n.position.x, 0, 620)
		if n.position.y < 160 or n.position.y > 1100:
			vel.y = -vel.y
			n.position.y = clampf(n.position.y, 160, 1100)
		h["vel"] = vel
		n.rotation += delta
		if inv <= 0.0 and (n.position + n.size / 2).distance_to(ppos) < 85.0:
			hearts -= 1; inv = 1.5; GameState.sfx("hit"); target = ppos
			_update_hud()
			if hearts <= 0: _fail(); return
	var all := true
	for it in items:
		if not it["got"]:
			all = false
			if (it["node"].position + Vector2(55, 55)).distance_to(ppos) < 85.0:
				it["got"] = true; it["node"].visible = false
				score += 100; GameState.sfx("collect"); _update_hud()
	if all and not items.is_empty(): _after_collect()

func _fail() -> void:
	phase = "result"
	GameState.sfx("fail")
	GameState.record_attempt(GameState.selected_level)  # المحاولة تُسجَّل ولا يضيع أي تقدم سابق
	var v := _panel("حاول مرة أخرى!", "لا بأس، الجراثيم سريعة. تقدمك السابق محفوظ.")
	v.add_child(UI.button("إعادة المحاولة", func(): GameState.go("res://scenes/level.tscn")))
	v.add_child(UI.button("الخريطة", func(): GameState.go("res://scenes/map.tscn"), Color("#8d99ae")))

# ---------- الأسئلة ----------
func _start_quiz() -> void:
	phase = "quiz"
	qi = 0; qok = 0
	_ask()

func _ask() -> void:
	var qs: Array = lv.get("questions", [])
	if qi >= qs.size():
		_finish(); return
	var q: Dictionary = qs[qi]
	var v := _panel("سؤال %d من %d" % [qi + 1, qs.size()], q["q"])
	GameState.speak(q["q"])
	var opts: Array = [q["answer"]] + q["wrong"]
	opts.shuffle()
	for o in opts:
		v.add_child(UI.button(o, func(): _answer(o == q["answer"], q), Color("#6c63ff")))

func _answer(ok: bool, q: Dictionary) -> void:
	if ok: qok += 1; score += 200; GameState.sfx("collect")
	else: GameState.sfx("hit")
	var v := _panel("أحسنت!" if ok else "ليس تماماً", "" if ok else "الإجابة الصحيحة: " + q["answer"])
	v.add_child(UI.button("التالي", func(): qi += 1; _ask()))

func _finish() -> void:
	phase = "result"
	var total: int = lv.get("questions", []).size()
	var stars := 1 + (1 if hearts >= 2 else 0) + (1 if qok == total and pmiss <= 2 else 0)
	score += hearts * 50
	GameState.complete_level(GameState.selected_level, stars, score)
	GameState.sfx("win")
	player.scale = Vector2.ONE * 1.3
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
	if lv.has("puzzle"): _start_puzzle()
	else: _start_quiz()

func _start_puzzle() -> void:
	phase = "puzzle"
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
