extends Control

@onready var resource_list := $MarginContainer/VBoxContainer/ResourceList
@onready var status_label := $MarginContainer/VBoxContainer/StatusLabel
var _labels := {}
var _resource_manager: Node = null

func _ready() -> void:
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")
		for resource_name in _resource_manager.get_resource_names():
			_add_resource_label(resource_name, _resource_manager.get_resource_amount(resource_name))

func update_resource_display(resource_name: String, new_value: float) -> void:
	if not _labels.has(resource_name):
		_add_resource_label(resource_name, new_value)
	_labels[resource_name].text = _format_line(resource_name, new_value)

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
