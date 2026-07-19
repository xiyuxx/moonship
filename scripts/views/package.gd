class_name MailPackage
extends Node3D

@onready var parcel_mesh: MeshInstance3D = $ParcelMesh
@onready var label: Label3D = $Label3D

func configure(order: Dictionary, special_done: bool) -> void:
	update_label(order, special_done)

func make_box() -> void:
	parcel_mesh.mesh = BoxMesh.new()
	(parcel_mesh.mesh as BoxMesh).size = Vector3(0.72, 0.55, 0.58)

func update_label(order: Dictionary, special_done: bool) -> void:
		var special: String = "\n" + str(order["mark"]) if special_done and str(order["mark"]) != "" else ""
	label.text = "%s\n%s\n[%s]%s" % [order["recipient"], order["address"], order["storage"], special]

func pick_up(camera: Camera3D) -> void:
	reparent(camera)
	position = Vector3(0.38, -0.32, -0.9)
	visible = true

func place(root: Node3D, position_3d: Vector3) -> void:
	reparent(root)
	global_position = position_3d
