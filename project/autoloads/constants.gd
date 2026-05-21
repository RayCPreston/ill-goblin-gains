extends Node

enum Dir { N, NE, E, SE, S, SW, W, NW }

const TILE_SIZE = 16
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
