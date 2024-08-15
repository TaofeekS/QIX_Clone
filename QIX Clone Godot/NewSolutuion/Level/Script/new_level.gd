extends Node2D

var atlasInfo = {
	"2,1" : 0,
	"4,1" : 1,
	"6,1" : 2,
	"4,3" : 3
}
@export var timeCount = 100
var liveCount = 3
var lineCoords = []
var bulletScenes = []
var lineList = []
var currentLineIndex = 0
var stopBullet = false
var bulletMoving = false
var whiteTileMaxCount = 0
var drawRect = Rect2()
var QixPos = Vector2(0,0)
var newNodes = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$CanvasLayer/Control/lifeCount.text = str(liveCount)
	whiteTileMaxCount = $TileMap.get_used_cells_by_id(0,0,Vector2i(4,3)).size()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()
	$centerPos.position = getEnemiesCenter()
	timeCount -= delta
	$CanvasLayer/Control/timeLabel.text = str(round(timeCount))
	
	
	if timeCount <= 0:
		get_tree().paused = true
		$CanvasLayer/Control/gameOver.show()
		set_process(false)
	pass


func _physics_process(delta):
	QixPos = $centerPos.position


func getNextTile(pos : Vector2, dir : Vector2):
	var nextPos = pos + (dir *Vector2(16,16))
	nextPos = nextPos.snapped(Vector2(16,16))
	var nextCood = $TileMap.local_to_map(nextPos)
	var tileId = $TileMap.get_cell_source_id(0,nextCood)
	var tileAtlas = $TileMap.get_cell_atlas_coords(0,nextCood)
	return convertAtlasCordinateToIndex(tileAtlas)


func addLinePoints(pos : Vector2,prevDir):
	currentLineIndex = 0
	pos = pos.snapped(Vector2(16,16))
	
	var posCoord = $TileMap.local_to_map(pos)
	var nextTileIndex = getNextTile(pos,prevDir)
	if nextTileIndex == 2:
		
		if lineList.has(pos):
			lineList.erase(pos)
		if lineList.size() == 1:
			$player.wanderPoints = []
			
			$player.fillTimer = $player.fillCooldown
	
			$player.auto = false
			$player.position = lineList[0]
			
			$TileMap.set_cell(0,$TileMap.local_to_map(lineList[0]),0,Vector2i(4,1))
			lineList = []
			lineCoords = []
			return
		$TileMap.set_cell(0,posCoord,0,Vector2i(4,3))
	else:
		lineList.append(pos)
		lineCoords.append(posCoord)
		$TileMap.set_cell(0,posCoord,0,Vector2i(6,1))


func convertAtlasCordinateToIndex(coordi : Vector2i):
	var strCoord = str(coordi.x) + "," + str(coordi.y)
	var keys = atlasInfo.keys()
	if keys.has(strCoord):
		return atlasInfo[strCoord]
	
	return -1


func bucketFillAreaBasedOnPoints(points):
	var cells = $TileMap.get_used_cells_by_id(0,0,Vector2i(6,1))
	for cell in cells:
		$TileMap.set_cell(0,cell,0,Vector2i(4,1))
	stopMovementBullet()
	lineList = []
	lineCoords = []
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	
	for point in points:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x,point.x)
		max_y = max(max_y,point.y)
	
	var startPoints = []
	var possibleWallPoints = []
	
	
	possibleWallPoints.append(points[0] + Vector2(0,16))
	possibleWallPoints.append(points[0] + Vector2(0,-16))
	possibleWallPoints.append(points[0] + Vector2(-16,0))
	possibleWallPoints.append(points[0] + Vector2(16,0))
	
	
	possibleWallPoints.append(points[points.size() -1] + Vector2(0,16))
	possibleWallPoints.append(points[points.size() -1] + Vector2(0,-16))
	possibleWallPoints.append(points[points.size() -1] + Vector2(-16,0))
	possibleWallPoints.append(points[points.size() -1] + Vector2(16,0))

	for point in points:
		point = point.snapped(Vector2(16,16))
		startPoints.append(point + Vector2(-20,20))
		startPoints.append(point + Vector2(20,-20))
		startPoints.append(point + Vector2(-20,-20))
		startPoints.append(point + Vector2(20,20))
	
	for newNode in newNodes:
		newNode.queue_free()
	newNodes = []
	
	for startPoint in startPoints:
		var newNode = $centerPos.duplicate()
		add_child(newNode)
		newNode.position = startPoint
		newNodes.append(newNode)
		#newNode.visible = false
	
	var validDraw = false
	var QixPoint = $TileMap.local_to_map(QixPos)
	for startPoint in startPoints:
		var filledPoint = []
		var Q = []
		var invalidCells = []
		Q.append($TileMap.local_to_map(startPoint))
		
		var runTime = 0
		
		while Q.size() > 0:
			var posCoord = Q[0]
			var QPos = $TileMap.map_to_local(posCoord)
			var tileIndex = getNextTile(QPos,Vector2(0,0))
			if Q.size() == 1 and filledPoint.size() == 0:
				if tileIndex == 0 or tileIndex == 1:
					for node in newNodes:
						if node.position == startPoint:
							node.modulate = Color.BLUE
							break
					revertTileCoordIntoBase(filledPoint)
					filledPoint = []
					break
			if Q[0] == QixPoint:
				for node in newNodes:
					if node.position == startPoint:
						node.modulate = Color.RED
						break
				revertTileCoordIntoBase(filledPoint)               
				filledPoint = []
				break
			
			
			
			$TileMap.set_cell(0,posCoord,0,Vector2i(2,1),1)
			var pos = $TileMap.map_to_local(posCoord)
			Q.erase(posCoord)
			filledPoint.append(posCoord)
			invalidCells.append(Q)
			
			var neigbours = $TileMap.get_surrounding_cells(posCoord)
			for neigbour in neigbours:
				if not invalidCells.has(neigbour):
					var neigbourIndex = getTileIndexBasedOnCoord(neigbour)
					if neigbourIndex == 3 or neigbourIndex == 2:
						Q.append(neigbour)
					invalidCells.append(neigbour)
			if Q.size() == 0 and filledPoint.size() > 1:
				validDraw = true
			runTime += 1
		
		if validDraw:
			turnTileCoordinateToRealBlack(filledPoint)
			for node in newNodes:
				if node.position == startPoint:
					node.modulate = Color.WHITE
					break
			break
	drawRect = Rect2()
	addWallBasedOnArray(possibleWallPoints)
	getMapPercentage()


func getTileIndexBasedOnCoord(posCoord):
	var tileAtlas = $TileMap.get_cell_atlas_coords(0,posCoord)
	return convertAtlasCordinateToIndex(tileAtlas)


func revertTileCoordIntoBase(posCoords = []):
	for posCoord in posCoords:
		$TileMap.set_cell(0,posCoord,0,Vector2i(4,3))

func turnTileCoordinateToRealBlack(posCoords = []):
	for posCoord in posCoords:
		$TileMap.set_cell(0,posCoord,0,Vector2i(2,1))

func getMapPercentage():
	var whiteCount = $TileMap.get_used_cells_by_id(0,0,Vector2i(4,3)).size()
	var percentage = (float(whiteCount)/ float(whiteTileMaxCount)) * 100.0
	$CanvasLayer/Control/percentLabel.text = str(100 -round(percentage)) + "%"
	if (100 -round(percentage)) > 70:
		await get_tree().create_timer(1).timeout
		get_tree().paused = true
		$CanvasLayer/Control/winScreen.show()
	pass

func startMovementBullet():
	
	if bulletMoving:
		return
	$TileMap/bullet.show()
	$TileMap/bullet.monitoring = true
	stopBullet = false
	moveBullet(0)
	bulletMoving  = true


func stopMovementBullet():
	bulletMoving = false
	stopBullet = true
	$TileMap/bullet.hide()
	$TileMap/bullet.set_deferred("monitoring",false)


func moveBullet(index):
	
	if stopBullet:
		return
	
	if index >= lineList.size():
		
		return
	
	var tween = get_tree().create_tween()
	var linePos = lineList[index]
	tween.tween_property($TileMap/bullet,"position",linePos,0.00001)
	await tween.finished
	
	
	
	moveBullet(index +2)

func _on_bullet_body_entered(body):
	
	liveCount -= 1
	$CanvasLayer/Control/lifeCount.text = str(liveCount)
	if liveCount == 0:
		get_tree().paused = true
		$CanvasLayer/Control/gameOver.show()
		set_process(false)
	stopMovementBullet()
	returnPlayerToStartLine()
	

func returnPlayerToStartLine():
	var initialPos = lineList[0]
	var cells = $TileMap.get_used_cells_by_id(0,0,Vector2i(6,1))
	for cell in cells:
		$TileMap.set_cell(0,cell,0,Vector2i(4,3))
	
	$player.wanderPoints = []
	
	$player.fillTimer = $player.fillCooldown
	
	$player.auto = false
	$player.position = initialPos
	lineList = []
	lineCoords = []
	$TileMap.set_cell(0,$TileMap.local_to_map(initialPos),0,Vector2i(4,1))


func _on_restart_btn_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _draw():
	draw_rect(drawRect,Color.YELLOW,true)


func getEnemiesCenter():
	var totalEnemyPos = Vector2(0,0)
	var totalEnemyCount = 0
	
	for enemy in $Enemies.get_children():
		totalEnemyPos += enemy.position
		totalEnemyCount += 1
	
	var centerPos = totalEnemyPos / totalEnemyCount
	return centerPos


func addWallBasedOnArray(wallArray):
	for wallPoint in wallArray:
		var posCoord = $TileMap.local_to_map(wallPoint)
		var tileIndex = getNextTile($TileMap.map_to_local(posCoord) ,Vector2(0,0))
		$edgeTester/wall.position = wallPoint
		await get_tree().create_timer(0.01).timeout
		var wallCollision = $edgeTester/wall.getCollidingRayCasts()
		if wallCollision == 4:
			$TileMap.set_cell(0,posCoord,0,Vector2i(2,1))
