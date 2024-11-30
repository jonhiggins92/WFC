extends Node2D

var tile_rules = {
	"grass": ["grass", "road", 'water'],
	"road": ["road", "grass" ],
	"water": ["water", 'grass']
}
var grid_size = Vector2(50,50)
var grid = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tile_map_2 = $TileMapLayer2

	initialize_grid()
	await wave_function_collapse() 
	await get_tree().create_timer(.5).timeout
	post_process_tiles()
	await get_tree().create_timer(.5).timeout
	tile_map_2.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func initialize_grid():
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(['grass', 'water', 'road'])


func visualize_grid():
	var tile_map = $TileMapLayer
	for x in range(grid_size.x):
		for y in range((grid_size.y)):
			var possibilities: Array = grid[x][y]
			var random_tile = possibilities[randi() % possibilities.size()]
			tile_map.set_cell(Vector2i(x,y),0,get_tile_id(random_tile))
			
func get_tile_id(tile_name):
	if tile_name == 'grass':
		return Vector2i(0,0)
	if tile_name == 'road':
		return Vector2i(1,0)
	if tile_name == 'water':
		return Vector2i(2,0)
	if tile_name == 'highlight':
		return Vector2i(0,0)
	return Vector2i(-1,-1)
			
			
func collapse_cell(position: Vector2i):
	var possibilities = grid[position.x][position.y]
	var chosen_tile = possibilities[randi() % possibilities.size()]
	grid[position.x][position.y] = [chosen_tile]
	
	var tile_map = $TileMapLayer
	tile_map.set_cell(position, 0, get_tile_id(chosen_tile))
	
	var tile_map_2 = $TileMapLayer2
	tile_map_2.set_cell(position, 1, get_tile_id('highlight'))
	await get_tree().create_timer(0.1).timeout
	tile_map_2.set_cell(position, 1, Vector2i(-1,-1))
			
func propagate_constraints(position: Vector2i):
	var neighbors = get_neighbors(position)
	var collapsed_tile = grid[position.x][position.y][0]
	
	for neighbor in neighbors:
		var neighbor_possibilities = grid[neighbor.x][neighbor.y]
		grid[neighbor.x][neighbor.y] = neighbor_possibilities.filter(
	func(tile): return tile in tile_rules[collapsed_tile]
)

		
		if grid[neighbor.x][neighbor.y].size() ==1:
			collapse_cell(neighbor)
			
			
func get_neighbors(position: Vector2i) -> Array:
	var neighbors = []
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]
	
	for dir in directions:
		var neighbor_pos = position + dir
		if is_within_bounds(neighbor_pos):
			neighbors.append(neighbor_pos)
			
	return neighbors
	
func is_within_bounds(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < grid_size.x and position.y >= 0 and position.y < grid_size.y
	
	
func wave_function_collapse():
	while not is_grid_collapsed():
		var position = select_least_entropy_cell()
		collapse_cell(position)
		propagate_constraints(position)
		await get_tree().create_timer(0.001).timeout
		
func is_grid_collapsed() -> bool:
	for row in grid:
		for cell in row:
			if cell.size() > 1:
				return false
	return true
	
func select_least_entropy_cell() -> Vector2i:
	var min_entropy = INF
	var min_position = null
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if grid[x][y].size() > 1 and grid[x][y].size() < min_entropy:
				min_entropy = grid[x][y].size()
				min_position = Vector2i(x,y)
				
	return min_position
	
	
func post_process_tiles():
	var tile_map = $TileMapLayer
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var position = Vector2i(x,y)
			
			if grid[x][y][0] == 'water' and is_surrounded_by(position, 'grass'):
				grid[x][y] = ['grass']
				tile_map.set_cell(position, 0, get_tile_id('grass'))
				var tile_map_2 = $TileMapLayer2
				tile_map_2.set_cell(position, 1, get_tile_id('highlight'))
				
			
			if grid[x][y][0] == 'grass' and is_surrounded_by(position, 'water'):
				grid[x][y] = ['water']
				tile_map.set_cell(position, 0, get_tile_id('water'))
				var tile_map_2 = $TileMapLayer2
				tile_map_2.set_cell(position, 1, get_tile_id('highlight'))
				
			if grid[x][y][0] == 'road' and is_surrounded_by(position, 'grass'):
				grid[x][y] = ['grass']
				tile_map.set_cell(position, 0, get_tile_id('grass'))
				var tile_map_2 = $TileMapLayer2
				tile_map_2.set_cell(position, 1, get_tile_id('highlight'))
				
			
func is_surrounded_by(position: Vector2i, tile_type: String) -> bool:
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]
	
	for dir in directions:
		var neighbor_pos = position + dir
		if !is_within_bounds(neighbor_pos) or grid[neighbor_pos.x][neighbor_pos.y][0] != tile_type:
			return false #not surrounded
	return true
	
	
