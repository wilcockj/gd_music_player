extends Control

# TODO make scrolling behavior nicer on mobile
# require press and release on button to play if
# press and drag should scroll

@onready var PitchLabel: Label = $HBoxContainer/VBoxContainer/Pitch/PitchLabel
@onready var VolumeLabel: Label = $HBoxContainer/VBoxContainer/Volume/VolumeLabel
@onready var CurrentTimeLabel: Label = $HBoxContainer/VBoxContainer2/Scrubber/CurrentTimeLabel
@onready var ScrubberSlider: HSlider = $HBoxContainer/VBoxContainer2/Scrubber/ScrubberSlider
@onready var TimeLeftLabel: Label = $HBoxContainer/VBoxContainer2/Scrubber/TimeLeftLabel
@onready var PlayPauseButton: MaterialButton = $HBoxContainer/VBoxContainer2/Controls/PlayPauseButton
@onready var AlbumArt := $HBoxContainer/VBoxContainer2/Panel2/TextureRect
@onready var SongName := $HBoxContainer/VBoxContainer2/SongName
@onready var ArtistName := $HBoxContainer/VBoxContainer2/ArtistName

var button_list: Array[Button]
var song_index = -1
func _ready():
	EventBus.set_playback_position.connect(_on_set_playback_position)
	EventBus.song_request.connect(song_changed)
	EventBus.metadata_received.connect(_on_metadata_received)

func _on_metadata_received(meta: MusicMeta.MusicMetadata):
	AlbumArt.texture = meta.cover
	SongName.text = meta.title if meta.title else "NO DATA FOUND"
	ArtistName.text = meta.album if meta.album else "NO DATA FOUND"

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
	
func song_changed(path,prev_index,new_index):
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


func _on_scrubber_slider_value_changed(value):
	$HBoxContainer/VBoxContainer2/Scrubber/ScrubberChangedTimer.start()
	


func _on_scrubber_changed_timer_timeout():
	EventBus.scrub_to_percent.emit(ScrubberSlider.value / 100.0)
