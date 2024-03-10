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

func contains_substr(msg):
	if msg in (meta.title.to_lower() if meta.title else file.to_lower()):
		return true
	if msg in (meta.artist.to_lower() if meta.artist else "Unknown Artist"):
		return true
	if msg in (meta.album.to_lower() if meta.album else "Unknown Album"):
		return true

func _on_play_button_pressed():
	play_song.emit()
