extends Spatial

export var turn_speed: float = 10
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(_delta):
	rotation_degrees += Vector3.UP * turn_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
