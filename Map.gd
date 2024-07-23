extends Node2D

@export var plane_len = 45 # size of map
@export var path_count = 5 # number of paths
@export var map_scale = 25
@export var point_distance = 4 # distance between each points

# Node type probabilities
@export_range(0, 1) var type_a_prob: float = 0.25:
	set(value):
		type_a_prob = value
		update_probabilities()
@export_range(0, 1) var type_b_prob: float = 0.25:
	set(value):
		type_b_prob = value
		update_probabilities()
@export_range(0, 1) var type_c_prob: float = 0.25:
	set(value):
		type_c_prob = value
		update_probabilities()
@export_range(0, 1) var type_d_prob: float = 0.25:
	set(value):
		type_d_prob = value
		update_probabilities()

var node_count = plane_len * plane_len / 12 # number of nodes
var map_data = [] # astar

var nodes = {} # nodes
var node_counts = {"A": 0, "B": 0, "C": 0, "D": 0}

var node_scene = preload("res://Node.tscn")
var path_to_draw = []
var astar = AStar2D.new()

@onready var label = $Label

func _ready():
	normalize_probabilities()
	generate()

func normalize_probabilities():
	var total = type_a_prob + type_b_prob + type_c_prob + type_d_prob
	if total != 0:
		type_a_prob /= total
		type_b_prob /= total
		type_c_prob /= total
		type_d_prob /= total
	else:
		# If all probabilities are 0, set them to equal values
		type_a_prob = 0.25
		type_b_prob = 0.25
		type_c_prob = 0.25
		type_d_prob = 0.25
	update_probabilities()

func update_probabilities():
	if label:
		label.update_probabilities({
			"A": type_a_prob,
			"B": type_b_prob,
			"C": type_c_prob,
			"D": type_d_prob
		})

func generate():
	var generator = preload("res://MapGenerator.gd").new()
	self.map_data = generator.generate(plane_len, node_count, path_count, point_distance)
	
	node_counts = {"A": 0, "B": 0, "C": 0, "D": 0}
	
	for k in map_data.nodes.keys():
		var point = map_data.nodes[k]
		var node = node_scene.instantiate()
		node.position = point * map_scale + Vector2(200, 0)
		var node_type = get_random_node_type()
		node.set_node_type(node_type)
		node_counts[node_type] += 1
		add_child(node)
		nodes[k] = node
		astar.add_point(k, point)

	for path in map_data.paths:
		for i in range(path.size() - 1):
			var index1 = path[i]
			var index2 = path[i + 1]
			nodes[index1].add_child_node(nodes[index2])
			astar.connect_points(index1, index2)
	
	if label:
		label.update_counts(node_counts)

func get_random_node_type():
	var rand = randf()
	if rand < type_a_prob:
		return "A"
	elif rand < type_a_prob + type_b_prob:
		return "B"
	elif rand < type_a_prob + type_b_prob + type_c_prob:
		return "C"
	else:
		return "D"

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_node = get_node_at_position(event.position)
		
		if clicked_node:
			path_to_draw = find_path(nodes[0], clicked_node)
			var clicked_node_id = nodes.find_key(clicked_node)
			var connected_node_ids = astar.get_point_connections(clicked_node_id)
			print("Clicked node type: ", clicked_node.get_node_type())
			queue_redraw()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		reset_nodes()

func get_node_at_position(position):
	for node in nodes.values():
		var node_rect = Rect2(node.get_global_position() - Vector2(10, 10), Vector2(20, 20))
		if node_rect.has_point(position):
			return node
	return null

func find_path(start_node, end_node):
	var start_key = nodes.find_key(start_node)
	var end_key = nodes.find_key(end_node)
	if start_key != null and end_key != null:
		return astar.get_point_path(start_key, end_key)
	else:
		return []

func _draw():
	if path_to_draw.size() > 0:
		var clicked_node_id = nodes.find_key(get_node_at_position(get_global_mouse_position()))
		if clicked_node_id != null:
			draw_connections(clicked_node_id)
	draw_route()

func draw_route():    
	if path_to_draw.size() > 1:
		for i in range(path_to_draw.size() - 1):
			draw_line(path_to_draw[i] * map_scale + Vector2(200, 0), path_to_draw[i + 1] * map_scale + Vector2(200, 0), Color.RED, 8)

func draw_connections(clicked_node_id):
	var connected_node_ids = astar.get_point_connections(clicked_node_id)
	for connected_node_id in connected_node_ids:
		var start_pos = nodes[clicked_node_id].position
		var end_pos = nodes[connected_node_id].position
		draw_line(start_pos, end_pos, Color.YELLOW, 12)

func _on_button_pressed():
	reset_nodes()

func reset_nodes():
	for node in nodes.values():
		node.queue_free() # free node instances
	nodes.clear()
	astar.clear()
	path_to_draw.clear()
	normalize_probabilities()
	generate()
	queue_redraw()
