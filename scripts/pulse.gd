extends Area2D
class_name EnergyPulse

var direction := Vector2.RIGHT
var push_force := 780.0
var tint := Color("#39d6c5")
var life := 1.25
var speed := 1050.0
var shooter: Node2D

func configure(dir: Vector2, force: float, color: Color, source: Node2D) -> void:
    direction = dir.normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.RIGHT
    push_force = force
    tint = color
    shooter = source

func _ready() -> void:
    collision_layer = 0
    collision_mask = 1
    monitoring = true
    rotation = direction.angle()
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 9.0
    shape.shape = circle
    add_child(shape)
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    global_position += direction * speed * delta
    rotation = direction.angle()
    life -= delta
    if life <= 0.0 or global_position.x < -100.0 or global_position.x > 1380.0 or global_position.y < -100.0 or global_position.y > 820.0:
        queue_free()

func _on_body_entered(body: Node2D) -> void:
    if body == shooter:
        return
    if body is ArenaPlayer:
        body.velocity += direction * push_force
        body.velocity.y -= 150.0
        queue_free()

func _draw() -> void:
    # Яркий кинетический снаряд, а не круглая декоративная волна.
    draw_line(Vector2(-22.0,0.0),Vector2(2.0,0.0),Color(tint,0.35),9.0,true)
    var bullet := PackedVector2Array([
        Vector2(-9.0,-5.0),
        Vector2(5.0,-5.0),
        Vector2(12.0,0.0),
        Vector2(5.0,5.0),
        Vector2(-9.0,5.0)
    ])
    draw_colored_polygon(bullet,tint)
    draw_circle(Vector2(5.0,0.0),2.5,Color.WHITE)
