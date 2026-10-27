extends Node

enum Dir { N, NE, E, SE, S, SW, W, NW }

const TILE_SIZE = 16

const STARTING_POSITIVE_TRAIT_COUNT = 3
const STARTING_NEGATIVE_TRAIT_COUNT = 2
const STARTING_ITEM_COUNT = 3

const dir: Dictionary = {
	Dir.N: Vector2i(0, -1),
	Dir.NE: Vector2i(1, -1),
	Dir.E: Vector2i(1, 0),
	Dir.SE: Vector2i(1, 1),
	Dir.S: Vector2i(0, 1),
	Dir.SW: Vector2i(-1, 1),
	Dir.W: Vector2i(-1, 0),
	Dir.NW: Vector2i(-1, -1)
}

static func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(world_pos / TILE_SIZE)

static func cell_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos * TILE_SIZE)

static func cell_center_to_world(grid_pos: Vector2i) -> Vector2:
	return cell_to_world(grid_pos) + Vector2(TILE_SIZE, TILE_SIZE) / 2.0
