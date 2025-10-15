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
	"morale",
	"colonists"
]

const STARTING_STOCK := {
	"water": 10.0,
	"metal": 12.0,
	"energy": 20.0,
	"food": 8.0,
	"oxygen": 8.0,
	"components": 0.0,
	"data": 0.0,
	"morale": 60.0,
	"colonists": 5.0
}

const COLONIST_NEEDS := {
	"water": 0.4,
	"food": 0.4,
	"oxygen": 0.5
}
const MORALE_GAIN_PER_TICK := 1.0
const MORALE_LOSS_PER_SHORTAGE := 4.0
const MIN_MORALE := 0.0
const MAX_MORALE := 100.0

var resources := {}
@export var colonist_count: int = 5
signal resource_updated(resource_name: String, new_value: float)

func _ready() -> void:
	for resource_name in TRACKED_RESOURCES:
		resources[resource_name] = STARTING_STOCK.get(resource_name, 0.0)
		resource_updated.emit(resource_name, resources[resource_name])
	colonist_count = int(resources.get("colonists", colonist_count))
	resources["colonists"] = float(colonist_count)
	resource_updated.emit("colonists", resources["colonists"])

func get_resource_names() -> PackedStringArray:
	return PackedStringArray(TRACKED_RESOURCES)

func get_resource_amount(resource_name: String) -> float:
	return float(resources.get(resource_name, 0.0))

func add(resource_name: String, amount: float) -> void:
	var current = float(resources.get(resource_name, 0.0))
	resources[resource_name] = current + amount
	resource_updated.emit(resource_name, resources[resource_name])

func can_afford(cost: Dictionary) -> bool:
	for resource_name in cost.keys():
		var required = float(cost[resource_name])
		if required <= 0.0:
			continue
		var available = float(resources.get(resource_name, 0.0))
		if available < required:
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for resource_name in cost.keys():
		var required = float(cost[resource_name])
		if required > 0.0:
			consume(resource_name, required)
	return true

func consume(resource_name: String, amount: float) -> bool:
	var current = float(resources.get(resource_name, 0.0))
	if current < amount:
		return false
	resources[resource_name] = current - amount
	resource_updated.emit(resource_name, resources[resource_name])
	return true

func tick() -> void:
	_apply_colonist_needs()
	_run_producers()

func get_morale_multiplier() -> float:
	var morale = float(resources.get("morale", 50.0))
	return clamp(0.5 + (morale / 100.0), 0.25, 1.75)

func _apply_colonist_needs() -> void:
	if colonist_count <= 0:
		return
	var shortages := 0
	for resource_name in COLONIST_NEEDS.keys():
		var per_colonist = float(COLONIST_NEEDS[resource_name])
		var required = per_colonist * colonist_count
		if required <= 0.0:
			continue
		var available = float(resources.get(resource_name, 0.0))
		if available >= required:
			resources[resource_name] = available - required
			resource_updated.emit(resource_name, resources[resource_name])
		else:
			if available > 0.0:
				resources[resource_name] = 0.0
				resource_updated.emit(resource_name, 0.0)
			shortages += 1
	if shortages == 0:
		_adjust_morale(MORALE_GAIN_PER_TICK)
	else:
		_adjust_morale(-MORALE_LOSS_PER_SHORTAGE * shortages)

func _adjust_morale(delta: float) -> void:
	var current = float(resources.get("morale", 0.0))
	var updated = clamp(current + delta, MIN_MORALE, MAX_MORALE)
	if not is_equal_approx(current, updated):
		resources["morale"] = updated
		resource_updated.emit("morale", updated)

func _run_producers() -> void:
	## Iterate registered producers; building autoruns will subscribe later.
	for producer in get_tree().get_nodes_in_group("resource_producers"):
		if producer.has_method("produce_tick"):
			producer.produce_tick(self)
