extends Node2D

const margin = 10

var children: Array = []
var node_type: String
var node_color: Color = Color.WHITE

func _ready():
	randomize()

func add_child_node(child):
	if !children.has(child):
		children.append(child)
		queue_redraw()

func set_node_type(type):
	node_type = type
	update_color()

func update_color():
	match node_type:
		"A": node_color = Color.RED
		"B": node_color = Color.GREEN
		"C": node_color = Color.BLUE
		"D": node_color = Color.YELLOW
		_: node_color = Color.WHITE
	queue_redraw()

func _draw():
	# Draw the outer white circle
	draw_circle(Vector2.ZERO, 8, Color.WHITE)
	# Draw the inner colored circle
	draw_circle(Vector2.ZERO, 7, node_color)
	
	# Draw connection lines
	for child in children:
		var line = child.position - position
		var normal = line.normalized()
		line -= margin * normal
		draw_line(normal * margin, line, Color.GRAY, 2, true)

func get_node_type():
	return node_type
