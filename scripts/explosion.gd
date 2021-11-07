extends CPUParticles

onready var smoke = get_child(0)
var smoked = false
var timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	emitting = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	timer += delta
	if timer > .1 && ! smoked:
		smoke.emitting = true
		smoked = true
	if !emitting && !smoke.emitting:
		queue_free()
