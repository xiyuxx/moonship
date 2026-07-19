class_name DeliveryMap
extends Node2D

## 统一配送地图接口；后续地图继承它即可被主流程替换。
@export var map_id := ""
var courier_x := 120.0

func reset_at_dock() -> void:
	courier_x = 120.0
	queue_redraw()

func move(_horizontal_input: float, _delta: float) -> void: pass
func is_near_recipient(_recipient_id: String) -> bool: return false
func nearby_stop_name() -> String: return ""
func is_near_dock() -> bool: return true
