extends Control

export var player_text: PackedScene

onready var ip: SpinBox = get_node("Initial/IP/IP")
onready var init_menu = get_node("Initial")
onready var lobby_menu = get_node("Lobby Menu")
onready var players = get_node("Lobby Menu/Players")

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Initial/Host").connect("button_down", self, "host")
	get_node("Initial/Join").connect("button_down", self, "join")
	get_node("Initial/Quit").connect("button_down", self, "quit")
	get_node("Lobby Menu/Info/Play").connect("button_down", self, "play")

	print(get_tree().connect("network_peer_connected", self, "on_connected"))
	init_menu.visible = true;
	lobby_menu.visible = false;

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		print("enter pressed")
		if get_focus_owner() && get_focus_owner().name == "@@5":
			join()

remotesync func play():
	rpc(loadGame())

remotesync func loadGame():
	get_tree().change_scene("res://scenes/game.tscn")

func quit():
	get_tree().quit()

func join():
	print("join ip " + "10.0.0.%d" % [ip.get_value()])

	var peer = NetworkedMultiplayerENet.new()
	print(peer.create_client("10.0.0.%d" % [ip.get_value()], 5500))
	get_tree().network_peer = peer

func host():
	init_menu.visible = false;
	lobby_menu.visible = true;
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(5500, 4)
	get_tree().network_peer = peer

	var ip_string = "Lobby ID: "
	for x in IP.get_local_addresses():
		if x.begins_with("10."):
			ip_string += x.right(7) + "\n"
	get_node("Lobby Menu/Info/IP").text = ip_string

func on_connected(id: int):
	print("user connected!")
	init_menu.visible = false;
	lobby_menu.visible = true;

	var p = player_text.instance()
	players.add_child(p)
	p.text = "Player %d" %[id]

	if !get_tree().is_network_server():
		get_node("Lobby Menu/Info/Play").disabled = true
