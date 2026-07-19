## 仅负责搭建 3D 船舱和注册可交互格位。
class_name ShipBuilder
extends RefCounted

static func build(root: Node3D, storage_slots: Dictionary) -> Dictionary:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("344968")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b9c9e0")
	env.ambient_light_energy = 0.85
	environment.environment = env
	root.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.6
	root.add_child(light)
	_add_box(root, "地板", Vector3(0, -0.2, 0), Vector3(18, 0.4, 16), Color("754e37"), "")
	_add_box(root, "隔墙左段", Vector3(-7.0, 2.2, 0), Vector3(4.0, 4.8, 0.35), Color("44627e"), "")
	_add_box(root, "隔墙中段", Vector3(0, 2.2, 0), Vector3(4.0, 4.8, 0.35), Color("44627e"), "")
	_add_box(root, "隔墙右段", Vector3(7.0, 2.2, 0), Vector3(4.0, 4.8, 0.35), Color("44627e"), "")
	_add_box(root, "前墙", Vector3(0, 2.2, -8), Vector3(18, 4.8, 0.35), Color("e3d5bd"), "")
	_add_box(root, "后墙", Vector3(0, 2.2, 8), Vector3(18, 4.8, 0.35), Color("365678"), "")
	_add_station(root, "取件窗口", Vector3(-5.2, 1, -5.9), "counter_left", Color("d9974f"))
	_add_station(root, "取件窗口", Vector3(0, 1, -5.9), "counter_middle", Color("d9974f"))
	_add_station(root, "取件窗口", Vector3(5.2, 1, -5.9), "counter_right", Color("d9974f"))
	_add_station(root, "打包台", Vector3(-1.8, 1, -2.4), "packing", Color("ca7d61"))
	_add_station(root, "贴标与特殊标识台", Vector3(2.8, 1, -2.4), "label", Color("e8d8b5"))
	_add_station(root, "下岛入口", Vector3(-7, 0.7, 1.5), "gangway", Color("eee4bd"))
	_add_slots(root, storage_slots, "常温货架", [Vector3(-1.5, 1.2, 2.0), Vector3(0, 1.2, 2.0), Vector3(1.5, 1.2, 2.0), Vector3(-1.5, 1.2, 4.0), Vector3(0, 1.2, 4.0), Vector3(1.5, 1.2, 4.0)])
	_add_slots(root, storage_slots, "冷冻室", [Vector3(-6.2, 1.2, 4.0), Vector3(-6.2, 1.2, 5.3)])
	_add_slots(root, storage_slots, "温室", [Vector3(-6.2, 1.2, 6.5), Vector3(-6.2, 1.2, 7.4)])
	var player := Node3D.new()
	player.position = Vector3(0, 1.6, 3)
	root.add_child(player)
	var camera := Camera3D.new()
	camera.current = true
	player.add_child(camera)
	return {"player": player, "camera": camera}

static func _add_slots(root: Node3D, storage_slots: Dictionary, kind: String, positions: Array) -> void:
	for index in positions.size():
		var id := kind + "_" + str(index + 1)
		storage_slots[id] = {"kind": kind, "position": positions[index]}
		var color := Color("a88054") if kind == "常温货架" else Color("82c9dd") if kind == "冷冻室" else Color("83b86c")
		_add_station(root, kind + "格位 " + str(index + 1), positions[index], "slot:" + id, color, Vector3(0.95, 1.2, 0.95))

static func _add_box(root: Node3D, title: String, position_3d: Vector3, size: Vector3, color: Color, id: String) -> void:
	var body := StaticBody3D.new()
	body.name = title
	body.position = position_3d
	if id != "": body.set_meta("id", id)
	root.add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

static func _add_station(root: Node3D, title: String, position_3d: Vector3, id: String, color: Color, size := Vector3(2.3, 1.8, 1.1)) -> void:
	_add_box(root, title, position_3d, size, color, id)
	var label := Label3D.new()
	label.text = title
	label.position = position_3d + Vector3(0, 1.25, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.outline_size = 5
	root.add_child(label)
