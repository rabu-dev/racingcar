extends Node3D

func _ready():
	var parent = get_parent()
	if not parent:
		return
	for child in parent.get_children():
		if child == self:
			continue
		if child.has_signal("on_road_updated"):
			child.create_geo = false
