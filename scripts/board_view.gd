extends Node3D
class_name BoardView

const SIZE = 8
const CUBE = 1.0
const REST_Z = 0.61

var placed: Dictionary = {}
var ghost_nodes: Array = []

func _ready() -> void:
	build()

func key(r: int, c: int) -> String:
	return str(r) + "," + str(c)

func build() -> void:
	var quad := MeshInstance3D.new()
	quad.mesh = CubeMesh.mesh_for_size(CubeMesh.PZ, Vector3(SIZE, SIZE, 0), true)
	quad.position = Vector3(0, 0, 0.10)
	quad.material_override = Mats.board()
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(quad)

func cube_mask(r: int, c: int) -> int:
	var m := CubeMesh.PZ
	if not placed.has(key(r, c + 1)):
		m |= CubeMesh.PX
	if not placed.has(key(r, c - 1)):
		m |= CubeMesh.NX
	if not placed.has(key(r - 1, c)):
		m |= CubeMesh.PY
	if not placed.has(key(r + 1, c)):
		m |= CubeMesh.NY
	return m

func refresh_at(r: int, c: int) -> void:
	var k := key(r, c)
	if placed.has(k):
		(placed[k] as MeshInstance3D).mesh = CubeMesh.mesh_for(cube_mask(r, c))

func refresh_neighbors(r: int, c: int) -> void:
	refresh_at(r, c + 1)
	refresh_at(r, c - 1)
	refresh_at(r - 1, c)
	refresh_at(r + 1, c)

func set_cube(r: int, c: int, color: int, drop: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.scale = Vector3(CUBE, CUBE, CUBE)
	var target := Vector3(c - 3.5, 3.5 - r, REST_Z)
	if drop:
		mi.position = target + Vector3(0, 0, 2.6)
	else:
		mi.position = target
	mi.material_override = Mats.for_color(color)
	add_child(mi)
	placed[key(r, c)] = mi
	if drop:
		mi.mesh = CubeMesh.mesh_for(CubeMesh.FULL)
		var tw := create_tween()
		tw.tween_property(mi, "position", target, 0.28).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(_finish_place.bind(r, c))
	else:
		mi.mesh = CubeMesh.mesh_for(cube_mask(r, c))
		refresh_neighbors(r, c)

func _finish_place(r: int, c: int) -> void:
	var k := key(r, c)
	if placed.has(k):
		(placed[k] as MeshInstance3D).mesh = CubeMesh.mesh_for(cube_mask(r, c))
		refresh_neighbors(r, c)

func remove_cube(r: int, c: int) -> void:
	var k := key(r, c)
	if placed.has(k):
		(placed[k] as Node).queue_free()
		placed.erase(k)
		refresh_neighbors(r, c)

func pop_cells(cells: Array) -> void:
	var touched := {}
	for v in cells:
		var k := key(v.y, v.x)
		if placed.has(k):
			var mi: MeshInstance3D = placed[k] as MeshInstance3D
			placed.erase(k)
			var tw := create_tween()
			tw.tween_property(mi, "scale", Vector3.ONE * 0.01, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw.tween_callback(mi.queue_free)
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			touched[key(v.y + o.y, v.x + o.x)] = Vector2i(v.y + o.y, v.x + o.x)
	for t in touched.values():
		refresh_at(t.x, t.y)

func clear_all() -> void:
	for k in placed.keys():
		(placed[k] as Node).queue_free()
	placed.clear()
	hide_ghost()

func show_ghost(cells: Array, valid: bool, _color: int) -> void:
	hide_ghost()
	var occ := {}
	for v in cells:
		if v.x < 0 or v.x >= SIZE or v.y < 0 or v.y >= SIZE:
			continue
		occ[Vector2i(v.x, v.y)] = true
	for v in cells:
		if v.x < 0 or v.x >= SIZE or v.y < 0 or v.y >= SIZE:
			continue
		var mask := CubeMesh.PZ
		if not occ.has(Vector2i(v.x + 1, v.y)):
			mask |= CubeMesh.PX
		if not occ.has(Vector2i(v.x - 1, v.y)):
			mask |= CubeMesh.NX
		if not occ.has(Vector2i(v.x, v.y - 1)):
			mask |= CubeMesh.PY
		if not occ.has(Vector2i(v.x, v.y + 1)):
			mask |= CubeMesh.NY
		var mi := MeshInstance3D.new()
		mi.mesh = CubeMesh.mesh_for(mask)
		mi.scale = Vector3(CUBE, CUBE, CUBE)
		mi.position = Vector3(v.x - 3.5, 3.5 - v.y, REST_Z)
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
