extends Node

signal song_request(song_path,prev_index,new_index)
signal set_reverb(onoff)

signal set_playback_position(pos, len)
signal play
signal pause
signal prev_song
signal skip_song
signal scrub_to_percent(percent)
signal change_playback_speed(value)

signal metadata_received(meta: MusicMeta.MusicMetadata, song_path)
