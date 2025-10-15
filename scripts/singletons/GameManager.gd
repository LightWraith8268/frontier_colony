extends Node

## Global game state coordinator: ticks, save/load, prestige flow.
@export var tick_interval_seconds: float = 1.0

var _accumulated_time: float = 0.0
var is_paused: bool = false

func _ready() -> void:
	Engine.time_scale = 1.0

func _process(delta: float) -> void:
	if is_paused:
		return
	_accumulated_time += delta
	if _accumulated_time >= tick_interval_seconds:
		_accumulated_time -= tick_interval_seconds
		_tick()

func toggle_pause() -> void:
	is_paused = !is_paused

func _tick() -> void:
	## The ResourceManager drives resource production each tick.
	if Engine.has_singleton("ResourceManager"):
		Engine.get_singleton("ResourceManager").tick()
