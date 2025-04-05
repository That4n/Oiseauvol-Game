extends Node

@export var pipe_scene : PackedScene

var game_running : bool
var game_over : bool
var scroll
var score
const SCROLL_SPEED : int = 4
var screen_size : Vector2i
var ground_height : int
var pipes : Array
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200
var video_playing : bool = false

# Variables pour le switch de fond/thème
var is_day : bool = true
var last_switch_score : int = 0

# Références aux AudioStreamPlayers
@export var day_music : AudioStream
@export var night_music : AudioStream

func _ready():
	# Vérification et préchargement de la scène si nécessaire
	if pipe_scene == null:
		pipe_scene = load("res://Scenes/Pipe.tscn")  # Ajustez le chemin selon votre structure de projet
		if pipe_scene == null:
			push_error("Impossible de charger la scène de tuyau. Vérifiez le chemin dans _ready().")
	
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$VideoStreamPlayer.z_index = 100  # ou une valeur bien plus haute que les autres nodes

	# Initialisation des backgrounds
	$Background.show()    # Background de jour
	$Background2.hide()   # Background de nuit

	# Initialisation du sol (affiche le sol de jour)
	$Ground.get_node("Sprite2D").show()
	$Ground.get_node("Sprite2D2").hide()

	# Configurer les streams audio
	if day_music != null:
		$AudioStreamPlayer.stream = day_music
	if night_music != null:
		$AudioStreamPlayer2.stream = night_music
	
	# Démarrer la musique de jour au début
	$AudioStreamPlayer.play()

	# Si on a une vidéo, on la joue
	if $VideoStreamPlayer:
		video_playing = true
		$VideoStreamPlayer.play()
		$VideoStreamPlayer.finished.connect(_on_video_finished)
	else:
		new_game()

func _on_video_finished():
	video_playing = false
	$VideoStreamPlayer.hide()
	new_game()

func skip_video():
	if $VideoStreamPlayer:
		$VideoStreamPlayer.stop()
		$VideoStreamPlayer.hide()
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
	$Background.show()
	$Background2.hide()
	$Ground.get_node("Sprite2D").show()
	$Ground.get_node("Sprite2D2").hide()
	last_switch_score = 0

	# Réinitialisation de la musique au démarrage
	$AudioStreamPlayer2.stop()
	$AudioStreamPlayer.play()

func _input(event):
	if video_playing:
		if event is InputEventMouseButton and event.pressed:
			skip_video()
		return

	if game_over == false:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if game_running == false:
					start_game()
				else:
					if $Bird.flying:
						$Bird.flap()
						check_top()

func start_game():
	game_running = true
	$Bird.flying = true
	$Bird.flap()
	$PipeTimer.start()
	# Cacher le message d'instruction quand le jeu commence
	$StartPrompt.hide()

func _process(delta):
	if game_running:
		scroll += SCROLL_SPEED
		if scroll >= screen_size.x:
			scroll = 0
		$Ground.position.x = -scroll
		for pipe in pipes:
			pipe.position.x -= SCROLL_SPEED

func _on_pipe_timer_timeout():
	generate_pipes()

func generate_pipes():
	if pipe_scene == null:
		push_error("pipe_scene est toujours null après tentative de chargement!")
		return
		
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
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
	
	add_child(pipe)
	pipes.append(pipe)

func scored():
	score += 1
	$ScoreLabel.text = "SCORE: " + str(score)
	
	# Vérifie si le score est multiple de 10 et que c'est un nouveau palier
	if score > 0 and score % 10 == 0 and score != last_switch_score:
		is_day = not is_day  # Inverse l'état
		if is_day:
			# Passage au mode jour
			$Background.show()
			$Background2.hide()
			$Ground.get_node("Sprite2D").show()
			$Ground.get_node("Sprite2D2").hide()
			
			# Change la musique pour le jour
			$AudioStreamPlayer2.stop()
			$AudioStreamPlayer.play()
			print("Switching to day music")
		else:
			# Passage au mode nuit
			$Background.hide()
			$Background2.show()
			$Ground.get_node("Sprite2D").hide()
			$Ground.get_node("Sprite2D2").show()
			
			# Change la musique pour la nuit
			$AudioStreamPlayer.stop()
			$AudioStreamPlayer2.play()
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
