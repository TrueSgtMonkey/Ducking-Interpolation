extends KinematicBody

#height state
enum { STANDING, DUCKING, JUMPING, DUCK_JUMPING }
var heightState : int = STANDING

#move state
enum { IDLE, SLOW, NORMAL, FAST }
var moveState : int = IDLE

export (float) var speed = 6.0
export (float) var sprintMultiplier = 2.0
export (float) var jumpSpeed := 24.0
export (float) var mouseSensitivity = 0.25
export (float) var duckSpeed := 1.0
export (float) var collisionDuckHeight = 0.7

var velocity := Vector3()
var dir := Vector3()
var gravity := 30.0
var delta := 0.0

var originalPivotLocation : Vector3
var originalColHeight : float

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	originalPivotLocation = $Pivot.transform.origin
	originalColHeight = $CollisionShape.shape.height
	
func _physics_process(delta):
	self.delta = delta
	dir = getInput()
	
	match moveState:
		IDLE:
			easeOut(0.85)
		SLOW:
			dir = dir.normalized()
			velocity.x = dir.x * speed * 0.5
			velocity.z = dir.z * speed * 0.5
		NORMAL:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
		FAST:
			dir = dir.normalized()
			velocity.x = dir.x * speed * sprintMultiplier
			velocity.z = dir.z * speed * sprintMultiplier

	if is_on_ceiling():
		velocity.y *= -0.25
	
	if is_on_floor():
		match heightState:
			JUMPING:
				velocity.y = jumpSpeed
			DUCK_JUMPING:
				velocity.y = jumpSpeed
			STANDING:
				velocity.y = 0
			DUCKING:
				velocity.y = 0
	else:
		velocity.y -= gravity * delta
	
	var vel := move_and_slide(velocity, Vector3.UP, true).normalized()
	$DuckCast2.transform.origin.x = -vel.x * $CollisionShape.shape.radius
	$DuckCast2.transform.origin.z = -vel.z * $CollisionShape.shape.radius
	$DuckCast.transform.origin.x = vel.x * $CollisionShape.shape.radius
	$DuckCast.transform.origin.z = vel.z * $CollisionShape.shape.radius
		
func _input(event):
	if event.is_action_released("jump"):
		if velocity.y > 0.0:
			velocity.y *= 0.25
		
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		$Pivot.rotate_y(-event.relative.x * mouseSensitivity * delta)
		$Pivot/Camera.rotate_x(-event.relative.y * mouseSensitivity * delta)
		
func getInput():
	var dir := Vector3()
	var moveInputs := 0
	if Input.is_key_pressed(KEY_A):
		dir += -$Pivot/Camera.global_transform.basis.x
		moveInputs += 1
	if Input.is_key_pressed(KEY_D):
		dir += $Pivot/Camera.global_transform.basis.x
		moveInputs += 1
	if Input.is_key_pressed(KEY_W):
		dir += -$Pivot/Camera.global_transform.basis.z
		moveInputs += 1
	if Input.is_key_pressed(KEY_S):
		dir += $Pivot/Camera.global_transform.basis.z
		moveInputs += 1
	
	if moveInputs > 0:
		$DuckCast2.enabled = true
		if Input.is_key_pressed(KEY_SHIFT):
			if heightState != DUCKING:
				moveState = FAST
		else:
			moveState = NORMAL
	else:
		$DuckCast2.enabled = false
		moveState = IDLE
		
	if Input.is_action_pressed("jump"):
		heightState = JUMPING
	else:
		heightState = STANDING
		
	if Input.is_key_pressed(KEY_CONTROL):
		duck()
		match heightState:
			STANDING:
				heightState = DUCKING
				moveState = SLOW
			JUMPING:
				heightState = DUCK_JUMPING
	else:
		if !$DuckCast.is_colliding() && !$DuckCast2.is_colliding():
			stand()
			match heightState:
				DUCKING:
					heightState = STANDING
		else:
			heightState = DUCKING
			moveState = SLOW
		
	return dir

func easeOut(mult : float, minimum : float = 0.05):
	if mult >= 1.0 && mult < 0.0:
		return
	if abs(velocity.x) > minimum || abs(velocity.z) > minimum:
		velocity.x *= mult
		velocity.z *= mult
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		
func duck():
	if $Pivot.transform.origin.y > $DuckSpot.transform.origin.y:
		$Pivot.transform.origin.y -= duckSpeed * delta
	else:
		$Pivot.transform.origin = $DuckSpot.transform.origin
	if $CollisionShape.shape.height > collisionDuckHeight:
		$CollisionShape.shape.height -= duckSpeed * delta
	else:
		$CollisionShape.shape.height = collisionDuckHeight
		
func stand():
	if $Pivot.transform.origin.y < originalPivotLocation.y:
		$Pivot.transform.origin.y += duckSpeed * delta
	else:
		$Pivot.transform.origin = originalPivotLocation
	if $CollisionShape.shape.height < originalColHeight:
		$CollisionShape.shape.height += duckSpeed * delta
	else:
		$CollisionShape.shape.height = originalColHeight
