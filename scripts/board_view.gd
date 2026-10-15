extends Node3D
class_name BoardView

const SIZE = 8
const CUBE = 1.0
const REST_Y = 0.61

var placed: Dictionary = {}
var ghost_nodes: Array = []

func _ready() -> void:
	build()

func key(r: int, c: int) -> String:
	return str(r) + "," + str(c)

func build() -> void:
	for r in SIZE:
		for c in SIZE:
			var mi := MeshInstance3D.new()
			mi.mesh = Mats.box()
			mi.scale = Vector3(CUBE, 0.22, CUBE)
			mi.position = Vector3(c - 3.5, 0.0, r - 3.5)
			mi.material_override = Mats.empty()
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)

func set_cube(r: int, c: int, color: int, drop: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Mats.box()
	mi.scale = Vector3(CUBE, CUBE, CUBE)
	var target := Vector3(c - 3.5, REST_Y, r - 3.5)
	if drop:
		mi.position = target + Vector3(0, 2.6, 0)
	else:
		mi.position = target
	mi.material_override = Mats.for_color(color)
	add_child(mi)
	placed[key(r, c)] = mi
	if drop:
		var tw := create_tween()
		tw.tween_property(mi, "position", target, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func remove_cube(r: int, c: int) -> void:
	var k := key(r, c)
	if placed.has(k):
		(placed[k] as Node).queue_free()
		placed.erase(k)

func pop_cells(cells: Array) -> void:
	for v in cells:
		var k := key(v.y, v.x)
		if placed.has(k):
			var mi: MeshInstance3D = placed[k] as MeshInstance3D
			placed.erase(k)
			var tw := create_tween()
			tw.tween_property(mi, "scale", Vector3.ONE * 0.01, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(mi.queue_free)

func clear_all() -> void:
	for k in placed.keys():
		(placed[k] as Node).queue_free()
	placed.clear()
	hide_ghost()

func show_ghost(cells: Array, valid: bool, _color: int) -> void:
	hide_ghost()
	for v in cells:
		if v.x < 0 or v.x >= SIZE or v.y < 0 or v.y >= SIZE:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = Mats.box()
		mi.scale = Vector3(CUBE, CUBE, CUBE)
		mi.position = Vector3(v.x - 3.5, REST_Y, v.y - 3.5)
			if valid:
				mi.material_override = Mats.ghost_grey()
			else:
				mi.material_override = Mats.ghost_bad()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		ghost_nodes.append(mi)

func hide_ghost() -> void:
	for n in ghost_nodes:
		(n as Node).queue_free()
	ghost_nodes.clear()
