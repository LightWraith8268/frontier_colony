extends Node2D

const HUD_SCENE := preload("res://ui/hud/ResourceHUD.tscn")
const BUILD_MENU_SCENE := preload("res://ui/hud/BuildMenu.tscn")
const BUILDING_LIBRARY := preload("res://scripts/buildings/BuildingLibrary.gd")
const SOLAR_PANEL_SCENE := preload("res://scenes/buildings/SolarPanel.tscn")
const WATER_EXTRACTOR_SCENE := preload("res://scenes/buildings/WaterExtractor.tscn")
const HYDROPONICS_SCENE := preload("res://scenes/buildings/HydroponicsBay.tscn")

@onready var buildings_root := $Buildings

var _hud_instance: Control = null
var _game_manager: Node = null
var _resource_manager: Node = null
var _build_menu_instance: Control = null
var _pending_building_id: String = ""

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
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			_attempt_place_building()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			_clear_pending_building()

func _ensure_input_mappings() -> void:
	var defaults = {
		"pause_sim": KEY_P,
		"speed_up": KEY_BRACKETRIGHT,
		"speed_down": KEY_BRACKETLEFT,
		"open_build_menu": KEY_B,
		"toggle_overlay": KEY_TAB
	}
	for action_name in defaults.keys():
		var keycode = defaults[action_name]
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		if not _action_has_key(action_name, keycode):
			var ev = InputEventKey.new()
			ev.physical_keycode = keycode
			ev.keycode = keycode
			InputMap.action_add_event(action_name, ev)

func _action_has_key(action_name: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
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
	if not buildings_root:
		return
	var solar := SOLAR_PANEL_SCENE.instantiate()
	solar.position = Vector2(-120, 0)
	buildings_root.add_child(solar)

	var extractor := WATER_EXTRACTOR_SCENE.instantiate()
	extractor.position = Vector2(0, 0)
	buildings_root.add_child(extractor)

	var hydro := HYDROPONICS_SCENE.instantiate()
	hydro.position = Vector2(120, 0)
	buildings_root.add_child(hydro)

func _toggle_build_menu() -> void:
	if not _build_menu_instance:
		return
	_build_menu_instance.visible = not _build_menu_instance.visible
	if _build_menu_instance.visible:
		_update_status("Select a building to place, or right click to cancel.")
	elif _pending_building_id.is_empty():
		_update_status("Press B to open the build menu.")

func _on_building_chosen(building_id: String) -> void:
	_pending_building_id = building_id
	if _build_menu_instance:
		_build_menu_instance.hide()
	var data = BUILDING_LIBRARY.get_data(building_id)
	var name = data.get("display_name", building_id)
	_update_status("Placing %s: left click to confirm, right click to cancel." % name)

func _attempt_place_building() -> void:
	if _pending_building_id.is_empty() or not _resource_manager or not buildings_root:
		return
	var data = BUILDING_LIBRARY.get_data(_pending_building_id)
	if data.is_empty():
		_update_status("Unknown building selection.")
		_pending_building_id = ""
		return
	var cost = data.get("cost", {})
	var name = data.get("display_name", _pending_building_id)
	if not _resource_manager.can_afford(cost):
		_update_status("Not enough resources for %s." % name)
		return
	if not _resource_manager.pay(cost):
		_update_status("Payment failed for %s." % name)
		return
	var building = BUILDING_LIBRARY.instantiate(_pending_building_id)
	if not building:
		_update_status("Failed to create %s." % name)
		return
	var world_position = get_global_mouse_position()
	var local_position = buildings_root.to_local(world_position)
	if building is Node2D:
		building.position = local_position
	buildings_root.add_child(building)
	_update_status("%s placed." % name)
	_pending_building_id = ""

func _clear_pending_building() -> void:
	if _pending_building_id.is_empty():
		return
	_pending_building_id = ""
	_update_status("Placement canceled. Press B for the build menu.")

func _update_status(message: String) -> void:
	if _hud_instance and _hud_instance.has_method("set_status_message"):
		_hud_instance.set_status_message(message)
