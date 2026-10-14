extends SceneTree

func fail(msg: String) -> void:
	print("FAIL ", msg)
	quit(1)

func make_piece(cells: Array, w: int, h: int, color: int) -> Dictionary:
	return {"id": 1, "shape": {"w": w, "h": h, "cells": cells}, "color": color, "used": false}

func _init() -> void:
	var st := GameState.new()
	if st.board.size() != 8 or (st.board[0] as Array).size() != 8:
		fail("board size")
		return
	if st.tray.size() != 3:
		fail("tray size")
		return
	st.tray = [make_piece([Vector2i(0, 0)], 1, 1, 2), make_piece([Vector2i(0, 0)], 1, 1, 2), make_piece([Vector2i(0, 0)], 1, 1, 2)]
	for c in 7:
		var r: Dictionary = st.place(0, 0, c)
		if not bool(r["ok"]):
			fail("place row " + str(c))
			return
		st.tray[0] = make_piece([Vector2i(0, 0)], 1, 1, 2)
		st.tray[0]["used"] = false
	var before: int = st.score
	var res: Dictionary = st.place(0, 0, 7)
	if not bool(res["ok"]):
		fail("final place")
		return
	if int(res["lines"]) != 1:
		fail("lines")
		return
	if int(st.board[0][0]) != -1 or int(st.board[0][7]) != -1:
		fail("row not cleared")
		return
	if st.combo != 1:
		fail("combo")
		return
	if st.score <= before:
		fail("score")
		return
	var bad: Dictionary = st.place(0, 0, 0)
	st.tray[0] = make_piece([Vector2i(0, 0), Vector2i(1, 0)], 2, 1, 0)
	st.board[0][0] = 5
	st.board[0][1] = 5
	bad = st.place(0, 0, 0)
	if bool(bad["ok"]):
		fail("overlap accepted")
		return
	for r in 8:
		for c in 8:
			st.board[r][c] = 3
	st.tray = [make_piece([Vector2i(0, 0)], 1, 1, 0)]
	if st.any_move():
		fail("full board has move")
		return
	print("PASS logic")
	quit(0)
