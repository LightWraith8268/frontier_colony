extends Node
class_name BuildingLibrary

const BUILDINGS := {
	"solar_panel": {
		"display_name": "Solar Panel",
		"scene": preload("res://scenes/buildings/SolarPanel.tscn"),
		"cost": {
			"metal": 3.0
		}
	},
	"water_extractor": {
		"display_name": "Water Extractor",
		"scene": preload("res://scenes/buildings/WaterExtractor.tscn"),
		"cost": {
			"metal": 6.0,
			"energy": 2.0
		}
	},
	"hydroponics_bay": {
		"display_name": "Hydroponics Bay",
		"scene": preload("res://scenes/buildings/HydroponicsBay.tscn"),
		"cost": {
			"metal": 6.0,
			"water": 3.0
		}
	}
}

static func get_ids() -> Array:
	return BUILDINGS.keys()

static func get_data(building_id: String) -> Dictionary:
	return BUILDINGS.get(building_id, {})

static func instantiate(building_id: String) -> Node:
	var data = get_data(building_id)
	if data.is_empty():
		return null
	return data["scene"].instantiate()
