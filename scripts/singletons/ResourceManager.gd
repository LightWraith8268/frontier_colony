extends Node

## Tracks resource pools and dispatches production during the global tick.
const TRACKED_RESOURCES := [
	"water",
	"metal",
	"energy",
	"food",
	"oxygen",
	"components",
	"data",
	"morale"
]

var resources := {}
signal resource_updated(resource_name: String, new_value: float)

func _ready() -> void:
	for resource_name in TRACKED_RESOURCES:
		resources[resource_name] = 0.0

func add(resource_name: String, amount: float) -> void:
	resources[resource_name] = (resources.get(resource_name, 0.0) + amount)
	resource_updated.emit(resource_name, resources[resource_name])

func consume(resource_name: String, amount: float) -> bool:
	var current := resources.get(resource_name, 0.0)
	if current < amount:
		return false
	resources[resource_name] = current - amount
	resource_updated.emit(resource_name, resources[resource_name])
	return true

func tick() -> void:
	## Iterate registered producers; building autoruns will subscribe later.
	for producer in get_tree().get_nodes_in_group("resource_producers"):
		if producer.has_method("produce_tick"):
			producer.produce_tick(self)
