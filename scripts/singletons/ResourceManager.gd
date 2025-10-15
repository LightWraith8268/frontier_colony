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

var resources: Dictionary = {}
@export var colonist_count: int = 5
signal resource_updated(resource_name: String, new_value: float)
signal power_status_changed(power_data: Dictionary)

var _energy_generated_last_tick: float = 0.0
var _energy_consumed_last_tick: float = 0.0
var _power_shortages: int = 0
var _battery_charge: float = 0.0
var _battery_capacity_total: float = 0.0
var _battery_registry: Dictionary = {}
var _last_power_status: Dictionary = {}

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
	if resource_name == "energy":
		_energy_generated_last_tick += amount

func can_afford(cost: Dictionary) -> bool:
	for resource_name in cost.keys():
		var required: float = float(cost[resource_name])
		if required <= 0.0:
			continue
		var available: float = float(resources.get(resource_name, 0.0))
		if available < required:
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for resource_name in cost.keys():
		var required: float = float(cost[resource_name])
		if required > 0.0:
			consume(resource_name, required)
	return true

func consume(resource_name: String, amount: float) -> bool:
	var current: float = float(resources.get(resource_name, 0.0))
	if current < amount:
		return false
	resources[resource_name] = current - amount
	resource_updated.emit(resource_name, resources[resource_name])
	if resource_name == "energy":
		_energy_consumed_last_tick += amount
	return true

func tick() -> void:
	_reset_tick_counters()
	_apply_colonist_needs()
	_run_producers()
	_balance_power_storage()
	_emit_power_status()

func get_morale_multiplier() -> float:
	var morale: float = float(resources.get("morale", 50.0))
	return clamp(0.5 + (morale / 100.0), 0.25, 1.75)

func _apply_colonist_needs() -> void:
	if colonist_count <= 0:
		return
	var shortages: int = 0
	for resource_name in COLONIST_NEEDS.keys():
		var per_colonist: float = float(COLONIST_NEEDS[resource_name])
		var required: float = per_colonist * colonist_count
		if required <= 0.0:
			continue
		var available: float = float(resources.get(resource_name, 0.0))
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
	var current: float = float(resources.get("morale", 0.0))
	var updated: float = clamp(current + delta, MIN_MORALE, MAX_MORALE)
	if not is_equal_approx(current, updated):
		resources["morale"] = updated
		resource_updated.emit("morale", updated)

func _run_producers() -> void:
	## Iterate registered producers; building autoruns will subscribe later.
	for producer in get_tree().get_nodes_in_group("resource_producers"):
		if producer.has_method("produce_tick"):
			producer.produce_tick(self)

func ensure_energy(required: float) -> bool:
	var available: float = float(resources.get("energy", 0.0))
	if available >= required:
		return true
	var deficit: float = required - available
	if deficit <= 0.0:
		return true
	var drawn: float = min(deficit, _battery_charge)
	if drawn > 0.0:
		_battery_charge -= drawn
		resources["energy"] = available + drawn
		resource_updated.emit("energy", resources["energy"])
	available = float(resources.get("energy", 0.0))
	return available >= required

func note_power_shortage() -> void:
	_power_shortages += 1

func register_battery(owner: Node, capacity: float) -> void:
	if _battery_registry.has(owner):
		return
	_battery_registry[owner] = capacity
	_battery_capacity_total += capacity
	_emit_power_status()

func unregister_battery(owner: Node) -> void:
	if not _battery_registry.has(owner):
		return
	var capacity: float = float(_battery_registry[owner])
	_battery_capacity_total = max(0.0, _battery_capacity_total - capacity)
	_battery_registry.erase(owner)
	_battery_charge = clamp(_battery_charge, 0.0, _battery_capacity_total)
	_emit_power_status()

func get_power_status() -> Dictionary:
	return _last_power_status.duplicate(true)

func _reset_tick_counters() -> void:
	_energy_generated_last_tick = 0.0
	_energy_consumed_last_tick = 0.0
	_power_shortages = 0

func _balance_power_storage() -> void:
	if _battery_capacity_total <= 0.0:
		return
	var net: float = _energy_generated_last_tick - _energy_consumed_last_tick
	if net > 0.0:
		var available_capacity: float = _battery_capacity_total - _battery_charge
		if available_capacity <= 0.0:
			return
		var energy_available: float = float(resources.get("energy", 0.0))
		var to_store: float = min(net, available_capacity)
		to_store = min(to_store, energy_available)
		if to_store > 0.0:
			resources["energy"] = energy_available - to_store
			resource_updated.emit("energy", resources["energy"])
			_battery_charge += to_store
	elif net < 0.0:
		var deficit: float = min(-net, _battery_charge)
		if deficit > 0.0:
			_battery_charge -= deficit
			resources["energy"] = float(resources.get("energy", 0.0)) + deficit
			resource_updated.emit("energy", resources["energy"])

func _emit_power_status() -> void:
	var status: Dictionary = {
		"generation": _energy_generated_last_tick,
		"consumption": _energy_consumed_last_tick,
		"net": _energy_generated_last_tick - _energy_consumed_last_tick,
		"shortages": _power_shortages,
		"battery_charge": _battery_charge,
		"battery_capacity": _battery_capacity_total
	}
	_last_power_status = status
	power_status_changed.emit(status)
