extends FileDialog

var screen_size: Vector2 
# Called when the node enters the scene tree for the first time.
func _ready():
	#pass
	print(position)
	fill_screen()
	get_tree().get_root().size_changed.connect(resize)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func fill_screen():
	var dec_size = get_size_with_decorations()
	var prev_size = size
	
	position = Vector2(0,0)
	screen_size = DisplayServer.window_get_size()
	
	size = screen_size
	

func resize():
	fill_screen()
