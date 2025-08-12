# Simple Sprite Sheet Approach for Repto Rumble
# This creates individual PNG files that can be used in SpriteFrames

@tool
extends EditorScript

func _run():
	print("Creating simple placeholder sprite files...")
	
	# Create sprites directory if it doesn't exist
	var dir = DirAccess.open("res://sprites/characters/")
	if not dir.dir_exists("simple"):
		dir.make_dir("simple")
	
	# Define colors for different animations
	var sprite_colors = {
		"idle": Color.BLUE,
		"run": Color.GREEN,
		"jump": Color.ORANGE,
		"attack": Color.RED
	}
	
	var size = Vector2i(32, 48)
	
	for sprite_name in sprite_colors:
		var color = sprite_colors[sprite_name]
		
		# Create image
		var image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		image.fill(color)
		
		# Save as PNG
		var save_path = "res://sprites/characters/simple/" + sprite_name + ".png"
		var error = image.save_png(save_path)
		
		if error == OK:
			print("Created: ", save_path)
		else:
			print("Error creating: ", save_path, " - ", error)
	
	print("Sprite creation complete!")
