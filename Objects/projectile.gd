extends Area2D

class_name Projectile

@export var speed: float = 100.0

var damageAmount = 1.0
var direction: Vector2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += delta * speed * direction
	pass

func setup(dir: Vector2, damage: float):
	self.damageAmount = damage
	direction = dir
	look_at(global_position + dir)
	set_rotation_degrees(get_rotation_degrees() + 90)
	return

func _on_body_entered(body):
	if body.has_method("damage"):
		body.damage(damageAmount)
	queue_free()
	return
