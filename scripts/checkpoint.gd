extends Area

export var index: int

onready var judge = get_node("../Judge")

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("body_entered", self, "body_enter")
	judge.register_checkpoint(self)

func body_enter(body):
	if body.is_in_group("boat"):
		judge.pass_checkpoint(body, index)
		body.spawn = global_transform.origin + Vector3.UP * 10
		body.spawn_rot = rotation_degrees + Vector3.DOWN * 90