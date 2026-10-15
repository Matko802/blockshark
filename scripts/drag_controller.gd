extends Node

var camera: Camera3D
var board_view: BoardView
var state: GameState
var main
var dragging := -1
var drag_node: Node3D
var drag_accum := Vector3.ZERO
var last_pointer := Vector3.ZERO
var last_valid := false
var has_pointer := false
var lift_dir := Vector3(0, 0, -1)
var lift_blend := 0.0

const DRAG_Y = 1.5
const HOME = Vector3(0, 1.5, 0.5)
const LIFT_CELLS = 1.0
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
	var piece: Dictionary = state.tray[dragging]
	var shape: Dictionary = piece["shape"]
	var w: int = shape["w"]
	var h: int = shape["h"]
	var lift := lift_dir * (LIFT_CELLS * lift_taper() * lift_blend)
	drag_node.position = Vector3(HOME.x + drag_accum.x - w * 0.5 + lift.x, DRAG_Y, HOME.z + drag_accum.z - h * 0.5 + lift.z)

func current_gain() -> float:
	var base := clampf(camera.size / 9.0, 0.6, 1.6)
	if last_valid:
		return base * 0.65
	return base

func lift_taper() -> float:
	return clampf((last_pointer.z + 4.0) / TAPER_BAND, 0.0, 1.0)

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

func compute_lift_dir() -> Vector3:
	var vs := camera.get_viewport().get_visible_rect().size
	var c := vs * 0.5
	var plane := Plane(Vector3.UP, DRAG_Y)
	var from_a := camera.project_ray_origin(c)
	var dir_a := camera.project_ray_normal(c)
	var from_b := camera.project_ray_origin(c + Vector2(0, -60.0))
	var dir_b := camera.project_ray_normal(c + Vector2(0, -60.0))
	var a = plane.intersects_ray(from_a, dir_a)
	var b = plane.intersects_ray(from_b, dir_b)
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
	var p0 = plane_point(screen_pos)
	if p0 == null:
		return
	var pt0: Vector3 = p0
	dragging = idx
	drag_node = node
	main.on_pickup(idx)
	lift_dir = compute_lift_dir()
	lift_blend = 0.0
	drag_accum = Vector3.ZERO
	last_pointer = pt0
	last_valid = false
	has_pointer = true
	move_drag(screen_pos)

func target_center() -> Vector3:
	var lift := lift_dir * (LIFT_CELLS * lift_taper())
	return Vector3(HOME.x + drag_accum.x + lift.x, DRAG_Y, HOME.z + drag_accum.z + lift.z)

func target_anchor() -> Vector2i:
	var piece: Dictionary = state.tray[dragging]
	var shape: Dictionary = piece["shape"]
	var w: int = shape["w"]
	var h: int = shape["h"]
	var c := target_center()
	return Vector2i(roundi(c.x + 4.0 - w * 0.5), roundi(c.z + 4.0 - h * 0.5))

func move_drag(screen_pos: Vector2) -> void:
	if dragging < 0 or drag_node == null:
		return
	var p = plane_point(screen_pos)
	if p == null:
		return
	var pt: Vector3 = p
	var step := pt - last_pointer
	last_pointer = pt
	drag_accum += Vector3(step.x, 0.0, step.z) * current_gain()
	last_valid = bool(main.on_drag_preview(dragging, target_anchor()))

func end_drag(screen_pos: Vector2) -> void:
	if dragging < 0:
		return
	var idx := dragging
	var anchor := Vector2i(-99, -99)
	if drag_node != null and is_instance_valid(drag_node) and has_pointer:
		var piece: Dictionary = state.tray[idx]
		var shape: Dictionary = piece["shape"]
		var w: int = shape["w"]
		var h: int = shape["h"]
		var vc := drag_node.position + Vector3(w * 0.5, 0.0, h * 0.5)
		anchor = Vector2i(roundi(vc.x + 4.0 - w * 0.5), roundi(vc.z + 4.0 - h * 0.5))
	dragging = -1
	drag_node = null
	has_pointer = false
	lift_blend = 0.0
	main.on_drop(idx, anchor)
