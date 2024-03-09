extends Node

signal song_request(song_path,prev_index,new_index)
signal set_reverb(onoff)

signal set_playback_position(pos, len)
signal play
signal pause
signal scrub_to_percent(percent)
