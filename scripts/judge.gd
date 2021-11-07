extends Node

export var laps: int = 3
export var menu_entry: PackedScene

var checkpoints = []
var progress = {}

onready var end_menu = get_child(0)
onready var place = get_child(1)
onready var lap = get_child(2)
var my_bod:Node = null

var finish_count = 0
var time = 0
var my_bod_set = false

func _ready():
	end_menu.visible = false
	end_menu.get_node("VBox/Con").visible = false
	end_menu.get_node("VBox/Con/Play").connect("button_down", get_node("../../Start Menu"), "reload")
	end_menu.get_node("VBox/Con/Menu").connect("button_down", get_node("../../Start Menu"), "menu")

func _process(delta):
	time += delta
	if my_bod_set:
		# print(progress)
		lap.text = "Lap %d" %[progress[my_bod][1]]
		find_place()


var i = 0
func register_checkpoint(c):
	checkpoints.append(c)
	c.index = i
	i += 1

func init(body, name):
	progress[body] = [0,0, name]
	if body.is_network_master():
		my_bod = body
		my_bod_set = true

func pass_checkpoint(body, index):
	if index != progress[body][0] && !progress[body][0] == checkpoints.size():
		return

	progress[body][0] += 1
	if progress[body][0] > checkpoints.size():
		progress[body][0] = 1
		progress[body][1] += 1
	if progress[body][1] == laps:
		print(progress[body][2] + " Finished")
		finish_count += 1
		var inst = menu_entry.instance()
		inst.get_node("Place").text = "%d" %[finish_count]
		inst.get_node("Name").text = progress[body][2]
		inst.get_node("Time").text = format_time(time)
		end_menu.get_child(0).add_child(inst)

		if finish_count == progress.size() && get_tree().is_network_server():
			end_menu.get_node("VBox/Con").visible = true

		if body.is_network_master():
			end_menu.visible = true
			body.get_node("../VCon").visible = false

func find_place():
	var p = progress.duplicate()
	var ar = []

	for i in progress.size():
		var f = get_furthest(p)
		p.erase(f)
		ar.append(f)
		place.text = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"][i]
	print(ar)

func get_furthest(p):
	var furthest = null
	for b in p:
		if !furthest:
			furthest = b
			continue
		var d = p[b]
		if d[1] > p[furthest][1]:
			furthest = b
		elif d[1] == p[furthest][1] && d[0] > p[furthest][0]:
			furthest = b
		elif d[1] == p[furthest][1] && d[0] == p[furthest][0]:
			var c = checkpoints[d[0]].global_transform.origin
			if b.global_transform.origin.distance_to(c) < furthest.global_transform.origin.distance_to(c):
				furthest = b
	return furthest


func format_time(t, digit_format = "%02d"):
	var digits = []

	var minutes = digit_format % [t / 60]
	digits.append(minutes)

	var seconds = digit_format % [int(ceil(t)) % 60]
	digits.append(seconds)

	var formatted = ""
	var colon = " : "

	for digit in digits:
		formatted += digit + colon

	if not formatted.empty():
		formatted = formatted.rstrip(colon)

	return formatted
