extends Control


@onready var PitchLabel: Label = $HBoxContainer/VBoxContainer/Pitch/PitchLabel
@onready var VolumeLabel: Label = $HBoxContainer/VBoxContainer/Volume/VolumeLabel
@onready var CurrentTimeLabel: Label = $HBoxContainer/VBoxContainer2/Scrubber/CurrentTimeLabel
@onready var ScrubberSlider: HSlider = $HBoxContainer/VBoxContainer2/Scrubber/ScrubberSlider
@onready var TimeLeftLabel: Label = $HBoxContainer/VBoxContainer2/Scrubber/TimeLeftLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.set_playback_position.connect(_on_set_playback_position)
	EventBus.song_request.connect(song_changed)

func _on_set_playback_position(pos, length):
	CurrentTimeLabel.text = "%d:%02d"%[int(floor(pos / 60.0)), int(pos) % 60]
	ScrubberSlider.value = (pos / length) * 100
	TimeLeftLabel.text = "-%d:%02d"%[int(floor((length - pos) / 60.0)), int(length - pos) % 60]

func add_list_of_files(list):
	for i in list.size():
		# get file from pathda
		# split by / get -1
		var filepath: String = list[i]
		var filename = filepath.split("/",true)[-1]
		#print(file.split("/",true)[-1])
		var new_button = Button.new()
		new_button.text = filename
		new_button.set_meta("path",filepath)
		new_button.set_meta("index",i)
		new_button.pressed.connect(play_song.bind(new_button))
		%FileDisplayVbox.add_child(new_button)

func play_song(button):
	print("Should play " + button.get_meta("path"))
	EventBus.song_request.emit(button.get_meta("path"),button.get_meta("index"))
	
func song_changed(path,index):
	%SongName.text = path.split("/",true)[-1]
	
func _on_reverb_check_box_toggled(toggled_on):
	EventBus.set_reverb.emit(toggled_on)

func _on_pitch_slider_value_changed(value):
	PitchLabel.text = str(value)
	var pitch: AudioEffectPitchShift = AudioServer.get_bus_effect(0, 1)
	pitch.pitch_scale = value


func _on_volume_slider_value_changed(value):
	#(-80-0)
	var new_volume_db = remap(value,0,100,-40,0)
	AudioServer.set_bus_volume_db(0,new_volume_db)
	VolumeLabel.text = str(value) + "%"
	
