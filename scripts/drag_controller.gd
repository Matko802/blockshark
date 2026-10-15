extends Node

var camera: Camera3D
var board_view: BoardView
var state: GameState
var main
var dragging := -1
var drag_node: Node3D
var grab_offset := Vector3.ZERO
var hold_center := Vector3.ZERO
var hold_ready := false

const DRAG_Y = 1.5

func setup(cam: Camera3D, bv: BoardView, st: GameState, mn) -> void:
	camera = cam
	board_view = bv
	state = st
	main = mn

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
	hold_ready = false
	var p0 = plane_point(screen_pos)
	if p0 != null:
		var pt0: Vector3 = p0
		var shape0: Dictionary = piece["shape"]
		var w0: int = shape0["w"]
		var h0: int = shape0["h"]
		var center0 := Vector3(node.position.x + w0 * 0.5, 0.0, node.position.z + h0 * 0.5)
		grab_offset = center0 - Vector3(pt0.x, 0.0, pt0.z)
		var vs := camera.get_viewport().get_visible_rect().size
		var c = drag_plane_point(Vector2(vs.x * 0.5, vs.y * 0.40))
		if c != null:
			var cc: Vector3 = c
			hold_center = cc
			hold_ready = true
			drag_node.position = Vector3(cc.x + grab_offset.x - w0 * 0.5, DRAG_Y, cc.z + grab_offset.z - h0 * 0.5)
	move_drag(screen_pos)

func move_drag(screen_pos: Vector2) -> void:
	if dragging < 0 or drag_node == null:
		return
	var p = plane_point(screen_pos)
	if p == null:
		return
	var pt: Vector3 = p
	var q = drag_plane_point(screen_pos)
	var piece: Dictionary = state.tray[dragging]
	var shape: Dictionary = piece["shape"]
	var w: int = shape["w"]
	var h: int = shape["h"]
	if hold_ready:
		drag_node.position = Vector3(hold_center.x + grab_offset.x - w * 0.5, DRAG_Y, hold_center.z + grab_offset.z - h * 0.5)
	elif q != null:
		var qc: Vector3 = q
		drag_node.position = Vector3(qc.x + grab_offset.x - w * 0.5, DRAG_Y, qc.z + grab_offset.z - h * 0.5)
	else:
		drag_node.position = Vector3(pt.x + grab_offset.x - w * 0.5, DRAG_Y, pt.z + grab_offset.z - h * 0.5)
	main.on_drag_preview(dragging, pt)

func end_drag(screen_pos: Vector2) -> void:
	if dragging < 0:
		return
	var idx := dragging
	dragging = -1
	drag_node = null
	grab_offset = Vector3.ZERO
	hold_ready = false
	var p = plane_point(screen_pos)
	var anchor := Vector2i(-99, -99)
	if p != null:
		var pt: Vector3 = p
		anchor = main.anchor_for(idx, pt)
	main.on_drop(idx, anchor)
