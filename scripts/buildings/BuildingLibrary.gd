extends Node
class_name BuildingLibrary

const BUILDINGS := {
	"metal_mine": {
		"display_name": "Metal Mine",
		"scene": preload("res://scenes/buildings/MetalMine.tscn"),
		"cost": {
			"metal": 6.0
		},
		"requires": {},
		"order": 0
	},
	"solar_panel": {
		"display_name": "Solar Panel",
		"scene": preload("res://scenes/buildings/SolarPanel.tscn"),
		"cost": {
			"metal": 3.0
		},
		"requires": {
			"metal_mine": 1
		},
		"order": 1
	},
	"water_extractor": {
		"display_name": "Water Extractor",
		"scene": preload("res://scenes/buildings/WaterExtractor.tscn"),
		"cost": {
			"metal": 6.0
		},
		"requires": {
			"metal_mine": 1
		},
		"order": 2
	},
	"hydroponics_bay": {
		"display_name": "Hydroponics Bay",
		"scene": preload("res://scenes/buildings/HydroponicsBay.tscn"),
		"cost": {
			"metal": 6.0,
			"water": 3.0
		},
		"requires": {
			"water_extractor": 1
		},
		"order": 3
	},
	"battery_storage": {
		"display_name": "Battery Storage",
		"scene": preload("res://scenes/buildings/BatteryStorage.tscn"),
		"cost": {
			"metal": 5.0
		},
		"requires": {
			"solar_panel": 1
		},
		"order": 4
	},
	"foundry": {
		"display_name": "Foundry",
		"scene": preload("res://scenes/buildings/Foundry.tscn"),
		"cost": {
			"metal": 12.0,
			"energy": 2.0
		},
		"requires": {
			"metal_mine": 1,
			"solar_panel": 1
		},
		"order": 5
	},
	"research_lab": {
		"display_name": "Research Lab",
		"scene": preload("res://scenes/buildings/ResearchLab.tscn"),
		"cost": {
			"components": 2.0,
			"energy": 2.5
		},
		"requires": {
			"foundry": 1
		},
		"order": 6
	}
}

static func get_ids() -> Array:
	var ids := BUILDINGS.keys()
	ids.sort_custom(func(a, b):
		var order_a := int(BUILDINGS[a].get("order", 100))
		var order_b := int(BUILDINGS[b].get("order", 100))
		if order_a == order_b:
			var name_a := String(BUILDINGS[a].get("display_name", a))
			var name_b := String(BUILDINGS[b].get("display_name", b))
			return name_a < name_b
		return order_a < order_b
	)
	return ids

static func get_data(building_id: String) -> Dictionary:
	return BUILDINGS.get(building_id, {})

static func instantiate(building_id: String) -> Node:
	var data = get_data(building_id)
	if data.is_empty():
		return null
	return data["scene"].instantiate()
