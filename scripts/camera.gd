extends Camera

onready var to_follow: Node = get_node("../boat")

export var follow_lerp: float = .1
export var look_lerp: float = .1
export var offset: Vector3

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var t = Transform.IDENTITY.rotated(Vector3.UP, to_follow.transform.basis.get_euler().y)
	transform.origin = lerp(transform.origin,
	to_follow.transform.origin + t.basis * offset, follow_lerp)

	var b = transform.basis.slerp(transform.looking_at(
	to_follow.transform.origin, Vector3.UP).basis, look_lerp)
	transform.basis = Basis(b)
