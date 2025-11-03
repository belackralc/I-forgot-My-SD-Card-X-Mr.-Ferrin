extends Node

# --- Player Stats ---
var player_health: int = 100
var sd_card_count: int = 0
var sd_cards_total: int = 0
var game_is_over: bool = false

# --- Signals ---
signal player_health_changed(new_health)
signal sd_cards_changed(new_count)
signal monster_spotted(current_health, max_health)
signal monster_lost()
signal monster_health_changed(current_health, max_health)
signal player_hurt
@warning_ignore("unused_signal")
signal game_paused
@warning_ignore("unused_signal")
signal game_unpaused


# --- Scene References ---
var main_scene_path = "res://world.tscn"
var game_over_scene: PackedScene = preload("res://game_over.tscn")
var win_screen_scene: PackedScene = preload("res://win_screen.tscn")


func _ready():
	await get_tree().create_timer(0.01).timeout
	var sd_cards = get_tree().get_nodes_in_group("sd_card")
	sd_cards_total = sd_cards.size()
	sd_cards_changed.emit(sd_card_count)
	game_is_over = false


# --- NEW FUNCTION ---
# We create a public function that resets all stats to their defaults.
func reset_stats():
	print("[GameState] Resetting stats for new game.")
	player_health = 100
	sd_card_count = 0
	game_is_over = false
	# Ensure game is unpaused when we go back to menu
	get_tree().paused = false


# --- Player Functions ---
func take_damage(amount: int):
	if game_is_over:
		return
	player_health -= amount
	player_health_changed.emit(player_health)
	player_hurt.emit()
	
	if player_health <= 0:
		player_health = 0
		game_is_over = true
		_go_to_scene(game_over_scene)

func add_sd_card():
	if game_is_over:
		return
	sd_card_count += 1
	sd_cards_changed.emit(sd_card_count)

func use_sd_card():
	if game_is_over:
		return
	if sd_card_count > 0:
		sd_card_count -= 1
		sd_cards_changed.emit(sd_card_count)

# --- Monster Signal Pass-Throughs ---
func _on_monster_spotted(current_health, max_health):
	if game_is_over:
		return
	monster_spotted.emit(current_health, max_health)
	
func _on_monster_lost():
	if game_is_over:
		return
	monster_lost.emit()

func _on_monster_health_changed(current_health, max_health):
	if game_is_over:
		return
	monster_health_changed.emit(current_health, max_health)


# --- Win/Loss Logic ---
func _on_monster_died():
	if game_is_over:
		return
	game_is_over = true
	_go_to_scene(win_screen_scene)


func restart_game():
	# --- CLEANUP: We now use our new reset function ---
	reset_stats()
	get_tree().change_scene_to_file(main_scene_path)


func _go_to_scene(scene: PackedScene):
	get_tree().change_scene_to_packed(scene)
