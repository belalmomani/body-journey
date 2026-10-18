extends Control
var email: LineEdit
var pw: LineEdit
var nm: LineEdit
var consent: CheckBox
var status: Label
func _ready() -> void:
	var v := UI.root(self)
	v.add_child(UI.label("مرحباً!", 56))
	status = UI.label("", 28, Color("#c0392b"))
	nm = UI.input("اسم اللاعب (اختياري، لا تكتب اسمك الحقيقي)")
	email = UI.input("البريد الإلكتروني (لولي الأمر)")
	pw = UI.input("كلمة المرور", true)
	v.add_child(nm); v.add_child(email); v.add_child(pw)
	consent = CheckBox.new()
	consent.text = "أنا ولي الأمر وأوافق على سياسة الخصوصية"
	consent.add_theme_font_size_override("font_size", 28)
	v.add_child(consent)
	v.add_child(status)
	v.add_child(UI.button("تسجيل الدخول", _login))
	v.add_child(UI.button("إنشاء حساب", _register, Color("#2a9d8f")))
	v.add_child(UI.button("نسيت كلمة المرور", _reset, Color("#6c63ff")))
	v.add_child(UI.button("العب كضيف", _guest, Color("#f4a261")))
	v.add_child(UI.button("سياسة الخصوصية", func(): GameState.go("res://scenes/privacy.tscn"), Color("#8d99ae")))

func _busy(b: bool) -> void:
	for c in find_children("*", "Button", true, false):
		(c as Button).disabled = b

func _fail(r: Dictionary) -> void:
	status.text = Cloud.error_text(str(r.get("error", "UNKNOWN")))
	_busy(false)

func _login() -> void:
	_busy(true); status.text = "جارٍ الدخول…"
	var r = await Cloud.sign_in(email.text.strip_edges(), pw.text)
	if r["ok"]: GameState.go("res://scenes/menu.tscn")
	else: _fail(r)

func _register() -> void:
	if not consent.button_pressed:
		status.text = "يلزم موافقة ولي الأمر أولاً."; return
	_busy(true); status.text = "جارٍ إنشاء الحساب…"
	var r = await Cloud.register(email.text.strip_edges(), pw.text, nm.text.strip_edges())
	if r["ok"]: GameState.go("res://scenes/menu.tscn")
	else: _fail(r)

func _reset() -> void:
	_busy(true)
	var r = await Cloud.reset_password(email.text.strip_edges())
	status.text = "أُرسل رابط الاستعادة إلى بريدك." if r["ok"] else Cloud.error_text(str(r.get("error", "")))
	_busy(false)

func _guest() -> void:
	_busy(true)
	if Cloud.configured:
		var r = await Cloud.guest()
		if not r["ok"]:
			status.text = Cloud.error_text(str(r.get("error", ""))) + " سيُحفظ تقدمك على هذا الجهاز فقط."
	GameState.local_mode = true
	GameState.go("res://scenes/menu.tscn")
