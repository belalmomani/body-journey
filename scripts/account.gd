extends Control
var status: Label
var armed := false
func _ready() -> void:
	var v := UI.root(self)
	v.add_child(UI.label("الحساب والبيانات", 48))
	var who := "غير مسجّل (حفظ محلي فقط)"
	if Cloud.signed_in(): who = "ضيف (سحابي)" if Cloud.is_guest else Cloud.email
	v.add_child(UI.label("الحالة: " + who, 28))
	status = UI.label("", 28, Color("#c0392b"))
	v.add_child(status)
	if Cloud.signed_in() and Cloud.is_guest:
		var e := UI.input("بريد ولي الأمر لربط الحساب")
		var p := UI.input("كلمة المرور", true)
		v.add_child(e); v.add_child(p)
		v.add_child(UI.button("ربط الحساب (يبقى تقدمك)", func():
			var r = await Cloud.link_guest(e.text.strip_edges(), p.text)
			status.text = "تم الربط." if r["ok"] else Cloud.error_text(str(r.get("error", "")))))
	if Cloud.signed_in():
		v.add_child(UI.button("مزامنة الآن", func():
			status.text = "تمت المزامنة." if await Cloud.pull() else "تعذّرت المزامنة (لا اتصال)."))
		v.add_child(UI.button("تسجيل الخروج", func():
			Cloud.sign_out(); GameState.local_mode = false; GameState.go("res://scenes/login.tscn"), Color("#6c63ff")))
		v.add_child(UI.button("حذف الحساب وبياناتي السحابية", _delete, Color("#c0392b")))
	v.add_child(UI.button("مسح التقدم المحلي", _wipe_local, Color("#e76f51")))
	UI.back_button(v, "res://scenes/settings.tscn")

func _delete() -> void:
	if not armed:
		armed = true; status.text = "اضغط مرة أخرى للتأكيد. الحذف نهائي."; return
	var r = await Cloud.delete_account()
	if r["ok"]:
		GameState.data = GameState._default(); GameState.save_local(); GameState.go("res://scenes/login.tscn")
	else:
		status.text = Cloud.error_text(str(r.get("error", ""))) + " (قد يلزم تسجيل الدخول من جديد ثم المحاولة)"

func _wipe_local() -> void:
	if not armed:
		armed = true; status.text = "اضغط مرة أخرى للتأكيد."; return
	GameState.data = GameState._default(); GameState.save_local(); status.text = "تم المسح المحلي."; armed = false
