extends RefCounted
class_name CubeMesh

const PX := 1
const NX := 2
const PY := 4
const NY := 8
const PZ := 16
const NZ := 32
const FULL := 63

static var _cache: Dictionary = {}

static func _face(st: SurfaceTool, n: Vector3, u: Vector3, v: Vector3) -> void:
	_quad(st, n, n * 0.5, u, v, Vector2(0, 0), Vector2(1, 1))

static func _quad(st: SurfaceTool, n: Vector3, c: Vector3, u: Vector3, v: Vector3, uv0: Vector2, uv1: Vector2) -> void:
	var p0 := c - (u + v) * 0.5
	var p1 := c + (u - v) * 0.5
	var p2 := c + (u + v) * 0.5
	var p3 := c + (v - u) * 0.5
	st.set_normal(n)
	st.set_uv(Vector2(uv0.x, uv0.y))
	st.add_vertex(p0)
	st.set_normal(n)
	st.set_uv(Vector2(uv1.x, uv1.y))
	st.add_vertex(p2)
	st.set_normal(n)
	st.set_uv(Vector2(uv1.x, uv0.y))
	st.add_vertex(p1)
	st.set_normal(n)
	st.set_uv(Vector2(uv0.x, uv0.y))
	st.add_vertex(p0)
	st.set_normal(n)
	st.set_uv(Vector2(uv0.x, uv1.y))
	st.add_vertex(p3)
	st.set_normal(n)
	st.set_uv(Vector2(uv1.x, uv1.y))
	st.add_vertex(p2)

static func mesh_for(mask: int) -> ArrayMesh:
	if _cache.has(mask):
		return _cache[mask]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if mask & PX != 0:
		_face(st, Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
	if mask & NX != 0:
		_face(st, Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1))
	if mask & PY != 0:
		_face(st, Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1))
	if mask & NY != 0:
		_face(st, Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1))
	if mask & PZ != 0:
		_face(st, Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))
	if mask & NZ != 0:
		_face(st, Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0))
	var mesh := st.commit()
	_cache[mask] = mesh
	return mesh

static func mesh_for_size(mask: int, size: Vector3, tiled: bool = true) -> ArrayMesh:
	var k := str(mask) + "|" + str(size) + "|" + str(tiled)
	if _cache.has(k):
		return _cache[k]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size * 0.5
	var uv := Vector2(0, 0)
	var fxy := Vector2(size.x, size.y) if tiled else Vector2.ONE
	var fxz := Vector2(size.x, size.z) if tiled else Vector2.ONE
	var fyz := Vector2(size.y, size.z) if tiled else Vector2.ONE
	if mask & PX != 0:
		_quad(st, Vector3(1, 0, 0), Vector3(h.x, 0, 0), Vector3(0, size.y, 0), Vector3(0, 0, size.z), uv, fyz)
	if mask & NX != 0:
		_quad(st, Vector3(-1, 0, 0), Vector3(-h.x, 0, 0), Vector3(0, size.y, 0), Vector3(0, 0, -size.z), uv, fyz)
	if mask & PY != 0:
		_quad(st, Vector3(0, 1, 0), Vector3(0, h.y, 0), Vector3(size.x, 0, 0), Vector3(0, 0, -size.z), uv, fxz)
	if mask & NY != 0:
		_quad(st, Vector3(0, -1, 0), Vector3(0, -h.y, 0), Vector3(size.x, 0, 0), Vector3(0, 0, size.z), uv, fxz)
	if mask & PZ != 0:
		_quad(st, Vector3(0, 0, 1), Vector3(0, 0, h.z), Vector3(size.x, 0, 0), Vector3(0, size.y, 0), uv, fxy)
	if mask & NZ != 0:
		_quad(st, Vector3(0, 0, -1), Vector3(0, 0, -h.z), Vector3(-size.x, 0, 0), Vector3(0, size.y, 0), uv, fxy)
	var mesh2 := st.commit()
	_cache[k] = mesh2
	return mesh2
