extends Area2D

signal hit

var scored: bool = false;

func _on_body_entered(body: Node2D) -> void:
	hit.emit()  
