extends Node2D

const VU_COUNT = 500
const FREQ_MAX = 11050.0
const MIN_DB = 60
const SMOOTHING_RISE = 0.5  # This value now affects both rising and falling movements equally
const SMOOTHING_FALL = 0.2

var spectrum

var average_magnitudes := PackedFloat32Array()  # Initialize as empty, to be resized in _ready
var WIDTH
var HEIGHT

var paused: bool = false
var pause_time: int = 0

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 2)
	average_magnitudes.resize(VU_COUNT)
	average_magnitudes.fill(0.0)
	# Assume EventBus is a valid object you have set up elsewhere for event communication
	EventBus.pause.connect(song_paused)
	EventBus.play.connect(song_started)

func song_paused():
	pause_time = Time.get_ticks_msec()
	paused = true

func song_started():
	paused = false

func _process(_delta):
	if not paused:
		update_average_magnitudes()
	queue_redraw()

func update_average_magnitudes():
	var prev_hz = 0.0
	for i in range(1, VU_COUNT + 1):
		var hz = i * FREQ_MAX / VU_COUNT
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		# Apply smoothing more intelligently
		if magnitude > average_magnitudes[i - 1]:
			# Rising: Apply smoothing
			average_magnitudes[i - 1] = lerp(average_magnitudes[i - 1], magnitude, SMOOTHING_RISE)
		else:
			# Falling: Perhaps apply a different factor or same based on desired effect
			average_magnitudes[i - 1] = lerp(average_magnitudes[i - 1], magnitude, SMOOTHING_FALL)
		# Clamp to zero if very small, to avoid drawing noise
		if average_magnitudes[i - 1] < 0.0011:
			average_magnitudes[i - 1] = 0
		prev_hz = hz

func _draw():
	if paused and Time.get_ticks_msec() - pause_time < 1000:
		# Add a return statement here to pause drawing if needed
		return
	WIDTH = get_parent().size.x
	HEIGHT = get_parent().size.y / 2
	var w = WIDTH / VU_COUNT
	for i in range(VU_COUNT):
		var magnitude = average_magnitudes[i]
		var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height = energy * HEIGHT
		draw_rect(Rect2(w * i, HEIGHT - height, w, height), Color.PALE_GREEN)
		draw_rect(Rect2(w * i, HEIGHT, w, height), Color.PALE_GREEN)
