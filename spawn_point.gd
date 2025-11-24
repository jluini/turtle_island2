@tool

extends Marker2D

@export var player : int = 0:
	set(new_player):
		player = new_player
		queue_redraw()

@export var flipped : bool = false:
	set(new_flipped):
		flipped = new_flipped
		queue_redraw()

const COLORS = [
	Color.LIGHT_GRAY,
	Color.BLUE,
	Color.RED,
	Color.GREEN,
	Color.YELLOW,
	Color.CYAN,
	Color.MAGENTA,
	Color.DARK_GRAY,
	Color.ORANGE
]

const ERROR_COLOR = Color.BLANCHED_ALMOND

func _draw():
	if Engine.is_editor_hint():
		var origin : Vector2 = Vector2.ZERO
		var delta : Vector2 = Vector2(30.0, 0.0)
		var factor = -1.0 if flipped else +1.0
		var color = get_color()
		
		draw_line(origin, origin + factor * delta, color, 4.0)

func get_color() -> Color:
	if player >= 0 and player < COLORS.size():
		return COLORS[player]
	else:
		return ERROR_COLOR
