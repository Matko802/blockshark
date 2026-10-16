extends SceneTree

var failures := 0

func check(cond: bool, msg: String) -> void:
	if cond:
		print("ok ", msg)
	else:
		failures += 1
		print("FAIL ", msg)

func find_fit(state: GameState, shape: Dictionary):
	for r in 8:
		for c in 8:
			if state.can_place(shape, r, c):
				return Vector2i(c, r)
	return null

func ghost_center_world(anchor: Vector2i, w: int, h: int) -> Vector3:
	return Vector3(anchor.x - 3.5 + float(w - 1) * 0.5, 3.5 - anchor.y - float(h - 1) * 0.5, 1.5)

func _on_watchdog() -> void:
	print("FAIL watchdog timeout")
	quit(2)

func _init() -> void:
	create_timer(120.0).timeout.connect(_on_watchdog)
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await physics_frame
	await physics_frame
	await physics_frame
	var cam: Camera3D = game.get_node("Camera3D")
	var drag = game.get_node("Drag")
	var state: GameState = game.state
	for round_i in 8:
		var remaining: Array = state.remaining()
		if remaining.is_empty() or state.game_over:
			break
		var had := remaining.size()
		var piece: Dictionary = remaining[0]
		var idx := state.tray.find(piece)
		var shape: Dictionary = piece["shape"]
		var w: int = shape["w"]
		var h: int = shape["h"]
		var spot = find_fit(state, shape)
		if spot == null:
			break
		var node: Node3D = game.tray_node(idx)
		var pointer: Vector2 = cam.unproject_position(node.position)
		drag.begin_drag(pointer)
		check(drag.dragging == idx, "pickup round " + str(round_i))
		drag.lift_blend = 1.0
		for i in 14:
			var anchor: Vector2i = drag.node_anchor()
			if anchor == spot:
				break
			var g := ghost_center_world(anchor, w, h)
			var want := Vector3(spot.x - 3.5 + float(w - 1) * 0.5, 3.5 - spot.y - float(h - 1) * 0.5, 1.5)
			pointer += cam.unproject_position(want) - cam.unproject_position(g)
			drag.move_drag(pointer)
			await process_frame
		var final_anchor: Vector2i = drag.node_anchor()
		check(final_anchor == spot, "ghost steered onto fit spot round " + str(round_i) + " got " + str(final_anchor))
		var cells: Array = game.ghost_cells(idx, final_anchor)
		check(game.ghost_valid(cells), "ghost valid round " + str(round_i))
		var before: int = state.score
		drag.end_drag(pointer)
		await process_frame
		var gained: int = state.score - before
		var ncells: int = (shape["cells"] as Array).size()
		check(gained >= ncells, "score grows round " + str(round_i))
		if had == 1:
			check(state.remaining().size() == 3, "tray refilled round " + str(round_i))
		else:
			check(bool((state.tray[idx] as Dictionary)["used"]), "slot consumed round " + str(round_i))
	if failures == 0:
		print("PASS dragexact")
	else:
		print("FAIL dragexact count=", failures)
	quit(failures)
