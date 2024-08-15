extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var prevDir = Vector2(0,0)
var auto = false
var wanderPoints = []
var fillTimer = 0
@export var fillCooldown = 0.1



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	position = position.snapped(Vector2(16,16))


func _physics_process(delta):
	# Add the gravity.
	if fillTimer > 0:
		fillTimer -= delta
	var direction = Vector2(Input.get_axis("ui_left", "ui_right"),Input.get_axis("ui_up", "ui_down"))
	if direction.x != 0:
		if direction.y != 0:
			return
	if not auto:
		get_parent().lineList = []
		var allowAccess = false
		if Input.is_action_just_pressed("ui_accept"):
			direction = getValidOutDirection()
			allowAccess = true
			print(direction)
			
		
		if direction != Vector2(0,0):
			var nextTile = get_parent().getNextTile(position,direction)
			if(nextTile != -1 and nextTile != 0):
				velocity = direction * SPEED
				velocity = velocity.snapped(Vector2(16,16))
				if nextTile == 3 and allowAccess:
					fillTimer = fillCooldown
					wanderPoints = []
					wanderPoints.append(position.snapped(Vector2(16,16)))
					auto = true
				elif nextTile ==3 and not allowAccess:
					velocity = Vector2(0,0)
			else:
				velocity = Vector2(0,0)
				position = position.snapped(Vector2(16,16))
			prevDir = direction
		else:
			velocity = Vector2(0,0)
			position = position.snapped(Vector2(16,16))
	else:
		
		var currentPos = position.snapped(Vector2(16,16))
		if wanderPoints.has(currentPos)  and fillTimer <= 0:
			wanderPoints.erase(currentPos)
		if direction != Vector2(0,0):
			
			if prevDir != direction:
				var nextTile = get_parent().getNextTile(position,direction)
				if nextTile == 3:
					wanderPoints.append(position.snapped(Vector2(16,16)))
				prevDir = direction
		
		var nextTile = get_parent().getNextTile(position,Vector2(0,0))
		
		
		if nextTile == 1:
			if wanderPoints.size() > 1 or fillTimer <= 0:
				wanderPoints.append(position.snapped(Vector2(16,16)))
				get_parent().bucketFillAreaBasedOnPoints(wanderPoints)
				auto = false
				return
		get_parent().addLinePoints(position,prevDir)
		velocity = prevDir * SPEED
		velocity = velocity.snapped(Vector2(16,16))
	
	move_and_slide()


func getValidOutDirection():
	for ray in $rayCont.get_children():
		if not ray.is_colliding():
			if ray.name == "downRay":
				return Vector2(0,1)
			elif ray.name == "upRay":
				return Vector2(0,-1)
			elif ray.name == "leftRay":
				return Vector2(-1,0)
			else:
				return Vector2(1,0)
	
	return Vector2(0,0)

