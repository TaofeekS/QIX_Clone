extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	linear_velocity = Vector2(randi()% 1000 -500,randi()% 1000 -500)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _physics_process(delta):
	var tileIndex = get_parent().get_parent().getNextTile(position,Vector2(0,0))
	
	if tileIndex == 2:
		get_parent().get_parent()._on_bullet_body_entered(self)


func _on_area_2d_body_entered(body):
	if body.name == "player":
		get_parent().get_parent()._on_bullet_body_entered(self)
	if body.name == "TileMap":
		queue_free()
