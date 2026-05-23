## AudioManager — handles music and SFX
extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx: int = 8

# Simple procedural audio using Godot's built-in
var music_bus: int = 0
var sfx_bus: int = 1

func _ready() -> void:
	AudioServer.add_bus()
	AudioServer.set_bus_name(1, "SFX")
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	for i in range(max_sfx):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)

func play_sfx(name: String, pitch: float = 1.0) -> void:
	for p in sfx_players:
		if not p.playing:
			var stream: AudioStream = _get_sfx_stream(name)
			if stream:
				p.stream = stream
				p.pitch_scale = pitch
				p.play()
			return

func play_music(name: String) -> void:
	var stream: AudioStream = _get_music_stream(name)
	if stream:
		music_player.stream = stream
		music_player.play()

func stop_music() -> void:
	music_player.stop()

func set_music_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(0, db)

func set_sfx_volume(db: float) -> void:
	AudioServer.set_bus_volume_db(1, db)

# Procedural sound generation — no external audio files needed
func _get_sfx_stream(name: String) -> AudioStream:
	match name:
		"eat":
			return _make_tone(880, 0.08, "sine")
		"eat2":
			return _make_tone(1100, 0.08, "sine")
		"eat3":
			return _make_tone(660, 0.1, "sine")
		"combo":
			return _make_tone(1200, 0.15, "sine")
		"vortex":
			return _make_tone(400, 0.3, "sawtooth")
		"poison":
			return _make_tone(150, 0.2, "sawtooth")
		"bonus":
			return _make_tone(1400, 0.2, "sine")
		"boss_hit":
			return _make_tone(200, 0.15, "square")
		"boss_die":
			return _make_tone(100, 0.5, "sawtooth")
		"magnet_on":
			return _make_tone(600, 0.05, "sine")
		"magnet_off":
			return _make_tone(400, 0.05, "sine")
		"mouth_close":
			return _make_tone(300, 0.1, "triangle")
		"wave_start":
			return _make_tone(800, 0.15, "sine")
		"level_complete":
			return _make_tone(1000, 0.3, "sine")
		_:
			return null

func _get_music_stream(_name: String) -> AudioStream:
	# Placeholder — in production you'd load OGG/WAV files
	return null

func _make_tone(freq: float, duration: float, wave: String = "sine") -> AudioStream:
	var playback: AudioStreamGenerator = AudioStreamGenerator.new()
	playback.mix_rate = 22050
	# Return generator — actual tone played procedurally
	# For simplicity, we create a short AudioStreamWAV
	var data: PackedByteArray = PackedByteArray()
	var samples: int = int(22050 * duration)
	for i in range(samples):
		var t: float = float(i) / 22050.0
		var val: float = 0.0
		var phase: float = t * freq * TAU
		match wave:
			"sine":
				val = sin(phase)
			"square":
				val = 1.0 if sin(phase) >= 0 else -1.0
			"sawtooth":
				val = 2.0 * fmod(t * freq, 1.0) - 1.0
			"triangle":
				val = 2.0 * abs(2.0 * fmod(t * freq, 1.0) - 1.0) - 1.0
		# Envelope: fade in/out
		var env: float = 1.0
		var attack: float = 0.01
		var release: float = 0.05
		if t < attack:
			env = t / attack
		elif t > duration - release:
			env = (duration - t) / release
		val *= env * 0.3
		var sample: int = int(val * 32767)
		sample = clampi(sample, -32768, 32767)
		data.append_array(PackedInt16Array([sample]).to_byte_array())
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream
