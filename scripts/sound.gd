extends Node
class_name SharkSound

const RATE = 22050

var players: Array = []
var cursor := 0
var muted := false

func _ready() -> void:
	for i in 6:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		players.append(pl)

func tone_stream(freqs: Array, dur_each: float, vol: float, harsh: bool) -> AudioStreamWAV:
	var per := int(RATE * dur_each)
	var data := PackedByteArray()
	data.resize(per * freqs.size())
	var idx := 0
	for f in freqs:
		var ff := float(f)
		for i in per:
			var t := float(i) / RATE
			var env := 1.0 - float(i) / float(per)
			var s := sin(TAU * ff * t)
			if harsh:
				s = sign(s) * 0.6
			data[idx] = int(128.0 + 100.0 * vol * env * s)
			idx += 1
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.mix_rate = RATE
	w.data = data
	return w

func play_freqs(freqs: Array, dur_each: float, vol: float, harsh: bool) -> void:
	if muted or players.is_empty():
		return
	var pl: AudioStreamPlayer = players[cursor] as AudioStreamPlayer
	cursor = (cursor + 1) % players.size()
	pl.stream = tone_stream(freqs, dur_each, vol, harsh)
	pl.play()

func select() -> void:
	play_freqs([880.0], 0.06, 0.5, false)

func place() -> void:
	play_freqs([660.0], 0.09, 0.6, false)

func cleared(lines: int) -> void:
	if lines <= 1:
		play_freqs([523.0, 784.0], 0.09, 0.6, false)
	elif lines == 2:
		play_freqs([523.0, 659.0, 784.0], 0.09, 0.65, false)
	else:
		play_freqs([523.0, 659.0, 784.0, 1046.0], 0.1, 0.7, false)

func invalid() -> void:
	play_freqs([160.0], 0.14, 0.6, true)

func over() -> void:
	play_freqs([392.0, 311.0, 233.0], 0.16, 0.6, false)
