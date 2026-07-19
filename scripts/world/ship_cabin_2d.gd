## 斜俯视船舱背景：木地板、地毯、后墙与舷窗灯光，营造类似星露谷的立体室内质感。
class_name ShipCabin2D
extends Node2D

func _draw() -> void:
	# 舱外深色海面作为整体画布底色。
	draw_rect(Rect2(0, 0, 1280, 720), Color("162131"))

	# 后墙：带厚度感的墙体，底部压一条阴影线区分墙面与地板。
	draw_rect(Rect2(0, 0, 1280, 118), Color("2c3f57"))
	draw_rect(Rect2(0, 108, 1280, 14), Color("1c2a3c"))

	# 木地板主体 + 深色踢脚边框，模拟斜俯视下的地面体块。
	draw_rect(Rect2(36, 80, 1208, 600), Color("d6b07a"), true)
	draw_rect(Rect2(36, 80, 1208, 600), Color("6c4836"), false, 8.0)
	for y in range(120, 680, 42):
		draw_line(Vector2(40, y), Vector2(1240, y), Color("9d734f"), 1.0)
	# 竖向木纹分缝，弱化"纯平面"感。
	for x in range(80, 1240, 160):
		draw_line(Vector2(x, 122), Vector2(x, 676), Color("c49f6c"), 1.0)

	# 中央地毯，呼应参考图的暖色通道地毯，同时提示玩家主要动线。
	draw_rect(Rect2(560, 250, 220, 400), Color("8a3f3a"))
	draw_rect(Rect2(560, 250, 220, 400), Color("6f2f2c"), false, 4.0)
	draw_rect(Rect2(650, 250, 40, 400), Color("caa15f"))

	# 顶部墙裙/横梁，提供垂直厚度错觉。
	draw_rect(Rect2(36, 80, 1208, 60), Color("f0dfbf"), true)
	draw_rect(Rect2(36, 132, 1208, 6), Color("c7a877"))

	# 舷窗与暖黄灯光辉光，弱化平面墙壁。
	for x in [690, 855, 1020]:
		draw_circle(Vector2(x, 110), 30, Color(0.98, 0.85, 0.55, 0.16))
		draw_circle(Vector2(x, 110), 19, Color("7099b8"))
		draw_arc(Vector2(x, 110), 19, 0.0, TAU, 20, Color("5a7894"), 3.0)
		draw_circle(Vector2(x, 110), 8, Color(1.0, 0.92, 0.72, 0.85))

	# 吊灯：从横梁垂下，呼应参考图的暖色吊灯氛围。
	for x in [230, 640, 1050]:
		draw_line(Vector2(x, 140), Vector2(x, 178), Color("4b3a2a"), 3.0)
		draw_circle(Vector2(x, 190), 34, Color(0.98, 0.82, 0.5, 0.14))
		draw_circle(Vector2(x, 188), 16, Color("5a4326"))
		draw_circle(Vector2(x, 188), 12, Color("caa15f"))
		draw_circle(Vector2(x, 188), 6, Color(1.0, 0.9, 0.68, 0.9))
