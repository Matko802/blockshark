extends Node
class_name SharkSound

const RATE = 22050

var players: Array = []
var cursor := 0
var muted := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for i in 6:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		players.append(pl)

func seg_tone(freq: float, dur: float, vol: float) -> PackedByteArray:
	var n := int(RATE * dur)
	var out := PackedByteArray()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := 1.0 - float(i) / float(n)
		var s := sin(TAU * freq * t)
		out[i] = clampi(int(128.0 + 100.0 * vol * env * s), 0, 255)
	return out

func seg_click(freq: float, dur: float, vol: float) -> PackedByteArray:
	var n := int(RATE * dur)
	var out := PackedByteArray()
	out.resize(n)
	var f := freq * rng.randf_range(0.85, 1.18)
	var phase := rng.randf_range(0.0, TAU)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 120.0)
		var noise := rng.randf_range(-1.0, 1.0)
		var s := noise * 0.55 + sin(TAU * f * t + phase) * 0.45
		out[i] = clampi(int(128.0 + 110.0 * vol * env * s), 0, 255)
	return out

func seg_thock(freq: float, dur: float, vol: float) -> PackedByteArray:
	var n := int(RATE * dur)
	var out := PackedByteArray()
	out.resize(n)
	var f := freq * rng.randf_range(0.92, 1.08)
	for i in n:
		var t := float(i) / RATE
		var body := sin(TAU * f * t) * exp(-t * 28.0)
		var snap := rng.randf_range(-1.0, 1.0) * exp(-t * 160.0) * 0.7
		var s := body * 0.8 + snap
		out[i] = clampi(int(128.0 + 110.0 * vol * s), 0, 255)
	return out

func seg_silence(dur: float) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(int(RATE * dur))
	for i in out.size():
		out[i] = 128
	return out

func stream_of(parts: Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	for part in parts:
		data.append_array(part)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.mix_rate = RATE
	w.data = data
	return w

func play_stream(s: AudioStreamWAV) -> void:
	if muted or players.is_empty():
		return
	var pl: AudioStreamPlayer = players[cursor] as AudioStreamPlayer
	cursor = (cursor + 1) % players.size()
	pl.stream = s
	pl.play()

func chime(freq: float, vol: float) -> PackedByteArray:
	var out := seg_click(freq, 0.04, vol)
	out.append_array(seg_tone(freq, 0.14, vol))
	return out

func select() -> void:
	play_stream(stream_of([seg_click(2600.0, 0.035, 0.5)]))

func place() -> void:
	play_stream(stream_of([seg_thock(rng.randf_range(200.0, 240.0), 0.09, 0.65)]))
	play_stream(stream_of([seg_click(3200.0, 0.025, 0.4)]))

func tray() -> void:
	play_stream(stream_of([seg_click(1800.0, 0.04, 0.4), seg_silence(0.03), seg_click(2400.0, 0.04, 0.4)]))

func cleared(lines: int) -> void:
	var ladder := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
	var parts: Array = []
	var n := mini(lines + 1, 5)
	for i in n:
		parts.append(chime(float(ladder[i]), 0.55))
	play_stream(stream_of(parts))

func invalid() -> void:
	play_stream(stream_of([seg_thock(110.0, 0.14, 0.6)]))

func over() -> void:
	play_stream(stream_of([seg_tone(523.25, 0.15, 0.55), seg_tone(440.0, 0.15, 0.55), seg_tone(349.23, 0.15, 0.55), seg_tone(293.66, 0.2, 0.55)]))
