extends Node2D

var mp3_list: Array[String]
@onready var filelist: PackedScene = load("res://filelist.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	EventBus.song_request.connect(_on_song_request)
	EventBus.set_reverb.connect(_on_set_reverb)
	OS.get_name()
	if OS.get_name() == "Android":
		%FileDialog.root_subfolder = "/storage/emulated/0/"
	if OS.get_name() == "macOS":
		%FileDialog.root_subfolder = "/Users/"
	#get_tree().create_timer(1).timeout.connect(func():$AudioStreamPlayer.playing = true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func _on_set_reverb(onoff):
	AudioServer.set_bus_effect_enabled(0, 0, onoff)
	

func explore_dir(dir):
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
				var new_dir = dir.get_current_dir() + "/" + file_name
				print("new dir: " + new_dir)
				var fs = DirAccess.open(new_dir)
				explore_dir(fs)
			else:
				print("Found file: " + file_name)
				if file_name.get_extension() == "mp3":
					mp3_list.append(dir.get_current_dir() + "/" + file_name)
			file_name = dir.get_next()

func _on_file_dialog_dir_selected(dir):
	print(dir)
	var fs = DirAccess.open(dir)
	explore_dir(fs)
	#print(mp3_list)
	var list = filelist.instantiate()
	get_tree().root.add_child(list)
	list.add_list_of_files(mp3_list)


func _on_song_request(song_path):
	print("In main song path that was requested = ", song_path)
	var stream = load_mp3(song_path)
	$AudioStreamPlayer.stream = stream
	$AudioStreamPlayer.playing = true
	
	
func load_mp3(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound
