extends Node

var camera: Camera3D
var board_view: BoardView
var state: GameState
var main
var dragging := -1
var drag_node: Node3D
var spawn_center := Vector3.ZERO
var drag_accum := Vector3.ZERO
var last_pointer := Vector3.ZERO
var last_valid := false
var last_anchor := Vector2i(-999, -999)
var has_pointer := false
var lift_full := Vector3.ZERO
var lift_blend := 0.0

const DRAG_Z = 1.5
const LIFT_PX = 200.0
const TAPER_BAND = 1.5

func setup(cam: Camera3D, bv: BoardView, st: GameState, mn) -> void:
	camera = cam
	board_view = bv
	state = st
	main = mn

func _process(delta: float) -> void:
	if dragging < 0 or drag_node == null or not is_instance_valid(drag_node) or not has_pointer:
		return
	lift_blend = minf(lift_blend + delta * 7.0, 1.0)
	place_node()

func current_gain() -> float:
	return 1.0

func lift_taper() -> float:
	return clampf((4.5 - last_pointer.y) / TAPER_BAND, 0.0, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if camera == null or state == null:
		return
	if state.game_over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if dragging < 0:
				begin_drag(event.position)
		else:
			end_drag(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if dragging < 0:
				begin_drag(event.position)
		else:
			end_drag(event.position)
	elif dragging >= 0:
		if event is InputEventMouseMotion:
			move_drag(event.position)
		elif event is InputEventScreenDrag:
			move_drag(event.position)

func ray_hit(screen_pos: Vector2) -> Dictionary:
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 100.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = true
	return camera.get_world_3d().direct_space_state.intersect_ray(q)

func wall_plane() -> Plane:
	return Plane(Vector3(0, 0, 1), DRAG_Z)

func plane_point(screen_pos: Vector2):
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	return wall_plane().intersects_ray(from, dir)

func compute_lift() -> Vector3:
	var vs := camera.get_viewport().get_visible_rect().size
	var c := vs * 0.5
	var plane := wall_plane()
	var from_a := camera.project_ray_origin(c)
	var dir_a := camera.project_ray_normal(c)
	var from_b := camera.project_ray_origin(c + Vector2(0, -LIFT_PX))
	var dir_b := camera.project_ray_normal(c + Vector2(0, -LIFT_PX))
	var a = plane.intersects_ray(from_a, dir_a)
	var b = plane.intersects_ray(from_b, dir_b)
	if a == null or b == null:
		return Vector3(0, 1, 0)
	var va: Vector3 = a
	var vb: Vector3 = b
	var d := vb - va
	d.z = 0.0
	if d.length() < 0.001:
		return Vector3(0, 1, 0)
	return d

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
	var p0 = plane_point(screen_pos)
	if p0 == null:
		return
	var pt0: Vector3 = p0
	dragging = idx
	drag_node = node
	main.on_pickup(idx)
	node.position = Vector3(node.position.x, node.position.y, DRAG_Z)
	spawn_center = Vector3(node.position.x, node.position.y, DRAG_Z)
	lift_full = compute_lift()
	lift_blend = 0.0
	drag_accum = Vector3.ZERO
	last_pointer = pt0
	last_valid = false
	last_anchor = Vector2i(-999, -999)
	has_pointer = true
	move_drag(screen_pos)

func place_node() -> void:
	var lift := lift_full * (lift_taper() * lift_blend)
	drag_node.position = Vector3(spawn_center.x + drag_accum.x + lift.x, spawn_center.y + drag_accum.y + lift.y, DRAG_Z)

func node_anchor() -> Vector2i:
	return snap_anchor(drag_node.position, shape_w(), shape_h())

func shape_w() -> int:
	return int((state.tray[dragging] as Dictionary)["shape"]["w"])

func shape_h() -> int:
	return int((state.tray[dragging] as Dictionary)["shape"]["h"])

func aim_center() -> Vector3:
	var lift := lift_full * lift_taper()
	return Vector3(spawn_center.x + drag_accum.x + lift.x, spawn_center.y + drag_accum.y + lift.y, DRAG_Z)

func aim_over_board() -> bool:
	return aim_center().y >= -4.25

func snap_anchor(center: Vector3, w: int, h: int) -> Vector2i:
	var col := clampi(roundi(center.x + 3.5 - float(w - 1) * 0.5), 0, 8 - w)
	var row := clampi(roundi(3.5 - center.y - float(h - 1) * 0.5), 0, 8 - h)
	return Vector2i(col, row)

func move_drag(screen_pos: Vector2) -> void:
	if dragging < 0 or drag_node == null:
		return
	var p = plane_point(screen_pos)
	if p == null:
		return
	var pt: Vector3 = p
	var step := pt - last_pointer
	last_pointer = pt
	drag_accum += Vector3(step.x, step.y, 0.0) * current_gain()
	place_node()
	if not aim_over_board():
		board_view.hide_ghost()
		last_valid = false
		return
	var anchor := snap_anchor(aim_center(), shape_w(), shape_h())
	if anchor != last_anchor:
		last_anchor = anchor
		main.buzz(20)
	last_valid = bool(main.on_drag_preview(dragging, anchor))

func end_drag(screen_pos: Vector2) -> void:
	if dragging < 0:
		return
	var idx := dragging
	var anchor := Vector2i(-99, -99)
	if has_pointer and aim_over_board():
		anchor = snap_anchor(aim_center(), shape_w(), shape_h())
	dragging = -1
	drag_node = null
	has_pointer = false
	lift_blend = 0.0
	main.on_drop(idx, anchor)
