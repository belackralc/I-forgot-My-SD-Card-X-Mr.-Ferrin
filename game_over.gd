extends Control

# --- This script fixes the invisible mouse and ensures buttons work ---

@onready var restart_button = $CenterContainer/VBoxContainer/RestartButton
@onready var main_menu_button = $CenterContainer/VBoxContainer/MainMenuButton

func _ready():
	# FIX 1: Make the mouse visible!
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# FIX 2: Ensure the game is unpaused (this screen runs "Always" anyway)
	get_tree().paused = false
	
	# Connect signals
	restart_button.pressed.connect(_on_restart_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

func _on_restart_button_pressed():
	# GameState.restart_game() handles all the logic, including unpausing
	GameState.restart_game()

func _on_main_menu_button_pressed():
	# Go back to the main menu
	get_tree().change_scene_to_file("res://MainMenu.tscn")
