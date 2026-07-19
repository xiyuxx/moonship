## HUD、对话框与猫咪城镇覆盖层。
class_name GameHud
extends RefCounted

const IslandView = preload("res://scripts/views/island_view.gd")

static func build_hud(root: Node) -> Dictionary:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var top := ColorRect.new()
	top.color = Color(0.04, 0.08, 0.14, 0.88)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 138
	layer.add_child(top)
	var hud := Label.new()
	hud.position = Vector2(28, 18)
	hud.add_theme_font_size_override("font_size", 22)
	top.add_child(hud)
	var objective := Label.new()
	objective.position = Vector2(28, 56)
	objective.size = Vector2(1120, 74)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_size_override("font_size", 17)
	top.add_child(objective)
	var prompt := Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.position.y = -65
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 18)
	layer.add_child(prompt)

	var dialogue := PanelContainer.new()
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue.offset_left = 80
	dialogue.offset_right = -80
	dialogue.offset_top = -245
	dialogue.offset_bottom = -82
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.11, 0.18, 0.96)
	style.border_color = Color("e4c27c")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	dialogue.add_theme_stylebox_override("panel", style)
	layer.add_child(dialogue)
	var row := HBoxContainer.new()
	dialogue.add_child(row)
	var portrait := ColorRect.new()
	portrait.custom_minimum_size = Vector2(102, 102)
	portrait.color = Color("d78d48")
	row.add_child(portrait)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	var speaker := Label.new()
	speaker.add_theme_font_size_override("font_size", 22)
	text_column.add_child(speaker)
	var body := Label.new()
	body.custom_minimum_size = Vector2(0, 62)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	text_column.add_child(body)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	text_column.add_child(actions)
	var advance := Button.new()
	advance.text = "继续  [F / 空格 / 回车]"
	actions.add_child(advance)
	var confirm := Button.new()
	confirm.text = "确认"
	actions.add_child(confirm)
	var cancel := Button.new()
	cancel.text = "取消"
	actions.add_child(cancel)
	dialogue.visible = false
	return {"hud":hud, "objective":objective, "prompt":prompt, "dialogue":dialogue, "portrait":portrait, "speaker":speaker, "body":body, "advance":advance, "confirm":confirm, "cancel":cancel}

static func build_island(root: Node) -> Dictionary:
	var layer := CanvasLayer.new()
	layer.layer = 0
	root.add_child(layer)
	var map := IslandView.new()
	layer.add_child(map)
	var text := Label.new()
	text.position = Vector2(35, 25)
	text.size = Vector2(1120, 170)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 20)
	layer.add_child(text)
	layer.visible = false
	return {"layer":layer, "map":map, "text":text}