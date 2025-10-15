extends Node
class_name BaseBuilding

@export var display_name: String = "Building"
@export var production: Dictionary = {}
@export var consumption: Dictionary = {}
@export var morale_bonus: float = 0.0

func _ready() -> void:
	add_to_group("resource_producers")

func produce_tick(resource_manager: Node) -> void:
	if _can_produce(resource_manager):
		for resource_name in consumption.keys():
			var cost = consumption[resource_name]
			if cost > 0.0:
				resource_manager.consume(resource_name, cost)
		var output_multiplier := 1.0
		if resource_manager.has_method("get_morale_multiplier"):
			output_multiplier = resource_manager.get_morale_multiplier()
		output_multiplier = max(0.0, output_multiplier + morale_bonus)
		for resource_name in production.keys():
			resource_manager.add(resource_name, production[resource_name] * output_multiplier)

func _can_produce(resource_manager: Node) -> bool:
	for resource_name in consumption.keys():
		var cost = consumption[resource_name]
		if cost <= 0.0:
			continue
		cost = float(cost)
		if resource_name == "energy" and resource_manager.has_method("ensure_energy"):
			if not resource_manager.ensure_energy(cost):
				if resource_manager.has_method("note_power_shortage"):
					resource_manager.note_power_shortage()
				return false
		if resource_manager.get_resource_amount(resource_name) < cost:
			if resource_name == "energy" and resource_manager.has_method("note_power_shortage"):
				resource_manager.note_power_shortage()
			return false
	return true
