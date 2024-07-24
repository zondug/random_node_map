extends Node2D

@export var point_radius = 8  # Base radius of the outer circles representing points
@export var max_edge_length = 300  # Maximum length of edges to draw
@export var min_distance_between_points = 150  # Minimum distance between points
@export var total_points = 10  # Total number of points to create before connecting

const margin = 10  # Margin for drawing connection lines

# Node type probabilities
@export var node_probabilities: Dictionary = {
	"A": 0.25,
	"B": 0.25,
	"C": 0.25,
	"D": 0.25
}:
	set(value):
		node_probabilities = value
		normalize_probabilities()

var points = []  # List to store all points
var edges = []  # List to store all edges
var node_types = {}  # Dictionary to store node types
var node_counts = {}
var astar = AStar2D.new()
var path_to_draw = []

var current_points = 0  # Counter for current number of points
var is_connecting = false  # Flag to indicate if we're in the connecting phase

@onready var label = $Label

# Noise map variables
var noise = FastNoiseLite.new()
var noise_image: Image
var noise_texture: ImageTexture

func _ready():
	normalize_probabilities()
	reset_node_counts()
	generate_noise_map()

func generate_noise_map():
	noise.seed = randi()
	noise.frequency = 0.0015
	
	noise_image = Image.create(get_viewport().size.x, get_viewport().size.y, false, Image.FORMAT_RF)
	for x in range(noise_image.get_width()):
		for y in range(noise_image.get_height()):
			var noise_value = noise.get_noise_2d(x, y)
			noise_image.set_pixel(x, y, Color(noise_value, noise_value, noise_value, 1))
	
	noise_texture = ImageTexture.create_from_image(noise_image)

func get_noise_height(position: Vector2) -> float:
	var pixel_color = noise_image.get_pixelv(position)
	return pixel_color.r  # Use red channel as height value (0..1)

func normalize_probabilities():
	var total = 0.0
	for prob in node_probabilities.values():
		total += prob
	
	if total > 0:
		for type in node_probabilities:
			node_probabilities[type] /= total
	else:
		# If all probabilities are 0, set them to equal values
		var count = node_probabilities.size()
		for type in node_probabilities:
			node_probabilities[type] = 1.0 / count
	
	update_probabilities()

func update_probabilities():
	if label:
		label.update_probabilities(node_probabilities)

func reset_node_counts():
	node_counts.clear()
	for type in node_probabilities:
		node_counts[type] = 0

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_connecting:
			add_point(event.position)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		reset()

func add_point(position):
	for point in points:
		if point.distance_to(position) < min_distance_between_points:
			print("Point too close to existing point. Ignoring.")
			return

	points.append(position)
	var node_type = get_random_node_type()
	node_types[position] = node_type
	node_counts[node_type] += 1
	current_points += 1
	
	if current_points >= total_points:
		connect_points_delaunay()
	
	queue_redraw()
	
	if label:
		label.update_counts(node_counts)

func get_random_node_type():
	var rand = randf()
	var cumulative_prob = 0.0
	for type in node_probabilities:
		cumulative_prob += node_probabilities[type]
		if rand < cumulative_prob:
			return type
	return node_probabilities.keys()[0]  # Fallback to first type

func connect_points_delaunay():
	is_connecting = true
	edges.clear()
	astar.clear()
	
	var delaunay = Geometry2D.triangulate_delaunay(points)
	for i in range(0, delaunay.size(), 3):
		var p1 = delaunay[i]
		var p2 = delaunay[i+1]
		var p3 = delaunay[i+2]
		
		add_edge_if_valid(p1, p2)
		add_edge_if_valid(p2, p3)
		add_edge_if_valid(p3, p1)
	
	is_connecting = false

func add_edge_if_valid(index1, index2):
	var start = points[index1]
	var end = points[index2]
	if start.distance_to(end) <= max_edge_length:
		var edge = [index1, index2]
		edge.sort()
		if not edge in edges:
			edges.append(edge)
			var start_height = get_noise_height(start)
			var end_height = get_noise_height(end)
			var height_diff = abs(start_height - end_height)
			var distance = start.distance_to(end)
			var cost = distance * (1 + height_diff * 10)  # 높이 차이에 가중치를 줍니다
			if not astar.has_point(index1):
				astar.add_point(index1, start)
			if not astar.has_point(index2):
				astar.add_point(index2, end)
			astar.connect_points(index1, index2, true)
			print("Edge added between ", index1, " and ", index2, " with cost ", cost)



func _draw():
	# Draw noise map
	draw_texture(noise_texture, Vector2.ZERO)
	
	# Draw edges
	for edge in edges:
		draw_edge(edge[0], edge[1])
	
	# Draw points
	for point in points:
		var node_type = node_types[point]
		var color = get_color_for_node_type(node_type)
		var height = get_noise_height(point)
		var radius = point_radius * (1 + height)  # Increase radius based on height
		draw_circle(point, radius, Color.WHITE)
		draw_circle(point, radius - 1, color)
	
	# Draw path
	if path_to_draw.size() > 1:
		for i in range(path_to_draw.size() - 1):
			draw_edge(path_to_draw[i], path_to_draw[i + 1], Color.RED, 4)

func draw_edge(index1: int, index2: int, color: Color = Color.GRAY, width: float = 2.0):
	var start = points[index1]
	var end = points[index2]
	var path = astar.get_point_path(index1, index2)
	
	for i in range(1, path.size()):
		var from = path[i-1]
		var to = path[i]
		var from_height = get_noise_height(from)
		var to_height = get_noise_height(to)
		
		# 높이에 따른 오프셋 계산
		var from_offset = Vector2(0, -from_height * 50)
		var to_offset = Vector2(0, -to_height * 50)
		
		draw_line(from + from_offset, to + to_offset, color, width, true)
	
	# 거리 레이블 그리기
	var mid_point = start.lerp(end, 0.5)
	var mid_height = get_noise_height(mid_point)
	var label_offset = Vector2(0, -mid_height * 50)
	var distance = start.distance_to(end)
	draw_string(ThemeDB.fallback_font, mid_point + label_offset, "%d" % distance, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)


func get_color_for_node_type(node_type):
	match node_type:
		"A": return Color.RED
		"B": return Color.GREEN
		"C": return Color.BLUE
		"D": return Color.YELLOW
		_: return Color.WHITE


func reset():
	points.clear()
	edges.clear()
	node_types.clear()
	reset_node_counts()
	astar.clear()
	path_to_draw.clear()
	current_points = 0
	is_connecting = false
	generate_noise_map()  # Regenerate noise map on reset
	queue_redraw()
	print("Reset complete")
	
	if label:
		label.update_counts(node_counts)

func _on_clear_button_pressed():
	reset()

func find_path(start_index, end_index):
	path_to_draw = astar.get_point_path(start_index, end_index)
	queue_redraw()

func get_node_at_position(position):
	for i in range(points.size()):
		var point = points[i]
		var height = get_noise_height(point)
		var radius = point_radius * (1 + height)
		if point.distance_to(position) <= radius:
			return i
	return -1

func _on_find_path_button_pressed():
	if is_connecting:
		return
	var start_index = get_node_at_position(get_global_mouse_position())
	if start_index != -1:
		for i in range(points.size()):
			if i != start_index:
				find_path(start_index, i)
				break
