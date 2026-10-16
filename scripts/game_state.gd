extends RefCounted
class_name GameState

const SIZE = 8
const SAVE_PATH = "user://blockshark.cfg"

var board: Array = []
var tray: Array = []
var score: int = 0
var best: int = 0
var combo: int = 0
var last_gain: int = 0
var game_over: bool = false
var muted: bool = false
var rng := RandomNumberGenerator.new()
var next_id: int = 1

func _init() -> void:
	rng.randomize()
	reset_board()
	load_data()
	new_batch()

func reset_board() -> void:
	board.clear()
	for r in SIZE:
		var row: Array = []
		for c in SIZE:
			row.append(-1)
		board.append(row)

func roll_batch() -> void:
	tray.clear()
	for i in 3:
		var shape: Dictionary = PieceDefs.random_shape(rng)
		tray.append({"id": next_id, "shape": shape, "color": rng.randi_range(0, 7), "used": false})
		next_id += 1

func batch_has_fit() -> bool:
	for p in tray:
		if fits_anywhere(p["shape"]):
			return true
	return false

func new_batch() -> void:
	roll_batch()
	for attempt in 25:
		if batch_has_fit():
			return
		roll_batch()

func can_place(shape: Dictionary, row: int, col: int) -> bool:
	var cells: Array = shape["cells"]
	for cell in cells:
		var r: int = row + cell.y
		var c: int = col + cell.x
		if r < 0 or r >= SIZE or c < 0 or c >= SIZE:
			return false
		if int(board[r][c]) != -1:
			return false
	return true

func fits_anywhere(shape: Dictionary) -> bool:
	for r in SIZE:
		for c in SIZE:
			if can_place(shape, r, c):
				return true
	return false

func remaining() -> Array:
	var out: Array = []
	for p in tray:
		if not bool(p["used"]):
			out.append(p)
	return out

func any_move() -> bool:
	for p in remaining():
		if fits_anywhere(p["shape"]):
			return true
	return false

func find_clears() -> Dictionary:
	var rows: Array = []
	var cols: Array = []
	for r in SIZE:
		var full := true
		for c in SIZE:
			if int(board[r][c]) == -1:
				full = false
				break
		if full:
			rows.append(r)
	for c in SIZE:
		var full := true
		for r in SIZE:
			if int(board[r][c]) == -1:
				full = false
				break
		if full:
			cols.append(c)
	return {"rows": rows, "cols": cols}

func clear_score(lines: int, combo_before: int) -> int:
	if lines <= 0:
		return 0
	var base := 10
	if lines == 2:
		base = 30
	elif lines == 3:
		base = 60
	elif lines >= 4:
		base = 100 + (lines - 4) * 50
	return base + combo_before * 10

func place(index: int, row: int, col: int) -> Dictionary:
	var fail := {"ok": false, "gained": 0, "cleared": [], "lines": 0}
	if game_over:
		return fail
	if index < 0 or index >= tray.size():
		return fail
	var piece: Dictionary = tray[index]
	if bool(piece["used"]):
		return fail
	var shape: Dictionary = piece["shape"]
	if not can_place(shape, row, col):
		return fail
	var cells: Array = shape["cells"]
	for cell in cells:
		board[row + cell.y][col + cell.x] = int(piece["color"])
	var gained: int = cells.size()
	var cl := find_clears()
	var rows: Array = cl["rows"]
	var cols: Array = cl["cols"]
	var lines: int = rows.size() + cols.size()
	var cleared: Array = []
	if lines > 0:
		gained += clear_score(lines, combo)
		combo += 1
		for r in rows:
			for c in SIZE:
				cleared.append(Vector2i(c, r))
		for c in cols:
			for r in SIZE:
				var v := Vector2i(c, r)
				if not cleared.has(v):
					cleared.append(v)
		for v in cleared:
			board[v.y][v.x] = -1
	else:
		combo = 0
	piece["used"] = true
	score += gained
	last_gain = gained
	if score > best:
		best = score
		save_data()
	if remaining().is_empty():
		new_batch()
	if not remaining().is_empty() and not any_move():
		game_over = true
	return {"ok": true, "gained": gained, "cleared": cleared, "lines": lines}

func restart() -> void:
	reset_board()
	score = 0
	combo = 0
	last_gain = 0
	game_over = false
	new_batch()

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best = int(cfg.get_value("game", "best", 0))
		muted = bool(cfg.get_value("game", "muted", false))

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "best", best)
	cfg.set_value("game", "muted", muted)
	cfg.save(SAVE_PATH)
