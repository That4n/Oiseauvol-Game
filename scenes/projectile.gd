extends Area2D

const GRAVITY: float = 15
const SPEED: float = 350
const ROTATION: float = 150;

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	
	var screen_size = get_window().size;
	if position.x  < 0 or position.x > screen_size.x:
		queue_free();
		return;
		
	position += Vector2(SPEED, GRAVITY) * delta;
	rotation += deg_to_rad(ROTATION) * delta;
