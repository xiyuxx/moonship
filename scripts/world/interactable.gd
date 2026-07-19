class_name Interactable
extends Area3D

## 编辑器中可摆放的通用互动台。interaction_id 由主流程解释。
@export var interaction_id := ""
@export var display_name := ""

@onready var label: Label3D = $Label3D

func _ready() -> void:
	add_to_group("interactable")
	set_meta("id", interaction_id)
	label.text = display_name
