extends CharacterBody2D
class_name ArenaPlayer

signal pulse_requested(origin: Vector2, direction: Vector2, force: float, tint: Color, shooter: Node2D)
signal got_hit(direction: Vector2, hit_target: Node2D)
signal reload_started

@export var is_bot := false
@export var body_color := Color("#39d6c5")

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
var ground_accel_scale := 1.0
var wall_jump_scale := 1.0

# Lightweight articulated ragdoll: every limb segment has its own angular inertia.
var ragdoll_angles := {
    "arm_l": -0.95, "forearm_l": -0.72,
    "arm_r": 0.95, "forearm_r": 0.72,
    "leg_l": -0.12, "shin_l": -0.08,
    "leg_r": 0.12, "shin_r": 0.08
}
var ragdoll_speeds := {
    "arm_l": 0.0, "forearm_l": 0.0,
    "arm_r": 0.0, "forearm_r": 0.0,
    "leg_l": 0.0, "shin_l": 0.0,
    "leg_r": 0.0, "shin_r": 0.0
}

func _ready() -> void:
    collision_layer = 1
    collision_mask = 3
    var shape := CollisionShape2D.new()
    floor_snap_length = 8.0
    safe_margin = 0.08
    var capsule := CapsuleShape2D.new()
    capsule.radius = 20.0
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
    _update_ragdoll(delta)
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
    var predicted_target: Vector2 = target.global_position + target.velocity * minf(travel_time,0.32)
    var aim_vector: Vector2 = (predicted_target - global_position).normalized()
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

func _update_ragdoll(delta: float) -> void:
    var grounded := is_on_floor()
    var run_cycle := sin(animation_time) if absf(velocity.x) > 35.0 and grounded else 0.0
    var air := 0.0 if grounded else clampf(absf(velocity.y) / 850.0, 0.0, 1.0)
    var local_aim := Vector2(aim_input.x * facing, aim_input.y).normalized()
    if local_aim.length() < 0.1:
        local_aim = Vector2.RIGHT
    var weapon_angle := PI * 0.5 - local_aim.angle()
    var targets := {
        "arm_l": -0.92 - run_cycle * 0.28 - air * 0.55,
        "forearm_l": -0.62 - run_cycle * 0.18 - air * 0.35,
        "arm_r": lerpf(0.88, weapon_angle, 0.82) + air * 0.48,
        "forearm_r": lerpf(0.62, weapon_angle + 0.18, 0.86) + air * 0.32,
        "leg_l": -0.10 + run_cycle * 0.58 + air * -0.22,
        "shin_l": -0.05 + maxf(0.0, run_cycle) * 0.48 + air * 0.72,
        "leg_r": 0.10 - run_cycle * 0.58 + air * 0.22,
        "shin_r": 0.05 + maxf(0.0, -run_cycle) * 0.48 - air * 0.72
    }
    targets["arm_r"] = float(targets["arm_r"]) - recoil_kick * 0.035
    targets["forearm_r"] = float(targets["forearm_r"]) - recoil_kick * 0.055
    for key in ragdoll_angles.keys():
        var angle_now: float = ragdoll_angles[key]
        var speed_now: float = ragdoll_speeds[key]
        var target_angle: float = float(targets[key])
        var stiffness := 17.0 if key.begins_with("shin") or key.begins_with("forearm") else 12.0
        var damping := 5.2
        var gravity_torque := -sin(angle_now) * (2.2 + air * 1.5)
        var acceleration := (target_angle - angle_now) * stiffness + gravity_torque - speed_now * damping
        speed_now += acceleration * delta
        angle_now += speed_now * delta
        ragdoll_speeds[key] = speed_now
        ragdoll_angles[key] = angle_now

func _limb_vector(angle: float, length: float) -> Vector2:
    return Vector2(sin(angle), cos(angle)) * length

func _draw_limb(from_point: Vector2, to_point: Vector2, width: float, fill: Color, outline: Color) -> void:
    draw_line(from_point, to_point, outline, width + 4.0, true)
    draw_line(from_point, to_point, fill, width, true)
    draw_circle(from_point, width * 0.53, outline)
    draw_circle(from_point, width * 0.34, fill)
    draw_circle(to_point, width * 0.48, outline)
    draw_circle(to_point, width * 0.30, fill)

func _draw() -> void:
    var bob := absf(sin(animation_time * 2.0)) * 1.8 if absf(velocity.x) > 35.0 and is_on_floor() else 0.0
    var body_center := Vector2(0.0, -8.0 + bob)
    var outline := Color("#252833")
    var cream := Color("#f2e7d0")
    var skin := Color("#f4d9c5")
    var accent := body_color
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

    # Two independently swinging legs with loose knees and rounded shoes.
    var hip_l := Vector2(-9.0, 12.0 + bob)
    var hip_r := Vector2(9.0, 12.0 + bob)
    var knee_l := hip_l + _limb_vector(ragdoll_angles["leg_l"], 15.0)
    var knee_r := hip_r + _limb_vector(ragdoll_angles["leg_r"], 15.0)
    var foot_l := knee_l + _limb_vector(ragdoll_angles["leg_l"] + ragdoll_angles["shin_l"], 15.0)
    var foot_r := knee_r + _limb_vector(ragdoll_angles["leg_r"] + ragdoll_angles["shin_r"], 15.0)
    _draw_limb(hip_l, knee_l, 7.0, cream, outline)
    _draw_limb(knee_l, foot_l, 6.5, cream, outline)
    _draw_limb(hip_r, knee_r, 7.0, cream, outline)
    _draw_limb(knee_r, foot_r, 6.5, cream, outline)
    draw_line(foot_l + Vector2(-4.5, 1.0), foot_l + Vector2(5.5, 1.0), outline, 8.0, true)
    draw_line(foot_r + Vector2(-4.5, 1.0), foot_r + Vector2(5.5, 1.0), outline, 8.0, true)
    draw_line(foot_l + Vector2(-4.0, 0.0), foot_l + Vector2(4.0, 0.0), accent, 3.0, true)
    draw_line(foot_r + Vector2(-4.0, 0.0), foot_r + Vector2(4.0, 0.0), accent, 3.0, true)

    # Arms articulate at shoulders and elbows; recoil and aim move the weapon arm.
    var shoulder_l := Vector2(-17.0, -5.0 + bob)
    var shoulder_r := Vector2(17.0, -5.0 + bob)
    var elbow_l := shoulder_l + _limb_vector(ragdoll_angles["arm_l"], 14.0)
    var elbow_r := shoulder_r + _limb_vector(ragdoll_angles["arm_r"], 14.0)
    var hand_l := elbow_l + _limb_vector(ragdoll_angles["arm_l"] + ragdoll_angles["forearm_l"], 13.0)
    var hand_r := elbow_r + _limb_vector(ragdoll_angles["arm_r"] + ragdoll_angles["forearm_r"], 13.0)
    _draw_limb(shoulder_l, elbow_l, 6.5, cream, outline)
    _draw_limb(elbow_l, hand_l, 5.5, cream, outline)
    _draw_limb(shoulder_r, elbow_r, 6.5, cream, outline)
    _draw_limb(elbow_r, hand_r, 5.5, cream, outline)
    draw_circle(hand_l, 4.2, skin)
    draw_circle(hand_r, 4.2, skin)

    # ROUNDS-like compact ball fighter: one clean round silhouette.
    draw_circle(body_center, 28.0, outline)
    draw_circle(body_center, 24.5, cream)
    draw_arc(body_center + Vector2(0.0, 1.0), 22.0, 0.12, PI - 0.12, 32, Color("#d4c8ae"), 1.8, true)
    draw_circle(Vector2(-8.5, -9.0 + bob), 2.7, outline)
    draw_circle(Vector2(8.5, -9.0 + bob), 2.7, outline)
    draw_circle(Vector2(-7.7, -9.8 + bob), 0.85, Color.WHITE)
    draw_circle(Vector2(9.3, -9.8 + bob), 0.85, Color.WHITE)
    draw_arc(Vector2(0.0, -1.0 + bob), 4.8, 0.18, PI - 0.18, 16, Color("#9a655d"), 1.7, true)
    draw_circle(Vector2(-17.0, 1.0 + bob), 3.0, Color("#eaa59c", 0.52))
    draw_circle(Vector2(17.0, 1.0 + bob), 3.0, Color("#eaa59c", 0.52))

    # Kiwi's cream fringe and tiny green leaf.
    draw_colored_polygon(PackedVector2Array([
        Vector2(-23.0, -16.0 + bob), Vector2(-20.0, -28.0 + bob),
        Vector2(-8.0, -35.0 + bob), Vector2(7.0, -33.0 + bob),
        Vector2(21.0, -24.0 + bob), Vector2(24.0, -12.0 + bob),
        Vector2(13.0, -17.0 + bob), Vector2(2.0, -20.0 + bob),
        Vector2(-9.0, -17.0 + bob)
    ]), cream)
    draw_polyline(PackedVector2Array([
        Vector2(-23.0, -16.0 + bob), Vector2(-20.0, -28.0 + bob),
        Vector2(-8.0, -35.0 + bob), Vector2(7.0, -33.0 + bob),
        Vector2(21.0, -24.0 + bob), Vector2(24.0, -12.0 + bob)
    ]), outline, 2.2, true)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-4.0, -33.0 + bob), Vector2(4.0, -43.0 + bob),
        Vector2(17.0, -40.0 + bob), Vector2(9.0, -31.0 + bob),
        Vector2(2.0, -27.0 + bob)
    ]), accent)
    draw_line(Vector2(-14.0, 17.0 + bob), Vector2(14.0, 17.0 + bob), accent, 3.0, true)

    if muzzle_flash > 0.0:
        draw_circle(hand_r + _limb_vector(ragdoll_angles["arm_r"] + ragdoll_angles["forearm_r"], 5.0), 5.0, Color("#fff0a8", muzzle_flash / 0.075))
    if hit_flash > 0.0:
        draw_circle(body_center, 31.0, Color(1.0, 0.35, 0.28, hit_flash * 0.35))
    if reload_visual > 0.0:
        draw_arc(body_center, 32.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - reload_visual), 32, accent, 3.0, true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
