extends ImmediateGeometry

export var flag_offset: Vector3
export var lin_s: Vector3 = Vector3.ONE * 10
export var rad_s: Vector3 = Vector3.ONE * 10
export var centre_force: float = .2
export var damp: float = 0.99

onready var boat: KinematicBody = get_node("..")
onready var base: Spatial = get_node("base")
onready var flag: Transform = get_node("base/flag").transform
onready var flag_base: Node = get_node("base/flag/base")

onready var pos_offset: Vector3 = flag.origin

var vel: Vector3
var rad_vel: Vector3

var pos: Vector3
var rot: Vector3
var pos_v: Vector3
var rot_v: Vector3

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	draw_line(Vector3.ZERO, flag.origin)
	pass

func _physics_process(_delta):
	var acc = boat.vel - vel
	vel = boat.vel
	var rad_acc = boat.rad_vel - rad_vel
	rad_vel = boat.rad_vel

	# push rot
	rot_v.x -= rad_acc.x * rad_s.x
	rot_v.x -= acc.z * lin_s.z

	rot_v.y -= rad_acc.x * rad_s.x
	rot_v.y -= rad_acc.y * rad_s.y

	rot_v.z -= rad_acc.x * rad_s.x
	rot_v.z -= rad_acc.y * rad_s.y
	rot_v.z -= rad_acc.z * rad_s.z

	# push pos
	pos_v.z -= acc.z * lin_s.z
	pos_v.z -= rad_acc.x * rad_s.x
	pos_v.x -= acc.x * lin_s.x
	pos_v.x -= rad_acc.z * rad_s.z

	# centre to 0
	rot_v -= rot * centre_force
	pos_v -= pos * centre_force
	# damp movement
	rot_v *= damp
	pos_v *= damp
	# apply rotational and linear velocity
	rot += rot_v
	pos += pos_v

	base.rotation_degrees = rot
	flag.origin = pos + pos_offset


func draw_line(a: Vector3, b: Vector3):
	clear()
	begin(Mesh.PRIMITIVE_LINES)
	add_vertex(a)
	add_vertex(b)
	end()
