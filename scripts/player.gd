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
var weapon_hand_blend := 1.0
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
var menu_preview_mode := false
var menu_spawn_position := Vector2.ZERO
var menu_respawn_timer := 0.0
var menu_jump_cooldown := 0.0
var menu_strafe_phase := 0.0
var menu_mascot := false
var remote_controlled := false
var remote_move := 0.0
var remote_aim := Vector2.RIGHT
var remote_jump := false
var remote_fire := false
var remote_reload := false
var max_health := 100
var health := 100


# Lightweight ragdoll-style limb physics. Angles and angular velocity are
# simulated independently, while shoulder/hip anchors follow the torso.
var arm_back_angle := -0.18
var arm_front_angle := 0.18
var leg_back_angle := -0.12
var leg_front_angle := 0.12
var knee_back_angle := -0.28
var knee_front_angle := 0.28
var arm_back_angular_velocity := 0.0
var arm_front_angular_velocity := 0.0
var elbow_back_angle := -0.72
var elbow_front_angle := 0.72
var elbow_back_angular_velocity := 0.0
var elbow_front_angular_velocity := 0.0
var leg_back_angular_velocity := 0.0
var leg_front_angular_velocity := 0.0
var knee_back_angular_velocity := 0.0
var knee_front_angular_velocity := 0.0
var ragdoll_timer := 0.0
var ragdoll_strength := 0.0
var torso_lean := 0.0
var torso_angular_velocity := 0.0
var ragdoll_spin := 0.0


func _ready() -> void:
    collision_layer = 1
    collision_mask = 3
    var shape := CollisionShape2D.new()
    floor_snap_length = 10.0
    safe_margin = 0.04
    # One stable full-height capsule keeps the visible legs at floor level.
    # The old torso-only circle let the drawn feet extend through platforms.
    var core := CapsuleShape2D.new()
    core.radius = 18.0
    core.height = 88.0
    shape.shape = core
    shape.position = Vector2(0.0, 8.0)
    add_child(shape)

func set_move(value: Vector2) -> void:
    move_stick = value

func _set_facing(value: float) -> void:
    var next_facing := signf(value)
    if next_facing == 0.0 or next_facing == facing:
        return
    weapon_hand_blend = 1.0
    facing = next_facing

func set_aim(value: Vector2) -> void:
    if value.length() > 0.16:
        aim_input = value.normalized()
        if absf(aim_input.x) > 0.12:
            _set_facing(aim_input.x)

func set_jump(value: bool) -> void:
    touch_jump = value

func set_fire(value: bool) -> void:
    touch_fire = value

func shoot_once() -> void:
    if not is_bot and not remote_controlled and is_physics_processing():
        _fire_pulse()

func take_damage(amount: int) -> void:
    health = maxi(0, health - maxi(amount, 0))

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
    if menu_preview_mode:
        if menu_respawn_timer > 0.0:
            menu_respawn_timer = maxf(0.0, menu_respawn_timer - delta)
            velocity = Vector2.ZERO
            if menu_respawn_timer <= 0.0:
                global_position = menu_spawn_position
                velocity = Vector2.ZERO
                health = max_health
                ammo = magazine_size
                reload_timer = 0.0
                reload_visual = 0.0
                pulse_cooldown = 0.55
                collision_layer = 1
                visible = true
            else:
                queue_redraw()
                return
        elif health <= 0 or global_position.y > 900.0:
            menu_respawn_timer = 0.85
            collision_layer = 0
            visible = false
            velocity = Vector2.ZERO
            queue_redraw()
            return
    # Walk-cycle phase follows distance travelled, not a fixed timer: faster movement
    # produces faster, grounded steps and stopping immediately settles the gait.
    if is_on_floor() and absf(velocity.x) > 18.0:
        animation_time += delta * (absf(velocity.x) / 22.0)
    else:
        animation_time += delta * 2.2
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
    if remote_controlled:
        move_input = remote_move
        aim_input = remote_aim
        jump_held = remote_jump
        fire_held = remote_fire
        if remote_reload:
            start_reload()
            remote_reload = false
    elif is_bot:
        _think_bot(delta)
    else:
        _read_keyboard()
    if absf(move_input) > 0.01 and wall_jump_lock <= 0.0:
        _set_facing(move_input)
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
        _set_facing(wall_normal.x)
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
    var moving := is_on_floor() and absf(velocity.x) > 35.0
    var walk_drive := clampf(velocity.x / maxf(move_speed, 1.0), -1.0, 1.0) if is_on_floor() else clampf(velocity.x / maxf(move_speed, 1.0), -0.22, 0.22)
    var jump_drive := clampf(-velocity.y / 900.0, -0.85, 0.85)
    var accel_swing := clampf(horizontal_acceleration / 2200.0, -1.1, 1.1)

    # Shoulder joints swing outward; elbows and knees have independent spring motion.
    var arm_back_target := -0.92 - walk_drive * 0.30 - jump_drive * 0.16
    var arm_front_target := 0.92 + walk_drive * 0.30 - jump_drive * 0.16
    var elbow_back_target := -0.78 + walk_drive * 0.16
    var elbow_front_target := 0.78 - walk_drive * 0.16
    # Real alternating gait: one leg reaches forward while the other pushes
    # backward. The recovering leg folds at the knee and lifts clear of the floor.
    var gait := sin(animation_time)
    var gait_cos := cos(animation_time)
    var stride_strength := absf(walk_drive)
    var leg_back_target := (gait * 0.92 * stride_strength if moving else -walk_drive * 0.10) + jump_drive * 0.22
    var leg_front_target := (-gait * 0.92 * stride_strength if moving else -walk_drive * 0.10) + jump_drive * 0.22
    var knee_back_target := (0.02 + maxf(0.0, gait_cos) * 0.95 if moving else -0.08) + absf(jump_drive) * 0.28
    var knee_front_target := (0.02 + maxf(0.0, -gait_cos) * 0.95 if moving else -0.08) + absf(jump_drive) * 0.28

    # Strong impacts temporarily release the limb springs into a loose ragdoll pose.
    ragdoll_timer = maxf(0.0, ragdoll_timer - delta)
    ragdoll_strength = move_toward(ragdoll_strength, 1.0 if ragdoll_timer > 0.0 else 0.0, delta * (2.8 if ragdoll_timer > 0.0 else 1.65))
    var ragdoll_drive := ragdoll_strength
    var fall_drive := clampf(velocity.y / 900.0, -0.5, 1.0)
    arm_back_target = lerpf(arm_back_target, -1.35 + fall_drive * 1.15 + ragdoll_spin * 0.35, ragdoll_drive)
    arm_front_target = lerpf(arm_front_target, 1.35 + fall_drive * 1.15 - ragdoll_spin * 0.35, ragdoll_drive)
    elbow_back_target = lerpf(elbow_back_target, -1.1 + fall_drive * 0.9, ragdoll_drive)
    elbow_front_target = lerpf(elbow_front_target, 1.1 + fall_drive * 0.9, ragdoll_drive)
    leg_back_target = lerpf(leg_back_target, -0.8 + fall_drive * 0.7 + ragdoll_spin * 0.28, ragdoll_drive)
    leg_front_target = lerpf(leg_front_target, 0.8 + fall_drive * 0.7 - ragdoll_spin * 0.28, ragdoll_drive)
    knee_back_target = lerpf(knee_back_target, 0.9, ragdoll_drive)
    knee_front_target = lerpf(knee_front_target, 0.9, ragdoll_drive)
    ragdoll_spin = move_toward(ragdoll_spin, 0.0, delta * 1.8)
    var spring_k := lerpf(58.0, 17.0, ragdoll_drive)
    var damping_rate := lerpf(13.5, 3.8, ragdoll_drive)
    arm_back_angular_velocity += ((arm_back_target - arm_back_angle) * spring_k - arm_back_angular_velocity * damping_rate - accel_swing * 1.0) * delta
    arm_front_angular_velocity += ((arm_front_target - arm_front_angle) * spring_k - arm_front_angular_velocity * damping_rate - accel_swing * 1.0) * delta
    elbow_back_angular_velocity += ((elbow_back_target - elbow_back_angle) * 72.0 - elbow_back_angular_velocity * 15.0) * delta
    elbow_front_angular_velocity += ((elbow_front_target - elbow_front_angle) * 72.0 - elbow_front_angular_velocity * 15.0) * delta
    leg_back_angular_velocity += ((leg_back_target - leg_back_angle) * spring_k - leg_back_angular_velocity * damping_rate + accel_swing * 0.8) * delta
    leg_front_angular_velocity += ((leg_front_target - leg_front_angle) * spring_k - leg_front_angular_velocity * damping_rate + accel_swing * 0.8) * delta
    knee_back_angular_velocity += ((knee_back_target - knee_back_angle) * 48.0 - knee_back_angular_velocity * 12.0) * delta
    knee_front_angular_velocity += ((knee_front_target - knee_front_angle) * 48.0 - knee_front_angular_velocity * 12.0) * delta

    arm_back_angle = clampf(arm_back_angle + arm_back_angular_velocity * delta, -1.65, 1.65)
    arm_front_angle = clampf(arm_front_angle + arm_front_angular_velocity * delta, -1.65, 1.65)
    elbow_back_angle = clampf(elbow_back_angle + elbow_back_angular_velocity * delta, -1.5, 1.5)
    elbow_front_angle = clampf(elbow_front_angle + elbow_front_angular_velocity * delta, -1.5, 1.5)
    leg_back_angle = clampf(leg_back_angle + leg_back_angular_velocity * delta, -1.15, 1.15)
    leg_front_angle = clampf(leg_front_angle + leg_front_angular_velocity * delta, -1.15, 1.15)
    knee_back_angle = clampf(knee_back_angle + knee_back_angular_velocity * delta, -0.25, 1.15)
    knee_front_angle = clampf(knee_front_angle + knee_front_angular_velocity * delta, -0.25, 1.15)


func _weapon_hand_local() -> Vector2:
    var local_aim := Vector2(aim_input.x * facing, aim_input.y).normalized()
    if local_aim.length_squared() < 0.01:
        local_aim = Vector2.RIGHT
    return Vector2(0.0, -8.0) + local_aim * 8.0


func apply_hit_impulse(direction: Vector2, force: float) -> void:
    var side := signf(direction.x)
    if side == 0.0:
        side = 1.0
    var kick := clampf(force / 780.0, 0.45, 1.8)
    arm_back_angular_velocity -= side * 3.8 * kick
    arm_front_angular_velocity -= side * 4.6 * kick
    leg_back_angular_velocity -= side * 2.2 * kick
    leg_front_angular_velocity -= side * 2.8 * kick
    hitstun_timer = maxf(hitstun_timer, 0.32)
    ragdoll_timer = maxf(ragdoll_timer, clampf(force / 780.0 * 0.48, 0.28, 0.9))
    ragdoll_spin += direction.x * clampf(force / 780.0, 0.55, 1.9) * 1.15
    torso_angular_velocity += -side * clampf(force / 780.0, 0.55, 1.9) * 2.8


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
        jump_held = false
        return

    var delta_x := target.global_position.x - global_position.x
    var distance_x := absf(delta_x)
    var direct_vector := target.global_position - global_position
    var travel_time := absf(direct_vector.x) / maxf(projectile_speed, 1.0)
    var predicted_target: Vector2 = target.global_position + target.velocity * minf(travel_time, 0.32)
    # Compensate for the projectile's gravity so shots lead moving targets.
    var gravity_compensation := Vector2(0.0, 525.0 * travel_time * travel_time)
    var aim_vector: Vector2 = (predicted_target - global_position - gravity_compensation).normalized()
    set_aim(aim_vector)

    if menu_preview_mode:
        # Menu fighters alternate between closing distance, retreating and strafing.
        # The phase offset makes the two bots behave independently rather than mirror-lock.
        menu_jump_cooldown = maxf(0.0, menu_jump_cooldown - delta)
        var strafe := sin(float(Time.get_ticks_msec()) * 0.00072 + menu_strafe_phase)
        if distance_x > 390.0:
            move_input = signf(delta_x)
        elif distance_x < 175.0:
            move_input = -signf(delta_x)
        else:
            move_input = strafe * 0.72

        # Occasional short hops keep the preview lively without constant bunny-hopping.
        if is_on_floor() and menu_jump_cooldown <= 0.0 and randf() < delta * 0.42:
            bot_jump_hold_timer = 0.16
            menu_jump_cooldown = randf_range(1.5, 2.8)
        else:
            bot_jump_hold_timer = maxf(0.0, bot_jump_hold_timer - delta)
        jump_held = bot_jump_hold_timer > 0.0
    else:
        if distance_x > 235.0:
            move_input = signf(delta_x)
        elif distance_x < 115.0:
            move_input = -signf(delta_x)
        else:
            move_input = 0.0
        bot_jump_hold_timer = maxf(0.0,bot_jump_hold_timer-delta)
        if is_on_floor() and bot_jump_hold_timer <= 0.0 and (target.global_position.y < global_position.y - 70.0 or (distance_x < 100.0 and randf() < 0.018)):
            bot_jump_hold_timer = 0.23
        jump_held = bot_jump_hold_timer > 0.0

    bot_think -= delta
    if ammo <= 0 and reload_timer <= 0.0:
        start_reload()
    if bot_think <= 0.0:
        bot_think = 0.18 if menu_preview_mode else 0.18
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
        _set_facing(direction.x)

    # Spawn from the hand-held blaster muzzle, not from the fighter's chest.
    var gun_anchor := _weapon_hand_local()
    var hand_world_offset := Vector2(gun_anchor.x * facing, gun_anchor.y)
    var muzzle := hand_world_offset + direction * 25.0
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
    weapon_hand_blend = 1.0
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
    health = max_health

func _draw() -> void:
    var moving := is_on_floor() and absf(velocity.x) > 35.0
    var stride := sin(animation_time) if moving else 0.0
    var bob := absf(stride) * 1.4 if moving else sin(animation_time * 2.0) * 0.45
    var center := Vector2(0.0, -8.0 + bob)
    var outline := Color("#142333")
    var dark := body_color.darkened(0.22)
    var light := body_color.lightened(0.12)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
    if skin_style == "kiwi":
        _draw_kiwi_ball()
        if not menu_mascot:
            _draw_two_hand_blaster(Vector2(0.0, -7.0))
        return

    # Far-side limbs are drawn first so they emerge naturally from behind the torso.
    var hip_back := Vector2(-6.5, 8.0)
    var hip_front := Vector2(6.5, 8.0)
    # Shorten the visible leg reach while grounded so shoes sit on top of
    # the capsule's floor contact instead of dipping through thin platforms.
    var leg_len := 22.5 if is_on_floor() else 27.0
    var knee_back := hip_back + Vector2(sin(leg_back_angle) * leg_len, cos(leg_back_angle) * leg_len)
    var knee_front := hip_front + Vector2(sin(leg_front_angle) * leg_len, cos(leg_front_angle) * leg_len)
    var foot_back_angle := leg_back_angle + knee_back_angle
    var foot_front_angle := leg_front_angle + knee_front_angle
    var foot_back := knee_back + Vector2(sin(foot_back_angle) * leg_len, cos(foot_back_angle) * leg_len)
    var foot_front := knee_front + Vector2(sin(foot_front_angle) * leg_len, cos(foot_front_angle) * leg_len)
    if is_on_floor():
        foot_back.y = minf(foot_back.y, 63.0)
        foot_front.y = minf(foot_front.y, 63.0)
    # Soft rounded upper legs, padded knees and chunky sneakers.
    draw_line(hip_back, knee_back, outline, 13.0, true)
    draw_line(hip_back, knee_back, dark, 9.0, true)
    draw_circle(knee_back, 5.8, outline)
    draw_circle(knee_back, 4.1, dark)
    draw_line(knee_back, foot_back, outline, 11.5, true)
    draw_line(knee_back, foot_back, dark, 7.8, true)
    draw_line(foot_back + Vector2(-7,0), foot_back + Vector2(9,0), outline, 9.5, true)
    draw_line(foot_back + Vector2(-6,-1), foot_back + Vector2(8,-1), dark, 6.0, true)

    var shoulder_back := Vector2(-12.0, -7.0)
    var shoulder_front := Vector2(12.0, -7.0)
    var elbow_back := shoulder_back
    var elbow_front := shoulder_front
    var hand_back := Vector2.ZERO
    var hand_front := Vector2.ZERO

    # Compact rounded torso leaves the hips and shoulders readable.
    draw_circle(center, 24.0, Color(body_color, 0.08))
    draw_circle(center, 20.0, outline)
    draw_circle(center, 17.5, body_color)
    draw_arc(center, 17.2, 0.0, TAU, 48, light, 1.5, true)
    if skin_style != "kiwi":
        draw_circle(center + Vector2(-4.5,-6.0), 5.5, Color(1,1,1,0.12))
        draw_circle(center + Vector2(-5.5,-2.0), 1.8, Color("#102536"))
        draw_circle(center + Vector2(5.5,-2.0), 1.8, Color("#102536"))
        draw_line(center + Vector2(-2.5,5.0), center + Vector2(2.5,5.0), Color("#102536"), 1.5, true)

    # Near-side leg is in front of the torso, with a visible knee and foot.
    draw_line(hip_front, knee_front, outline, 13.0, true)
    draw_line(hip_front, knee_front, light, 9.0, true)
    draw_circle(knee_front, 5.8, outline)
    draw_circle(knee_front, 4.1, body_color.lightened(0.05))
    draw_line(knee_front, foot_front, outline, 11.5, true)
    draw_line(knee_front, foot_front, body_color, 7.8, true)
    draw_line(foot_front + Vector2(-7,0), foot_front + Vector2(10,0), outline, 9.5, true)
    draw_line(foot_front + Vector2(-6,-1), foot_front + Vector2(9,-1), light, 6.0, true)
    draw_circle(hip_front, 5.0, light)

    if kiwi_aura:
        for leaf_index in range(4):
            var leaf_angle := animation_time * 0.35 + TAU * float(leaf_index) / 4.0
            var leaf_center := center + Vector2(cos(leaf_angle),sin(leaf_angle)) * 30.0
            draw_set_transform(leaf_center,leaf_angle,Vector2.ONE)
            draw_colored_polygon(PackedVector2Array([Vector2(0,-5),Vector2(5,0),Vector2(0,8),Vector2(-5,0)]),Color("#8fc65e",0.9))
        draw_set_transform(Vector2.ZERO,0.0,Vector2(facing,1.0))

    if skin_style == "kiwi_human":
        # Match Kiwi's original reference: mint-silver hair, pink-tinted ends,
        # and the dark green military cap with a red band and gold star.
        var hair := Color("#b9d9bd")
        var hair_light := Color("#e9f0d9")
        var hair_shadow := Color("#668d70")
        var hair_pink := Color("#d99ab7")
        var cap_dark := Color("#183c2c")
        var cap_green := Color("#315b3d")
        var cap_light := Color("#5d8150")
        var cap_red := Color("#8e4148")
        var gold := Color("#e6bd58")

        # Back hair and two soft side locks, kept close to the head silhouette.
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-17,-25), center+Vector2(-23,-15),
            center+Vector2(-22,5), center+Vector2(-18,22),
            center+Vector2(-12,27), center+Vector2(-10,10),
            center+Vector2(-12,-9)
        ]),hair_shadow)
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-16,-24), center+Vector2(-20,-14),
            center+Vector2(-19,5), center+Vector2(-16,19),
            center+Vector2(-12,22), center+Vector2(-12,7),
            center+Vector2(-13,-9)
        ]),hair)
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(16,-24), center+Vector2(22,-14),
            center+Vector2(21,5), center+Vector2(17,22),
            center+Vector2(11,27), center+Vector2(10,10),
            center+Vector2(12,-9)
        ]),hair_shadow)
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(15,-23), center+Vector2(19,-13),
            center+Vector2(18,5), center+Vector2(15,19),
            center+Vector2(11,22), center+Vector2(12,7),
            center+Vector2(13,-9)
        ]),hair)
        # Pink tips echo the colored ends visible in the original character art.
        draw_line(center+Vector2(-16,10),center+Vector2(-13,23),hair_pink,2.0,true)
        draw_line(center+Vector2(15,9),center+Vector2(12,23),hair_pink,2.0,true)

        # Rounded crown of hair peeks out below the cap.
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-18,-17), center+Vector2(-17,-29),
            center+Vector2(-10,-36), center+Vector2(0,-38),
            center+Vector2(11,-34), center+Vector2(18,-23),
            center+Vector2(17,-12), center+Vector2(11,-16),
            center+Vector2(5,-12), center+Vector2(0,-19),
            center+Vector2(-6,-12), center+Vector2(-12,-17)
        ]),hair_shadow)
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-16,-17), center+Vector2(-15,-28),
            center+Vector2(-9,-34), center+Vector2(0,-36),
            center+Vector2(10,-32), center+Vector2(15,-22),
            center+Vector2(15,-13), center+Vector2(10,-17),
            center+Vector2(5,-14), center+Vector2(0,-21),
            center+Vector2(-6,-14), center+Vector2(-11,-18)
        ]),hair)
        # Distinct layered fringe; individual locks frame the face instead of
        # forming a single flat helmet-shaped patch.
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-14,-25), center+Vector2(-8,-32),
            center+Vector2(-3,-31), center+Vector2(-7,-20),
            center+Vector2(-13,-15)
        ]),hair_light)
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-5,-32), center+Vector2(2,-34),
            center+Vector2(4,-25), center+Vector2(0,-17),
            center+Vector2(-4,-23)
        ]),hair_light)
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(5,-32), center+Vector2(11,-28),
            center+Vector2(14,-19), center+Vector2(8,-15),
            center+Vector2(4,-22)
        ]),hair)

        # Original-style peaked cap: domed crown, red lower band and short visor.
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-21,-29), center+Vector2(-18,-43),
            center+Vector2(-9,-51), center+Vector2(3,-53),
            center+Vector2(16,-47), center+Vector2(22,-34),
            center+Vector2(17,-28), center+Vector2(7,-31),
            center+Vector2(-7,-31)
        ]),cap_dark)
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(-17,-31), center+Vector2(-15,-42),
            center+Vector2(-7,-48), center+Vector2(3,-50),
            center+Vector2(13,-45), center+Vector2(18,-34),
            center+Vector2(12,-32), center+Vector2(4,-34),
            center+Vector2(-6,-34)
        ]),cap_green)
        draw_line(center+Vector2(-19,-31),center+Vector2(-8,-34),cap_light,1.8,true)
        draw_line(center+Vector2(-8,-34),center+Vector2(5,-34),cap_light,1.8,true)
        draw_line(center+Vector2(5,-34),center+Vector2(18,-31),cap_dark,1.8,true)
        # Red band and gold piping make the cap recognizable at game scale.
        draw_line(center+Vector2(-18,-29),center+Vector2(17,-29),cap_red,4.0,true)
        draw_line(center+Vector2(-17,-31),center+Vector2(16,-31),gold,1.1,true)
        # Five-point star badge, centered on the front of the cap.
        draw_colored_polygon(PackedVector2Array([
            center+Vector2(0,-47), center+Vector2(2.0,-42.5),
            center+Vector2(6.5,-42.2), center+Vector2(3.0,-39.2),
            center+Vector2(4.0,-34.8), center+Vector2(0,-37.2),
            center+Vector2(-4.0,-34.8), center+Vector2(-3.0,-39.2),
            center+Vector2(-6.5,-42.2), center+Vector2(-2.0,-42.5)
        ]),gold)
        draw_line(center+Vector2(-1,-46),center+Vector2(0,-39),Color("#fff0a8"),0.9,true)
    if hit_flash > 0.0:
        draw_circle(center, 23.0, Color(1.0,0.45,0.34,hit_flash*0.24))
        draw_arc(center, 23.0, 0.0, TAU, 48, Color(1.0,0.82,0.72,hit_flash*0.8), 2.0, true)
    if reload_visual > 0.0:
        # Keep the reload pip at screen-right even while the fighter turns.
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
        var reload_pip := center + Vector2(29.0, -39.0)
        draw_circle(reload_pip, 8.5, Color("#101a27", 0.92))
        draw_arc(reload_pip, 7.2, 0.0, TAU, 32, Color("#526174", 0.95), 2.2, true)
        var reload_progress := 1.0 - reload_visual
        draw_arc(reload_pip, 7.2, -PI/2.0, -PI/2.0 + TAU * reload_progress, 32, Color("#f2d66d"), 2.8, true)
        draw_circle(reload_pip, 2.0, Color("#f2d66d", 0.9))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))

    _draw_two_hand_blaster(center)




func _draw_kiwi_ball() -> void:
    # Kiwi stays a simple green ROUNDS ball: no human face or torso.
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
    var center := Vector2(0.0, -7.0)
    var outline := Color("#172333")
    var green := Color("#477b4c")
    var green_light := Color("#78a76a")
    var hair := Color("#c9c0b2")
    var hair_light := Color("#f0e9dc")
    var hair_dark := Color("#8f887e")

    # Short animated legs are attached directly under the sphere.
    var hip_back := center + Vector2(-9.0, 15.0)
    var hip_front := center + Vector2(9.0, 15.0)
    # Use the same simulated hip/knee joints as the humanoid fighters.
    var back_angle := leg_back_angle
    var front_angle := leg_front_angle
    var knee_back := hip_back + Vector2(sin(back_angle) * 13.0, cos(back_angle) * 13.0)
    var knee_front := hip_front + Vector2(sin(front_angle) * 13.0, cos(front_angle) * 13.0)
    var foot_back := knee_back + Vector2(sin(back_angle + knee_back_angle) * 12.0, cos(back_angle + knee_back_angle) * 12.0)
    var foot_front := knee_front + Vector2(sin(front_angle + knee_front_angle) * 12.0, cos(front_angle + knee_front_angle) * 12.0)

    # Sitting pose for the menu mascot: feet hang over the title letters.
    if menu_mascot:
        knee_back = hip_back + Vector2(-5.0, 12.0)
        foot_back = knee_back + Vector2(-8.0, 10.0)
        knee_front = hip_front + Vector2(7.0, 12.0)
        foot_front = knee_front + Vector2(10.0, 10.0)

    draw_line(hip_back, knee_back, outline, 7.0, true)
    draw_line(hip_back, knee_back, Color("#31583d"), 4.4, true)
    draw_line(knee_back, foot_back, outline, 6.5, true)
    draw_line(knee_back, foot_back, Color("#31583d"), 4.0, true)
    draw_line(foot_back + Vector2(-4.0, 0.0), foot_back + Vector2(6.0, 1.0), outline, 6.0, true)
    draw_line(foot_back + Vector2(-3.0, -1.0), foot_back + Vector2(5.0, 0.0), Color("#263344"), 3.5, true)

    # The whole body is one green sphere.
    draw_circle(center + Vector2(0.0, 2.0), 28.0, Color("#101a27", 0.30))
    draw_circle(center, 26.0, outline)
    draw_circle(center, 23.0, green)
    draw_arc(center, 22.4, PI * 1.08, PI * 1.92, 36, green_light, 2.0, true)
    draw_circle(center + Vector2(-8.0, -9.0), 6.0, Color(1.0, 1.0, 1.0, 0.10))

    # Small friendly face on the green sphere.
    draw_circle(center + Vector2(-8.0, -1.0), 4.2, Color("#f7fff0"))
    draw_circle(center + Vector2(8.0, -1.0), 4.2, Color("#f7fff0"))
    draw_circle(center + Vector2(-7.0, -0.5), 2.0, Color("#203b32"))
    draw_circle(center + Vector2(9.0, -0.5), 2.0, Color("#203b32"))
    draw_circle(center + Vector2(-7.7, -1.5), 0.8, Color.WHITE)
    draw_circle(center + Vector2(8.3, -1.5), 0.8, Color.WHITE)
    draw_arc(center + Vector2(0.0, 5.0), 5.0, 0.18, PI - 0.18, 16, Color("#203b32"), 1.7, true)
    draw_circle(center + Vector2(-14.0, 5.0), 2.2, Color("#f0a3a0", 0.45))
    draw_circle(center + Vector2(14.0, 5.0), 2.2, Color("#f0a3a0", 0.45))

    # Light hair buns and side locks frame the ball, not a human head.
    draw_circle(center + Vector2(-21.0, -22.0), 9.0, hair_dark)
    draw_circle(center + Vector2(-21.0, -22.0), 7.2, hair)
    draw_circle(center + Vector2(21.0, -22.0), 9.0, hair_dark)
    draw_circle(center + Vector2(21.0, -22.0), 7.2, hair)
    draw_arc(center + Vector2(-21.0, -22.0), 7.0, PI * 1.1, PI * 1.8, 16, hair_light, 1.3, true)
    draw_arc(center + Vector2(21.0, -22.0), 7.0, PI * 1.1, PI * 1.8, 16, hair_light, 1.3, true)
    draw_line(center + Vector2(-17.0, -15.0), center + Vector2(-15.0, 7.0), hair_dark, 6.0, true)
    draw_line(center + Vector2(-17.0, -15.0), center + Vector2(-15.0, 7.0), hair, 3.6, true)
    draw_line(center + Vector2(17.0, -15.0), center + Vector2(15.0, 7.0), hair_dark, 6.0, true)
    draw_line(center + Vector2(17.0, -15.0), center + Vector2(15.0, 7.0), hair, 3.6, true)
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-17.0, -14.0), center + Vector2(-15.0, -27.0),
        center + Vector2(-8.0, -34.0), center + Vector2(1.0, -36.0),
        center + Vector2(12.0, -31.0), center + Vector2(17.0, -21.0),
        center + Vector2(12.0, -20.0), center + Vector2(6.0, -24.0),
        center + Vector2(0.0, -18.0), center + Vector2(-6.0, -23.0)
    ]), hair_dark)
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-15.0, -15.0), center + Vector2(-13.0, -26.0),
        center + Vector2(-7.0, -32.0), center + Vector2(1.0, -34.0),
        center + Vector2(11.0, -29.0), center + Vector2(15.0, -21.0),
        center + Vector2(11.0, -21.0), center + Vector2(5.0, -25.0),
        center + Vector2(0.0, -19.0), center + Vector2(-6.0, -24.0)
    ]), hair)
    draw_line(center + Vector2(-10.0, -30.0), center + Vector2(-5.0, -33.0), hair_light, 1.8, true)

    # Original green cap, placed directly on the hairstyle.
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-17.0, -28.0), center + Vector2(-13.0, -39.0),
        center + Vector2(-4.0, -45.0), center + Vector2(8.0, -44.0),
        center + Vector2(17.0, -36.0), center + Vector2(18.0, -28.0)
    ]), outline)
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-14.0, -29.0), center + Vector2(-11.0, -37.0),
        center + Vector2(-3.0, -42.0), center + Vector2(7.0, -41.0),
        center + Vector2(14.0, -35.0), center + Vector2(15.0, -29.0)
    ]), green)
    draw_line(center + Vector2(-16.0, -28.0), center + Vector2(18.0, -28.0), outline, 4.0, true)
    draw_line(center + Vector2(-12.0, -30.0), center + Vector2(14.0, -30.0), green_light, 1.4, true)
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(0.0, -39.0), center + Vector2(2.0, -35.0),
        center + Vector2(6.0, -35.0), center + Vector2(3.0, -32.0),
        center + Vector2(4.0, -28.0), center + Vector2(0.0, -30.0),
        center + Vector2(-4.0, -28.0), center + Vector2(-3.0, -32.0),
        center + Vector2(-6.0, -35.0), center + Vector2(-2.0, -35.0)
    ]), Color("#e4c66e"))

    # Near-side leg is drawn last so both feet remain clearly visible.
    draw_line(hip_front, knee_front, outline, 7.0, true)
    draw_line(hip_front, knee_front, Color("#477b4c"), 4.4, true)
    draw_line(knee_front, foot_front, outline, 6.5, true)
    draw_line(knee_front, foot_front, Color("#31583d"), 4.0, true)
    draw_line(foot_front + Vector2(-4.0, 0.0), foot_front + Vector2(6.0, 1.0), outline, 6.0, true)
    draw_line(foot_front + Vector2(-3.0, -1.0), foot_front + Vector2(5.0, 0.0), Color("#263344"), 3.5, true)

    if hit_flash > 0.0:
        draw_arc(center, 29.0, 0.0, TAU, 48, Color(1.0, 0.86, 0.72, hit_flash * 0.8), 2.0, true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_two_hand_blaster(center: Vector2) -> void:
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
    var local_aim := Vector2(aim_input.x * facing, aim_input.y).normalized()
    if local_aim.length_squared() < 0.01:
        local_aim = Vector2.RIGHT
    var side := local_aim.rotated(PI * 0.5)
    # Keep the grip low on the torso so the arms never sweep across the eyes.
    var gun_origin := center + Vector2(0.0, 9.0) + local_aim * 7.0
    var grip_hand := gun_origin - local_aim * 2.0 + side * 4.0
    var support_hand := gun_origin + local_aim * 9.0 + side * 4.0
    # Hands stay below the eye line even when the weapon is aimed upward.
    grip_hand.y = maxf(grip_hand.y, center.y + 3.0)
    support_hand.y = maxf(support_hand.y, center.y + 3.0)
    var shoulder_a := Vector2(-12.0, 3.0)
    var shoulder_b := Vector2(12.0, 3.0)
    # Elbows are spring-driven joints: they flex independently when running,
    # aiming, recoiling and being hit, while hands remain connected to the blaster.
    var elbow_a := shoulder_a.lerp(grip_hand, 0.50) + Vector2(sin(arm_back_angle) * 7.0, cos(elbow_back_angle) * 5.0) + side * 2.0
    var elbow_b := shoulder_b.lerp(support_hand, 0.50) + Vector2(sin(arm_front_angle) * 7.0, cos(elbow_front_angle) * 5.0) - side * 2.0
    var arm_outline := Color("#142333")
    var arm_color := body_color.lightened(0.12)
    for arm_points in [[shoulder_a, elbow_a, grip_hand], [shoulder_b, elbow_b, support_hand]]:
        draw_line(arm_points[0], arm_points[1], arm_outline, 11.5, true)
        draw_line(arm_points[0], arm_points[1], arm_color, 8.0, true)
        draw_line(arm_points[1], arm_points[2], arm_outline, 10.0, true)
        draw_line(arm_points[1], arm_points[2], arm_color, 7.0, true)
        draw_circle(arm_points[1], 5.8, arm_outline)
        draw_circle(arm_points[1], 4.0, arm_color)
        draw_circle(arm_points[2], 5.0, Color("#e9c9aa"))
    draw_circle(shoulder_a, 5.0, arm_color)
    draw_circle(shoulder_b, 5.0, arm_color)
    var screen_origin := Vector2(gun_origin.x * facing, gun_origin.y)
    draw_set_transform(screen_origin, aim_input.angle(), Vector2.ONE)
    var outline := Color("#142333")
    var metal := Color("#202c3b")
    var metal_light := Color("#53677d")
    var trim := body_color.lightened(0.42)
    var barrel_len := 23.0 + float(weapon_level) * 3.0
    var pistol := PackedVector2Array([Vector2(-7,-5), Vector2(barrel_len-4,-5), Vector2(barrel_len+1,-2), Vector2(barrel_len+1,2), Vector2(2,3), Vector2(0,9), Vector2(-6,9), Vector2(-5,3), Vector2(-9,1), Vector2(-9,-3)])
    draw_colored_polygon(pistol, outline)
    draw_colored_polygon(PackedVector2Array([Vector2(-5,-3),Vector2(barrel_len-4,-3),Vector2(barrel_len-2,0),Vector2(1,1),Vector2(-2,2),Vector2(-6,1)]), metal)
    draw_line(Vector2(-3,-2),Vector2(barrel_len-5,-2),trim,1.8,true)
    draw_rect(Rect2(barrel_len-1,-1.8,3.0,3.6),Color("#101820"))
    draw_line(Vector2(-4,4),Vector2(-5,8),metal_light,1.4,true)
    draw_line(Vector2(-7,5),Vector2(-3,5),metal_light,1.2,true)
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
        draw_circle(Vector2(barrel_len+4,0),flash_size*0.62,Color("#ffd978",muzzle_flash*1.8))
        draw_colored_polygon(PackedVector2Array([Vector2(barrel_len+1,0),Vector2(barrel_len+flash_size,-flash_size*0.4),Vector2(barrel_len+flash_size*0.55,0),Vector2(barrel_len+flash_size,flash_size*0.4)]),Color("#fff0a8",0.95))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
