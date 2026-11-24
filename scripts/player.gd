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

# Lightweight ragdoll-style limb physics. Angles and angular velocity are
# simulated independently, while shoulder/hip anchors follow the torso.
var arm_back_angle := -0.38
var arm_front_angle := 1.0
var leg_back_angle := -0.12
var leg_front_angle := 0.12
var knee_back_angle := -0.28
var knee_front_angle := 0.28
var arm_back_angular_velocity := 0.0
var arm_front_angular_velocity := 0.0
var elbow_back_angle := -0.18
var elbow_front_angle := 0.55
var elbow_back_angular_velocity := 0.0
var elbow_front_angular_velocity := 0.0
var leg_back_angular_velocity := 0.0
var leg_front_angular_velocity := 0.0
var knee_back_angular_velocity := 0.0
var knee_front_angular_velocity := 0.0


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
    var previous_horizontal_velocity := velocity.x
    move_and_slide()
    var horizontal_acceleration := (velocity.x - previous_horizontal_velocity) / maxf(delta, 0.001)
    _step_limb_physics(delta, horizontal_acceleration)
    if is_on_wall() and not is_on_floor() and velocity.y > 160.0:
        velocity.y = minf(velocity.y, 270.0)
    queue_redraw()
func _step_limb_physics(delta: float, horizontal_acceleration: float) -> void:
    var grounded := is_on_floor()
    var moving := grounded and absf(move_input) > 0.05
    var gait := sin(animation_time) if moving else 0.0
    var local_aim := Vector2(aim_input.x * facing, aim_input.y).normalized()
    if local_aim.length_squared() < 0.01:
        local_aim = Vector2.RIGHT
    # The front arm follows the aim direction; the elbow keeps a small natural bend.
    var aim_angle := atan2(local_aim.x, local_aim.y)
    var arm_front_target := aim_angle * 0.68
    var elbow_front_target := aim_angle * 0.32
    var arm_back_target := -0.38 - gait * 0.34
    var elbow_back_target := -0.18 + gait * 0.18

    # Alternating hip and knee motion drives visible walking and landing poses.
    var leg_back_target := gait * 0.42 if grounded else -0.16
    var leg_front_target := -gait * 0.42 if grounded else 0.16
    var knee_back_target := maxf(0.0, gait) * 0.58 if moving else (0.22 if not grounded else -0.04)
    var knee_front_target := maxf(0.0, -gait) * 0.58 if moving else (0.22 if not grounded else -0.04)
    var accel_swing := clampf(horizontal_acceleration / 2400.0, -0.8, 0.8)

    var spring_k := 64.0
    var damping_rate := 15.0
    arm_back_angular_velocity += ((arm_back_target - arm_back_angle) * spring_k - arm_back_angular_velocity * damping_rate - accel_swing * 0.8) * delta
    arm_front_angular_velocity += ((arm_front_target - arm_front_angle) * spring_k - arm_front_angular_velocity * damping_rate) * delta
    elbow_back_angular_velocity += ((elbow_back_target - elbow_back_angle) * 70.0 - elbow_back_angular_velocity * 15.0) * delta
    elbow_front_angular_velocity += ((elbow_front_target - elbow_front_angle) * 70.0 - elbow_front_angular_velocity * 15.0) * delta
    leg_back_angular_velocity += ((leg_back_target - leg_back_angle) * spring_k - leg_back_angular_velocity * damping_rate + accel_swing * 0.65) * delta
    leg_front_angular_velocity += ((leg_front_target - leg_front_angle) * spring_k - leg_front_angular_velocity * damping_rate + accel_swing * 0.65) * delta
    knee_back_angular_velocity += ((knee_back_target - knee_back_angle) * 52.0 - knee_back_angular_velocity * 13.0) * delta
    knee_front_angular_velocity += ((knee_front_target - knee_front_angle) * 52.0 - knee_front_angular_velocity * 13.0) * delta

    arm_back_angle = clampf(arm_back_angle + arm_back_angular_velocity * delta, -1.25, 1.25)
    arm_front_angle = clampf(arm_front_angle + arm_front_angular_velocity * delta, -2.35, 2.35)
    elbow_back_angle = clampf(elbow_back_angle + elbow_back_angular_velocity * delta, -0.9, 0.9)
    elbow_front_angle = clampf(elbow_front_angle + elbow_front_angular_velocity * delta, -1.1, 1.1)
    leg_back_angle = clampf(leg_back_angle + leg_back_angular_velocity * delta, -0.72, 0.72)
    leg_front_angle = clampf(leg_front_angle + leg_front_angular_velocity * delta, -0.72, 0.72)
    knee_back_angle = clampf(knee_back_angle + knee_back_angular_velocity * delta, -0.12, 0.82)
    knee_front_angle = clampf(knee_front_angle + knee_front_angular_velocity * delta, -0.12, 0.82)


func _weapon_hand_local() -> Vector2:
    var shoulder := Vector2(12.0, -8.0)
    var elbow := shoulder + Vector2(sin(arm_front_angle) * 14.0, cos(arm_front_angle) * 14.0)
    var forearm_angle := arm_front_angle + elbow_front_angle
    return elbow + Vector2(sin(forearm_angle) * 13.0, cos(forearm_angle) * 13.0)


func apply_hit_impulse(direction: Vector2, force: float) -> void:
    var side := signf(direction.x)
    if side == 0.0:
        side = 1.0
    var kick := clampf(force / 780.0, 0.45, 1.8)
    arm_back_angular_velocity -= side * 3.8 * kick
    arm_front_angular_velocity -= side * 4.6 * kick
    leg_back_angular_velocity -= side * 2.2 * kick
    leg_front_angular_velocity -= side * 2.8 * kick
    hitstun_timer = maxf(hitstun_timer, 0.16)


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

    # Spawn from the hand-held blaster muzzle, not from the fighter's chest.
    var hand_world_offset := Vector2(_weapon_hand_local().x * facing, _weapon_hand_local().y)
    var muzzle := hand_world_offset + direction * (26.0 + float(weapon_level) * 3.0)
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
    var bob := absf(stride) * 1.4 if moving else sin(animation_time * 2.0) * 0.45
    var center := Vector2(0.0, -8.0 + bob)
    var outline := Color("#142333")
    var dark := body_color.darkened(0.22)
    var light := body_color.lightened(0.12)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

    # Far-side limbs are drawn first so they emerge naturally from behind the torso.
    var hip_back := Vector2(-6.5, 8.0)
    var hip_front := Vector2(6.5, 8.0)
    var leg_len := 17.0
    var knee_back := hip_back + Vector2(sin(leg_back_angle) * leg_len, cos(leg_back_angle) * leg_len)
    var knee_front := hip_front + Vector2(sin(leg_front_angle) * leg_len, cos(leg_front_angle) * leg_len)
    var foot_back_angle := leg_back_angle + knee_back_angle
    var foot_front_angle := leg_front_angle + knee_front_angle
    var foot_back := knee_back + Vector2(sin(foot_back_angle) * leg_len, cos(foot_back_angle) * leg_len)
    var foot_front := knee_front + Vector2(sin(foot_front_angle) * leg_len, cos(foot_front_angle) * leg_len)
    draw_line(hip_back, knee_back, outline, 8.0, true)
    draw_line(hip_back, knee_back, dark, 4.8, true)
    draw_line(knee_back, foot_back, outline, 7.5, true)
    draw_line(knee_back, foot_back, dark, 4.6, true)
    draw_line(foot_back + Vector2(-5,0), foot_back + Vector2(7,0), outline, 7.0, true)
    draw_line(foot_back + Vector2(-4,0), foot_back + Vector2(6,0), dark, 4.0, true)

    var shoulder_back := Vector2(-12.0, -8.0)
    var shoulder_front := Vector2(12.0, -8.0)
    var upper_arm_len := 14.0
    var forearm_len := 13.0
    var elbow_back := shoulder_back + Vector2(sin(arm_back_angle) * upper_arm_len, cos(arm_back_angle) * upper_arm_len)
    var elbow_front := shoulder_front + Vector2(sin(arm_front_angle) * upper_arm_len, cos(arm_front_angle) * upper_arm_len)
    var wrist_back_angle := arm_back_angle + elbow_back_angle
    var wrist_front_angle := arm_front_angle + elbow_front_angle
    var hand_back := elbow_back + Vector2(sin(wrist_back_angle) * forearm_len, cos(wrist_back_angle) * forearm_len)
    var hand_front := _weapon_hand_local()
    draw_line(shoulder_back, elbow_back, outline, 8.0, true)
    draw_line(shoulder_back, elbow_back, dark, 5.0, true)
    draw_line(elbow_back, hand_back, outline, 7.5, true)
    draw_line(elbow_back, hand_back, dark, 4.7, true)
    draw_circle(hand_back, 4.0, dark)

    # Compact rounded torso leaves the hips and shoulders readable.
    draw_circle(center, 24.0, Color(body_color, 0.08))
    draw_circle(center, 20.0, outline)
    draw_circle(center, 17.5, body_color)
    draw_arc(center, 17.2, 0.0, TAU, 48, light, 1.5, true)
    draw_circle(center + Vector2(-4.5,-6.0), 5.5, Color(1,1,1,0.12))
    draw_circle(center + Vector2(-5.5,-2.0), 1.8, Color("#102536"))
    draw_circle(center + Vector2(5.5,-2.0), 1.8, Color("#102536"))
    draw_line(center + Vector2(-2.5,5.0), center + Vector2(2.5,5.0), Color("#102536"), 1.5, true)

    # Near-side leg is in front of the torso, with a visible knee and foot.
    draw_line(hip_front, knee_front, outline, 8.0, true)
    draw_line(hip_front, knee_front, light, 4.8, true)
    draw_circle(knee_front, 3.8, body_color.lightened(0.05))
    draw_line(knee_front, foot_front, outline, 7.5, true)
    draw_line(knee_front, foot_front, body_color, 4.6, true)
    draw_line(foot_front + Vector2(-5,0), foot_front + Vector2(8,0), outline, 7.0, true)
    draw_line(foot_front + Vector2(-4,0), foot_front + Vector2(7,0), light, 4.0, true)
    draw_circle(hip_front, 4.0, light)

    # Near-side arm stays visibly separated from the body and bends at the elbow.
    draw_line(shoulder_front, elbow_front, outline, 8.0, true)
    draw_line(shoulder_front, elbow_front, light, 5.0, true)
    draw_circle(elbow_front, 4.2, light)
    draw_line(elbow_front, hand_front, outline, 7.5, true)
    draw_line(elbow_front, hand_front, body_color, 4.7, true)
    draw_circle(hand_front, 4.0, light)
    draw_circle(shoulder_front, 4.0, light)

    if kiwi_aura:
        for leaf_index in range(4):
            var leaf_angle := animation_time * 0.35 + TAU * float(leaf_index) / 4.0
            var leaf_center := center + Vector2(cos(leaf_angle),sin(leaf_angle)) * 30.0
            draw_set_transform(leaf_center,leaf_angle,Vector2.ONE)
            draw_colored_polygon(PackedVector2Array([Vector2(0,-5),Vector2(5,0),Vector2(0,8),Vector2(-5,0)]),Color("#8fc65e",0.9))
        draw_set_transform(Vector2.ZERO,0.0,Vector2(facing,1.0))

    if skin_style == "kiwi":
        var hair := Color("#d8d0c3")
        var hair_light := Color("#eee8dc")
        var hair_shadow := Color("#aaa397")
        var shirt := Color("#f4f0e8")
        var green := Color("#477b4c")
        var green_dark := Color("#294c38")
        var tie := Color("#e5bd48")
        draw_colored_polygon(PackedVector2Array([center+Vector2(-15,7),center+Vector2(15,7),center+Vector2(18,22),center+Vector2(-18,22)]),green_dark)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-13,7),center+Vector2(13,7),center+Vector2(15,19),center+Vector2(-15,19)]),shirt)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-15,7),center+Vector2(-4,12),center+Vector2(0,18),center+Vector2(4,12),center+Vector2(15,7),center+Vector2(12,16),center+Vector2(0,22),center+Vector2(-12,16)]),green)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-2.5,9),center+Vector2(2.5,9),center+Vector2(4,19),center+Vector2(0,22),center+Vector2(-4,19)]),tie)
        draw_circle(center+Vector2(-18,-19),8.0,hair_shadow)
        draw_circle(center+Vector2(-18,-20),6.0,hair)
        draw_circle(center+Vector2(18,-19),8.0,hair_shadow)
        draw_circle(center+Vector2(18,-20),6.0,hair)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-20,-11),center+Vector2(-19,-27),center+Vector2(-11,-35),center+Vector2(0,-38),center+Vector2(13,-33),center+Vector2(20,-20),center+Vector2(16,-11),center+Vector2(7,-21),center+Vector2(0,-17),center+Vector2(-7,-22),center+Vector2(-16,-12)]),hair)
        draw_colored_polygon(PackedVector2Array([center+Vector2(-18,-15),center+Vector2(-12,-27),center+Vector2(-4,-32),center+Vector2(-6,-19),center+Vector2(-12,-11)]),hair_light)
        draw_colored_polygon(PackedVector2Array([center+Vector2(3,-33),center+Vector2(12,-31),center+Vector2(19,-20),center+Vector2(11,-23),center+Vector2(5,-19)]),hair_shadow)
        draw_line(center+Vector2(-17,-15),center+Vector2(-15,4),hair_shadow,4.0,true)
        draw_line(center+Vector2(17,-16),center+Vector2(15,4),hair_shadow,4.0,true)
        draw_line(center+Vector2(-1,-36),center+Vector2(4,-44),hair_light,2.8,true)
        draw_circle(center+Vector2(-6,-3),2.5,Color("#792f48"))
        draw_circle(center+Vector2(6,-3),2.5,Color("#792f48"))
        draw_circle(center+Vector2(11,4),1.4,Color("#3b2930"))
        draw_circle(center+Vector2(-9,6),2.4,Color("#d88c91",0.62))
        draw_circle(center+Vector2(9,6),2.4,Color("#d88c91",0.62))

    if hit_flash > 0.0:
        draw_circle(center, 23.0, Color(1.0,0.45,0.34,hit_flash*0.24))
        draw_arc(center, 23.0, 0.0, TAU, 48, Color(1.0,0.82,0.72,hit_flash*0.8), 2.0, true)
    if reload_visual > 0.0:
        draw_arc(center, 26.0, -PI/2.0, -PI/2.0+TAU*(1.0-reload_visual), 32, Color.WHITE, 2.2, true)

    # The blaster is anchored to the front hand instead of floating at the torso.
    var local_aim := Vector2(aim_input.x * facing, aim_input.y).normalized()
    if local_aim.length_squared() < 0.01:
        local_aim = Vector2.RIGHT
    var gun_origin := hand_front + local_aim * 1.5
    draw_set_transform(gun_origin, local_aim.angle(), Vector2.ONE)
    var metal := Color("#202c3b")
    var metal_light := Color("#53677d")
    var trim := body_color.lightened(0.42)
    var barrel_len := 23.0 + float(weapon_level) * 3.0
    # A compact sidearm silhouette: slide, muzzle, trigger guard and angled grip.
    var pistol := PackedVector2Array([
        Vector2(-8,-5), Vector2(barrel_len-4,-5), Vector2(barrel_len+2,-3),
        Vector2(barrel_len+2,2), Vector2(5,2), Vector2(2,5),
        Vector2(0,12), Vector2(-7,10), Vector2(-4,3),
        Vector2(-9,1), Vector2(-9,-3)
    ])
    draw_colored_polygon(pistol,outline)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-6,-3),Vector2(barrel_len-4,-3),Vector2(barrel_len-1,0),
        Vector2(3,0),Vector2(1,2),Vector2(-6,1)
    ]),metal)
    draw_line(Vector2(-3,-2),Vector2(barrel_len-5,-2),trim,1.8,true)
    draw_rect(Rect2(barrel_len-1,-1.8,3.0,3.6),Color("#101820"))
    draw_line(Vector2(-4,4),Vector2(-5,8),metal_light,1.4,true)
    draw_line(Vector2(-7,5),Vector2(-3,5),metal_light,1.2,true)
    # Trigger guard and trigger are separate so the grip reads as a pistol.
    draw_arc(Vector2(-1,4),4.0,0.0,PI*0.92,16,outline,2.0,true)
    draw_line(Vector2(-1,3),Vector2(1,6),metal_light,1.2,true)
    draw_rect(Rect2(-3,-7,6,2),metal_light)
    draw_circle(Vector2(1,-6),1.1,trim)
    if weapon_level >= 1:
        draw_rect(Rect2(5,-8,barrel_len-7,2),trim)
        draw_circle(Vector2(barrel_len-1,0),3.0,Color(trim,0.5))
    if weapon_level >= 2:
        draw_line(Vector2(4,7),Vector2(barrel_len-5,7),Color("#d8e6f0"),1.6,true)
    if weapon_level >= 3:
        draw_arc(Vector2(8,0),12.0,-PI*0.72,PI*0.72,24,trim,2.0,true)
    if muzzle_flash > 0.0:
        var flash_size := 7.0 + muzzle_flash * 80.0
        draw_colored_polygon(PackedVector2Array([Vector2(barrel_len+1,0),Vector2(barrel_len+flash_size,-flash_size*0.4),Vector2(barrel_len+flash_size*0.55,0),Vector2(barrel_len+flash_size,flash_size*0.4)]),Color("#fff0a8",0.9))
    # Draw the gripping hand last so the fingers visibly wrap around the pistol grip.
    draw_circle(Vector2(-1.0, 1.5), 4.6, outline)
    draw_circle(Vector2(-1.0, 1.5), 3.3, light)
    draw_line(Vector2(-3.0, 1.0), Vector2(1.5, 2.0), dark, 1.2, true)
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
