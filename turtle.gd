extends DynamicBody

@export var player_name = "carlos":
	set(new_player_name):
		player_name = new_player_name
		$label.text = new_player_name
