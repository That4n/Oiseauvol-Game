extends Node

@export var pipe_scene : PackedScene = load("res://scenes/pipe.tscn");

const SCROLL_SPEED : int = 3
const SPEED_FACTOR: int = 100

const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200
const PIPE_MOVING : int = 3
const PIPE_DELAY_DECREASE = 10

var game_running : bool
var game_over : bool
var scroll
var score

var screen_size : Vector2i
var ground_height : int
var video_playing : bool = false

var pipes : Array
var pipe_delay = PIPE_DELAY;

# Variables pour le switch de fond/thème
var is_day : bool = true
var last_switch_score : int = 0
const DAY_SWITCH: int = 3

# Références aux AudioStreamPlayers
@export var day_music : AudioStream
@export var night_music : AudioStream

func _ready():

	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$"Video-Cinematique".z_index = 100  # ou une valeur bien plus haute que les autres nodes

	# Initialisation des backgrounds
	$"Fond-Jour".show()    # Background de jour
	$"Fond-Nuit".hide()   # Background de nuit

	# Initialisation du sol (affiche le sol de jour)
	$Ground.get_node("Sprite2D").show()
	$Ground.get_node("Sprite2D2").hide()

	# Configurer les streams audio
	if day_music != null:
		$"Audio-Fond".stream = day_music
	if night_music != null:
		$"Audio-Fond-Acceleré".stream = night_music
	
	# Démarrer la musique de jour au début
	$"Audio-Fond".play()

	# Si on a une vidéo, on la joue
	if $"Video-Cinematique":
		video_playing = true
		$"Video-Cinematique".play()
		$"Video-Cinematique".finished.connect(_on_video_finished)
	else:
		new_game()

func _on_video_finished():
	video_playing = false
	$"Video-Cinematique".hide()
	new_game()

func skip_video():
	if $"Video-Cinematique":
		$"Video-Cinematique".stop()
		$"Video-Cinematique".hide()
	video_playing = false
	new_game()

func new_game():
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	$ScoreLabel.text = "SCORE: " + str(score)
	$GameOver.hide()
	# Afficher le message d'instruction
	$StartPrompt.show()
	get_tree().call_group("pipes", "queue_free")
	pipes.clear()
	generate_pipes()
	$Bird.reset()
	
	# Réinitialise le thème au démarrage : état de jour
	is_day = true
	$"Fond-Jour".show()
	$"Fond-Nuit".hide()
	$Ground.get_node("Sprite2D").show()
	$Ground.get_node("Sprite2D2").hide()
	last_switch_score = 0

	# Réinitialisation de la musique au démarrage
	$"Audio-Fond".play()
	$"Audio-Fond-Acceleré".stop()

func _input(event):
		
	var trigger: bool = false;
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			trigger = true;
	elif event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			trigger = true
			
	if trigger:
		
		if video_playing:
			skip_video();
			return;
			
		if game_over:
			pass
		
		if not game_running:
			start_game()
		else:
			if $Bird.flying:
				$Bird.flap()
				check_top()

func start_game():
	is_day = true;
	game_running = true
	$Bird.flying = true
	$Bird.flap()
	$PipeTimer.start()
	# Cacher le message d'instruction quand le jeu commence
	$StartPrompt.hide()

func _process(delta):
	if game_running:
		scroll += SCROLL_SPEED * delta * SPEED_FACTOR  # Le *100 permet de garder une valeur raisonnable pour SCROLL_SPEED
		if scroll >= screen_size.x:
			scroll = 0
		$Ground.position.x = -scroll
		for pipe in pipes:
			pipe.position.x -= SCROLL_SPEED * delta * SPEED_FACTOR
			
			if pipe.moving and abs(pipe.position.x - $Bird.position.x) < 50:
				pipe.moving = false;

func _on_pipe_timer_timeout():
	generate_pipes()

func generate_pipes():
	
	if score > 0 and score % PIPE_DELAY_DECREASE == 0:
		if pipe_delay > PIPE_DELAY / 3:
			pipe_delay = min(PIPE_DELAY, pipe_delay - 10)
		
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + pipe_delay
	pipe.position.y = (screen_size.y - ground_height) / 2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	
	# Met à jour le thème pour les tuyaux :
	# Si c'est le jour, on affiche la version jour (day nodes) et on cache la version nuit
	# Sinon, on fait l'inverse.
	if is_day:
		if pipe.has_node("Upper-nuit"):
			pipe.get_node("Upper-nuit").hide()
		if pipe.has_node("Lower-nuit"):
			pipe.get_node("Lower-nuit").hide()
		if pipe.has_node("Upper"):
			pipe.get_node("Upper").show()
		if pipe.has_node("Lower"):
			pipe.get_node("Lower").show()
	else:
		if pipe.has_node("Upper"):
			pipe.get_node("Upper").hide()
		if pipe.has_node("Lower"):
			pipe.get_node("Lower").hide()
		if pipe.has_node("Upper-nuit"):
			pipe.get_node("Upper-nuit").show()
		if pipe.has_node("Lower-nuit"):
			pipe.get_node("Lower-nuit").show()
			
	if len(pipes) > 0 and len(pipes) % PIPE_MOVING == 0:
		pipe.initial_position = Vector2(pipe.position);
		pipe.set_moving(true)
	
	add_child(pipe)
	pipes.append(pipe)

func scored():
	score += 1
	$ScoreLabel.text = "SCORE: " + str(score)
	
	# Vérifie si le score est multiple de 10 et que c'est un nouveau palier
	if score > 0 and score % DAY_SWITCH == 0 and score != last_switch_score:
		is_day = not is_day  # Inverse l'état
		if is_day:
			# Passage au mode jour
			$"Fond-Jour".show()
			$"Fond-Nuit".hide()
			$Ground.get_node("Sprite2D").show()
			$Ground.get_node("Sprite2D2").hide()
			
			# Change la musique pour le jour
			$"Audio-Fond-Acceleré".stop()
			$"Audio-Fond".play()
			print("Switching to day music")
		else:
			# Passage au mode nuit
			$"Fond-Jour".hide()
			$"Fond-Nuit".show()
			$Ground.get_node("Sprite2D").hide()
			$Ground.get_node("Sprite2D2").show()
			
			# Change la musique pour la nuit
			$"Audio-Fond".stop()
			$"Audio-Fond-Acceleré".play()
			print("Switching to night music")

		last_switch_score = score
		
		# Optionnel : mettre à jour les tuyaux existants
		for pipe in pipes:
			if is_day:
				if pipe.has_node("Upper-nuit"):
					pipe.get_node("Upper-nuit").hide()
				if pipe.has_node("Lower-nuit"):
					pipe.get_node("Lower-nuit").hide()
				if pipe.has_node("Upper"):
					pipe.get_node("Upper").show()
				if pipe.has_node("Lower"):
					pipe.get_node("Lower").show()
			else:
				if pipe.has_node("Upper"):
					pipe.get_node("Upper").hide()
				if pipe.has_node("Lower"):
					pipe.get_node("Lower").hide()
				if pipe.has_node("Upper-nuit"):
					pipe.get_node("Upper-nuit").show()
				if pipe.has_node("Lower-nuit"):
					pipe.get_node("Lower-nuit").show()

func check_top():
	if $Bird.position.y < 0:
		$Bird.falling = true
		stop_game()

func stop_game():
	$PipeTimer.stop()
	$GameOver.show()
	$Bird.flying = false
	game_running = false
	game_over = true

func bird_hit():
	$Bird.falling = true
	stop_game()

func _on_ground_hit():
	$Bird.falling = false
	stop_game()

func _on_game_over_restart():
	new_game()
