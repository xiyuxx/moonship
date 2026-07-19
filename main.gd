## 月光邮船首章场景协调器：订单状态、教程、对话与配送闭环。
extends Node3D

const GameHud = preload("res://scripts/ui/game_hud.gd")
const PackageView = preload("res://scripts/views/package_view.gd")
const NpcData = preload("res://scripts/data/npc_data.gd")

var orders: Array[Dictionary] = []
var day := 1
var phase := "day"
var coins := 35
var town_reputation := 0
var next_order := 0
var delivered_today := 0
var completed_order_ids: Array[String] = []
var current_customer: Dictionary = {}
var active_order: Dictionary = {}
var packed := false
var labelled := false
var special_done := false
var carrying := false
var package_node: Node3D
var package_label: Label3D

# 格位是仓库中唯一的存储真相；视觉实体与订单数据按同一格位索引。
var storage_slots: Dictionary = {}
var slot_orders: Dictionary = {}
var slot_visuals: Dictionary = {}
var backpack: Array[Dictionary] = []
var backpack_capacity := 2
var selected_backpack := 0
var island_mode := false
var warned_empty_island := false

var player: Node3D
var camera: Camera3D
var hud: Label
var objective: Label
var prompt: Label
var island_layer: CanvasLayer
# 地图场景使用统一的动态接口，避免依赖编辑器全局 class_name 缓存。
var island_map: Node2D
var island_text: Label
var dialogue: PanelContainer
var dialogue_portrait: ColorRect
var dialogue_speaker: Label
var dialogue_body: Label
var dialogue_advance: Button
var dialogue_confirm: Button
var dialogue_cancel: Button
var dialogue_active := false
var dialogue_mode := ""
var dialogue_lines: Array[Dictionary] = []
var dialogue_index := 0
var dialogue_callback: Callable = Callable()
var confirm_callback: Callable = Callable()
var cancel_callback: Callable = Callable()
var tutorial_stage := 0
var tutorial_complete := false
var yaw := 0.0
var pitch := -0.15


func _ready() -> void:
	_start_day(true)
	_register_input()
	_build_ship()
	_build_hud()
	_build_island()
	player.interact_requested.connect(_interact)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh_hud()
	_show_intro()


func _process(delta: float) -> void:
	if dialogue_active:
		return
	if island_mode:
		island_map.call("move", Input.get_axis("move_left", "move_right"), delta)
		_update_island_text()
		return
	_update_prompt()


func _input(event: InputEvent) -> void:
	if dialogue_active:
		if event is InputEventKey and event.pressed:
			if dialogue_mode == "lines" and (event.keycode == KEY_F or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
				_advance_dialogue()
			elif dialogue_mode == "confirm" and (event.keycode == KEY_F or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
				_accept_confirmation()
			elif dialogue_mode == "confirm" and event.keycode == KEY_ESCAPE:
				_cancel_confirmation()
		return
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
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and not current_customer.is_empty():
		current_customer.clear()
		_notice("已礼貌拒绝此单；可以在任一窗口接下一位客户。")


# =============================================================================
# 对话与首日教程
# =============================================================================
func _show_intro() -> void:
	_show_dialogue([
		_line("阿岚", "我是阿岚……常来找你爷爷修留声机。听说他走了，我很难过。", Color("d78d48")),
		_line("阿岚", "不过这艘船还在。要是你愿意，今天先替我送一只发条盒吧。先走到任一取件窗口，按 F 接待我。", Color("d78d48"))
	], Callable(self, "_start_tutorial"))

func _start_tutorial() -> void:
	tutorial_stage = 1
	_notice("教学 1/7：走到任一取件窗口，按 F 接待阿岚。客户不会排队，请按自己的节奏来。")

func _tutorial_notice(stage: int, text: String) -> bool:
	if tutorial_stage == stage:
		tutorial_stage += 1
		_notice("教学 %d/7：%s" % [stage, text])
		return true
	return false

func _show_dialogue(lines: Array[Dictionary], finished: Callable = Callable()) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_callback = finished
	dialogue_mode = "lines"
	dialogue_active = true
	player.input_enabled = false
	dialogue.visible = true
	dialogue_advance.visible = true
	dialogue_confirm.visible = false
	dialogue_cancel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_render_dialogue_line()

func _show_confirmation(text: String, confirmed: Callable, cancelled: Callable = Callable()) -> void:
	dialogue_mode = "confirm"
	dialogue_active = true
	player.input_enabled = false
	dialogue.visible = true
	dialogue_speaker.text = "夜晚航程确认"
	dialogue_portrait.color = Color("e4c27c")
	dialogue_body.text = text
	dialogue_advance.visible = false
	dialogue_confirm.visible = true
	dialogue_cancel.visible = true
	dialogue_confirm.text = "确认  [F / 回车]"
	dialogue_cancel.text = "取消  [Esc]"
	confirm_callback = confirmed
	cancel_callback = cancelled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _render_dialogue_line() -> void:
	var line: Dictionary = dialogue_lines[dialogue_index]
	dialogue_speaker.text = str(line.get("speaker", ""))
	dialogue_body.text = str(line.get("text", ""))
	dialogue_portrait.color = line.get("color", Color.WHITE)

func _advance_dialogue() -> void:
	if dialogue_mode != "lines":
		return
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_render_dialogue_line()
		return
	var finished := dialogue_callback
	_hide_dialogue()
	if finished.is_valid():
		finished.call()

func _accept_confirmation() -> void:
	var confirmed := confirm_callback
	_hide_dialogue()
	if confirmed.is_valid():
		confirmed.call()

func _cancel_confirmation() -> void:
	var cancelled := cancel_callback
	_hide_dialogue()
	if cancelled.is_valid():
		cancelled.call()

func _hide_dialogue() -> void:
	dialogue_active = false
	dialogue_mode = ""
	dialogue.visible = false
	dialogue_lines.clear()
	dialogue_callback = Callable()
	confirm_callback = Callable()
	cancel_callback = Callable()
	if not island_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.input_enabled = true
	else:
		# 投递结算对话结束后，立刻回到岛屿键盘控制状态。
		_update_island_text()

func _line(speaker: String, text: String, color: Color) -> Dictionary:
	return {"speaker": speaker, "text": text, "color": color}


# =============================================================================
# 白天：接件、打包、贴标和玩家自由整理。
# =============================================================================
func _interact(id: String) -> void:
	if id.begins_with("slot:"):
		_interact_slot(id.trim_prefix("slot:"))
		_refresh_hud()
		return
	match id:
		"counter_left", "counter_middle", "counter_right": _use_counter(id)
		"packing": _use_packing()
		"label": _use_label_table()
		"gangway": _use_gangway()
	_refresh_hud()

func _use_counter(counter_id: String) -> void:
	if not active_order.is_empty():
		if not carrying and not packed:
			if str(active_order.get("counter_id", "")) != counter_id:
				_notice("这件物品仍在原来的窗口。请回到接单窗口拿取。")
				return
			_pick_up()
			if not _tutorial_notice(2, "已拿起物品。带到打包台按 F 封箱。"):
				_notice("已从窗口拿起物品，请带到打包台。")
		else:
			_notice("请先完成手中的这件包裹。")
		return
	if current_customer.is_empty():
		if next_order >= orders.size():
			_notice("今日没有新的来件。请整理已接收的包裹。")
			return
		current_customer = orders[next_order].duplicate(true)
		current_customer["counter_id"] = counter_id
		next_order += 1
		var npc: Dictionary = NpcData.get_npc(str(current_customer["sender_id"]))
		_show_dialogue([
			_line(str(npc.get("name", "居民")), str(current_customer["sender_text"]), npc.get("color", Color.WHITE)),
			_line("订单信息", "%s\n%s\n报酬 %d 金币" % [current_customer["item"], current_customer["description"], current_customer["pay"]], Color("e4c27c"))
		])
		_notice("客户已在这个窗口等候。对话结束后按 F 接单，按 R 可拒绝。")
		return
	if str(current_customer.get("counter_id", "")) != counter_id:
		_notice("客户正在另一个窗口等候，请回到原窗口。")
		return
	active_order = current_customer.duplicate(true)
	current_customer.clear()
	_spawn_package(Vector3({"counter_left":-5.2, "counter_middle":0.0, "counter_right":5.2}[counter_id], 2.02, -5.9), false)
	if not _tutorial_notice(1, "已接单。物品留在当前窗口，再按 F 将它拿起。"):
		_notice("已接单。物品留在此窗口；再次按 F 拿起。")

func _use_packing() -> void:
	if active_order.is_empty():
		_notice("请先在窗口接单并拿起物品。")
		return
	if not carrying and not packed:
		_notice("请回到领取窗口按 F 拿起物品。")
		return
	if carrying and not packed:
		_place_package(Vector3(-1.8, 2.02, -2.4))
		_make_box()
		packed = true
		labelled = true
		special_done = str(active_order["mark"]) == ""
		_update_package_label()
		if str(active_order["mark"]) == "":
			_tutorial_notice(3, "已封箱并生成地址面单。拿起纸箱，选择正确的仓储格位入库。")
		else:
			_tutorial_notice(3, "已封箱并生成地址面单。此件还需特殊标识，请拿起纸箱前往贴标台。")
		if tutorial_stage != 4:
			_notice("已封箱并完成地址面单。包装要求：%s。" % active_order["pack"])
		return
	if packed and not carrying:
		_pick_up()
		_notice("已拿起纸箱。")
		return
	_notice("纸箱已在手中。")

func _use_label_table() -> void:
	if active_order.is_empty() or not packed or not carrying:
		_notice("请先封箱并拿起纸箱。")
		return
	if str(active_order["mark"]) == "":
		_notice("普通包裹不需要特殊标识，可直接入库。")
		return
	if not special_done:
		special_done = true
		_update_package_label()
		if not _tutorial_notice(4, "特殊标识已完成。现在将纸箱放入与保存条件一致的空格。"):
			_notice("已加贴「%s」。可入库。" % active_order["mark"])
		return
	_notice("特殊标识已经完成。")

func _interact_slot(slot_id: String) -> void:
	var info: Dictionary = storage_slots[slot_id]
	if phase == "night":
		_load_from_slot(slot_id)
		return
	if carrying:
		if active_order.is_empty() or not labelled or (str(active_order["mark"]) != "" and not special_done):
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
		slot_orders[slot_id] = active_order.duplicate(true)
		slot_visuals[slot_id] = package_node
		active_order.clear()
		package_node = null
		package_label = null
		carrying = false
		packed = false
		labelled = false
		special_done = false
		if not _tutorial_notice(5, "首件包裹已入库。继续接收其余订单；准备好后前往下岛入口结束白天。"):
			_notice("已放入 %s。可随时从这个具体格位拿起并重新整理。" % info["kind"])
		return
	if not slot_orders.has(slot_id):
		_notice("这是空格位。拿着完成的纸箱时可放入这里。")
		return
	active_order = slot_orders[slot_id].duplicate(true)
	package_node = slot_visuals[slot_id]
	var label_node := package_node.get_node_or_null("Label3D")
	package_label = label_node as Label3D
	slot_orders.erase(slot_id)
	slot_visuals.erase(slot_id)
	packed = true
	labelled = true
	special_done = true
	_pick_up()
	_notice("已从格位拿起「%s」。可搬到另一个匹配格位继续整理。" % active_order["item"])


# =============================================================================
# 夜晚：玩家从具体格位装包，并在猫咪城镇配送。
# =============================================================================
func _use_gangway() -> void:
	if phase == "day":
		if not active_order.is_empty() or not current_customer.is_empty() or carrying:
			_notice("请先完成当前窗口订单，再决定是否结束白天。")
			return
		if slot_orders.is_empty():
			_notice("先完成至少一件包裹的入库，才能结束白天。")
			return
		_show_confirmation("要结束白天并进入夜晚装载吗？\n夜晚可从具体货架格位挑选最多 %d 件包裹带下船。" % backpack_capacity, Callable(self, "_begin_night"))
		return
	if backpack.is_empty():
		if not slot_orders.is_empty():
			_notice("请先从具体仓储格位选择包裹装入背包。")
			return
		if next_order < orders.size():
			phase = "day"
			_notice("船上还有居民的订单。白天继续接待，处理完再出航。")
			_refresh_hud()
			return
		_show_day_summary()
		return
	island_mode = true
	warned_empty_island = false
	island_layer.visible = true
	island_map.call("reset_at_dock")
	player.input_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	selected_backpack = 0
	_tutorial_notice(7, "已下岛。A/D 前往包裹面单上的收件地点，Q/E 选择背包纸箱，按 F 投递。")
	_update_island_text()

func _begin_night() -> void:
	phase = "night"
	if not _tutorial_notice(6, "夜晚开始。走到想配送的具体货架格位，按 F 把纸箱装入背包。"):
		_notice("夜晚开始。选择具体格位装入背包，再从下岛入口出发。")
	_refresh_hud()

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
		if bool(island_map.call("is_near_dock")):
			_return_to_ship()
		elif not warned_empty_island:
			warned_empty_island = true
			island_text.text = "背包里没有猫咪城镇的快递了，回到左侧码头返回邮船吧。"
		return
	var order: Dictionary = backpack[selected_backpack]
	if bool(island_map.call("is_near_recipient", str(order["recipient_id"]))):
		_deliver_order(order)
		return
	var nearby: String = str(island_map.call("nearby_stop_name"))
	if nearby != "":
		island_text.text = "这里是%s；「%s」应送往%s。" % [nearby, order["item"], order["address"]]
	else:
		island_text.text = "还没有到达收件人身边。面单地址：%s" % order["address"]

func _deliver_order(order: Dictionary) -> void:
	backpack.remove_at(selected_backpack)
	selected_backpack = max(0, selected_backpack - 1)
	var visual: Variant = order.get("visual", null)
	if visual is Node3D and is_instance_valid(visual):
		visual.queue_free()
	coins += int(order["pay"])
	town_reputation += int(order["reputation"])
	delivered_today += 1
	completed_order_ids.append(str(order["id"]))
	var npc: Dictionary = NpcData.get_npc(str(order["recipient_id"]))
	_show_dialogue([
		_line(str(npc.get("name", order["recipient"])), "%s\n\n投递完成：获得 %d 金币 · 猫咪城镇声望 +%d\n%s\n\n按 F 继续配送。" % [order["delivery_text"], order["pay"], order["reputation"], npc.get("hint", "")], npc.get("color", Color.WHITE))
	])
	_refresh_hud()
	_update_island_text()

func _return_to_ship() -> void:
	island_mode = false
	island_layer.visible = false
	player.input_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_notice("已返回邮船。")
	_refresh_hud()

func _show_day_summary() -> void:
	_show_dialogue([
		_line("第一日结算", "今日投递 %d 件，获得 %d 金币，猫咪城镇声望 %d。" % [delivered_today, coins - 35, town_reputation], Color("e4c27c")),
		_line("阿岚", "做得很好。明天还会有新的日常订单；慢慢来，这艘船会认得你的节奏。", Color("d78d48"))
	], Callable(self, "_start_next_day"))

func _start_next_day() -> void:
	day += 1
	_start_day(false)
	_notice("第 %d 天开始。猫咪城镇的居民会在你准备好时来到窗口。" % day)
	_refresh_hud()

func _start_day(first_day: bool) -> void:
	phase = "day"
	orders = OrderData.create_daily_orders()
	next_order = 0
	delivered_today = 0
	completed_order_ids.clear()
	current_customer.clear()
	active_order.clear()
	if not first_day:
		tutorial_complete = true


# =============================================================================
# 包裹实体、视图装配与输入。
# =============================================================================
func _spawn_package(world_position: Vector3, is_box: bool) -> void:
	if package_node != null and is_instance_valid(package_node):
		package_node.queue_free()
	var package := PackageView.create(self, world_position, is_box)
	package_node = package["node"]
	package_label = package["label"]

func _make_box() -> void:
	if package_node != null:
		PackageView.make_box(package_node)

func _update_package_label() -> void:
	if package_label != null and not active_order.is_empty():
		PackageView.update_label(package_label, active_order, special_done)

func _pick_up() -> void:
	if package_node != null:
		PackageView.pick_up(package_node, camera)
		carrying = true

func _place_package(position_3d: Vector3) -> void:
	if package_node != null:
		PackageView.place(package_node, self, position_3d)
	carrying = false

func _build_ship() -> void:
	player = $Player
	camera = player.camera
	for slot in get_tree().get_nodes_in_group("storage_slot"):
		storage_slots[slot.slot_id] = slot.get_slot_info()

func _build_hud() -> void:
	var nodes := GameHud.build_hud(self)
	hud = nodes["hud"]
	objective = nodes["objective"]
	prompt = nodes["prompt"]
	dialogue = nodes["dialogue"]
	dialogue_portrait = nodes["portrait"]
	dialogue_speaker = nodes["speaker"]
	dialogue_body = nodes["body"]
	dialogue_advance = nodes["advance"]
	dialogue_confirm = nodes["confirm"]
	dialogue_cancel = nodes["cancel"]
	dialogue_advance.pressed.connect(_advance_dialogue)
	dialogue_confirm.pressed.connect(_accept_confirmation)
	dialogue_cancel.pressed.connect(_cancel_confirmation)

func _build_island() -> void:
	island_layer = $IslandOverlay
	island_map = $IslandOverlay/MapViewport/IslandMap
	island_text = $IslandOverlay/IslandText
	island_layer.visible = false

func _target_id() -> String:
	return player.get_interaction_id()

func _register_input() -> void:
	var bindings := {"move_left":[KEY_A, KEY_LEFT], "move_right":[KEY_D, KEY_RIGHT], "move_forward":[KEY_W, KEY_UP], "move_back":[KEY_S, KEY_DOWN]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var input_event := InputEventKey.new()
			input_event.physical_keycode = key
			InputMap.action_add_event(action, input_event)

func _update_prompt() -> void:
	var id := _target_id()
	prompt.text = "[F] 互动" if id != "" else "WASD 移动 · 鼠标观察 · F 互动"

func _update_island_text() -> void:
	if backpack.is_empty():
		island_text.text = "背包为空，向左到码头按 F 返回邮船。"
		return
	var order: Dictionary = backpack[selected_backpack]
	var special := str(order.get("mark", ""))
	var special_text := "无特殊标识" if special == "" else "特殊标识：" + special
	island_text.text = "背包 %d/%d · Q/E 切换纸箱\n物品：%s\n收件人：%s · %s\n保存：%s · %s\n说明：%s\nA/D 移动，靠近正确地点按 F 投递。" % [backpack.size(), backpack_capacity, order["item"], order["recipient"], order["address"], order["storage"], special_text, order["description"]]

func _notice(text: String) -> void:
	objective.text = text

func _refresh_hud() -> void:
	var phase_name := "白天整理" if phase == "day" else "夜晚装载"
	hud.text = "第 %d 天 · %s · 金币 %d · 猫咪城镇声望 %d · 已入库 %d · 背包 %d/%d" % [day, phase_name, coins, town_reputation, slot_orders.size(), backpack.size(), backpack_capacity]
