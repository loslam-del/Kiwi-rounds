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
    {"name":"КОРОТКИЙ МОСТ","theme":"city","accent":"#d9ef70","platform":"#283b54","bg_top":"#172234","bg_bottom":"#121a27","platforms":[{"x":330,"y":555,"w":230,"h":20},{"x":950,"y":555,"w":230,"h":20},{"x":640,"y":420,"w":170,"h":20},{"x":190,"y":430,"w":150,"h":18},{"x":1090,"y":430,"w":150,"h":18}]},
    {"name":"ДВЕ БАШНИ","theme":"factory","accent":"#ff9b72","platform":"#3d3542","bg_top":"#282333","bg_bottom":"#171821","platforms":[{"x":180,"y":590,"w":190,"h":20},{"x":180,"y":440,"w":150,"h":20},{"x":1100,"y":590,"w":190,"h":20},{"x":1100,"y":440,"w":150,"h":20},{"x":640,"y":520,"w":150,"h":20}]},
    {"name":"ЛЕСТНИЦА","theme":"sky","accent":"#8ed7ff","platform":"#344b67","bg_top":"#142a46","bg_bottom":"#182536","platforms":[{"x":220,"y":600,"w":180,"h":20},{"x":420,"y":520,"w":170,"h":20},{"x":620,"y":440,"w":170,"h":20},{"x":820,"y":360,"w":170,"h":20},{"x":1050,"y":520,"w":180,"h":20}]},
    {"name":"ЦЕНТРАЛЬНЫЙ ОСТРОВ","theme":"jungle","accent":"#8ee28d","platform":"#315244","bg_top":"#17372f","bg_bottom":"#13251f","platforms":[{"x":300,"y":560,"w":170,"h":20},{"x":980,"y":560,"w":170,"h":20},{"x":640,"y":500,"w":260,"h":22},{"x":640,"y":340,"w":150,"h":20}]},
    {"name":"РАЗЛОМ","theme":"rift","accent":"#c18cff","platform":"#44375f","bg_top":"#241c3b","bg_bottom":"#171426","platforms":[{"x":190,"y":560,"w":250,"h":20},{"x":1090,"y":560,"w":250,"h":20},{"x":450,"y":410,"w":150,"h":20},{"x":830,"y":410,"w":150,"h":20}]},
    {"name":"КРЕСТ","theme":"ice","accent":"#9be8ff","platform":"#34516a","bg_top":"#19354c","bg_bottom":"#122334","platforms":[{"x":640,"y":570,"w":340,"h":20},{"x":640,"y":390,"w":340,"h":20},{"x":390,"y":480,"w":150,"h":20},{"x":890,"y":480,"w":150,"h":20}]},
    {"name":"ПАРЯЩИЕ СТУПЕНИ","theme":"sunset","accent":"#ffc477","platform":"#59415a","bg_top":"#422d4d","bg_bottom":"#211d32","platforms":[{"x":250,"y":610,"w":170,"h":20},{"x":470,"y":510,"w":170,"h":20},{"x":690,"y":410,"w":170,"h":20},{"x":910,"y":510,"w":170,"h":20},{"x":1130,"y":610,"w":170,"h":20}]},
    {"name":"КРИСТАЛЬНЫЙ ЗАЛ","theme":"crystal","accent":"#7cf0df","platform":"#28565b","bg_top":"#14343d","bg_bottom":"#101e2c","platforms":[{"x":230,"y":590,"w":180,"h":18},{"x":1050,"y":590,"w":180,"h":18},{"x":430,"y":470,"w":150,"h":18},{"x":850,"y":470,"w":150,"h":18},{"x":640,"y":330,"w":210,"h":18}]},
    {"name":"ПЕПЕЛЬНЫЙ КРАТЕР","theme":"volcano","accent":"#ff795e","platform":"#563b3b","bg_top":"#3a2027","bg_bottom":"#1d171d","platforms":[{"x":250,"y":580,"w":210,"h":22},{"x":1030,"y":580,"w":210,"h":22},{"x":480,"y":450,"w":150,"h":18},{"x":800,"y":450,"w":150,"h":18},{"x":640,"y":540,"w":110,"h":18}]},
    {"name":"НОЧНОЙ ПОРТ","theme":"harbor","accent":"#6fd5ff","platform":"#29465c","bg_top":"#13283b","bg_bottom":"#101923","platforms":[{"x":210,"y":600,"w":200,"h":18},{"x":1070,"y":600,"w":200,"h":18},{"x":420,"y":500,"w":160,"h":18},{"x":860,"y":500,"w":160,"h":18},{"x":640,"y":400,"w":190,"h":18},{"x":640,"y":260,"w":120,"h":18}]}
]

var player: ArenaPlayer
var rival: ArenaPlayer
var ui: Control
var hud: Label
var player_health_bar: ProgressBar
var rival_health_bar: ProgressBar
var player_health_text: Label
var rival_health_text: Label
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
var arena_theme := "city"
var arena_accent := Color("#d9ef70")
var arena_platform_color := Color("#283b54")
var arena_bg_top := Color("#172234")
var arena_bg_bottom := Color("#121a27")
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
const ONLINE_SERVER_URL := "wss://kiwi-rounds-server.onrender.com/ws"
var online_socket := WebSocketPeer.new()
var online_connected := false
var online_connecting := false
var online_status_label: Label
var online_rooms_list: VBoxContainer
var online_name_input: LineEdit
var online_room_name_input: LineEdit
var online_password_input: LineEdit
var music_player: AudioStreamPlayer
var music_tracks: Array[String] = [
    "res://music/влад пиво, ЯРЧЕ СОЛНЦА, besoboy - Пообещай (hitmo.net).mp3",
    "res://music/rabzyyx - im so crazy for you [mp3uk.net].mp3",
    "res://music/dabbackwood - заново [mp3uk.net] (1).mp3",
    "res://music/akkiemi_-_truth_yandere_(mp3.pm).aac",
    "res://music/Moetwee, Differentwrld - Help Me (hitmo.net).mp3",
    "res://music/onda-andar-type-london (1).mp3",
    "res://music/zxcursed_x_shadowraze_-_metamorphosis_3_x_chronospher_(mp3.pm).mp3"
]
var music_display_names: Array[String] = [
    "Пообещай — besoboy, влад пиво, ЯРЧЕ СОЛНЦА",
    "I'm so crazy for youuu — Rebzyyx",
    "заново (slowed) — dabbackwood",
    "truth yandere^^ — akkiemi",
    "help me — differentwrld, moetwee",
    "type london — onda andar",
    "METAMORPHOSIS 3 — zxcursed, Sadfriendd, INTERWORLD"
]
var music_last_index := -1
var menu_record_needle: Control
var music_track_button: Button
var music_visualizer_bars: Array[ColorRect] = []
var online_player_id := ""
var online_host_id := ""
var online_is_host := false
var online_in_match := false
var online_sync_timer := 0.0
var online_reload_pending := false
var online_start_button: Button



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
    _apply_skin()
    boot_stage = "Подготовка интерфейса..."
    _make_ui()
    _setup_music()
    boot_stage = "Запуск меню..."
    _show_main_menu()
    _update_hud()
    boot_loading = false
    var startup_layer := get_node_or_null("StartupLayer")
    if startup_layer != null:
        startup_layer.queue_free()
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0,0,1280,720),arena_bg_bottom.darkened(0.08))
    draw_rect(Rect2(0,0,1280,470),arena_bg_top)
    draw_rect(Rect2(0,470,1280,250),arena_bg_bottom)
    _draw_arena_backdrop()
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
    if phase == "menu":
        _draw_menu_record()
    # Soft arena halos and a faint central light column.
    draw_circle(Vector2(640,450),250.0,Color(0.28,0.62,0.68,0.025))
    draw_arc(Vector2(640,470),430,PI,TAU,80,Color(0.38,0.65,0.82,0.12),2.0,true)
    draw_arc(Vector2(640,470),520,PI,TAU,80,Color(0.38,0.55,0.77,0.06),2.0,true)
    draw_rect(Rect2(0,0,1280,5),arena_accent)
    draw_rect(Rect2(0,700,1280,20),Color("#0b111b"))
    draw_line(Vector2(0,700),Vector2(1280,700),arena_accent.darkened(0.15),2.0)
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
    if all_maps.is_empty():
        return
    map_index = posmod(index, all_maps.size())
    var map_data: Dictionary = all_maps[map_index]
    arena_theme = str(map_data.get("theme", "city"))
    arena_accent = Color.from_string(str(map_data.get("accent", "#d9ef70")), Color("#d9ef70"))
    arena_platform_color = Color.from_string(str(map_data.get("platform", "#283b54")), Color("#283b54"))
    arena_bg_top = Color.from_string(str(map_data.get("bg_top", "#172234")), Color("#172234"))
    arena_bg_bottom = Color.from_string(str(map_data.get("bg_bottom", "#121a27")), Color("#121a27"))
    _add_platform(Vector2(640, 700), Vector2(1400, 50))
    _add_side_wall(-15.0)
    _add_side_wall(1295.0)
    var platforms: Variant = map_data.get("platforms", [])
    if typeof(platforms) == TYPE_ARRAY:
        for item in platforms:
            if typeof(item) == TYPE_DICTIONARY:
                var platform_x := clampf(float(item.get("x", 640)), 100.0, 1180.0)
                var platform_y := clampf(float(item.get("y", 500)), 100.0, 660.0)
                var platform_w := clampf(float(item.get("w", 180)), 70.0, 520.0)
                var platform_h := clampf(float(item.get("h", 22)), 12.0, 42.0)
                _add_platform(Vector2(platform_x, platform_y), Vector2(platform_w, platform_h))
    queue_redraw()

func _draw_menu_record() -> void:
    var center := Vector2(1170.0, 112.0)
    draw_circle(center + Vector2(0, 3), 48.0, Color(0, 0, 0, 0.28))
    draw_circle(center, 46.0, Color("#111923"))
    draw_arc(center, 43.0, 0.0, TAU, 72, Color("#526173", 0.9), 1.4, true)
    for ring in range(5):
        var radius := 12.0 + float(ring) * 6.2
        draw_arc(center, radius, 0.0, TAU, 56, Color("#718095", 0.30), 1.0, true)
    var spin := background_time * 2.8
    draw_line(center, center + Vector2(cos(spin), sin(spin)) * 40.0, Color("#36e6df", 0.8), 2.0, true)
    draw_line(center, center + Vector2(cos(spin + PI), sin(spin + PI)) * 40.0, Color("#36e6df", 0.8), 2.0, true)
    draw_circle(center, 10.0, Color("#d9ef70"))
    draw_circle(center, 3.0, Color("#101923"))

func _draw_arena_backdrop() -> void:
    var soft_accent := Color(arena_accent, 0.10)
    match arena_theme:
        "factory":
            for i in range(8):
                var x := 70.0 + float(i) * 165.0
                var height := 110.0 + float((i * 47) % 170)
                draw_rect(Rect2(x, 470.0 - height, 54.0, height), Color(arena_accent, 0.035))
                draw_line(Vector2(x + 8.0, 470.0 - height), Vector2(x + 46.0, 470.0 - height), soft_accent, 3.0)
        "sky":
            for i in range(5):
                var x := 120.0 + float(i) * 255.0 + sin(background_time * 0.22 + float(i)) * 18.0
                var y := 145.0 + float((i * 61) % 150)
                draw_circle(Vector2(x, y), 38.0, Color(0.76, 0.88, 1.0, 0.035))
                draw_circle(Vector2(x + 30.0, y + 8.0), 26.0, Color(0.76, 0.88, 1.0, 0.03))
        "jungle":
            for i in range(9):
                var x := float(i) * 165.0 + 20.0
                var sway := sin(background_time * 0.5 + float(i)) * 8.0
                draw_colored_polygon(PackedVector2Array([Vector2(x - 42.0, 490.0), Vector2(x + sway, 180.0 + float(i % 3) * 38.0), Vector2(x + 42.0, 490.0)]), Color(arena_accent, 0.045))
                draw_line(Vector2(x + sway, 230.0), Vector2(x + sway, 500.0), Color(arena_accent, 0.07), 3.0)
        "rift":
            for i in range(7):
                var radius := 90.0 + float(i) * 48.0
                var phase_offset := background_time * (0.18 if i % 2 == 0 else -0.14)
                draw_arc(Vector2(640.0, 390.0), radius, phase_offset, phase_offset + PI * 1.35, 48, Color(arena_accent, 0.075), 2.0, true)
        "ice":
            for i in range(8):
                var x := 60.0 + float(i) * 170.0
                var height := 100.0 + float((i * 53) % 145)
                draw_colored_polygon(PackedVector2Array([Vector2(x - 34.0, 470.0), Vector2(x, 470.0 - height), Vector2(x + 34.0, 470.0)]), Color(arena_accent, 0.035))
                draw_line(Vector2(x, 470.0 - height + 12.0), Vector2(x, 470.0), Color(0.82, 0.95, 1.0, 0.08), 1.5)
        "sunset":
            for i in range(5):
                var radius := 70.0 + float(i) * 25.0
                draw_arc(Vector2(1000.0, 250.0), radius, PI, TAU, 48, Color(arena_accent, 0.08), 2.0, true)
        "crystal":
            for i in range(10):
                var x := 55.0 + float(i) * 130.0
                var y := 155.0 + float((i * 37) % 180)
                draw_colored_polygon(PackedVector2Array([Vector2(x, y - 34.0), Vector2(x + 12.0, y), Vector2(x, y + 34.0), Vector2(x - 12.0, y)]), Color(arena_accent, 0.09))
        "volcano":
            for i in range(6):
                var x := 90.0 + float(i) * 225.0
                var peak := 320.0 + float((i * 31) % 100)
                draw_colored_polygon(PackedVector2Array([Vector2(x - 100.0, 500.0), Vector2(x, peak), Vector2(x + 100.0, 500.0)]), Color("#160f18", 0.32))
                draw_line(Vector2(x - 8.0, peak + 20.0), Vector2(x + 8.0, peak + 20.0), Color(arena_accent, 0.22), 3.0)
        "harbor":
            for i in range(7):
                var x := 70.0 + float(i) * 190.0
                draw_line(Vector2(x, 170.0), Vector2(x, 480.0), Color(arena_accent, 0.055), 3.0)
                draw_line(Vector2(x - 28.0, 210.0), Vector2(x + 28.0, 210.0), Color(arena_accent, 0.07), 2.0)
        _:
            for i in range(7):
                var x := 90.0 + float(i) * 185.0
                var height := 80.0 + float((i * 41) % 130)
                draw_rect(Rect2(x, 470.0 - height, 42.0, height), Color(arena_accent, 0.025))


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
    visual.color = arena_platform_color.darkened(0.28)
    wall.add_child(visual)
    var edge := Line2D.new()
    edge.points = PackedVector2Array([Vector2(0,-450),Vector2(0,450)])
    edge.width = 3.0
    edge.default_color = Color(arena_accent,0.35)
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
    visual.color = arena_platform_color
    body.add_child(visual)
    var lower_glow := Polygon2D.new()
    lower_glow.polygon = PackedVector2Array([Vector2(-dimensions.x/2,dimensions.y/2),Vector2(dimensions.x/2,dimensions.y/2),Vector2(dimensions.x/2,dimensions.y/2+5),Vector2(-dimensions.x/2,dimensions.y/2+5)])
    lower_glow.color = Color(arena_accent.darkened(0.18),0.55)
    body.add_child(lower_glow)
    var glow := Line2D.new()
    glow.points = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2)])
    glow.width = 12.0
    glow.default_color = Color(arena_accent,0.15)
    glow.antialiased = true
    body.add_child(glow)
    var stripe := Line2D.new()
    stripe.points = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2)])
    stripe.width = 3.5
    stripe.default_color = arena_accent
    stripe.antialiased = true
    body.add_child(stripe)
    var edge := Line2D.new()
    edge.points = PackedVector2Array([Vector2(-dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,-dimensions.y/2),Vector2(dimensions.x/2,dimensions.y/2),Vector2(-dimensions.x/2,dimensions.y/2),Vector2(-dimensions.x/2,-dimensions.y/2)])
    edge.width = 1.2
    edge.default_color = Color(arena_accent.lightened(0.18),0.45)
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
        {"id":"kiwi_araga","name":"Киви Арага","color":"#e9c5a8","style":"kiwi_human"}
    ]
    skins.append_array(mod_loader.skins)
    return skins

func _apply_skin() -> void:
    # Keep preview, saved selection and equipped skin on one shared list.
    var skins := _get_skins()
    if skins.is_empty():
        skin_index = 0
        return
    skin_index = clampi(skin_index, 0, skins.size() - 1)
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
    var skins := _get_skins()
    if skins.is_empty():
        return
    skin_index = posmod(skin_index + 1, skins.size())
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
    if phase == "fight" and (player.health <= 0 or rival.health <= 0):
        call_deferred("_finish_round", player.health > 0)

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
    player_health_bar = _create_health_bar(ui, Vector2(24, 68), Color("#55dfb0"))
    rival_health_bar = _create_health_bar(ui, Vector2(956, 68), Color("#ff7c86"))
    player_health_text = _create_health_label(ui, Vector2(24, 43), "ТЫ")
    rival_health_text = _create_health_label(ui, Vector2(956, 43), "СОПЕРНИК")
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
    reload_button.pressed.connect(_request_reload)
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
    aim_joystick.released.connect(player.shoot_once)
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

func _create_health_bar(parent: Control, at: Vector2, fill_color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = at
    bar.size = Vector2(300, 18)
    bar.min_value = 0
    bar.max_value = 100
    bar.show_percentage = false
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color("#111c2a", 0.94)
    bg.set_corner_radius_all(8)
    var fill := StyleBoxFlat.new()
    fill.bg_color = fill_color
    fill.set_corner_radius_all(8)
    bar.add_theme_stylebox_override("background", bg)
    bar.add_theme_stylebox_override("fill", fill)
    parent.add_child(bar)
    return bar

func _create_health_label(parent: Control, at: Vector2, caption: String) -> Label:
    var label := Label.new()
    label.position = at
    label.size = Vector2(300, 22)
    label.text = caption
    label.add_theme_font_size_override("font_size", 14)
    label.add_theme_color_override("font_color", Color("#eaf2fb"))
    parent.add_child(label)
    return label

func _request_reload() -> void:
    if online_in_match and not online_is_host:
        online_reload_pending = true
    else:
        player.start_reload()

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

func _setup_music() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "BackgroundMusic"
    music_player.bus = "Master"
    music_player.volume_db = -8.0
    add_child(music_player)
    music_player.finished.connect(_play_next_music)
    _apply_audio_settings()
    _play_round_music()

func _play_next_music() -> void:
    if not is_instance_valid(music_player) or music_tracks.is_empty():
        return
    _play_music_index((music_last_index + 1) % music_tracks.size())

func _play_round_music() -> void:
    if music_tracks.is_empty():
        return
    var index := posmod(round_index - 1, music_tracks.size())
    if index == music_last_index and is_instance_valid(music_player) and music_player.playing:
        return
    _play_music_index(index)

func _play_music_index(index: int) -> void:
    if not is_instance_valid(music_player) or music_tracks.is_empty():
        return
    music_last_index = posmod(index, music_tracks.size())
    var stream := load(music_tracks[music_last_index]) as AudioStream
    if stream == null:
        push_warning("Не удалось загрузить музыку: " + music_tracks[music_last_index])
        if music_last_index == 3:
            # AAC import is not available on every Godot Android export; skip it gracefully.
            _play_music_index((music_last_index + 1) % music_tracks.size())
        return
    music_player.stream = stream
    music_player.play()
    _update_music_track_button()

func _update_music_track_button() -> void:
    if not is_instance_valid(music_track_button) or music_last_index < 0 or music_last_index >= music_tracks.size():
        return
    var track_name := music_display_names[music_last_index] if music_last_index < music_display_names.size() else "Трек"
    music_track_button.text = "♫  " + track_name + "   ›"
    music_track_button.tooltip_text = "Нажми, чтобы переключить трек"

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
    _poll_online_socket()
    _online_sync_tick(delta)
    background_time += delta
    if is_instance_valid(menu_record_needle):
        menu_record_needle.rotation = background_time * 2.8
    for i in range(music_visualizer_bars.size()):
        var bar := music_visualizer_bars[i]
        if is_instance_valid(bar):
            var pulse := 0.25 + 0.75 * absf(sin(background_time * (5.0 + float(i) * 0.7) + float(i) * 1.2))
            bar.scale.y = pulse
            bar.position.y = 3.0 + (1.0 - pulse) * 8.0
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
        if is_instance_valid(player_health_bar):
            player_health_bar.visible = false
        if is_instance_valid(rival_health_bar):
            rival_health_bar.visible = false
        if is_instance_valid(player_health_text):
            player_health_text.visible = false
        if is_instance_valid(rival_health_text):
            rival_health_text.visible = false
        return
    if is_instance_valid(ammo_label):
        ammo_label.text = player.ammo_text()
    _update_hud()
    if player.health <= 0 or player.global_position.y > 850:
        _finish_round(false)
    elif rival.health <= 0 or rival.global_position.y > 850:
        _finish_round(true)

func _start_game(mode: String) -> void:
    _clear_pulses()
    online_in_match = false
    player.remote_controlled = false
    rival.remote_controlled = false
    game_mode = mode
    player.set_physics_process(true)
    rival.visible = mode != "training"
    rival.set_physics_process(mode != "training")
    rival.collision_layer = 0 if mode == "training" else 1
    player.target = rival if mode != "training" else null
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
    if mode != "training":
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
    who.health = who.max_health

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
    shade.color = Color(0, 0, 0, 0)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(shade)
    overlay = shade

    # Full-screen live arena is created first, so all menu controls render above it.
    _create_menu_bot_preview(shade)
    _create_menu_record(shade)

    var logo := Label.new()
    logo.name = "MenuLogo"
    logo.text = "KIWI  ROUNDS"
    logo.position = Vector2(390, 22)
    logo.size = Vector2(500, 66)
    logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    logo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    logo.add_theme_font_size_override("font_size", 42)
    logo.add_theme_color_override("font_color", Color("#f4f7ff"))
    logo.add_theme_color_override("font_shadow_color", Color("#36e6df", 0.65))
    logo.add_theme_constant_override("shadow_offset_x", 0)
    logo.add_theme_constant_override("shadow_offset_y", 2)
    logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shade.add_child(logo)

    var subtitle := Label.new()
    subtitle.text = "NEON BOT ARENA  •  RANDOM MAPS  •  RANDOM BUILDS"
    subtitle.position = Vector2(300, 105)
    subtitle.size = Vector2(680, 24)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", Color("#a9e9ee"))
    shade.add_child(subtitle)

    # Centered translucent menu keeps the live fight visible around it.
    var menu_panel := Panel.new()
    menu_panel.position = Vector2(425, 155)
    menu_panel.size = Vector2(430, 390)
    var menu_style := StyleBoxFlat.new()
    menu_style.bg_color = Color("#091321", 0.78)
    menu_style.border_color = Color("#36e6df", 0.82)
    menu_style.set_border_width_all(2)
    menu_style.set_corner_radius_all(22)
    menu_style.shadow_color = Color("#36e6df", 0.22)
    menu_style.shadow_size = 22
    menu_panel.add_theme_stylebox_override("panel", menu_style)
    shade.add_child(menu_panel)

    var play := _add_button("▶   ИГРАТЬ", Vector2(465, 238), Vector2(350, 66), shade)
    play.add_theme_font_size_override("font_size", 25)
    play.add_theme_stylebox_override("normal", _menu_button_style(Color("#36e6df"), Color("#b5fff4")))
    play.add_theme_color_override("font_color", Color("#07151d"))
    play.pressed.connect(_show_mode_menu)

    var skins := _add_button("✦   СКИНЫ", Vector2(465, 322), Vector2(350, 58), shade)
    skins.add_theme_stylebox_override("normal", _menu_button_style(Color("#172b43"), Color("#8b67ff")))
    skins.add_theme_color_override("font_color", Color("#e8f6ff"))
    skins.pressed.connect(_open_skins)

    var settings := _add_button("⚙   НАСТРОЙКИ", Vector2(465, 394), Vector2(350, 58), shade)
    settings.add_theme_stylebox_override("normal", _menu_button_style(Color("#172b43"), Color("#36e6df")))
    settings.add_theme_color_override("font_color", Color("#e8f6ff"))
    settings.pressed.connect(_show_settings)

    var mods := _add_button("▣   МОДЫ", Vector2(465, 466), Vector2(350, 58), shade)
    mods.add_theme_stylebox_override("normal", _menu_button_style(Color("#172b43"), Color("#8b67ff")))
    mods.add_theme_color_override("font_color", Color("#e8f6ff"))
    mods.pressed.connect(_open_mods)

    var footer := Label.new()
    footer.text = "KIWI LABS   •   BUILD. FIGHT. REPEAT."
    footer.position = Vector2(425, 508)
    footer.size = Vector2(430, 22)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 12)
    footer.add_theme_color_override("font_color", Color("#9bb8c9"))
    shade.add_child(footer)

func _create_menu_record(parent: Control) -> void:
    var record := Panel.new()
    record.name = "MenuVinylRecord"
    record.position = Vector2(1120, 64)
    record.size = Vector2(96, 96)
    record.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var outer := StyleBoxFlat.new()
    outer.bg_color = Color("#101923")
    outer.border_color = Color("#526779")
    outer.set_border_width_all(2)
    outer.set_corner_radius_all(48)
    record.add_theme_stylebox_override("panel", outer)
    parent.add_child(record)

    var ring := Panel.new()
    ring.position = Vector2(12, 12)
    ring.size = Vector2(72, 72)
    ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var ring_style := StyleBoxFlat.new()
    ring_style.bg_color = Color("#172536")
    ring_style.border_color = Color("#526779", 0.8)
    ring_style.set_border_width_all(2)
    ring_style.set_corner_radius_all(36)
    ring.add_theme_stylebox_override("panel", ring_style)
    record.add_child(ring)

    for i in range(3):
        var groove := Panel.new()
        var inset := 20.0 + float(i) * 10.0
        groove.position = Vector2(inset, inset)
        groove.size = Vector2(72.0 - inset * 2.0, 72.0 - inset * 2.0)
        groove.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var groove_style := StyleBoxFlat.new()
        groove_style.bg_color = Color(0, 0, 0, 0)
        groove_style.border_color = Color("#718095", 0.42)
        groove_style.set_border_width_all(1)
        groove_style.set_corner_radius_all(36)
        groove.add_theme_stylebox_override("panel", groove_style)
        ring.add_child(groove)

    menu_record_needle = ColorRect.new()
    menu_record_needle.name = "MenuRecordNeedle"
    menu_record_needle.position = Vector2(47, 46)
    menu_record_needle.size = Vector2(35, 4)
    menu_record_needle.pivot_offset = Vector2(2, 2)
    menu_record_needle.color = Color("#36e6df")
    menu_record_needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    record.add_child(menu_record_needle)

    var visualizer := HBoxContainer.new()
    visualizer.position = Vector2(1000, 172)
    visualizer.size = Vector2(190, 24)
    visualizer.add_theme_constant_override("separation", 5)
    visualizer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(visualizer)
    music_visualizer_bars.clear()
    for i in range(12):
        var bar := ColorRect.new()
        bar.custom_minimum_size = Vector2(7, 20)
        bar.size = Vector2(7, 20)
        bar.color = Color("#36e6df") if i % 3 != 0 else Color("#d9ef70")
        bar.pivot_offset = Vector2(3.5, 10)
        bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        visualizer.add_child(bar)
        music_visualizer_bars.append(bar)

    music_track_button = Button.new()
    music_track_button.position = Vector2(965, 202)
    music_track_button.size = Vector2(260, 42)
    music_track_button.text = "♫  Загрузка музыки..."
    music_track_button.tooltip_text = "Нажми, чтобы переключить трек"
    music_track_button.add_theme_font_size_override("font_size", 13)
    music_track_button.add_theme_color_override("font_color", Color("#eaf2fb"))
    music_track_button.add_theme_stylebox_override("normal", _menu_button_style(Color("#172536"), Color("#526779")))
    music_track_button.add_theme_stylebox_override("hover", _menu_button_style(Color("#20394c"), Color("#36e6df")))
    music_track_button.add_theme_stylebox_override("pressed", _menu_button_style(Color("#101923"), Color("#d9ef70")))
    music_track_button.pressed.connect(_play_next_music)
    parent.add_child(music_track_button)
    _update_music_track_button()

    var hub := Panel.new()
    hub.position = Vector2(39, 39)
    hub.size = Vector2(18, 18)
    hub.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var hub_style := StyleBoxFlat.new()
    hub_style.bg_color = Color("#d9ef70")
    hub_style.set_corner_radius_all(9)
    hub.add_theme_stylebox_override("panel", hub_style)
    record.add_child(hub)

func _create_menu_bot_preview(parent: Control) -> void:
    # Full-screen background sparring match, independent from the real match state.
    var stage := Node2D.new()
    stage.name = "MenuBotPreview"
    stage.position = Vector2.ZERO
    parent.add_child(stage)

    var map_data: Dictionary = all_maps.pick_random() if not all_maps.is_empty() else DEFAULT_MAPS[0]
    var bg := ColorRect.new()
    bg.position = Vector2.ZERO
    bg.size = Vector2(1280, 720)
    bg.color = Color.from_string(str(map_data.get("bg_bottom", "#101a2a")), Color("#101a2a"))
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(bg)
    parent.move_child(bg, 0)
    parent.move_child(stage, 1)

    # Soft horizon and floor lighting make the whole viewport feel like an arena.
    var horizon := Polygon2D.new()
    horizon.polygon = PackedVector2Array([Vector2(0,0),Vector2(1280,0),Vector2(1280,520),Vector2(0,520)])
    horizon.color = Color.from_string(str(map_data.get("bg_top", "#172234")), Color("#172234"))
    stage.add_child(horizon)

    var ground := StaticBody2D.new()
    ground.position = Vector2(640, 690)
    ground.collision_layer = 2
    var ground_shape := CollisionShape2D.new()
    var ground_rect := RectangleShape2D.new()
    ground_rect.size = Vector2(1280, 80)
    ground_shape.shape = ground_rect
    ground.add_child(ground_shape)
    stage.add_child(ground)
    _add_menu_preview_platform(stage, Vector2(640, 650), Vector2(1280, 18), Color.from_string(str(map_data.get("accent", "#36e6df")), Color("#36e6df")), false)

    for wall_x in [18.0, 1262.0]:
        var wall := StaticBody2D.new()
        wall.position = Vector2(wall_x, 360)
        wall.collision_layer = 2
        var wall_shape := CollisionShape2D.new()
        var wall_rect := RectangleShape2D.new()
        wall_rect.size = Vector2(36, 720)
        wall_shape.shape = wall_rect
        wall.add_child(wall_shape)
        stage.add_child(wall)

    var platform_data: Array = map_data.get("platforms", [])
    var used_platforms := 0
    for item in platform_data:
        if typeof(item) != TYPE_DICTIONARY:
            continue
        var px := clampf(float(item.get("x", 640)), 130.0, 1150.0)
        var py := clampf(float(item.get("y", 500)), 310.0, 605.0)
        var pw := clampf(float(item.get("w", 170)), 110.0, 290.0)
        _add_menu_preview_platform(stage, Vector2(px, py), Vector2(pw, 16), Color.from_string(str(map_data.get("accent", "#36e6df")), Color("#36e6df")), true)
        used_platforms += 1
        if used_platforms >= 6:
            break

    var bot_a: ArenaPlayer = PLAYER_SCRIPT.new()
    bot_a.name = "MenuBotKiwi"
    bot_a.is_bot = true
    bot_a.menu_preview_mode = false
    bot_a.body_color = Color("#e8bd9c")
    bot_a.skin_style = "kiwi_human"
    bot_a.position = Vector2(360, 585)
    bot_a.bot_accuracy = 0.86
    bot_a.move_speed = 430.0
    bot_a.pulse_force = 610.0
    bot_a.pulse_interval = 0.56
    bot_a.magazine_size = 8
    bot_a.ammo = 8
    bot_a.reload_duration = 1.1
    bot_a.bot_think = 0.04
    stage.add_child(bot_a)
    bot_a.set_physics_process(true)

    var bot_b: ArenaPlayer = PLAYER_SCRIPT.new()
    bot_b.name = "MenuBotPink"
    bot_b.is_bot = true
    bot_b.menu_preview_mode = false
    bot_b.body_color = Color("#ff6fae")
    bot_b.position = Vector2(920, 585)
    bot_b.bot_accuracy = 0.86
    bot_b.move_speed = 430.0
    bot_b.pulse_force = 610.0
    bot_b.pulse_interval = 0.56
    bot_b.magazine_size = 8
    bot_b.ammo = 8
    bot_b.reload_duration = 1.1
    bot_b.bot_think = 0.04
    stage.add_child(bot_b)
    bot_b.set_physics_process(true)
    bot_a.target = bot_b
    bot_b.target = bot_a
    bot_a.pulse_requested.connect(_spawn_menu_preview_pulse.bind(stage))
    bot_b.pulse_requested.connect(_spawn_menu_preview_pulse.bind(stage))

    # Each menu visit gets a different small set of combat upgrades.
    var preview_upgrade_pool: Array = []
    for upgrade in all_upgrades:
        var effect := str(upgrade.get("effect", upgrade.get("id", "")))
        if effect in ["homing", "ricochet", "heavy", "rapid", "magazine", "piercing", "kiwi_charm"]:
            preview_upgrade_pool.append(upgrade)
    preview_upgrade_pool.shuffle()
    if preview_upgrade_pool.size() > 0:
        bot_a.apply_upgrade(str(preview_upgrade_pool[0].get("effect", preview_upgrade_pool[0].get("id", ""))))
    if preview_upgrade_pool.size() > 1:
        bot_b.apply_upgrade(str(preview_upgrade_pool[1].get("effect", preview_upgrade_pool[1].get("id", ""))))

func _add_menu_preview_platform(stage: Node2D, at: Vector2, dimensions: Vector2, accent: Color, collide: bool = true) -> void:
    var body := StaticBody2D.new()
    body.position = at
    body.collision_layer = 2 if collide else 0
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = dimensions
    shape.shape = rect
    body.add_child(shape)
    var visual := Polygon2D.new()
    visual.polygon = PackedVector2Array([
        Vector2(-dimensions.x / 2, -dimensions.y / 2),
        Vector2(dimensions.x / 2, -dimensions.y / 2),
        Vector2(dimensions.x / 2, dimensions.y / 2),
        Vector2(-dimensions.x / 2, dimensions.y / 2)
    ])
    visual.color = Color("#17263b")
    body.add_child(visual)
    var glow := Line2D.new()
    glow.points = PackedVector2Array([Vector2(-dimensions.x / 2, -dimensions.y / 2), Vector2(dimensions.x / 2, -dimensions.y / 2)])
    glow.width = 5.0
    glow.default_color = accent
    glow.antialiased = true
    body.add_child(glow)
    stage.add_child(body)

func _spawn_menu_preview_pulse(origin: Vector2, direction: Vector2, force: float, tint: Color, shooter: Node2D, stage: Node2D) -> void:
    var pulse: EnergyPulse = PULSE_SCRIPT.new()
    pulse.configure(direction, force, tint, shooter)
    pulse.global_position = origin
    stage.add_child(pulse)


func _add_menu_battle_scene(parent: Control) -> void:
    # Four frozen fighter poses create a layered firefight illustration.
    var hide_a: ArenaPlayer = PLAYER_SCRIPT.new()
    hide_a.body_color = Color("#f2e5ce")
    hide_a.skin_style = "kiwi"
    hide_a.position = Vector2(790,455)
    hide_a.facing = 1.0
    hide_a.aim_input = Vector2(1,-0.35)
    hide_a.scale = Vector2(1.35,1.35)
    hide_a.set_physics_process(false)
    hide_a.set_process(false)
    parent.add_child(hide_a)

    var hide_b: ArenaPlayer = PLAYER_SCRIPT.new()
    hide_b.body_color = Color("#b47cff")
    hide_b.position = Vector2(900,448)
    hide_b.facing = 1.0
    hide_b.aim_input = Vector2(1,-0.18)
    hide_b.scale = Vector2(1.25,1.25)
    hide_b.set_physics_process(false)
    hide_b.set_process(false)
    parent.add_child(hide_b)

    var shooter_a: ArenaPlayer = PLAYER_SCRIPT.new()
    shooter_a.body_color = Color("#ff786f")
    shooter_a.position = Vector2(1050,390)
    shooter_a.facing = -1.0
    shooter_a.aim_input = Vector2(-0.9,-0.35)
    shooter_a.scale = Vector2(1.45,1.45)
    shooter_a.set_physics_process(false)
    shooter_a.set_process(false)
    parent.add_child(shooter_a)

    var shooter_b: ArenaPlayer = PLAYER_SCRIPT.new()
    shooter_b.body_color = Color("#ffc857")
    shooter_b.position = Vector2(1160,430)
    shooter_b.facing = -1.0
    shooter_b.aim_input = Vector2(-1,-0.12)
    shooter_b.scale = Vector2(1.2,1.2)
    shooter_b.set_physics_process(false)
    shooter_b.set_process(false)
    parent.add_child(shooter_b)

    # Muzzle streaks sit behind the cover to sell crossfire and depth.
    var tracer_back := Line2D.new()
    tracer_back.points = PackedVector2Array([Vector2(1015,375),Vector2(900,410),Vector2(820,430)])
    tracer_back.width = 13.0
    tracer_back.default_color = Color("#ff9b72",0.20)
    tracer_back.antialiased = true
    parent.add_child(tracer_back)
    var tracer_front := Line2D.new()
    tracer_front.points = PackedVector2Array([Vector2(1125,418),Vector2(1010,440),Vector2(945,450)])
    tracer_front.width = 5.0
    tracer_front.default_color = Color("#ffe8a1",0.72)
    tracer_front.antialiased = true
    parent.add_child(tracer_front)

    var wall_shadow := Polygon2D.new()
    wall_shadow.polygon = PackedVector2Array([Vector2(700,500),Vector2(1190,500),Vector2(1210,610),Vector2(680,610)])
    wall_shadow.color = Color("#080e17",0.72)
    parent.add_child(wall_shadow)
    var cover := Polygon2D.new()
    cover.polygon = PackedVector2Array([Vector2(690,475),Vector2(1195,475),Vector2(1170,590),Vector2(715,590)])
    cover.color = Color("#34495a")
    parent.add_child(cover)
    var cover_top := Polygon2D.new()
    cover_top.polygon = PackedVector2Array([Vector2(690,475),Vector2(1195,475),Vector2(1183,492),Vector2(700,492)])
    cover_top.color = Color("#8da5a8")
    parent.add_child(cover_top)
    var cover_edge := Line2D.new()
    cover_edge.points = PackedVector2Array([Vector2(690,475),Vector2(1195,475),Vector2(1170,590),Vector2(715,590),Vector2(690,475)])
    cover_edge.width = 3.0
    cover_edge.default_color = Color("#b9e36c",0.75)
    cover_edge.antialiased = true
    parent.add_child(cover_edge)

    var label := Label.new()
    label.text = "COVER FIRE  /  KIWI SQUAD"
    label.position = Vector2(680,92)
    label.size = Vector2(480,28)
    label.add_theme_font_size_override("font_size",14)
    label.add_theme_color_override("font_color",Color("#b9e36c"))
    parent.add_child(label)

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
        ["ОНЛАЙН",Callable(self,"_show_online_info")],
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
    _close_overlay()
    game_controls.visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#0b1019")
    ui.add_child(shade)
    overlay = shade
    _add_menu_ornaments(shade)
    var title := Label.new()
    title.text = "СЕТЕВАЯ ИГРА"
    title.position = Vector2(0, 25)
    title.size = Vector2(1280, 55)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.add_theme_color_override("font_color", Color("#f3f1e8"))
    shade.add_child(title)
    online_status_label = Label.new()
    online_status_label.position = Vector2(250, 90)
    online_status_label.size = Vector2(780, 38)
    online_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    online_status_label.add_theme_font_size_override("font_size", 17)
    online_status_label.text = "Подключение..."
    shade.add_child(online_status_label)
    var left := Panel.new()
    left.position = Vector2(105, 150)
    left.size = Vector2(500, 430)
    left.add_theme_stylebox_override("panel", _menu_button_style(Color("#172333"), Color("#36e6df")))
    shade.add_child(left)
    var right := Panel.new()
    right.position = Vector2(675, 150)
    right.size = Vector2(500, 430)
    right.add_theme_stylebox_override("panel", _menu_button_style(Color("#172333"), Color("#8b67ff")))
    shade.add_child(right)
    var name_title := Label.new()
    name_title.text = "ТВОЙ НИК"
    name_title.position = Vector2(140, 175)
    name_title.size = Vector2(430, 30)
    name_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_title.add_theme_color_override("font_color", Color("#f3f1e8"))
    shade.add_child(name_title)
    online_name_input = LineEdit.new()
    online_name_input.text = "Игрок"
    online_name_input.placeholder_text = "Имя игрока"
    online_name_input.position = Vector2(165, 215)
    online_name_input.size = Vector2(380, 42)
    shade.add_child(online_name_input)
    var room_title := Label.new()
    room_title.text = "НАЗВАНИЕ НОВОЙ КОМНАТЫ"
    room_title.position = Vector2(140, 275)
    room_title.size = Vector2(430, 30)
    room_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    room_title.add_theme_color_override("font_color", Color("#f3f1e8"))
    shade.add_child(room_title)
    online_room_name_input = LineEdit.new()
    online_room_name_input.text = "Комната Kiwi"
    online_room_name_input.position = Vector2(165, 315)
    online_room_name_input.size = Vector2(380, 42)
    shade.add_child(online_room_name_input)
    online_password_input = LineEdit.new()
    online_password_input.placeholder_text = "Пароль комнаты (необязательно)"
    online_password_input.secret = true
    online_password_input.position = Vector2(165, 370)
    online_password_input.size = Vector2(380, 42)
    shade.add_child(online_password_input)
    var create := _add_button("СОЗДАТЬ КОМНАТУ", Vector2(205, 435), Vector2(300, 52), shade)
    create.pressed.connect(_online_create_room)
    online_start_button = _add_button("НАЧАТЬ БОЙ", Vector2(205, 500), Vector2(300, 52), shade)
    online_start_button.visible = false
    online_start_button.pressed.connect(_online_start_match)
    var refresh := _add_button("ОБНОВИТЬ", Vector2(775, 175), Vector2(300, 48), shade)
    refresh.pressed.connect(_online_request_rooms)
    var rooms_title := Label.new()
    rooms_title.text = "СПИСОК КОМНАТ"
    rooms_title.position = Vector2(700, 235)
    rooms_title.size = Vector2(450, 32)
    rooms_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rooms_title.add_theme_color_override("font_color", Color("#f3f1e8"))
    shade.add_child(rooms_title)
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(710, 275)
    scroll.size = Vector2(430, 270)
    shade.add_child(scroll)
    online_rooms_list = VBoxContainer.new()
    online_rooms_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    online_rooms_list.add_theme_constant_override("separation", 8)
    scroll.add_child(online_rooms_list)
    var back := _add_button("НАЗАД", Vector2(520, 615), Vector2(240, 52), shade)
    back.pressed.connect(_show_mode_menu)
    if online_socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
        online_connected = true
        _online_set_status("Подключено к серверу", Color("#9be89b"))
        _online_request_rooms()
    else:
        _online_connect()

func _online_connect() -> void:
    if online_connecting:
        return
    online_socket = WebSocketPeer.new()
    var err := online_socket.connect_to_url(ONLINE_SERVER_URL)
    if err != OK:
        _online_set_status("Ошибка подключения: " + str(err), Color("#ff8b8b"))
        return
    online_connecting = true
    _online_set_status("Подключаемся к серверу...", Color("#d9ef70"))

func _poll_online_socket() -> void:
    if online_socket == null:
        return
    online_socket.poll()
    var state := online_socket.get_ready_state()
    if state == WebSocketPeer.STATE_OPEN:
        if not online_connected:
            online_connected = true
            online_connecting = false
            _online_set_status("Соединение установлено", Color("#9be89b"))
            var nick := "Игрок"
            if is_instance_valid(online_name_input) and online_name_input.text.strip_edges() != "":
                nick = online_name_input.text.strip_edges()
            _online_send({"type":"set_name", "name":nick})
            _online_request_rooms()
        while online_socket.get_available_packet_count() > 0:
            var packet := online_socket.get_packet()
            var data: Variant = JSON.parse_string(packet.get_string_from_utf8())
            if typeof(data) == TYPE_DICTIONARY:
                _online_handle_message(data)
    elif state == WebSocketPeer.STATE_CLOSED and (online_connected or online_connecting):
        online_connected = false
        online_connecting = false
        _online_set_status("Связь потеряна. Вернись назад и снова открой онлайн.", Color("#ff8b8b"))

func _online_send(data: Dictionary) -> void:
    if online_socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
        online_socket.send_text(JSON.stringify(data))

func _online_request_rooms() -> void:
    if online_connected:
        _online_send({"type":"list_rooms"})

func _online_create_room() -> void:
    if not online_connected:
        _online_set_status("Нет соединения с сервером", Color("#ff8b8b"))
        return
    var nick := online_name_input.text.strip_edges()
    if nick == "":
        nick = "Игрок"
    _online_send({"type":"set_name", "name":nick})
    _online_send({"type":"create_room", "name":online_room_name_input.text.strip_edges(), "password":online_password_input.text})
    _online_set_status("Создаём комнату...", Color("#d9ef70"))

func _online_join_room(room_id: String) -> void:
    if not online_connected:
        return
    var nick := online_name_input.text.strip_edges()
    if nick == "":
        nick = "Игрок"
    _online_send({"type":"set_name", "name":nick})
    _online_send({"type":"join_room", "roomId":room_id, "password":online_password_input.text})
    _online_set_status("Подключаемся к комнате...", Color("#d9ef70"))

func _online_handle_message(data: Dictionary) -> void:
    match str(data.get("type", "")):
        "connected":
            online_player_id = str(data.get("playerId", ""))
            _online_set_status("Сервер принял подключение", Color("#9be89b"))
        "room_list":
            _online_render_rooms(data.get("rooms", []))
        "room_joined":
            _online_set_status("В комнате " + str(data.get("roomId", "")) + ". Ожидаем соперника.", Color("#9be89b"))
        "room_state":
            var room: Dictionary = data.get("room", {})
            online_host_id = str(room.get("hostId", ""))
            online_is_host = online_host_id == online_player_id
            var names: Array[String] = []
            var room_players: Array = room.get("players", [])
            for person in room_players:
                if typeof(person) == TYPE_DICTIONARY:
                    names.append(str(person.get("name", "Игрок")))
            if is_instance_valid(online_start_button):
                online_start_button.visible = online_is_host and room_players.size() == 2
            _online_set_status(str(room.get("name", "Комната")) + " • " + str(names), Color("#9be89b"))
        "match_started":
            _start_online_match(str(data.get("hostId", "")))
        "game_input":
            if online_in_match and online_is_host:
                var input_data: Dictionary = data.get("input", {})
                rival.remote_controlled = true
                rival.remote_move = float(input_data.get("move", 0.0))
                rival.remote_aim = Vector2(float(input_data.get("aimX", 1.0)), float(input_data.get("aimY", 0.0))).normalized()
                rival.remote_jump = bool(input_data.get("jump", false))
                rival.remote_fire = bool(input_data.get("fire", false))
                rival.remote_reload = bool(input_data.get("reload", false))
        "game_state":
            if online_in_match and not online_is_host:
                _apply_online_state(data.get("state", {}))
        "error":
            _online_set_status(str(data.get("message", "Ошибка сервера")), Color("#ff8b8b"))

func _online_start_match() -> void:
    if online_connected and online_is_host:
        _online_send({"type":"start_match"})

func _start_online_match(host_id: String) -> void:
    online_is_host = host_id == online_player_id
    online_in_match = true
    online_sync_timer = 0.0
    game_mode = "online"
    score_player = 0
    score_bot = 0
    round_index = 1
    active_training_cards.clear()
    _reset_player_stats(player)
    _reset_player_stats(rival)
    _make_arena(0)
    player.reset_round(Vector2(350,390))
    rival.reset_round(Vector2(930,390))
    player.target = rival
    rival.target = player
    rival.visible = true
    if online_is_host:
        player.remote_controlled = false
        rival.remote_controlled = true
        player.set_physics_process(true)
        rival.set_physics_process(true)
    else:
        player.set_physics_process(false)
        rival.set_physics_process(false)
    phase = "fight"
    _close_overlay()
    game_controls.visible = true
    hud.visible = true
    _update_hud()

func _online_sync_tick(delta: float) -> void:
    if not online_in_match or not online_connected:
        return
    online_sync_timer += delta
    if online_is_host:
        if online_sync_timer >= 0.05:
            online_sync_timer = 0.0
            _online_send({
                "type":"game_state",
                "state":{
                    "player_pos":[player.global_position.x, player.global_position.y],
                    "player_vel":[player.velocity.x, player.velocity.y],
                    "rival_pos":[rival.global_position.x, rival.global_position.y],
                    "rival_vel":[rival.velocity.x, rival.velocity.y],
                    "score_player":score_player,
                    "score_bot":score_bot,
                    "round":round_index,
                    "phase":phase,
                    "map_index":map_index,
                    "player_ammo":player.ammo,
                    "rival_ammo":rival.ammo,
                    "player_reload":player.reload_timer,
                    "rival_reload":rival.reload_timer,
                    "player_stats":{
                        "move_speed":player.move_speed,"jump_speed":player.jump_speed,
                        "gravity_scale":player.gravity_scale,"air_control_scale":player.air_control_scale,
                        "ground_accel_scale":player.ground_accel_scale,"wall_jump_scale":player.wall_jump_scale,
                        "extra_air_jumps":player.extra_air_jumps,"pulse_force":player.pulse_force,
                        "pulse_interval":player.pulse_interval,"magazine_size":player.magazine_size,
                        "reload_duration":player.reload_duration,"homing_strength":player.homing_strength,
                        "ricochet_count":player.ricochet_count,"projectile_speed":player.projectile_speed,
                        "weapon_level":player.weapon_level,"kiwi_aura":player.kiwi_aura
                    },
                    "rival_stats":{
                        "move_speed":rival.move_speed,"jump_speed":rival.jump_speed,
                        "gravity_scale":rival.gravity_scale,"air_control_scale":rival.air_control_scale,
                        "ground_accel_scale":rival.ground_accel_scale,"wall_jump_scale":rival.wall_jump_scale,
                        "extra_air_jumps":rival.extra_air_jumps,"pulse_force":rival.pulse_force,
                        "pulse_interval":rival.pulse_interval,"magazine_size":rival.magazine_size,
                        "reload_duration":rival.reload_duration,"homing_strength":rival.homing_strength,
                        "ricochet_count":rival.ricochet_count,"projectile_speed":rival.projectile_speed,
                        "weapon_level":rival.weapon_level,"kiwi_aura":rival.kiwi_aura
                    }
                }
            })
    elif online_sync_timer >= 0.05:
        online_sync_timer = 0.0
        var move_value := player.move_stick.x
        if absf(move_value) < 0.01:
            move_value = player.move_input
        _online_send({
            "type":"game_input",
            "input":{
                "move":move_value,
                "aimX":player.aim_input.x,
                "aimY":player.aim_input.y,
                "jump":player.touch_jump or player.jump_held,
                "fire":player.touch_fire or player.fire_held,
                "reload":online_reload_pending
            }
        })
        online_reload_pending = false

func _apply_online_state(state: Variant) -> void:
    if typeof(state) != TYPE_DICTIONARY:
        return
    var data: Dictionary = state
    var incoming_round := int(data.get("round", 1))
    var incoming_map := int(data.get("map_index", 0))
    var incoming_phase := str(data.get("phase", "fight"))
    var round_changed := incoming_round != round_index or incoming_map != map_index
    if round_changed:
        _clear_pulses()
        _make_arena(incoming_map)
        round_index = incoming_round
        player.reset_round(Vector2(930,390))
        rival.reset_round(Vector2(350,390))
    map_index = incoming_map
    var host_player_stats: Dictionary = data.get("player_stats", {})
    var host_rival_stats: Dictionary = data.get("rival_stats", {})
    _apply_online_player_stats(rival, host_player_stats)
    _apply_online_player_stats(player, host_rival_stats)
    var pp: Array = data.get("player_pos", [])
    var pv: Array = data.get("player_vel", [])
    var rp: Array = data.get("rival_pos", [])
    var rv: Array = data.get("rival_vel", [])
    if pp.size() >= 2:
        rival.global_position = Vector2(float(pp[0]), float(pp[1]))
    if pv.size() >= 2:
        rival.velocity = Vector2(float(pv[0]), float(pv[1]))
    if rp.size() >= 2:
        player.global_position = Vector2(float(rp[0]), float(rp[1]))
    if rv.size() >= 2:
        player.velocity = Vector2(float(rv[0]), float(rv[1]))
    score_player = int(data.get("score_bot", 0))
    score_bot = int(data.get("score_player", 0))
    player.ammo = int(data.get("rival_ammo", player.ammo))
    rival.ammo = int(data.get("player_ammo", rival.ammo))
    player.reload_timer = float(data.get("rival_reload", player.reload_timer))
    rival.reload_timer = float(data.get("player_reload", rival.reload_timer))
    if incoming_phase == "fight":
        if phase != "fight" or round_changed:
            _close_overlay()
            phase = "fight"
            player.set_physics_process(false)
            rival.set_physics_process(false)
            game_controls.visible = true
    elif incoming_phase == "upgrade":
        if phase != "upgrade":
            phase = "upgrade"
            player.set_physics_process(false)
            rival.set_physics_process(false)
            _close_overlay()
            _show_panel("СОПЕРНИК ВЫБИРАЕТ УЛУЧШЕНИЕ", [], "Следующий раунд начнётся автоматически.")
            game_controls.visible = false
    elif incoming_phase == "match_end":
        if phase != "match_end":
            phase = "match_end"
            player.set_physics_process(false)
            rival.set_physics_process(false)
            _show_panel("МАТЧ ЗАВЕРШЁН", [
                ["СЫГРАТЬ ЕЩЁ", Callable(self, "_restart_match")],
                ["В ГЛАВНОЕ МЕНЮ", Callable(self, "_show_main_menu")]
            ], "Счёт: %d : %d" % [score_player, score_bot])
            game_controls.visible = false
    elif incoming_phase == "menu":
        phase = "menu"
        _show_main_menu()
    _update_hud()

func _apply_online_player_stats(who: ArenaPlayer, stats: Dictionary) -> void:
    if stats.is_empty():
        return
    who.move_speed = float(stats.get("move_speed", who.move_speed))
    who.jump_speed = float(stats.get("jump_speed", who.jump_speed))
    who.gravity_scale = float(stats.get("gravity_scale", who.gravity_scale))
    who.air_control_scale = float(stats.get("air_control_scale", who.air_control_scale))
    who.ground_accel_scale = float(stats.get("ground_accel_scale", who.ground_accel_scale))
    who.wall_jump_scale = float(stats.get("wall_jump_scale", who.wall_jump_scale))
    who.extra_air_jumps = int(stats.get("extra_air_jumps", who.extra_air_jumps))
    who.pulse_force = float(stats.get("pulse_force", who.pulse_force))
    who.pulse_interval = float(stats.get("pulse_interval", who.pulse_interval))
    who.magazine_size = int(stats.get("magazine_size", who.magazine_size))
    who.reload_duration = float(stats.get("reload_duration", who.reload_duration))
    who.homing_strength = float(stats.get("homing_strength", who.homing_strength))
    who.ricochet_count = int(stats.get("ricochet_count", who.ricochet_count))
    who.projectile_speed = float(stats.get("projectile_speed", who.projectile_speed))
    who.weapon_level = int(stats.get("weapon_level", who.weapon_level))
    who.kiwi_aura = bool(stats.get("kiwi_aura", who.kiwi_aura))
    who.ammo = mini(who.ammo, who.magazine_size)

func _online_render_rooms(rooms: Variant) -> void:
    if not is_instance_valid(online_rooms_list):
        return
    for child in online_rooms_list.get_children():
        child.queue_free()
    if typeof(rooms) != TYPE_ARRAY or rooms.is_empty():
        var empty := Label.new()
        empty.text = "Открытых комнат пока нет"
        empty.add_theme_color_override("font_color", Color("#a7a9b2"))
        online_rooms_list.add_child(empty)
        return
    for item in rooms:
        if typeof(item) != TYPE_DICTIONARY:
            continue
        var room: Dictionary = item
        var room_id := str(room.get("id", ""))
        var button := Button.new()
        button.text = str(room.get("name", "Комната")) + "  •  " + str(room.get("players", 0)) + "/" + str(room.get("maxPlayers", 8)) + ("  •  ЗАКРЫТА" if bool(room.get("locked", false)) else "")
        button.custom_minimum_size = Vector2(410, 48)
        button.add_theme_font_size_override("font_size", 15)
        button.add_theme_color_override("font_color", Color("#f3f1e8"))
        button.add_theme_stylebox_override("normal", _menu_button_style(Color("#303644"), Color("#596174")))
        button.pressed.connect(_online_join_room.bind(room_id))
        online_rooms_list.add_child(button)

func _online_set_status(message: String, tint: Color = Color("#d9ef70")) -> void:
    if is_instance_valid(online_status_label):
        online_status_label.text = message
        online_status_label.add_theme_color_override("font_color", tint)

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
    rival.visible = game_mode != "training"
    rival.set_physics_process(game_mode != "training")
    rival.collision_layer = 0 if game_mode == "training" else 1
    player.target = rival if game_mode != "training" else null
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
    if skins.is_empty():
        return
    skin_index = clampi(skin_index, 0, skins.size() - 1)
    _close_overlay()
    game_controls.visible = false

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#0b111b")
    ui.add_child(shade)
    overlay = shade
    _add_menu_ornaments(shade)

    var title := Label.new()
    title.text = "ВЫБОР БОЙЦА"
    title.position = Vector2(0, 28)
    title.size = Vector2(1280, 54)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    title.add_theme_color_override("font_color", Color("#f3f1e8"))
    shade.add_child(title)

    var skin: Dictionary = skins[skin_index]
    var skin_color := Color.from_string(str(skin.get("color", "#39d6c5")), Color("#39d6c5"))

    var preview_panel := Panel.new()
    preview_panel.position = Vector2(380, 105)
    preview_panel.size = Vector2(520, 380)
    var preview_style := StyleBoxFlat.new()
    preview_style.bg_color = Color("#172333")
    preview_style.border_color = skin_color
    preview_style.set_border_width_all(2)
    preview_style.set_corner_radius_all(22)
    preview_panel.add_theme_stylebox_override("panel", preview_style)
    shade.add_child(preview_panel)

    var preview_area := Control.new()
    preview_area.position = Vector2(10, 10)
    preview_area.size = Vector2(500, 360)
    preview_area.clip_contents = false
    preview_panel.add_child(preview_area)

    var floor_line := ColorRect.new()
    floor_line.position = Vector2(45, 325)
    floor_line.size = Vector2(410, 3)
    floor_line.color = Color(skin_color, 0.75)
    preview_area.add_child(floor_line)

    var fighter: ArenaPlayer = PLAYER_SCRIPT.new()
    fighter.body_color = skin_color
    fighter.skin_style = str(skin.get("style", "default"))
    fighter.facing = 1.0
    fighter.aim_input = Vector2(0.85, -0.16)
    fighter.position = Vector2(250, 235)
    fighter.scale = Vector2(1.18, 1.18)
    fighter.set_physics_process(false)
    fighter.set_process(false)
    fighter.z_index = 2
    preview_area.add_child(fighter)

    var name_label := Label.new()
    name_label.text = str(skin.get("name", skin.get("id", "MOD"))).to_upper()
    name_label.position = Vector2(300, 490)
    name_label.size = Vector2(680, 48)
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 28)
    name_label.add_theme_color_override("font_color", Color("#f3f1e8"))
    shade.add_child(name_label)

    var count_label := Label.new()
    count_label.text = "%d / %d" % [skin_index + 1, skins.size()]
    count_label.position = Vector2(0, 535)
    count_label.size = Vector2(1280, 28)
    count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count_label.add_theme_font_size_override("font_size", 15)
    count_label.add_theme_color_override("font_color", Color("#9baabd"))
    shade.add_child(count_label)

    var previous := _add_button("‹", Vector2(260, 245), Vector2(100, 76), shade)
    previous.add_theme_font_size_override("font_size", 42)
    previous.add_theme_stylebox_override("normal", _menu_button_style(Color("#253446"), Color("#b9e36c")))
    previous.pressed.connect(_select_skin.bind(posmod(skin_index - 1, skins.size())))

    var next := _add_button("›", Vector2(920, 245), Vector2(100, 76), shade)
    next.add_theme_font_size_override("font_size", 42)
    next.add_theme_stylebox_override("normal", _menu_button_style(Color("#253446"), Color("#b9e36c")))
    next.pressed.connect(_select_skin.bind(posmod(skin_index + 1, skins.size())))

    var back := _add_button("НАЗАД", Vector2(360, 600), Vector2(250, 58), shade)
    back.add_theme_stylebox_override("normal", _menu_button_style(Color("#303d4d"), Color("#718ba1")))
    back.pressed.connect(_apply_skin_and_return)

    var equip := _add_button("НАДЕТО  ✓", Vector2(670, 600), Vector2(250, 58), shade)
    equip.add_theme_stylebox_override("normal", _menu_button_style(Color("#596b32"), Color("#d9ef70")))
    equip.pressed.connect(_apply_skin_and_return)

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
    info.text = "СОБЕРИ СВОЙ БИЛД  •  КАЖДУЮ КАРТУ МОЖНО УСИЛИТЬ ДО 3 СТАКОВ"
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
        style.bg_color = Color("#20291f") if active else Color("#171d29")
        style.border_color = Color("#d9ef70") if active else Color("#53647b")
        style.set_border_width_all(3 if active else 2)
        style.set_corner_radius_all(15)
        style.shadow_color = Color(0.0,0.0,0.0,0.42)
        style.shadow_size = 10
        style.shadow_offset = Vector2(0,4)
        style.content_margin_left = 12
        style.content_margin_right = 12
        style.content_margin_top = 10
        style.content_margin_bottom = 10
        panel.add_theme_stylebox_override("panel",style)
        var column := VBoxContainer.new()
        column.alignment = BoxContainer.ALIGNMENT_CENTER
        column.add_theme_constant_override("separation",10)
        panel.add_child(column)
        var art_area := Panel.new()
        art_area.custom_minimum_size = Vector2(315,125)
        var art_style := StyleBoxFlat.new()
        art_style.bg_color = Color("#34452f") if active else Color("#222d3c")
        art_style.border_color = Color("#91b75d") if active else Color("#64758e")
        art_style.set_border_width_all(1)
        art_style.set_corner_radius_all(11)
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
        stack_label.text = "АКТИВНО  ×%d / 3" % stack_count if stack_count > 0 else "МОЖНО УСИЛИТЬ ДО 3 РАЗ"
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
        choose.text = "СБРОСИТЬ СТАКИ" if stack_count >= 3 else ("ДОБАВИТЬ СТАК  ×%d" % (stack_count + 1))
        choose.custom_minimum_size = Vector2(290,44)
        choose.add_theme_stylebox_override("normal",_menu_button_style(Color("#596b32") if active else Color("#343b4b"),Color("#d9ef70") if active else Color("#667087")))
        choose.pressed.connect(_toggle_training_card.bind(id))
        column.add_child(choose)
        grid.add_child(panel)

func _build_training_maps(shade: Control) -> void:
    var info := Label.new()
    info.text = "АРЕНЫ: %d  •  У КАЖДОЙ СВОЯ АТМОСФЕРА И РАСКЛАДКА" % all_maps.size()
    info.position = Vector2(0,155)
    info.size = Vector2(1280,32)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size",16)
    info.add_theme_color_override("font_color",Color("#aab8cc"))
    shade.add_child(info)

    var scroll := ScrollContainer.new()
    scroll.position = Vector2(70,195)
    scroll.size = Vector2(1140,425)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.clip_contents = true
    shade.add_child(scroll)

    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation",18)
    grid.add_theme_constant_override("v_separation",16)
    scroll.add_child(grid)

    for i in range(all_maps.size()):
        var map_data: Dictionary = all_maps[i]
        var accent := Color.from_string(str(map_data.get("accent", "#8da9cb")), Color("#8da9cb"))
        var selected := i == map_index
        var platforms: Array = map_data.get("platforms", [])

        var panel := PanelContainer.new()
        panel.custom_minimum_size = Vector2(520,188)
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#203b38") if selected else Color("#182333")
        style.border_color = accent if selected else Color("#40556e")
        style.set_border_width_all(3 if selected else 1)
        style.set_corner_radius_all(16)
        style.content_margin_left = 12
        style.content_margin_right = 12
        style.content_margin_top = 9
        style.content_margin_bottom = 9
        style.shadow_color = Color(0.0,0.0,0.0,0.3)
        style.shadow_size = 8
        style.shadow_offset = Vector2(0,3)
        panel.add_theme_stylebox_override("panel",style)

        var column := VBoxContainer.new()
        column.add_theme_constant_override("separation",6)
        panel.add_child(column)

        var header := HBoxContainer.new()
        header.add_theme_constant_override("separation",8)
        column.add_child(header)
        var name_label := Label.new()
        name_label.text = str(map_data.get("name","АРЕНА"))
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name_label.add_theme_font_size_override("font_size",18)
        name_label.add_theme_color_override("font_color",Color("#f4f7ff"))
        header.add_child(name_label)
        var state_label := Label.new()
        state_label.text = "АКТИВНАЯ" if selected else "%d ПЛАТФОРМ" % platforms.size()
        state_label.add_theme_font_size_override("font_size",11)
        state_label.add_theme_color_override("font_color",accent)
        header.add_child(state_label)

        var preview := Control.new()
        preview.custom_minimum_size = Vector2(490,88)
        preview.clip_contents = true
        column.add_child(preview)
        var backdrop := ColorRect.new()
        backdrop.position = Vector2.ZERO
        backdrop.size = Vector2(490,88)
        backdrop.color = Color.from_string(str(map_data.get("bg_top","#172234")),Color("#172234"))
        preview.add_child(backdrop)
        for line_index in range(6):
            var grid_line := ColorRect.new()
            grid_line.position = Vector2(0,12.0 + float(line_index) * 12.0)
            grid_line.size = Vector2(490,1)
            grid_line.color = Color(accent,0.08)
            preview.add_child(grid_line)

        var ground := ColorRect.new()
        ground.position = Vector2(0,81)
        ground.size = Vector2(490,7)
        ground.color = Color.from_string(str(map_data.get("platform","#283b54")),Color("#283b54"))
        preview.add_child(ground)

        for platform_value in platforms:
            if typeof(platform_value) != TYPE_DICTIONARY:
                continue
            var platform: Dictionary = platform_value
            var center_x := 12.0 + clampf(float(platform.get("x",640)) / 1280.0,0.0,1.0) * 466.0
            var center_y := 5.0 + clampf(float(platform.get("y",500)) / 720.0,0.0,1.0) * 70.0
            var platform_w := clampf(float(platform.get("w",180)) / 1280.0 * 466.0,18.0,190.0)
            var platform_h := clampf(float(platform.get("h",20)) / 720.0 * 88.0,3.0,6.0)
            var bar := ColorRect.new()
            bar.position = Vector2(clampf(center_x - platform_w * 0.5,0.0,490.0-platform_w),clampf(center_y-platform_h*0.5,2.0,76.0))
            bar.size = Vector2(platform_w,platform_h)
            bar.color = accent if selected else accent.darkened(0.12)
            preview.add_child(bar)

        var spawn_left := ColorRect.new()
        spawn_left.position = Vector2(32,69)
        spawn_left.size = Vector2(7,12)
        spawn_left.color = Color("#f2e5ce")
        preview.add_child(spawn_left)
        var spawn_right := ColorRect.new()
        spawn_right.position = Vector2(451,69)
        spawn_right.size = Vector2(7,12)
        spawn_right.color = Color("#ff786f")
        preview.add_child(spawn_right)

        var select := Button.new()
        select.text = "АРЕНА ВЫБРАНА  ✓" if selected else "ВЫБРАТЬ АРЕНУ"
        select.custom_minimum_size = Vector2(470,34)
        select.focus_mode = Control.FOCUS_NONE
        select.add_theme_stylebox_override("normal",_menu_button_style(Color("#526b35") if selected else Color("#29394d"),accent))
        select.pressed.connect(_select_training_map.bind(i))
        column.add_child(select)
        grid.add_child(panel)

func _select_training_map(index: int) -> void:
    if all_maps.is_empty():
        return
    map_index = posmod(index,all_maps.size())
    _make_arena(map_index)
    player.reset_round(Vector2(350,390))
    _open_training_cards()

func _toggle_training_card(card_id: String) -> void:
    var stack_count := active_training_cards.count(card_id)
    if stack_count >= 3:
        while active_training_cards.has(card_id):
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
        if game_mode == "online":
            phase = "match_end"
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
    if not is_instance_valid(hud):
        return
    var arena_name := "АРЕНА"
    if not all_maps.is_empty():
        arena_name = str(all_maps[clampi(map_index, 0, all_maps.size() - 1)].get("name", "АРЕНА"))
    if is_instance_valid(player_health_bar):
        player_health_bar.max_value = player.max_health
        player_health_bar.value = player.health
        player_health_bar.visible = phase == "fight"
    if is_instance_valid(player_health_text):
        player_health_text.text = "ТЫ  %d / %d HP" % [player.health, player.max_health]
        player_health_text.visible = phase == "fight"
    if is_instance_valid(rival_health_bar):
        rival_health_bar.max_value = rival.max_health
        rival_health_bar.value = rival.health
        rival_health_bar.visible = phase == "fight" and game_mode != "training"
    if is_instance_valid(rival_health_text):
        rival_health_text.text = "БОТ  %d / %d HP" % [rival.health, rival.max_health]
        rival_health_text.visible = phase == "fight" and game_mode != "training"
    if game_mode == "training":
        hud.text = "ТРЕНИРОВКА  •  " + arena_name
    elif game_mode == "online":
        hud.text = "%s     РАУНД %d     ТЫ  %d : %d  СОПЕРНИК" % [arena_name,round_index,score_player,score_bot]
    else:
        hud.text = "%s     РАУНД %d     ТЫ  %d : %d  CPU" % [arena_name,round_index,score_player,score_bot]

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
    rival.visible = game_mode != "training"
    rival.set_physics_process(game_mode != "training")
    rival.collision_layer = 0 if game_mode == "training" else 1
    player.target = rival if game_mode != "training" else null
    round_index += 1
    _play_round_music()
    _make_arena(map_index if game_mode == "training" else round_index - 1)
    player.reset_round(Vector2(350,390))
    if game_mode != "training":
        rival.reset_round(Vector2(930,390))
    phase = "fight"
    game_controls.visible = true
    _update_hud()

func _show_match_end() -> void:
    var result := "ПОБЕДА!" if score_player >= 5 else ("ПОБЕДИЛ СОПЕРНИК" if game_mode == "online" else "ПОБЕДИЛ CPU")
    _show_panel(result,[
        ["СЫГРАТЬ ЕЩЁ",Callable(self,"_restart_match")],
        ["ГЛАВНОЕ МЕНЮ",Callable(self,"_show_main_menu")]
    ],"Первый до 5 побед. Счёт: %d : %d" % [score_player,score_bot])

func _restart_match() -> void:
    if game_mode == "online":
        if online_is_host and online_connected:
            online_in_match = false
            _online_send({"type":"start_match"})
        return
    _start_game(game_mode)
