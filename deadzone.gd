extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is not RigidBody2D:
		return

	print("%s: body %s entered" % [name, body.name])
