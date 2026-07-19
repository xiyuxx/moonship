## 斜俯视 2D 船舱原型：保留订单与投递循环，移除 3D 相机和射线交互。
extends Node2D

const GameHud = preload("res://scripts/ui/game_hud.gd")
const PackageView = preload("res://scripts/views/package_view_2d.gd")
const NpcData = preload("res://scripts/data/npc_data.gd")

var orders: Array[Dictionary] = []
var day := 1
var phase := "day"
var coins := 35
var town_reputation := 0
var next_order := 0
var delivered_today := 0
var current_customer: Dictionary = {}
var active_order: Dictionary = {}
var carrying := false
var packed := false
var special_done := false
var package_node: Node2D
var package_label: Label
var player: CharacterBody2D
var interactions := {}
var storage_slots := {}
var slot_orders := {}
var slot_visuals := {}
var backpack: Array[Dictionary] = []
var backpack_capacity := 2
var selected_backpack := 0
var island_mode := false
var hud: Label
var objective: Label
var prompt: Label
var dialogue: PanelContainer
var dialogue_portrait: ColorRect
var dialogue_speaker: Label
var dialogue_body: Label
var dialogue_advance: Button
var dialogue_confirm: Button
var dialogue_cancel: Button
var island_layer: CanvasLayer
var island_map: Node2D
var island_text: Label
var dialogue_lines: Array[Dictionary] = []
var dialogue_index := 0
var dialogue_callback := Callable()
var confirm_callback := Callable()
var dialogue_mode := ""
var dialogue_active := false

func _ready() -> void:
	_register_input()
	player = $Player
	player.interact_requested.connect(_interact_nearest)
	_build_ship_layout()
	_build_hud()
	island_layer = $IslandOverlay
	island_map = $IslandOverlay/MapViewport/IslandMap
	island_text = $IslandOverlay/IslandText
	island_layer.visible = false
	_start_day()
	_refresh_hud()
	_show_dialogue([_line("阿岚", "欢迎来到月光邮船。先走到任一取件窗口，按 F 接待我。", Color("d78d48"))])

func _process(delta: float) -> void:
	if dialogue_active: return
	if island_mode:
		island_map.call("move", Input.get_axis("move_left", "move_right"), delta)
		_update_island_text()
		return
	_update_prompt()

func _input(event: InputEvent) -> void:
	if dialogue_active and event is InputEventKey and event.pressed:
		if event.keycode in [KEY_F, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			if dialogue_mode == "lines": _advance_dialogue()
			else: _accept_confirmation()
		return
	if island_mode and event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q and not backpack.is_empty(): selected_backpack = posmod(selected_backpack - 1, backpack.size())
		elif event.keycode == KEY_E and not backpack.is_empty(): selected_backpack = posmod(selected_backpack + 1, backpack.size())
		elif event.keycode == KEY_F: _island_interact()

func _build_ship_layout() -> void:
	_add_station("counter_left", "取件窗口 · 左", Vector2(160, 200), Vector2(130, 82), Color("dbc093"))
	_add_station("counter_middle", "取件窗口 · 中", Vector2(305, 200), Vector2(130, 82), Color("dbc093"))
	_add_station("counter_right", "取件窗口 · 右", Vector2(450, 200), Vector2(130, 82), Color("dbc093"))
	_add_station("packing", "打包台", Vector2(660, 203), Vector2(180, 88), Color("d59f61"))
	_add_station("label", "贴标台", Vector2(875, 203), Vector2(180, 88), Color("9fbf9a"))
	_add_station("gangway", "下岛入口", Vector2(126, 570), Vector2(130, 76), Color("91a6b9"))
	var ambient := [Vector2(275, 512), Vector2(390, 512), Vector2(505, 512), Vector2(275, 594), Vector2(390, 594), Vector2(505, 594)]
	for i in ambient.size(): _add_slot("常温货架_%d" % (i + 1), "常温货架", ambient[i])
	_add_slot("冷冻室_1", "冷冻室", Vector2(755, 522))
	_add_slot("冷冻室_2", "冷冻室", Vector2(755, 606))
	_add_station("freezer_door", "冷冻室 · 扩建门", Vector2(960, 490), Vector2(170, 70), Color("83b6c8"))
	_add_station("greenhouse_door", "温室 · 扩建门", Vector2(960, 590), Vector2(170, 70), Color("a5c991"))

func _add_station(id: String, title: String, position_2d: Vector2, size: Vector2, color: Color) -> void:
	interactions[id] = {"position": position_2d, "radius": maxf(size.x, size.y) * 0.72}
	var panel := Polygon2D.new()
	panel.polygon = PackedVector2Array([position_2d + Vector2(-size.x/2,-size.y/2), position_2d + Vector2(size.x/2,-size.y/2), position_2d + Vector2(size.x/2,size.y/2), position_2d + Vector2(-size.x/2,size.y/2)])
	panel.color = color
	panel.z_index = int(position_2d.y) - 30
	$ShipCabin.add_child(panel)
	var label := Label.new()
	label.text = title
	label.position = position_2d + Vector2(-size.x/2, -10)
	label.size = Vector2(size.x, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.z_index = int(position_2d.y) - 28
	$ShipCabin.add_child(label)

func _add_slot(id: String, kind: String, position_2d: Vector2) -> void:
	storage_slots[id] = {"kind": kind, "position": position_2d}
	_add_station("slot:" + id, kind + "\n" + id.get_slice("_", -1), position_2d, Vector2(96, 66), Color("c69662") if kind == "常温货架" else Color("8dbdcd"))

func _interact_nearest() -> void:
	var best := ""
	var distance := INF
	for id in interactions:
		var d: float = player.position.distance_to(interactions[id]["position"])
		if d < interactions[id]["radius"] and d < distance: best = id; distance = d
	if best == "": _notice("靠近工作台、货架或下岛入口后按 F。")
	elif best.begins_with("slot:"): _interact_slot(best.trim_prefix("slot:"))
	elif best.begins_with("counter_"): _use_counter(best)
	elif best == "packing": _use_packing()
	elif best == "label": _use_label()
	elif best == "gangway": _use_gangway()
	else: _notice("这是一扇预留的扩建门。冷冻室与温室将在后续升级后开放。")
	_refresh_hud()

func _use_counter(id: String) -> void:
	if not active_order.is_empty():
		if not carrying and not packed and active_order.get("counter_id") == id: _pick_up(); _notice("已拿起物品，前往打包台。")
		else: _notice("请先完成手中的订单。")
		return
	if current_customer.is_empty():
		if next_order >= orders.size(): _notice("今日没有新的来件。请整理已入库的包裹。"); return
		current_customer = orders[next_order].duplicate(true); current_customer["counter_id"] = id; next_order += 1
		var npc := NpcData.get_npc(str(current_customer["sender_id"]))
		_show_dialogue([_line(str(npc.get("name", "居民")), str(current_customer["sender_text"]), npc.get("color", Color.WHITE)), _line("订单信息", "%s\n%s\n报酬 %d 金币" % [current_customer["item"], current_customer["description"], current_customer["pay"]], Color("e4c27c"))])
		_notice("对话结束后再次按 F 接单。")
		return
	if current_customer.get("counter_id") != id: _notice("客户在另一扇窗口等候。 "); return
	active_order = current_customer.duplicate(true); current_customer.clear()
	_spawn_package(interactions[id]["position"] + Vector2(0, 46), false)
	_notice("已接单；再次按 F 拿起物品。")

func _use_packing() -> void:
	if active_order.is_empty(): _notice("请先在窗口接单。"); return
	if not carrying and not packed: _notice("请回到领取窗口拿起物品。"); return
	if carrying and not packed:
		packed = true; special_done = str(active_order["mark"]) == ""; _place_package(interactions["packing"]["position"] + Vector2(0, 46)); _update_package_label(); _notice("已封箱。%s" % ("前往贴标台。" if not special_done else "拿起纸箱后放入对应货架。")); return
	if packed and not carrying: _pick_up(); _notice("已拿起纸箱。")

func _use_label() -> void:
	if active_order.is_empty() or not packed or not carrying: _notice("请先封箱并拿起纸箱。"); return
	if str(active_order["mark"]) == "": _notice("普通包裹不需特殊标识。"); return
	special_done = true; _update_package_label(); _notice("已加贴「%s」，可入库。" % active_order["mark"])

func _interact_slot(id: String) -> void:
	var info: Dictionary = storage_slots[id]
	if phase == "night": _load_from_slot(id); return
	if carrying:
		if active_order.is_empty() or (str(active_order["mark"]) != "" and not special_done): _notice("纸箱尚未完成贴标。"); return
		if info["kind"] != active_order["storage"]: _notice("该格位属于%s；此包裹需要%s。" % [info["kind"], active_order["storage"]]); return
		if slot_orders.has(id): _notice("这个格位已有包裹。"); return
		_place_package(info["position"]); slot_orders[id] = active_order.duplicate(true); slot_visuals[id] = package_node
		active_order.clear(); package_node = null; package_label = null; carrying = false; packed = false; special_done = false; _notice("已入库。可继续接单，或前往下岛入口。")
	elif slot_orders.has(id):
		active_order = slot_orders[id].duplicate(true); package_node = slot_visuals[id]; package_label = package_node.get_node("Label"); slot_orders.erase(id); slot_visuals.erase(id); packed = true; special_done = true; _pick_up(); _notice("已从货架拿起纸箱。")
	else: _notice("这是空格位。")

func _use_gangway() -> void:
	if phase == "day":
		if not active_order.is_empty() or not current_customer.is_empty() or carrying: _notice("请先完成当前订单。"); return
		if slot_orders.is_empty(): _notice("至少完成一件入库后才能出航。"); return
		_show_confirmation("结束白天，进入夜晚装载？\n可从具体货架选择最多 %d 件包裹。" % backpack_capacity, Callable(self, "_begin_night")); return
	if backpack.is_empty():
		if not slot_orders.is_empty(): _notice("先从具体货架选择包裹装入背包。"); return
		if next_order < orders.size(): phase = "day"; _notice("还有订单，白天继续。"); return
		_start_next_day(); return
	island_mode = true; island_layer.visible = true; island_map.call("reset_at_dock"); player.input_enabled = false; selected_backpack = 0; _update_island_text()

func _begin_night() -> void: phase = "night"; _notice("夜晚开始。到具体货架按 F 装入背包。 "); _refresh_hud()
func _load_from_slot(id: String) -> void:
	if not slot_orders.has(id): _notice("这个格位是空的。"); return
	if backpack.size() >= backpack_capacity: _notice("背包已满。"); return
	var order: Dictionary = slot_orders[id]; var visual: Node2D = slot_visuals[id]; slot_orders.erase(id); slot_visuals.erase(id); visual.visible = false; order["visual"] = visual; backpack.append(order); _notice("已装入「%s」（%d/%d）。" % [order["item"], backpack.size(), backpack_capacity])

func _island_interact() -> void:
	if backpack.is_empty():
		if bool(island_map.call("is_near_dock")): _return_to_ship()
		return
	var order: Dictionary = backpack[selected_backpack]
	if bool(island_map.call("is_near_recipient", str(order["recipient_id"]))):
		backpack.remove_at(selected_backpack); selected_backpack = max(0, selected_backpack - 1); var visual = order.get("visual"); if visual is Node2D and is_instance_valid(visual): visual.queue_free()
		coins += int(order["pay"]); town_reputation += int(order["reputation"]); delivered_today += 1
		var npc := NpcData.get_npc(str(order["recipient_id"])); _show_dialogue([_line(str(npc.get("name", order["recipient"])), "%s\n\n获得 %d 金币 · 声望 +%d" % [order["delivery_text"], order["pay"], order["reputation"]], npc.get("color", Color.WHITE))]); _refresh_hud()
	else: island_text.text = "还没有到达收件人身边。面单地址：%s" % order["address"]

func _return_to_ship() -> void: island_mode = false; island_layer.visible = false; player.input_enabled = true; _notice("已返回邮船。")
func _start_next_day() -> void: day += 1; _start_day(); _notice("第 %d 天开始。" % day); _refresh_hud()
func _start_day() -> void: phase = "day"; orders = OrderData.create_daily_orders(); next_order = 0; delivered_today = 0; current_customer.clear(); active_order.clear()
func _spawn_package(pos: Vector2, box: bool) -> void: var package := PackageView.create($Packages, pos, box); package_node = package["node"]; package_label = package["label"]
func _update_package_label() -> void: if package_label != null: PackageView.update_label(package_label, active_order, special_done)
func _pick_up() -> void: if package_node != null: PackageView.pick_up(package_node, player); carrying = true
func _place_package(pos: Vector2) -> void: if package_node != null: PackageView.place(package_node, $Packages, pos); carrying = false
func _register_input() -> void:
	for name in {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN]}:
		if not InputMap.has_action(name): InputMap.add_action(name)
		for key in {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN]}[name]: var e := InputEventKey.new(); e.physical_keycode = key; InputMap.action_add_event(name,e)
func _build_hud() -> void:
	var nodes := GameHud.build_hud(self); hud = nodes["hud"]; objective = nodes["objective"]; prompt = nodes["prompt"]; dialogue = nodes["dialogue"]; dialogue_portrait = nodes["portrait"]; dialogue_speaker = nodes["speaker"]; dialogue_body = nodes["body"]; dialogue_advance = nodes["advance"]; dialogue_confirm = nodes["confirm"]; dialogue_cancel = nodes["cancel"]; dialogue_advance.pressed.connect(_advance_dialogue); dialogue_confirm.pressed.connect(_accept_confirmation); dialogue_cancel.pressed.connect(_hide_dialogue)
func _update_prompt() -> void: prompt.text = "WASD 移动 · 靠近设施按 F 互动"
func _update_island_text() -> void:
	if backpack.is_empty(): island_text.text = "背包为空，向左到码头按 F 返回邮船。"; return
	var o: Dictionary = backpack[selected_backpack]; island_text.text = "背包 %d/%d · Q/E 切换\n物品：%s\n收件人：%s · %s\nA/D 移动，靠近正确地点按 F 投递。" % [backpack.size(), backpack_capacity, o["item"], o["recipient"], o["address"]]
func _refresh_hud() -> void: hud.text = "第 %d 天 · %s · 金币 %d · 猫咪城镇声望 %d · 已入库 %d · 背包 %d/%d" % [day, "白天整理" if phase == "day" else "夜晚装载", coins, town_reputation, slot_orders.size(), backpack.size(), backpack_capacity]
func _notice(text: String) -> void: objective.text = text
func _line(s: String, t: String, c: Color) -> Dictionary: return {"speaker":s,"text":t,"color":c}
func _show_dialogue(lines: Array[Dictionary]) -> void: dialogue_lines = lines; dialogue_index = 0; dialogue_mode = "lines"; dialogue_active = true; player.input_enabled = false; dialogue.visible = true; dialogue_advance.visible = true; dialogue_confirm.visible = false; dialogue_cancel.visible = false; _render_dialogue()
func _show_confirmation(text: String, confirmed: Callable) -> void: dialogue_mode = "confirm"; dialogue_active = true; player.input_enabled = false; dialogue.visible = true; dialogue_speaker.text = "夜晚航程确认"; dialogue_portrait.color = Color("e4c27c"); dialogue_body.text = text; dialogue_advance.visible = false; dialogue_confirm.visible = true; dialogue_cancel.visible = true; confirm_callback = confirmed
func _render_dialogue() -> void: var line: Dictionary = dialogue_lines[dialogue_index]; dialogue_speaker.text = line["speaker"]; dialogue_body.text = line["text"]; dialogue_portrait.color = line["color"]
func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_render_dialogue()
	else:
		_hide_dialogue()
func _accept_confirmation() -> void: var cb := confirm_callback; _hide_dialogue(); if cb.is_valid(): cb.call()
func _hide_dialogue() -> void: dialogue_active = false; dialogue.visible = false; if not island_mode: player.input_enabled = true
