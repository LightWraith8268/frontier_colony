extends CanvasLayer

## Bridges UI scenes with global resource and game state signals.
var hud: Node = null
var _resource_manager: Node = null

func _ready() -> void:
	if has_node("/root/ResourceManager"):
		_resource_manager = get_node("/root/ResourceManager")
		_resource_manager.resource_updated.connect(_on_resource_updated)

func register_hud(node: Node) -> void:
	hud = node

func _on_resource_updated(resource_name: String, new_value: float) -> void:
	if hud and hud.has_method("update_resource_display"):
		hud.update_resource_display(resource_name, new_value)
