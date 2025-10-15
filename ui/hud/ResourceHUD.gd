extends Control

const BUILDING_LIBRARY := preload("res://scripts/buildings/BuildingLibrary.gd")

@onready var resource_grid := $MarginContainer/VBoxContainer/ResourceGrid
@onready var building_grid := $MarginContainer/VBoxContainer/BuildingGrid
@onready var power_summary := $MarginContainer/VBoxContainer/PowerBox/PowerSummary
@onready var battery_summary := $MarginContainer/VBoxContainer/PowerBox/BatterySummary
@onready var status_label := $MarginContainer/VBoxContainer/StatusLabel
@onready var log_panel := $MarginContainer/VBoxContainer/LogPanel
@onready var controls_value := $MarginContainer/VBoxContainer/ControlsValue

var _resource_manager: Node = null
var _resource_labels := {}
var _building_labels := {}
var _building_placeholder: Label = null
var _log_buffer: Array[String] = []
const MAX_LOG_ENTRIES := 30

func _ready() -> void:
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")
		for resource_name in _resource_manager.get_resource_names():
			_add_resource_label(resource_name, _resource_manager.get_resource_amount(resource_name))
	_update_building_placeholder()
	_update_controls_reference()

func update_resource_display(resource_name: String, new_value: float) -> void:
	if not _resource_labels.has(resource_name):
		_add_resource_label(resource_name, new_value)
	_resource_labels[resource_name].text = _format_line(resource_name, new_value)

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
			building_grid.add_child(label)
		label.text = "%s: %d" % [_resolve_building_name(building_id), count]
		if remaining.has(building_id):
			remaining.erase(building_id)

	for orphan_id in remaining:
		var stale: Label = _building_labels.get(orphan_id, null)
		if stale:
			stale.queue_free()
		_building_labels.erase(orphan_id)
	_update_building_placeholder()

func update_power_status(power_data: Dictionary) -> void:
	var generation := float(power_data.get("generation", 0.0))
	var consumption := float(power_data.get("consumption", 0.0))
	var net := float(power_data.get("net", 0.0))
	var shortages := int(power_data.get("shortages", 0))
	var battery_charge := float(power_data.get("battery_charge", 0.0))
	var battery_capacity := float(power_data.get("battery_capacity", 0.0))
	power_summary.text = "Net: %s (Gen %.2f / Use %.2f) | Shortages: %d" % [_format_signed(net), generation, consumption, shortages]
	battery_summary.text = "Battery: %.2f / %.2f" % [battery_charge, battery_capacity]

func set_status_message(message: String) -> void:
	status_label.text = message
	append_log(message)

func append_log(message: String) -> void:
	_log_buffer.append("[%s] %s" % [_timestamp(), message])
	if _log_buffer.size() > MAX_LOG_ENTRIES:
		while _log_buffer.size() > MAX_LOG_ENTRIES:
			_log_buffer.remove_at(0)
	log_panel.clear()
	for entry in _log_buffer:
		log_panel.append_text(entry + "\n")
	log_panel.scroll_to_line(log_panel.get_line_count())

func _add_resource_label(resource_name: String, value: float) -> void:
	var label := Label.new()
	label.name = resource_name
	label.text = _format_line(resource_name, value)
	_resource_labels[resource_name] = label
	resource_grid.add_child(label)

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
			building_grid.add_child(_building_placeholder)
	else:
		_clear_building_placeholder()

func _clear_building_placeholder() -> void:
	if _building_placeholder and is_instance_valid(_building_placeholder):
		_building_placeholder.queue_free()
	_building_placeholder = null

func _update_controls_reference() -> void:
	var controls_text := ""
	controls_text += "[b]B[/b] - Toggle build menu\n"
	controls_text += "[b]P[/b] - Pause/Resume simulation\n"
	controls_text += "[b]][/b] - Increase tick speed\n"
	controls_text += "[b][[/b] - Decrease tick speed\n"
	controls_text += "Click build buttons to construct instantly"
	controls_value.text = controls_text

func _format_signed(value: float) -> String:
	if value > 0.0:
		return "+%.2f" % value
	if value < 0.0:
		return "%.2f" % value
	return "0.00"

func _timestamp() -> String:
	return Time.get_time_string_from_system()
