extends CanvasLayer

var main
var score_label: Label
var best_label: Label
var combo_label: Label
var gain_label: Label
var hint_label: Label
var top_box: VBoxContainer
var buttons_row: HBoxContainer
var restart_button: Button
var over_dim: ColorRect
var over_score: Label
var mute_button: Button

func setup(mn) -> void:
	main = mn
	build()
	fit_ui()
	get_viewport().size_changed.connect(fit_ui)

func ui_scale() -> float:
	var vs := get_viewport().get_visible_rect().size
	return clampf(minf(vs.x / 720.0, vs.y / 1280.0), 0.72, 1.3)

func fit_ui() -> void:
	var s := ui_scale()
	score_label.add_theme_font_size_override("font_size", int(76.0 * s))
	gain_label.add_theme_font_size_override("font_size", int(34.0 * s))
	best_label.add_theme_font_size_override("font_size", int(26.0 * s))
	combo_label.add_theme_font_size_override("font_size", int(26.0 * s))
	hint_label.add_theme_font_size_override("font_size", int(24.0 * s))
	mute_button.add_theme_font_size_override("font_size", int(22.0 * s))
	restart_button.add_theme_font_size_override("font_size", int(22.0 * s))
	top_box.offset_top = 36.0 * s
	buttons_row.offset_top = 36.0 * s
	buttons_row.offset_right = -16.0 * s
	hint_label.offset_top = -100.0 * s
	hint_label.offset_bottom = -64.0 * s

func big_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	top_box = VBoxContainer.new()
	top_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_box.offset_top = 40
	top_box.offset_bottom = 320
	top_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_box.add_theme_constant_override("separation", 2)
	root.add_child(top_box)
	var top: VBoxContainer = top_box
	score_label = big_label("0", 76, Color.WHITE)
	top.add_child(score_label)
	gain_label = big_label("", 34, Color(0.45, 0.85, 1.0))
	gain_label.modulate = Color(1, 1, 1, 0)
	top.add_child(gain_label)
	best_label = big_label("BEST 0", 26, Color(0.75, 0.78, 0.9))
	top.add_child(best_label)
	combo_label = big_label("", 26, Color(1.0, 0.8, 0.3))
	top.add_child(combo_label)
	buttons_row = HBoxContainer.new()
	buttons_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	buttons_row.offset_left = -260
	buttons_row.offset_top = 40
	buttons_row.offset_right = -16
	buttons_row.offset_bottom = 110
	buttons_row.add_theme_constant_override("separation", 12)
	root.add_child(buttons_row)
	var row: HBoxContainer = buttons_row
	mute_button = Button.new()
	mute_button.text = "Sound On"
	mute_button.add_theme_font_size_override("font_size", 22)
	mute_button.pressed.connect(main.toggle_mute)
	row.add_child(mute_button)
	restart_button = Button.new()
	restart_button.text = "Restart"
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.pressed.connect(main.restart_game)
	row.add_child(restart_button)
	hint_label = big_label("Drag blocks onto the board", 24, Color(0.6, 0.64, 0.78))
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 16
	hint_label.offset_right = -16
	hint_label.offset_top = -100
	hint_label.offset_bottom = -64
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(hint_label)
	over_dim = ColorRect.new()
	over_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_dim.color = Color(0, 0, 0, 0.62)
	over_dim.visible = false
	root.add_child(over_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_dim.add_child(center)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.12, 0.97)
	sb.set_corner_radius_all(24)
	sb.set_content_margin_all(36)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := big_label("GAME OVER", 52, Color.WHITE)
	box.add_child(title)
	over_score = big_label("", 30, Color(0.8, 0.83, 0.95))
	box.add_child(over_score)
	var again := Button.new()
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(260, 72)
	again.add_theme_font_size_override("font_size", 30)
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
	if m:
		mute_button.text = "Muted"
	else:
		mute_button.text = "Sound On"
