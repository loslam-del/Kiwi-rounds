extends Area2D
class_name EnergyPulse

var direction := 1.0
var push_force := 610.0
var tint := Color("#39d6c5")
var life := 1.4
var speed := 760.0
var hit_ids: Array[int] = []

func configure(dir: float, force: float, color: Color) -> void:
    direction = dir
    push_force = force
    tint = color

func _ready() -> void:
    collision_layer = 0
    collision_mask = 1
    monitoring = true
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 19.0
    shape.shape = circle
    add_child(shape)
    body_entered.connect(_on_body_entered)
    queue_redraw()

func _physics_process(delta: float) -> void:
    global_position.x += direction * speed * delta
    life -= delta
    if life <= 0.0 or global_position.x < -100.0 or global_position.x > 1380.0:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body is ArenaPlayer and not hit_ids.has(body.get_instance_id()):
        hit_ids.append(body.get_instance_id())
        body.velocity.x += direction * push_force
        body.velocity.y -= 230.0
        queue_free()

func _draw() -> void:
    draw_circle(Vector2.ZERO, 15.0, Color(tint, 0.26))
    draw_circle(Vector2.ZERO, 8.0, tint)
    draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
