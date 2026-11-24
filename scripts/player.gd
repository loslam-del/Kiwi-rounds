extends CharacterBody2D
class_name ArenaPlayer

signal pulse_requested(origin: Vector2, direction: Vector2, force: float, tint: Color, shooter: Node2D)

@export var is_bot := false
@export var body_color := Color("#39d6c5")

const GRAVITY := 1680.0
const JUMP_SPEED := -690.0
const BASE_SPEED := 430.0
const GROUND_ACCEL := 2550.0
const AIR_ACCEL := 1120.0
const GROUND_FRICTION := 2050.0
const AIR_DRAG := 120.0
const MAX_FALL_SPEED := 1120.0
const COYOTE_TIME := 0.105
const JUMP_BUFFER_TIME := 0.13
const WALL_JUMP_X := 475.0
const WALL_JUMP_Y := -625.0

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
var magazine_size := 6
var ammo := 6
var reload_duration := 1.35
var reload_timer := 0.0
var bot_think := 0.0
var bot_accuracy := 0.64
var facing := 1.0
var animation_time := 0.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var jump_was_held := false
var jump_hold_timer := 0.0
var wall_jump_lock := 0.0
var recoil_kick := 0.0
var muzzle_flash := 0.0
var reload_visual := 0.0

func _ready() -> void:
    collision_layer = 1
    collision_mask = 3
    var shape := CollisionShape2D.new()
    floor_snap_length = 8.0
    safe_margin = 0.08
    var capsule := CapsuleShape2D.new()
    capsule.radius = 18.0
    capsule.height = 88.0
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
    animation_time += delta * (8.5 if absf(velocity.x) > 35.0 and is_on_floor() else 2.2)
    pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
    recoil_kick = move_toward(recoil_kick, 0.0, delta * 38.0)
    muzzle_flash = maxf(0.0, muzzle_flash - delta)
    if reload_timer > 0.0:
        reload_timer = maxf(0.0, reload_timer - delta)
        reload_visual = reload_timer / maxf(reload_duration, 0.01)
        if reload_timer == 0.0:
            ammo = magazine_size
            reload_visual = 0.0
    if is_bot:
        _think_bot(delta)
    else:
        _read_keyboard()
    if absf(move_input) > 0.01 and wall_jump_lock <= 0.0:
        facing = signf(move_input)
    if is_on_floor():
        coyote_timer = COYOTE_TIME
    else:
        coyote_timer = maxf(0.0, coyote_timer - delta)
    if jump_held and not jump_was_held:
        jump_buffer_timer = JUMP_BUFFER_TIME
    else:
        jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
    jump_was_held = jump_held
    wall_jump_lock = maxf(0.0, wall_jump_lock - delta)
    var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
    if wall_jump_lock > 0.0:
        accel *= 0.18
    if absf(move_input) > 0.01:
        velocity.x = move_toward(velocity.x, move_input * move_speed, accel * delta)
    elif is_on_floor():
        velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, AIR_DRAG * delta)
    velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
    if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
        velocity.y = jump_speed
        coyote_timer = 0.0
        jump_buffer_timer = 0.0
        jump_hold_timer = 0.16
    elif jump_buffer_timer > 0.0 and is_on_wall() and not is_on_floor():
        var wall_normal := get_wall_normal()
        velocity.x = wall_normal.x * WALL_JUMP_X
        velocity.y = WALL_JUMP_Y
        facing = signf(wall_normal.x)
        jump_buffer_timer = 0.0
        coyote_timer = 0.0
        wall_jump_lock = 0.16
        jump_hold_timer = 0.12
    if jump_held and jump_hold_timer > 0.0 and velocity.y < 0.0:
        velocity.y -= 980.0 * delta
        jump_hold_timer = maxf(0.0, jump_hold_timer - delta)
    elif not jump_held:
        jump_hold_timer = 0.0
        if velocity.y < -180.0:
            velocity.y *= 0.58
    if fire_held and pulse_cooldown <= 0.0 and reload_timer <= 0.0:
        if ammo > 0:
            _fire_pulse()
        else:
            start_reload()
    move_and_slide()
    if is_on_wall() and not is_on_floor() and velocity.y > 160.0:
        velocity.y = minf(velocity.y, 270.0)
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
    if ammo <= 0 or reload_timer > 0.0:
        return
    ammo -= 1
    pulse_cooldown = pulse_interval
    muzzle_flash = 0.075
    recoil_kick = minf(recoil_kick + 7.0, 15.0)
    var shot_dir := aim_input.normalized()
    if shot_dir == Vector2.ZERO:
        shot_dir = Vector2(facing, 0.0)
    velocity -= shot_dir * (105.0 if is_on_floor() else 145.0)
    if ammo == 0:
        start_reload()
    var direction := aim_input.normalized()
    if direction == Vector2.ZERO:
        direction = Vector2(facing, 0.0)
    if absf(direction.x) > 0.12:
        facing = signf(direction.x)

    var muzzle := Vector2(facing * 13.0, -7.0) + direction * 38.0
    pulse_requested.emit(global_position + muzzle, direction, pulse_force, body_color, self)

func start_reload() -> void:
    if reload_timer <= 0.0 and ammo < magazine_size:
        reload_timer = reload_duration

func ammo_text() -> String:
    if reload_timer > 0.0:
        return "ПЕРЕЗАРЯДКА %.1f" % reload_timer
    return "ПАТРОНЫ %d/%d" % [ammo, magazine_size]

func apply_upgrade(upgrade_id: String) -> void:
    match upgrade_id:
        "swift":
            move_speed *= 1.16
            pulse_force *= 0.90
        "spring":
            jump_speed *= 1.12
            move_speed *= 0.92
        "wave":
            pulse_force *= 1.22
            reload_duration *= 1.12
        "rapid":
            reload_duration *= 0.82
            pulse_force *= 0.90
        "sturdy":
            pulse_force *= 1.10
            move_speed *= 1.06
            jump_speed *= 1.08

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
    ammo = magazine_size
    reload_timer = 0.0
    reload_visual = 0.0
    coyote_timer = 0.0
    jump_buffer_timer = 0.0
    jump_hold_timer = 0.0
    wall_jump_lock = 0.0
    recoil_kick = 0.0
    muzzle_flash = 0.0

func _draw() -> void:
    var moving := absf(velocity.x) > 35.0 and is_on_floor()
    var stride := sin(animation_time) * 8.0 if moving else 0.0
    var bob := absf(sin(animation_time * 2.0)) * 1.8 if moving else 0.0
    var skin := Color("#efbd94")
    var dark := Color("#202633")
    draw_circle(Vector2(0,46),19,Color(0,0,0,0.24))
    var foot_l := Vector2(-10+stride,42)
    var foot_r := Vector2(10-stride,42)
    draw_line(Vector2(-7,13+bob),foot_l,dark,11,true)
    draw_line(Vector2(7,13+bob),foot_r,dark,11,true)
    draw_line(foot_l+Vector2(-5,2),foot_l+Vector2(7,2),Color("#e8eaf0"),8,true)
    draw_line(foot_r+Vector2(-5,2),foot_r+Vector2(7,2),Color("#e8eaf0"),8,true)
    var rear := Vector2(-facing*21,2+sin(animation_time+PI)*3)
    draw_line(Vector2(-facing*10,-8),rear,Color("#27313f"),12,true)
    draw_line(rear,rear+Vector2(-facing*3,9),skin,8,true)
    draw_colored_polygon(PackedVector2Array([Vector2(-16,-15),Vector2(16,-15),Vector2(18,13),Vector2(11,23),Vector2(-11,23),Vector2(-18,13)]),body_color)
    draw_polyline(PackedVector2Array([Vector2(-16,-15),Vector2(-18,13),Vector2(-11,23),Vector2(11,23),Vector2(18,13),Vector2(16,-15)]),dark,2.5,true)
    draw_line(Vector2(0,-11),Vector2(0,18),Color("#e6e9ef"),2,true)
    draw_rect(Rect2(-12,16,24,4),dark)
    draw_rect(Rect2(-5,-22,10,10),skin)
    draw_circle(Vector2(0,-34-bob),14,skin)
    draw_arc(Vector2(0,-34-bob),14,PI,TAU,24,dark,3,true)
    draw_colored_polygon(PackedVector2Array([Vector2(-14,-37-bob),Vector2(-10,-48-bob),Vector2(0,-52-bob),Vector2(12,-47-bob),Vector2(15,-35-bob),Vector2(7,-40-bob),Vector2(-2,-42-bob),Vector2(-10,-37-bob)]),Color("#293044"))
    draw_circle(Vector2(facing*5,-34-bob),2.3,dark)
    draw_circle(Vector2(facing*8,-34-bob),1.0,Color.WHITE)
    draw_line(Vector2(facing,-26-bob),Vector2(facing*5,-25-bob),Color("#9b5e55"),1.5,true)
    var gun_dir := aim_input.normalized()
    if gun_dir == Vector2.ZERO:
        gun_dir = Vector2(facing,0)
    var side := Vector2(-gun_dir.y,gun_dir.x)
    var shoulder := Vector2(facing*11,-9)
    var grip := shoulder + gun_dir*22 + side*2
    draw_line(shoulder,grip,Color("#293342"),11,true)
    draw_circle(grip,5,skin)
    var support := Vector2(-facing*7,-4)
    draw_line(support,support+gun_dir*14,Color("#293342"),9,true)
    draw_circle(support+gun_dir*14,4.5,skin)
    var slide := PackedVector2Array([grip-side*5-gun_dir*8,grip+side*5-gun_dir*8,grip+side*5+gun_dir*20,grip-side*5+gun_dir*20])
    draw_colored_polygon(slide,Color("#394354"))
    draw_polyline(PackedVector2Array([slide[0],slide[1],slide[2],slide[3],slide[0]]),Color("#111722"),1.8,true)
    draw_line(grip+gun_dir*15,grip+gun_dir*31,Color("#aeb8c8"),5,true)
    draw_line(grip+side*3+gun_dir,grip+side*3-gun_dir*8,Color("#222936"),4,true)
    draw_line(grip+side*4+gun_dir,grip+side*10-gun_dir*3,Color("#303b4c"),6,true)
    draw_line(grip+gun_dir*31+side*2,grip+gun_dir*31-side*2,Color("#e4e9f1"),2,true)
    if pulse_cooldown > pulse_interval-0.09:
        draw_circle(grip+gun_dir*34,5,Color("#f6e78d"))
