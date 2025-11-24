extends Node2D

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

enum State {
	NOTHING,
	INITIAL,
	
	HOSTING,
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

@export var state : State = State.NOTHING
@export var peers : Array = []

func _ready() -> void:
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
	
	print("create_server -> ", error_string(error))
	
	if error:
		return error
	
	multiplayer.multiplayer_peer = peer
	set_state(State.CONNECTING)
	
	return error

###

func _add_peer(peer_id : int) -> void:
	peers.append(peer_id)
	print("Peers: %s" % [peers])

func _start_game() -> void:
	_rpc_start_game.rpc(peers)
	_start_simulation()

func _start_simulation():
	print("%s: _start_simulation" % [multiplayer.get_unique_id()])
	print("1: %s" % [%simulation.get_child_count()])
	for child in %simulation.get_children():
		child.free()
	print("2: %s" % [%simulation.get_child_count()])
	
	var scenario = map.instantiate()
	
	%simulation.add_child(scenario)
	print("3: %s" % [%simulation.get_child_count()])
	

func coso(e):
	print(e.name)

### RPCs

@rpc("authority", "call_remote", "reliable", 0)
func _rpc_start_game(peer_ids):
	self.peers = peer_ids
	print("%s: _rpc_start_game" % [multiplayer.get_unique_id()])
	_start_simulation()

### Network callbacks

func _on_peer_connected(id):
	print("%s: peer_connected %s" % [multiplayer.get_unique_id(), id])
	
	if state == State.HOSTING:
		_add_peer(id)
		pass
		
	elif state == State.CONNECTING and id == 1:
		print("%s: Soy cliente y me conecté a un server " % [multiplayer.get_unique_id()])
		set_state(State.CONNECTED)

func _on_peer_disconnected(id):
	print("%s: peer_disconnected %s" % [multiplayer.get_unique_id(), id])

func _on_connected_to_server():
	print("%s: connected_to_server" % [multiplayer.get_unique_id()])

func _on_connection_failed():
	print("%s: connection_failed" % [multiplayer.get_unique_id()])

func _on_server_disconnected():
	print("server_disconnected")
