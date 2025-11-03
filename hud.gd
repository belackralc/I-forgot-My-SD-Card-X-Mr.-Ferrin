# This is the script for our new "HUD.tscn" scene.
extends CanvasLayer

# --- Core UI ---
@onready var crosshair: Label = $Crosshair
@onready var health_label: Label = $MarginContainer/HBoxContainer/HealthLabel
@onready var sd_card_label: Label = $MarginContainer/HBoxContainer/SDCardLabel
@onready var mr_ferrin_health_bar: ProgressBar = $MrFerrinHealthBar
@onready var InGameUI: MarginContainer = $MarginContainer

# --- New Pause Menu & Hurt Effect UI ---
@onready var PauseMenu: ColorRect = $PauseMenu
@onready var HurtEffect: ColorRect = $HurtEffect
@onready var ResumeButton: Button = $PauseMenu/VBoxContainer/ResumeButton
@onready var MainMenuButton: Button = $PauseMenu/VBoxContainer/MainMenuButton


# --- NEW: PAUSE LOGIC MOVED HERE FROM GameState.gd ---
# This is the correct place for this logic.
func _unhandled_input(event: InputEvent):
	if event.is_action("ui_cancel") and event.is_pressed() and not event.is_echo():
		
		# Don't let the player pause if they are dead (game over)
		if GameState.game_is_over:
			return
			
		if get_tree().paused:
			# If we are already paused (in the menu), unpause
			unpause_game()
		else:
			# If we are in the game, pause
			pause_game()

func pause_game():
	get_tree().paused = true
	GameState.game_paused.emit() # Tell ourselves (and GameState)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unpause_game():
	get_tree().paused = false
	GameState.game_unpaused.emit() # Tell ourselves (and GameState)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
# --- END NEW PAUSE LOGIC ---


func _ready():
	# --- Connect to GameState signals ---
	GameState.player_health_changed.connect(_on_health_changed)
	GameState.sd_cards_changed.connect(_on_sd_cards_changed)
	GameState.monster_spotted.connect(_on_monster_spotted)
	GameState.monster_lost.connect(_on_monster_lost)
	GameState.monster_health_changed.connect(_on_monster_health_changed)
	GameState.player_hurt.connect(_on_player_hurt)
	
	# --- Connect to the signals we now emit ourselves ---
	GameState.game_paused.connect(_on_game_paused)
	GameState.game_unpaused.connect(_on_game_unpaused)

	# --- Connect pause menu buttons ---
	ResumeButton.pressed.connect(_on_resume_button_pressed)
	MainMenuButton.pressed.connect(_on_main_menu_button_pressed)

	# --- Set initial visibility ---
	crosshair.visible = false
	mr_ferrin_health_bar.visible = false
	PauseMenu.visible = false
	HurtEffect.visible = false
	
	_on_health_changed(GameState.player_health)
	_on_sd_cards_changed(GameState.sd_card_count)


# --- Player Stat Callbacks ---
func _on_health_changed(new_health: int):
	health_label.text = "Health: %s" % new_health

func _on_sd_cards_changed(new_count: int):
	sd_card_label.text = "SD Card Ammo: %s" % new_count
	crosshair.visible = (new_count > 0) and not get_tree().paused


# --- Mr. Ferrin's Signal Callbacks ---
func _on_monster_spotted(current_health, max_health):
	mr_ferrin_health_bar.max_value = max_health
	mr_ferrin_health_bar.value = current_health
	mr_ferrin_health_bar.visible = not get_tree().paused

func _on_monster_lost():
	mr_ferrin_health_bar.visible = false

func _on_monster_health_changed(current_health, max_health):
	mr_ferrin_health_bar.max_value = max_health
	mr_ferrin_health_bar.value = current_health


# --- Pause & Hurt Callbacks ---

func _on_game_paused():
	PauseMenu.visible = true
	InGameUI.visible = false
	crosshair.visible = false
	mr_ferrin_health_bar.visible = false
	
	# --- NEW: Also hide held item ---
	# We need to find the player and tell it to hide the item
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera3D/Visuals"):
		player.get_node("Camera3D/Visuals").visible = false

func _on_game_unpaused():
	PauseMenu.visible = false
	InGameUI.visible = true
	# Re-check visibility for crosshair
	crosshair.visible = (GameState.sd_card_count > 0)
	# Re-check visibility for boss bar
	# --- FIX: Check if boss is actually active ---
	var boss_is_active = mr_ferrin_health_bar.value > 0 and mr_ferrin_health_bar.value < mr_ferrin_health_bar.max_value
	mr_ferrin_health_bar.visible = boss_is_active
	
	# --- NEW: Also show held item ---
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera3D/Visuals"):
		# Re-check visibility based on ammo
		player.get_node("Camera3D/Visuals").visible = (GameState.sd_card_count > 0)


func _on_player_hurt():
	HurtEffect.visible = true
	get_tree().create_timer(0.2).timeout.connect(func(): HurtEffect.visible = false)


# --- Pause Menu Button Functions ---

func _on_resume_button_pressed():
	# We now call the function that lives in this same script
	unpause_game()

func _on_main_menu_button_pressed():
	# We must unpause *before* changing scenes, or the tree stays paused
	unpause_game()
	# Go back to the main menu
	get_tree().change_scene_to_file("res://MainMenu.tscn")
