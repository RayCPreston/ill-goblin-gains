class_name FloatingTextRequest
extends RefCounted

var text: String = ""
var cell: Vector2i = Vector2i.ZERO
var font_size: int = 8
var color: Color = Color(0.0, 1.0, 0.0, 0.55)  # patrol cone green; alpha lifted from the cone's 0.15 so glyphs stay legible
var spread_radius: float = 6.0
var rise_pixels: float = 10.0
var duration: float = 0.9
var fov_gated: bool = true

static func create(text_value: String, cell_value: Vector2i) -> FloatingTextRequest:
	var request: FloatingTextRequest = FloatingTextRequest.new()
	request.text = text_value
	request.cell = cell_value
	return request
