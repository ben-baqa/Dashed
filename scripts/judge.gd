extends Node

export var laps: int = 3

var checkpoints = []
var progress = {}

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
	if progress[body][1] >= laps:
		print(progress[body][2] + " Wins!")
