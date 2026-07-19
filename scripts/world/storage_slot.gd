class_name StorageSlot
extends Area3D

## 一个可见、可选中且能直接在编辑器调整位置的仓储格位。
@export var slot_id := ""
@export_enum("常温货架", "冷冻室", "温室") var storage_kind := "常温货架"

@onready var label: Label3D = $Label3D

func _ready() -> void:
	add_to_group("storage_slot")
	set_meta("id", "slot:" + slot_id)
	label.text = "%s\n%s" % [storage_kind, slot_id]

func get_slot_info() -> Dictionary:
	return {"kind": storage_kind, "position": global_position}
