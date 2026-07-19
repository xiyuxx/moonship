## 包裹 3D 外观与其世界/相机之间的移动。
class_name PackageView
extends RefCounted

static func create(root: Node3D, world_position: Vector3, is_box: bool) -> Dictionary:
	var node := Node3D.new()
	root.add_child(node)
	node.global_position = world_position
	var mesh := MeshInstance3D.new()
	var shape = BoxMesh.new() if is_box else CylinderMesh.new()
	if shape is BoxMesh:
		shape.size = Vector3(0.72, 0.55, 0.58)
	else:
		shape.top_radius = 0.28
		shape.bottom_radius = 0.34
		shape.height = 0.5
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("b9814f") if is_box else Color("cf8e65")
	mesh.material_override = material
	node.add_child(mesh)
	# 正面实体面单：纸箱被玩家拿起时，面单朝向相机所在的一侧。
	var label_card := MeshInstance3D.new()
	var card_mesh := BoxMesh.new()
	card_mesh.size = Vector3(0.60, 0.34, 0.014)
	label_card.mesh = card_mesh
	label_card.position = Vector3(0, 0.03, 0.298)
	var card_material := StandardMaterial3D.new()
	card_material.albedo_color = Color("f3e4c5")
	label_card.material_override = card_material
	node.add_child(label_card)
	var label := Label3D.new()
	label.name = "Label3D"
	label.position = Vector3(-0.25, 0.15, 0.307)
	label.rotation_degrees = Vector3.ZERO
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.pixel_size = 0.0021
	label.font_size = 22
	label.outline_size = 1
	label.modulate = Color("2b2420")
	label.text = "未贴标签"
	node.add_child(label)
	return {"node": node, "label": label}

static func make_box(node: Node3D) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var box_mesh := BoxMesh.new()
			box_mesh.size = Vector3(0.72, 0.55, 0.58)
			child.mesh = box_mesh
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("b9814f")
			child.material_override = material
			return

static func update_label(label: Label3D, order: Dictionary, special_done: bool) -> void:
	var special: String = "\n" + order["mark"] if special_done and str(order["mark"]) != "" else ""
	label.text = "%s\n%s\n[%s]%s" % [order["recipient"], order["address"], order["storage"], special]

static func pick_up(node: Node3D, camera: Camera3D) -> void:
	node.reparent(camera)
	node.position = Vector3(0.38, -0.32, -0.9)
	node.visible = true

static func place(node: Node3D, root: Node3D, position_3d: Vector3) -> void:
	node.reparent(root)
	node.global_position = position_3d




