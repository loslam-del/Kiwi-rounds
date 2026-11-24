extends CharacterBody2D
class_name ArenaPlayer

signal pulse_requested(origin: Vector2, direction: Vector2, force: float, tint: Color, shooter: Node2D)
signal got_hit(direction: Vector2, hit_target: Node2D)
signal reload_started

@export var is_bot := false
@export var body_color := Color("#39d6c5")
@export var skin_style := "default"

const GRAVITY := 1420.0
const JUMP_SPEED := -715.0
const BASE_SPEED := 430.0
const GROUND_ACCEL := 2850.0
const AIR_ACCEL := 1450.0
const GROUND_FRICTION := 2350.0
const AIR_DRAG := 55.0
const MAX_FALL_SPEED := 1380.0
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
var hitstun_timer := 0.0
var bot_jump_hold_timer := 0.0
var air_jumps_left := 1
var extra_air_jumps := 0
var gravity_scale := 1.0
var air_control_scale := 1.0
var homing_strength := 0.0
var ricochet_count := 0
var projectile_speed := 1050.0
var weapon_level := 0
var ground_accel_scale := 1.0
var wall_jump_scale := 1.0
var kiwi_aura := false


func _ready() -> void:
    collision_layer = 1
    collision_mask = 3
    var shape := CollisionShape2D.new()
    floor_snap_length = 8.0
    safe_margin = 0.08
    var core := CircleShape2D.new()
    core.radius = 21.0
    shape.shape = core
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

func clear_touch_controls() -> void:
    move_stick = Vector2.ZERO
    move_input = 0.0
    touch_jump = false
    touch_fire = false
    jump_held = false
    fire_held = false
    jump_buffer_timer = 0.0
    jump_hold_timer = 0.0

func _physics_process(delta: float) -> void:
    animation_time += delta * (8.5 if absf(velocity.x) > 35.0 and is_on_floor() else 2.2)
    pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
    recoil_kick = move_toward(recoil_kick, 0.0, delta * 38.0)
    muzzle_flash = maxf(0.0, muzzle_flash - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    hitstun_timer = maxf(0.0,hitstun_timer-delta)
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
        air_jumps_left = 1 + extra_air_jumps
    else:
        coyote_timer = maxf(0.0, coyote_timer - delta)
    var jump_released := jump_was_held and not jump_held
    if jump_held and not jump_was_held:
        jump_buffer_timer = JUMP_BUFFER_TIME
    else:
        jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
    jump_was_held = jump_held
    wall_jump_lock = maxf(0.0, wall_jump_lock - delta)
    var accel: float = GROUND_ACCEL * ground_accel_scale if is_on_floor() else AIR_ACCEL * air_control_scale
    if wall_jump_lock > 0.0:
        accel *= 0.18
    if hitstun_timer > 0.0:
        accel *= 0.16
    if absf(move_input) > 0.01:
        velocity.x = move_toward(velocity.x, move_input * move_speed, accel * delta)
    elif is_on_floor():
        velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, AIR_DRAG * delta)
    velocity.y = minf(velocity.y + GRAVITY * gravity_scale * delta, MAX_FALL_SPEED * gravity_scale)
    if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
        velocity.y = jump_speed
        coyote_timer = 0.0
        jump_buffer_timer = 0.0
        jump_hold_timer = 0.16
    elif jump_buffer_timer > 0.0 and is_on_wall() and not is_on_floor():
        var wall_normal := get_wall_normal()
        velocity.x = wall_normal.x * WALL_JUMP_X * wall_jump_scale
        velocity.y = WALL_JUMP_Y * wall_jump_scale
        facing = signf(wall_normal.x)
        jump_buffer_timer = 0.0
        coyote_timer = 0.0
        wall_jump_lock = 0.16
        jump_hold_timer = 0.12
    elif jump_buffer_timer > 0.0 and air_jumps_left > 0 and not is_on_floor():
        velocity.y = jump_speed * 0.86
        air_jumps_left -= 1
        jump_buffer_timer = 0.0
        jump_hold_timer = 0.13
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
    var travel_time := direct_vector.length() / maxf(projectile_speed, 1.0)
    var predicted_target: Vector2 = target.global_position + target.velocity * minf(travel_time,0.32)
    var aim_vector: Vector2 = (predicted_target - global_position).normalized()
    set_aim(aim_vector)
    bot_jump_hold_timer = maxf(0.0,bot_jump_hold_timer-delta)
    if is_on_floor() and bot_jump_hold_timer <= 0.0 and (target.global_position.y < global_position.y - 70.0 or (distance_x < 100.0 and randf() < 0.018)):
        bot_jump_hold_timer = 0.23
    jump_held = bot_jump_hold_timer > 0.0

    bot_think -= delta
    if ammo <= 0 and reload_timer <= 0.0:
        start_reload()
    if bot_think <= 0.0:
        bot_think = 0.18
        if ammo > 0 and reload_timer <= 0.0 and aim_vector.length() > 0.0 and randf() < bot_accuracy:
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
            move_speed *= 1.18
            jump_speed *= 0.94
        "spring":
            jump_speed *= 1.18
            move_speed *= 0.93
        "feather":
            gravity_scale *= 0.82
            air_control_scale *= 1.08
        "wall":
            wall_jump_scale *= 1.22
            air_control_scale *= 1.10
        "air":
            extra_air_jumps += 1
            air_jumps_left += 1
            move_speed *= 0.95
        "grounded":
            ground_accel_scale *= 1.22
            gravity_scale *= 0.92
        "homing":
            homing_strength = minf(homing_strength + 4.2, 8.0)
            projectile_speed *= 0.90
            weapon_level += 1
        "ricochet":
            ricochet_count += 2
            pulse_force *= 0.88
            weapon_level += 1
        "heavy":
            pulse_force *= 1.24
            pulse_interval *= 1.15
            weapon_level += 2
        "rapid":
            pulse_interval *= 0.78
            pulse_force *= 0.91
            weapon_level += 1
        "magazine":
            magazine_size += 3
            ammo += 3
            reload_duration *= 1.12
            weapon_level += 1
        "piercing":
            projectile_speed *= 1.22
            pulse_force *= 1.08
            reload_duration *= 1.16
            weapon_level += 2
        "kiwi_charm":
            kiwi_aura = true

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
    hitstun_timer = 0.0
    bot_jump_hold_timer = 0.0
    air_jumps_left = 1 + extra_air_jumps

func _draw() -> void:
    var moving := is_on_floor() and absf(velocity.x) > 35.0
    var stride := sin(animation_time) if moving else 0.0
    var bob := absf(stride) * 2.0 if moving else sin(animation_time * 2.0) * 0.7
    var center := Vector2(0.0, -8.0 + bob)
    var outline := Color("#142333")
    var face := Color("#102536")
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

    # A single coherent fighter silhouette: limbs are decorative drawing only,
    # never separate physics bodies, so they cannot scatter across the arena.
    var back_leg := Vector2(-8.0, 12.0)
    var front_leg := Vector2(8.0, 12.0)
    var back_foot := back_leg + Vector2(stride * 5.0, 12.0 + absf(stride) * 1.5)
    var front_foot := front_leg + Vector2(-stride * 5.0, 12.0 + absf(stride) * 1.5)
    draw_line(back_leg, back_foot, outline, 10.0, true)
    draw_line(back_leg, back_foot, body_color.darkened(0.12), 6.5, true)
    draw_line(front_leg, front_foot, outline, 10.0, true)
    draw_line(front_leg, front_foot, body_color, 6.5, true)
    draw_line(back_foot + Vector2(-3,0), back_foot + Vector2(6,0), outline, 5.0, true)
    draw_line(front_foot + Vector2(-3,0), front_foot + Vector2(6,0), outline, 5.0, true)

    var arm_swing := stride * 4.0
    draw_line(Vector2(-15,-8), Vector2(-19-arm_swing,-1), outline, 9.0, true)
    draw_line(Vector2(-15,-8), Vector2(-19-arm_swing,-1), body_color.darkened(0.12), 5.5, true)
    draw_line(Vector2(14,-8), Vector2(19+arm_swing,-3), outline, 9.0, true)
    draw_line(Vector2(14,-8), Vector2(19+arm_swing,-3), body_color.lightened(0.08), 5.5, true)

    # Rounded armored body with a readable face and bright rim.
    draw_circle(center, 28.0, Color(body_color, 0.07))
    draw_circle(center, 23.0, outline)
    draw_circle(center, 20.0, body_color)
    draw_arc(center, 19.6, 0.0, TAU, 48, body_color.lightened(0.52), 1.8, true)
    draw_circle(center + Vector2(-5.0,-7.0), 7.0, Color(1.0,1.0,1.0,0.12))
    draw_circle(center + Vector2(-6.0,-2.0), 2.0, face)
    draw_circle(center + Vector2(6.0,-2.0), 2.0, face)
    draw_line(center + Vector2(-3.0,6.0), center + Vector2(3.0,6.0), face, 1.8, true)
    draw_arc(center + Vector2(0,2), 23.0, PI*0.12, PI*0.88, 28, Color(1,1,1,0.24), 1.3, true)

    if kiwi_aura:
        for leaf_index in range(4):
            var leaf_angle := animation_time * 0.35 + TAU * float(leaf_index) / 4.0
            var leaf_center := center + Vector2(cos(leaf_angle),sin(leaf_angle)) * 34.0
            draw_set_transform(leaf_center,leaf_angle,Vector2.ONE)
            draw_colored_polygon(PackedVector2Array([Vector2(0,-5),Vector2(5,0),Vector2(0,8),Vector2(-5,0)]),Color("#8fc65e",0.9))
        draw_set_transform(Vector2.ZERO,0.0,Vector2(facing,1.0))

    if skin_style == "kiwi":
        # Kiwi's school look: ash-blonde low twin buns, face-framing locks and uniform.
        var hair := Color("#d8d0c3")
        var hair_light := Color("#eee8dc")
        var hair_shadow := Color("#aaa397")
        var shirt := Color("#f4f0e8")
        var green := Color("#477b4c")
        var green_dark := Color("#294c38")
        var tie := Color("#e5bd48")
        # White shirt, green sailor collar and yellow necktie.
        draw_colored_polygon(PackedVector2Array([center+Vector2(-17,8),center+Vector2(17,8),center+Vector2(21,27),center+Vector2(-21,27)]),green_dark)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-15,7),center+Vector2(15,7),center+Vector2(17,22),center+Vector2(-17,22)]),shirt)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-17,7),center+Vector2(-4,13),center+Vector2(0,19),center+Vector2(4,13),center+Vector2(17,7),center+Vector2(13,18),center+Vector2(0,25),center+Vector2(-13,18)]),green)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-3,9),center+Vector2(3,9),center+Vector2(5,21),center+Vector2(0,25),center+Vector2(-5,21)]),tie)
        # Low twin buns behind the head.
        draw_circle(center+Vector2(-20,-21),9.0,hair_shadow)
        draw_circle(center+Vector2(-20,-22),7.0,hair)
        draw_circle(center+Vector2(20,-21),9.0,hair_shadow)
        draw_circle(center+Vector2(20,-22),7.0,hair)
        # Ash-blonde layered fringe, shoulder-length side locks and ahoge.
        draw_colored_polygon(PackedVector2Array([center+Vector2(-22,-12),center+Vector2(-21,-29),center+Vector2(-12,-39),center+Vector2(0,-42),center+Vector2(14,-36),center+Vector2(22,-22),center+Vector2(18,-12),center+Vector2(8,-23),center+Vector2(0,-18),center+Vector2(-8,-24),center+Vector2(-17,-13)]),hair)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-20,-16),center+Vector2(-14,-30),center+Vector2(-5,-35),center+Vector2(-7,-20),center+Vector2(-13,-12)]),hair_light)
        draw_colored_polygon(PackedVector2Array([center+Vector2(3,-36),center+Vector2(13,-34),center+Vector2(21,-21),center+Vector2(12,-25),center+Vector2(5,-20)]),hair_shadow)
        draw_line(center+Vector2(-19,-17),center+Vector2(-17,5),hair_shadow,5.0,true)
        draw_line(center+Vector2(18,-18),center+Vector2(17,4),hair_shadow,5.0,true)
        draw_line(center+Vector2(-1,-39),center+Vector2(4,-49),hair_light,3.0,true)
        # Wine-red eyes, a beauty mark and soft cheek color.
        draw_circle(center+Vector2(-7,-3),2.8,Color("#792f48"))
        draw_circle(center+Vector2(7,-3),2.8,Color("#792f48"))
        draw_circle(center+Vector2(13,5),1.6,Color("#3b2930"))
        draw_circle(center+Vector2(-10,7),2.8,Color("#d88c91",0.62))
        draw_circle(center+Vector2(10,7),2.8,Color("#d88c91",0.62))

    if hit_flash > 0.0:
        draw_circle(center, 26.0, Color(1.0,0.45,0.34,hit_flash*0.24))
        draw_arc(center, 26.0, 0.0, TAU, 48, Color(1.0,0.82,0.72,hit_flash*0.8), 2.2, true)
    if reload_visual > 0.0:
        draw_arc(center, 30.0, -PI/2.0, -PI/2.0+TAU*(1.0-reload_visual), 32, Color.WHITE, 2.4, true)

    var gun_aim := aim_input.normalized()
    if gun_aim == Vector2.ZERO:
        gun_aim = Vector2(facing,0.0)
    var gun_origin := Vector2(9.0 * facing, -8.0 + bob)
    draw_set_transform(gun_origin, gun_aim.angle(), Vector2.ONE)
    var metal := Color("#202c3b")
    var trim := body_color.lightened(0.42)
    var barrel_len := 25.0 + float(weapon_level) * 3.0
    draw_circle(Vector2(0,0), 14.0, Color(trim,0.12))
    draw_rect(Rect2(-7,-8,barrel_len+12,17), outline)
    draw_rect(Rect2(-5,-6,barrel_len+9,13), metal)
    draw_rect(Rect2(-2,-5,barrel_len+6,3), trim)
    draw_rect(Rect2(-7,5,11,13), outline)
    draw_rect(Rect2(-4,7,6,8), trim.darkened(0.16))
    draw_rect(Rect2(4,-10,9,3), Color("#91a5bb"))
    if weapon_level >= 1:
        draw_rect(Rect2(7,-12,barrel_len-2,3), trim)
        draw_circle(Vector2(barrel_len-2,0), 5.0, Color(trim,0.45))
    if weapon_level >= 2:
        draw_rect(Rect2(8,8,barrel_len-8,3), Color("#d8e6f0"))
        draw_circle(Vector2(2,-14), 3.5, Color("#ffe08a"))
    if weapon_level >= 3:
        draw_arc(Vector2(10,0), 19.0, -PI*0.75, PI*0.75, 24, trim, 2.8, true)
    if muzzle_flash > 0.0:
        var flash_size := 8.0 + muzzle_flash * 90.0
        draw_colored_polygon(PackedVector2Array([Vector2(barrel_len+2,0),Vector2(barrel_len+flash_size,-flash_size*0.42),Vector2(barrel_len+flash_size*0.55,0),Vector2(barrel_len+flash_size,flash_size*0.42)]),Color("#fff0a8",0.9))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
