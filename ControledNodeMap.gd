extends Node2D

@export var point_radius = 5  # Radius of the circles representing points
@export var max_edge_length = 300  # Maximum length of edges to draw
@export var min_distance_between_points = 100  # Minimum distance between points
@export var max_connections_per_point = 4  # Maximum number of connections per point

var points = []  # List to store all points
var edges = []  # List to store all edges

func _ready():
	pass

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		add_point(event.position)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		reset()

func add_point(position):
	# Check if the new point is too close to existing points
	for point in points:
		if point.distance_to(position) < min_distance_between_points:
			print("Point too close to existing point. Ignoring.")
			return

	points.append(position)
	connect_to_nearest_points(position)
	queue_redraw()

func connect_to_nearest_points(new_point):
	var distances = []
	for point in points:
		if point != new_point:
			var distance = new_point.distance_to(point)
			if distance <= max_edge_length:
				distances.append({"point": point, "distance": distance})
	
	# Sort distances from nearest to farthest
	distances.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	# Connect to the nearest points, up to max_connections_per_point
	var connections = 0
	for distance_info in distances:
		if connections >= max_connections_per_point:
			break
		add_edge(new_point, distance_info["point"])
		connections += 1

func add_edge(p1, p2):
	var edge = [p1, p2]
	edge.sort()
	if not edge in edges:
		edges.append(edge)

func _draw():
	# Draw edges
	for edge in edges:
		draw_line(edge[0], edge[1], Color.RED, 2)
	
	# Draw points
	for point in points:
		draw_circle(point, point_radius, Color.BLUE)

func reset():
	points.clear()
	edges.clear()
	queue_redraw()
	print("Reset complete")

func _on_clear_button_pressed():
	reset()
