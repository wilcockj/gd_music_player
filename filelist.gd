extends Control

# TODO make scrolling behavior nicer on mobile
# require press and release on button to play if
# press and drag should scroll

@export var SPIN_SPEED: float = 0.5
@export var BG_SCALE: float = 2.5

@onready var PitchLabel: Label = %PitchLabel
@onready var VolumeLabel: Label = %VolumeLabel
@onready var CurrentTimeLabel: Label = %CurrentTimeLabel
@onready var ScrubberSlider: HSlider = %ScrubberSlider
@onready var TimeLeftLabel: Label = %TimeLeftLabel
@onready var PlayPauseButton: MaterialButton = %PlayPauseButton
@onready var AlbumArt := %AlbumArt
@onready var SongName := %SongName
@onready var ArtistName := %ArtistName
@onready var BGImage := %BGImage
@onready var PlayBackLabel := %PlayBackLabel
@onready var SearchBar := %SearchBar
@onready var FileDisplayVBox := %FileDisplayVbox

@onready var tmp_art = load("res://assets/images/tmp_art.tres")

var button_list: Array[Button]
var song_index = -1

func _process(delta):
	BGImage.pivot_offset = BGImage.size / 2
	BGImage.rotation += SPIN_SPEED * delta

func _ready():
	EventBus.set_playback_position.connect(_on_set_playback_position)
	EventBus.song_request.connect(song_changed)
	EventBus.metadata_received.connect(_on_metadata_received)

func _on_metadata_received(meta: MusicMeta.MusicMetadata, file_path):
	if meta.cover:
		AlbumArt.texture = meta.cover
	else:
		AlbumArt.texture = tmp_art
	set_background(AlbumArt.texture)
		
	SongName.text = meta.title if meta.title else file_path.split("/")[-1]
	ArtistName.text = meta.artist if meta.artist else "Unknown Artist"
	ArtistName.text = "%s - %s (%s)"%[
		meta.artist if meta.artist else "Unknown Artist",
		meta.album if meta.artist else "Unknow Album",
		meta.year if meta.year else 0
	]

func set_background(texture):
	BGImage.texture = texture
	BGImage.size = DisplayServer.window_get_size() * BG_SCALE
	BGImage.position = Vector2.ZERO
	BGImage.position -= DisplayServer.window_get_size() * (BG_SCALE / 4)

func _on_set_playback_position(pos, length):
	CurrentTimeLabel.text = "%d:%02d"%[int(floor(pos / 60.0)), int(pos) % 60]
	ScrubberSlider.value = (pos / length) * 100
	TimeLeftLabel.text = "-%d:%02d"%[int(floor((length - pos) / 60.0)), int(length - pos) % 60]

func add_list_of_files(list):
	for i in list.size():
		var filepath: String = list[i]
		var filename = filepath.split("/",true)[-1]
		var new_button = Button.new()
		button_list.append(new_button)
		new_button.text = filename
		new_button.set_meta("path",filepath)
		new_button.set_meta("index",i)
		new_button.pressed.connect(play_song.bind(new_button))
		%FileDisplayVbox.add_child(new_button)

func play_song(button):
	PlayPauseButton.text = "󰏤"
	EventBus.play.emit()
	EventBus.song_request.emit(button.get_meta("path"),song_index,button.get_meta("index"))
	
func song_changed(_path,prev_index,new_index):
	#SongName.text = path.split("/",true)[-1]
	button_list[prev_index].modulate = Color.WHITE
	button_list[new_index].modulate = Color.GREEN
	song_index = new_index
	
func _on_reverb_check_box_toggled(toggled_on):
	EventBus.set_reverb.emit(toggled_on)

func _on_pitch_slider_value_changed(value):
	PitchLabel.text = str(value)
	var pitch: AudioEffectPitchShift = AudioServer.get_bus_effect(0, 1)
	pitch.pitch_scale = value

func _on_volume_slider_value_changed(value):
	var new_volume_db = remap(value,0,100,-40,0)
	AudioServer.set_bus_volume_db(0,new_volume_db)
	VolumeLabel.text = str(value) + "%"
	
func _on_play_pause_button_pressed():
	if PlayPauseButton.text == "󰐊":
		PlayPauseButton.text = "󰏤"
		EventBus.play.emit()
	else:
		PlayPauseButton.text = "󰐊"
		EventBus.pause.emit()

func _on_scrubber_slider_drag_ended(value_changed):
	# TODO: This only changes when you drag and then release
	# would be nice to be able to tap or click and have it 
	# change to that point
	if value_changed:
		EventBus.scrub_to_percent.emit(ScrubberSlider.value / 100.0)

func _on_scrubber_slider_value_changed(_value):
	$HBoxContainer/VBoxContainer2/Scrubber/ScrubberChangedTimer.start()

func _on_scrubber_changed_timer_timeout():
	EventBus.scrub_to_percent.emit(ScrubberSlider.value / 100.0)

func _on_play_back_slider_value_changed(value):
	PlayBackLabel.text = "%.01fx"%value
	EventBus.change_playback_speed.emit(value)

func _on_search_bar_text_changed(new_text):
	for button: Button in FileDisplayVBox.get_children():
		if new_text.to_lower() in button.text.to_lower() or new_text == "":
			button.show()
		else:
			button.hide()
