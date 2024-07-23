extends Label

var node_counts = {"A": 0, "B": 0, "C": 0, "D": 0}
var node_probabilities = {"A": 0.25, "B": 0.25, "C": 0.25, "D": 0.25}

func _ready():
	update_label()

func update_counts(new_counts):
	node_counts = new_counts
	update_label()

func update_probabilities(new_probabilities):
	node_probabilities = new_probabilities
	update_label()

func update_label():
	var total_nodes = sum_counts()
	var text = ""
	for type in ["A", "B", "C", "D"]:
		var count = node_counts[type]
		var probability = node_probabilities[type]
		var percentage = 0.0 if total_nodes == 0 else (count / float(total_nodes)) * 100
		text += "%s = %d (%.1f%%) [%.1f%%]\n" % [type, count, percentage, probability * 100]
	self.text = text

func sum_counts():
	return node_counts.values().reduce(func(accum, number): return accum + number, 0)
