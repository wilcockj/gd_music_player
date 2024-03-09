extends FileDialog

var screen_size: Vector2 

func _ready():
	#pass
	print(position)
	fill_screen()
	get_tree().get_root().size_changed.connect(resize)

func fill_screen():
	position = Vector2(0,0)
	screen_size = DisplayServer.window_get_size()
	
	size = screen_size
	
func resize():
	fill_screen()
