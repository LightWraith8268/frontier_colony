extends CanvasLayer

## Bridges UI scenes with global resource and game state signals.
var hud: Node = null
var _resource_manager: Node = null
var _last_power_status: Dictionary = {}

func _ready() -> void:
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")
		_resource_manager.resource_updated.connect(_on_resource_updated)
		if _resource_manager.has_signal("power_status_changed"):
			_resource_manager.power_status_changed.connect(_on_power_status_changed)
			if _resource_manager.has_method("get_power_status"):
				_last_power_status = _resource_manager.get_power_status()

func register_hud(node: Node) -> void:
	hud = node
	if _last_power_status and hud and hud.has_method("update_power_status"):
		hud.update_power_status(_last_power_status)

func _on_resource_updated(resource_name: String, new_value: float) -> void:
	if hud and hud.has_method("update_resource_display"):
		hud.update_resource_display(resource_name, new_value)

func _on_power_status_changed(power_data: Dictionary) -> void:
	_last_power_status = power_data
	if hud and hud.has_method("update_power_status"):
		hud.update_power_status(power_data)
