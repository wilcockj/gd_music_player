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
@onready var EQOption := %EQOption
@onready var Bands := %Bands
@onready var PitchSlider := %PitchSlider
@onready var PlayBackSlider := %PlayBackSlider
@onready var VolumeSlider := %VolumeSlider
@onready var Settings := %Settings
@onready var ExpandSettings := %ExpandSettingsButton

@onready var tmp_art = load("res://assets/images/tmp_art.tres")
@onready var MusicButton: PackedScene = load("res://scenes/ui/music_button.tscn")

var button_list: Array[HBoxContainer]
var song_index = -1
var settings_visible = false

func _process(delta):
	BGImage.pivot_offset = BGImage.size / 2
	BGImage.rotation += SPIN_SPEED * delta

func _ready():
	EventBus.set_playback_position.connect(_on_set_playback_position)
	EventBus.song_request.connect(song_changed)
	EventBus.metadata_received.connect(_on_metadata_received)
	
	for option in EQManager.settings:
		EQOption.add_item(option["name"])
		
	Settings.hide()

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

func load_mp3(path) -> AudioStreamMP3:
	var file = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound

func async_update_button_data(index, path, b):
	var stream := load_mp3(path)
	b.meta = MusicMeta.get_mp3_metadata(stream) #TODO: dont load every single file
	var filepath: String = path
	var filename = filepath.split("/",true)[-1]
	b.file = filename
	b.path = filepath
	b.index = index
	b.show_data()


func add_list_of_files(list):
	var threads: Array[Thread] = []
	for i in list.size():
		var b: HBoxContainer = MusicButton.instantiate()
		button_list.append(b)
		FileDisplayVBox.add_child(b)
		b.play_song.connect(play_song.bind(b))
		var t := Thread.new()
		threads.append(t)
		t.start(async_update_button_data.bind(i, list[i], b))
	for thread: Thread in threads:
		thread.wait_to_finish()

func play_song(button):
	PlayPauseButton.text = "󰏤"
	EventBus.play.emit()
	EventBus.song_request.emit(button.path, song_index, button.index)
	
func song_changed(_path,prev_index,new_index):
	#SongName.text = path.split("/",true)[-1]
	button_list[prev_index].modulate = Color.WHITE
	button_list[new_index].modulate = Color.PALE_GREEN
	song_index = new_index
	
func _on_reverb_check_box_toggled(toggled_on):
	EventBus.set_reverb.emit(toggled_on)

func _on_pitch_slider_value_changed(value):
	AudioServer.set_bus_effect_enabled(0, 1, true)
	PitchLabel.text = "%.02fx"%value
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
	PlayBackLabel.text = "%.02fx"%value
	EventBus.change_playback_speed.emit(value)

func _on_search_bar_text_changed(new_text):
	for button in FileDisplayVBox.get_children():
		var sanitized_search: String = new_text.to_lower()
		if new_text == "" or button.contains_substr(sanitized_search):
			button.show()
		else:
			button.hide()

func _on_eq_option_item_selected(index):
	var setting = EQManager.settings[index]
	var band_idx = 0
	for band in setting:
		if band != "name":
			var eq: AudioEffectEQ = AudioServer.get_bus_effect(0, 3)
			eq.set_band_gain_db(band_idx, setting[band])
			var sliders = Bands.get_children()
			for slider in sliders:
				if slider.name == "Band%s"%band_idx:
					slider.value = setting[band]
			band_idx += 1

func _on_pitch_reset_pressed():
	PitchSlider.value = 1.0
	AudioServer.set_bus_effect_enabled(0, 1, false)

func _on_playback_reset_pressed():
	PlayBackSlider.value = 1.0

func _on_volume_reset_pressed():
	VolumeSlider.value = 100

func _on_back_button_pressed():
	PlayPauseButton.text = "󰏤"
	EventBus.prev_song.emit()
	print("Prev Song request")
	if song_index > 0:
		EventBus.song_request.emit(button_list[song_index-1].path, song_index, song_index-1)


func _on_forward_button_pressed():
	PlayPauseButton.text = "󰏤"
	EventBus.skip_song.emit()
	print("Next Song request")
	if song_index < button_list.size():
		EventBus.song_request.emit(button_list[song_index+1].path, song_index, song_index+1)

func _on_expand_settings_button_pressed():
	settings_visible = !settings_visible
	if settings_visible:
		ExpandSettings.text = "󰛃"
		%SettingsLabel.text = "Settings:"
	else:
		ExpandSettings.text = "󰛀"
		%SettingsLabel.text = "Settings..."
	Settings.visible = settings_visible
