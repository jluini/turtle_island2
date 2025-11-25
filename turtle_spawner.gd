extends MultiplayerSpawner

@export var character : PackedScene

func _ready() -> void:
	spawn_function = custom_spawn_function

#func get_spawn_node():
	#return get_node(spawn_path)

func custom_spawn_function(data):
	#var spawn_node = get_spawn_node()
	print("custom_spawn_function(%s)" % [data])
	
	var new_turtle = character.instantiate()
	
	new_turtle.player_name = data[1]
	new_turtle.position = data[2]
	
	# spawn_node.add_child(new_turtle)
	
	return new_turtle
