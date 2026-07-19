class_name MailPlayer
extends CharacterBody3D

signal interact_requested(interaction_id: String)

@export var speed := 4.2
@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay

var yaw := 0.0
var pitch := -0.15
var input_enabled := true

func _physics_process(_delta: float) -> void:
	if not input_enabled:
		velocity = Vector3.ZERO
		return
	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := global_transform.basis.x * move.x + global_transform.basis.z * move.y
	direction.y = 0.0
	velocity = direction * speed
	move_and_slide()
	position.x = clamp(position.x, -8.0, 8.0)
	position.z = clamp(position.z, -7.0, 7.0)

func _input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * 0.0025
		pitch = clamp(pitch - event.relative.y * 0.0025, -1.1, 0.8)
		rotation.y = yaw
		camera.rotation.x = pitch
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		var interaction_id := get_interaction_id()
		if interaction_id != "":
			interact_requested.emit(interaction_id)

func get_interaction_id() -> String:
	interaction_ray.force_raycast_update()
	var collider := interaction_ray.get_collider()
	return str(collider.get_meta("id")) if collider != null and collider.has_meta("id") else ""
