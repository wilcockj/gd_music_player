extends HBoxContainer

signal play_song

var meta: MusicMeta.MusicMetadata
var file: String
var path: String
var index: int

# Called when the node enters the scene tree for the first time.
func _ready():
	$SongInfo/Title.text = meta.title if meta.title else file
	$SongInfo/ArtistAlbum.text = "%s - %s"%[
		meta.artist if meta.artist else "Unknown Artist",
		meta.album if meta.album else "Unknown Album"
	]
	if meta.cover:
		$AlbumArt.texture = meta.cover

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_button_pressed():
	play_song.emit()
