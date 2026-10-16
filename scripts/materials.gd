extends RefCounted
class_name Mats

const STONE: Texture2D = preload("res://assets/textures/stone.png")
const BEDROCK: Texture2D = preload("res://assets/textures/bedrock.png")
const GRASS: Texture2D = preload("res://assets/textures/grass_top.png")
const BOARD_TEX: Texture2D = preload("res://assets/textures/board_grass.png")

const COLORS = [
	Color(0.94, 0.27, 0.27),
	Color(0.98, 0.45, 0.09),
	Color(0.98, 0.80, 0.08),
	Color(0.13, 0.77, 0.37),
	Color(0.08, 0.72, 0.65),
	Color(0.23, 0.51, 0.96),
	Color(0.66, 0.33, 0.97),
	Color(0.93, 0.28, 0.60),
]

static var _box: BoxMesh
static var _mats: Array = []
static var _ghost_mats: Array = []
static var _empty_mat: StandardMaterial3D
static var _board_mat: StandardMaterial3D
static var _ghost_bad: StandardMaterial3D
static var _ghost_grey: StandardMaterial3D
static var _base_mat: StandardMaterial3D

static func box() -> BoxMesh:
	if _box == null:
		_box = BoxMesh.new()
		_box.size = Vector3.ONE
	return _box

static func for_color(i: int) -> StandardMaterial3D:
	while _mats.size() <= i:
		_mats.append(null)
	if _mats[i] == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = COLORS[i % COLORS.size()]
		m.albedo_texture = STONE
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		m.roughness = 0.35
		m.metallic = 0.05
		_mats[i] = m
	return _mats[i]

static func ghost_color(i: int) -> StandardMaterial3D:
	while _ghost_mats.size() <= i:
		_ghost_mats.append(null)
	if _ghost_mats[i] == null:
		var m := StandardMaterial3D.new()
		var c: Color = COLORS[i % COLORS.size()]
		c.a = 0.5
		m.albedo_color = c
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.5
		_ghost_mats[i] = m
	return _ghost_mats[i]

static func unique_color(i: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = COLORS[i % COLORS.size()]
	m.albedo_texture = STONE
	m.uv1_scale = Vector3(0.5, 0.5, 0.5)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = 0.35
	m.metallic = 0.05
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func empty() -> StandardMaterial3D:
	if _empty_mat == null:
		_empty_mat = StandardMaterial3D.new()
		_empty_mat.albedo_color = Color(0.8, 0.8, 0.8)
		_empty_mat.albedo_texture = GRASS
		_empty_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		_empty_mat.roughness = 0.9
	return _empty_mat

static func board() -> StandardMaterial3D:
	if _board_mat == null:
		_board_mat = StandardMaterial3D.new()
		_board_mat.albedo_color = Color(0.8, 0.8, 0.8)
		_board_mat.albedo_texture = BOARD_TEX
		_board_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		_board_mat.roughness = 0.9
	return _board_mat

static func base() -> StandardMaterial3D:
	if _base_mat == null:
		_base_mat = StandardMaterial3D.new()
		_base_mat.albedo_color = Color(0.55, 0.58, 0.72)
		_base_mat.albedo_texture = BEDROCK
		_base_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		_base_mat.roughness = 0.9
	return _base_mat

static func ghost_bad() -> StandardMaterial3D:
	if _ghost_bad == null:
		_ghost_bad = StandardMaterial3D.new()
		_ghost_bad.albedo_color = Color(1.0, 0.05, 0.10, 0.75)
		_ghost_bad.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost_bad.roughness = 0.6
	return _ghost_bad

static func ghost_grey() -> StandardMaterial3D:
	if _ghost_grey == null:
		_ghost_grey = StandardMaterial3D.new()
		_ghost_grey.albedo_color = Color(0.75, 0.75, 0.78, 0.55)
		_ghost_grey.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost_grey.roughness = 0.6
	return _ghost_grey
