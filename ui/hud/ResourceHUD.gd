extends Control

signal build_requested(building_id: String)

const BUILDING_LIBRARY := preload("res://scripts/buildings/BuildingLibrary.gd")

@onready var resource_grid: GridContainer = $ScrollContainer/MarginContainer/VBoxContainer/ResourcesPanel/Content/ResourceGrid
@onready var power_bar: ProgressBar = $ScrollContainer/MarginContainer/VBoxContainer/PowerPanel/PowerContent/PowerRow/PowerBar
@onready var power_label: Label = $ScrollContainer/MarginContainer/VBoxContainer/PowerPanel/PowerContent/PowerRow/PowerLabel
@onready var battery_label: Label = $ScrollContainer/MarginContainer/VBoxContainer/PowerPanel/PowerContent/BatteryLabel
@onready var build_buttons: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer/BuildPanel/BuildContent/BuildButtons
@onready var status_label: Label = $ScrollContainer/MarginContainer/VBoxContainer/StatusPanel/StatusContent/StatusLabel
@onready var log_text: RichTextLabel = $ScrollContainer/MarginContainer/VBoxContainer/LogPanel/LogContent/LogText
@onready var controls_value: RichTextLabel = $ScrollContainer/MarginContainer/VBoxContainer/ControlsPanel/ControlsContent/ControlsValue

var _resource_manager: Node = null
var _resource_labels: Dictionary = {}
var _build_buttons: Dictionary = {}
var _building_counts: Dictionary = {}
var _log_buffer: Array[String] = []
const MAX_LOG_ENTRIES := 30

func _ready() -> void:
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")
		for resource_name in _resource_manager.get_resource_names():
			_add_resource_label(resource_name, _resource_manager.get_resource_amount(resource_name))
	_create_build_buttons()
	_update_controls_reference()
	_refresh_build_availability()

func update_resource_display(resource_name: String, new_value: float) -> void:
	if not _resource_labels.has(resource_name):
		_add_resource_label(resource_name, new_value)
	var label := _resource_labels[resource_name] as Label
	if label:
		label.text = _format_resource_line(resource_name, new_value)
	_refresh_build_availability()

func update_building_counts(counts: Dictionary) -> void:
	_building_counts = counts.duplicate(true)
	for building_id in _build_buttons.keys():
		var info := _build_buttons[building_id] as Dictionary
		if info == null:
			continue
		var button := info.get("button") as Button
		if button == null:
			continue
		var data := info.get("data") as Dictionary
		var count: int = counts.get(building_id, 0)
		button.text = _format_button_text(data, count)
		info["count"] = count
	_refresh_build_availability()

func update_power_status(power_data: Dictionary) -> void:
	var generation: float = float(power_data.get("generation", 0.0))
	var consumption: float = float(power_data.get("consumption", 0.0))
	var net: float = float(power_data.get("net", 0.0))
	var shortages: int = int(power_data.get("shortages", 0))
	var charge: float = float(power_data.get("battery_charge", 0.0))
	var capacity: float = max(0.01, float(power_data.get("battery_capacity", 0.0)))
	power_bar.max_value = capacity
	power_bar.value = clamp(charge, 0.0, capacity)
	power_label.text = "Net: %s (Gen %.2f / Use %.2f) | Shortages: %d" % [_format_signed(net), generation, consumption, shortages]
	battery_label.text = "Battery: %.2f / %.2f" % [charge, capacity]

func set_status_message(message: String) -> void:
	status_label.text = message
	append_log(message)

func append_log(message: String) -> void:
	_log_buffer.append("[%s] %s" % [_timestamp(), message])
	while _log_buffer.size() > MAX_LOG_ENTRIES:
		_log_buffer.remove_at(0)
	log_text.clear()
	for entry in _log_buffer:
		log_text.append_text(entry + "\n")
	log_text.scroll_to_line(log_text.get_line_count())

func focus_build_panel() -> void:
	for building_id in _build_buttons.keys():
		var button := _build_buttons[building_id]["button"] as Button
		if button and not button.disabled:
			button.grab_focus()
			break

func _add_resource_label(resource_name: String, value: float) -> void:
	var label := Label.new()
	label.name = resource_name
	label.text = _format_resource_line(resource_name, value)
	_resource_labels[resource_name] = label
	resource_grid.add_child(label)

func _create_build_buttons() -> void:
	for building_id in BUILDING_LIBRARY.get_ids():
		var data: Dictionary = BUILDING_LIBRARY.get_data(building_id)
		var button: Button = Button.new()
		button.focus_mode = Control.FOCUS_ALL
		button.text = _format_button_text(data, 0)
		button.tooltip_text = _cost_to_text(data.get("cost", {}))
		button.pressed.connect(_on_build_button_pressed.bind(building_id))
		build_buttons.add_child(button)
		_build_buttons[building_id] = {
			"button": button,
			"data": data,
			"count": 0
		}

func _format_resource_line(resource_name: String, value: float) -> String:
	return "%s: %s" % [resource_name.capitalize(), _format_resource_value(resource_name, value)]

func _format_resource_value(resource_name: String, value: float) -> String:
	match resource_name:
		"colonists":
			return str(int(round(value)))
		"morale":
			return "%d%%" % int(round(value))
		_:
			return "%.2f" % value

func _format_button_text(data: Dictionary, count: int) -> String:
	if data == null:
		return "Structure (%d)" % count
	return "%s (%d) – %s" % [data.get("display_name", "Structure"), count, _cost_to_text(data.get("cost", {}))]

func _cost_to_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "Free"
	var parts: Array[String] = []
	for resource_name in cost.keys():
		var amount := float(cost[resource_name])
		if amount <= 0.0:
			continue
		parts.append("%s %.0f" % [resource_name.capitalize(), amount])
	return ", ".join(parts)

func _on_build_button_pressed(building_id: String) -> void:
	build_requested.emit(building_id)

func _refresh_build_availability() -> void:
	if not _resource_manager:
		return
	for building_id in _build_buttons.keys():
		var info := _build_buttons[building_id] as Dictionary
		if info == null:
			continue
		var button := info.get("button") as Button
		if button == null:
			continue
		var data := info.get("data") as Dictionary
		var cost: Dictionary = data.get("cost", {})
		var affordable: bool = _resource_manager.can_afford(cost)
		button.disabled = not affordable

func _update_controls_reference() -> void:
	var text := "[b]B[/b] — Focus construction panel\n"
	text += "[b]P[/b] — Pause/Resume simulation\n"
	text += "[b]][/b] — Increase tick speed\n"
	text += "[b][[/b] — Decrease tick speed\n"
	text += "Click construction buttons to build instantly."
	controls_value.text = text

func _format_signed(value: float) -> String:
	if value > 0.0:
		return "+%.2f" % value
	if value < 0.0:
		return "%.2f" % value
	return "0.00"

func _timestamp() -> String:
	return Time.get_time_string_from_system()
