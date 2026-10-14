extends RefCounted
class_name PieceFactory

const CUBE = 0.92

static func build(shape: Dictionary, color: int, unique: bool, pickable: bool) -> Node3D:
	var root := Node3D.new()
	var cells: Array = shape["cells"]
	var w: int = shape["w"]
	var h: int = shape["h"]
	for cell in cells:
		var mi := MeshInstance3D.new()
		mi.mesh = Mats.box()
		mi.scale = Vector3(CUBE, CUBE, CUBE)
		mi.position = Vector3(cell.x + 0.5, CUBE * 0.5, cell.y + 0.5)
		if unique:
			mi.material_override = Mats.unique_color(color)
		else:
			mi.material_override = Mats.for_color(color)
		root.add_child(mi)
	if pickable:
		var area := Area3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(w, 1.0, h)
		cs.shape = bs
		cs.position = Vector3(w * 0.5, 0.5, h * 0.5)
		area.add_child(cs)
		root.add_child(area)
		root.set_meta("area", area)
	return root
