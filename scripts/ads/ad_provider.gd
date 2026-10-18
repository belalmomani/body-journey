class_name AdProvider
extends RefCounted
# واجهة موحدة لأي شبكة إعلانات. بدّل المزود دون لمس منطق المراحل.
func load_interstitial() -> void: pass
func is_ready() -> bool: return false
# يجب استدعاء on_closed دائماً (نجاح/فشل/إغلاق) حتى لا يتوقف اللعب.
func show_interstitial(on_closed: Callable) -> void: on_closed.call()
