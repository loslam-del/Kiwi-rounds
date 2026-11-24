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
    collision_mask = 3
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
        body.hit_flash = 0.18
        body.got_hit.emit(direction)
        queue_free()
    else:
        queue_free()

func _draw() -> void:
    # Glowing kinetic bolt with layered core and motion streak.
    var tail := Vector2(-27.0,0.0)
    draw_line(tail,Vector2(2.0,0.0),Color(tint,0.16),15.0,true)
    draw_line(tail,Vector2(2.0,0.0),Color(tint,0.38),8.0,true)
    var halo := PackedVector2Array([Vector2(-12,-8),Vector2(5,-8),Vector2(17,0),Vector2(5,8),Vector2(-12,8)])
    draw_colored_polygon(halo,Color(tint,0.42))
    var core := PackedVector2Array([Vector2(-9,-4.5),Vector2(6,-4.5),Vector2(13,0),Vector2(6,4.5),Vector2(-9,4.5)])
    draw_colored_polygon(core,tint)
    draw_line(Vector2(-6,0),Vector2(8,0),Color.WHITE,2.0,true)
    draw_circle(Vector2(7,0),2.5,Color.WHITE)
