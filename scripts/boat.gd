extends KinematicBody

export var move_force: float = 1
export var turn_force: float = 1
export var float_force: float = 5
export var lin_fric: Vector3
export var level_fric: Vector3
export var rad_fric: Vector3
export var gas_lerp: float = .23

export var out_of_water_threshold: float = .2
export var gravity: float = .5

export var ramp_boost: float = .25

export var turn_pitch: float = 1
export var max_pitch: float = 2
export var gas_yaw: float = 1
export var centre_force: Vector2 = Vector2(.2, 2)
export var level_speed: float = 30


var vel: Vector3
var rad_vel: Vector3

onready var particles: CPUParticles = get_node("../particles")
var prev_emission_point: Vector3
var prev_emission_norm: Vector3
# onready var part_offset: float = particles.transform.origin.z


var gas: float = false
var left: bool = false
var right: bool = false
var dash: bool = false

var on_ramp: bool = false
var in_water: bool = false
var in_water_body: bool = false
var in_air: bool = false
var water_timer: float = 0
var water_entry_point: float

onready var cam: Camera = get_node("../Camera")
onready var norm_cam_lerp = cam.follow_lerp
onready var norm_cam_look = cam.look_lerp

var normal: Vector3 = Vector3.UP
onready var spawn: Vector3 = global_transform.origin
var spawn_rot: Vector3 = Vector3.ZERO

var dead_time = 1
var dead_timer = 10
export var explosion: PackedScene

func _ready():
	if is_network_master():
		cam.current = true

	var water = get_node("../../Track/Water")

	water.connect("body_entered", self, "water_entered")
	water.connect("body_exited", self, "water_exited")

# Called every frame. 'delta' is the elapsed time since the previous frame.
master func _process(delta):
	if !is_network_master():
		return

	if dead_timer > dead_time:
		if Input.is_action_pressed("gas"):
			gas = lerp(gas, 1, gas_lerp * delta)
		else:
			gas = lerp(gas, 0, gas_lerp / 10)

		left = Input.is_action_pressed("left")
		right = Input.is_action_pressed("right")
		dash = dash || Input.is_action_just_pressed("dash")

	update_particles(gas)
	water_timer += delta
	dead_timer += delta
	rpc("network_update", transform, gas)

master func _physics_process(_delta):
	if !is_network_master():

		return
	# determine if is in the water

	# if global_transform.origin.y < 0:
	# 	in_water = true
	# 	water_timer = 0
	# elif water_timer > out_of_water_threshold:
	# 	in_water = false

	if in_water_body:
		in_water = true
		water_timer = 0
		get_float_point()
	elif water_timer > out_of_water_threshold:
		in_water = false

	# determine clamped pitch of turn based on velocity
	var pitch = Vector3.BACK * turn_pitch
	pitch *= (vel - Vector3.UP * vel.y).length_squared() / 100
	if pitch.length() > max_pitch:
		pitch = pitch.normalized() * max_pitch
	elif pitch.length() < -max_pitch:
		pitch = - pitch.normalized() * max_pitch

	# turn left of right with pitch, limit turning to speed if in water
	var turn = Vector3.DOWN * turn_force
	if in_water:
		turn = (turn + pitch) * gas;
	else:
		turn += pitch
	if left:
		rad_vel -= turn
	if right:
		rad_vel += turn

	# apply radial friction
	if !on_ramp:
		rad_vel.x *= rad_fric.x
	rad_vel.y *= rad_fric.y
	rad_vel.z *= rad_fric.z
	

	if in_water:
		# apply linear velocity (different if level)
		var level = vel.length() > level_speed
		if level:
			vel.x *= level_fric.x
			vel.z *= level_fric.z
			vel.y *= level_fric.y
		else:
			vel.x *= lin_fric.x
			vel.z *= lin_fric.z
			vel.y *= lin_fric.y
		
		# apply gas force and yaw
		vel += transform.basis.z * move_force * gas
		if !level:
			rad_vel.x -= gas_yaw * gas
	
		# apply floating force
		vel += (water_entry_point - global_transform.origin.y) * float_force * Vector3.UP

		rad_vel.x -= rotation_degrees.x * centre_force.y
		rad_vel.z -= rotation_degrees.z * centre_force.x
	if on_ramp:
		vel += transform.basis.z * move_force * gas + Vector3.UP * gravity
		rad_vel.x -= gas_yaw * gas
	if !in_water && !on_ramp:
		rad_vel.x -= rotation_degrees.x * centre_force.y / 5

	if in_air:
		cam.follow_lerp = norm_cam_lerp / 4
	elif in_water && dead_timer > dead_time:
		cam.follow_lerp = norm_cam_lerp
		cam.look_lerp = norm_cam_look
	
	# rotate and move
	rotation_degrees += rad_vel
	vel += Vector3.DOWN * gravity
	vel = move_and_slide(vel)

	var prev_ramp = on_ramp
	on_ramp = false
	for i in get_slide_count():
		var col = get_slide_collision(i)
		if col.collider.is_in_group("ramp"):
			on_ramp = true
	
	if prev_ramp && ! on_ramp:
		in_air = true
	in_air = in_air && !in_water
	# print("gas: %f, speed: %d" % [gas, vel.length()])
	
	for i in get_slide_count():
		var col: KinematicCollision = get_slide_collision(i)
		if col.collider.is_in_group("land"):
			rpc("explode")
			break
	


func update_particles(gas: float):
	var new_point = transform.origin - transform.basis.z * 1.4
	var e_norm = transform.basis.y * gas - transform.basis.z * (gas + 1)
	var offset = transform.basis.x * .15 
	var norm_offset = Vector3.RIGHT * .25
	var p = []
	var n = []
	var i = 0.0
	var speed_ratio = vel.x * vel.x + vel.z * vel.z / 10000
	speed_ratio += gas / 2
	while i <= 1:
		var point = lerp(prev_emission_point, new_point, i)
		if rand_range(0, 1) > speed_ratio:
			point += Vector3.DOWN * 1000
		p.append(point - offset)
		p.append(point + offset)
		n.append(lerp(prev_emission_norm, e_norm, i) - norm_offset)
		n.append(lerp(prev_emission_norm, e_norm, i) + norm_offset)

		i += 2.0 / 20
	
	particles.emission_points = p
	particles.emission_normals = n
	prev_emission_point = transform.origin - transform.basis.z * 1.4
	prev_emission_norm = transform.basis.y * gas - transform.basis.z * (gas + 1)

# detect water
func water_entered(body: Node):
	# print("water collision")
	if body != self:
		return
	in_water_body = true
	# get_float_point()

func water_exited(body: Node):
	if(vel.y < 0):
		return
	# print("water exit")
	if body != self:
		return
	in_water_body = false

func get_float_point():
	var space_state = get_world().direct_space_state
	var res = space_state.intersect_ray(global_transform.origin + Vector3.UP * 10, global_transform.origin + Vector3.DOWN * 10, [self], 1, false, true)
	
	if !res.empty():
		water_entry_point = res.position.y + .2
		normal = res.normal
		return;

remotesync func explode():
	var inst = explosion.instance()
	inst.global_transform.origin = global_transform.origin
	get_node("../..").add_child(inst)
	global_transform.origin = spawn + randf() * Vector3.RIGHT
	rotation_degrees = spawn_rot
	vel = Vector3.ZERO
	rad_vel = Vector3.ZERO
	gas = 0
	left = false
	right = false
	dash = false
	cam.follow_lerp = 0
	cam.look_lerp = 0
	dead_timer = 0



remote func network_update(remote_transform, network_gas):
	transform = remote_transform
	update_particles(network_gas)
