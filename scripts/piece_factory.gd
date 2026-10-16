extends RefCounted
class_name PieceFactory

const CUBE = 1.0

static func build(shape: Dictionary, color: int, unique: bool, pickable: bool) -> Node3D:
	var root := Node3D.new()
	var cells: Array = shape["cells"]
	var w: int = shape["w"]
	var h: int = shape["h"]
	var occ := {}
	for cell in cells:
		occ[Vector2i(cell.x, cell.y)] = true
	for cell in cells:
		var mask := CubeMesh.PZ | CubeMesh.NZ
		if not occ.has(Vector2i(cell.x + 1, cell.y)):
			mask |= CubeMesh.PX
		if not occ.has(Vector2i(cell.x - 1, cell.y)):
			mask |= CubeMesh.NX
		if not occ.has(Vector2i(cell.x, cell.y - 1)):
			mask |= CubeMesh.PY
		if not occ.has(Vector2i(cell.x, cell.y + 1)):
			mask |= CubeMesh.NY
		var mi := MeshInstance3D.new()
		mi.mesh = CubeMesh.mesh_for(mask)
		mi.scale = Vector3(CUBE, CUBE, CUBE)
		mi.position = Vector3(cell.x - float(w - 1) * 0.5, float(h - 1) * 0.5 - cell.y, 0.0)
		if unique:
			mi.material_override = Mats.unique_color(color)
		else:
			mi.material_override = Mats.for_color(color)
		root.add_child(mi)
	if pickable:
		var area := Area3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(w + 0.2, h + 0.2, 2.0)
		cs.shape = bs
		area.add_child(cs)
		root.add_child(area)
		root.set_meta("area", area)
	return root
