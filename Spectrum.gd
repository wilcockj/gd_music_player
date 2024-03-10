extends Node2D

const VU_COUNT = 4096

const FREQ_MAX = 11050.0

const MIN_DB = 60
const SMOOTHING = 0.5  # Adjust this value to control the smoothing effect

var spectrum

var average_magnitudes: PackedFloat32Array # Initialize with zeros

var WIDTH
var HEIGHT

var paused: bool
var pause_time: int = 0

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 2)
	average_magnitudes.resize(VU_COUNT)
	average_magnitudes.fill(0.0)
	EventBus.pause.connect(song_paused)
	EventBus.play.connect(song_started)

func song_paused():
	pause_time = Time.get_ticks_msec()
	paused = true

func song_started():
	paused = false

func _process(_delta):
	queue_redraw()
	update_average_magnitudes()

func update_average_magnitudes():
	var prev_hz = 0.0
	for i in range(1, VU_COUNT + 1):
		var hz = i * FREQ_MAX / VU_COUNT
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		# Update the rolling average
		average_magnitudes[i - 1] = lerp(average_magnitudes[i - 1], magnitude, SMOOTHING)
		if average_magnitudes[i - 1] < 0.0011:
			average_magnitudes[i - 1] = 0
		prev_hz = hz

func _draw():
	if paused and pause_time + 1000 < Time.get_ticks_msec() :
		return
	WIDTH = get_parent().size.x
	HEIGHT = get_parent().size.y /2
	var w = WIDTH / VU_COUNT
	for i in range(VU_COUNT):
		var magnitude = average_magnitudes[i]
		var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height = energy * HEIGHT
		draw_rect(Rect2(w * (i + 1), HEIGHT - height, w, height), Color.WHITE)
		draw_rect(Rect2(w * (i + 1), HEIGHT, w, height), Color.WHITE)
