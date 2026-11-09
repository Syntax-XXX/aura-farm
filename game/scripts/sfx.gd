extends Node
## Alle Geräusche werden beim Start erzeugt (keine Audiodateien nötig).

const RATE := 22050

var noise_loop: AudioStreamWAV
var noise_short: AudioStreamWAV
var tones := {}
var players: Array[AudioStreamPlayer] = []
var inhale_player: AudioStreamPlayer


func _ready() -> void:
	noise_loop = _brown(2.0, true)
	noise_short = _brown(1.4, false)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	inhale_player = AudioStreamPlayer.new()
	inhale_player.stream = noise_loop
	inhale_player.volume_db = -14.0
	add_child(inhale_player)


func _brown(seconds: float, loop: bool) -> AudioStreamWAV:
	var count := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var last := 0.0
	for i in count:
		last = clampf(last + randf_range(-1.0, 1.0) * 0.08, -1.0, 1.0) * 0.995
		var env := 1.0
		if not loop:
			env = pow(1.0 - float(i) / count, 1.5) * minf(1.0, i / 600.0)
		data.encode_s16(i * 2, int(last * 22000.0 * env))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = count
	return w


func _tone(freq: float, seconds: float, square := false) -> AudioStreamWAV:
	var key := "%d_%d_%s" % [int(freq), int(seconds * 1000), square]
	if tones.has(key):
		return tones[key]
	var count := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var ph := TAU * freq * i / RATE
		var v := sin(ph)
		if square:
			v = 1.0 if v > 0.0 else -1.0
			v *= 0.4
		var env := minf(1.0, i / 200.0) * pow(1.0 - float(i) / count, 2.0)
		data.encode_s16(i * 2, int(v * 14000.0 * env))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	tones[key] = w
	return w


func _play(stream: AudioStream, vol := -6.0, pitch := 1.0) -> void:
	for p in players:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol
			p.pitch_scale = pitch
			p.play()
			return


func inhale_start() -> void:
	inhale_player.pitch_scale = 0.8
	inhale_player.play()


func inhale_update(charge: float) -> void:
	inhale_player.pitch_scale = 0.8 + charge / 100.0 * 0.7


func inhale_stop() -> void:
	inhale_player.stop()


func exhale(strength: float) -> void:
	_play(noise_short, -10.0 + strength * 6.0, 0.7 + strength * 0.3)


func cough() -> void:
	for i in 3:
		get_tree().create_timer(i * 0.28).timeout.connect(func(): _play(noise_short, -2.0, 2.2))


func melody(freqs: Array, step := 0.1, square := false, vol := -10.0) -> void:
	for i in freqs.size():
		var f: float = freqs[i]
		get_tree().create_timer(i * step).timeout.connect(func(): _play(_tone(f, step * 1.8, square), vol))


func win(big: bool) -> void:
	melody([523.0, 659.0, 784.0, 1046.0, 1318.0] if big else [659.0, 784.0, 1046.0], 0.09)


func fail() -> void:
	melody([392.0, 370.0, 349.0, 262.0], 0.22, true, -16.0)


func key(ok: bool) -> void:
	_play(_tone(880.0 if ok else 180.0, 0.06, true), -18.0)
