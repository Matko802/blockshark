extends RefCounted
class_name M3Kit

const ICON_FONT: FontFile = preload("res://assets/icons/SharkIcons.ttf")

const INK = Color(0.92, 0.94, 1.0)
const INK_DIM = Color(0.68, 0.72, 0.85)
const TONAL = Color(0.17, 0.20, 0.34)
const TONAL_HOVER = Color(0.23, 0.27, 0.44)
const TONAL_DOWN = Color(0.12, 0.14, 0.26)
const ACCENT = Color(0.55, 0.81, 1.0)
const GOLD = Color(1.0, 0.80, 0.30)
const CARD = Color(0.09, 0.11, 0.21, 0.97)

const GLYPHS = {
	"settings": 0xe8b8,
	"refresh": 0xe5d5,
	"volume_up": 0xe050,
	"volume_off": 0xe04f,
	"star": 0xe838,
	"trophy": 0xea65,
	"download": 0xe2c0,
	"close": 0xe5cd,
	"check": 0xe5ca,
	"info": 0xe88e,
	"update": 0xe923,
	"rocket": 0xe62e,
}

static func glyph(glyph_name: String) -> String:
	return String.chr(int(GLYPHS.get(glyph_name, 0xe88e)))

static func icon_label(glyph_name: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = glyph(glyph_name)
	l.add_theme_font_override("font", ICON_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func pill(bg: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(12)
	return sb

static func style_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", pill(TONAL, 20))
	b.add_theme_stylebox_override("hover", pill(TONAL_HOVER, 20))
	b.add_theme_stylebox_override("pressed", pill(TONAL_DOWN, 20))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK_DIM)
	b.focus_mode = Control.FOCUS_NONE

static func style_text_button(b: Button) -> void:
	var e := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", e)
	b.add_theme_stylebox_override("hover", e)
	b.add_theme_stylebox_override("pressed", e)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", ACCENT)
	b.add_theme_color_override("font_hover_color", INK)
	b.focus_mode = Control.FOCUS_NONE

static func icon_button(glyph_name: String, size: int) -> Button:
	var b := Button.new()
	b.text = glyph(glyph_name)
	b.add_theme_font_override("font", ICON_FONT)
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(56, 56)
	b.add_theme_stylebox_override("normal", pill(TONAL, 28))
	b.add_theme_stylebox_override("hover", pill(TONAL_HOVER, 28))
	b.add_theme_stylebox_override("pressed", pill(TONAL_DOWN, 28))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.focus_mode = Control.FOCUS_NONE
	return b

static func style_card(p: PanelContainer, radius: int = 24) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(28)
	p.add_theme_stylebox_override("panel", sb)
