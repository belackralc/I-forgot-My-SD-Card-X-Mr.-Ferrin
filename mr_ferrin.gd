extends CharacterBody3D

# --- Player Detection ---
# This holds a reference to the player node, but only if the player
# is inside our DetectionZone.
var player = null

# --- Navigation ---
@onready var nav_agent = $NavigationAgent3D

# --- Stats ---
@export var health = 100
const MAX_HEALTH = 100

# --- State Machine ---
# A simple variable to track what the monster is doing.
# 0 = IDLE, 1 = CHASING
var state = 0

# --- Damage Cooldown ---
@onready var damage_cooldown_timer = $DamageCooldownTimer
var player_in_damage_zone = false # Is the player close enough to hit?

# This is a new signal. We will tell GameState when we die.
signal monster_died

# --- NEW SIGNALS for 2D HEALTH BAR ---
# We will tell GameState about our health, and GameState will tell the HUD.
signal monster_health_changed(current_health, max_health)
signal monster_spotted(current_health, max_health)
signal monster_lost()

# --- NEW FOR FLASH EFFECT ---
# --- FIX: This name must match your 3D mesh node! ---
@onready var visual_mesh = $MonsterMesh
# This is the new Timer node you will add in the editor
@onready var flash_timer = $FlashTimer
var original_material: StandardMaterial3D


func _ready():
	print("[MR. FERRIN] _ready()")
	
	# --- NEW FOR FLASH EFFECT ---
	# Check if the visual_mesh was found before trying to use it
	if visual_mesh:
		# Store the original material so we can revert to it
		original_material = visual_mesh.get_active_material(0)
	else:
		print("ERROR: Could not find 'MonsterMesh' node. Flashing effect will not work.")

	
	# Connect the new flash timer
	if not flash_timer.is_connected("timeout", Callable(self, "_on_flash_timer_timeout")):
		flash_timer.connect("timeout", Callable(self, "_on_flash_timer_timeout"))
		print("[MR. FERRIN] Connected flash_timer")
	# --- END NEW ---

	
	# --- Connect all signals in code to be safe ---
	
	# 1. Detection Zone
	var detection_zone = $DetectionZone
	if not detection_zone.is_connected("body_entered", Callable(self, "_on_detection_zone_body_entered")):
		detection_zone.connect("body_entered", Callable(self, "_on_detection_zone_body_entered"))
		print("[MR. FERRIN] Connected body_entered")
		
	if not detection_zone.is_connected("body_exited", Callable(self, "_on_detection_zone_body_exited")):
		detection_zone.connect("body_exited", Callable(self, "_on_detection_zone_body_exited"))
		print("[MR. FERRIN] Connected body_exited")

	# 2. Damage Zone
	var damage_zone = $DamageZone
	if not damage_zone.is_connected("body_entered", Callable(self, "_on_damage_zone_body_entered")):
		damage_zone.connect("body_entered", Callable(self, "_on_damage_zone_body_entered"))
		print("[MR. FERRIN] Connected damage_zone_body_entered")

	if not damage_zone.is_connected("body_exited", Callable(self, "_on_damage_zone_body_exited")):
		damage_zone.connect("body_exited", Callable(self, "_on_damage_zone_body_exited"))
		print("[MR. FERRIN] Connected damage_zone_body_exited")
		
	# 3. Damage Cooldown Timer
	if not damage_cooldown_timer.is_connected("timeout", Callable(self, "_on_damage_cooldown_timer_timeout")):
		damage_cooldown_timer.connect("timeout", Callable(self, "_on_damage_cooldown_timer_timeout"))
		print("[MR. FERRIN] Connected damage_cooldown_timer")

	# 4. Connect our "died" signal to GameState
	if not monster_died.is_connected(GameState._on_monster_died):
		monster_died.connect(GameState._on_monster_died)
		print("[MR. FERRIN] Connected monster_died to GameState")
		
	# --- NEW 2D HEALTH BAR CONNECTIONS ---
	if not monster_health_changed.is_connected(GameState._on_monster_health_changed):
		monster_health_changed.connect(GameState._on_monster_health_changed)
		print("[MR. FERRIN] Connected monster_health_changed to GameState")

	if not monster_spotted.is_connected(GameState._on_monster_spotted):
		monster_spotted.connect(GameState._on_monster_spotted)
		print("[MR. FERRIN] Connected monster_spotted to GameState")
		
	if not monster_lost.is_connected(GameState._on_monster_lost):
		monster_lost.connect(GameState._on_monster_lost)
		print("[MR. FERRIN] Connected monster_lost to GameState")


func _physics_process(_delta):
	
	if health <= 0:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	match state:
		0: # IDLE
			velocity = Vector3.ZERO
			
		1: # CHASING
			if is_instance_valid(player):
				nav_agent.set_target_position(player.global_position)
				var next_path_pos = nav_agent.get_next_path_position()
				var direction = (next_path_pos - global_position).normalized()
				velocity = direction * 3.0 # Move speed of 3
			else:
				state = 0
				player = null
				emit_signal("monster_lost") # Tell HUD to hide bar
				
	move_and_slide()
	
	if player_in_damage_zone and damage_cooldown_timer.is_stopped():
		damage_cooldown_timer.start()


# --- Public Function ---
# This is called by the sd_card_projectile.
func take_damage(amount):
	if health <= 0:
		return # Already dead
		
	if not is_instance_valid(visual_mesh):
		print("ERROR: 'visual_mesh' node not found, can't flash red.")
		return 

	print("[MR. FERRIN] Took damage, new health: %s" % (health - amount))
	health -= amount
	
	# --- NEW SOUND ---
	# Play the monster hurt sound at our position
	SoundManager.play_sound_3d(SoundManager.MONSTER_HURT_SOUND, global_position)
	# --- END NEW ---
	
	# Tell the HUD to show our health bar
	emit_signal("monster_spotted", health, MAX_HEALTH)
	
	# Emit the signal to update the HUD
	emit_signal("monster_health_changed", health, MAX_HEALTH)

	if health <= 0:
		print("[MR. FERRIN] Died!")
		emit_signal("monster_died") 
		emit_signal("monster_lost") 
		visual_mesh.material_override = null
		queue_free() 
	else:
		# Flash red
		var flash_material = original_material.duplicate()
		flash_material.albedo_color = Color.RED
		visual_mesh.material_override = flash_material
		flash_timer.start()


# --- Signal Callbacks ---

func _on_detection_zone_body_entered(body):
	if body.is_in_group("player"):
		print("[MR. FERRIN] Player entered zone.")
		player = body
		state = 1 # Change state to CHASING
		
		# (We moved the monster_spotted signal to take_damage)

func _on_detection_zone_body_exited(body):
	if body.is_in_group("player"):
		print("[MR. FERRIN] Player exited zone.")
		player = null
		state = 0 # Change state to IDLE
		emit_signal("monster_lost")

# --- Damage Zone Signals ---
func _on_damage_zone_body_entered(body):
	if body.is_in_group("player"):
		player_in_damage_zone = true

func _on_damage_zone_body_exited(body):
	if body.is_in_group("player"):
		player_in_damage_zone = false
		damage_cooldown_timer.stop()

# --- Timer Signal ---
func _on_damage_cooldown_timer_timeout():
	# Timer finished!
	if player_in_damage_zone:
		print("[MR. FERRIN] Dealing damage to player")
		GameState.take_damage(25) # Tell GameState to hurt player
		
		# --- NEW SOUND ---
		# Play the player hurt sound at the player's position
		# We need to check if player is still valid just in case
		if is_instance_valid(player):
			SoundManager.play_sound_3d(SoundManager.PLAYER_HURT_SOUND, player.global_position)
		# --- END NEW ---
	
	if not player_in_damage_zone:
		damage_cooldown_timer.stop()

# --- NEW FUNCTION FOR FLASH EFFECT ---
func _on_flash_timer_timeout():
	# Timer finished, remove the red "override" material
	if is_instance_valid(visual_mesh):
		visual_mesh.material_override = null
