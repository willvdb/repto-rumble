extends ProgressBar

@onready var player = null

func _ready():
    player = get_node("../../Player") # Adjust path to your player
    if player:
        min_value = 0.0
        max_value = player.max_stamina

func _process(_delta):
    if player:
        value = player.stamina