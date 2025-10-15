extends "res://scripts/buildings/BaseBuilding.gd"

@export var capacity: float = 25.0

var _resource_manager: Node = null

func _ready() -> void:
	super._ready()
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")
		if _resource_manager.has_method("register_battery"):
			_resource_manager.register_battery(self, capacity)

func _exit_tree() -> void:
	if _resource_manager and _resource_manager.has_method("unregister_battery"):
		_resource_manager.unregister_battery(self)
