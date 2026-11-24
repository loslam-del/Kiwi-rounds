extends SceneTree

func _initialize() -> void:
    call_deferred("_run_physics_checks")

func _fail(message: String) -> void:
    push_error("PHYSICS TEST FAILED: " + message)
    quit(1)

func _run_physics_checks() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("main scene could not be loaded")
        return
    var game := packed.instantiate()
    root.add_child(game)
    current_scene = game
    for _i in range(4):
        await process_frame

    var player := game.get("player") as CharacterBody2D
    var rival := game.get("rival") as CharacterBody2D
    if player == null or rival == null:
        _fail("players were not created during boot")
        return

    game.set("vibration_enabled", false)
    game.call("_start_game", "training")
    rival.set("bot_accuracy", 0.0)
    player.call("set_move", Vector2.RIGHT)
    for _i in range(12):
        await physics_frame
    if player.velocity.x <= 20.0:
        _fail("player movement did not accelerate")
        return

    player.call("set_move", Vector2.ZERO)
    player.velocity.x = 0.0
    player.call("set_jump", true)
    for _i in range(2):
        await physics_frame
    if player.velocity.y >= -50.0:
        _fail("jump did not apply upward velocity")
        return
    player.call("set_jump", false)
    for _i in range(75):
        await physics_frame
    if not player.is_on_floor():
        _fail("player did not land on the platform")
        return

    player.global_position = Vector2(50.0, 300.0)
    player.velocity = Vector2(-850.0, 0.0)
    player.call("set_move", Vector2.LEFT)
    for _i in range(18):
        await physics_frame
    if player.global_position.x < 18.0:
        _fail("side wall did not stop the player")
        return
    player.call("set_move", Vector2.ZERO)
    player.velocity = Vector2.ZERO
    player.call("set_jump", true)
    await physics_frame
    if player.velocity.x <= 0.0 or player.velocity.y >= 0.0:
        _fail("wall jump did not launch away from the wall")
        return
    player.call("set_jump", false)

    for _i in range(8):
        await physics_frame
    var ammo_before: int = int(player.get("ammo"))
    player.call("set_fire", true)
    await physics_frame
    player.call("set_fire", false)
    if int(player.get("ammo")) >= ammo_before:
        _fail("player shot did not consume ammunition")
        return

    rival.set("ammo", 0)
    rival.set("reload_timer", 0.0)
    await physics_frame
    if float(rival.get("reload_timer")) <= 0.0:
        _fail("bot did not automatically start reloading")
        return

    var pulse_script := load("res://scripts/pulse.gd") as Script
    var pulse := pulse_script.new() as Area2D
    game.add_child(pulse)
    pulse.call("configure", Vector2.RIGHT, 610.0, Color.WHITE, rival)
    pulse.global_position = player.global_position - Vector2(35.0, 0.0)
    pulse.call("_on_body_entered", player)
    if float(player.get("hitstun_timer")) <= 0.0:
        _fail("projectile hit did not apply hitstun")
        return

    player.set("ricochet_count", 2)
    var bounce := pulse_script.new() as Area2D
    game.add_child(bounce)
    bounce.call("configure", Vector2.UP, 610.0, Color.WHITE, player)
    var platform := StaticBody2D.new()
    platform.name = "ArenaPlatform"
    game.add_child(platform)
    bounce.call("_on_body_entered", platform)
    var bounce_direction: Vector2 = bounce.get("direction")
    if bounce_direction.y <= 0.0 or int(bounce.get("ricochets_left")) != 1:
        _fail("projectile did not ricochet from a platform")
        return

    player.set("homing_strength", 4.2)
    var guided := pulse_script.new() as Area2D
    game.add_child(guided)
    guided.call("configure", Vector2.UP, 610.0, Color.WHITE, player)
    guided.call("_physics_process", 0.1)
    var guided_direction: Vector2 = guided.get("direction")
    if guided_direction.x <= 0.0:
        _fail("homing projectile did not turn toward its target")
        return

    await create_timer(0.35).timeout
    print("PHYSICS TEST PASSED: movement, jump, firing, bot reload, projectile hit")
    quit(0)
