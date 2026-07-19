## 月光邮船的主控制器。
## 职责：启动游戏、维护订单流程、在 3D 船舱与 2D 岛屿之间切换。
## 订单内容在 order_data.gd；横版岛屿绘制在 island_view.gd。
extends Node3D

# ---- 游戏状态 ----
var orders: Array[Dictionary] = []
var coins := 35
var next_order := 0
var current_customer: Variant = null
var pending: Array = []
var active_order: Variant = null
var stored: Array = []
var packed := false
var labelled := false
var marked := false
var island_mode := false

# ---- 场景节点引用 ----
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
# 主生命周期：先看这里，了解游戏每帧如何运行。
# =============================================================================
func _ready() -> void:
	orders = OrderData.create_daily_orders()
	_register_input()
	_build_ship()
	_build_hud()
	_build_island()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_hud()


func _process(delta: float) -> void:
	if island_mode:
		_update_island(delta)
		return
	_move_ship_player(delta)
	_update_prompt()


func _input(event: InputEvent) -> void:
	if island_mode:
		if event is InputEventKey and event.pressed and event.keycode == KEY_F:
			_island_interact()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.0025
		pitch = clamp(pitch - event.relative.y * 0.0025, -1.1, 0.8)
		player.rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_interact_with_station(_target_station())
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and current_customer != null:
		current_customer = null
		_set_notice("已礼貌拒绝此单。")


# =============================================================================
# 主玩法流程：船上收件、处理、入库与岛屿投递。
# =============================================================================
func _interact_with_station(station: String) -> void:
	match station:
		"counter": _use_counter()
		"packing": _use_packing()
		"label": _use_label_printer()
		"mark": _use_mark_station()
		"storage": _use_storage()
		"gangway": _go_to_island()
		_: return
	_update_hud()


func _use_counter() -> void:
	# 第一次互动让下一位客户出现；第二次互动则正式接单。
	if current_customer == null:
		if next_order >= orders.size():
			_set_notice("今天没有新客户了。请处理已接下的订单。")
			return
		current_customer = orders[next_order].duplicate()
		next_order += 1
		_set_notice("%s 想寄「%s」。按 F 接单，按 R 礼貌拒单。" % [current_customer["sender"], current_customer["item"]])
		return
	pending.append(current_customer)
	_set_notice("已接单：%s。请去打包台处理。" % current_customer["item"])
	current_customer = null


func _use_packing() -> void:
	if active_order == null:
		if pending.is_empty():
			_set_notice("目前没有等待打包的订单。")
			return
		active_order = pending.pop_front()
	if packed:
		_set_notice("这个包裹已经打包完成。")
		return
	packed = true
	_set_notice("已用「%s」完成打包。下一步去标签打印机。" % active_order["pack"])


func _use_label_printer() -> void:
	if active_order == null or not packed:
		_set_notice("请先从打包台领取并打包订单。")
		return
	labelled = true
	_set_notice("已贴标签：%s / %s。下一步前往特殊标识台。" % [active_order["recipient"], active_order["address"]])


func _use_mark_station() -> void:
	if active_order == null or not labelled:
		_set_notice("请先完成包装与地址标签。")
		return
	marked = true
	_set_notice("已加贴「%s」。现在可前往对应仓储区入库。" % active_order["mark"])


func _use_storage() -> void:
	if active_order == null or not marked:
		_set_notice("当前没有完成全部手续的包裹。")
		return
	stored.append(active_order)
	_set_notice("已将「%s」放入%s。可走到舷梯，前往岛屿投递。" % [active_order["item"], active_order["storage"]])
	active_order = null
	packed = false
	labelled = false
	marked = false


func _go_to_island() -> void:
	if stored.is_empty():
		_set_notice("船上没有已经处理好的包裹。")
		return
	island_mode = true
	island_layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_island_text()


func _island_interact() -> void:
	# 投递完成后不自动返航；玩家必须自己走回左侧码头。
	if stored.is_empty():
		if island_map.is_near_dock():
			_return_to_ship()
		else:
			island_text.text = "包裹已经投递。请向左走回码头，再按 F 返回邮船。"
		return
	if not island_map.is_near_recipient():
		island_text.text = "还没有到达收件人身边。继续向右走。"
		return
	var order: Dictionary = stored.pop_front()
	coins += int(order["pay"])
	_update_hud()
	island_text.text = "投递成功！获得 %d 金币。请向左走回码头，按 F 返回邮船。" % order["pay"]


func _return_to_ship() -> void:
	island_mode = false
	island_layer.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_set_notice("已返回邮船。可以继续处理下一件订单。")
	_update_hud()


# =============================================================================
# 3D/2D 场景更新与输入。
# =============================================================================
func _move_ship_player(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	# Input.get_vector 的“向前”是负数，因此这里减去 Y 分量。
	var direction := right * movement.x - forward * movement.y
	direction.y = 0
	player.position += direction * delta * 4.2
	player.position.x = clamp(player.position.x, -6.8, 6.8)
	player.position.z = clamp(player.position.z, -4.2, 4.2)


func _update_island(delta: float) -> void:
	island_map.move(Input.get_axis("move_left", "move_right"), delta)
	if not stored.is_empty():
		_update_island_text()


func _register_input() -> void:
	# 在代码中注册，避免必须手动打开 Godot 的项目设置。
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN]
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var input_event := InputEventKey.new()
			input_event.physical_keycode = key
			InputMap.action_add_event(action, input_event)


# =============================================================================
# 场景搭建：当前全部使用基础几何体，后续可替换为正式美术资产。
# =============================================================================
func _build_ship() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("5e89ad")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dbe9ff")
	env.ambient_light_energy = 0.75
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.4
	add_child(light)
	_add_box("船舱地板", Vector3(0, -0.2, 0), Vector3(16, 0.4, 10), Color("754e37"), "")
	_add_box("左墙", Vector3(-8, 2.2, 0), Vector3(0.35, 4.8, 10), Color("365678"), "")
	_add_box("右墙", Vector3(8, 2.2, 0), Vector3(0.35, 4.8, 10), Color("365678"), "")
	_add_box("后墙", Vector3(0, 2.2, 5), Vector3(16, 4.8, 0.35), Color("365678"), "")
	_add_station("接件柜台", Vector3(-5.4, 1.0, -3.4), Color("d9974f"), "counter")
	_add_station("打包台", Vector3(-1.8, 1.0, -3.4), Color("ca7d61"), "packing")
	_add_station("标签打印机", Vector3(1.8, 0.9, -3.4), Color("e8d8b5"), "label")
	_add_station("特殊标识台", Vector3(5.1, 0.9, -3.4), Color("d27972"), "mark")
	_add_station("分类货架", Vector3(-4.2, 1.0, 2.7), Color("a88054"), "storage")
	_add_station("冷冻室", Vector3(0.0, 1.0, 2.7), Color("82c9dd"), "storage")
	_add_station("温室", Vector3(4.2, 1.0, 2.7), Color("83b86c"), "storage")
	_add_station("下岛舷梯", Vector3(0, 0.5, -4.8), Color("eee4bd"), "gangway")
	player = Node3D.new()
	player.position = Vector3(0, 1.6, 0)
	add_child(player)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 74.0
	player.add_child(camera)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := ColorRect.new()
	top.color = Color(0.04, 0.08, 0.14, 0.86)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.size.y = 138
	layer.add_child(top)
	hud = Label.new()
	hud.position = Vector2(28, 20)
	hud.add_theme_font_size_override("font_size", 23)
	top.add_child(hud)
	objective = Label.new()
	objective.position = Vector2(28, 58)
	objective.add_theme_font_size_override("font_size", 17)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.size = Vector2(900, 70)
	top.add_child(objective)
	prompt = Label.new()
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.position.y = -75
	prompt.size.y = 48
	layer.add_child(prompt)


func _build_island() -> void:
	island_layer = CanvasLayer.new()
	island_layer.layer = 3
	add_child(island_layer)
	island_map = IslandView.new()
	island_layer.add_child(island_map)
	island_text = Label.new()
	island_text.position = Vector2(35, 25)
	island_text.add_theme_font_size_override("font_size", 22)
	island_text.add_theme_color_override("font_color", Color.WHITE)
	island_layer.add_child(island_text)
	island_layer.visible = false


# =============================================================================
# 低层工具：物体生成、射线检测和 UI 文本。
# =============================================================================
func _add_box(title: String, position_3d: Vector3, size: Vector3, color: Color, station: String) -> void:
	var body := StaticBody3D.new()
	body.name = title
	body.position = position_3d
	if station != "":
		body.set_meta("station", station)
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _add_station(title: String, position_3d: Vector3, color: Color, station: String) -> void:
	_add_box(title, position_3d, Vector3(2.5, 1.8, 1.1), color, station)
	var label := Label3D.new()
	label.text = title
	label.position = position_3d + Vector3(0, 1.35, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 52
	label.outline_size = 8
	label.modulate = Color.WHITE
	add_child(label)


func _target_station() -> String:
	var center := get_viewport().get_visible_rect().size * 0.5
	var start := camera.project_ray_origin(center)
	var query := PhysicsRayQueryParameters3D.create(start, start + camera.project_ray_normal(center) * 4.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ""
	var collider: Object = hit.get("collider")
	if collider != null and collider.has_meta("station"):
		return str(collider.get_meta("station"))
	return ""


func _update_prompt() -> void:
	var station := _target_station()
	prompt.text = "[F] 使用：%s" % _station_name(station) if station != "" else "WASD 移动 · 鼠标观察 · 靠近装置按 F"


func _station_name(id: String) -> String:
	return {"counter":"接件柜台", "packing":"打包台", "label":"标签打印机", "mark":"特殊标识台", "storage":"分类仓储", "gangway":"下岛舷梯"}.get(id, "")


func _update_island_text() -> void:
	if stored.is_empty():
		island_text.text = "包裹已投递。向左走到码头，按 F 返回邮船。"
		return
	var order: Dictionary = stored[0]
	island_text.text = "北礁岛 · 横版投递\n包裹：%s → %s\nA/D 或方向键移动；到收件人或码头旁按 F。" % [order["item"], order["recipient"]]


func _set_notice(text: String) -> void:
	objective.text = text


func _update_hud() -> void:
	hud.text = "月光邮船 · 一人称船舱邮局     金币：%d     已入库：%d" % [coins, stored.size()]
	if objective.text == "":
		objective.text = "依次操作：接件柜台 → 打包台 → 标签打印机 → 特殊标识台 → 分类仓储 → 下岛舷梯。"
