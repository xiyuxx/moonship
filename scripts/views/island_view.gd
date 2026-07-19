## 猫咪城镇横版配送图。每个收件人都有独立互动范围。
class_name IslandView
extends DeliveryMap

const STOPS := {
	"luna": {"x":310.0, "name":"图书室", "color":Color("b9b6c7")},
	"noah": {"x":455.0, "name":"裁缝店", "color":Color("37343c")},
	"bello": {"x":610.0, "name":"钟楼", "color":Color("c89955")},
	"youyou": {"x":765.0, "name":"小剧团", "color":Color("e0a0a0")},
	"anmian": {"x":930.0, "name":"港口诊所", "color":Color("f2f1e8")},
	"yunjie": {"x":1090.0, "name":"潮汐壶茶馆", "color":Color("8d654c")}
}
func move(horizontal_input: float, delta: float) -> void:
	courier_x = clamp(courier_x + horizontal_input * delta * 300.0, 70.0, 1160.0)
	queue_redraw()

func is_near_recipient(recipient_id: String) -> bool:
	if not STOPS.has(recipient_id):
		return false
	return absf(courier_x - float(STOPS[recipient_id]["x"])) <= 58.0

func nearby_stop_name() -> String:
	for id in STOPS:
		if absf(courier_x - float(STOPS[id]["x"])) <= 58.0:
			return str(STOPS[id]["name"])
	return ""

func is_near_dock() -> bool:
	return courier_x <= 180.0

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("5586ad"))
	draw_circle(Vector2(1100, 110), 58, Color("fff2a6"))
	draw_rect(Rect2(0, 495, 1280, 225), Color("d9b674"))
	draw_rect(Rect2(0, 455, 1280, 42), Color("8aa46e"))
	draw_rect(Rect2(0, 430, 175, 36), Color("754e37"))
	draw_string(ThemeDB.fallback_font, Vector2(30, 415), "返回邮船", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	for id in STOPS:
		var stop: Dictionary = STOPS[id]
		var x := float(stop["x"])
		var color: Color = stop["color"]
		draw_rect(Rect2(x - 46, 310, 92, 145), color.darkened(0.20))
		draw_rect(Rect2(x - 31, 340, 62, 115), color.lightened(0.15))
		draw_circle(Vector2(x, 426), 25, color)
		draw_circle(Vector2(x - 9, 421), 3, Color("24222b"))
		draw_circle(Vector2(x + 9, 421), 3, Color("24222b"))
		draw_string(ThemeDB.fallback_font, Vector2(x - 45, 292), str(stop["name"]), HORIZONTAL_ALIGNMENT_CENTER, 90, 17, Color.WHITE)
	draw_circle(Vector2(courier_x, 470), 25, Color("28496f"))
	draw_rect(Rect2(courier_x - 16, 495, 32, 40), Color("f7d58c"))
	draw_string(ThemeDB.fallback_font, Vector2(60, 110), "猫咪城镇 · 夜晚配送", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
