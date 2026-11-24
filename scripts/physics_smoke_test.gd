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
    current_scene = game
    root.add_child(game)
    for _i in range(4):
        await process_frame

    var player := game.get("player") as CharacterBody2D
    var rival := game.get("rival") as CharacterBody2D
    if player == null or rival == null:
        _fail("players were not created during boot")
        return

    game.set("vibration_enabled", false)
    game.call("_start_game", "training")
    player.call("set_move", Vector2.RIGHT)
    for _i in range(12):
        await physics_frame
    if player.velocity.x <= 20.0:
        _fail("player movement did not accelerate")
        return

    player.call("set_jump", true)
    for _i in range(2):
        await physics_frame
    if player.velocity.y >= -50.0:
        _fail("jump did not apply upward velocity")
        return
    player.call("set_jump", false)

    for _i in range(32):
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
    var pulse := pulse_script.new()
    game.add_child(pulse)
    pulse.call("configure", Vector2.RIGHT, 610.0, Color.WHITE, rival)
    pulse.global_position = player.global_position - Vector2(35.0, 0.0)
    pulse.call("_on_body_entered", player)
    if float(player.get("hitstun_timer")) <= 0.0:
        _fail("projectile hit did not apply hitstun")
        return

    print("PHYSICS TEST PASSED: movement, jump, firing, bot reload, projectile hit")
    quit(0)
