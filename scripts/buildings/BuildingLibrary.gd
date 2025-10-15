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
			"metal": 6.0
		}
	},
	"metal_mine": {
		"display_name": "Metal Mine",
		"scene": preload("res://scenes/buildings/MetalMine.tscn"),
		"cost": {
			"metal": 8.0,
			"energy": 2.0
		}
	},
	"battery_storage": {
		"display_name": "Battery Storage",
		"scene": preload("res://scenes/buildings/BatteryStorage.tscn"),
		"cost": {
			"metal": 5.0
		}
	},
	"hydroponics_bay": {
		"display_name": "Hydroponics Bay",
		"scene": preload("res://scenes/buildings/HydroponicsBay.tscn"),
		"cost": {
			"metal": 6.0,
			"water": 3.0
		}
	},
	"foundry": {
		"display_name": "Foundry",
		"scene": preload("res://scenes/buildings/Foundry.tscn"),
		"cost": {
			"metal": 10.0,
			"energy": 2.0
		}
	},
	"research_lab": {
		"display_name": "Research Lab",
		"scene": preload("res://scenes/buildings/ResearchLab.tscn"),
		"cost": {
			"components": 2.0,
			"energy": 2.5
		}
	}
}

static func get_ids() -> Array:
	var ids := BUILDINGS.keys()
	ids.sort()
	return ids

static func get_data(building_id: String) -> Dictionary:
	return BUILDINGS.get(building_id, {})

static func instantiate(building_id: String) -> Node:
	var data = get_data(building_id)
	if data.is_empty():
		return null
	return data["scene"].instantiate()
