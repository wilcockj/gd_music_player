extends Node2D

const VU_COUNT = 128

const FREQ_MAX = 11050.0

const MIN_DB = 60
const SMOOTHING = 0.5  # Adjust this value to control the smoothing effect

var spectrum

var average_magnitudes: PackedFloat32Array # Initialize with zeros

var WIDTH
var HEIGHT


func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 2)
	average_magnitudes.resize(VU_COUNT)
	average_magnitudes.fill(0.0)

func _process(delta):
	queue_redraw()
	update_average_magnitudes()

func update_average_magnitudes():
	var w = WIDTH / VU_COUNT
	var prev_hz = 0.0
	for i in range(1, VU_COUNT + 1):
		var hz = i * FREQ_MAX / VU_COUNT
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		# Update the rolling average
		average_magnitudes[i - 1] = lerp(average_magnitudes[i - 1], magnitude, SMOOTHING)
		prev_hz = hz

func _draw():
	WIDTH = get_parent().size.x
	HEIGHT = get_parent().size.y /2
	var w = WIDTH / VU_COUNT
	for i in range(VU_COUNT):
		var magnitude = average_magnitudes[i]
		var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height = energy * HEIGHT
		draw_rect(Rect2(w * (i + 1), HEIGHT - height, w, height), Color.WHITE)
		draw_rect(Rect2(w * (i + 1), HEIGHT, w, height), Color.WHITE)
