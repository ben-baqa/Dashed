extends ImmediateGeometry

export var flag_offset: Vector3

onready var boat: KinematicBody = get_node("..")
onready var flag: MeshInstance = get_node("flag")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	draw_line(Vector3.ZERO, flag.transform.origin + flag_offset)
	pass


func draw_line(a: Vector3, b: Vector3):
	clear()
	begin(Mesh.PRIMITIVE_LINES)
	add_vertex(a)
	add_vertex(b)
	end()
