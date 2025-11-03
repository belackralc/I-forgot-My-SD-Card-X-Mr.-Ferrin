extends Control

# --- This is the new script from "Instructions (Final Bug-Fix).md" ---

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	# This makes the mouse cursor visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# --- THIS IS THE FIX ---
	# Any time the main menu loads, we tell GameState to reset itself.
	# This ensures we are always starting a fresh game!
	GameState.reset_stats()
	# --- END FIX ---

	# Connect button signals
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _on_start_button_pressed():
	# Load the main game world
	get_tree().change_scene_to_file("res://world.tscn")

func _on_quit_button_pressed():
	# Quit the application
	get_tree().quit()
