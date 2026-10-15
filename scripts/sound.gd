extends Node
class_name SharkSound

const PICKUP := preload("res://assets/sounds/pickup.ogg")
const PLACE := [
	preload("res://assets/sounds/place1.ogg"),
	preload("res://assets/sounds/place2.ogg"),
	preload("res://assets/sounds/place3.ogg"),
]
const BREAK := [
	preload("res://assets/sounds/clear1.ogg"),
	preload("res://assets/sounds/clear2.ogg"),
]
const BREAK_LOW := preload("res://assets/sounds/clear_low.ogg")
const TRAY_SND := preload("res://assets/sounds/tray.ogg")
const INVALID_SND := preload("res://assets/sounds/invalid.ogg")
const GAMEOVER := preload("res://assets/sounds/gameover.ogg")

var players: Array = []
var cursor := 0
var muted := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for i in 8:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		players.append(pl)

func play_sfx(s: AudioStream, pitch := 1.0, vol_db := 0.0) -> void:
	if muted or players.is_empty():
		return
	var pl: AudioStreamPlayer = players[cursor] as AudioStreamPlayer
	cursor = (cursor + 1) % players.size()
	pl.stream = s
	pl.pitch_scale = pitch
	pl.volume_db = vol_db
	pl.play()

func ui() -> void:
	play_sfx(PICKUP, rng.randf_range(1.25, 1.35), -5.0)

func select() -> void:
	play_sfx(PICKUP, rng.randf_range(0.96, 1.06), -2.0)

func place() -> void:
	play_sfx(PLACE[rng.randi_range(0, PLACE.size() - 1)], rng.randf_range(0.95, 1.05))

func tray() -> void:
	play_sfx(TRAY_SND, rng.randf_range(0.97, 1.03), -3.0)

func cleared(lines: int) -> void:
	var n := mini(lines + 1, 5)
	for i in n:
		play_sfx(BREAK[rng.randi_range(0, BREAK.size() - 1)], 1.0 + float(i) * 0.12, -1.5)
		await get_tree().create_timer(0.07).timeout
	if lines >= 2:
		play_sfx(BREAK_LOW, 0.7, -2.0)

func invalid() -> void:
	play_sfx(INVALID_SND, rng.randf_range(0.97, 1.03), -2.0)

func over() -> void:
	play_sfx(GAMEOVER, 1.0, -1.0)
