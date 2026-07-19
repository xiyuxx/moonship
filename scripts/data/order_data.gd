## 首章固定订单。下一阶段可在此基础上加入日常随机池。
class_name OrderData
extends RefCounted

const NpcData = preload("res://scripts/data/npc_data.gd")

static func create_daily_orders() -> Array[Dictionary]:
	return [
		_order("aran_intro", "阿岚的留声机发条盒", "aran", "bello", "猫咪城镇 · 钟楼顶层", "木箱", "常温货架", "易碎", 30, 4, "爷爷的老顾客阿岚，请你将修好的发条盒送去钟楼。"),
		_order("luna_flowers", "城镇花店鲜花束", "luna", "luna", "猫咪城镇 · 钟楼街图书室", "纸箱", "温室", "", 22, 2, "米粒托邮船送来的鲜花，要在图书室窗边摆上一天。"),
		_order("noah_roll", "面包房奶油卷", "noah", "noah", "猫咪城镇 · 彩线巷裁缝店", "纸箱", "常温货架", "", 16, 2, "刚出炉的奶油卷，是忙碌的裁缝给自己留的午餐。"),
		_order("bello_gears", "修表铺齿轮盒", "bello", "bello", "猫咪城镇 · 钟楼顶层", "木箱", "常温货架", "易碎", 28, 3, "钟楼备用齿轮，得在夜间报时前送到。"),
		_order("youyou_cloth", "裁缝店布料卷", "youyou", "youyou", "猫咪城镇 · 喷泉广场剧团", "纸箱", "常温货架", "防潮", 20, 2, "剧团明晚演出的幕布补料，不能被潮气毁了。"),
		_order("anmian_medicine", "药房冷藏药剂", "anmian", "anmian", "猫咪城镇 · 港口诊所", "保温箱", "冷冻室", "冷藏急件", 34, 3, "诊所需要的冷藏药剂，阿棉特别交代过保存温度。"),
		_order("yunjie_teapot", "陶艺店上釉茶壶", "yunjie", "yunjie", "猫咪城镇 · 石板街潮汐壶茶馆", "木箱", "常温货架", "易碎", 30, 3, "给茶馆的新茶壶，今晚会迎来第一壶热茶。"
		)
	]

static func _order(id: String, item: String, sender_id: String, recipient_id: String, address: String, pack: String, storage: String, mark: String, pay: int, reputation: int, description: String) -> Dictionary:
	var sender: Dictionary = NpcData.get_npc(sender_id)
	var recipient: Dictionary = NpcData.get_npc(recipient_id)
	return {"id": id, "item": item, "sender_id": sender_id, "recipient_id": recipient_id, "sender": sender.get("name", "居民"), "recipient": recipient.get("name", "居民"), "address": address, "pack": pack, "storage": storage, "mark": mark, "pay": pay, "reputation": reputation, "origin": "猫咪城镇", "description": description, "sender_text": sender.get("receive", "麻烦你了。"), "delivery_text": recipient.get("deliver", "谢谢你送来包裹。"), "completed": false}