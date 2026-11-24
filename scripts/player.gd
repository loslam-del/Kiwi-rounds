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
var ragdoll_anchor_body: StaticBody2D
var ragdoll_parts: Array[RigidBody2D] = []
var ragdoll_joints: Array[PinJoint2D] = []
var ragdoll_root_joints: Array[PinJoint2D] = []
var ragdoll_anchor_offsets: Array[Vector2] = []

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
    call_deferred("_create_physics_ragdoll")

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
    _sync_ragdoll_anchor_joints()
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
    _rebuild_physics_ragdoll()

func _rebuild_physics_ragdoll() -> void:
    for joint in ragdoll_joints:
        if is_instance_valid(joint):
            joint.queue_free()
    for part in ragdoll_parts:
        if is_instance_valid(part):
            part.queue_free()
    ragdoll_parts.clear()
    ragdoll_joints.clear()
    if is_instance_valid(ragdoll_anchor_body):
        ragdoll_anchor_body.queue_free()
    ragdoll_anchor_body = null
    ragdoll_root_joints.clear()
    ragdoll_anchor_offsets.clear()
    call_deferred("_create_physics_ragdoll")

func _create_physics_ragdoll() -> void:
    if not is_inside_tree():
        return
    var world := get_tree().current_scene
    if world == null:
        return
    ragdoll_anchor_body = StaticBody2D.new()
    ragdoll_anchor_body.name = "RagdollTorsoAnchor"
    ragdoll_anchor_body.collision_layer = 0
    ragdoll_anchor_body.collision_mask = 0
    ragdoll_anchor_body.global_position = global_position
    world.add_child(ragdoll_anchor_body)
    _create_limb_chain(world, Vector2(-17.0, -5.0), -0.95, -0.72, 16.0, 15.0)
    _create_limb_chain(world, Vector2(17.0, -5.0), 0.95, 0.72, 16.0, 15.0)
    _create_limb_chain(world, Vector2(-7.5, 10.0), -0.12, -0.08, 15.0, 13.0)
    _create_limb_chain(world, Vector2(7.5, 10.0), 0.12, 0.08, 15.0, 13.0)
    _sync_ragdoll_anchor_joints()

func _create_limb_chain(world: Node, anchor_local: Vector2, upper_angle: float, lower_relative_angle: float, upper_length: float, lower_length: float) -> void:
    var anchor := global_position + Vector2(anchor_local.x * facing, anchor_local.y)
    var upper_direction := _limb_vector(upper_angle, 1.0).normalized()
    var upper_center := anchor + upper_direction * (upper_length * 0.5)
    var upper := _make_ragdoll_part(world, upper_length, upper_center, upper_angle)
    var elbow := anchor + upper_direction * upper_length
    var lower_angle := upper_angle + lower_relative_angle
    var lower_direction := _limb_vector(lower_angle, 1.0).normalized()
    var lower_center := elbow + lower_direction * (lower_length * 0.5)
    var lower := _make_ragdoll_part(world, lower_length, lower_center, lower_angle)
    _connect_ragdoll_parts(world, ragdoll_anchor_body, upper, anchor, true, anchor_local)
    _connect_ragdoll_parts(world, upper, lower, elbow, false, Vector2.ZERO)

func _make_ragdoll_part(world: Node, segment_length: float, at: Vector2, segment_angle: float) -> RigidBody2D:
    var part := RigidBody2D.new()
    part.name = "RagdollLimb"
    part.global_position = at
    var direction := _limb_vector(segment_angle, 1.0).normalized()
    part.rotation = Vector2.DOWN.angle_to(direction)
    part.mass = 0.075
    part.gravity_scale = 1.0
    part.linear_damp = 0.65
    part.angular_damp = 2.0
    part.collision_layer = 4
    part.collision_mask = 7
    part.can_sleep = false
    part.continuous_cd = true
    var collision := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = 2.2
    capsule.height = segment_length + 4.4
    collision.shape = capsule
    part.add_child(collision)
    var visual := Line2D.new()
    visual.name = "LimbVisual"
    visual.points = PackedVector2Array([Vector2(0.0, -segment_length * 0.5), Vector2(0.0, segment_length * 0.5)])
    visual.width = 4.2
    visual.default_color = body_color
    visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
    visual.end_cap_mode = Line2D.LINE_CAP_ROUND
    visual.antialiased = true
    part.add_child(visual)
    world.add_child(part)
    ragdoll_parts.append(part)
    add_collision_exceptions(part)
    return part

func add_collision_exceptions(part: RigidBody2D) -> void:
    part.add_collision_exception_with(self)
    for other in ragdoll_parts:
        if is_instance_valid(other):
            part.add_collision_exception_with(other)
            other.add_collision_exception_with(part)

func apply_ragdoll_impulse(direction: Vector2, strength: float) -> void:
    var impulse := direction.normalized() * strength
    for i in range(ragdoll_parts.size()):
        var part := ragdoll_parts[i]
        if is_instance_valid(part):
            var weight := 0.75 + float(i % 2) * 0.25
            part.apply_central_impulse(impulse * weight / 8.0)
            part.apply_torque_impulse(randf_range(-strength, strength) * 0.018)

func _connect_ragdoll_parts(world: Node, body_a: PhysicsBody2D, body_b: PhysicsBody2D, at: Vector2, root_joint: bool, anchor_local: Vector2) -> void:
    var joint := PinJoint2D.new()
    joint.name = "RagdollPin"
    joint.global_position = at
    joint.softness = 0.035
    joint.angular_limit_enabled = true
    joint.angular_limit_lower = -1.35 if not root_joint else -1.05
    joint.angular_limit_upper = 1.35 if not root_joint else 1.05
    world.add_child(joint)
    joint.node_a = joint.get_path_to(body_a)
    joint.node_b = joint.get_path_to(body_b)
    ragdoll_joints.append(joint)
    if root_joint:
        ragdoll_root_joints.append(joint)
        ragdoll_anchor_offsets.append(anchor_local)

func _sync_ragdoll_anchor_joints() -> void:
    if is_instance_valid(ragdoll_anchor_body):
        ragdoll_anchor_body.global_position = global_position
    for i in range(mini(ragdoll_root_joints.size(), ragdoll_anchor_offsets.size())):
        var joint := ragdoll_root_joints[i]
        if is_instance_valid(joint):
            var offset: Vector2 = ragdoll_anchor_offsets[i]
            joint.global_position = global_position + Vector2(offset.x * facing, offset.y)

func _limb_vector(angle: float, length: float) -> Vector2:
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

func _draw() -> void:
    var center := Vector2(0.0, -7.0)
    var face := Color("#102536")
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
    draw_circle(center, 21.0, body_color)
    draw_circle(center + Vector2(-6.0, -2.0), 1.9, face)
    draw_circle(center + Vector2(6.0, -2.0), 1.9, face)
    draw_line(center + Vector2(-3.0, 6.0), center + Vector2(3.0, 6.0), face, 1.8, true)
    if hit_flash > 0.0:
        draw_circle(center, 24.0, Color(1.0, 0.35, 0.28, hit_flash * 0.28))
    if reload_visual > 0.0:
        draw_arc(center, 25.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - reload_visual), 28, Color.WHITE, 2.0, true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
