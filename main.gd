extends Node 

@export var tuyau_scene : PackedScene

var game_running : bool
var game_over : bool
var scroll : int
var score : int
const SCROLL_SPEED : int = 4
var screen_size : Vector2i
var environnement_height : int
var pipes : Array
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200

func _ready():
	# Assurez-vous que tuyau_scene est bien chargé
	if tuyau_scene == null:
		tuyau_scene = load("res://tuyau.tscn")
	if tuyau_scene == null:
		print("Erreur : la scène tuyau n'a pas été trouvée.")
	
	screen_size = get_window().size
	environnement_height = $Environnement.get_node("Sprite2D").texture.get_height()
	new_game()

func new_game():
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	pipes.clear()
	generate_pipes()
	$Oiseau.reset()

func _input(event):
	if not game_over:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if not game_running:
					start_game()
				else:
					if $Oiseau.flying:
						$Oiseau.flap()

func start_game():
	game_running = true
	$Oiseau.flying = true
	$Oiseau.flap()
	$TuyauTimer.start()

func _process(_delta):
	if game_running:
		scroll += SCROLL_SPEED
		if scroll >= screen_size.x:
			scroll = 0
		$Environnement.position.x = -scroll
		for tuyau in pipes:
			tuyau.position.x -= SCROLL_SPEED

func _on_tuyau_timer_timeout() -> void:
	generate_pipes()

func generate_pipes():
	var tuyau = tuyau_scene.instantiate()
	
	# Placer le tuyau à droite de l'écran
	tuyau.position.x = screen_size.x + PIPE_DELAY
	
	# Placer le tuyau à une hauteur aléatoire mais contrôlée (centrée sur l'écran)
	tuyau.position.y = (screen_size.y / 2) + randi_range(-PIPE_RANGE, PIPE_RANGE)
	
	# Vérification de la position pour le débogage
	print("Tuyau généré à: ", tuyau.position)

	tuyau.hit.connect(oiseau_hit)
	add_child(tuyau)  # Ajouter correctement à la scène
	
func oiseau_hit():
	pass  # Ajouter la logique pour le cas où l'oiseau touche un tuyau
