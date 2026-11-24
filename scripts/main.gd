extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PULSE_SCRIPT = preload("res://scripts/pulse.gd")
const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
const MOD_LOADER_SCRIPT = preload("res://scripts/mod_loader.gd")

const DEFAULT_UPGRADES := [
    {"id":"swift","name":"ТУРБО-БОТИНКИ","icon":"SPD","buff":"БАФФ  Скорость +16%","debuff":"МИНУС  Сила выстрела −10%","effect":"swift"},
    {"id":"spring","name":"ПРУЖИННЫЙ МОДУЛЬ","icon":"JMP","buff":"БАФФ  Высота прыжка +12%","debuff":"МИНУС  Скорость −8%","effect":"spring"},
    {"id":"wave","name":"ТЯЖЁЛЫЙ КАЛИБР","icon":"PWR","buff":"БАФФ  Отбрасывание +22%","debuff":"МИНУС  Перезарядка дольше на 12%","effect":"wave"},
    {"id":"rapid","name":"БЫСТРЫЙ ЗАТВОР","icon":"RLD","buff":"БАФФ  Перезарядка быстрее на 18%","debuff":"МИНУС  Сила выстрела −10%","effect":"rapid"},
    {"id":"sturdy","name":"БОЕВОЙ РАЗГОН","icon":"MIX","buff":"БАФФ  Скорость +6%, прыжок +8%","debuff":"МИНУС  Нет","effect":"sturdy"}
]
const DEFAULT_MAPS := [
    {"name":"Сумеречная арена","platforms":[{"x":330,"y":545,"w":250,"h":24},{"x":950,"y":545,"w":250,"h":24},{"x":640,"y":420,"w":190,"h":22},{"x":130,"y":635,"w":170,"h":20},{"x":1150,"y":635,"w":170,"h":20}]},
    {"name":"Парящие острова","platforms":[{"x":250,"y":560,"w":210,"h":22},{"x":500,"y":455,"w":180,"h":22},{"x":780,"y":455,"w":180,"h":22},{"x":1030,"y":560,"w":210,"h":22},{"x":640,"y":330,"w":210,"h":22}]},
    {"name":"Ломаный мост","platforms":[{"x":200,"y":600,"w":180,"h":22},{"x":420,"y":495,"w":190,"h":22},{"x":640,"y":590,"w":190,"h":22},{"x":860,"y":495,"w":190,"h":22},{"x":1080,"y":600,"w":180,"h":22},{"x":640,"y":390,"w":150,"h":22}]}
]

var player: ArenaPlayer
var rival: ArenaPlayer
var ui: Control
var hud: Label
var overlay: Control
var game_controls: Control
var skin_button: Button
var ammo_label: Label
var fire_button: Button
var training_tab := "cards"
var skin_return_to_game := false
var platform_nodes: Array[StaticBody2D] = []
var mod_loader: GameModLoader
var all_maps: Array[Dictionary] = []
var all_upgrades: Array[Dictionary] = []
var map_index := 0
var skin_index := 0
var score_player := 0
var score_bot := 0
var round_index := 1
var phase := "menu"
var game_mode := "bot"
var bot_difficulty := "normal"
var bot_accuracy := 0.64
var active_training_cards: Array[String] = []
var selected_skin_color := Color("#39d6c5")
var sound_enabled := true
var vibration_enabled := true
var boot_loading := true
var boot_elapsed := 0.0
var boot_angle := 0.0
var boot_stage := "Подготовка игры..."
var mods_loaded := false
var arena_camera: Camera2D
var camera_shake_timer := 0.0
var camera_shake_strength := 0.0
var shake_enabled := true
var controls_mirrored := false
var sound_level := 0.72
var movement_joystick: VirtualJoystick
var aim_joystick: VirtualJoystick
var reload_button: Button
var jump_button: Button
var menu_button: Button
var cards_button: Button
var mod_json_input: TextEdit
var mod_status_message := "Вставь JSON мода и нажми ИМПОРТИРОВАТЬ."

func _ready() -> void:
    randomize()
    queue_redraw()
    call_deferred("_boot_game")

func _boot_game() -> void:
    boot_stage = "Подготовка игровых данных..."
    # Модуль модов не создаётся при запуске. Главное меню не зависит от модов.
    all_maps.assign(DEFAULT_MAPS)
    all_upgrades.assign(DEFAULT_UPGRADES)
    boot_stage = "Создание арены..."
    _make_arena(0)
    boot_stage = "Создание персонажей..."
    _make_players()
    boot_stage = "Подготовка интерфейса..."
    _make_ui()
    boot_stage = "Запуск меню..."
    _show_main_menu()
    _update_hud()
    boot_loading = false
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("#101723"))
    draw_rect(Rect2(0,0,1280,470),Color("#172234"))
    draw_rect(Rect2(0,470,1280,250),Color("#121a27"))
    for i in range(7):
        var y := 80.0 + float(i)*74.0
        draw_line(Vector2(0,y),Vector2(1280,y),Color(0.35,0.47,0.62,0.07),1.0)
    for i in range(13):
        var x := float((i*173+61)%1280)
        var y := float((i*97+43)%650)
        draw_circle(Vector2(x,y),1.5 if i%3==0 else 1.0,Color(0.72,0.84,1.0,0.25))
    draw_arc(Vector2(640,470),430,PI,TAU,80,Color(0.38,0.55,0.77,0.09),2.0,true)
    draw_arc(Vector2(640,470),520,PI,TAU,80,Color(0.38,0.55,0.77,0.06),2.0,true)
    draw_rect(Rect2(0,0,1280,5),Color("#d9ef70"))
    draw_rect(Rect2(0,700,1280,20),Color("#0b111b"))
    draw_line(Vector2(0,700),Vector2(1280,700),Color("#526a87"),2.0)
    if boot_loading:
        draw_rect(Rect2(0,0,1280,720),Color(0.03,0.04,0.06,0.82))
        draw_string(ThemeDB.fallback_font,Vector2(0,295),"KIWI ROUNDS",HORIZONTAL_ALIGNMENT_CENTER,1280,54,Color("#f2f2f2"))
        draw_string(ThemeDB.fallback_font,Vector2(0,345),"ЗАПУСК ИГРЫ",HORIZONTAL_ALIGNMENT_CENTER,1280,18,Color("#aab4c4"))
        var center := Vector2(640,430)
        draw_arc(center,27.0,boot_angle,boot_angle+4.4,48,Color("#d9ef70"),6.0,true)
        draw_circle(center+Vector2(cos(boot_angle)*27.0,sin(boot_angle)*27.0),5.0,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(0,500),boot_stage,HORIZONTAL_ALIGNMENT_CENTER,1280,18,Color("#aaaaaa"))
        draw_string(ThemeDB.fallback_font,Vector2(0,675),"Пожалуйста, подожди",HORIZONTAL_ALIGNMENT_CENTER,1280,15,Color("#777f8e"))
        return

func _make_arena(index: int) -> void:
    for old_platform in platform_nodes:
        if is_instance_valid(old_platform):
            old_platform.queue_free()
    platform_nodes.clear()
    _add_platform(Vector2(640, 700), Vector2(1400, 50))
    _add_side_wall(-15.0)
    _add_side_wall(1295.0)
    if all_maps.is_empty():
        return
    map_index = index % all_maps.size()
    var map_data: Dictionary = all_maps[map_index]
    var platforms: Variant = map_data.get("platforms", [])
    if typeof(platforms) == TYPE_ARRAY:
        for item in platforms:
            if typeof(item) == TYPE_DICTIONARY:
                _add_platform(Vector2(float(item.get("x",640)),float(item.get("y",500))),Vector2(float(item.get("w",180)),float(item.get("h",22))))

func _add_side_wall(x: float) -> void:
    var wall := StaticBody2D.new()
    wall.position = Vector2(x,350)
    wall.collision_layer = 2
    wall.collision_mask = 0
    var shape_node := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(30,900)
    shape_node.shape = rect
    wall.add_child(shape_node)
    add_child(wall)
    platform_nodes.append(wall)
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([Vector2(-15,-450),Vector2(15,-450),Vector2(15,450),Vector2(-15,450)])
    visual.color = Color("#1c293b")
    wall.add_child(visual)
    var edge := Line2D.new()
    edge.points = PackedVector2Array([Vector2(0,-450),Vector2(0,450)])
    edge.width = 3.0
    edge.default_color = Color("#526a87",0.45)
    wall.add_child(edge)

func _add_platform(at: Vector2, dimensions: Vector2) -> void:
    var body := StaticBody2D.new()
    body.position = at
    body.collision_layer = 2
    body.collision_mask = 0
    var shape_node := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = dimensions
    shape_node.shape = rect
    body.add_child(shape_node)
    add_child(body)
    platform_nodes.append(body)
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,dimensions.y/2),Vector2(-dimensions.x/2,dimensions.y/2)])
    visual.color = Color("#283b54")
    body.add_child(visual)
    var lower_glow := Polygon2D.new()
    lower_glow.polygon = PackedVector2Array([Vector2(-dimensions.x/2,dimensions.y/2),Vector2(dimensions.x/2,dimensions.y/2),Vector2(dimensions.x/2,dimensions.y/2+5),Vector2(-dimensions.x/2,dimensions.y/2+5)])
    lower_glow.color = Color("#6d8fb8",0.55)
    body.add_child(lower_glow)
    var stripe := Line2D.new()
    stripe.points = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2)])
    stripe.width = 5.0
    stripe.default_color = Color("#d9ef70")
    stripe.antialiased = true
    body.add_child(stripe)

func _make_players() -> void:
    player = PLAYER_SCRIPT.new()
    player.body_color = selected_skin_color
    player.position = Vector2(350,390)
    player.pulse_requested.connect(_spawn_pulse)
    player.got_hit.connect(_on_player_hit)
    add_child(player)
    rival = PLAYER_SCRIPT.new()
    rival.is_bot = true
    rival.body_color = Color("#ff786f")
    rival.position = Vector2(930,390)
    rival.target = player
    rival.pulse_requested.connect(_spawn_pulse)
    rival.got_hit.connect(_on_player_hit)
    arena_camera = Camera2D.new()
    arena_camera.position = Vector2(640,360)
    arena_camera.enabled = true
    arena_camera.position_smoothing_enabled = false
    add_child(arena_camera)
    add_child(rival)

func _get_skins() -> Array[Dictionary]:
    if mod_loader == null:
        mod_loader = MOD_LOADER_SCRIPT.new()
    if not mods_loaded:
        mod_loader.load_all()
        all_maps.assign(DEFAULT_MAPS)
        all_maps.append_array(mod_loader.maps)
        all_upgrades.assign(DEFAULT_UPGRADES)
        all_upgrades.append_array(mod_loader.upgrades)
        mods_loaded = true
    var skins: Array[Dictionary] = [
        {"name":"Бирюзовый","color":"#39d6c5"},
        {"name":"Лазурный","color":"#4b9cff"},
        {"name":"Фиолетовый","color":"#b47cff"},
        {"name":"Золотой","color":"#ffc857"},
        {"name":"Розовый","color":"#ff78b7"}
    ]
    skins.append_array(mod_loader.skins)
    return skins

func _apply_skin() -> void:
    var skins: Array[Dictionary] = [
        {"name":"Бирюзовый","color":"#39d6c5"},
        {"name":"Лазурный","color":"#4b9cff"},
        {"name":"Фиолетовый","color":"#b47cff"},
        {"name":"Золотой","color":"#ffc857"},
        {"name":"Розовый","color":"#ff78b7"}
    ]
    if mods_loaded and mod_loader != null:
        skins.append_array(mod_loader.skins)
    if skins.is_empty():
        return
    skin_index = posmod(skin_index, skins.size())
    var skin: Dictionary = skins[skin_index]
    selected_skin_color = Color.from_string(str(skin.get("color","#39d6c5")),Color("#39d6c5"))
    if is_instance_valid(player):
        player.body_color = selected_skin_color
        player.queue_redraw()
    if is_instance_valid(skin_button):
        skin_button.text = "СКИН: " + str(skin.get("name",skin.get("id","MOD")))

func _cycle_skin() -> void:
    skin_index += 1
    _apply_skin()

func _on_player_hit(_direction: Vector2, hit_target: Node2D) -> void:
    if shake_enabled:
        camera_shake_timer = 0.16
        camera_shake_strength = 7.0
    _play_sfx("hit")
    if hit_target == player and vibration_enabled:
        Input.vibrate_handheld(55,0.25)

func _clear_pulses() -> void:
    for node in get_children():
        if node is EnergyPulse:
            node.queue_free()

func _spawn_pulse(origin: Vector2, direction: Vector2, force: float, tint: Color, shooter: Node2D) -> void:
    var pulse: EnergyPulse = PULSE_SCRIPT.new()
    pulse.configure(direction,force,tint,shooter)
    _play_sfx("shot")
    pulse.global_position = origin
    add_child(pulse)

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)
    hud = Label.new()
    hud.position = Vector2(0,14)
    hud.size = Vector2(1280,50)
    hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_theme_font_size_override("font_size",28)
    hud.add_theme_color_override("font_color",Color("#f4f7ff"))
    ui.add_child(hud)
    game_controls = Control.new()
    game_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(game_controls)
    skin_button = _add_button("СКИН",Vector2(1080,18),Vector2(150,50),game_controls)
    skin_button.pressed.connect(_open_skins)
    movement_joystick = JOYSTICK_SCRIPT.new()
    movement_joystick.position = Vector2(35,535)
    movement_joystick.size = Vector2(150,150)
    movement_joystick.value_changed.connect(player.set_move)
    game_controls.add_child(movement_joystick)
    fire_button = _add_button("ВЫСТРЕЛ",Vector2(205,585),Vector2(145,76),game_controls)
    fire_button.button_down.connect(player.set_fire.bind(true))
    fire_button.button_up.connect(player.set_fire.bind(false))
    reload_button = _add_button("ПЕРЕЗАРЯДКА",Vector2(365,585),Vector2(175,76),game_controls)
    reload_button.add_theme_font_size_override("font_size",15)
    reload_button.pressed.connect(player.start_reload)
    reload_button.pressed.connect(_play_sfx.bind("reload"))
    ammo_label = Label.new()
    ammo_label.position = Vector2(190,545)
    ammo_label.size = Vector2(360,32)
    ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ammo_label.add_theme_font_size_override("font_size",18)
    ammo_label.add_theme_color_override("font_color",Color("#f4f7ff"))
    game_controls.add_child(ammo_label)
    aim_joystick = JOYSTICK_SCRIPT.new()
    aim_joystick.position = Vector2(1080,535)
    aim_joystick.size = Vector2(150,150)
    aim_joystick.value_changed.connect(player.set_aim)
    game_controls.add_child(aim_joystick)
    jump_button = _add_button("ПРЫЖОК",Vector2(1090,405),Vector2(130,82),game_controls)
    jump_button.button_down.connect(player.set_jump.bind(true))
    jump_button.button_up.connect(player.set_jump.bind(false))
    menu_button = _add_button("МЕНЮ",Vector2(18,18),Vector2(120,50),game_controls)
    menu_button.pressed.connect(_show_pause_menu)
    cards_button = _add_button("КАРТОЧКИ",Vector2(150,18),Vector2(160,50),game_controls)
    cards_button.pressed.connect(_open_training_cards)
    _apply_skin()
    _apply_control_layout()
    _apply_audio_settings()

func _apply_control_layout() -> void:
    if not is_instance_valid(movement_joystick) or not is_instance_valid(aim_joystick):
        return
    if controls_mirrored:
        movement_joystick.position = Vector2(1080,535)
        aim_joystick.position = Vector2(35,535)
        fire_button.position = Vector2(205,585)
        reload_button.position = Vector2(365,585)
        jump_button.position = Vector2(35,405)
    else:
        movement_joystick.position = Vector2(35,535)
        aim_joystick.position = Vector2(1080,535)
        fire_button.position = Vector2(820,585)
        reload_button.position = Vector2(820,495)
        jump_button.position = Vector2(1090,405)
    menu_button.position = Vector2(18,18)
    cards_button.position = Vector2(150,18)

func _apply_audio_settings() -> void:
    if AudioServer.bus_count > 0:
        AudioServer.set_bus_volume_linear(0,sound_level)
        AudioServer.set_bus_mute(0,sound_level <= 0.001)

func _play_sfx(kind: String) -> void:
    if sound_level <= 0.001:
        return
    var duration := 0.12
    var start_hz := 440.0
    var end_hz := 220.0
    var gain := 0.45
    match kind:
        "shot":
            duration = 0.10
            start_hz = 720.0
            end_hz = 180.0
            gain = 0.32
        "hit":
            duration = 0.16
            start_hz = 190.0
            end_hz = 65.0
            gain = 0.55
        "reload":
            duration = 0.22
            start_hz = 380.0
            end_hz = 620.0
            gain = 0.25
    var sample_rate := 22050
    var sample_count := int(sample_rate * duration)
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 2)
    for i in range(sample_count):
        var t := float(i) / float(sample_rate)
        var progress := float(i) / float(maxi(sample_count - 1,1))
        var frequency := lerpf(start_hz,end_hz,progress)
        var envelope := pow(1.0-progress,2.0)
        var sample := int(sin(TAU * frequency * t) * envelope * gain * sound_level * 18000.0)
        bytes[i*2] = sample & 0xff
        bytes[i*2+1] = (sample >> 8) & 0xff
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = bytes
    var audio := AudioStreamPlayer.new()
    audio.stream = stream
    audio.bus = "Master"
    add_child(audio)
    audio.finished.connect(audio.queue_free)
    audio.play()

func _add_button(caption: String, at: Vector2, dimensions: Vector2, parent: Control = null) -> Button:
    var button := Button.new()
    button.text = caption
    button.position = at
    button.size = dimensions
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size",19)
    button.add_theme_color_override("font_color",Color("#ffffff"))
    button.add_theme_stylebox_override("normal",_button_style(Color("#263b5b")))
    button.add_theme_stylebox_override("pressed",_button_style(Color("#3d638e")))
    if parent == null:
        ui.add_child(button)
    else:
        parent.add_child(button)
    return button

func _button_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_left = 18
    style.corner_radius_bottom_right = 18
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.border_color = Color("#7895bc")
    return style

func _process(delta: float) -> void:
    if is_instance_valid(arena_camera):
        if shake_enabled and camera_shake_timer > 0.0:
            camera_shake_timer = maxf(0.0,camera_shake_timer-delta)
            arena_camera.offset = Vector2(randf_range(-camera_shake_strength,camera_shake_strength),randf_range(-camera_shake_strength,camera_shake_strength))
        else:
            arena_camera.offset = Vector2.ZERO
    if boot_loading:
        boot_elapsed += delta
        boot_angle = fmod(boot_angle + delta * 4.2, TAU)
        queue_redraw()
        return
    if phase != "fight":
        return
    if is_instance_valid(ammo_label):
        ammo_label.text = player.ammo_text()
    if player.global_position.y > 850:
        _finish_round(false)
    elif rival.global_position.y > 850:
        _finish_round(true)

func _start_game(mode: String) -> void:
    _clear_pulses()
    player.set_physics_process(true)
    rival.set_physics_process(true)
    game_mode = mode
    score_player = 0
    score_bot = 0
    round_index = 1
    active_training_cards.clear()
    _reset_player_stats(player)
    _reset_player_stats(rival)
    rival.bot_accuracy = bot_accuracy
    rival.move_speed = 340.0 if bot_difficulty == "easy" else (480.0 if bot_difficulty == "hard" else 430.0)
    _make_arena(map_index if mode == "training" else 0)
    player.reset_round(Vector2(350,390))
    rival.reset_round(Vector2(930,390))
    phase = "fight"
    _close_overlay()
    game_controls.visible = true
    hud.visible = true
    _update_hud()

func _reset_player_stats(who: ArenaPlayer) -> void:
    who.move_speed = 430.0
    who.jump_speed = -735.0
    who.pulse_force = 610.0
    who.pulse_interval = 0.78
    who.magazine_size = 6
    who.ammo = 6
    who.reload_duration = 1.35
    who.reload_timer = 0.0

func _show_main_menu() -> void:
    phase = "menu"
    skin_return_to_game = false
    player.set_physics_process(false)
    rival.set_physics_process(false)
    game_controls.visible = false
    hud.visible = false
    _close_overlay()
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#101116")
    ui.add_child(shade)
    overlay = shade
    var ring := Panel.new()
    ring.position = Vector2(365,95)
    ring.size = Vector2(550,535)
    var rs := StyleBoxFlat.new()
    rs.bg_color = Color("#151923")
    rs.border_color = Color("#343a4b")
    rs.set_border_width_all(2)
    rs.set_corner_radius_all(260)
    ring.add_theme_stylebox_override("panel",rs)
    shade.add_child(ring)
    var logo := Panel.new()
    logo.position = Vector2(548,55)
    logo.size = Vector2(184,184)
    var ls := StyleBoxFlat.new()
    ls.bg_color = Color("#242b25")
    ls.border_color = Color("#b9e36c")
    ls.set_border_width_all(5)
    ls.set_corner_radius_all(92)
    logo.add_theme_stylebox_override("panel",ls)
    shade.add_child(logo)
    _add_kiwi_mascot(logo,Vector2(92,92))
    var title := Label.new()
    title.text = "KIWI ROUNDS"
    title.position = Vector2(0,235)
    title.size = Vector2(1280,62)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",48)
    title.add_theme_color_override("font_color",Color("#f2f1e9"))
    shade.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "ONE ARENA. TWO FIGHTERS. NO MERCY."
    subtitle.position = Vector2(0,292)
    subtitle.size = Vector2(1280,28)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size",14)
    subtitle.add_theme_color_override("font_color",Color("#9a9da8"))
    shade.add_child(subtitle)
    var play := _add_button("ИГРАТЬ",Vector2(440,345),Vector2(400,82),shade)
    play.add_theme_font_size_override("font_size",30)
    play.add_theme_stylebox_override("normal",_menu_button_style(Color("#d9ef70"),Color("#f1f7bb")))
    play.add_theme_color_override("font_color",Color("#171b13"))
    play.pressed.connect(_show_mode_menu)
    var settings := _add_button("НАСТРОЙКИ",Vector2(180,470),Vector2(245,66),shade)
    settings.add_theme_stylebox_override("normal",_menu_button_style(Color("#292e3a"),Color("#596174")))
    settings.pressed.connect(_show_settings)
    var mods := _add_button("МОДЫ",Vector2(855,470),Vector2(245,66),shade)
    mods.add_theme_stylebox_override("normal",_menu_button_style(Color("#292e3a"),Color("#596174")))
    mods.pressed.connect(_open_mods)
    var skins := _add_button("СКИНЫ",Vector2(518,570),Vector2(245,66),shade)
    skins.add_theme_stylebox_override("normal",_menu_button_style(Color("#292e3a"),Color("#b9e36c")))
    skins.pressed.connect(_open_skins)
    var footer := Label.new()
    footer.text = "KIWI ROUNDS  •  ANDROID BUILD"
    footer.position = Vector2(0,675)
    footer.size = Vector2(1280,24)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size",12)
    footer.add_theme_color_override("font_color",Color("#666b78"))
    shade.add_child(footer)

func _add_kiwi_mascot(parent: Control, center: Vector2) -> void:
    var kiwi := Polygon2D.new()
    kiwi.position = center
    kiwi.polygon = PackedVector2Array([Vector2(-48,-30),Vector2(-30,-52),Vector2(0,-58),Vector2(31,-45),Vector2(49,-17),Vector2(43,22),Vector2(20,49),Vector2(-14,54),Vector2(-43,34),Vector2(-55,0)])
    kiwi.color = Color("#9bcf4a")
    parent.add_child(kiwi)
    var belly := Polygon2D.new()
    belly.position = center + Vector2(0,8)
    belly.polygon = PackedVector2Array([Vector2(-34,-8),Vector2(-20,-29),Vector2(12,-34),Vector2(34,-10),Vector2(30,19),Vector2(8,37),Vector2(-22,28),Vector2(-38,7)])
    belly.color = Color("#d8ed9a")
    parent.add_child(belly)
    var leaf := Polygon2D.new()
    leaf.position = center + Vector2(0,-51)
    leaf.polygon = PackedVector2Array([Vector2(-4,4),Vector2(0,-27),Vector2(23,-17),Vector2(10,2)])
    leaf.color = Color("#65a94c")
    parent.add_child(leaf)
    for eye_x in [-18,12]:
        var eye := ColorRect.new()
        eye.position = center + Vector2(eye_x,-9)
        eye.size = Vector2(8,13)
        eye.color = Color("#20252b")
        parent.add_child(eye)
    var smile := ColorRect.new()
    smile.position = center + Vector2(-4,17)
    smile.size = Vector2(13,4)
    smile.color = Color("#52643b")
    parent.add_child(smile)

func _show_mode_menu() -> void:
    _show_panel("ВЫБОР РЕЖИМА",[
        ["ИГРАТЬ ОНЛАЙН",Callable(self,"_show_online_info")],
        ["ПРОТИВ БОТОВ",Callable(self,"_show_difficulty_menu")],
        ["ТРЕНИРОВКА",Callable(self,"_start_training")],
        ["НАЗАД",Callable(self,"_show_main_menu")]
    ],"Выбери, как хочешь играть")

func _show_difficulty_menu() -> void:
    _show_panel("СЛОЖНОСТЬ БОТОВ",[
        ["ЛЁГКАЯ",Callable(self,"_set_easy")],
        ["ОБЫЧНАЯ",Callable(self,"_set_normal")],
        ["СЛОЖНАЯ",Callable(self,"_set_hard")],
        ["НАЗАД",Callable(self,"_show_mode_menu")]
    ],"Сейчас: " + bot_difficulty.to_upper())

func _set_easy() -> void:
    bot_difficulty = "easy"
    bot_accuracy = 0.38
    _start_game("bot")

func _set_normal() -> void:
    bot_difficulty = "normal"
    bot_accuracy = 0.64
    _start_game("bot")

func _set_hard() -> void:
    bot_difficulty = "hard"
    bot_accuracy = 0.88
    _start_game("bot")

func _start_training() -> void:
    _start_game("training")
    _open_training_cards()

func _show_online_info() -> void:
    _show_panel("ОНЛАЙН",[
        ["НАЗАД",Callable(self,"_show_mode_menu")]
    ],"Сетевой матчмейкинг ещё не подключён. Этот пункт подготовлен для будущего онлайн-режима.")

func _show_pause_menu() -> void:
    phase = "paused"
    player.set_physics_process(false)
    rival.set_physics_process(false)
    _show_panel("ПАУЗА",[
        ["ПРОДОЛЖИТЬ",Callable(self,"_resume_game")],
        ["КАРТОЧКИ",Callable(self,"_open_training_cards")],
        ["В ГЛАВНОЕ МЕНЮ",Callable(self,"_show_main_menu")]
    ],"Игра приостановлена")

func _resume_game() -> void:
    _close_overlay()
    player.set_physics_process(true)
    rival.set_physics_process(true)
    phase = "fight"
    game_controls.visible = true

func _show_settings() -> void:
    _show_panel("НАСТРОЙКИ",[
        ["ЗВУК: " + ("ВКЛ" if sound_enabled else "ВЫКЛ"),Callable(self,"_toggle_sound")],
        ["ГРОМКОСТЬ: " + str(roundi(sound_level*100)) + "%  ↻",Callable(self,"_cycle_volume")],
        ["ВИБРАЦИЯ: " + ("ВКЛ" if vibration_enabled else "ВЫКЛ"),Callable(self,"_toggle_vibration")],
        ["ТРЯСКА КАМЕРЫ: " + ("ВКЛ" if shake_enabled else "ВЫКЛ"),Callable(self,"_toggle_shake")],
        ["РАСКЛАДКА: " + ("ЛЕВША" if controls_mirrored else "ПРАВША"),Callable(self,"_toggle_controls")],
        ["НАЗАД",Callable(self,"_show_main_menu")]
    ],"Настройки применяются сразу. Нажми на громкость, чтобы переключить уровень.")

func _toggle_sound() -> void:
    sound_enabled = not sound_enabled
    sound_level = 0.72 if sound_enabled else 0.0
    _apply_audio_settings()
    _show_settings()

func _toggle_vibration() -> void:
    vibration_enabled = not vibration_enabled
    _show_settings()

func _cycle_volume() -> void:
    if sound_level <= 0.001:
        sound_level = 0.35
    elif sound_level < 0.5:
        sound_level = 0.72
    else:
        sound_level = 1.0
    sound_enabled = sound_level > 0.001
    _apply_audio_settings()
    _show_settings()

func _toggle_shake() -> void:
    shake_enabled = not shake_enabled
    _show_settings()

func _toggle_controls() -> void:
    controls_mirrored = not controls_mirrored
    _apply_control_layout()
    _show_settings()

func _open_skins() -> void:
    if phase == "fight":
        skin_return_to_game = true
        phase = "paused"
        player.set_physics_process(false)
        rival.set_physics_process(false)
    else:
        skin_return_to_game = false
    var skins := _get_skins()
    _close_overlay()
    game_controls.visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#101116")
    ui.add_child(shade)
    overlay = shade
    var title := Label.new()
    title.text = "ВЫБОР БОЙЦА"
    title.position = Vector2(0,28)
    title.size = Vector2(1280,58)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",40)
    title.add_theme_color_override("font_color",Color("#f3f1e8"))
    shade.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "КАЖДЫЙ ЦВЕТ — ТВОЙ СТИЛЬ. ВЫБЕРИ СВОЙ."
    subtitle.position = Vector2(0,85)
    subtitle.size = Vector2(1280,28)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size",14)
    subtitle.add_theme_color_override("font_color",Color("#a7a9b2"))
    shade.add_child(subtitle)
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(65,135)
    scroll.size = Vector2(1150,465)
    shade.add_child(scroll)
    var grid := GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation",16)
    grid.add_theme_constant_override("v_separation",16)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(grid)
    for i in range(skins.size()):
        var skin: Dictionary = skins[i]
        var color := Color.from_string(str(skin.get("color","#39d6c5")),Color("#39d6c5"))
        var card := PanelContainer.new()
        card.custom_minimum_size = Vector2(265,300)
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#30352b") if i == skin_index else Color("#20242e")
        style.border_color = Color("#d9ef70") if i == skin_index else Color("#454b5b")
        style.set_border_width_all(3 if i == skin_index else 1)
        style.set_corner_radius_all(18)
        card.add_theme_stylebox_override("panel",style)
        var column := VBoxContainer.new()
        column.alignment = BoxContainer.ALIGNMENT_CENTER
        column.add_theme_constant_override("separation",8)
        card.add_child(column)
        var preview_area := Control.new()
        preview_area.custom_minimum_size = Vector2(235,175)
        column.add_child(preview_area)
        var fighter: ArenaPlayer = PLAYER_SCRIPT.new()
        fighter.body_color = color
        fighter.scale = Vector2(1.45,1.45)
        fighter.position = Vector2(117,105)
        fighter.set_physics_process(false)
        fighter.set_process(false)
        preview_area.add_child(fighter)
        var name_label := Label.new()
        name_label.text = str(skin.get("name",skin.get("id","MOD")))
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size",19)
        name_label.add_theme_color_override("font_color",Color("#f3f1e8"))
        column.add_child(name_label)
        var choose := Button.new()
        choose.text = "ЭКИПИРОВАНО  ✓" if i == skin_index else "ВЫБРАТЬ"
        choose.custom_minimum_size = Vector2(220,45)
        choose.add_theme_stylebox_override("normal",_menu_button_style(Color("#596b32") if i == skin_index else Color("#303644"),Color("#d9ef70") if i == skin_index else Color("#596174")))
        choose.pressed.connect(_select_skin.bind(i))
        column.add_child(choose)
        grid.add_child(card)
    var back := _add_button("НАЗАД",Vector2(500,625),Vector2(280,58),shade)
    back.add_theme_stylebox_override("normal",_menu_button_style(Color("#303644"),Color("#d9ef70")))
    back.pressed.connect(_apply_skin_and_return)

func _select_skin(index: int) -> void:
    skin_index = index
    _apply_skin()
    _open_skins()

func _previous_skin() -> void:
    skin_index -= 1
    _apply_skin()
    _open_skins()

func _apply_skin_and_return() -> void:
    _apply_skin()
    if skin_return_to_game:
        skin_return_to_game = false
        _resume_game()
    else:
        _show_main_menu()

func _open_mods() -> void:
    _get_skins()
    _close_overlay()
    game_controls.visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#101722")
    ui.add_child(shade)
    overlay = shade
    var title := Label.new()
    title.text = "МАСТЕР МОДОВ"
    title.position = Vector2(0,24)
    title.size = Vector2(1280,58)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",38)
    title.add_theme_color_override("font_color",Color("#f4f7ff"))
    shade.add_child(title)
    var summary := Label.new()
    summary.text = "Модов: %d   •   Скинов: %d   •   Арен: %d   •   Карточек: %d" % [mod_loader.loaded_mod_names.size(),mod_loader.skins.size(),mod_loader.maps.size(),mod_loader.upgrades.size()]
    summary.position = Vector2(80,88)
    summary.size = Vector2(1120,30)
    summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    summary.add_theme_font_size_override("font_size",17)
    summary.add_theme_color_override("font_color",Color("#b9e36c"))
    shade.add_child(summary)
    var help := Label.new()
    help.text = "Вставь JSON мода из буфера обмена. Он сохранится внутри игры на телефоне."
    help.position = Vector2(100,125)
    help.size = Vector2(1080,34)
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_font_size_override("font_size",15)
    help.add_theme_color_override("font_color",Color("#a7b1c2"))
    shade.add_child(help)
    mod_json_input = TextEdit.new()
    mod_json_input.position = Vector2(120,170)
    mod_json_input.size = Vector2(1040,365)
    mod_json_input.text = '{"name":"Мой мод","skins":[{"name":"Мятный","color":"#39d6c5"}],"maps":[{"name":"Моя арена","platforms":[{"x":300,"y":550,"w":180,"h":22},{"x":950,"y":550,"w":180,"h":22}]}],"upgrades":[]}'
    mod_json_input.add_theme_font_size_override("font_size",16)
    mod_json_input.add_theme_color_override("font_color",Color("#e9eef8"))
    mod_json_input.add_theme_color_override("background_color",Color("#202938"))
    mod_json_input.add_theme_color_override("caret_color",Color("#d9ef70"))
    shade.add_child(mod_json_input)
    var status := Label.new()
    status.text = mod_status_message
    status.position = Vector2(100,545)
    status.size = Vector2(1080,30)
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size",14)
    status.add_theme_color_override("font_color",Color("#d9ef70"))
    shade.add_child(status)
    var import_button := _add_button("ИМПОРТИРОВАТЬ",Vector2(260,590),Vector2(260,58),shade)
    import_button.add_theme_stylebox_override("normal",_menu_button_style(Color("#596b32"),Color("#d9ef70")))
    import_button.add_theme_color_override("font_color",Color("#ffffff"))
    import_button.pressed.connect(_import_mod_from_text)
    var reload_button_ui := _add_button("ОБНОВИТЬ",Vector2(520,590),Vector2(220,58),shade)
    reload_button_ui.pressed.connect(_reload_mods)
    var back := _add_button("НАЗАД",Vector2(760,590),Vector2(220,58),shade)
    back.pressed.connect(_show_main_menu)
    var footer := Label.new()
    footer.text = "ПОДДЕРЖИВАЮТСЯ СКИНЫ, АРЕНЫ И КАРТОЧКИ С ГОТОВЫМИ ЭФФЕКТАМИ"
    footer.position = Vector2(0,675)
    footer.size = Vector2(1280,24)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size",12)
    footer.add_theme_color_override("font_color",Color("#626875"))
    shade.add_child(footer)

func _import_mod_from_text() -> void:
    if not is_instance_valid(mod_json_input):
        return
    var parsed: Variant = JSON.parse_string(mod_json_input.text)
    if typeof(parsed) != TYPE_DICTIONARY:
        mod_status_message = "Ошибка: проверь JSON — скобки, кавычки и запятые."
        _open_mods()
        return
    if not parsed.has("name"):
        mod_status_message = "Ошибка: у мода должно быть поле name."
        _open_mods()
        return
    var directory := DirAccess.open("user://")
    if directory == null:
        mod_status_message = "Не удалось открыть папку данных игры."
        _open_mods()
        return
    var make_error := directory.make_dir_recursive("mods/quick_import")
    if make_error != OK and make_error != ERR_ALREADY_EXISTS:
        mod_status_message = "Не удалось создать папку для мода."
        _open_mods()
        return
    var file := FileAccess.open("user://mods/quick_import/mod.json",FileAccess.WRITE)
    if file == null:
        mod_status_message = "Не удалось сохранить mod.json."
        _open_mods()
        return
    file.store_string(mod_json_input.text)
    file.close()
    mod_status_message = "Мод сохранён. Проверяю его содержимое..."
    _reload_mods()

func _reload_mods() -> void:
    if mod_loader == null:
        mod_loader = MOD_LOADER_SCRIPT.new()
    mod_loader.load_all()
    mods_loaded = true
    all_maps.assign(DEFAULT_MAPS)
    all_maps.append_array(mod_loader.maps)
    all_upgrades.assign(DEFAULT_UPGRADES)
    all_upgrades.append_array(mod_loader.upgrades)
    _apply_skin()
    mod_status_message = "Загрузка завершена: %d модов, %d скинов, %d арен, %d карточек. Предупреждений: %d." % [mod_loader.loaded_mod_names.size(),mod_loader.skins.size(),mod_loader.maps.size(),mod_loader.upgrades.size(),mod_loader.warnings.size()]
    _open_mods()

func _open_training_cards() -> void:
    if game_mode != "training":
        _show_panel("КАРТОЧКИ",[
            ["ОТКРЫТЬ ТРЕНИРОВКУ",Callable(self,"_start_training")],
            ["НАЗАД",Callable(self,"_resume_game")]
        ],"Карточки и выбор арены доступны в тренировке.")
        return
    phase = "paused"
    player.set_physics_process(false)
    rival.set_physics_process(false)
    _close_overlay()
    game_controls.visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#101722")
    ui.add_child(shade)
    overlay = shade
    var title := Label.new()
    title.text = "ТРЕНИРОВКА"
    title.position = Vector2(0,24)
    title.size = Vector2(1280,55)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",36)
    title.add_theme_color_override("font_color",Color("#f4f7ff"))
    shade.add_child(title)
    var tabs := HBoxContainer.new()
    tabs.position = Vector2(330,90)
    tabs.size = Vector2(620,55)
    tabs.add_theme_constant_override("separation",14)
    shade.add_child(tabs)
    var upgrades_tab := Button.new()
    upgrades_tab.text = "КАРТОЧКИ"
    upgrades_tab.custom_minimum_size = Vector2(300,52)
    upgrades_tab.pressed.connect(_set_training_tab.bind("cards"))
    tabs.add_child(upgrades_tab)
    var maps_tab := Button.new()
    maps_tab.text = "ВЫБОР АРЕНЫ"
    maps_tab.custom_minimum_size = Vector2(300,52)
    maps_tab.pressed.connect(_set_training_tab.bind("maps"))
    tabs.add_child(maps_tab)
    if training_tab == "maps":
        _get_skins()
        _build_training_maps(shade)
    else:
        _build_upgrade_cards(shade)
    var done := _add_button("ГОТОВО",Vector2(500,635),Vector2(280,58),shade)
    done.pressed.connect(_resume_game)

func _set_training_tab(tab: String) -> void:
    training_tab = tab
    _open_training_cards()

func _build_upgrade_cards(shade: Control) -> void:
    var info := Label.new()
    info.text = "СОБЕРИ СВОЙ БИЛД  •  УСИЛЕНИЯ И ОСЛАБЛЕНИЯ"
    info.position = Vector2(0,145)
    info.size = Vector2(1280,28)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size",15)
    info.add_theme_color_override("font_color",Color("#a7a9b2"))
    shade.add_child(info)
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(55,185)
    scroll.size = Vector2(1170,425)
    shade.add_child(scroll)
    var grid := GridContainer.new()
    grid.columns = 3
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation",16)
    grid.add_theme_constant_override("v_separation",16)
    scroll.add_child(grid)
    for card in all_upgrades:
        var id := str(card.get("effect",card.get("id","")))
        var active := active_training_cards.has(id)
        var panel := PanelContainer.new()
        panel.custom_minimum_size = Vector2(355,385)
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#30352b") if active else Color("#20242e")
        style.border_color = Color("#d9ef70") if active else Color("#454b5b")
        style.set_border_width_all(3 if active else 1)
        style.set_corner_radius_all(18)
        panel.add_theme_stylebox_override("panel",style)
        var column := VBoxContainer.new()
        column.alignment = BoxContainer.ALIGNMENT_CENTER
        column.add_theme_constant_override("separation",10)
        panel.add_child(column)
        var art_area := Panel.new()
        art_area.custom_minimum_size = Vector2(315,125)
        var art_style := StyleBoxFlat.new()
        art_style.bg_color = Color("#343b2b") if active else Color("#292f3c")
        art_style.set_corner_radius_all(12)
        art_area.add_theme_stylebox_override("panel",art_style)
        column.add_child(art_area)
        var art := Polygon2D.new()
        art.position = Vector2(157,58)
        art.color = Color("#d9ef70") if active else Color("#a9b3c7")
        match id:
            "swift":
                art.polygon = PackedVector2Array([Vector2(-58,-15),Vector2(10,-15),Vector2(10,-34),Vector2(62,0),Vector2(10,34),Vector2(10,15),Vector2(-58,15)])
            "spring":
                art.polygon = PackedVector2Array([Vector2(-38,-42),Vector2(38,-42),Vector2(-15,-14),Vector2(38,-14),Vector2(-15,14),Vector2(38,14),Vector2(10,42),Vector2(-38,42),Vector2(-10,14),Vector2(-45,14),Vector2(-15,-14)])
            "wave":
                art.polygon = PackedVector2Array([Vector2(0,-48),Vector2(18,-15),Vector2(52,-12),Vector2(25,10),Vector2(34,45),Vector2(0,25),Vector2(-34,45),Vector2(-25,10),Vector2(-52,-12),Vector2(-18,-15)])
            "rapid":
                art.polygon = PackedVector2Array([Vector2(10,-48),Vector2(-35,8),Vector2(-8,8),Vector2(-22,48),Vector2(38,-14),Vector2(10,-14)])
            "sturdy":
                art.polygon = PackedVector2Array([Vector2(0,-47),Vector2(42,-25),Vector2(34,20),Vector2(0,49),Vector2(-34,20),Vector2(-42,-25)])
            _:
                art.polygon = PackedVector2Array([Vector2(-40,-40),Vector2(40,-40),Vector2(40,40),Vector2(-40,40)])
        art_area.add_child(art)
        var icon_label := Label.new()
        icon_label.text = str(card.get("icon",""))
        icon_label.position = Vector2(0,91)
        icon_label.size = Vector2(315,24)
        icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon_label.add_theme_font_size_override("font_size",13)
        icon_label.add_theme_color_override("font_color",Color("#f3f1e8"))
        art_area.add_child(icon_label)
        var name_label := Label.new()
        name_label.text = str(card.get("name",id))
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size",18)
        name_label.add_theme_color_override("font_color",Color("#f3f1e8"))
        column.add_child(name_label)
        var buff := Label.new()
        buff.text = "▲  " + str(card.get("buff",card.get("desc","")))
        buff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        buff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        buff.add_theme_font_size_override("font_size",13)
        buff.add_theme_color_override("font_color",Color("#b9e36c"))
        column.add_child(buff)
        var debuff := Label.new()
        debuff.text = "▼  " + str(card.get("debuff","МИНУС  Нет"))
        debuff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        debuff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        debuff.add_theme_font_size_override("font_size",13)
        debuff.add_theme_color_override("font_color",Color("#ff897d"))
        column.add_child(debuff)
        var choose := Button.new()
        choose.text = "ВЫБРАНО  ✓" if active else "ВЫБРАТЬ КАРТУ"
        choose.custom_minimum_size = Vector2(290,44)
        choose.add_theme_stylebox_override("normal",_menu_button_style(Color("#596b32") if active else Color("#343b4b"),Color("#d9ef70") if active else Color("#667087")))
        choose.pressed.connect(_toggle_training_card.bind(id))
        column.add_child(choose)
        grid.add_child(panel)

func _build_training_maps(shade: Control) -> void:
    var info := Label.new()
    info.text = "Выбери арену — она сменится сразу, пока бой на паузе."
    info.position = Vector2(0,155)
    info.size = Vector2(1280,32)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size",17)
    info.add_theme_color_override("font_color",Color("#aab8cc"))
    shade.add_child(info)
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(90,200)
    scroll.size = Vector2(1100,410)
    shade.add_child(scroll)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation",20)
    grid.add_theme_constant_override("v_separation",18)
    scroll.add_child(grid)
    for i in range(all_maps.size()):
        var map_data: Dictionary = all_maps[i]
        var panel := PanelContainer.new()
        panel.custom_minimum_size = Vector2(510,180)
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#244d4c") if i == map_index else Color("#202e42")
        style.border_color = Color("#64d6bd") if i == map_index else Color("#526b8c")
        style.set_border_width_all(2)
        style.set_corner_radius_all(14)
        panel.add_theme_stylebox_override("panel",style)
        var column := VBoxContainer.new()
        column.add_theme_constant_override("separation",8)
        panel.add_child(column)
        var name_label := Label.new()
        name_label.text = str(map_data.get("name","Арена")) + ("  ✓" if i == map_index else "")
        name_label.add_theme_font_size_override("font_size",20)
        name_label.add_theme_color_override("font_color",Color("#f4f7ff"))
        column.add_child(name_label)
        var preview := Control.new()
        preview.custom_minimum_size = Vector2(460,72)
        column.add_child(preview)
        var ground := ColorRect.new()
        ground.position = Vector2(0,60)
        ground.size = Vector2(460,10)
        ground.color = Color("#506b89")
        preview.add_child(ground)
        var platforms: Array = map_data.get("platforms",[])
        for platform_value in platforms:
            var platform: Dictionary = platform_value
            var bar := ColorRect.new()
            var px := clampf(float(platform.get("x",640))/1280.0*440.0-20.0,0.0,420.0)
            var py := clampf(float(platform.get("y",500))/720.0*58.0,5.0,50.0)
            var pw := clampf(float(platform.get("w",180))/1280.0*440.0,24.0,130.0)
            bar.position = Vector2(px,py)
            bar.size = Vector2(pw,6)
            bar.color = Color("#70d7c3") if i == map_index else Color("#8da9cb")
            preview.add_child(bar)
        var select := Button.new()
        select.text = "ВЫБРАНА" if i == map_index else "ВЫБРАТЬ ЭТУ АРЕНУ"
        select.custom_minimum_size = Vector2(440,38)
        select.pressed.connect(_select_training_map.bind(i))
        column.add_child(select)
        grid.add_child(panel)

func _select_training_map(index: int) -> void:
    if all_maps.is_empty():
        return
    map_index = posmod(index,all_maps.size())
    _make_arena(map_index)
    player.reset_round(Vector2(350,390))
    rival.reset_round(Vector2(930,390))
    _open_training_cards()

func _toggle_training_card(card_id: String) -> void:
    if active_training_cards.has(card_id):
        active_training_cards.erase(card_id)
    else:
        active_training_cards.append(card_id)
    _reset_player_stats(player)
    for active_id in active_training_cards:
        player.apply_upgrade(active_id)
    _open_training_cards()

func _show_panel(title_text: String, buttons: Array, subtitle: String = "") -> void:
    _close_overlay()
    game_controls.visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#101116")
    ui.add_child(shade)
    overlay = shade
    var panel := Panel.new()
    panel.position = Vector2(300,45)
    panel.size = Vector2(680,630)
    var ps := StyleBoxFlat.new()
    ps.bg_color = Color("#1c2029")
    ps.border_color = Color("#414858")
    ps.set_border_width_all(2)
    ps.set_corner_radius_all(24)
    panel.add_theme_stylebox_override("panel",ps)
    shade.add_child(panel)
    var title := Label.new()
    title.text = title_text
    title.position = Vector2(0,78)
    title.size = Vector2(1280,75)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",42)
    title.add_theme_color_override("font_color",Color("#f3f1e8"))
    shade.add_child(title)
    var accent := ColorRect.new()
    accent.position = Vector2(535,166)
    accent.size = Vector2(210,4)
    accent.color = Color("#d9ef70")
    shade.add_child(accent)
    if subtitle != "":
        var info := Label.new()
        info.text = subtitle
        info.position = Vector2(340,185)
        info.size = Vector2(600,75)
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        info.add_theme_font_size_override("font_size",16)
        info.add_theme_color_override("font_color",Color("#a7a9b2"))
        shade.add_child(info)
    var list := VBoxContainer.new()
    var compact := buttons.size() > 4
    list.position = Vector2(390,265 if compact else 285)
    list.size = Vector2(500,390 if compact else 340)
    list.add_theme_constant_override("separation",8 if compact else 12)
    shade.add_child(list)
    for entry in buttons:
        var button := Button.new()
        button.text = str(entry[0])
        button.custom_minimum_size = Vector2(500,50 if compact else 58)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.focus_mode = Control.FOCUS_NONE
        button.add_theme_font_size_override("font_size",20)
        button.add_theme_color_override("font_color",Color("#f3f1e8"))
        button.add_theme_stylebox_override("normal",_menu_button_style(Color("#303644"),Color("#596174")))
        button.add_theme_stylebox_override("hover",_menu_button_style(Color("#414a5b"),Color("#d9ef70")))
        button.add_theme_stylebox_override("pressed",_menu_button_style(Color("#596b32"),Color("#d9ef70")))
        button.pressed.connect(entry[1])
        list.add_child(button)
    var footer := Label.new()
    footer.text = "KIWI ROUNDS  /  ARENA PROTOTYPE"
    footer.position = Vector2(0,675)
    footer.size = Vector2(1280,24)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size",12)
    footer.add_theme_color_override("font_color",Color("#626875"))
    shade.add_child(footer)

func _menu_button_style(fill: Color, outline: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = outline
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    style.content_margin_left = 18
    style.content_margin_right = 18
    return style

func _close_overlay() -> void:
    if is_instance_valid(overlay):
        overlay.queue_free()
    overlay = null

func _finish_round(player_won: bool) -> void:
    if phase != "fight":
        return
    _clear_pulses()
    phase = "upgrade"
    player.set_physics_process(false)
    rival.set_physics_process(false)
    if player_won:
        score_player += 1
    else:
        score_bot += 1
    _update_hud()
    if score_player >= 3 or score_bot >= 3:
        _show_match_end()
    elif game_mode == "training":
        _show_training_round_end()
    else:
        _show_upgrade_panel()

func _update_hud() -> void:
    if is_instance_valid(hud):
        hud.text = "ТРЕНИРОВКА" if game_mode == "training" else "РАУНД %d     ТЫ  %d : %d  CPU" % [round_index,score_player,score_bot]

func _show_training_round_end() -> void:
    _show_panel("РАУНД ЗАВЕРШЁН",[
        ["КАРТОЧКИ",Callable(self,"_open_training_cards")],
        ["СЛЕДУЮЩИЙ РАУНД",Callable(self,"_next_round")],
        ["В ГЛАВНОЕ МЕНЮ",Callable(self,"_show_main_menu")]
    ],"В тренировке можно свободно выдавать и убирать карточки.")

func _show_upgrade_panel() -> void:
    var choices: Array = all_upgrades.duplicate(true)
    choices.shuffle()
    var buttons: Array = []
    for i in range(mini(3,choices.size())):
        var item: Dictionary = choices[i]
        buttons.append([str(item.get("name",item.get("id","Улучшение"))) + "\n" + str(item.get("desc","")),Callable(self,"_choose_upgrade").bind(str(item.get("effect",item.get("id",""))))])
    _show_panel("ВЫБЕРИ УЛУЧШЕНИЕ",buttons,"После выбора начнётся следующий раунд")

func _choose_upgrade(upgrade_id: String) -> void:
    player.apply_upgrade(upgrade_id)
    if not all_upgrades.is_empty():
        var bot_choice: Dictionary = all_upgrades.pick_random()
        rival.apply_upgrade(str(bot_choice.get("effect",bot_choice.get("id",""))))
    _next_round()

func _next_round() -> void:
    _clear_pulses()
    _close_overlay()
    player.set_physics_process(true)
    rival.set_physics_process(true)
    round_index += 1
    _make_arena(round_index - 1)
    player.reset_round(Vector2(350,390))
    rival.reset_round(Vector2(930,390))
    phase = "fight"
    game_controls.visible = true
    _update_hud()

func _show_match_end() -> void:
    var result := "ПОБЕДА!" if score_player >= 3 else "ПОБЕДИЛ CPU"
    _show_panel(result,[
        ["СЫГРАТЬ ЕЩЁ",Callable(self,"_restart_match")],
        ["ГЛАВНОЕ МЕНЮ",Callable(self,"_show_main_menu")]
    ],"Счёт: %d : %d" % [score_player,score_bot])

func _restart_match() -> void:
    _start_game(game_mode)
