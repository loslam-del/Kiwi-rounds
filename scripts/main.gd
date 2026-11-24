extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PULSE_SCRIPT = preload("res://scripts/pulse.gd")
const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
const ACTION_BUTTON_SCRIPT = preload("res://scripts/virtual_action_button.gd")
const MOD_LOADER_SCRIPT = preload("res://scripts/mod_loader.gd")

const DEFAULT_UPGRADES := [
    {"id":"swift","name":"ТУРБО-ШАГ","icon":"↗","art":"dash","primary":"Рывковая мобильность","buff":"СКОРОСТЬ +18%","debuff":"ВЫСОТА ПРЫЖКА −6%","effect":"swift"},
    {"id":"spring","name":"ПРУЖИНА","icon":"↟","art":"spring","primary":"Усиленный прыжок","buff":"ПРЫЖОК +18%","debuff":"СКОРОСТЬ −7%","effect":"spring"},
    {"id":"feather","name":"ЛЁГКОСТЬ","icon":"✦","art":"feather","primary":"Низкая гравитация","buff":"ГРАВИТАЦИЯ −18%","debuff":"МЕДЛЕННЕЕ ПАДЕНИЕ","effect":"feather"},
    {"id":"wall","name":"СТЕНКА-РАКЕТКА","icon":"↶","art":"wall","primary":"Сильный отскок от стен","buff":"ОТТАЛКИВАНИЕ ОТ СТЕН +22%","debuff":"МЕНЬШЕ КОНТРОЛЯ В ВОЗДУХЕ","effect":"wall"},
    {"id":"air","name":"ВОЗДУШНЫЙ ШАГ","icon":"＋","art":"air","primary":"Дополнительный прыжок","buff":"ЕЩЁ ОДИН ПРЫЖОК В ВОЗДУХЕ","debuff":"СКОРОСТЬ −5%","effect":"air"},
    {"id":"grounded","name":"ТЯЖЁЛЫЕ БОТИНКИ","icon":"⬇","art":"boots","primary":"Ускорение на земле","buff":"УСКОРЕНИЕ НА ЗЕМЛЕ +22%","debuff":"ГРАВИТАЦИЯ −8%","effect":"grounded"},
    {"id":"homing","name":"ОХОТНИК","icon":"◎","art":"homing","primary":"САМОНАВОДКА СНАРЯДА","buff":"ПУЛЯ ПЛАВНО ДОВОРАЧИВАЕТ К ПРОТИВНИКУ","debuff":"СКОРОСТЬ СНАРЯДА −10%","effect":"homing"},
    {"id":"ricochet","name":"РЕЙКОШЕТ","icon":"⤴","art":"ricochet","primary":"РИКОШЕТ ×2","buff":"СНАРЯД ОТСКАКИВАЕТ ОТ СТЕН И ПЛАТФОРМ","debuff":"СИЛА ОТБРАСЫВАНИЯ −12%","effect":"ricochet"},
    {"id":"heavy","name":"ТЯЖЁЛЫЙ КАЛИБР","icon":"▰","art":"heavy","primary":"УСИЛЕННЫЙ ВЫСТРЕЛ","buff":"ОТБРАСЫВАНИЕ +24%","debuff":"СКОРОСТЬ СТРЕЛЬБЫ −15%","effect":"heavy"},
    {"id":"rapid","name":"ШТУРМОВОЙ МОДУЛЬ","icon":"»","art":"rapid","primary":"УСКОРЕННАЯ СТРЕЛЬБА","buff":"ПЕРЕЗАРЯДКА МЕЖДУ ВЫСТРЕЛАМИ −22%","debuff":"СИЛА ВЫСТРЕЛА −9%","effect":"rapid"},
    {"id":"magazine","name":"ДВОЙНОЙ МАГАЗИН","icon":"▥","art":"magazine","primary":"9 ЗАРЯДОВ В ОБОЙМЕ","buff":"МАГАЗИН +3 ПАТРОНА","debuff":"ПЕРЕЗАРЯДКА ДОЛЬШЕ +12%","effect":"magazine"},
    {"id":"piercing","name":"РАЗГОННЫЙ СТВОЛ","icon":"➤","art":"piercing","primary":"РАЗОГНАННЫЙ СНАРЯД","buff":"СКОРОСТЬ СНАРЯДА +22%","debuff":"ПЕРЕЗАРЯДКА ДОЛЬШЕ +16%","effect":"piercing"},
    {"id":"kiwi_charm","name":"ОБЕРЕГ КИВИ","icon":"✿","art":"kiwi","primary":"КОСМЕТИЧЕСКИЙ ЭФФЕКТ","buff":"ЗЕЛЁНЫЕ ЛИСТЬЯ И МЯГКОЕ СИЯНИЕ","debuff":"БЕЗ ИЗМЕНЕНИЯ ХАРАКТЕРИСТИК","effect":"kiwi_charm"}
]
const DEFAULT_MAPS := [
    {"name":"КОРОТКИЙ МОСТ","platforms":[{"x":330,"y":555,"w":230,"h":20},{"x":950,"y":555,"w":230,"h":20},{"x":640,"y":420,"w":170,"h":20},{"x":190,"y":430,"w":150,"h":18},{"x":1090,"y":430,"w":150,"h":18}]},
    {"name":"ДВЕ БАШНИ","platforms":[{"x":180,"y":590,"w":190,"h":20},{"x":180,"y":440,"w":150,"h":20},{"x":1100,"y":590,"w":190,"h":20},{"x":1100,"y":440,"w":150,"h":20},{"x":640,"y":520,"w":150,"h":20}]},
    {"name":"ЛЕСТНИЦА","platforms":[{"x":220,"y":600,"w":180,"h":20},{"x":420,"y":520,"w":170,"h":20},{"x":620,"y":440,"w":170,"h":20},{"x":820,"y":360,"w":170,"h":20},{"x":1050,"y":520,"w":180,"h":20}]},
    {"name":"ЦЕНТРАЛЬНЫЙ ОСТРОВ","platforms":[{"x":300,"y":560,"w":170,"h":20},{"x":980,"y":560,"w":170,"h":20},{"x":640,"y":500,"w":260,"h":22},{"x":640,"y":340,"w":150,"h":20}]},
    {"name":"РАЗЛОМ","platforms":[{"x":190,"y":560,"w":250,"h":20},{"x":1090,"y":560,"w":250,"h":20},{"x":450,"y":410,"w":150,"h":20},{"x":830,"y":410,"w":150,"h":20}]},
    {"name":"КРЕСТ","platforms":[{"x":640,"y":570,"w":340,"h":20},{"x":640,"y":390,"w":340,"h":20},{"x":390,"y":480,"w":150,"h":20},{"x":890,"y":480,"w":150,"h":20}]},
    {"name":"ПАРЯЩИЕ СТУПЕНИ","platforms":[{"x":250,"y":610,"w":170,"h":20},{"x":470,"y":510,"w":170,"h":20},{"x":690,"y":410,"w":170,"h":20},{"x":910,"y":510,"w":170,"h":20},{"x":1130,"y":610,"w":170,"h":20}]}
]

var player: ArenaPlayer
var rival: ArenaPlayer
var ui: Control
var hud: Label
var overlay: Control
var game_controls: Control
var skin_button: Button
var ammo_label: Label
var fire_button: VirtualActionButton
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
var selected_skin_style := "default"
var sound_enabled := true
var vibration_enabled := true
var boot_loading := true
var boot_elapsed := 0.0
var boot_angle := 0.0
var boot_stage := "Подготовка игры..."
var boot_status_label: Label
var mods_loaded := false
var arena_camera: Camera2D
var camera_shake_timer := 0.0
var camera_shake_strength := 0.0
var background_time := 0.0
var impact_flash := 0.0
var impact_flash_color := Color.WHITE
var shake_enabled := true
var controls_mirrored := false
var sound_level := 0.72
var movement_joystick: VirtualJoystick
var aim_joystick: VirtualJoystick
var reload_button: VirtualActionButton
var jump_button: VirtualActionButton
var menu_button: Button
var cards_button: Button
var mod_json_input: TextEdit
var mod_status_message := "Вставь JSON мода и нажми ИМПОРТИРОВАТЬ."
var mod_json_buffer := ""

func _ready() -> void:
    boot_status_label = get_node_or_null("StartupLayer/BootScreen/BootStatus") as Label
    randomize()
    _load_settings()
    queue_redraw()
    call_deferred("_boot_game")

func _load_settings() -> void:
    var config := ConfigFile.new()
    if config.load("user://settings.cfg") != OK:
        return
    sound_level = clampf(float(config.get_value("settings","sound_level",0.72)),0.0,1.0)
    sound_enabled = sound_level > 0.001
    vibration_enabled = bool(config.get_value("settings","vibration_enabled",true))
    shake_enabled = bool(config.get_value("settings","shake_enabled",true))
    controls_mirrored = bool(config.get_value("settings","controls_mirrored",false))
    skin_index = maxi(0,int(config.get_value("settings","skin_index",0)))

func _save_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("settings","sound_level",sound_level)
    config.set_value("settings","vibration_enabled",vibration_enabled)
    config.set_value("settings","shake_enabled",shake_enabled)
    config.set_value("settings","controls_mirrored",controls_mirrored)
    config.set_value("settings","skin_index",skin_index)
    config.save("user://settings.cfg")

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
    var startup_layer := get_node_or_null("StartupLayer")
    if startup_layer != null:
        startup_layer.queue_free()
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720),Color("#101723"))
    draw_rect(Rect2(0,0,1280,470),Color("#172234"))
    draw_rect(Rect2(0,470,1280,250),Color("#121a27"))
    for i in range(7):
        var y := 80.0 + float(i)*74.0
        draw_line(Vector2(0,y),Vector2(1280,y),Color(0.35,0.47,0.62,0.07),1.0)
    for i in range(25):
        var x := float((i*173+61)%1280)
        var base_y := float((i*97+43)%650)
        var y := fposmod(base_y + sin(background_time * 0.7 + float(i)) * 5.0, 660.0)
        var twinkle := 0.12 + (sin(background_time * 2.0 + float(i) * 1.7) + 1.0) * 0.09
        draw_circle(Vector2(x,y),1.5 if i%3==0 else 1.0,Color(0.72,0.88,1.0,twinkle))
    # Architectural light columns and a subtle animated arena grid.
    for i in range(13):
        var gx := 54.0 + float(i) * 98.0
        var sway := sin(background_time * 0.42 + float(i) * 0.7) * 10.0
        draw_line(Vector2(gx+sway,70),Vector2(gx-sway*0.5,680),Color(0.38,0.72,0.82,0.025),1.0)
    for i in range(6):
        var gy := 520.0 + float(i) * 28.0
        draw_line(Vector2(0,gy),Vector2(1280,gy),Color(0.45,0.72,0.84,0.035),1.0)
    for i in range(8):
        var orbit := 92.0 + float(i) * 22.0
        var phase_offset := background_time * (0.16 if i % 2 == 0 else -0.12)
        draw_arc(Vector2(640,435),orbit,phase_offset,phase_offset+PI*0.62,48,Color(0.42,0.82,0.78,0.045),1.2,true)
    # Soft arena halos and a faint central light column.
    draw_circle(Vector2(640,450),250.0,Color(0.28,0.62,0.68,0.025))
    draw_arc(Vector2(640,470),430,PI,TAU,80,Color(0.38,0.65,0.82,0.12),2.0,true)
    draw_arc(Vector2(640,470),520,PI,TAU,80,Color(0.38,0.55,0.77,0.06),2.0,true)
    draw_rect(Rect2(0,0,1280,5),Color("#d9ef70"))
    draw_rect(Rect2(0,700,1280,20),Color("#0b111b"))
    draw_line(Vector2(0,700),Vector2(1280,700),Color("#526a87"),2.0)
    if impact_flash > 0.0:
        draw_rect(Rect2(0,0,1280,720),Color(impact_flash_color, impact_flash * 0.13))
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
    wall.name = "ArenaSideWall"
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
    body.name = "ArenaPlatform"
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
    var glow := Line2D.new()
    glow.points = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2)])
    glow.width = 12.0
    glow.default_color = Color("#d9ef70",0.12)
    glow.antialiased = true
    body.add_child(glow)
    var stripe := Line2D.new()
    stripe.points = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2)])
    stripe.width = 3.5
    stripe.default_color = Color("#d9ef70")
    stripe.antialiased = true
    body.add_child(stripe)
    var edge := Line2D.new()
    edge.points = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,dimensions.y/2),Vector2(-dimensions.x/2,dimensions.y/2),Vector2(-dimensions.x/2,-dimensions.y/2)])
    edge.width = 1.2
    edge.default_color = Color("#8fb3d8",0.45)
    edge.antialiased = true
    body.add_child(edge)

func _make_players() -> void:
    player = PLAYER_SCRIPT.new()
    player.body_color = selected_skin_color
    player.skin_style = selected_skin_style
    player.position = Vector2(350,390)
    player.pulse_requested.connect(_spawn_pulse)
    player.got_hit.connect(_on_player_hit)
    player.reload_started.connect(_play_sfx.bind("reload"))
    add_child(player)
    rival = PLAYER_SCRIPT.new()
    rival.is_bot = true
    rival.body_color = Color("#ff786f")
    rival.position = Vector2(930,390)
    rival.target = player
    player.target = rival
    rival.pulse_requested.connect(_spawn_pulse)
    rival.got_hit.connect(_on_player_hit)
    rival.reload_started.connect(_play_sfx.bind("reload"))
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
        {"name":"Розовый","color":"#ff78b7"},
        {"id":"kiwi_araga","name":"Киви Арага","color":"#f2e5ce","style":"kiwi"}
    ]
    skins.append_array(mod_loader.skins)
    return skins

func _apply_skin() -> void:
    var skins: Array[Dictionary] = [
        {"name":"Бирюзовый","color":"#39d6c5"},
        {"name":"Лазурный","color":"#4b9cff"},
        {"name":"Фиолетовый","color":"#b47cff"},
        {"name":"Золотой","color":"#ffc857"},
        {"name":"Розовый","color":"#ff78b7"},
        {"id":"kiwi_araga","name":"Киви Арага","color":"#f2e5ce","style":"kiwi"}
    ]
    if mods_loaded and mod_loader != null:
        skins.append_array(mod_loader.skins)
    if skins.is_empty():
        return
    skin_index = posmod(skin_index, skins.size())
    var skin: Dictionary = skins[skin_index]
    selected_skin_color = Color.from_string(str(skin.get("color","#39d6c5")),Color("#39d6c5"))
    selected_skin_style = str(skin.get("style","default"))
    if is_instance_valid(player):
        player.body_color = selected_skin_color
        player.skin_style = selected_skin_style
        player.queue_redraw()
    if is_instance_valid(skin_button):
        skin_button.text = "СКИН: " + str(skin.get("name",skin.get("id","MOD")))
    _save_settings()

func _cycle_skin() -> void:
    skin_index += 1
    _apply_skin()

func _on_player_hit(_direction: Vector2, hit_target: Node2D) -> void:
    if shake_enabled:
        camera_shake_timer = 0.16
        camera_shake_strength = 9.0
    impact_flash = 0.12
    impact_flash_color = Color("#ff806f") if hit_target == player else Color("#72e6d3")
    queue_redraw()
    _play_sfx("hit")
    if hit_target == player and vibration_enabled:
        Input.vibrate_handheld(55,0.25)

func _clear_control_inputs() -> void:
    if is_instance_valid(player):
        player.clear_touch_controls()
    if is_instance_valid(movement_joystick):
        movement_joystick.cancel_input()
    if is_instance_valid(aim_joystick):
        aim_joystick.cancel_input()
    if is_instance_valid(fire_button):
        fire_button.cancel_input()
    if is_instance_valid(jump_button):
        jump_button.cancel_input()
    if is_instance_valid(reload_button):
        reload_button.cancel_input()

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
    hud.position = Vector2(0,12)
    hud.size = Vector2(1280,42)
    hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_theme_font_size_override("font_size",22)
    hud.add_theme_color_override("font_color",Color("#f4f7ff"))
    ui.add_child(hud)
    game_controls = Control.new()
    game_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(game_controls)
    skin_button = _add_button("СКИН",Vector2(1080,18),Vector2(150,50),game_controls)
    skin_button.pressed.connect(_open_skins)
    movement_joystick = JOYSTICK_SCRIPT.new()
    movement_joystick.position = Vector2(28,575)
    movement_joystick.size = Vector2(116,116)
    movement_joystick.value_changed.connect(player.set_move)
    game_controls.add_child(movement_joystick)
    fire_button = ACTION_BUTTON_SCRIPT.new()
    fire_button.caption = "ВЫСТРЕЛ"
    fire_button.position = Vector2(32,490)
    fire_button.size = Vector2(116,52)
    fire_button.button_down.connect(player.set_fire.bind(true))
    fire_button.button_up.connect(player.set_fire.bind(false))
    game_controls.add_child(fire_button)
    reload_button = ACTION_BUTTON_SCRIPT.new()
    reload_button.caption = "ПЕРЕЗАРЯДКА"
    reload_button.position = Vector2(164,625)
    reload_button.size = Vector2(132,48)
    reload_button.pressed.connect(player.start_reload)
    game_controls.add_child(reload_button)
    ammo_label = Label.new()
    ammo_label.position = Vector2(158,590)
    ammo_label.size = Vector2(150,28)
    ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ammo_label.add_theme_font_size_override("font_size",14)
    ammo_label.add_theme_color_override("font_color",Color("#f4f7ff"))
    game_controls.add_child(ammo_label)
    aim_joystick = JOYSTICK_SCRIPT.new()
    aim_joystick.position = Vector2(1136,575)
    aim_joystick.size = Vector2(116,116)
    aim_joystick.value_changed.connect(player.set_aim)
    game_controls.add_child(aim_joystick)
    jump_button = ACTION_BUTTON_SCRIPT.new()
    jump_button.caption = "ПРЫЖОК"
    jump_button.position = Vector2(1136,490)
    jump_button.size = Vector2(112,52)
    jump_button.button_down.connect(player.set_jump.bind(true))
    jump_button.button_up.connect(player.set_jump.bind(false))
    game_controls.add_child(jump_button)
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
        movement_joystick.position = Vector2(1136,575)
        aim_joystick.position = Vector2(28,575)
        fire_button.position = Vector2(1132,490)
        reload_button.position = Vector2(984,625)
        jump_button.position = Vector2(32,490)
    else:
        movement_joystick.position = Vector2(28,575)
        aim_joystick.position = Vector2(1136,575)
        fire_button.position = Vector2(32,490)
        reload_button.position = Vector2(164,625)
        jump_button.position = Vector2(1136,490)
    movement_joystick.size = Vector2(116,116)
    aim_joystick.size = Vector2(116,116)
    fire_button.size = Vector2(116,52)
    reload_button.size = Vector2(132,48)
    jump_button.size = Vector2(112,52)
    ammo_label.position = Vector2(158 if not controls_mirrored else 972,590)
    ammo_label.size = Vector2(150,28)
    menu_button.position = Vector2(18,18)
    cards_button.position = Vector2(150,18)

func _apply_audio_settings() -> void:
    if AudioServer.bus_count > 0:
        AudioServer.set_bus_volume_db(0, linear_to_db(maxf(sound_level, 0.0001)))
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
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_font_size_override("font_size",19)
    button.add_theme_color_override("font_color",Color("#f6f7ee"))
    button.add_theme_color_override("font_hover_color",Color("#ffffff"))
    button.add_theme_color_override("font_pressed_color",Color("#e8f6a0"))
    button.add_theme_stylebox_override("normal",_button_style(Color("#263b5b")))
    button.add_theme_stylebox_override("hover",_button_style(Color("#354f70")))
    button.add_theme_stylebox_override("pressed",_button_style(Color("#3d638e")))
    button.add_theme_stylebox_override("focus",_button_style(Color("#354f70")))
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
    style.shadow_color = Color(0.0,0.0,0.0,0.32)
    style.shadow_size = 7
    style.shadow_offset = Vector2(0,3)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    return style

func _process(delta: float) -> void:
    background_time += delta
    queue_redraw()
    impact_flash = maxf(0.0, impact_flash - delta * 2.8)
    if is_instance_valid(arena_camera):
        if camera_shake_timer > 0.0:
            camera_shake_timer = maxf(0.0,camera_shake_timer-delta)
            if shake_enabled:
                var shake_power := camera_shake_strength * clampf(camera_shake_timer / 0.16, 0.0, 1.0)
                arena_camera.offset = Vector2(randf_range(-shake_power,shake_power),randf_range(-shake_power,shake_power))
            else:
                arena_camera.offset = Vector2.ZERO
        else:
            arena_camera.offset = Vector2.ZERO
    if impact_flash > 0.0:
        queue_redraw()
    if boot_loading:
        if is_instance_valid(boot_status_label):
            boot_status_label.text = boot_stage
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
    who.jump_speed = -715.0
    who.gravity_scale = 1.0
    who.air_control_scale = 1.0
    who.ground_accel_scale = 1.0
    who.wall_jump_scale = 1.0
    who.extra_air_jumps = 0
    who.air_jumps_left = 1
    who.pulse_force = 610.0
    who.pulse_interval = 0.78
    who.magazine_size = 6
    who.ammo = 6
    who.reload_duration = 1.35
    who.reload_timer = 0.0
    who.homing_strength = 0.0
    who.ricochet_count = 0
    who.projectile_speed = 1050.0
    who.weapon_level = 0
    who.kiwi_aura = false

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
    var outline := Color("#20232b")
    var face := Polygon2D.new()
    face.position = center
    face.polygon = PackedVector2Array([
        Vector2(-49,-8),Vector2(-44,-31),Vector2(-28,-48),Vector2(-5,-55),
        Vector2(19,-50),Vector2(39,-34),Vector2(49,-9),Vector2(44,20),
        Vector2(27,43),Vector2(0,51),Vector2(-28,42),Vector2(-45,19)
    ])
    face.color = Color("#f4dfc4")
    parent.add_child(face)

    var fringe := Polygon2D.new()
    fringe.position = center
    fringe.polygon = PackedVector2Array([
        Vector2(-47,-10),Vector2(-42,-34),Vector2(-25,-49),Vector2(-5,-53),
        Vector2(18,-48),Vector2(38,-32),Vector2(46,-12),Vector2(25,-21),
        Vector2(8,-24),Vector2(-8,-19),Vector2(-24,-8)
    ])
    fringe.color = Color("#eee4cc")
    parent.add_child(fringe)

    var fringe_line := Line2D.new()
    fringe_line.points = PackedVector2Array([
        center+Vector2(-47,-10),center+Vector2(-42,-34),center+Vector2(-25,-49),
        center+Vector2(-5,-53),center+Vector2(18,-48),center+Vector2(38,-32)
    ])
    fringe_line.width = 3.0
    fringe_line.default_color = outline
    parent.add_child(fringe_line)

    for eye_x in [-17,17]:
        var eye := ColorRect.new()
        eye.position = center + Vector2(eye_x-3,-4)
        eye.size = Vector2(6,12)
        eye.color = outline
        parent.add_child(eye)
        var shine := ColorRect.new()
        shine.position = center + Vector2(eye_x-1,-3)
        shine.size = Vector2(2,3)
        shine.color = Color.WHITE
        parent.add_child(shine)

    var mouth := Line2D.new()
    mouth.points = PackedVector2Array([center+Vector2(-5,20),center+Vector2(0,24),center+Vector2(6,19)])
    mouth.width = 2.5
    mouth.default_color = Color("#9a655d")
    parent.add_child(mouth)

    var bow_left := Polygon2D.new()
    bow_left.position = center + Vector2(-7,-48)
    bow_left.polygon = PackedVector2Array([Vector2(0,0),Vector2(-17,-10),Vector2(-14,7)])
    bow_left.color = Color("#86bd58")
    parent.add_child(bow_left)
    var bow_right := Polygon2D.new()
    bow_right.position = center + Vector2(7,-48)
    bow_right.polygon = PackedVector2Array([Vector2(0,0),Vector2(17,-10),Vector2(14,7)])
    bow_right.color = Color("#86bd58")
    parent.add_child(bow_right)
    var bow_center := Polygon2D.new()
    bow_center.position = center + Vector2(0,-48)
    bow_center.polygon = PackedVector2Array([Vector2(-5,-5),Vector2(5,-5),Vector2(6,5),Vector2(-6,5)])
    bow_center.color = Color("#4d8b43")
    parent.add_child(bow_center)

    var collar := Polygon2D.new()
    collar.position = center + Vector2(0,40)
    collar.polygon = PackedVector2Array([Vector2(-15,0),Vector2(0,10),Vector2(15,0),Vector2(0,17)])
    collar.color = Color("#f8f3e7")
    parent.add_child(collar)
    var collar_edge := Line2D.new()
    collar_edge.points = PackedVector2Array([
        center+Vector2(-15,40),center+Vector2(0,50),center+Vector2(15,40)
    ])
    collar_edge.width = 2.0
    collar_edge.default_color = outline
    parent.add_child(collar_edge)

func _show_mode_menu() -> void:
    _show_panel("ВЫБОР РЕЖИМА",[
        ["ОНЛАЙН — ПОЗЖЕ",Callable(self,"_show_online_info")],
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
    # Training begins immediately. Cards are opened only from the dedicated CARDS menu.
    _start_game("training")

func _show_online_info() -> void:
    _show_panel("ОНЛАЙН",[
        ["НАЗАД",Callable(self,"_show_mode_menu")]
    ],"Сетевой режим пока не подключён. Сейчас доступны полноценные бои с ботом и тренировка.")

func _show_pause_menu() -> void:
    phase = "paused"
    _clear_control_inputs()
    _clear_pulses()
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
    _save_settings()
    _show_settings()

func _toggle_vibration() -> void:
    vibration_enabled = not vibration_enabled
    _save_settings()
    _show_settings()

func _cycle_volume() -> void:
    if sound_level <= 0.001:
        sound_level = 0.35
    elif sound_level < 0.5:
        sound_level = 0.72
    elif sound_level < 0.9:
        sound_level = 1.0
    else:
        sound_level = 0.0
    sound_enabled = sound_level > 0.001
    _apply_audio_settings()
    _save_settings()
    _show_settings()

func _toggle_shake() -> void:
    shake_enabled = not shake_enabled
    _save_settings()
    _show_settings()

func _toggle_controls() -> void:
    controls_mirrored = not controls_mirrored
    _apply_control_layout()
    _save_settings()
    _show_settings()

func _open_skins() -> void:
    if phase == "fight":
        skin_return_to_game = true
        phase = "paused"
        _clear_control_inputs()
        _clear_pulses()
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
        style.shadow_color = Color(0.0,0.0,0.0,0.34)
        style.shadow_size = 9
        style.shadow_offset = Vector2(0,4)
        card.add_theme_stylebox_override("panel",style)
        var column := VBoxContainer.new()
        column.alignment = BoxContainer.ALIGNMENT_CENTER
        column.add_theme_constant_override("separation",8)
        card.add_child(column)
        var preview_area := Control.new()
        preview_area.custom_minimum_size = Vector2(235,175)
        var preview_back := Panel.new()
        preview_back.position = Vector2(5,5)
        preview_back.size = Vector2(225,165)
        var preview_style := StyleBoxFlat.new()
        preview_style.bg_color = Color("#171d27")
        preview_style.border_color = color.darkened(0.18)
        preview_style.set_border_width_all(2)
        preview_style.set_corner_radius_all(14)
        preview_back.add_theme_stylebox_override("panel",preview_style)
        preview_area.add_child(preview_back)
        var color_chip := ColorRect.new()
        color_chip.position = Vector2(15,15)
        color_chip.size = Vector2(205,4)
        color_chip.color = color
        preview_area.add_child(color_chip)
        column.add_child(preview_area)
        var fighter: ArenaPlayer = PLAYER_SCRIPT.new()
        fighter.body_color = color
        fighter.skin_style = str(skin.get("style","default"))
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
        choose.text = "НАДЕТО  ✓" if i == skin_index else "ЭКИПИРОВАТЬ"
        choose.custom_minimum_size = Vector2(220,45)
        choose.focus_mode = Control.FOCUS_NONE
        choose.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        choose.add_theme_font_size_override("font_size",16)
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
    mod_json_input.text = mod_json_buffer if mod_json_buffer != "" else '{"name":"Мой мод","skins":[{"name":"Мятный","color":"#39d6c5"}],"maps":[{"name":"Моя арена","platforms":[{"x":300,"y":550,"w":180,"h":22},{"x":950,"y":550,"w":180,"h":22}]}],"upgrades":[]}'
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
    mod_json_buffer = mod_json_input.text
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
        phase = "paused"
        _clear_control_inputs()
        _clear_pulses()
        player.set_physics_process(false)
        rival.set_physics_process(false)
        _show_panel("КАРТОЧКИ",[
            ["ОТКРЫТЬ ТРЕНИРОВКУ",Callable(self,"_start_training")],
            ["НАЗАД",Callable(self,"_resume_game")]
        ],"Карточки и выбор арены доступны в тренировке.")
        return
    phase = "paused"
    _clear_control_inputs()
    _clear_pulses()
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

func _add_card_illustration(parent: Control, card_id: String, active: bool) -> void:
    var tint := Color("#d9ef70") if active else Color("#91a7c4")
    var dark := Color("#101a28")
    var glow := Color(tint,0.12)
    var halo := Polygon2D.new()
    halo.position = Vector2(157,59)
    halo.polygon = PackedVector2Array([Vector2(-115,-54),Vector2(115,-54),Vector2(137,0),Vector2(115,54),Vector2(-115,54),Vector2(-137,0)])
    halo.color = glow
    parent.add_child(halo)
    var frame := Line2D.new()
    frame.points = PackedVector2Array([Vector2(30,59),Vector2(48,14),Vector2(85,5),Vector2(108,14),Vector2(126,59),Vector2(108,104),Vector2(85,113),Vector2(48,104),Vector2(30,59)])
    frame.width = 2.0
    frame.default_color = Color(tint,0.28)
    frame.antialiased = true
    parent.add_child(frame)
    # Custom illustrated emblem for each card, with a shared hand-painted tech-art language.
    var emblem := Polygon2D.new()
    emblem.position = Vector2(157,58)
    emblem.color = tint
    parent.add_child(emblem)
    match card_id:
        "homing":
            emblem.polygon = PackedVector2Array([Vector2(-8,-43),Vector2(9,-18),Vector2(34,-10),Vector2(14,8),Vector2(7,38),Vector2(-8,20),Vector2(-25,37),Vector2(-20,7),Vector2(-40,-9),Vector2(-15,-18)])
            var target_ring := Line2D.new()
            var pts := PackedVector2Array()
            for i in range(49):
                var a := TAU * float(i) / 48.0
                pts.append(Vector2(cos(a),sin(a))*49.0)
            target_ring.points = pts
            target_ring.width = 2.2
            target_ring.default_color = Color(tint,0.8)
            target_ring.antialiased = true
            parent.add_child(target_ring)
            var dot := Polygon2D.new()
            dot.polygon = PackedVector2Array([Vector2(-5,-5),Vector2(5,-5),Vector2(5,5),Vector2(-5,5)])
            dot.position = Vector2(157,58)
            dot.color = Color.WHITE
            parent.add_child(dot)
        "ricochet":
            emblem.polygon = PackedVector2Array([Vector2(-12,-43),Vector2(12,-43),Vector2(12,-5),Vector2(42,-5),Vector2(42,17),Vector2(-12,17)])
            var bounce := Line2D.new()
            bounce.points = PackedVector2Array([Vector2(90,86),Vector2(90,27),Vector2(207,27),Vector2(207,86)])
            bounce.width = 4.0
            bounce.default_color = tint
            bounce.antialiased = true
            parent.add_child(bounce)
        "heavy":
            emblem.polygon = PackedVector2Array([Vector2(-55,-17),Vector2(27,-17),Vector2(27,-30),Vector2(58,0),Vector2(27,30),Vector2(27,17),Vector2(-55,17)])
            var weight := Polygon2D.new()
            weight.position = Vector2(157,58)
            weight.polygon = PackedVector2Array([Vector2(-13,-43),Vector2(13,-43),Vector2(13,-17),Vector2(40,-17),Vector2(40,17),Vector2(13,17),Vector2(13,43),Vector2(-13,43),Vector2(-13,17),Vector2(-40,17),Vector2(-40,-17),Vector2(-13,-17)])
            weight.color = Color(tint,0.5)
            parent.add_child(weight)
        "rapid":
            emblem.polygon = PackedVector2Array([Vector2(13,-47),Vector2(-34,7),Vector2(-7,7),Vector2(-22,47),Vector2(39,-15),Vector2(11,-15)])
            var speed_lines := Line2D.new()
            speed_lines.points = PackedVector2Array([Vector2(55,43),Vector2(96,43),Vector2(115,31)])
            speed_lines.width = 4.0
            speed_lines.default_color = tint
            parent.add_child(speed_lines)
        "magazine":
            emblem.polygon = PackedVector2Array([Vector2(-35,-37),Vector2(35,-37),Vector2(35,38),Vector2(-35,38)])
            for i in range(3):
                var slot := ColorRect.new()
                slot.position = Vector2(134.0+float(i)*16.0,37.0)
                slot.size = Vector2(8,42)
                slot.color = dark
                parent.add_child(slot)
        "piercing":
            emblem.polygon = PackedVector2Array([Vector2(-60,-9),Vector2(24,-9),Vector2(24,-24),Vector2(61,0),Vector2(24,24),Vector2(24,9),Vector2(-60,9)])
            var streak := Line2D.new()
            streak.points = PackedVector2Array([Vector2(84,59),Vector2(224,59)])
            streak.width = 2.0
            streak.default_color = Color.WHITE
            parent.add_child(streak)
        "kiwi":
            emblem.polygon = PackedVector2Array([Vector2(0,-48),Vector2(17,-22),Vector2(42,-12),Vector2(20,10),Vector2(10,43),Vector2(-8,23),Vector2(-39,34),Vector2(-25,3),Vector2(-43,-18),Vector2(-13,-20)])
            var leaf_vein := Line2D.new()
            leaf_vein.points = PackedVector2Array([Vector2(157,58),Vector2(157,25),Vector2(177,10)])
            leaf_vein.width = 3.0
            leaf_vein.default_color = Color("#f3f0d8")
            parent.add_child(leaf_vein)
        "spring":
            emblem.polygon = PackedVector2Array([Vector2(-35,-42),Vector2(35,-42),Vector2(-15,-14),Vector2(35,-14),Vector2(-15,14),Vector2(35,14),Vector2(8,42),Vector2(-35,42)])
        "feather":
            emblem.polygon = PackedVector2Array([Vector2(-42,26),Vector2(-15,-36),Vector2(6,-45),Vector2(31,-15),Vector2(38,18),Vector2(5,42),Vector2(-9,8)])
        "wall":
            emblem.polygon = PackedVector2Array([Vector2(-42,-35),Vector2(-20,-35),Vector2(-20,25),Vector2(20,25),Vector2(20,4),Vector2(44,4),Vector2(44,45),Vector2(-42,45)])
        "air":
            emblem.polygon = PackedVector2Array([Vector2(-10,-46),Vector2(10,-46),Vector2(10,-10),Vector2(46,-10),Vector2(46,10),Vector2(10,10),Vector2(10,46),Vector2(-10,46),Vector2(-10,10),Vector2(-46,10),Vector2(-46,-10),Vector2(-10,-10)])
        "boots":
            emblem.polygon = PackedVector2Array([Vector2(-39,-42),Vector2(-4,-42),Vector2(-4,15),Vector2(40,15),Vector2(40,39),Vector2(-39,39)])
        _:
            emblem.polygon = PackedVector2Array([Vector2(-44,-34),Vector2(0,-49),Vector2(44,-34),Vector2(35,26),Vector2(0,48),Vector2(-35,26)])
    var shine := Line2D.new()
    shine.points = PackedVector2Array([Vector2(126,30),Vector2(145,19),Vector2(169,18)])
    shine.width = 2.0
    shine.default_color = Color(1.0,1.0,1.0,0.55)
    parent.add_child(shine)

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
        var stack_count := active_training_cards.count(id)
        var active := stack_count > 0
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
        _add_card_illustration(art_area, id, active)
        var icon_label := Label.new()
        icon_label.text = str(card.get("icon",""))
        icon_label.position = Vector2(0,91)
        icon_label.size = Vector2(315,24)
        icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon_label.add_theme_font_size_override("font_size",13)
        icon_label.add_theme_color_override("font_color",Color("#f3f1e8"))
        art_area.add_child(icon_label)
        var stack_label := Label.new()
        stack_label.text = "СТАК ×%d" % stack_count if stack_count > 0 else "СТАКИРУЕТСЯ"
        stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        stack_label.add_theme_font_size_override("font_size",12)
        stack_label.add_theme_color_override("font_color",Color("#b9e36c") if stack_count > 0 else Color("#7f8a9b"))
        column.add_child(stack_label)
        var name_label := Label.new()
        name_label.text = str(card.get("name",id))
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size",18)
        name_label.add_theme_color_override("font_color",Color("#f3f1e8"))
        column.add_child(name_label)
        var primary := Label.new()
        primary.text = str(card.get("primary","ОСНОВНОЙ ЭФФЕКТ"))
        primary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        primary.add_theme_font_size_override("font_size",14)
        primary.add_theme_color_override("font_color",Color("#f0d88a"))
        column.add_child(primary)
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

func _add_menu_ornaments(parent: Control) -> void:
    var top_glow := ColorRect.new()
    top_glow.position = Vector2(0,0)
    top_glow.size = Vector2(1280,5)
    top_glow.color = Color("#d9ef70")
    parent.add_child(top_glow)
    var left_rail := ColorRect.new()
    left_rail.position = Vector2(26,215)
    left_rail.size = Vector2(3,290)
    left_rail.color = Color(0.48,0.66,0.83,0.22)
    parent.add_child(left_rail)
    var right_rail := ColorRect.new()
    right_rail.position = Vector2(1251,215)
    right_rail.size = Vector2(3,290)
    right_rail.color = Color(0.48,0.66,0.83,0.22)
    parent.add_child(right_rail)
    for i in range(9):
        var dot := ColorRect.new()
        dot.position = Vector2(72.0 + float(i)*142.0, 690.0)
        dot.size = Vector2(3,3)
        dot.color = Color(0.85,0.93,0.57,0.48)
        parent.add_child(dot)

func _show_panel(title_text: String, buttons: Array, subtitle: String = "") -> void:
    _close_overlay()
    game_controls.visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#0b1019")
    ui.add_child(shade)
    overlay = shade
    _add_menu_ornaments(shade)
    var panel := Panel.new()
    panel.position = Vector2(300,45)
    panel.size = Vector2(680,630)
    var ps := StyleBoxFlat.new()
    ps.bg_color = Color("#1c2029")
    ps.border_color = Color("#414858")
    ps.set_border_width_all(2)
    ps.set_corner_radius_all(24)
    ps.shadow_color = Color(0.0,0.0,0.0,0.48)
    ps.shadow_size = 22
    ps.shadow_offset = Vector2(0,9)
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
        button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        button.add_theme_font_size_override("font_size",20)
        button.add_theme_color_override("font_color",Color("#f3f1e8"))
        button.add_theme_color_override("font_hover_color",Color("#ffffff"))
        button.add_theme_stylebox_override("normal",_menu_button_style(Color("#303644"),Color("#596174")))
        button.add_theme_stylebox_override("hover",_menu_button_style(Color("#414a5b"),Color("#d9ef70")))
        button.add_theme_stylebox_override("pressed",_menu_button_style(Color("#596b32"),Color("#d9ef70")))
        button.add_theme_stylebox_override("focus",_menu_button_style(Color("#414a5b"),Color("#d9ef70")))
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
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    style.shadow_color = Color(0.0,0.0,0.0,0.30)
    style.shadow_size = 5
    style.shadow_offset = Vector2(0,2)
    return style

func _close_overlay() -> void:
    if is_instance_valid(overlay):
        overlay.queue_free()
    overlay = null

func _finish_round(player_won: bool) -> void:
    if phase != "fight":
        return
    _clear_control_inputs()
    _clear_pulses()
    phase = "upgrade"
    player.set_physics_process(false)
    rival.set_physics_process(false)
    if player_won:
        score_player += 1
    else:
        score_bot += 1
    _update_hud()
    if game_mode == "training":
        _show_training_round_end()
    elif score_player >= 5 or score_bot >= 5:
        _show_match_end()
    elif player_won:
        # Only the losing side receives an upgrade.
        if not all_upgrades.is_empty():
            var bot_choice: Dictionary = all_upgrades.pick_random()
            rival.apply_upgrade(str(bot_choice.get("effect",bot_choice.get("id",""))))
        _next_round()
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
    _close_overlay()
    game_controls.visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#10141c")
    ui.add_child(shade)
    overlay = shade

    var title := Label.new()
    title.text = "ТЫ ПРОИГРАЛ РАУНД"
    title.position = Vector2(0,54)
    title.size = Vector2(1280,58)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",38)
    title.add_theme_color_override("font_color",Color("#f2f0e8"))
    shade.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Выбери усиление — теперь твой ход"
    subtitle.position = Vector2(0,118)
    subtitle.size = Vector2(1280,34)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size",18)
    subtitle.add_theme_color_override("font_color",Color("#aeb7c7"))
    shade.add_child(subtitle)

    for i in range(mini(3,choices.size())):
        var item: Dictionary = choices[i]
        var card := PanelContainer.new()
        card.position = Vector2(105.0 + float(i)*365.0,205.0)
        card.size = Vector2(330,390)
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#202a35")
        style.border_color = Color("#8ba66a")
        style.set_border_width_all(2)
        style.set_corner_radius_all(16)
        card.add_theme_stylebox_override("panel",style)
        shade.add_child(card)

        var column := VBoxContainer.new()
        column.alignment = BoxContainer.ALIGNMENT_CENTER
        column.add_theme_constant_override("separation",12)
        card.add_child(column)

        var symbol := Label.new()
        symbol.text = str(item.get("icon","✦"))
        symbol.custom_minimum_size = Vector2(290,92)
        symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        symbol.add_theme_font_size_override("font_size",58)
        symbol.add_theme_color_override("font_color",Color("#d9ef70"))
        column.add_child(symbol)

        var name_label := Label.new()
        name_label.text = str(item.get("name","УЛУЧШЕНИЕ"))
        name_label.custom_minimum_size = Vector2(290,54)
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        name_label.add_theme_font_size_override("font_size",20)
        name_label.add_theme_color_override("font_color",Color("#f4f1e8"))
        column.add_child(name_label)

        var buff := Label.new()
        buff.text = "▲  " + str(item.get("buff",""))
        buff.custom_minimum_size = Vector2(290,54)
        buff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        buff.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        buff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        buff.add_theme_font_size_override("font_size",15)
        buff.add_theme_color_override("font_color",Color("#b9e36c"))
        column.add_child(buff)

        var debuff := Label.new()
        debuff.text = "▼  " + str(item.get("debuff",""))
        debuff.custom_minimum_size = Vector2(290,48)
        debuff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        debuff.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        debuff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        debuff.add_theme_font_size_override("font_size",14)
        debuff.add_theme_color_override("font_color",Color("#ff9a91"))
        column.add_child(debuff)

        var choose := Button.new()
        choose.text = "ВЫБРАТЬ"
        choose.custom_minimum_size = Vector2(286,52)
        choose.add_theme_font_size_override("font_size",18)
        choose.add_theme_stylebox_override("normal",_menu_button_style(Color("#d9ef70"),Color("#eff9bf")))
        choose.add_theme_color_override("font_color",Color("#172015"))
        choose.pressed.connect(_choose_upgrade.bind(str(item.get("effect",item.get("id","")))))
        column.add_child(choose)

    var footer := Label.new()
    footer.text = "KIWI ROUNDS  •  BUILD YOUR MOVEMENT"
    footer.position = Vector2(0,675)
    footer.size = Vector2(1280,24)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size",12)
    footer.add_theme_color_override("font_color",Color("#626875"))
    shade.add_child(footer)

func _choose_upgrade(upgrade_id: String) -> void:
    player.apply_upgrade(upgrade_id)
    _next_round()

func _next_round() -> void:
    _clear_pulses()
    _close_overlay()
    player.set_physics_process(true)
    rival.set_physics_process(true)
    round_index += 1
    _make_arena(map_index if game_mode == "training" else round_index - 1)
    player.reset_round(Vector2(350,390))
    rival.reset_round(Vector2(930,390))
    phase = "fight"
    game_controls.visible = true
    _update_hud()

func _show_match_end() -> void:
    var result := "ПОБЕДА!" if score_player >= 5 else "ПОБЕДИЛ CPU"
    _show_panel(result,[
        ["СЫГРАТЬ ЕЩЁ",Callable(self,"_restart_match")],
        ["ГЛАВНОЕ МЕНЮ",Callable(self,"_show_main_menu")]
    ],"Первый до 5 побед. Счёт: %d : %d" % [score_player,score_bot])

func _restart_match() -> void:
    _start_game(game_mode)
