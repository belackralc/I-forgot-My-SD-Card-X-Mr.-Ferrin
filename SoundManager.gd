extends Node

# This script will be an Autoload (Singleton).
# We load our sounds into constants to make them easy to use.

# --- IMPORTANT ---
# If you created an "sfx" folder, change these paths!
# e.g., preload("res://sfx/shoot.wav")
const SHOOT_SOUND = preload("res://sfx/shoot.wav")
const HIT_SOUND = preload("res://sfx/hit.wav")
const PLAYER_HURT_SOUND = preload("res://sfx/player_hurt.wav")
const MONSTER_HURT_SOUND = preload("res://sfx/monster_hurt.wav")


# This is our main function. We will call it from other scripts.
# It creates a new 3D sound player, sets its position,
# plays the sound, and then deletes itself when finished.
func play_sound_3d(sound_resource: AudioStream, position: Vector3):
	
	# Create a new sound player instance
	var sfx = AudioStreamPlayer3D.new()
	
	# Assign the sound file we want to play
	sfx.stream = sound_resource
	
	# --- THE FIX ---
	# The correct property name is "volume_db", not "unit_db".
	sfx.volume_db = 5.0
	
	# This is the magic line:
	# Connect the player's "finished" signal to its own "queue_free" (delete) function.
	# This makes the sound player automatically delete itself after it's done playing.
	sfx.finished.connect(sfx.queue_free)
	
	# We MUST add the node to the tree *before* we can set its global_position.
	
	# Add the new sound player to the main game world
	get_tree().get_root().add_child(sfx)
	
	# NOW we can set its position in the 3D world
	sfx.global_position = position
	# --- END FIX ---
	
	# Play the sound!
	sfx.play()
