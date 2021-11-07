extends Area


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_overlapping_bodies().size() > 0:
		print(get_overlapping_bodies())
	if get_overlapping_areas().size() > 0:
		print(get_overlapping_areas())
	if overlaps_body(get_node("../../1/boat")):
		print("YEET")
