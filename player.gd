extends CharacterBody3D

# --- Player Movement ---
@export var move_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var sensitivity: float = 0.003
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Projectile ---
@export var projectile_scene: PackedScene

# --- Node References ---
@onready var camera: Camera3D = $Camera3D
# This will be our "held item" model
@onready var held_item = $Camera3D/Visuals


func _ready():
	# This locks the mouse cursor to the game window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Connect to the GameState signal
	# This will run our new function whenever the ammo changes
	GameState.sd_cards_changed.connect(_on_sd_cards_changed)
	
	# Set the initial visibility of the held item
	held_item.visible = (GameState.sd_card_count > 0)


# This function runs every time the "sd_cards_changed" signal is emitted
func _on_sd_cards_changed(new_count):
	# Show the held item if ammo > 0, hide it if ammo is 0
	# --- FIX: Also hide if paused ---
	held_item.visible = (new_count > 0) and not get_tree().paused


func _unhandled_input(event: InputEvent):
	
	# --- NEW PAUSE LOGIC (FIXED) ---
	# If the game is paused, don't allow mouse look or firing.
	# GameState.gd handles the *act* of pausing when 'Esc' is hit.
	# The player just needs to *check* if the game is paused.
	if get_tree().paused:
		return
	# --- END NEW PAUSE LOGIC ---

	# Capture mouse movement
	if event is InputEventMouseMotion:
		camera.rotate_x(-event.relative.y * sensitivity)
		rotate_y(-event.relative.x * sensitivity)
		# Clamp the camera's up/down rotation
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		# --- THE FIX ---
		# Stop processing this event, since it was just mouse movement.
		return

	# Handle "fire" input
	# --- THE FIX (AGAIN) ---
	# This is the robust way to check for a "just pressed" action from an event.
	if event.is_action("fire") and event.is_pressed() and not event.is_echo():
		# Check with GameState if we have any ammo
		if GameState.sd_card_count > 0:
			
			# Tell GameState we used one card
			# --- FIX: Call the correct function name ---
			GameState.use_sd_card()
			
			# --- NEW SOUND ---
			# Play the shoot sound at the camera's position
			SoundManager.play_sound_3d(SoundManager.SHOOT_SOUND, camera.global_position)
			
			# Create a new projectile instance
			var projectile = projectile_scene.instantiate()
			
			# Get the camera's transform (position and rotation)
			var spawn_transform = camera.global_transform
			
			# Add the projectile to the main game world
			get_tree().get_root().add_child(projectile)
			
			# Set the projectile's transform to match the camera
			projectile.global_transform = spawn_transform
			
			# Move the projectile slightly forward
			projectile.global_position += spawn_transform.basis.z * -0.5


func _physics_process(delta: float):
	
	# --- NEW PAUSE LOGIC (FIXED) ---
	# If the game is paused, don't allow any movement
	if get_tree().paused:
		# This is important to stop the player from sliding
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# --- END NEW PAUSE LOGIC ---
	
	# Handle gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get input for horizontal movement
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Handle Sprint
	var current_speed = move_speed
	if Input.is_action_pressed("move_sprint"):
		current_speed = sprint_speed

	# Apply movement
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# This is the "lerp"/slide-to-stop logic
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
