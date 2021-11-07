extends Node

export var laps: int = 3
export var menu_entry: PackedScene

var checkpoints = []
var progress = {}

onready var end_menu = get_child(0)

var finish_count = 1
var time = 0

func _ready():
	end_menu.visible = false
func _process(delta):
	time += delta


var i = 0
func register_checkpoint(c):
	checkpoints.append(c)
	c.index = i
	i += 1

func init(body, name):
	progress[body] = [0,0, name]

func pass_checkpoint(body, index):
	if index != progress[body][0] && !progress[body][0] == checkpoints.size():
		return

	progress[body][0] += 1
	if progress[body][0] > checkpoints.size():
		progress[body][0] = 1
		progress[body][1] += 1
	if progress[body][1] == laps:
		print(progress[body][2] + " Finished")
		var inst = menu_entry.instance()
		inst.get_node("Place").text = "%d" %[finish_count]
		finish_count += 1
		inst.get_node("Name").text = progress[body][2]
		inst.get_node("Time").text = format_time(time)
		end_menu.get_child(0).add_child(inst)

		if body.is_network_master():
			end_menu.visible = true
			body.get_node("../VCon").visible = false


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
