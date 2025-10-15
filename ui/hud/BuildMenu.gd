extends Control

const BUILDING_LIBRARY := preload("res://scripts/buildings/BuildingLibrary.gd")

signal building_chosen(building_id: String)

@onready var button_list := $Panel/MarginContainer/VBoxContainer

func _ready() -> void:
	_populate_buttons()

func _populate_buttons() -> void:
	for child in button_list.get_children():
		child.queue_free()
	for building_id in BUILDING_LIBRARY.get_ids():
		var data = BUILDING_LIBRARY.get_data(building_id)
		var button = Button.new()
		var cost_text = _cost_to_text(data.get("cost", {}))
		button.text = "%s (%s)" % [data.get("display_name", building_id), cost_text]
		button.pressed.connect(_on_button_pressed.bind(building_id))
		button_list.add_child(button)

func _on_button_pressed(building_id: String) -> void:
	building_chosen.emit(building_id)

func _cost_to_text(cost: Dictionary) -> String:
	var parts := []
	for resource_name in cost.keys():
		var amount = float(cost[resource_name])
		if amount <= 0.0:
			continue
		parts.append("%s %.0f" % [resource_name.capitalize(), amount])
	if parts.is_empty():
		return "Free"
	return ", ".join(parts)
