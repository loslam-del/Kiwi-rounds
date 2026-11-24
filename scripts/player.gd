extends CharacterBody2D
class_name ArenaPlayer

signal pulse_requested(origin: Vector2, direction: float, force: float, tint: Color)

@export var is_bot := false
@export var body_color := Color("#39d6c5")

const GRAVITY := 1850.0
const JUMP_SPEED := -735.0
const BASE_SPEED := 430.0

var move_input := 0.0
var jump_held := false
var fire_held := false
var touch_left := false
var touch_right := false
var touch_jump := false
var touch_fire := false
var target: Node2D
var move_speed := BASE_SPEED
var jump_speed := JUMP_SPEED
var pulse_force := 610.0
var pulse_cooldown := 0.0
var pulse_interval := 0.78
var bot_think := 0.0
var facing := 1.0

func _ready() -> void:
    collision_layer = 1
    collision_mask = 3
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 25.0
    shape.shape = circle
    add_child(shape)
    queue_redraw()

func set_left(value: bool) -> void:
    touch_left = value

func set_right(value: bool) -> void:
    touch_right = value

func set_jump(value: bool) -> void:
    touch_jump = value

func set_fire(value: bool) -> void:
    touch_fire = value

func _physics_process(delta: float) -> void:
    pulse_cooldown = maxf(0.0, pulse_cooldown - delta)

    if is_bot:
        _think_bot(delta)
    else:
        _read_keyboard()

    if move_input != 0.0:
        facing = signf(move_input)
    velocity.x = move_toward(velocity.x, move_input * move_speed, 2400.0 * delta)
    velocity.y += GRAVITY * delta

    if jump_held and is_on_floor():
        velocity.y = jump_speed

    if fire_held and pulse_cooldown <= 0.0:
        _fire_pulse()

    move_and_slide()

func _read_keyboard() -> void:
    var horizontal := 0.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        horizontal -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        horizontal += 1.0
    move_input = clampf(horizontal + float(touch_right) - float(touch_left), -1.0, 1.0)
    jump_held = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or touch_jump
    fire_held = Input.is_key_pressed(KEY_SPACE) or touch_fire

func _think_bot(delta: float) -> void:
    if not is_instance_valid(target):
        move_input = 0.0
        return
    var dx := target.global_position.x - global_position.x
    move_input = signf(dx) if absf(dx) > 100.0 else 0.0
    if absf(dx) > 0.01:
        facing = signf(dx)
    jump_held = is_on_floor() and target.global_position.y < global_position.y - 65.0
    bot_think -= delta
    if bot_think <= 0.0:
        bot_think = 0.22
        if absf(dx) < 560.0 and signf(dx) == facing:
            if randf() < 0.62:
                _fire_pulse()

func _fire_pulse() -> void:
    if pulse_cooldown > 0.0:
        return
    pulse_cooldown = pulse_interval
    pulse_requested.emit(global_position + Vector2(facing * 34.0, -3.0), facing, pulse_force, body_color)

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
    jump_held = false
    fire_held = false
    touch_left = false
    touch_right = false
    touch_jump = false
    touch_fire = false
    pulse_cooldown = 0.4

func _draw() -> void:
    draw_circle(Vector2(0, 0), 25.0, body_color)
    draw_circle(Vector2(0, 0), 25.0, Color("#17233b"), false, 3.0)
    draw_circle(Vector2(facing * 8.0, -5.0), 4.0, Color.WHITE)
    draw_circle(Vector2(facing * 9.5, -5.0), 2.0, Color("#17233b"))
    draw_arc(Vector2(0, 2), 10.0, 0.25, PI - 0.25, 16, Color("#17233b"), 2.5)
