class_name PackageView2D
extends RefCounted

static func create(root: Node2D, world_position: Vector2, is_box: bool) -> Dictionary:
	var node := Node2D.new()
	root.add_child(node)
	node.global_position = world_position
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-28, -20), Vector2(28, -20), Vector2(28, 20), Vector2(-28, 20)]) if is_box else PackedVector2Array([Vector2(-24, -17), Vector2(24, -17), Vector2(28, 17), Vector2(-28, 17)])
	body.color = Color("b9814f") if is_box else Color("cf8e65")
	node.add_child(body)
	var tape := Line2D.new()
	tape.points = PackedVector2Array([Vector2(0, -20), Vector2(0, 20)])
	tape.width = 5.0
	tape.default_color = Color("e4c27c")
	node.add_child(tape)
	var label := Label.new()
	label.name = "Label"
	label.position = Vector2(-82, 28)
	label.size = Vector2(164, 64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.text = "未贴标签"
	node.add_child(label)
	return {"node": node, "label": label}

static func make_box(_node: Node2D) -> void:
	pass

static func update_label(label: Label, order: Dictionary, special_done: bool) -> void:
	var special := " · " + str(order["mark"]) if special_done and str(order["mark"]) != "" else ""
	label.text = "%s\n%s\n[%s]%s" % [order["recipient"], order["address"], order["storage"], special]

static func pick_up(node: Node2D, player: Node2D) -> void:
	node.reparent(player)
	node.position = Vector2(34, -34)
	node.z_index = 12

static func place(node: Node2D, root: Node2D, position_2d: Vector2) -> void:
	node.reparent(root)
	node.global_position = position_2d
	node.z_index = int(position_2d.y)
