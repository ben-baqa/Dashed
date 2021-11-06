extends Control

onready var ip: LineEdit = get_node("Initial/IP/IP")
onready var init_menu = get_node("Initial")
onready var lobby_menu = get_node("Lobby Menu")

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Initial/Host").connect("button_down", self, "host")
	get_node("Initial/Join").connect("button_down", self, "join")
	get_node("Initial/Quit").connect("button_down", self, "quit")
	get_node("Lobby Menu/Info/Play").connect("button_down", self, "play")

	get_tree().connect("network_peer_connected", self, "on_connected")
	init_menu.visible = true;
	lobby_menu.visible = false;


func play():
	print("play pressed")
	get_tree().change_scene("res://scenes/game.tscn")

func quit():
	print("Quit")
	get_tree().quit()

func join():
	print("join ip " + ip.text)
	init_menu.visible = false;
	lobby_menu.visible = true;

	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip.text, 5500)
	get_tree().network_peer = peer

func host():
	print("host")
	init_menu.visible = false;
	lobby_menu.visible = true;

	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(5500, 4)
	get_tree().network_peer = peer

	var ip_string = "IP: "
	for x in IP.get_local_addresses():
		ip_string += x + "\n"
	get_node("Lobby Menu/Info/IP").text = ip_string

func on_connected(id: int):
	print("user connected!")
