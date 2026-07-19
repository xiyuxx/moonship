class_name MailPlayer2D
extends CharacterBody2D

signal interact_requested

@export var speed := 260.0
var input_enabled := true

func _physics_process(_delta: float) -> void:
	if not input_enabled:
		velocity = Vector2.ZERO
		return
	velocity = Input.get_vector("move_left", "move_right", "move_forward", "move_back") * speed
	move_and_slide()
	position.x = clampf(position.x, 54.0, 1225.0)
	position.y = clampf(position.y, 178.0, 654.0)

func _input(event: InputEvent) -> void:
	if input_enabled and event is InputEventKey and event.pressed and event.keycode == KEY_F:
		interact_requested.emit()
