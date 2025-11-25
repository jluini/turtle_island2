extends RigidBody2D
class_name DynamicBody

@export var synced_transform : Transform2D

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		transform = synced_transform

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if is_multiplayer_authority():
		synced_transform = state.transform
	else:
		state.transform = synced_transform
