extends Area2D
class_name EnergyPulse

var direction := Vector2.RIGHT
var push_force := 780.0
var tint := Color("#39d6c5")
var life := 1.25
var speed := 1050.0
var shooter: Node2D
var target: Node2D
var homing_strength := 0.0
var ricochets_left := 0
var weapon_level := 0

func configure(dir: Vector2, force: float, color: Color, source: Node2D) -> void:
    direction = dir.normalized()
    if direction == Vector2.ZERO:
        direction = Vector2.RIGHT
    push_force = force
    tint = color
    shooter = source
    target = source.get("target") as Node2D
    homing_strength = float(source.get("homing_strength"))
    ricochets_left = int(source.get("ricochet_count"))
    speed = float(source.get("projectile_speed"))
    weapon_level = int(source.get("weapon_level"))

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
    if homing_strength > 0.0 and is_instance_valid(target):
        var to_target := (target.global_position - global_position).normalized()
        var turn := clampf(direction.angle_to(to_target), -homing_strength * delta, homing_strength * delta)
        direction = direction.rotated(turn).normalized()
    global_position += direction * speed * delta
    rotation = direction.angle()
    life -= delta
    if life <= 0.0 or global_position.x < -100.0 or global_position.x > 1380.0 or global_position.y < -100.0 or global_position.y > 820.0:
        queue_free()

func _spawn_impact_particles() -> void:
    # Expanding ring gives impacts a clear readable contact point.
    var burst := Node2D.new()
    burst.global_position = global_position
    get_tree().current_scene.add_child(burst)
    var ring := Line2D.new()
    var ring_points := PackedVector2Array()
    for i in range(33):
        var angle := TAU * float(i) / 32.0
        ring_points.append(Vector2(cos(angle),sin(angle)) * 13.0)
    ring.points = ring_points
    ring.width = 2.6
    ring.default_color = tint.lightened(0.35)
    ring.antialiased = true
    burst.add_child(ring)
    var ring_tween := burst.create_tween()
    ring_tween.set_parallel(true)
    ring_tween.tween_property(burst,"scale",Vector2(3.0,3.0),0.22)
    ring_tween.tween_property(burst,"modulate:a",0.0,0.22)
    ring_tween.chain().tween_callback(burst.queue_free)
    var particles := CPUParticles2D.new()
    particles.one_shot = true
    particles.amount = 14
    particles.lifetime = 0.24
    particles.explosiveness = 1.0
    particles.direction = direction
    particles.spread = 155.0
    particles.initial_velocity_min = 90.0
    particles.initial_velocity_max = 260.0
    particles.gravity = Vector2(0.0,220.0)
    particles.scale_amount_min = 2.4
    particles.scale_amount_max = 2.4
    particles.color = tint.lightened(0.35)
    get_tree().current_scene.add_child(particles)
    particles.global_position = global_position
    particles.finished.connect(particles.queue_free)
    particles.emitting = true

func _on_body_entered(body: Node2D) -> void:
    if body == shooter:
        return
    if body is StaticBody2D and ricochets_left > 0:
        ricochets_left -= 1
        if body.name == "ArenaSideWall":
            direction.x = -direction.x
        else:
            direction.y = -direction.y
        direction = direction.normalized()
        rotation = direction.angle()
        global_position += direction * 10.0
        speed *= 0.94
        queue_redraw()
        return
    if body is ArenaPlayer:
        body.velocity += direction * push_force
        body.apply_hit_impulse(direction, push_force)
        body.velocity.y -= 150.0
        body.velocity.x = clampf(body.velocity.x,-1150.0,1150.0)
        body.velocity.y = clampf(body.velocity.y,-1250.0,1250.0)
        body.hitstun_timer = 0.14
        body.hit_flash = 0.18
        body.got_hit.emit(direction, body)
        _spawn_impact_particles()
        queue_free()
    else:
        _spawn_impact_particles()
        queue_free()

func _draw() -> void:
    # Layered neon streak, readable bright core and a tiny leading spark.
    var tail := Vector2(-34.0,0.0)
    draw_line(tail,Vector2(4.0,0.0),Color(tint,0.075),22.0,true)
    draw_line(tail,Vector2(4.0,0.0),Color(tint,0.18),14.0,true)
    draw_line(tail,Vector2(0.0,0.0),Color(tint,0.48),7.0,true)
    var halo := PackedVector2Array([Vector2(-14,-10),Vector2(6,-8),Vector2(20,0),Vector2(6,8),Vector2(-14,10)])
    draw_colored_polygon(halo,Color(tint,0.28))
    var core := PackedVector2Array([Vector2(-10,-4.5),Vector2(7,-4.5),Vector2(15,0),Vector2(7,4.5),Vector2(-10,4.5)])
    draw_colored_polygon(core,tint.lightened(0.08))
    draw_line(Vector2(-7,0),Vector2(10,0),Color(1.0,1.0,1.0,0.9),2.4,true)
    draw_circle(Vector2(10,0),3.2,Color.WHITE)
    if weapon_level >= 1:
        draw_arc(Vector2.ZERO,13.0,0.0,TAU,24,Color(tint.lightened(0.4),0.85),1.8,true)
    if weapon_level >= 2:
        draw_line(Vector2(-18,-9),Vector2(13,-9),Color.WHITE,1.4,true)
        draw_line(Vector2(-18,9),Vector2(13,9),Color.WHITE,1.4,true)
