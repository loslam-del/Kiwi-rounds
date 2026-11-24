extends CharacterBody2D
class_name ArenaPlayer

signal pulse_requested(origin: Vector2, direction: Vector2, force: float, tint: Color, shooter: Node2D)
signal got_hit(direction: Vector2, hit_target: Node2D)
signal reload_started

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
var hit_flash := 0.0
var bot_jump_hold_timer := 0.0

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
    hit_flash = maxf(0.0, hit_flash - delta)
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
    var jump_released := jump_was_held and not jump_held
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
    elif jump_released:
        jump_hold_timer = 0.0
        if velocity.y < -180.0:
            velocity.y *= 0.58
    elif not jump_held:
        jump_hold_timer = 0.0
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
    var distance_x := absf(delta_x)
    if distance_x > 235.0:
        move_input = signf(delta_x)
    elif distance_x < 115.0:
        move_input = -signf(delta_x)
    else:
        move_input = 0.0
    var direct_vector := target.global_position - global_position
    var travel_time := direct_vector.length() / 1050.0
    var predicted_target := target.global_position + target.velocity * minf(travel_time,0.32)
    var aim_vector := (predicted_target - global_position).normalized()
    set_aim(aim_vector)
    bot_jump_hold_timer = maxf(0.0,bot_jump_hold_timer-delta)
    if is_on_floor() and bot_jump_hold_timer <= 0.0 and (target.global_position.y < global_position.y - 70.0 or (distance_x < 100.0 and randf() < 0.018)):
        bot_jump_hold_timer = 0.23
    jump_held = bot_jump_hold_timer > 0.0

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
        reload_started.emit()

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
    hit_flash = 0.0
    bot_jump_hold_timer = 0.0

func _draw() -> void:
    var grounded := is_on_floor()
    var moving := absf(velocity.x) > 35.0 and grounded
    var stride := sin(animation_time) * 9.0 if moving else 0.0
    var bob := absf(sin(animation_time * 2.0)) * 2.0 if moving else 0.0
    if hit_flash > 0.0:
        draw_circle(Vector2(0,-8),37.0,Color(1.0,0.32,0.28,hit_flash*0.8))
    var skin := Color("#efbd94")
    var outline := Color("#18212d")
    var suit := body_color
    draw_circle(Vector2(0,48),19.0,Color(0.0,0.0,0.0,0.22))
    var left_foot := Vector2(-11.0 + stride,43.0)
    var right_foot := Vector2(11.0 - stride,43.0)
    draw_line(Vector2(-7,13+bob),left_foot,outline,12.0,true)
    draw_line(Vector2(7,13+bob),right_foot,outline,12.0,true)
    draw_line(left_foot+Vector2(-5,2),left_foot+Vector2(8,2),Color("#e8edf5"),8.0,true)
    draw_line(right_foot+Vector2(-5,2),right_foot+Vector2(8,2),Color("#e8edf5"),8.0,true)
    draw_colored_polygon(PackedVector2Array([Vector2(-15,-12),Vector2(-23,-8),Vector2(-23,12),Vector2(-14,18)]),Color("#273344"))
    draw_colored_polygon(PackedVector2Array([Vector2(-16,-17),Vector2(13,-17),Vector2(19,-7),Vector2(16,14),Vector2(10,23),Vector2(-11,23),Vector2(-18,12),Vector2(-19,-5)]),suit)
    draw_polyline(PackedVector2Array([Vector2(-16,-17),Vector2(-19,-5),Vector2(-18,12),Vector2(-11,23),Vector2(10,23),Vector2(16,14),Vector2(19,-7),Vector2(13,-17)]),outline,3.0,true)
    draw_colored_polygon(PackedVector2Array([Vector2(-8,-14),Vector2(7,-14),Vector2(5,12),Vector2(-4,15)]),suit.lightened(0.23))
    draw_line(Vector2(0,-10),Vector2(0,16),Color("#e8edf5",0.7),2.0,true)
    draw_rect(Rect2(-13,15,26,5),outline)
    draw_rect(Rect2(-8,17,16,2),Color("#d9ef70"))
    draw_rect(Rect2(-5,-25,10,12),skin)
    draw_circle(Vector2(0,-36-bob),15.0,skin)
    draw_arc(Vector2(0,-36-bob),15.0,PI,TAU,28,outline,3.0,true)
    draw_colored_polygon(PackedVector2Array([Vector2(-15,-39-bob),Vector2(-12,-50-bob),Vector2(-2,-54-bob),Vector2(10,-51-bob),Vector2(16,-41-bob),Vector2(9,-43-bob),Vector2(1,-46-bob),Vector2(-8,-42-bob)]),Color("#283247"))
    draw_circle(Vector2(facing*6,-36-bob),2.4,outline)
    draw_circle(Vector2(facing*7,-37-bob),0.9,Color.WHITE)
    draw_line(Vector2(facing,-27-bob),Vector2(facing*6,-27-bob),Color("#9b5e55"),1.7,true)
    var aim := aim_input.normalized()
    if aim == Vector2.ZERO:
        aim = Vector2(facing,0.0)
    var side := Vector2(-aim.y,aim.x)
    var shoulder := Vector2(facing*12,-10)
    var back_shoulder := Vector2(-facing*12,-8)
    draw_line(back_shoulder,back_shoulder+Vector2(-facing*8,14),Color("#263448"),10.0,true)
    draw_circle(back_shoulder+Vector2(-facing*8,14),5.0,skin)
    var hand := shoulder + aim*(25.0-recoil_kick*0.3)
    draw_line(shoulder,hand,Color("#263448"),13.0,true)
    draw_line(shoulder+Vector2(0,-2),hand+Vector2(0,-2),suit.lightened(0.2),4.0,true)
    draw_circle(hand,6.0,skin)
    var gun_origin := hand + aim*5.0
    var gun_back := gun_origin - aim*13.0
    var barrel_end := gun_origin + aim*37.0
    var casing := PackedVector2Array([gun_back+side*7.0,gun_origin+side*8.0,barrel_end-side*5.0,barrel_end+side*5.0,gun_origin-side*8.0,gun_back-side*7.0])
    draw_colored_polygon(casing,Color("#293647"))
    draw_polyline(PackedVector2Array([casing[0],casing[1],casing[2],casing[3],casing[4],casing[5],casing[0]]),outline,2.2,true)
    draw_colored_polygon(PackedVector2Array([gun_origin+side*5.0+aim*2.0,gun_origin+side*5.0+aim*23.0,gun_origin-side*5.0+aim*23.0,gun_origin-side*5.0+aim*2.0]),Color("#53657b"))
    draw_line(gun_origin+aim*25.0+side*3.0,barrel_end+side*3.0,Color("#aebed0"),3.0,true)
    draw_line(gun_origin+aim*25.0-side*3.0,barrel_end-side*3.0,Color("#aebed0"),3.0,true)
    draw_colored_polygon(PackedVector2Array([gun_origin+aim*5.0+side*4.0,gun_origin+aim*13.0+side*4.0,gun_origin+aim*13.0-side*4.0,gun_origin+aim*5.0-side*4.0]),Color("#d9ef70"))
    draw_line(gun_origin+aim*4.0+side*7.0,gun_origin+aim*4.0-side*7.0,Color("#dce8f5"),2.0,true)
    var grip_start := gun_origin-aim*3.0-side*5.0
    var grip_end := grip_start-aim*4.0-side*14.0
    draw_colored_polygon(PackedVector2Array([grip_start,grip_start+side*7.0,grip_end+side*5.0,grip_end]),Color("#202a38"))
    draw_line(grip_start,grip_end,Color("#65778d"),2.0,true)
    draw_circle(gun_origin+aim*13.0,3.0,Color("#eaf6ad"))
    if muzzle_flash > 0.0:
        var flash_center := barrel_end+aim*7.0
        draw_colored_polygon(PackedVector2Array([flash_center+aim*14.0,flash_center+side*5.0,flash_center-aim*3.0,flash_center-side*5.0]),Color("#f7ed9c",clampf(muzzle_flash/0.075,0.0,1.0)))
        draw_circle(flash_center,5.0,Color("#ffffff",clampf(muzzle_flash/0.075,0.0,1.0)))
    for i in range(magazine_size):
        var pip_color := Color("#d9ef70") if i < ammo else Color("#505b6c")
        draw_circle(Vector2(-14.0+float(i)*5.5,29.0),1.9,pip_color)
    if reload_visual > 0.0:
        draw_arc(Vector2(0,-36-bob),21.0,-PI/2.0,-PI/2.0+TAU*(1.0-reload_visual),32,Color("#d9ef70"),3.0,true)
