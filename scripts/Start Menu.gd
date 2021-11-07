extends Control

export var player_text: PackedScene
export var player: PackedScene
export var spawn_pos: Vector3

onready var ip: SpinBox = get_node("Initial/IP/IP")
onready var username: LineEdit = get_node("Initial/Name/Name")
onready var color1: ColorPickerButton = get_node("Initial/Colour/main")
onready var color2: ColorPickerButton = get_node("Initial/Colour/highlight")
onready var init_menu = get_node("Initial")
onready var lobby_menu = get_node("Lobby Menu")
onready var player_list = get_node("Lobby Menu/Players")

var players = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# connect UI buttons to functions
	get_node("Initial/Host").connect("button_down", self, "host")
	get_node("Initial/Join").connect("button_down", self, "join")
	get_node("Initial/Quit").connect("button_down", self, "quit")
	get_node("Lobby Menu/Info/Play").connect("button_down", self, "play")

	print(get_tree().connect("network_peer_connected", self, "on_connected"))
	init_menu.visible = true;
	lobby_menu.visible = false;

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if ip.has_focus():
			join()

# called by UI button
func play():
	rpc("loadGame")

# called by play button of host
remotesync func loadGame():
	# destroy Lobby UI
	remove_child(init_menu)
	init_menu.queue_free()
	remove_child(lobby_menu)
	lobby_menu.queue_free()

	# load game scene
	var game_scene = load("res://scenes/game.tscn").instance()
	get_node("/root").add_child(game_scene)

	# instantiate
	var offset = 0
	for id in players:
		var player_instance = player.instance()
		player_instance.set_name(str(id))
		player_instance.transform.origin = spawn_pos + Vector3.RIGHT * offset
		offset += .5
		player_instance.set_network_master(id)
		game_scene.add_child(player_instance)

		# apply colours
		var mesh: MeshInstance = player_instance.get_node("boat/Mesh")
		var mat1 = mesh.get_surface_material(0).duplicate()
		mat1.albedo_color = players[id]["c1"]
		mesh.set_surface_material(0, mat1)

		var mat2 = mesh.get_surface_material(1).duplicate()
		mat2.albedo_color = players[id]["c2"]
		mesh.set_surface_material(1, mat2)

# called by UI button
func quit():
	get_tree().quit()

# called by UI button, initiated client conection
func join():
	var join_ip = "10.0.0.%d" % [ip.get_value()]
	print("joining ip " + join_ip)
	get_node("Lobby Menu/Info/IP").text = "Lobby ID: %d" % [ip.get_value()]

	var peer = NetworkedMultiplayerENet.new()
	print(peer.create_client(join_ip, 5500))
	get_tree().network_peer = peer

# called by UI button, initiates host server
func host():
	init_menu.visible = false;
	lobby_menu.visible = true;
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(5500, 4)
	get_tree().network_peer = peer

	# fill out ip_string
	var ip_string = "Lobby ID: "
	for x in IP.get_local_addresses():
		if x.begins_with("10."):
			ip_string += x.right(7) + "\n"
	get_node("Lobby Menu/Info/IP").text = ip_string
	players[get_tree().get_network_unique_id()] = {"name": username.text,"c1":color1.color, "c2": color2.color}
	update_players(players)

# called when a new player is connected
func on_connected(_id: int):
	print("user connected!")
	init_menu.visible = false;
	lobby_menu.visible = true;

	if !get_tree().is_network_server():
		get_node("Lobby Menu/Info/Play").disabled = true
	# registers a new player with the host
	rpc_id(1, "register_player", username.text, color1.color, color2.color)

# register new player host side
remotesync func register_player(player_name: String, c1: Color, c2: Color):
	var id = get_tree().get_rpc_sender_id()
	players[id] = {"name": player_name, "c1": c1, "c2": c2}
	rpc("update_players", players)

# push host player list to all instances
remotesync func update_players(player_info):
	players = player_info
	for c in player_list.get_children():
		player_list.remove_child(c)
		c.queue_free()
	for p in player_info:
		var inst = player_text.instance()
		player_list.add_child(inst)
		inst.get_node("name").text = "Player %d:  " %[p] + player_info[p]["name"]
		# set up colour selection in lobby
		var c1 = inst.get_node("main")
		c1.color = player_info[p]["c1"]
		var c2 = inst.get_node("highlight")
		c2.color = player_info[p]["c2"]
		if p == get_tree().get_network_unique_id():
			c1.connect("color_changed", self, "main_colour_change")
			c2.connect("color_changed", self, "highlight_colour_change")
		else:
			c1.disabled = true
			c2.disabled = true

	# print("updating list of players!")
	# print(players)


# manage editing colours in lobby
func main_colour_change(color):
	var id = get_tree().get_network_unique_id()
	rpc_id(1, "update_colours", id, color, color2.color)

func highlight_colour_change(color):
	var id = get_tree().get_network_unique_id()
	rpc_id(1, "update_colours", id, color1.color, color)

remotesync func update_colours(id, main: Color, high: Color):
	players[id]["c1"] = main
	players[id]["c2"] = high
	rpc("update_players", players)
