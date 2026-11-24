extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PULSE_SCRIPT = preload("res://scripts/pulse.gd")
const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
const MOD_LOADER_SCRIPT = preload("res://scripts/mod_loader.gd")

const DEFAULT_UPGRADES := [
    {"id":"swift","name":"ТУРБО-БОТИНКИ","icon":"➤","buff":"БАФФ  Скорость +16%","debuff":"МИНУС  Сила выстрела −10%","effect":"swift"},
    {"id":"spring","name":"ПРУЖИННЫЙ МОДУЛЬ","icon":"↑","buff":"БАФФ  Высота прыжка +12%","debuff":"МИНУС  Скорость −8%","effect":"spring"},
    {"id":"wave","name":"ТЯЖЁЛЫЙ КАЛИБР","icon":"✦","buff":"БАФФ  Отбрасывание +22%","debuff":"МИНУС  Перезарядка дольше на 12%","effect":"wave"},
    {"id":"rapid","name":"БЫСТРЫЙ ЗАТВОР","icon":"⚡","buff":"БАФФ  Перезарядка быстрее на 18%","debuff":"МИНУС  Сила выстрела −10%","effect":"rapid"},
    {"id":"sturdy","name":"БОЕВОЙ РАЗГОН","icon":"◆","buff":"БАФФ  Скорость +6%, прыжок +8%","debuff":"МИНУС  Нет","effect":"sturdy"}
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
    draw_rect(Rect2(0, 0, 1280, 720), Color("#111111"))
    if boot_loading:
        draw_rect(Rect2(0, 0, 1280, 5), Color("#eeeeee"))
        draw_rect(Rect2(0, 715, 1280, 5), Color("#333333"))
        draw_string(ThemeDB.fallback_font, Vector2(0, 295), "KIWI ROUNDS", HORIZONTAL_ALIGNMENT_CENTER, 1280, 54, Color("#f2f2f2"))
        draw_string(ThemeDB.fallback_font, Vector2(0, 345), "ЗАПУСК ИГРЫ", HORIZONTAL_ALIGNMENT_CENTER, 1280, 18, Color("#888888"))
        var center := Vector2(640, 430)
        draw_arc(center, 27.0, boot_angle, boot_angle + 4.4, 48, Color("#777777"), 6.0, true)
        draw_circle(center + Vector2(cos(boot_angle) * 27.0, sin(boot_angle) * 27.0), 5.0, Color("#f2f2f2"))
        draw_string(ThemeDB.fallback_font, Vector2(0, 500), boot_stage, HORIZONTAL_ALIGNMENT_CENTER, 1280, 18, Color("#aaaaaa"))
        draw_string(ThemeDB.fallback_font, Vector2(0, 675), "Пожалуйста, подожди", HORIZONTAL_ALIGNMENT_CENTER, 1280, 15, Color("#666666"))
        return
    draw_rect(Rect2(0, 0, 1280, 8), Color("#e6e6e6"))
    draw_rect(Rect2(0, 680, 1280, 40), Color("#202020"))
    for i in range(14):
        var x := float((i * 113 + 45) % 1280)
        var y := float((i * 67 + 30) % 650)
        draw_circle(Vector2(x,y),1.5,Color("#3a3a3a"))
    draw_rect(Rect2(0, 0, 1280, 720), Color(0,0,0,0), false, 2.0, true)

func _make_arena(index: int) -> void:
    for old_platform in platform_nodes:
        if is_instance_valid(old_platform):
            old_platform.queue_free()
    platform_nodes.clear()
    _add_platform(Vector2(640, 700), Vector2(1400, 50))
    if all_maps.is_empty():
        return
    map_index = index % all_maps.size()
    var map_data: Dictionary = all_maps[map_index]
    var platforms: Variant = map_data.get("platforms", [])
    if typeof(platforms) == TYPE_ARRAY:
        for item in platforms:
            if typeof(item) == TYPE_DICTIONARY:
                _add_platform(Vector2(float(item.get("x",640)),float(item.get("y",500))),Vector2(float(item.get("w",180)),float(item.get("h",22))))

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
    visual.color = Color("#354766")
    body.add_child(visual)
    var stripe := Line2D.new()
    stripe.points = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2)])
    stripe.width = 4.0
    stripe.default_color = Color("#6f91b9")
    body.add_child(stripe)

func _make_players() -> void:
    player = PLAYER_SCRIPT.new()
    player.body_color = selected_skin_color
    player.position = Vector2(350,390)
    player.pulse_requested.connect(_spawn_pulse)
    add_child(player)
    rival = PLAYER_SCRIPT.new()
    rival.is_bot = true
    rival.body_color = Color("#ff786f")
    rival.position = Vector2(930,390)
    rival.target = player
    rival.pulse_requested.connect(_spawn_pulse)
    add_child(rival)

func _apply_skin() -> void:
    if mod_loader == null:
        mod_loader = MOD_LOADER_SCRIPT.new()
    var skins: Array[Dictionary] = [
        {"name":"Бирюзовый","color":"#39d6c5"},
        {"name":"Лазурный","color":"#4b9cff"},
        {"name":"Фиолетовый","color":"#b47cff"},
        {"name":"Золотой","color":"#ffc857"},
        {"name":"Розовый","color":"#ff78b7"}
    ]
    skins.append_array(mod_loader.skins)
    if skins.is_empty():
        return
    skin_index = posmod(skin_index, skins.size())
    var skin: Dictionary = skins[skin_index]
    selected_skin_color = Color.from_string(str(skin.get("color","#39d6c5")),Color("#39d6c5"))
    player.body_color = selected_skin_color
    player.queue_redraw()
    if is_instance_valid(skin_button):
        skin_button.text = "СКИН: " + str(skin.get("name",skin.get("id","MOD")))

func _cycle_skin() -> void:
    skin_index += 1
    _apply_skin()

func _spawn_pulse(origin: Vector2, direction: Vector2, force: float, tint: Color, shooter: Node2D) -> void:
    var pulse: EnergyPulse = PULSE_SCRIPT.new()
    pulse.configure(direction,force,tint,shooter)
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
    var movement_joystick: VirtualJoystick = JOYSTICK_SCRIPT.new()
    movement_joystick.position = Vector2(35,535)
    movement_joystick.size = Vector2(150,150)
    movement_joystick.value_changed.connect(player.set_move)
    game_controls.add_child(movement_joystick)
    fire_button = _add_button("ВЫСТРЕЛ",Vector2(205,585),Vector2(145,76),game_controls)
    fire_button.button_down.connect(player.set_fire.bind(true))
    fire_button.button_up.connect(player.set_fire.bind(false))
    var reload_button := _add_button("ПЕРЕЗАРЯДКА",Vector2(365,585),Vector2(175,76),game_controls)
    reload_button.add_theme_font_size_override("font_size",15)
    reload_button.pressed.connect(player.start_reload)
    ammo_label = Label.new()
    ammo_label.position = Vector2(190,545)
    ammo_label.size = Vector2(360,32)
    ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ammo_label.add_theme_font_size_override("font_size",18)
    ammo_label.add_theme_color_override("font_color",Color("#f4f7ff"))
    game_controls.add_child(ammo_label)
    var aim_joystick: VirtualJoystick = JOYSTICK_SCRIPT.new()
    aim_joystick.position = Vector2(1080,535)
    aim_joystick.size = Vector2(150,150)
    aim_joystick.value_changed.connect(player.set_aim)
    game_controls.add_child(aim_joystick)
    var jump_button := _add_button("ПРЫЖОК",Vector2(1090,405),Vector2(130,82),game_controls)
    jump_button.button_down.connect(player.set_jump.bind(true))
    jump_button.button_up.connect(player.set_jump.bind(false))
    var menu_button := _add_button("МЕНЮ",Vector2(18,18),Vector2(120,50),game_controls)
    menu_button.pressed.connect(_show_pause_menu)
    var cards_button := _add_button("КАРТОЧКИ",Vector2(150,18),Vector2(160,50),game_controls)
    cards_button.pressed.connect(_open_training_cards)
    _apply_skin()

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
    player.set_physics_process(false)
    rival.set_physics_process(false)
    game_controls.visible = false
    hud.visible = false
    _show_panel("KIWI ROUNDS",[
        ["ИГРАТЬ",Callable(self,"_show_mode_menu")],
        ["НАСТРОЙКИ",Callable(self,"_show_settings")],
        ["СКИНЫ",Callable(self,"_open_skins")],
        ["МОДЫ",Callable(self,"_open_mods")]
    ],"ARENA FIGHTER     •     ANDROID")

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
        ["ВИБРАЦИЯ: " + ("ВКЛ" if vibration_enabled else "ВЫКЛ"),Callable(self,"_toggle_vibration")],
        ["НАЗАД",Callable(self,"_show_main_menu")]
    ],"Звуковые эффекты и вибрация будут подключены отдельно")

func _toggle_sound() -> void:
    sound_enabled = not sound_enabled
    _show_settings()

func _toggle_vibration() -> void:
    vibration_enabled = not vibration_enabled
    _show_settings()

func _open_skins() -> void:
    if phase == "fight":
        phase = "paused"
        player.set_physics_process(false)
        rival.set_physics_process(false)
    var skin_count := 5 + mod_loader.skins.size()
    var current_name := "Выбран скин " + str(skin_index + 1) + " из " + str(skin_count)
    _show_panel("СКИНЫ",[
        ["ПРЕДЫДУЩИЙ",Callable(self,"_previous_skin")],
        ["СЛЕДУЮЩИЙ",Callable(self,"_cycle_skin")],
        ["ПРИМЕНИТЬ И НАЗАД",Callable(self,"_apply_skin_and_return")],
        ["В ГЛАВНОЕ МЕНЮ",Callable(self,"_show_main_menu")]
    ],current_name + "\nЦвет персонажа меняется сразу")

func _previous_skin() -> void:
    skin_index -= 1
    _apply_skin()
    _open_skins()

func _apply_skin_and_return() -> void:
    _apply_skin()
    if phase == "fight":
        _resume_game()
    else:
        _show_main_menu()

func _open_mods() -> void:
    if mod_loader == null:
        mod_loader = MOD_LOADER_SCRIPT.new()
    if not mods_loaded:
        mod_loader.load_all()
        all_maps.assign(DEFAULT_MAPS)
        all_maps.append_array(mod_loader.maps)
        all_upgrades.assign(DEFAULT_UPGRADES)
        all_upgrades.append_array(mod_loader.upgrades)
        mods_loaded = true
    var description := "Найдено модов: %d\nСкинов: %d  •  карт: %d  •  карточек: %d\nПапка: user://mods/\nКаждый мод должен содержать mod.json." % [mod_loader.loaded_mod_names.size(),mod_loader.skins.size(),mod_loader.maps.size(),mod_loader.upgrades.size()]
    if not mod_loader.loaded_mod_names.is_empty():
        for mod_name in mod_loader.loaded_mod_names:
            description += "\n" + mod_name
    _show_panel("МОДЫ",[
        ["ПЕРЕЗАГРУЗИТЬ МОДЫ",Callable(self,"_reload_mods")],
        ["НАЗАД",Callable(self,"_show_main_menu")]
    ],description)

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
    _open_mods()

func _open_training_cards() -> void:
    if phase == "fight":
        player.set_physics_process(false)
        rival.set_physics_process(false)
    if game_mode != "training":
        _show_panel("КАРТОЧКИ",[
            ["ОТКРЫТЬ ТРЕНИРОВКУ",Callable(self,"_start_training")],
            ["НАЗАД",Callable(self,"_resume_game")]
        ],"Выдавать и удалять карточки можно в режиме тренировки.")
        return

    phase = "paused"
    _close_overlay()
    game_controls.visible = false

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#101722")
    ui.add_child(shade)
    overlay = shade

    var title := Label.new()
    title.text = "КАРТОЧКИ УЛУЧШЕНИЙ"
    title.position = Vector2(0,42)
    title.size = Vector2(1280,66)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",38)
    title.add_theme_color_override("font_color",Color("#f4f7ff"))
    shade.add_child(title)

    var info := Label.new()
    info.text = "Нажми на карточку, чтобы включить или убрать эффект. Активно: %d из %d" % [active_training_cards.size(),all_upgrades.size()]
    info.position = Vector2(100,112)
    info.size = Vector2(1080,42)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size",18)
    info.add_theme_color_override("font_color",Color("#aab8cc"))
    shade.add_child(info)

    var grid := GridContainer.new()
    grid.columns = 3
    grid.position = Vector2(110,178)
    grid.size = Vector2(1060,350)
    grid.add_theme_constant_override("h_separation",18)
    grid.add_theme_constant_override("v_separation",16)
    shade.add_child(grid)

    for card in all_upgrades:
        var id := str(card.get("effect",card.get("id","")))
        var active := active_training_cards.has(id)
        var card_button := Button.new()
        var status := "✓  АКТИВНА" if active else "+  ВЫБРАТЬ"
        card_button.text = status + "\n" + str(card.get("name",id)) + "\n\n" + str(card.get("desc",""))
        card_button.custom_minimum_size = Vector2(330,150)
        card_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card_button.focus_mode = Control.FOCUS_NONE
        card_button.add_theme_font_size_override("font_size",18)
        card_button.add_theme_color_override("font_color",Color("#f5f7fb"))
        card_button.add_theme_color_override("font_hover_color",Color("#ffffff"))
        var fill := Color("#245b58") if active else Color("#26364d")
        var edge := Color("#64d6bd") if active else Color("#526b8c")
        card_button.add_theme_stylebox_override("normal",_menu_button_style(fill,edge))
        card_button.add_theme_stylebox_override("hover",_menu_button_style(Color("#385779"),Color("#b8d7ff")))
        card_button.add_theme_stylebox_override("pressed",_menu_button_style(Color("#17263a"),Color("#ffffff")))
        card_button.pressed.connect(_toggle_training_card.bind(id))
        grid.add_child(card_button)

    var done := _add_button("ГОТОВО",Vector2(520,590),Vector2(240,66),shade)
    done.add_theme_font_size_override("font_size",22)
    done.pressed.connect(_resume_game)

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
    shade.color = Color("#111111")
    ui.add_child(shade)
    overlay = shade

    var title := Label.new()
    title.text = title_text
    title.position = Vector2(0,95)
    title.size = Vector2(1280,100)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",58 if title_text == "KIWI ROUNDS" else 38)
    title.add_theme_color_override("font_color",Color("#f2f2f2"))
    title.add_theme_color_override("font_shadow_color",Color("#000000"))
    title.add_theme_constant_override("shadow_offset_x",3)
    title.add_theme_constant_override("shadow_offset_y",3)
    shade.add_child(title)

    var accent := ColorRect.new()
    accent.position = Vector2(500,195)
    accent.size = Vector2(280,5)
    accent.color = Color("#e5e5e5")
    shade.add_child(accent)

    if subtitle != "":
        var info := Label.new()
        info.text = subtitle
        info.position = Vector2(300,215)
        info.size = Vector2(680,70)
        info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        info.add_theme_font_size_override("font_size",17)
        info.add_theme_color_override("font_color",Color("#aaaaaa"))
        shade.add_child(info)

    var list := VBoxContainer.new()
    list.position = Vector2(390,305)
    list.size = Vector2(500,340)
    list.add_theme_constant_override("separation",9)
    shade.add_child(list)
    for index in range(buttons.size()):
        var entry: Array = buttons[index]
        var button := Button.new()
        button.text = str(entry[0])
        button.custom_minimum_size = Vector2(500,58)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.focus_mode = Control.FOCUS_NONE
        button.add_theme_font_size_override("font_size",23)
        button.add_theme_color_override("font_color",Color("#f0f0f0"))
        button.add_theme_color_override("font_hover_color",Color("#111111"))
        button.add_theme_stylebox_override("normal",_menu_button_style(Color("#242424"),Color("#555555")))
        button.add_theme_stylebox_override("hover",_menu_button_style(Color("#eeeeee"),Color("#ffffff")))
        button.add_theme_stylebox_override("pressed",_menu_button_style(Color("#cfcfcf"),Color("#ffffff")))
        button.pressed.connect(entry[1])
        list.add_child(button)

    var footer := Label.new()
    footer.text = "KIWI ROUNDS  /  v0.2"
    footer.position = Vector2(0,665)
    footer.size = Vector2(1280,30)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size",13)
    footer.add_theme_color_override("font_color",Color("#666666"))
    shade.add_child(footer)

func _menu_button_style(fill: Color, outline: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = outline
    style.border_width_left = 2
    style.border_width_right = 2
    style.border_width_top = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left = 2
    style.corner_radius_top_right = 2
    style.corner_radius_bottom_left = 2
    style.corner_radius_bottom_right = 2
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
