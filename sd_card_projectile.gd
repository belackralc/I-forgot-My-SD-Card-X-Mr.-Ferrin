# This is the script for our "sd_card_projectile.tscn"
# THIS VERSION EXTENDS Area3D to fix the error!
extends Area3D

# --- NEW: Preload the spark scene ---
# (Make sure this path matches your file!)
var hit_spark_scene = preload("res://hit_spark.tscn")

# How much damage the projectile does
@export var damage = 10

# How fast the projectile flies
@export var speed = 15.0

# How long until the projectile disappears if it hits nothing
@export var lifetime = 5.0

@onready var despawn_timer = $DespawnTimer

func _ready():
	# Set the timer and start it
	despawn_timer.wait_time = lifetime
	despawn_timer.start()
	
	# Connect the body_entered signal.
	# We are connecting this in the editor (Node->Signals tab)
	# so we can remove the code connection to fix the error.
	# body_entered.connect(_on_body_entered)


# We use _process to move the projectile forward manually
func _process(delta):
	# Move forward in the direction the projectile is facing
	# (global_transform.basis.z is its "forward" direction, which is usually negative Z)
	global_position -= global_transform.basis.z * speed * delta


# This function runs when the projectile's body hits another body
func _on_body_entered(body):
	
	# --- THIS IS THE FIX ---
	# Check if the body we hit is in the "player" group.
	if body.is_in_group("player"):
		# If it is the player, just ignore it and stop this
		# function right here. The projectile will keep flying.
		return
	# --- END OF FIX ---
	
	
	# If the body was *not* the player (e.g., a wall or monster),
	# continue on...
	
	# Check if the thing we hit (the body) has a function called "take_damage"
	if body.has_method("take_damage"):
		# If it does, call that function and pass it our damage
		body.take_damage(damage)
	
	# --- NEW SOUND ---
	# Play the hit sound from our SoundManager
	SoundManager.play_sound_3d(SoundManager.HIT_SOUND, global_position)
	# --- END NEW ---
	
	# --- NEW POLISH (SPARKS) ---
	# Instance the sparks
	var sparks = hit_spark_scene.instantiate()
	# Add them to the world
	get_tree().get_root().add_child(sparks)
	# Move them to our current position
	sparks.global_position = self.global_position
	# --- THE FIX: We must manually "light the fuse" for one-shot particles ---
	sparks.get_node("GPUParticles3D").emitting = true
	# --- END NEW ---

	
	# No matter what we hit (a wall, the monster, etc.),
	# destroy the projectile immediately.
	# This is safe now because the sound is played by the SoundManager,
	# not by this projectile.
	queue_free()


func _on_despawn_timer_timeout():
	# Disappear when the timer runs out
	queue_free()
