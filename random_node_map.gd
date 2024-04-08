extends Node2D

@export var plane_len = 45 # size of map
@export var node_count = 50 # number of nodes
@export var path_count = 5 # number of paths
@export var map_scale = 25
@export var point_distance = 4 # distance between each points
@export var node_radius = 10 # radius of each node

var paths = []
var nodes = {}

var path_to_draw = []
var astar = AStar2D.new()

func _ready():
	generate()

func generate():
	seed(Time.get_unix_time_from_system())
	
	var points = []
	points.append(Vector2(0, plane_len / 2)) # start point
	points.append(Vector2(plane_len, plane_len / 2)) # end point
	var center = Vector2(plane_len / 2, plane_len / 2)

	for i in range(node_count):
		var max_attempts = 10 # limit number of tries
		var attempts = 0
		while attempts < max_attempts:
			var point = Vector2(randi() % plane_len, randi() % plane_len)
			var dist_from_center = (point - center).length_squared()
			var in_circle = dist_from_center <= plane_len * plane_len / 4
			var distance_ok = true
			for other_point in points:
				if (point - other_point).length() < point_distance:
					distance_ok = false
					break
			if distance_ok and in_circle and not points.has(point):
				points.append(point)
				break
			attempts += 1
	
	var pool = PackedVector2Array(points)
	var triangles = Geometry2D.triangulate_delaunay(pool)
	
	for i in range(points.size()):
		astar.add_point(i, points[i])
		nodes[i] = points[i] * map_scale + Vector2(200, 0)
	
	for i in range(triangles.size() / 3):
		var p1 = triangles[i * 3]
		var p2 = triangles[i * 3 + 1]
		var p3 = triangles[i * 3 + 2]
		if not astar.are_points_connected(p1, p2):
			astar.connect_points(p1, p2)
		if not astar.are_points_connected(p2, p3):
			astar.connect_points(p2, p3)
		if not astar.are_points_connected(p1, p3):
			astar.connect_points(p1, p3)
	
	for i in range(path_count):
		var id_path = astar.get_id_path(0, 1)
		if id_path.size() == 0:
			break
		paths.append(id_path)
		
		for j in range(randi() % 2 + 1):
			var index = randi() % (id_path.size() - 2) + 1
			var id = id_path[index]
			astar.set_point_disabled(id, true)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_node_id = get_node_at_position(event.position)
		
		if clicked_node_id != null:
			path_to_draw = find_path(0, clicked_node_id)
			queue_redraw()

func get_node_at_position(position):
	for node_id in nodes:
		var node_pos = nodes[node_id]
		if position.distance_to(node_pos) <= node_radius:
			return node_id
	return null

func find_path(start_node_id, end_node_id):
	if start_node_id != null and end_node_id != null:
		return astar.get_point_path(start_node_id, end_node_id)
	else:
		return []

func _draw():
	draw_nodes()
	draw_connections()
	draw_path()

func draw_nodes():
	for node_pos in nodes.values():
		draw_circle(node_pos, node_radius, Color.WHITE)

func draw_connections():
	for node_id in nodes:
		var node_pos = nodes[node_id]
		var connected_node_ids = astar.get_point_connections(node_id)
		for connected_node_id in connected_node_ids:
			var connected_node_pos = nodes[connected_node_id]
			draw_line(node_pos, connected_node_pos, Color.YELLOW, 2)

func draw_path():
	if path_to_draw.size() > 1:
		for i in range(path_to_draw.size() - 1):
			var start_pos = nodes[path_to_draw[i]]
			var end_pos = nodes[path_to_draw[i + 1]]
			draw_line(start_pos, end_pos, Color.RED, 4)

func _on_button_pressed():
	nodes.clear()
	astar.clear()
	path_to_draw.clear()
	generate()
	queue_redraw()
