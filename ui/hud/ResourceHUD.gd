extends Control

const BUILDING_LIBRARY := preload("res://scripts/buildings/BuildingLibrary.gd")

@onready var resource_list := $MarginContainer/VBoxContainer/ResourceList
@onready var building_list := $MarginContainer/VBoxContainer/BuildingList
@onready var status_label := $MarginContainer/VBoxContainer/StatusLabel
var _labels := {}
var _resource_manager: Node = null
var _building_labels := {}
var _building_placeholder: Label = null

func _ready() -> void:
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")
		for resource_name in _resource_manager.get_resource_names():
			_add_resource_label(resource_name, _resource_manager.get_resource_amount(resource_name))
	_update_building_placeholder()

func update_resource_display(resource_name: String, new_value: float) -> void:
	if not _labels.has(resource_name):
		_add_resource_label(resource_name, new_value)
	_labels[resource_name].text = _format_line(resource_name, new_value)

func update_building_counts(counts: Dictionary) -> void:
	_clear_building_placeholder()
	var remaining: Array = _building_labels.keys()
	for building_id in counts.keys():
		var count := int(counts[building_id])
		var label: Label = _building_labels.get(building_id, null)
		if label == null:
			label = Label.new()
			label.name = building_id
			_building_labels[building_id] = label
			building_list.add_child(label)
		label.text = "%s: %d" % [_resolve_building_name(building_id), count]
		if remaining.has(building_id):
			remaining.erase(building_id)

	for orphan_id in remaining:
		var stale: Label = _building_labels.get(orphan_id, null)
		if stale:
			stale.queue_free()
		_building_labels.erase(orphan_id)
	_update_building_placeholder()

func set_status_message(message: String) -> void:
	if status_label:
		status_label.text = "Status: %s" % message

func _add_resource_label(resource_name: String, value: float) -> void:
	var label := Label.new()
	label.name = resource_name
	label.text = _format_line(resource_name, value)
	_labels[resource_name] = label
	resource_list.add_child(label)

func _format_line(resource_name: String, value: float) -> String:
	return "%s: %s" % [resource_name.capitalize(), _format_value(resource_name, value)]

func _format_value(resource_name: String, value: float) -> String:
	match resource_name:
		"colonists":
			return str(int(round(value)))
		"morale":
			return "%d%%" % int(round(value))
		_:
			return "%.2f" % value

func _resolve_building_name(building_id: String) -> String:
	var data: Dictionary = BUILDING_LIBRARY.get_data(building_id)
	return data.get("display_name", building_id.capitalize())

func _update_building_placeholder() -> void:
	if _building_labels.is_empty():
		if not _building_placeholder:
			_building_placeholder = Label.new()
			_building_placeholder.name = "Placeholder"
			_building_placeholder.text = "No structures yet."
			building_list.add_child(_building_placeholder)
	else:
		_clear_building_placeholder()

func _clear_building_placeholder() -> void:
	if _building_placeholder and is_instance_valid(_building_placeholder):
		_building_placeholder.queue_free()
	_building_placeholder = null
