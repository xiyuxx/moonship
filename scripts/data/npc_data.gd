## 猫咪城镇 NPC 的静态资料与首章对话文本。
class_name NpcData
extends RefCounted

const NPCS := {
	"aran": {"name":"阿岚", "role":"旧唱片与留声机修理铺主人", "color":Color("d78d48"), "place":"港口唱片铺", "personality":"温和、讲究、记性极好", "hint":"他保留着爷爷年轻时寄来的第一张明信片。", "receive":"这枚发条盒麻烦你送到钟楼。你爷爷总说，信要送到人手里，才算真正离开了船。", "deliver":"谢谢。船上的灯还亮着，阿岚会很安心。"},
	"luna": {"name":"露娜", "role":"图书管理员", "color":Color("b9b6c7"), "place":"钟楼街图书室", "personality":"克制、细心、轻微怕生", "hint":"她一直为一位远行朋友留着靠窗的空桌。", "receive":"压花书签请放平些，花瓣一折，就像故事少了一页。", "deliver":"花束到了。图书室今天正好需要一点颜色。"},
	"noah": {"name":"诺亚", "role":"裁缝", "color":Color("37343c"), "place":"彩线巷裁缝店", "personality":"直率、嘴硬心软", "hint":"他总在为森林里的妹妹准备合身的旅行斗篷。", "receive":"线轴别受潮，我可不想和打结的线较劲。", "deliver":"来得正好，这卷布能赶上明天的修改。谢了。"},
	"bello": {"name":"贝洛", "role":"钟楼管理员", "color":Color("c89955"), "place":"钟楼顶层", "personality":"严谨、略显古板", "hint":"钟楼每晚慢的一分钟，藏着他不愿改掉的旧习惯。", "receive":"齿轮盒要稳，钟可不喜欢一路颠簸。", "deliver":"很好。准时不是急着赶路，是让等你的人知道你会来。"},
	"youyou": {"name":"悠悠", "role":"小剧团领班", "color":Color("e0a0a0"), "place":"喷泉广场剧团", "personality":"热情、爱夸张、擅长带动气氛", "hint":"她仍在寻找老戏《月光邮船》缺失的最后一页。", "receive":"节目单请别压出折痕，它们今晚也要上台的！", "deliver":"太好了！哪怕只有一位观众，舞台也该亮起来。"},
	"anmian": {"name":"阿棉", "role":"港口医师", "color":Color("f2f1e8"), "place":"港口诊所", "personality":"冷静、利落、关心藏在叮嘱里", "hint":"她定期为北礁灯塔的一位老人准备药品。", "receive":"冷藏药剂别在甲板上晒着。海风不管它是不是急件。", "deliver":"温度没问题。谢谢你，病人会少等一会儿。"},
	"yunjie": {"name":"芸姐", "role":"潮汐壶茶馆主人", "color":Color("8d654c"), "place":"石板街潮汐壶茶馆", "personality":"圆融、善于倾听", "hint":"她替许多人代收暂时不想面对的信。", "receive":"茶壶劳烦轻放。它听得见一路的颠簸。", "deliver":"正好赶上晚茶。寄信的人未必想要答案，有时只想让话有个去处。"}
}

static func get_npc(id: String) -> Dictionary:
	return NPCS.get(id, {})