extends Camera

const MVSPD = 5

## Increase this value to give a slower turn speed
const CAMERA_TURN_SPEED = 200


func _ready():
	### Code for capturing the cursor ###
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta):
	### Code for Releasing the cursor ###
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

	### Camera Movement Code ###
	if Input.is_action_pressed("ui_up"):
		translate(Vector3(0,0,-MVSPD * delta))
	if Input.is_action_pressed("ui_down"):
		translate(Vector3(0,0,MVSPD * delta))
	if Input.is_action_pressed("ui_right"):
		translate(Vector3(MVSPD * delta,0,0))
	if Input.is_action_pressed("ui_left"):
		translate(Vector3(-MVSPD * delta,0,0))


func look_updown_rotation(rotation = 0):
	"""
  Returns a new Vector3 which contains only the x direction
  We'll use this vector to compute the final 3D rotation later
	"""
	var toReturn = self.get_rotation() + Vector3(rotation, 0, 0)

	##
	## We don't want the player to be able to bend over backwards
	## neither to be able to look under their arse.
	## Here we'll clamp the vertical look to 90° up and down
	toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)

	return toReturn

func look_leftright_rotation(rotation = 0):
	"""
  Returns a new Vector3 which contains only the y direction
  We'll use this vector to compute the final 3D rotation later
	"""
	return self.get_rotation() + Vector3(0, rotation, 0)

func _input(event):
	##
	## We'll only process mouse motion events
	if event is InputEventMouseMotion:
		self.set_rotation(look_leftright_rotation(event.relative.x / -CAMERA_TURN_SPEED))

	##
	## Now we can simply set our y-rotation for the camera, and let godot
	## handle the transformation of both together
		self.set_rotation(look_updown_rotation(event.relative.y / -CAMERA_TURN_SPEED))

