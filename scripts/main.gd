extends Node3D

const TRAY_Z = 6.3
const TRAY_X = [-2.9, 0.0, 2.9]
const TRAY_SCALE = 0.5
const TRAY_Y = 0.15

var state: GameState
var tray_nodes: Array = []
var tray_x: Dictionary = {}
var tray_tweens: Dictionary = {}
var time := 0.0
var app_version := "2.4.4"
var app_code := 0

@onready var board: BoardView = $Board
@onready var drag = $Drag
@onready var sound: SharkSound = $Sound
@onready var hud = $HUD
@onready var updater = $Updater
@onready var camera: Camera3D = $Camera3D
@onready var tray_root: Node3D = $Tray
@onready var sun: DirectionalLight3D = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment

const NIGHT_TOP = Color(0.008, 0.012, 0.045)
const NIGHT_HOR = Color(0.10, 0.14, 0.30)
const DAY_TOP = Color(0.25, 0.50, 0.95)
const DAY_HOR = Color(0.70, 0.85, 1.00)
const DUSK = Color(1.00, 0.45, 0.20)
const SUN_WARM = Color(1.00, 0.55, 0.30)
const SUN_WHITE = Color(1.00, 1.00, 1.00)
const MOON_TINT = Color(0.60, 0.75, 1.00)

func make_stars() -> void:
	var img := Image.create(512, 256, false, Image.FORMAT_RGB8)
	img.fill(Color.BLACK)
	for i in 500:
		var v := randf_range(0.35, 1.0)
		img.set_pixel(randi_range(0, 511), randi_range(0, 255), Color(v, v, v))
	var mat := world_env.environment.sky.sky_material as ProceduralSkyMaterial
	if mat != null:
		mat.sky_cover = ImageTexture.create_from_image(img)

func sun_elevation(h: float) -> float:
	if h >= 6.0 and h < 18.0:
		return sin((h - 6.0) / 12.0 * PI) * 65.0
	var nt := fposmod(h - 18.0, 24.0) / 12.0
	return sin(nt * PI) * 35.0

func update_sky() -> void:
	var dt := Time.get_datetime_dict_from_system()
	var h := float(dt["hour"]) + float(dt["minute"]) / 60.0
	var day := h >= 6.0 and h < 18.0
	var elev := sun_elevation(h)
	if day:
		var t := (h - 6.0) / 12.0
		sun.rotation = Vector3(deg_to_rad(-elev), deg_to_rad(lerpf(-60.0, 60.0, t)), 0.0)
	else:
		var nt := fposmod(h - 18.0, 24.0) / 12.0
		sun.rotation = Vector3(deg_to_rad(-elev), deg_to_rad(lerpf(120.0, 240.0, nt)), 0.0)
	var s := sin(deg_to_rad(elev)) if day else -0.25
	var day_f := smoothstep(-0.08, 0.30, s)
	var dusk_f := clampf(1.0 - absf(s) / 0.30, 0.0, 1.0) * smoothstep(-0.50, -0.02, s)
	var mat := world_env.environment.sky.sky_material as ProceduralSkyMaterial
	if mat != null:
		mat.sky_top_color = NIGHT_TOP.lerp(DAY_TOP, day_f) + DUSK * (dusk_f * 0.30)
		var hor := NIGHT_HOR.lerp(DAY_HOR, day_f) + DUSK * (dusk_f * 0.70)
		mat.sky_horizon_color = hor
		mat.ground_horizon_color = Color(hor.r * 0.45, hor.g * 0.45, hor.b * 0.45)
		mat.ground_bottom_color = Color(hor.r * 0.15, hor.g * 0.15, hor.b * 0.15)
		mat.sky_energy_multiplier = lerpf(0.25, 1.0, day_f)
		mat.ground_energy_multiplier = lerpf(0.30, 1.0, day_f)
		mat.sky_cover_modulate = Color(1, 1, 1) * (1.0 - day_f)
	if day:
		sun.light_color = SUN_WARM.lerp(SUN_WHITE, clampf(s / 0.5, 0.0, 1.0))
		sun.light_energy = lerpf(0.0, 1.15, smoothstep(-0.03, 0.20, s))
	else:
		sun.light_color = MOON_TINT
		sun.light_energy = 0.12
	world_env.environment.ambient_light_energy = lerpf(0.35, 0.9, day_f)

func load_version() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("res://version.cfg") == OK:
		app_version = str(cfg.get_value("app", "version_name", app_version))
		app_code = int(cfg.get_value("app", "version_code", 0))

func version_text() -> String:
	if app_code > 0:
		return "v" + app_version + "  build " + str(app_code)
	return "v" + app_version

func buzz(ms: int) -> void:
	if OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(ms)

func buzz_twice(a: int, gap: float, b: int) -> void:
	buzz(a)
	await get_tree().create_timer(gap).timeout
	buzz(b)

func _ready() -> void:
	load_version()
	state = GameState.new()
	sound.muted = state.muted
	camera.position = Vector3(0, 12.5, 9.5)
	camera.look_at(Vector3(0, 0, 1.5))
	fit_camera()
	get_viewport().size_changed.connect(fit_camera)
	make_stars()
	update_sky()
	var sky_timer := Timer.new()
	sky_timer.wait_time = 60.0
	sky_timer.autostart = true
	add_child(sky_timer)
	sky_timer.timeout.connect(update_sky)
	drag.setup(camera, board, state, self)
	hud.setup(self, version_text())
	updater.setup(self, hud, app_version)
	rebuild_tray()
	hud.refresh(state.score, state.best, state.combo)
	hud.set_muted(state.muted)
	updater.auto_check()

func _process(delta: float) -> void:
	time += delta
	for i in tray_nodes.size():
		var n: Node3D = tray_nodes[i] as Node3D
		if n == null or not is_instance_valid(n):
			continue
		if drag.dragging == i:
			continue
		n.position.y = TRAY_Y + sin(time * 2.2 + float(i) * 1.3) * 0.07

func fit_camera() -> void:
	var vs := get_viewport().get_visible_rect().size
	var aspect := vs.x / maxf(vs.y, 1.0)
	camera.size = maxf(9.0, 12.0 * aspect)

func slot_pos(i: int) -> Vector3:
	return Vector3(float(tray_x.get(i, TRAY_X[i])), TRAY_Y, TRAY_Z)

func remaining_indices() -> Array:
	var out: Array = []
	for i in state.tray.size():
		if not bool((state.tray[i] as Dictionary)["used"]):
			out.append(i)
	return out

func layout_tray(animated: bool) -> void:
	var ids := remaining_indices()
	var n := ids.size()
	for k in n:
		var idx: int = ids[k]
		tray_x[idx] = (float(k) - float(n - 1) * 0.5) * 2.9
		var node := tray_node(idx)
		if node == null:
			continue
		if tray_tweens.has(idx) and is_instance_valid(tray_tweens[idx]):
			(tray_tweens[idx] as Tween).kill()
		tray_tweens.erase(idx)
		if animated:
			var slide := create_tween()
			slide.tween_property(node, "position", slot_pos(idx), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tray_tweens[idx] = slide
		else:
			node.position = slot_pos(idx)

func rebuild_tray() -> void:
	for n in tray_nodes:
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
	tray_nodes.clear()
	tray_x.clear()
	tray_tweens.clear()
	for i in state.tray.size():
		var piece: Dictionary = state.tray[i]
		var node: Node3D = PieceFactory.build(piece["shape"], int(piece["color"]), true, true)
		node.position = slot_pos(i)
		node.scale = Vector3.ONE * 0.01
		tray_root.add_child(node)
		var area: Area3D = node.get_meta("area") as Area3D
		area.set_meta("slot", i)
		tray_nodes.append(node)
		var target := Vector3.ONE * TRAY_SCALE
		var tw := create_tween()
		tw.tween_property(node, "scale", target, 0.25).set_delay(float(i) * 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	layout_tray(false)
	update_tray_dim()

func tray_node(idx: int) -> Node3D:
	if idx < 0 or idx >= tray_nodes.size():
		return null
	var n: Node3D = tray_nodes[idx] as Node3D
	if n == null or not is_instance_valid(n):
		return null
	return n

func update_tray_dim() -> void:
	for i in tray_nodes.size():
		var n: Node3D = tray_nodes[i] as Node3D
		if n == null or not is_instance_valid(n):
			continue
		var piece: Dictionary = state.tray[i]
		var dim := false
		if not bool(piece["used"]):
			dim = not state.fits_anywhere(piece["shape"])
		set_node_dim(n, 0.3 if dim else 1.0)

func set_node_dim(node: Node3D, a: float) -> void:
	for ch in node.get_children():
		if ch is MeshInstance3D:
			var m: StandardMaterial3D = (ch as MeshInstance3D).material_override as StandardMaterial3D
			if m != null:
				var c := m.albedo_color
				c.a = a
				m.albedo_color = c

func on_pickup(idx: int) -> void:
	var node := tray_node(idx)
	if node == null:
		return
	if tray_tweens.has(idx) and is_instance_valid(tray_tweens[idx]):
		(tray_tweens[idx] as Tween).kill()
	tray_tweens.erase(idx)
	node.scale = Vector3.ONE
	sound.select()
	buzz(15)

func ghost_cells(idx: int, anchor: Vector2i) -> Array:
	var piece: Dictionary = state.tray[idx]
	var cells: Array = (piece["shape"] as Dictionary)["cells"]
	var out: Array = []
	for cell in cells:
		out.append(Vector2i(anchor.x + cell.x, anchor.y + cell.y))
	return out

func ghost_valid(cells: Array) -> bool:
	for v in cells:
		if v.x < 0 or v.x >= 8 or v.y < 0 or v.y >= 8:
			return false
		if int(state.board[v.y][v.x]) != -1:
			return false
	return true

func on_drag_preview(idx: int, anchor: Vector2i) -> bool:
	var cells := ghost_cells(idx, anchor)
	var piece: Dictionary = state.tray[idx]
	var ok := ghost_valid(cells)
	board.show_ghost(cells, ok, int(piece["color"]))
	return ok

func on_drop(idx: int, anchor: Vector2i) -> void:
	board.hide_ghost()
	if anchor.x < -50:
		back_to_slot(idx)
		return
	var piece: Dictionary = state.tray[idx]
	var shape: Dictionary = piece["shape"]
	var cells: Array = shape["cells"]
	var color: int = int(piece["color"])
	var res: Dictionary = state.place(idx, anchor.y, anchor.x)
	if not bool(res["ok"]):
		back_to_slot(idx)
		return
	var node := tray_node(idx)
	if node != null:
		tray_nodes[idx] = null
		node.queue_free()
	for cell in cells:
		board.set_cube(anchor.y + cell.y, anchor.x + cell.x, color, true)
	var cleared: Array = res["cleared"]
	var lines: int = res["lines"]
	if lines > 0:
		board.pop_cells(cleared)
		sound.cleared(lines)
		if lines > 1:
			buzz_twice(50, 0.07, 70)
		else:
			buzz(40)
	else:
		sound.place()
		buzz(25)
	hud.show_gain(int(res["gained"]))
	if state.remaining().size() == 3:
		rebuild_tray()
		sound.tray()
	else:
		layout_tray(true)
		update_tray_dim()
	hud.refresh(state.score, state.best, state.combo)
	if state.game_over:
		sound.over()
		buzz(150)
		hud.show_over(state.score, state.best)

func back_to_slot(idx: int) -> void:
	var node := tray_node(idx)
	if node == null:
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(node, "position", slot_pos(idx), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector3.ONE * TRAY_SCALE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func restart_game() -> void:
	drag.dragging = -1
	drag.drag_node = null
	drag.has_pointer = false
	board.hide_ghost()
	state.restart()
	board.clear_all()
	rebuild_tray()
	hud.hide_over()
	hud.refresh(state.score, state.best, state.combo)
	sound.tray()
	buzz(20)

func set_sound_enabled(sound_on: bool) -> void:
	state.muted = not sound_on
	sound.muted = state.muted
	state.save_data()
	hud.set_muted(state.muted)

func check_updates() -> void:
	updater.check(false)
