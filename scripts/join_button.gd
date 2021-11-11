extends Button

signal join
export var index: int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("button_down", self, "button_press")

func button_press():
	emit_signal("join", index)

