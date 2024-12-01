extends Node2D

@onready var grid_manager: Node = $GridManager

var tile_rules = {
	"grass": ["grass", "road", 'water'],
	"road": ["road", "grass" ],
	"water": ["water", 'grass'],
	'forest': ['grass', 'forest']
}
var grid_size = Vector2(50,50)
var grid = []
@export var speed = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tile_map_2 = $TileMapLayer2

	initialize_grid()
	await wave_function_collapse() 
	await get_tree().create_timer(.5).timeout
	await post_process_tiles()
	await get_tree().create_timer(.5).timeout
	clear_tilemap2()
	await post_process_tiles()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		reset_grid()
		await wave_function_collapse()
		post_process_tiles()
		clear_tilemap2()

func initialize_grid():
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(['grass', 'water', 'road'])

func clear_tilemap2():
	var tile_map = $TileMapLayer
	var tile_map_2 = $TileMapLayer2

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			tile_map_2.set_cell(Vector2i(x, y), 1, Vector2i(-1, -1))  # Clear highlights


func reset_grid():
	var tile_map = $TileMapLayer
	var tile_map_2 = $TileMapLayer2

	# Clear TileMaps
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(-1, -1))
			tile_map_2.set_cell(Vector2i(x, y), 1, Vector2i(-1, -1))  # Clear highlights

	# Reinitialize the grid
	grid.clear()
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
	if tile_name == 'forest':
		return Vector2i(0,0)
	return Vector2i(-1,-1)
			
			
func collapse_cell(position: Vector2i):
	var possibilities = grid[position.x][position.y]

	# Handle empty possibilities
	if possibilities.size() == 0:
		print("Error: Cell at ", position, " has no possibilities. Defaulting to 'grass'.")
		grid[position.x][position.y] = ["grass"]
		possibilities = ["grass"]
	
	# Select a tile
	var chosen_tile = possibilities[randi() % possibilities.size()]
	grid[position.x][position.y] = [chosen_tile]

	# Update the TileMap
	var tile_map = $TileMapLayer
	tile_map.set_cell(position, 0, get_tile_id(chosen_tile))

	# Highlight the current cell
	var tile_map_2 = $TileMapLayer2
	tile_map_2.set_cell(position, 1, get_tile_id('highlight'))
	await get_tree().create_timer(.01).timeout
	tile_map_2.set_cell(position, 1, Vector2i(-1, -1))

	
func propagate_constraints(position: Vector2i):
	var neighbors = get_neighbors(position)
	var collapsed_tile = grid[position.x][position.y][0]

	for neighbor in neighbors:
		var neighbor_possibilities = grid[neighbor.x][neighbor.y]
		grid[neighbor.x][neighbor.y] = neighbor_possibilities.filter(
			func(tile): return tile in tile_rules[collapsed_tile]
		)

		if grid[neighbor.x][neighbor.y].size() == 0:
			print("Empty possibilities at ", neighbor, " caused by ", position)

		if grid[neighbor.x][neighbor.y].size() == 1:
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
		await get_tree().create_timer(1 / 1000).timeout
		
func is_grid_collapsed() -> bool:
	for row in grid:
		for cell in row:
			if cell.size() > 1:
				return false
	return true
	
func select_least_entropy_cell() -> Vector2i:
	var min_entropy = INF
	var min_position: Vector2i = Vector2i(-1, -1)  # Default to an invalid position
	
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if grid[x][y].size() > 1 and grid[x][y].size() < min_entropy:
				min_entropy = grid[x][y].size()
				min_position = Vector2i(x,y)
	
	 # If no valid position was found, log an error and return a default
	if min_position == Vector2i(-1, -1):
		print("Error: No cell with entropy > 1 found. Returning default position.")
	
	return min_position
	
	
func post_process_tiles() -> void:
	var tile_map = $TileMapLayer
	var tile_map_2 = $TileMapLayer2

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var position = Vector2i(x, y)
			var current_tile = grid[x][y][0]
			var surrounding_tile = get_dominant_surrounding_tile(position)

			# General rule: Convert to the dominant surrounding tile
			if surrounding_tile != "" and surrounding_tile != current_tile:
				grid[x][y] = [surrounding_tile]
				tile_map.set_cell(position, 0, get_tile_id(surrounding_tile))
				tile_map_2.set_cell(position, 1, get_tile_id("highlight"))
				

			# Special rule: Grass surrounded by grass turns into forest
			if grid[x][y][0] == "grass" and surrounding_tile == "grass":
				grid[x][y] = ["forest"]
				tile_map.set_cell(position, 2, get_tile_id("forest"))
				tile_map_2.set_cell(position, 1, get_tile_id("highlight"))
				clear_tilemap2()

				
func get_dominant_surrounding_tile(position: Vector2i) -> String:
	var neighbors = get_neighbors(position)
	var tile_count = {}

	for neighbor in neighbors:
		var neighbor_tile = grid[neighbor.x][neighbor.y][0]
		tile_count[neighbor_tile] = tile_count.get(neighbor_tile, 0) + 1

	# Find the most common tile type
	for tile in tile_count:
		if tile_count[tile] == 4:  # Only return if all 4 surrounding tiles match
			return tile

	return ""  # Return empty if no dominant tile type

			
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
	
	
func update_tile_rules(new_rules: Dictionary):
	for tile in new_rules:
		tile_rules[tile] = new_rules[tile]

	print("Updated tile rules: ", tile_rules)
