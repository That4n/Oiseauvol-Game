extends Node 

@export var tuyau_scene : PackedScene = load("res://scenes/tuyau.tscn");

const SCROLL_SPEED : int = 4
const PIPE_DELAY : int = 100
const PIPE_RANGE : int = 200

var game_running : bool
var game_over : bool
var scroll : int
var score : int

var screen_size : Vector2i
var environnement_height : int
var pipes : Array

func _ready():
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
	
	if game_over:
		pass
		
	var trigger: bool = false;
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			trigger = true;
	elif event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			trigger = true
			
	if trigger:
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
	if tuyau_scene == null:
		print("Erreur : `tuyau_scene` est null au moment de l'instanciation.")
		return  # Stoppe la fonction pour éviter une erreur

	var tuyau = tuyau_scene.instantiate()
	if tuyau == null:
		print("Erreur : `tuyau` est null après instanciation.")
		return

	# Placer le tuyau à droite de l'écran
	tuyau.position.x = screen_size.x + PIPE_DELAY
	
	# Placer le tuyau à une hauteur aléatoire mais contrôlée (centrée sur l'écran)
	tuyau.position.y = (screen_size.y / 2) + randi_range(-PIPE_RANGE, PIPE_RANGE)
	
	# Vérification de la position pour le débogage
	print("Tuyau généré à: ", tuyau.position)

	if not tuyau.has_signal("hit"):
		print("Erreur : le signal `hit` n'existe pas dans tuyau.")
	else:
		tuyau.hit.connect(oiseau_hit)

	add_child(tuyau)  # Ajouter correctement à la scène
	pipes.append(tuyau)  # Ajouter à la liste des tuyaux

func oiseau_hit():
	pass  # Ajouter la logique pour le cas où l'oiseau touche un tuyau
