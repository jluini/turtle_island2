extends Node2D

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

enum State {
	NOTHING,
	INITIAL,
	
	HOSTING,
	STARTING,
	WAITING,
	CELEBRATING,
	
	CONNECTING,
	CONNECTED,
	
	PLAYING_LOCALLY,
	PLAYING_REMOTELLY,
	SETTLING
}

@export var map : PackedScene
@export var character : PackedScene
@export var stone : PackedScene

@export var state : State = State.NOTHING
@export var peers : Array = []

var stone_number = 0

func _ready() -> void:
	#ProjectSettings.set_setting("physics/2d/default_gravity", 0)
	#PhysicsServer2D.area_set_param(get_viewport().find_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, Vector2(1.0, 0.0))
	
	get_window().position = Vector2.ZERO
	
	set_state(State.INITIAL)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _input(event: InputEvent) -> void:
	if state == State.INITIAL:
		if event.is_action_pressed("ui_page_down"):
			_start_server()
			
		elif event.is_action_pressed("ui_page_up"):
			_start_client()
	elif state == State.HOSTING:
		if event.is_action_pressed("ui_accept"):
			if peers.size() > 1 or true:
				_start_game()
	
	elif state == State.STARTING:
		if event.is_action_pressed("ui_accept"):
			_start_game2()
	
	elif state == State.SETTLING:
		if event is InputEventMouseButton and event.is_pressed():
			var mouse_event : InputEventMouseButton = event
			if mouse_event.button_index == MOUSE_BUTTON_LEFT:
				var target : Vector2 = get_canvas_transform().affine_inverse() * mouse_event.position
				print(target)
				add_a_stone(target)
			
###

func set_state(new_state : State) -> void:
	$ui/state_label.text = State.find_key(new_state)
	self.state = new_state

###

func _start_server():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, 1)
	
	print("create_server -> ", error_string(error))
	
	if error:
		return error
	
	multiplayer.multiplayer_peer = peer
	set_state(State.HOSTING)
	peers = [1]
	
	return error

func _start_client():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	
	print("create_client -> ", error_string(error))
	
	if error:
		return error
	
	multiplayer.multiplayer_peer = peer
	set_state(State.CONNECTING)
	
	return error

###

func _add_peer(peer_id : int) -> void:
	peers.append(peer_id)
	print("Peers: %s" % [peers])

# only server
func _start_game() -> void:
	#_rpc_start_game.rpc(peers)
	#_start_server_simulation()
	set_state(State.STARTING)
	_clear_simulation()
	
	var scenario = map.instantiate()
	%simulation.add_child(scenario)
	
	#var turtle = character.instantiate()
	#turtle.position = %simulation.get_node("map/spawn_points/spawn_1_1").position
	#%simulation.add_child(turtle)
	
	#var turtle2 = character.instantiate()
	#turtle2.position = %simulation.get_node("map/spawn_points/spawn_2_1").position
	#turtle2.player_name = "222"
	#%simulation.add_child(turtle2)
	
	#var turtle11 = $turtle_spawner.spawn(["turtle.tscn", "1-1", %simulation.get_node("map/spawn_points/spawn_1_1").position])
	#var turtle12 = $turtle_spawner.spawn(["turtle.tscn", "1-2", %simulation.get_node("map/spawn_points/spawn_1_2").position])
	#var turtle21 = $turtle_spawner.spawn(["turtle.tscn", "2-1", %simulation.get_node("map/spawn_points/spawn_2_1").position])
	#var turtle22 = $turtle_spawner.spawn(["turtle.tscn", "2-2", %simulation.get_node("map/spawn_points/spawn_2_2").position])
	add_a_turtle(1, 1)
	add_a_turtle(1, 2)
	add_a_turtle(2, 1)
	add_a_turtle(2, 2)

func _start_game2():
	for c in %simulation.get_children():
		if c is RigidBody2D:
			c.gravity_scale = 1.0
	
	set_state(State.SETTLING)
	

func add_a_stone(position : Vector2):
	var new_stone = stone.instantiate()
	stone_number += 1
	new_stone.name = "stone_%s" % stone_number
	new_stone.position = position
	
	%simulation.add_child(new_stone)

func add_a_turtle(player_number, turtle_number):
	var new_turtle = character.instantiate()
	new_turtle.name = "turtle_%s_%s" % [player_number, turtle_number]
	new_turtle.position = %simulation.get_node("map/spawn_points/spawn_%s_%s" % [player_number, turtle_number]).position
	new_turtle.player_name = "%s-%s" % [player_number, turtle_number]
	
	%simulation.add_child(new_turtle)

# only server
func _start_server_simulation():
	_load_scenario()

# only client
func _start_client_simulation():
	#_load_scenario(true)
	_clear_simulation()

func _clear_simulation():
	for child in %simulation.get_children():
		if child.name == "map":
			child.free()
		else:
			child.free()

func _load_scenario(empty = false):
	#print("%s: load_scenario(%s)" % [multiplayer.get_unique_id(), empty])
	_clear_simulation()
	
	var scenario = map.instantiate()
	
	if empty:
		for c in scenario.get_children():
			if c.is_in_group("dynamic_object"):
				c.free()
		
	%simulation.add_child(scenario)

func coso(e):
	print(e.name)

### RPCs

#@rpc("authority", "call_remote", "reliable", 0)
#func _rpc_start_game(peer_ids):
	#self.peers = peer_ids
	#print("%s: _rpc_start_game" % [multiplayer.get_unique_id()])
	#call_deferred("_start_client_simulation")

### Network callbacks

func _on_peer_connected(id):
	print("%s: peer_connected %s" % [multiplayer.get_unique_id(), id])
	
	if state == State.HOSTING:
		_add_peer(id)
		pass
		
	elif state == State.CONNECTING and id == 1:
		print("%s: Soy cliente y me conecté a un server " % [multiplayer.get_unique_id()])
		set_state(State.CONNECTED)
		
		_clear_simulation()
		

func _on_peer_disconnected(id):
	print("%s: peer_disconnected %s" % [multiplayer.get_unique_id(), id])

func _on_connected_to_server():
	print("%s: connected_to_server" % [multiplayer.get_unique_id()])

func _on_connection_failed():
	print("%s: connection_failed" % [multiplayer.get_unique_id()])

func _on_server_disconnected():
	print("server_disconnected")


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	# print("Spawned this: %s" % [node.name])
	pass

func _on_turtle_spawner_despawned(node: Node) -> void:
	print("Despawned this: %s" % [node.name])
