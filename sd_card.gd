extends Area3D

# This script is for the collectible SD Card.

# --- UPDATED LINE ---
# Instead of getting the mesh, get the new "Visuals" container
@onready var visuals = $Visuals

# Runs once when the SD card is added to the game.
func _ready():
	# Add this node to the "sd_cards" group.
	# This is how our GameState will count how many cards exist.
	add_to_group("sd_cards")


func _process(delta: float):
	# This spins the whole Area3D (Visuals, Collision, and Label)
	rotate_y(1.0 * delta)
	
	var time = Time.get_ticks_msec() / 1000.0
	
	# --- UPDATED LINE ---
	# Now, we bob the "Visuals" node up and down.
	# Since the box and sticker are inside, they move together!
	visuals.position.y = sin(time * 2.0) * 0.1


func _on_body_entered(body):
	if body.get_script() and body.get_script().resource_path == "res://player.gd":
		
		# Tell our global GameState that we collected a card.
		# --- FIX: We need to tell it HOW MANY cards we collected ---
		GameState.add_sd_card()
		
		# Now we can safely delete the card.
		queue_free()
