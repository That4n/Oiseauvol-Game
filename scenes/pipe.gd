extends Area2D

signal hit
signal scored

func _on_body_entered(body):
	hit.emit()

func _on_score_area_body_entered(body):
	scored.emit()

var initial_position: Vector2
var moving: bool = false
var move_direction: float = 0
var move_progression: float = 0
var move_speed: float = 50
var move_range: float = 100

# Variables pour les limites de mouvement
var min_limit: float = 0
var max_limit: float = 0

func _ready():
	initial_position = position
	calculate_movement_limits()

func calculate_movement_limits():
	# Dans votre scène, les tuyaux sont nommés "Upper" et "Lower"
	var upper = $Upper
	var lower = $Lower
	
	# On utilise les CollisionShape2D pour déterminer les dimensions
	var upper_collision = $CollisionShape2D3
	var lower_collision = $CollisionShape2D2
	
	# Hauteur des parties supérieure et inférieure
	var upper_height = upper_collision.shape.size.y
	var lower_height = lower_collision.shape.size.y
	
	# Positions des extrémités
	var upper_top = position.y + upper.position.y - upper_height/2
	var lower_bottom = position.y + lower.position.y + lower_height/2
	
	# Hauteur de la vue
	var viewport_height = get_viewport_rect().size.y
	
	# Calcul des limites
	min_limit = upper_height/2 - upper.position.y
	max_limit = viewport_height - lower_height/2 - lower.position.y
	
	# Ajustement de l'amplitude de mouvement pour ne pas sortir des limites
	var max_possible_range_up = initial_position.y - min_limit
	var max_possible_range_down = max_limit - initial_position.y
	move_range = min(move_range, max_possible_range_up, max_possible_range_down)

func _process(delta: float) -> void:
	if moving:
		if move_direction == 0:
			# Initialisation aléatoire de la direction
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			move_direction = sign(rng.randf_range(-1, 1))
			if move_direction == 0:
				move_direction = 1
		
		# Calcul du nouveau mouvement
		move_progression += move_direction * move_speed * delta
		
		# Calcul de la nouvelle position avec clamp pour rester dans les limites
		var new_y = initial_position.y + move_progression
		new_y = clamp(new_y, initial_position.y - move_range, initial_position.y + move_range)
		new_y = clamp(new_y, min_limit, max_limit)
		
		# Inversion de direction si on atteint une limite
		if abs(new_y - initial_position.y) >= move_range - 1:
			move_direction *= -1
		
		# Application de la nouvelle position
		position.y = new_y
		move_progression = position.y - initial_position.y

func set_moving(should_move: bool):
	moving = should_move
	if not moving:
		reset_position()

func reset_position():
	position = initial_position
	move_progression = 0
	move_direction = 0
