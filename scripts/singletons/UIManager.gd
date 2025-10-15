extends CanvasLayer

## Bridges UI scenes with global resource and game state signals.
var hud: Node = null

func _ready() -> void:
	if Engine.has_singleton("ResourceManager"):
		Engine.get_singleton("ResourceManager").resource_updated.connect(_on_resource_updated)

func register_hud(node: Node) -> void:
	hud = node

func _on_resource_updated(resource_name: String, new_value: float) -> void:
	if hud and hud.has_method("update_resource_display"):
		hud.update_resource_display(resource_name, new_value)
