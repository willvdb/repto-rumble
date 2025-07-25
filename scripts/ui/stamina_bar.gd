extends ProgressBar

@onready var player: PlatformerController

func _ready():
    # Find the player in the scene
    player = get_tree().get_first_node_in_group("player")
    if not player:
        # Alternative: find by node path if you know the structure
        player = get_node("../../Player") # Adjust path as needed
    
    if player:
        # Connect to the stamina changed signal
        player.stamina_changed.connect(_on_stamina_changed)
        # Set initial values
        min_value = 0.0
        max_value = player.max_stamina
        value = player.stamina

func _on_stamina_changed(current_stamina: float, max_stamina_value: float):
    max_value = max_stamina_value
    value = current_stamina
    
    # Optional: Change color based on stamina level
    var fill_style = get_theme_stylebox("fill")
    if fill_style is StyleBoxFlat:
        if current_stamina < max_stamina_value * 0.3:
            fill_style.bg_color = Color.RED  # Low stamina
        elif current_stamina < max_stamina_value * 0.6:
            fill_style.bg_color = Color.YELLOW  # Medium stamina
        else:
            fill_style.bg_color = Color.GREEN  # High stamina