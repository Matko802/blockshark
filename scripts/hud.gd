extends CanvasLayer

var main
var version_text := ""
var score_label: Label
var best_label: Label
var combo_label: Label
var gain_label: Label
var hint_label: Label
var top_box: VBoxContainer
var settings_button: Button
var restart_button: Button
var over_dim: ColorRect
var over_score: Label
var settings_dim: ColorRect
var sound_switch: CheckButton
var settings_version: Label
var update_dim: ColorRect
var update_title: Label
var update_body: Label
var update_go: Button

func setup(mn, ver: String) -> void:
	main = mn
	version_text = ver
	build()
	fit_ui()
	get_viewport().size_changed.connect(fit_ui)

func title_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func ui_scale() -> float:
	var vs := get_viewport().get_visible_rect().size
	return clampf(minf(vs.x / 720.0, vs.y / 1280.0), 0.72, 1.3)

func fit_ui() -> void:
	var s := ui_scale()
	score_label.add_theme_font_size_override("font_size", int(68.0 * s))
	gain_label.add_theme_font_size_override("font_size", int(32.0 * s))
	best_label.add_theme_font_size_override("font_size", int(24.0 * s))
	combo_label.add_theme_font_size_override("font_size", int(24.0 * s))
	hint_label.add_theme_font_size_override("font_size", int(22.0 * s))
	top_box.offset_top = 32.0 * s

func dim_layer() -> ColorRect:
	var d := ColorRect.new()
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.color = Color(0, 0, 0, 0.62)
	d.visible = false
	return d

func sheet_card() -> PanelContainer:
	var p := PanelContainer.new()
	M3Kit.style_card(p)
	return p

func sheet_title(text: String) -> Label:
	return title_label(text, 30, M3Kit.INK)

func sheet_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 24)
	b.custom_minimum_size = Vector2(240, 60)
	M3Kit.style_button(b)
	return b

func build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	top_box = VBoxContainer.new()
	top_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_box.offset_top = 36
	top_box.offset_bottom = 320
	top_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_box.add_theme_constant_override("separation", 2)
	root.add_child(top_box)
	score_label = title_label("0", 68, M3Kit.INK)
	top_box.add_child(score_label)
	gain_label = title_label("", 32, M3Kit.ACCENT)
	gain_label.modulate = Color(1, 1, 1, 0)
	top_box.add_child(gain_label)
	var best_row := HBoxContainer.new()
	best_row.alignment = BoxContainer.ALIGNMENT_CENTER
	best_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	best_row.add_theme_constant_override("separation", 6)
	top_box.add_child(best_row)
	best_row.add_child(M3Kit.icon_label("star", 26, M3Kit.GOLD))
	best_label = title_label("BEST 0", 24, M3Kit.INK_DIM)
	best_row.add_child(best_label)
	combo_label = title_label("", 24, M3Kit.GOLD)
	top_box.add_child(combo_label)
	var left_box := HBoxContainer.new()
	left_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left_box.offset_left = 16
	left_box.offset_top = 36
	left_box.offset_right = 80
	left_box.offset_bottom = 100
	left_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left_box)
	settings_button = M3Kit.icon_button("settings", 30)
	settings_button.pressed.connect(show_settings)
	left_box.add_child(settings_button)
	var right_box := HBoxContainer.new()
	right_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_box.offset_left = -80
	right_box.offset_top = 36
	right_box.offset_right = -16
	right_box.offset_bottom = 100
	right_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right_box)
	restart_button = M3Kit.icon_button("refresh", 30)
	restart_button.pressed.connect(main.restart_game)
	right_box.add_child(restart_button)
	hint_label = title_label("Drag blocks onto the board", 22, M3Kit.INK_DIM)
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 16
	hint_label.offset_right = -16
	hint_label.offset_top = -96
	hint_label.offset_bottom = -64
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint_label)
	build_settings(root)
	build_update(root)
	build_over(root)

func build_settings(root: Control) -> void:
	settings_dim = dim_layer()
	root.add_child(settings_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_dim.add_child(center)
	var card := sheet_card()
	center.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	box.add_child(sheet_title("Settings"))
	var sound_row := HBoxContainer.new()
	sound_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sound_row.add_theme_constant_override("separation", 12)
	box.add_child(sound_row)
	sound_row.add_child(M3Kit.icon_label("volume_up", 30, M3Kit.INK))
	var sound_label := title_label("Sound", 24, M3Kit.INK)
	sound_row.add_child(sound_label)
	sound_switch = CheckButton.new()
	sound_switch.toggled.connect(main.set_sound_enabled)
	sound_row.add_child(sound_switch)
	var update_button := sheet_button("Check for updates")
	update_button.pressed.connect(main.check_updates)
	box.add_child(update_button)
	settings_version = title_label(version_text, 18, M3Kit.INK_DIM)
	box.add_child(settings_version)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.add_theme_font_size_override("font_size", 24)
	M3Kit.style_text_button(close_button)
	close_button.pressed.connect(hide_settings)
	box.add_child(close_button)

func build_update(root: Control) -> void:
	update_dim = dim_layer()
	root.add_child(update_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	update_dim.add_child(center)
	var card := sheet_card()
	center.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)
	update_title = sheet_title("Update")
	box.add_child(update_title)
	update_body = title_label("", 22, M3Kit.INK_DIM)
	update_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	update_body.custom_minimum_size = Vector2(420, 0)
	box.add_child(update_body)
	update_go = sheet_button("Download")
	update_go.pressed.connect(_on_update_go)
	box.add_child(update_go)
	var later := Button.new()
	later.text = "Later"
	later.add_theme_font_size_override("font_size", 24)
	M3Kit.style_text_button(later)
	later.pressed.connect(hide_update)
	box.add_child(later)

func build_over(root: Control) -> void:
	over_dim = dim_layer()
	root.add_child(over_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_dim.add_child(center)
	var panel := sheet_card()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(M3Kit.icon_label("trophy", 64, M3Kit.GOLD))
	box.add_child(sheet_title("GAME OVER"))
	over_score = title_label("", 28, M3Kit.INK_DIM)
	box.add_child(over_score)
	var again := sheet_button("Play Again")
	again.pressed.connect(main.restart_game)
	box.add_child(again)

func refresh(score: int, best: int, combo: int) -> void:
	score_label.text = str(score)
	best_label.text = "BEST " + str(best)
	if combo > 0:
		combo_label.text = "COMBO x" + str(combo)
	else:
		combo_label.text = ""

func show_gain(gained: int) -> void:
	gain_label.text = "+" + str(gained)
	gain_label.modulate = Color(1, 1, 1, 1)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(gain_label, "modulate:a", 0.0, 0.9).set_delay(0.25)

func show_over(score: int, best: int) -> void:
	over_score.text = "Score " + str(score) + "   Best " + str(best)
	over_dim.visible = true

func hide_over() -> void:
	over_dim.visible = false

func set_muted(m: bool) -> void:
	sound_switch.set_pressed_no_signal(not m)

func show_settings() -> void:
	settings_version.text = version_text
	settings_dim.visible = true

func hide_settings() -> void:
	settings_dim.visible = false

func show_update_dialog(title: String, body: String, primary_text: String, show_primary: bool) -> void:
	update_title.text = title
	update_body.text = body
	update_go.text = primary_text
	update_go.visible = show_primary
	update_dim.visible = true

func hide_update() -> void:
	update_dim.visible = false

func _on_update_go() -> void:
	main.updater.on_primary()
