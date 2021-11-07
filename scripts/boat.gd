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
var in_air: bool = false
var water_timer: float = 0

onready var cam: Camera = get_node("../Camera")
onready var norm_cam_lerp = cam.follow_lerp


func _ready():
	if is_network_master():
		cam.current = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
master func _process(delta):
	if !is_network_master():
		return

	if Input.is_action_pressed("gas"):
		gas = lerp(gas, 1, gas_lerp * delta)
	else:
		gas = lerp(gas, 0, gas_lerp / 10)

	left = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	dash = dash || Input.is_action_just_pressed("dash")

	update_particles(gas)
	water_timer += delta

master func _physics_process(_delta):
	if !is_network_master():
		return
	# particles.amount = int(lerp(min_particles, max_particles, gas))
	# determine if is in the water
	if global_transform.origin.y < 0:
		in_water = true
		water_timer = 0
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
		vel += -transform.origin.y * float_force * Vector3.UP

		rad_vel.x -= rotation_degrees.x * centre_force.y
		rad_vel.z -= rotation_degrees.z * centre_force.x
	if on_ramp:
		vel += transform.basis.z * move_force * gas + Vector3.UP * gravity
		rad_vel.x -= gas_yaw * gas
	if !in_water && !on_ramp:
		rad_vel.x -= rotation_degrees.x * centre_force.y / 5

	if in_air:
		cam.follow_lerp = norm_cam_lerp / 4
	else:
		cam.follow_lerp = norm_cam_lerp
	
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
	rpc("network_update", [transform, gas])
	

func update_particles(gas: float):
	var new_point = transform.origin - transform.basis.z * 1.4
	var e_norm = transform.basis.y * gas - transform.basis.z * (gas + 1)
	var offset = transform.basis.x * .15 
	var norm_offset = Vector3.RIGHT * .25
	var p = []
	var n = []
	var i = 0.0
	var speed_ratio = vel.x * vel.x + vel.z * vel.z / 1500
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


remote func network_update(remote_transform, network_gas):
	transform = remote_transform
	update_particles(network_gas)
