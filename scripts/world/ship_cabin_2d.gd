class_name ShipCabin2D
extends Node2D

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("21354b"))
	draw_rect(Rect2(36, 80, 1208, 600), Color("d6b07a"), true)
	draw_rect(Rect2(36, 80, 1208, 600), Color("6c4836"), false, 8.0)
	for y in range(120, 680, 42):
		draw_line(Vector2(40, y), Vector2(1240, y), Color("9d734f"), 1.0)
	draw_rect(Rect2(36, 80, 1208, 60), Color("f0dfbf"), true)
	for x in [690, 855, 1020]:
		draw_circle(Vector2(x, 110), 19, Color("7099b8"))
		draw_arc(Vector2(x, 110), 19, 0.0, TAU, 20, Color("5a7894"), 3.0)
