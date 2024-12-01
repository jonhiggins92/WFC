extends Node

signal grid_reset
signal cell_collapsed(position: Vector2i)

var grid_size = Vector2(20, 20)
var grid = []
var tile_rules = {
	"grass": ["grass", "road", "water"],
	"road": ["road", "grass"],
	"water": ["water", "grass"],
	"forest": ["grass", "forest"]
}

func initialize_grid():
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(['grass', 'water', 'road'])

func reset_grid():
	initialize_grid()
	emit_signal("grid_reset")

func is_within_bounds(position: Vector2i) -> bool:
	return position.x >= 0 and position.x < grid_size.x and position.y >= 0 and position.y < grid_size.y

func get_neighbors(position: Vector2i) -> Array:
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]
	var neighbors = []
	for dir in directions:
		var neighbor_pos = position + dir
		if is_within_bounds(neighbor_pos):
			neighbors.append(neighbor_pos)
	return neighbors

func update_tile_rules(new_rules: Dictionary):
	for tile in new_rules:
		tile_rules[tile] = new_rules[tile]
	print("Updated tile rules: ", tile_rules)
