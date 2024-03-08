extends Control


@onready var PitchLabel: Label = $HBoxContainer/VBoxContainer/Pitch/PitchLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func add_list_of_files(list):
	
	for filepath : String in list:
		# get file from path
		# split by / get -1
		var filename = filepath.split("/",true)[-1]
		#print(file.split("/",true)[-1])
		var new_button = Button.new()
		new_button.text = filename
		new_button.set_meta("path",filepath)
		new_button.pressed.connect(play_song.bind(new_button))
		%FileDisplayVbox.add_child(new_button)

func play_song(button):
	print("Should play " + button.get_meta("path"))
	EventBus.song_request.emit(button.get_meta("path"))
	
func _on_reverb_check_box_toggled(toggled_on):
	EventBus.set_reverb.emit(toggled_on)

func _on_pitch_slider_value_changed(value):
	PitchLabel.text = str(value)
