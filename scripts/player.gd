extends CharacterBody2D
class_name ArenaPlayer

signal pulse_requested(origin: Vector2, direction: Vector2, force: float, tint: Color)

@export var is_bot := false
@export var body_color := Color("#39d6c5")

const GRAVITY := 1850.0
const JUMP_SPEED := -735.0
const BASE_SPEED := 430.0

var move_input := 0.0
var move_stick := Vector2.ZERO
var jump_held := false
var fire_held := false
var touch_jump := false
var touch_fire := false
var aim_input := Vector2.RIGHT
var target: Node2D
var move_speed := BASE_SPEED
var jump_speed := JUMP_SPEED
var pulse_force := 780.0
var pulse_cooldown := 0.0
var pulse_interval := 0.62
var bot_think := 0.0
var bot_accuracy := 0.64
var facing := 1.0
var animation_time := 0.0

func _ready() -> void:
    collision_layer = 1
    collision_mask = 3
    var shape := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = 17.0
    capsule.height = 76.0
    shape.shape = capsule
    add_child(shape)

func set_move(value: Vector2) -> void:
    move_stick = value

func set_aim(value: Vector2) -> void:
    if value.length() > 0.16:
        aim_input = value.normalized()
        if absf(aim_input.x) > 0.12:
            facing = signf(aim_input.x)

func set_jump(value: bool) -> void:
    touch_jump = value

func set_fire(value: bool) -> void:
    touch_fire = value

func _physics_process(delta: float) -> void:
    animation_time += delta * (7.0 if absf(velocity.x) > 35.0 and is_on_floor() else 2.0)
    pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
    if is_bot:
        _think_bot(delta)
    else:
        _read_keyboard()

    if absf(move_input) > 0.01:
        facing = signf(move_input)

    velocity.x = move_toward(velocity.x, move_input * move_speed, 2400.0 * delta)
    velocity.y += GRAVITY * delta

    if jump_held and is_on_floor():
        velocity.y = jump_speed

    if fire_held and pulse_cooldown <= 0.0:
        _fire_pulse()

    move_and_slide()
    queue_redraw()

func _read_keyboard() -> void:
    var horizontal := 0.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        horizontal -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        horizontal += 1.0
    move_input = clampf(horizontal + move_stick.x, -1.0, 1.0)
    jump_held = touch_jump or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
    fire_held = touch_fire or Input.is_key_pressed(KEY_SPACE)

    var aim := Vector2.ZERO
    if Input.is_key_pressed(KEY_J):
        aim.x -= 1.0
    if Input.is_key_pressed(KEY_L):
        aim.x += 1.0
    if Input.is_key_pressed(KEY_I):
        aim.y -= 1.0
    if Input.is_key_pressed(KEY_K):
        aim.y += 1.0
    if aim != Vector2.ZERO:
        set_aim(aim)

func _think_bot(delta: float) -> void:
    if not is_instance_valid(target):
        move_input = 0.0
        return

    var delta_x := target.global_position.x - global_position.x
    move_input = signf(delta_x) if absf(delta_x) > 130.0 else 0.0
    var aim_vector := (target.global_position - global_position).normalized()
    set_aim(aim_vector)
    jump_held = is_on_floor() and target.global_position.y < global_position.y - 65.0

    bot_think -= delta
    if bot_think <= 0.0:
        bot_think = 0.18
        if aim_vector.length() > 0.0 and randf() < bot_accuracy:
            _fire_pulse()

func _fire_pulse() -> void:
    if pulse_cooldown > 0.0:
        return
    pulse_cooldown = pulse_interval
    var direction := aim_input.normalized()
    if direction == Vector2.ZERO:
        direction = Vector2(facing, 0.0)
    if absf(direction.x) > 0.12:
        facing = signf(direction.x)

    var muzzle := Vector2(facing * 13.0, -7.0) + direction * 38.0
    pulse_requested.emit(global_position + muzzle, direction, pulse_force, body_color)

func apply_upgrade(upgrade_id: String) -> void:
    match upgrade_id:
        "swift":
            move_speed *= 1.16
        "spring":
            jump_speed *= 1.12
        "wave":
            pulse_force *= 1.22
        "rapid":
            pulse_interval *= 0.82
        "sturdy":
            pulse_force *= 1.10
            move_speed *= 1.06

func reset_round(spawn: Vector2) -> void:
    global_position = spawn
    velocity = Vector2.ZERO
    move_input = 0.0
    move_stick = Vector2.ZERO
    jump_held = false
    fire_held = false
    touch_jump = false
    touch_fire = false
    aim_input = Vector2(facing, 0.0)
    pulse_cooldown = 0.4

func _draw() -> void:
    var moving := absf(velocity.x) > 35.0 and is_on_floor()
    var stride := sin(animation_time) * 9.0 if moving else 0.0
    var bob := absf(sin(animation_time * 2.0)) * 1.5 if moving else 0.0

    # Тень и ноги рисуются первыми, чтобы корпус находился поверх них.
    draw_ellipse_shadow()
    var left_hip := Vector2(-7.0, 14.0 + bob)
    var right_hip := Vector2(7.0, 14.0 + bob)
    var left_foot := Vector2(-9.0 + stride, 43.0)
    var right_foot := Vector2(9.0 - stride, 43.0)
    draw_line(left_hip, left_foot, Color("#26334a"), 10.0, true)
    draw_line(right_hip, right_foot, Color("#26334a"), 10.0, true)
    draw_line(left_foot + Vector2(-3.0,0), left_foot + Vector2(5.0,0), Color("#e7edf6"), 7.0, true)
    draw_line(right_foot + Vector2(-3.0,0), right_foot + Vector2(5.0,0), Color("#e7edf6"), 7.0, true)

    # Дальняя рука.
    var rear_hand := Vector2(-facing * 20.0, 5.0 + sin(animation_time + PI) * 3.0)
    draw_line(Vector2(-facing * 10.0,-7.0), rear_hand, Color("#d9a77f"), 8.0, true)
    draw_circle(rear_hand, 5.0, Color("#f0bd91"))

    # Корпус и шея.
    draw_rect(Rect2(-14.0,-13.0,28.0,34.0), body_color)
    draw_rect(Rect2(-14.0,-13.0,28.0,34.0), Color("#17233b"), false, 2.5)
    draw_rect(Rect2(-5.0,-18.0,10.0,8.0), Color("#e9b88e"))

    # Голова, глаза и контур.
    draw_circle(Vector2(0.0,-29.0-bob), 13.0, Color("#efbd94"))
    draw_arc(Vector2(0.0,-29.0-bob), 13.0, PI, TAU, 20, Color("#17233b"), 2.5, true)
    draw_circle(Vector2(facing * 5.0,-30.0-bob), 2.2, Color("#17233b"))
    draw_circle(Vector2(facing * 8.0,-30.0-bob), 1.0, Color.WHITE)

    # Передняя рука держит пистолет.
    var gun_dir := aim_input.normalized()
    if gun_dir == Vector2.ZERO:
        gun_dir = Vector2(facing,0.0)
    var side := Vector2(-gun_dir.y,gun_dir.x)
    var hand := Vector2(facing * 10.0,-5.0) + gun_dir * 22.0
    draw_line(Vector2(facing * 10.0,-7.0), hand, Color("#efbd94"), 9.0, true)
    draw_circle(hand, 5.5, Color("#efbd94"))

    # Пистолет: рукоять, затвор, ствол и мушка.
    var grip := hand - gun_dir * 2.0 + side * 7.0
    var gun_body := PackedVector2Array([
        hand - side * 5.0 - gun_dir * 5.0,
        hand + side * 5.0 - gun_dir * 5.0,
        hand + side * 4.0 + gun_dir * 16.0,
        hand - side * 4.0 + gun_dir * 16.0
    ])
    draw_colored_polygon(gun_body, Color("#303b50"))
    draw_line(hand + side * 2.0, hand + side * 11.0 - gun_dir * 1.0, Color("#303b50"), 6.0, true)
    draw_line(hand + gun_dir * 11.0, hand + gun_dir * 25.0, Color("#9daec4"), 5.0, true)
    draw_line(hand + gun_dir * 12.0 + side * 2.0, hand + gun_dir * 12.0 - side * 2.0, Color("#dce6f3"), 2.0, true)

    if pulse_cooldown > pulse_interval - 0.09:
        draw_circle(hand + gun_dir * 27.0, 5.0, Color("#fff0ad"))
