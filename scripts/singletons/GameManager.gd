extends Node

## Global game state coordinator: ticks, save/load, prestige flow.
@export var tick_interval_seconds: float = 1.0
const SPEED_LEVELS := [2.0, 1.0, 0.5, 0.25]

var _accumulated_time: float = 0.0
var is_paused: bool = false
var _resource_manager: Node = null
var _speed_index: int = 1

func _ready() -> void:
	Engine.time_scale = 1.0
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")

func _process(delta: float) -> void:
	if is_paused:
		return
	_accumulated_time += delta
	if _accumulated_time >= tick_interval_seconds:
		_accumulated_time -= tick_interval_seconds
		_tick()

func toggle_pause() -> void:
	is_paused = !is_paused

func increase_speed() -> void:
	_speed_index = max(_speed_index - 1, 0)
	tick_interval_seconds = SPEED_LEVELS[_speed_index]

func decrease_speed() -> void:
	_speed_index = min(_speed_index + 1, SPEED_LEVELS.size() - 1)
	tick_interval_seconds = SPEED_LEVELS[_speed_index]

func _tick() -> void:
	## The ResourceManager drives resource production each tick.
	if _resource_manager:
		_resource_manager.tick()
