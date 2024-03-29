extends Node2D

var mp3_list: Array[String]
var current_song_idx = -1

@onready var Player: AudioStreamPlayer = $AudioStreamPlayer
@onready var filelist: PackedScene = load("res://filelist.tscn")


func _ready():
	EventBus.song_request.connect(_on_song_request)
	EventBus.set_reverb.connect(_on_set_reverb)
	EventBus.play.connect(_on_play)
	EventBus.pause.connect(_on_pause)
	EventBus.scrub_to_percent.connect(_on_scrub_to_percent)
	EventBus.change_playback_speed.connect(_on_change_playback_speed)
	
	OS.get_name()
	if OS.get_name() == "Android":
		%FileDialog.root_subfolder = "/storage/emulated/0/"
	if OS.get_name() == "macOS":
		%FileDialog.root_subfolder = "/Users/"
	if OS.get_name() == "Linux":
		%FileDialog.root_subfolder = "/home"

func _on_change_playback_speed(value):
	Player.pitch_scale = value

func _on_scrub_to_percent(percent):
	print("time to scrub")
	var length = Player.stream.get_length()
	var pos = length * percent
	Player.play(pos)

func _on_play():
	Player.stream_paused = false
	
func _on_pause():
	Player.stream_paused = true
	
func _on_set_reverb(onoff):
	AudioServer.set_bus_effect_enabled(0, 0, onoff)

func explore_dir(dir):
	if not dir:
		return		
	var files = dir.get_files()
	var dirs = dir.get_directories()
	for file in files:
		if file.get_extension() == "mp3":
			mp3_list.append(dir.get_current_dir() + "/" + file)
	for cur_dir in dirs:
		var new_dir = dir.get_current_dir() + "/" + cur_dir
		var fs = DirAccess.open(new_dir)
		explore_dir(fs)
	

func _on_file_dialog_dir_selected(dir):
	print(dir)
	var fs = DirAccess.open(dir)
	explore_dir(fs)
	var list = filelist.instantiate()
	get_tree().root.add_child(list)
	list.add_list_of_files(mp3_list)


func _on_song_request(song_path,_prev_index,new_index):
	print("In main song path that was requested = ", song_path)
	var stream = load_mp3(song_path)
	$AudioStreamPlayer.stream = stream
	$AudioStreamPlayer.playing = true
	current_song_idx = new_index
	
	var meta: MusicMeta.MusicMetadata = MusicMeta.get_mp3_metadata(stream)
	EventBus.metadata_received.emit(meta, song_path)
	
func load_mp3(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound

func _on_timer_timeout():
	if Player.playing:
		var pos = Player.get_playback_position()
		var length = Player.stream.get_length()
		EventBus.set_playback_position.emit(pos, length)
	$Timer.start(0.5)


func _on_audio_stream_player_finished():
	#play next in list
	if current_song_idx < mp3_list.size() - 1 and current_song_idx >= 0:
		var next_index = current_song_idx + 1
		var current_index = current_song_idx
		# ERMM This is awkaward, had issue when sending current_song_idx to signal it
		# would already be updated by main by the time it got to file list
		EventBus.song_request.emit(mp3_list[current_song_idx+1],current_index,next_index)
	else:
		print("Reached final song")
	
