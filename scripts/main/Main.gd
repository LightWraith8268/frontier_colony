extends Node

const HUD_SCENE := preload("res://ui/hud/ResourceHUD.tscn")
const BUILD_MENU_SCENE := preload("res://ui/hud/BuildMenu.tscn")
const BUILDING_LIBRARY := preload("res://scripts/buildings/BuildingLibrary.gd")

@onready var buildings_root := $Buildings

var _hud_instance: Control = null
var _game_manager: Node = null
var _resource_manager: Node = null
var _build_menu_instance: Control = null
var _building_counts: Dictionary = {}

func _ready() -> void:
	if has_node("/root/GameManager"):
		_game_manager = get_node("/root/GameManager")
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")
	_ensure_input_mappings()
	_spawn_hud()
	_spawn_build_menu()
	_spawn_initial_colony()

func _exit_tree() -> void:
	if _hud_instance and is_instance_valid(_hud_instance):
		_hud_instance.queue_free()
	if _build_menu_instance and is_instance_valid(_build_menu_instance):
		_build_menu_instance.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not _game_manager:
		return
	if event.is_action_pressed("pause_sim"):
		_game_manager.toggle_pause()
	elif event.is_action_pressed("speed_up"):
		_game_manager.increase_speed()
	elif event.is_action_pressed("speed_down"):
		_game_manager.decrease_speed()
	elif event.is_action_pressed("open_build_menu"):
		_toggle_build_menu()

func _ensure_input_mappings() -> void:
	var defaults: Dictionary = {
		"pause_sim": KEY_P,
		"speed_up": KEY_BRACKETRIGHT,
		"speed_down": KEY_BRACKETLEFT,
		"open_build_menu": KEY_B,
		"toggle_overlay": KEY_TAB
	}
	for action_name in defaults.keys():
		var keycode: int = int(defaults[action_name])
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		if not _action_has_key(action_name, keycode):
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			ev.keycode = keycode
			InputMap.action_add_event(action_name, ev)

func _action_has_key(action_name: String, keycode: int) -> bool:
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventKey and input_event.physical_keycode == keycode:
			return true
	return false

func _spawn_hud() -> void:
	if _hud_instance:
		return
	_hud_instance = HUD_SCENE.instantiate()
	UIManager.add_child(_hud_instance)
	UIManager.register_hud(_hud_instance)
	_update_status("Press B to open the build menu.")

func _spawn_build_menu() -> void:
	if _build_menu_instance:
		return
	_build_menu_instance = BUILD_MENU_SCENE.instantiate()
	_build_menu_instance.building_chosen.connect(_on_building_chosen)
	UIManager.add_child(_build_menu_instance)

func _spawn_initial_colony() -> void:
	for building_id in ["solar_panel", "water_extractor", "hydroponics_bay"]:
		_create_and_register_building(building_id)
	_update_status("Starter colony online. Press B to expand.")

func _toggle_build_menu() -> void:
	if not _build_menu_instance:
		return
	_build_menu_instance.visible = not _build_menu_instance.visible
	if _build_menu_instance.visible:
		_update_status("Select a building to construct, or press B to close.")
	else:
		_update_status("Press B to open the build menu.")

func _on_building_chosen(building_id: String) -> void:
	var data: Dictionary = BUILDING_LIBRARY.get_data(building_id)
	var name: String = str(data.get("display_name", building_id))
	if data.is_empty():
		_update_status("Unknown structure selection.")
		return
	if not _resource_manager:
		_update_status("Resource manager unavailable.")
		return
	var cost: Dictionary = data.get("cost", {})
	if not _resource_manager.can_afford(cost):
		_update_status("Not enough resources for %s." % name)
		return
	if not _resource_manager.pay(cost):
		_update_status("Payment failed for %s." % name)
		return
	if _create_and_register_building(building_id):
		_update_status("%s constructed." % name)
	else:
		_update_status("Failed to create %s." % name)

func _create_and_register_building(building_id: String) -> bool:
	if not buildings_root:
		return false
	var building: Node = BUILDING_LIBRARY.instantiate(building_id)
	if not building:
		return false
	_register_building(building_id, building)
	return true

func _register_building(building_id: String, building: Node) -> void:
	building.set_meta("building_id", building_id)
	buildings_root.add_child(building)
	_building_counts[building_id] = int(_building_counts.get(building_id, 0)) + 1
	_refresh_building_counts_ui()

func _refresh_building_counts_ui() -> void:
	if _hud_instance and _hud_instance.has_method("update_building_counts"):
		var counts: Dictionary = {}
		for building_id in _building_counts.keys():
			counts[building_id] = _building_counts[building_id]
		_hud_instance.update_building_counts(counts)

func _update_status(message: String) -> void:
	if _hud_instance and _hud_instance.has_method("set_status_message"):
		_hud_instance.set_status_message(message)
