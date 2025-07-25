@tool

extends AspectRatioContainer

@onready var audio_player: AudioStreamPlayer

func _ready() -> void:
	var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var viewport_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	size = Vector2(viewport_width, viewport_height)
	
	# Set background using theme
	setup_background_theme()
	
	# Setup and play menu music
	setup_menu_audio()

func setup_menu_audio() -> void:
	# Create AudioStreamPlayer if it doesn't exist
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
	
	# Load the theme music
	var audio_stream = preload("res://audio/rr_theme.mp3")
	audio_player.stream = audio_stream
	
	# Configure audio settings
	audio_player.volume_db = -10.0 # Adjust volume as needed
	audio_player.autoplay = false
	
	# Play the music
	audio_player.play()

func setup_background_theme() -> void:
	# Create a new theme if one doesn't exist
	if not theme:
		theme = Theme.new()
	
	# Create a StyleBoxTexture for the background
	var style_box = StyleBoxTexture.new()
	
	# Load your background texture
	var background_texture = preload("res://images/bg.png")
	style_box.texture = background_texture
	
	# Configure how the texture should be displayed
	style_box.region_rect = Rect2(Vector2.ZERO, background_texture.get_size())
	
	# Set margins if needed (for 9-patch style stretching)
	# style_box.margin_left = 10
	# style_box.margin_right = 10
	# style_box.margin_top = 10
	# style_box.margin_bottom = 10
	
	# Apply the style to the container's panel background
	theme.set_stylebox("panel", "AspectRatioContainer", style_box)
	
	# Force the container to use the panel stylebox
	add_theme_stylebox_override("panel", style_box)
