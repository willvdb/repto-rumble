extends ProgressBar

@onready var player: PlatformerController
var tween: Tween

func _ready():
    # Find the player in the scene
    player = get_tree().get_first_node_in_group("player")
    if not player:
        # Try multiple fallback paths
        var potential_paths = [
            "../../Player",
            "../../../Player",
            "../../../../Player",
            "/root/Game/Player",
            "/root/Main/Player"
        ]
        
        for path in potential_paths:
            var node = get_node_or_null(path)
            if node and node is PlatformerController:
                player = node
                break
    
    if player:
        # Connect to the stamina changed signal
        player.stamina_changed.connect(_on_stamina_changed)
        # Set initial values
        min_value = 0.0
        max_value = player.max_stamina
        value = player.stamina
        
        # Create tween for smooth animations
        tween = create_tween()
        tween.stop()
    else:
        print("Warning: Could not find PlatformerController player for stamina bar")

func _on_stamina_changed(current_stamina: float, max_stamina_value: float):
    max_value = max_stamina_value
    
    # Smooth animation to new stamina value
    if tween:
        tween.kill()
    tween = create_tween()
    tween.tween_property(self, "value", current_stamina, 0.2)
    
    # Optional: Change color based on stamina level
    var fill_style = get_theme_stylebox("fill")
    if fill_style is StyleBoxFlat:
        var target_color: Color
        if current_stamina < max_stamina_value * 0.3:
            target_color = Color.RED # Low stamina
        elif current_stamina < max_stamina_value * 0.6:
            target_color = Color.ORANGE # Medium stamina
        else:
            target_color = Color.GREEN # High stamina
        
        # Smooth color transition
        tween.parallel().tween_property(fill_style, "bg_color", target_color, 0.3)