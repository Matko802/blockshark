extends SceneTree

var failures := 0

func check(cond: bool, msg: String) -> void:
	if cond:
		print("ok ", msg)
	else:
		failures += 1
		print("FAIL ", msg)

func first_fit(state: GameState) -> Array:
	for pi in state.tray.size():
		var piece: Dictionary = state.tray[pi]
		if bool(piece["used"]):
			continue
		var shape: Dictionary = piece["shape"]
		for r in 8:
			for c in 8:
				if state.can_place(shape, r, c):
					return [pi, r, c]
	return []

func _on_watchdog() -> void:
	print("FAIL watchdog timeout")
	quit(2)

func _init() -> void:
	create_timer(180.0).timeout.connect(_on_watchdog)
	var refills := 0
	var moves := 0
	for g in 5:
		var st := GameState.new()
		check(st.any_move(), "fresh game has moves")
		for m in 400:
			var fit: Array = first_fit(st)
			if fit.is_empty():
				break
			var had := st.remaining().size()
			var res: Dictionary = st.place(fit[0], fit[1], fit[2])
			check(bool(res["ok"]), "place ok game " + str(g))
			moves += 1
			check(st.game_over == (not st.any_move()), "gameover matches moves game " + str(g))
			if had == 1 and st.remaining().size() == 3:
				refills += 1
				check(st.any_move(), "fresh batch has a fit game " + str(g))
		check(st.game_over or moves > 0, "game ends game " + str(g))
	print("moves=", moves, " refills=", refills)
	check(refills > 0, "refills happened")
	if failures == 0:
		print("PASS soak")
	else:
		print("FAIL soak count=", failures)
	quit(failures)
