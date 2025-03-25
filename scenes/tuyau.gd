extends Area2D

signal hit

var scored: bool = false
var initial_position: Vector2

var moving: bool = false
var move_direction: float = 0
var move_progression: float = 0
var move_speed: float = 50
var move_range: float = 100

var min_limit: float = 0
var max_limit: float = 0

func _ready():
	initial_position = position
	calculate_movement_limits()

func calculate_movement_limits():
	if has_node("haut") and has_node("bas"):
		var haut = $haut
		var bas = $bas
		
		var haut_height = haut.texture.get_height() * haut.scale.y
		var bas_height = bas.texture.get_height() * bas.scale.y
		
		var haut_top = position.y + haut.position.y - haut_height/2
		var bas_bottom = position.y + bas.position.y + bas_height/2
		
		var viewport_height = get_viewport_rect().size.y
		min_limit = haut_height/2 - haut.position.y
		max_limit = viewport_height - bas_height/2 - bas.position.y
		
		var max_possible_range_up = initial_position.y - min_limit
		var max_possible_range_down = max_limit - initial_position.y
		move_range = min(move_range, max_possible_range_up, max_possible_range_down)

func _process(delta: float) -> void:
	if moving:
		if move_direction == 0:
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			move_direction = sign(rng.randf_range(-1, 1))
			if move_direction == 0:
				move_direction = 1
			
		move_progression += move_direction * move_speed * delta
		
		var new_y = initial_position.y + move_progression
		new_y = clamp(new_y, min_limit, max_limit)
		
		if new_y <= min_limit or new_y >= max_limit:
			move_direction *= -1
		
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
