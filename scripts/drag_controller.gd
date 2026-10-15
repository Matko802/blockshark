extends Node

var camera: Camera3D
var board_view: BoardView
var state: GameState
var main
var dragging := -1
var drag_node: Node3D
var grab_offset := Vector3.ZERO
var lift_dir := Vector3(0, 0, -1)
var lift_blend := 0.0
var last_target := Vector3.ZERO
var last_finger := Vector3.ZERO
var has_target := false

const DRAG_Y = 1.5
const LIFT_CELLS = 1.0
const TAPER_BAND = 1.5

func setup(cam: Camera3D, bv: BoardView, st: GameState, mn) -> void:
	camera = cam
	board_view = bv
	state = st
	main = mn

func _process(delta: float) -> void:
	if dragging < 0 or drag_node == null or not is_instance_valid(drag_node) or not has_target:
		return
	lift_blend = minf(lift_blend + delta * 7.0, 1.0)
	var piece: Dictionary = state.tray[dragging]
	var shape: Dictionary = piece["shape"]
	var w: int = shape["w"]
	var h: int = shape["h"]
	var lift := lift_dir * (LIFT_CELLS * lift_taper() * lift_blend)
	drag_node.position = Vector3(last_target.x + grab_offset.x - w * 0.5 + lift.x, DRAG_Y, last_target.z + grab_offset.z - h * 0.5 + lift.z)

func lift_taper() -> float:
	return clampf((last_finger.z + 4.0) / TAPER_BAND, 0.0, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if camera == null or state == null:
		return
	if state.game_over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			begin_drag(event.position)
		else:
			end_drag(event.position)
	elif event is InputEventMouseMotion and dragging >= 0:
		move_drag(event.position)

func ray_hit(screen_pos: Vector2) -> Dictionary:
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 100.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = true
	return camera.get_world_3d().direct_space_state.intersect_ray(q)

func plane_point(screen_pos: Vector2):
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, 0.0)
	return plane.intersects_ray(from, dir)

func drag_plane_point(screen_pos: Vector2):
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	var plane := Plane(Vector3.UP, DRAG_Y)
	return plane.intersects_ray(from, dir)

func compute_lift_dir() -> Vector3:
	var vs := camera.get_viewport().get_visible_rect().size
	var c := vs * 0.5
	var a = drag_plane_point(c)
	var b = drag_plane_point(c + Vector2(0, -60.0))
	if a == null or b == null:
		return Vector3(0, 0, -1)
	var va: Vector3 = a
	var vb: Vector3 = b
	var d := vb - va
	d.y = 0.0
	if d.length() < 0.001:
		return Vector3(0, 0, -1)
	return d.normalized()

func begin_drag(screen_pos: Vector2) -> void:
	var hit := ray_hit(screen_pos)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider == null or not collider.has_meta("slot"):
		return
	var idx := int(collider.get_meta("slot"))
	if idx < 0 or idx >= state.tray.size():
		return
	var piece: Dictionary = state.tray[idx]
	if bool(piece["used"]):
		return
	var node: Node3D = main.tray_node(idx)
	if node == null or not is_instance_valid(node):
		return
	dragging = idx
	drag_node = node
	main.on_pickup(idx)
	grab_offset = Vector3.ZERO
	lift_dir = compute_lift_dir()
	lift_blend = 0.0
	has_target = false
	var p0 = plane_point(screen_pos)
	if p0 != null:
		var pt0: Vector3 = p0
		var shape0: Dictionary = piece["shape"]
		var w0: int = shape0["w"]
		var h0: int = shape0["h"]
		var center0 := Vector3(node.position.x + w0 * 0.5, 0.0, node.position.z + h0 * 0.5)
		grab_offset = center0 - Vector3(pt0.x, 0.0, pt0.z)
	move_drag(screen_pos)

func target_anchor() -> Vector2i:
	var piece: Dictionary = state.tray[dragging]
	var shape: Dictionary = piece["shape"]
	var w: int = shape["w"]
	var h: int = shape["h"]
	var lift := lift_dir * (LIFT_CELLS * lift_taper())
	var vx := last_target.x + grab_offset.x + lift.x
	var vz := last_target.z + grab_offset.z + lift.z
	return Vector2i(roundi(vx + 4.0 - w * 0.5), roundi(vz + 4.0 - h * 0.5))

func move_drag(screen_pos: Vector2) -> void:
	if dragging < 0 or drag_node == null:
		return
	var p = plane_point(screen_pos)
	if p == null:
		return
	var pt: Vector3 = p
	var q = drag_plane_point(screen_pos)
	if q == null:
		return
	var qc: Vector3 = q
	last_target = qc
	last_finger = pt
	has_target = true
	main.on_drag_preview(dragging, target_anchor())

func end_drag(screen_pos: Vector2) -> void:
	if dragging < 0:
		return
	var idx := dragging
	var anchor := Vector2i(-99, -99)
	if drag_node != null and is_instance_valid(drag_node) and has_target:
		var piece: Dictionary = state.tray[idx]
		var shape: Dictionary = piece["shape"]
		var w: int = shape["w"]
		var h: int = shape["h"]
		var vc := drag_node.position + Vector3(w * 0.5, 0.0, h * 0.5)
		anchor = Vector2i(roundi(vc.x + 4.0 - w * 0.5), roundi(vc.z + 4.0 - h * 0.5))
	dragging = -1
	drag_node = null
	grab_offset = Vector3.ZERO
	has_target = false
	lift_blend = 0.0
	main.on_drop(idx, anchor)
