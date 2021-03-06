extends Control

export var player_text: PackedScene
export var player: PackedScene
export var spawn_pos: Vector3
export (Array, Mesh) var boats
export var base_mat: SpatialMaterial
export var high_mat: SpatialMaterial

onready var ip: SpinBox = get_node("Initial/IP/IP")
onready var username: LineEdit = get_node("Initial/Name/Name")
onready var color1: ColorPickerButton = get_node("Initial/Colour/main")
onready var color2: ColorPickerButton = get_node("Initial/Colour/highlight")
onready var init_menu = get_node("Initial")
onready var lobby_menu = get_node("Lobby Menu")
onready var player_list = get_node("Lobby Menu/Players")

var boat_spin: SpinBox
var boat: int = 0
var boat_rots = [0]

var players = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	# connect UI buttons to functions
	get_node("Initial/Host").connect("button_down", self, "host")
	get_node("Initial/Join").connect("button_down", self, "join")
	get_node("Initial/Quit").connect("button_down", self, "quit")
	get_node("Lobby Menu/Info/Play").connect("button_down", self, "play")

	get_tree().connect("network_peer_connected", self, "on_connected")
	init_menu.visible = true;
	lobby_menu.visible = false;

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if ip.has_focus():
			join()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# called by UI button
func play():
	rpc("loadGame")

# called by play button of host
remotesync func loadGame(reload = false):
	if reload:
		var prev_game_scene = get_node("../game")
		get_node("..").remove_child(prev_game_scene)
		prev_game_scene.queue_free()
	else:
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
	var judge = game_scene.get_node("Judge")
	for id in players:
		var player_instance = player.instance()
		player_instance.set_name(str(id))
		player_instance.transform.origin = spawn_pos + Vector3.RIGHT * offset
		offset += .5
		player_instance.set_network_master(id)
		game_scene.add_child(player_instance)

		# apply colours
		var mesh: MeshInstance = player_instance.get_node("boat/Mesh")
		mesh.mesh = boats[players[id]["boat"]]

		var mat1 = base_mat.duplicate()
		mat1.albedo_color = players[id]["c1"]
		mesh.set_surface_material(0, mat1)

		var mat2 = high_mat.duplicate()
		mat2.albedo_color = players[id]["c2"]
		mesh.set_surface_material(1, mat2)
		player_instance.get_node("boat/flag/base/flag").set_surface_material(0, mat2)

		player_instance.get_node("boat/Orb").set_surface_material(0, mat1)
		if id == get_tree().get_network_unique_id():
			player_instance.get_node("VCon/View/Camera").global_transform.origin = Vector3.UP * 250
		else:
			player_instance.get_node("VCon/View/Camera").queue_free()

		judge.init(player_instance.get_node("boat"), players[id]["name"])

func reload():
	print("reloading...")
	rpc("loadGame", true)

func menu():
	print("returning to menu")
	rpc("return_to_menu")

remotesync func return_to_menu():
	get_node("../game").queue_free()
	queue_free()
	get_tree().change_scene("res://scenes/Start Menu.tscn")
	get_tree().network_peer = null

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
	players[get_tree().get_network_unique_id()] = {"name": username.text,"c1":color1.color, "c2": color2.color, "boat": 0}
	update_players(players)

# called when a new player is connected
func on_connected(_id: int):
	print("user connected!")
	init_menu.visible = false;
	lobby_menu.visible = true;

	if !get_tree().is_network_server():
		get_node("Lobby Menu/Info/Play").queue_free()
	# registers a new player with the host
	rpc_id(1, "register_player", username.text, color1.color, color2.color)

# register new player host side
remotesync func register_player(player_name: String, c1: Color, c2: Color):
	var id = get_tree().get_rpc_sender_id()
	players[id] = {"name": player_name, "c1": c1, "c2": c2, "boat": 0}
	rpc("update_players", players)

# push host player list to all instances
remotesync func update_players(player_info):
	players = player_info
	var i = 0
	for c in player_list.get_children():
		if i < boat_rots.size():
			boat_rots[i] = c.get_node("VCon/View/Boat").rotation_degrees.y
		else:
			boat_rots.append(0)
		i+= 1
		player_list.remove_child(c)
		c.queue_free()

	i = 0
	for p in player_info:
		var inst = player_text.instance()
		player_list.add_child(inst)
		inst.get_node("HBox/name").text = player_info[p]["name"]

		# set up colour selection in lobby
		var c1 = inst.get_node("HBox/main")
		c1.color = player_info[p]["c1"]
		var c2 = inst.get_node("HBox/highlight")
		c2.color = player_info[p]["c2"]

		# set up boat selection in lobby
		var b_val = inst.get_node("HBox/boat")
		b_val.value = player_info[p]["boat"]

		var mesh: MeshInstance = inst.get_node("VCon/View/Boat")
		mesh.mesh = boats[player_info[p]["boat"]]
		if i < boat_rots.size():
			mesh.rotation_degrees.y = boat_rots[i]
		else:
			boat_rots.append(0)

		# colour boat properly
		var mat1 = base_mat.duplicate()
		mat1.albedo_color = player_info[p]["c1"]
		mesh.set_surface_material(0, mat1)

		var mat2 = high_mat.duplicate()
		mat2.albedo_color = player_info[p]["c2"]
		mesh.set_surface_material(1, mat2)

		# connect lobby colour pickers to update functions
		if p == get_tree().get_network_unique_id():
			c1.connect("color_changed", self, "main_colour_change")
			c2.connect("color_changed", self, "highlight_colour_change")
			c1.connect("popup_closed", self, "on_colour_picker_close")
			c2.connect("popup_closed", self, "on_colour_picker_close")
			b_val.connect("value_changed", self, "boat_change")
			inst.get_node("HBox/name").text += "\n(You)"
			boat_spin = b_val
		else:
			c1.queue_free()
			c2.queue_free()
			b_val.queue_free()

	# print("updating list of players!")
	# print(players)


# manage editing colours in lobby
func main_colour_change(color):
	var id = get_tree().get_network_unique_id()
	players[id]["c1"] = color

func highlight_colour_change(color):
	var id = get_tree().get_network_unique_id()
	players[id]["c2"] = color

func on_colour_picker_close():
	var id = get_tree().get_network_unique_id()
	rpc_id(1, "update_colours", id, players[id])

# update master colours when selected
remotesync func update_colours(id, val):
	players[id] = val
	rpc("update_players", players)

# manage editing boat in lobby
func boat_change(val):
	# print(val)
	var id = get_tree().get_network_unique_id()
	players[id]["boat"] = val
	boat_spin.release_focus()
	rpc_id(1, "update_boat", id, players[id])

# update server values of boats
remotesync func update_boat(id, val):
	players[id] = val
	rpc("update_players", players)
