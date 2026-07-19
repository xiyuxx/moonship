## 主控制器：白天收件/整理，夜晚选件/投递。
extends Node3D

var orders: Array[Dictionary] = []
var day := 1
var phase := "day"
var coins := 35
var next_order := 0
var current_customer: Variant = null
var active_order: Variant = null
var packed := false
var labelled := false
var special_done := false
var carrying := false
var package_node: Node3D
var package_label: Label3D

# 每个格位是仓库唯一的真实存储位置；slot_orders 是仓库的唯一数据来源。
var storage_slots: Dictionary = {}
var slot_orders: Dictionary = {}
var slot_visuals: Dictionary = {}
var backpack: Array = []
var backpack_capacity := 2
var selected_backpack := 0
var island_mode := false

var player: Node3D
var camera: Camera3D
var hud: Label
var objective: Label
var prompt: Label
var island_layer: CanvasLayer
var island_map: IslandView
var island_text: Label
var yaw := 0.0
var pitch := -0.15


# =============================================================================
# 主生命周期
# =============================================================================
func _ready() -> void:
	orders = OrderData.create_daily_orders()
	_register_input()
	_build_ship()
	_build_hud()
	_build_island()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh_hud()


func _process(delta: float) -> void:
	if island_mode:
		island_map.move(Input.get_axis("move_left", "move_right"), delta)
		return
	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := player.global_transform.basis.x * move.x + player.global_transform.basis.z * move.y
	direction.y = 0
	player.position += direction * delta * 4.2
	player.position.x = clamp(player.position.x, -8.0, 8.0)
	player.position.z = clamp(player.position.z, -7.0, 7.0)
	_update_prompt()


func _input(event: InputEvent) -> void:
	if island_mode:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_Q and not backpack.is_empty():
				selected_backpack = posmod(selected_backpack - 1, backpack.size())
				_update_island_text()
			elif event.keycode == KEY_E and not backpack.is_empty():
				selected_backpack = posmod(selected_backpack + 1, backpack.size())
				_update_island_text()
			elif event.keycode == KEY_F:
				_island_interact()
		return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * 0.0025
		pitch = clamp(pitch - event.relative.y * 0.0025, -1.1, 0.8)
		player.rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_interact(_target_id())
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and current_customer != null:
		current_customer = null
		_notice("已礼貌拒绝此单。")


# =============================================================================
# 白天：接件、打包、贴标和自由整理。
# =============================================================================
func _interact(id: String) -> void:
	if id.begins_with("slot:"):
		_interact_slot(id.trim_prefix("slot:"))
		return
	match id:
		"counter": _use_counter()
		"packing": _use_packing()
		"label": _use_label_table()
		"gangway": _use_gangway()
	_refresh_hud()


func _use_counter() -> void:
	if active_order != null:
		_notice("请先完成手中的包裹再接新订单。")
		return
	if current_customer == null:
		if next_order >= orders.size():
			_notice("今日没有新的来件。")
			return
		current_customer = orders[next_order].duplicate()
		next_order += 1
		_notice("%s 递来「%s」。收件人：%s；按 F 接单，按 R 拒绝。" % [current_customer["sender"], current_customer["item"], current_customer["recipient"]])
		return
	active_order = current_customer
	current_customer = null
	_spawn_package(Vector3(-5.2, 2.02, -5.9), false)
	_notice("已接单。物品在窗口柜台上；按 F 拿起后带到打包台。")


func _use_packing() -> void:
	if active_order == null:
		_notice("请先在取件窗口接单。")
		return
	if not carrying and not packed:
		_pick_up()
		_notice("已拿起未包装物品。带到打包台按 F 封箱。")
		return
	if carrying and not packed:
		_place_package(Vector3(-1.8, 2.02, -2.4))
		_make_box()
		packed = true
		_notice("已封箱。再按 F 拿起纸箱，带到贴标台。")
		return
	if packed and not carrying:
		_pick_up()
		_notice("已拿起纸箱。带到贴标台制作面单。")
		return
	_notice("纸箱已在手中，请前往贴标台。")


func _use_label_table() -> void:
	if active_order == null or not packed or not carrying:
		_notice("请先在打包台封箱并拿起纸箱。")
		return
	if not labelled:
		labelled = true
		_update_package_label()
		if str(active_order["mark"]) == "":
			special_done = true
			_notice("已贴上收件人、目的地与保存条件面单。这是普通包裹，可自行选择合适格位入库。")
		else:
			_notice("已贴地址面单。再按 F 在同一台面加贴「%s」。" % active_order["mark"])
		return
	if not special_done:
		special_done = true
		_update_package_label()
		_notice("已加贴「%s」。现在可手持纸箱，选择匹配的空格位入库。" % active_order["mark"])
		return
	_notice("面单已完成。请选择仓库中的空格位。")


func _interact_slot(slot_id: String) -> void:
	var info: Dictionary = storage_slots[slot_id]
	if phase == "night":
		_load_from_slot(slot_id)
		return
	# 白天：手持已完成箱子时放入空格；空手时从指定格位取出箱子。
	if carrying:
		if active_order == null or not labelled or not special_done:
			_notice("这个包裹尚未完成贴标，不能入库。")
			return
		if info["kind"] != active_order["storage"]:
			_notice("该格位属于%s；此包裹需要%s。" % [info["kind"], active_order["storage"]])
			return
		if slot_orders.has(slot_id):
			_notice("这个格位已有包裹。请选择另一个空格。")
			return
		_place_package(info["position"])
		active_order["slot"] = slot_id
		slot_orders[slot_id] = active_order
		slot_visuals[slot_id] = package_node
		active_order = null
		package_node = null
		carrying = false
		_notice("已放入 %s。之后可随时从这个具体格位拿起并重新整理。" % info["kind"])
		return
	if not slot_orders.has(slot_id):
		_notice("这是空格位。拿着已贴标纸箱时可放入这里。")
		return
	active_order = slot_orders[slot_id]
	package_node = slot_visuals[slot_id]
	slot_orders.erase(slot_id)
	slot_visuals.erase(slot_id)
	packed = true
	labelled = true
	special_done = true
	_pick_up()
	_notice("已从格位拿起「%s」。可搬到另一个匹配的空格继续整理。" % active_order["item"])


# =============================================================================
# 夜晚：从玩家指定的格位装包，再下岛投递。
# =============================================================================
func _use_gangway() -> void:
	if phase == "day":
		if slot_orders.is_empty():
			_notice("先完成至少一件包裹的入库，才能结束白天。")
			return
		phase = "night"
		_notice("夜晚开始。走到你想配送的具体格位，按 F 将纸箱装入背包。")
		return
	if backpack.is_empty():
		if not slot_orders.is_empty():
			_notice("请先从具体仓储格位选择包裹装入背包。")
			return
		phase = "day"
		day += 1
		next_order = 0
		orders = OrderData.create_daily_orders()
		_notice("新的一天开始。")
		return
	island_mode = true
	island_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	selected_backpack = 0
	_update_island_text()


func _load_from_slot(slot_id: String) -> void:
	if not slot_orders.has(slot_id):
		_notice("这个格位是空的。")
		return
	if backpack.size() >= backpack_capacity:
		_notice("背包已满（%d/%d）。请前往下岛入口。" % [backpack.size(), backpack_capacity])
		return
	var order: Dictionary = slot_orders[slot_id]
	var visual: Node3D = slot_visuals[slot_id]
	slot_orders.erase(slot_id)
	slot_visuals.erase(slot_id)
	visual.visible = false
	order["visual"] = visual
	backpack.append(order)
	_notice("已选择「%s」装入背包（%d/%d）。" % [order["item"], backpack.size(), backpack_capacity])


func _island_interact() -> void:
	if backpack.is_empty():
		if island_map.is_near_dock():
			island_mode = false
			island_layer.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_notice("已返回邮船。")
		return
	if not island_map.is_near_recipient():
		island_text.text = "还没有到达收件人身边。"
		return
	var order: Dictionary = backpack[selected_backpack]
	backpack.remove_at(selected_backpack)
	selected_backpack = max(0, selected_backpack - 1)
	var visual: Variant = order.get("visual", null)
	if visual is Node3D and is_instance_valid(visual):
		visual.queue_free()
	coins += int(order["pay"])
	island_text.text = "投递成功！获得 %d 金币。向左到码头按 F 返回。" % order["pay"]
	_refresh_hud()


# =============================================================================
# 物体、标签与场景搭建
# =============================================================================
func _spawn_package(world_position: Vector3, is_box: bool) -> void:
	if package_node != null and carrying:
		package_node.queue_free()
	package_node = Node3D.new()
	add_child(package_node)
	package_node.global_position = world_position
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
	package_node.add_child(mesh)
	package_label = Label3D.new()
	package_label.position = Vector3(0, 0.35, 0)
	package_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	package_label.font_size = 42
	package_label.outline_size = 5
	package_label.text = "未贴标签"
	package_node.add_child(package_label)


func _make_box() -> void:
	if package_node == null:
		return
	_spawn_package(package_node.global_position, true)


func _update_package_label() -> void:
	if package_label == null or active_order == null:
		return
	var special: String = "\n" + active_order["mark"] if special_done and str(active_order["mark"]) != "" else ""
	package_label.text = "%s\n%s\n[%s]%s" % [active_order["recipient"], active_order["address"], active_order["storage"], special]


func _pick_up() -> void:
	if package_node == null:
		return
	package_node.reparent(camera)
	package_node.position = Vector3(0.38, -0.32, -0.9)
	package_node.visible = true
	carrying = true


func _place_package(position_3d: Vector3) -> void:
	package_node.reparent(self)
	package_node.global_position = position_3d
	carrying = false


func _build_ship() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	add_child(light)
	_add_box("地板", Vector3(0, -0.2, 0), Vector3(18, 0.4, 16), Color("754e37"), "")
	_add_box("前墙", Vector3(0, 2.2, -8), Vector3(18, 4.8, 0.35), Color("e3d5bd"), "")
	_add_box("后墙", Vector3(0, 2.2, 8), Vector3(18, 4.8, 0.35), Color("365678"), "")
	_add_station("取件窗口", Vector3(-5.2, 1, -5.9), "counter", Color("d9974f"))
	_add_station("取件窗口", Vector3(0, 1, -5.9), "counter", Color("d9974f"))
	_add_station("取件窗口", Vector3(5.2, 1, -5.9), "counter", Color("d9974f"))
	_add_station("打包台", Vector3(-1.8, 1, -2.4), "packing", Color("ca7d61"))
	_add_station("贴标与特殊标识台", Vector3(2.8, 1, -2.4), "label", Color("e8d8b5"))
	_add_station("下岛入口", Vector3(-7, 0.7, 1.5), "gangway", Color("eee4bd"))
	_add_slots("常温货架", "常温货架", [Vector3(-1.5, 1.2, 2.0),Vector3(0, 1.2, 2.0),Vector3(1.5, 1.2, 2.0),Vector3(-1.5, 1.2, 4.0),Vector3(0, 1.2, 4.0),Vector3(1.5, 1.2, 4.0)])
	_add_slots("冷冻室", "冷冻室", [Vector3(-6.2, 1.2, 4.0),Vector3(-6.2, 1.2, 5.3)])
	_add_slots("温室", "温室", [Vector3(-6.2, 1.2, 6.5),Vector3(-6.2, 1.2, 7.4)])
	player = Node3D.new()
	player.position = Vector3(0, 1.6, 3)
	add_child(player)
	camera = Camera3D.new()
	camera.current = true
	player.add_child(camera)


func _add_slots(prefix: String, kind: String, positions: Array) -> void:
	for index in positions.size():
		var id := prefix + "_" + str(index + 1)
		storage_slots[id] = {"kind": kind, "position": positions[index]}
		_add_station(kind + "格位 " + str(index + 1), positions[index], "slot:" + id, Color("a88054") if kind == "常温货架" else Color("82c9dd") if kind == "冷冻室" else Color("83b86c"), Vector3(0.95, 1.2, 0.95))


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := ColorRect.new()
	top.color = Color(0.04, 0.08, 0.14, 0.86)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.size.y = 138
	layer.add_child(top)
	hud = Label.new(); hud.position = Vector2(28, 20); hud.add_theme_font_size_override("font_size", 22); top.add_child(hud)
	objective = Label.new(); objective.position = Vector2(28, 58); objective.size = Vector2(1000, 70); objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; objective.add_theme_font_size_override("font_size", 17); top.add_child(objective)
	prompt = Label.new(); prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); prompt.position.y = -70; prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; prompt.add_theme_font_size_override("font_size", 18); layer.add_child(prompt)


func _build_island() -> void:
	island_layer = CanvasLayer.new(); island_layer.layer = 3; add_child(island_layer)
	island_map = IslandView.new(); island_layer.add_child(island_map)
	island_text = Label.new(); island_text.position = Vector2(35,25); island_text.add_theme_font_size_override("font_size",22); island_layer.add_child(island_text)
	island_layer.visible = false


func _add_box(title: String, position_3d: Vector3, size: Vector3, color: Color, id: String) -> void:
	var body := StaticBody3D.new(); body.name = title; body.position = position_3d
	if id != "": body.set_meta("id", id)
	add_child(body)
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size; mesh.mesh = box
	var material := StandardMaterial3D.new(); material.albedo_color = color; mesh.material_override = material; body.add_child(mesh)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; collision.shape = shape; body.add_child(collision)


func _add_station(title: String, position_3d: Vector3, id: String, color: Color, size := Vector3(2.3, 1.8, 1.1)) -> void:
	_add_box(title, position_3d, size, color, id)
	var label := Label3D.new(); label.text = title; label.position = position_3d + Vector3(0, 1.25, 0); label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.font_size = 42; label.outline_size = 5; add_child(label)


func _target_id() -> String:
	var center := get_viewport().get_visible_rect().size * 0.5
	var start := camera.project_ray_origin(center)
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, start + camera.project_ray_normal(center) * 4.0))
	if hit.is_empty(): return ""
	var collider: Object = hit.get("collider")
	return str(collider.get_meta("id")) if collider != null and collider.has_meta("id") else ""


func _register_input() -> void:
	for pair in {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN]}:
		if not InputMap.has_action(pair): InputMap.add_action(pair)
		for key in {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN]}[pair]:
			var input_event := InputEventKey.new(); input_event.physical_keycode = key; InputMap.action_add_event(pair, input_event)


func _update_prompt() -> void:
	var id := _target_id()
	prompt.text = "[F] 互动" if id != "" else "WASD 移动 · 鼠标观察 · F 互动"


func _update_island_text() -> void:
	if backpack.is_empty(): island_text.text = "背包为空，向左到码头按 F 返回。"; return
	var order: Dictionary = backpack[selected_backpack]
	island_text.text = "背包 %d/%d：%s → %s\nA/D 移动，Q/E 选箱，F 投递。" % [backpack.size(), backpack_capacity, order["item"], order["recipient"]]


func _notice(text: String) -> void:
	objective.text = text


func _refresh_hud() -> void:
	var phase_name := "白天整理" if phase == "day" else "夜晚装载"
	hud.text = "第 %d 天 · %s · 金币 %d · 已入库 %d · 背包 %d/%d" % [day, phase_name, coins, slot_orders.size(), backpack.size(), backpack_capacity]


