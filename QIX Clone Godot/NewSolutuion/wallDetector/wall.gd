extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func getCollidingRayCasts():
	var rayCount = 0
	for ray in $rayCont.get_children():
		if ray.is_colliding():
			rayCount += 1
	
	return rayCount
