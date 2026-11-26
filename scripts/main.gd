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
var match_rounds_to_win := 5
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
    "res://music/akkiemi_-_truth_yandere.mp3",
    "res://music/Moetwee, Differentwrld - Help Me (hitmo.net).mp3",
    "res://music/onda-andar-type-london (1).mp3",
    "res://music/zxcursed_x_shadowraze_-_metamorphosis_3_x_chronospher_(mp3.pm).mp3"
]
var music_display_names: Array[String] = [
    "Пообещай",
    "I'm so crazy for youuu",
    "заново",
    "truth yandere^^",
    "help me",
    "type london",
    "METAMORPHOSIS 3"
]
var music_last_index := -1
var menu_record_needle: Control
var menu_record_disc: Control
var music_track_button: Button
var music_ticker_label: Label
var music_modal: Control
var music_modal_disc: Control
var music_visualizer_bars: Array[ColorRect] = []
var online_player_id := ""
var online_host_id := ""
var online_is_host := false
var online_in_match := false
var online_sync_timer := 0.0
var online_reload_pending := false
var online_start_button: Button
var control_edit_mode := false
var control_drag_target: Control
var control_drag_offset := Vector2.ZERO
var control_positions: Dictionary = {}
var control_editor_overlay: Control



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
    control_positions = config.get_value("controls","positions",{})

func _save_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("settings","sound_level",sound_level)
    config.set_value("settings","vibration_enabled",vibration_enabled)
    config.set_value("settings","shake_enabled",shake_enabled)
    config.set_value("settings","controls_mirrored",controls_mirrored)
    config.set_value("settings","skin_index",skin_index)
    config.set_value("controls","positions",control_positions)
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
    # Anime-inspired painted arena: layered twilight sky, distant silhouettes,
    # drifting petals and cinematic speed accents. Character rendering is untouched.
    draw_rect(Rect2(0,0,1280,720),Color("#17243d"))
    var sky_top := Color("#172943")
    var sky_low := Color("#704b75")
    for band in range(12):
        var t := float(band) / 11.0
        var band_color := sky_top.lerp(sky_low,t)
        draw_rect(Rect2(0, float(band) * 42.0, 1280, 44), band_color)
    _draw_anime_arena_backdrop()
    for i in range(18):
        var x := float((i * 197 + 61) % 1280)
        var y := fposmod(float((i * 113 + 37) % 700) + background_time * (8.0 + float(i % 4) * 3.0), 720.0)
        var sway := sin(background_time * 0.7 + float(i)) * 14.0
        var petal := Vector2(x + sway, y)
        draw_set_transform(petal, background_time * (0.25 + float(i % 3) * 0.08), Vector2.ONE)
        draw_colored_polygon(PackedVector2Array([Vector2(-4,0),Vector2(0,-2),Vector2(5,0),Vector2(0,3)]), Color("#ffd5e4", 0.22 + float(i % 4) * 0.06))
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    # Thin hand-painted action streaks around the arena edges.
    for i in range(7):
        var y := 115.0 + float(i) * 78.0
        var drift := sin(background_time * 0.8 + float(i)) * 22.0
        draw_line(Vector2(0,y+drift),Vector2(120.0 + float(i%3)*36.0,y-18.0+drift),Color("#f7b7d2",0.10),2.0,true)
        draw_line(Vector2(1280,y-drift),Vector2(1160.0-float(i%3)*36.0,y+18.0-drift),Color("#a8dcff",0.09),2.0,true)
    draw_rect(Rect2(0,700,1280,20),Color("#17233a"))
    draw_line(Vector2(0,700),Vector2(1280,700),Color("#f2b8d0",0.55),2.0,true)
    if impact_flash > 0.0:
        draw_rect(Rect2(0,0,1280,720),Color(impact_flash_color, impact_flash * 0.13))
    if boot_loading:
        draw_rect(Rect2(0,0,1280,720),Color(0.03,0.04,0.06,0.82))
        draw_string(ThemeDB.fallback_font,Vector2(0,300),"KIWI ROUNDS",HORIZONTAL_ALIGNMENT_CENTER,1280,68,Color("#f2f2f2"))
        draw_string(ThemeDB.fallback_font,Vector2(0,345),"ЗАПУСК ИГРЫ",HORIZONTAL_ALIGNMENT_CENTER,1280,18,Color("#aab4c4"))
        var center := Vector2(640,430)
        draw_arc(center,27.0,boot_angle,boot_angle+4.4,48,Color("#f4b7d0"),6.0,true)
        draw_circle(center+Vector2(cos(boot_angle)*27.0,sin(boot_angle)*27.0),5.0,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(0,500),boot_stage,HORIZONTAL_ALIGNMENT_CENTER,1280,18,Color("#aaaaaa"))
        draw_string(ThemeDB.fallback_font,Vector2(0,675),"Пожалуйста, подожди",HORIZONTAL_ALIGNMENT_CENTER,1280,15,Color("#777f8e"))
        return

func _draw_anime_arena_backdrop() -> void:
    # Distant mountains and layered Japanese-inspired skyline silhouettes.
    for layer in range(3):
        var base_y := 480.0 + float(layer) * 44.0
        var points := PackedVector2Array([Vector2(0,base_y)])
        for i in range(9):
            var x := float(i) * 160.0
            var peak := base_y - 65.0 - float((i * 43 + layer * 29) % 120)
            points.append(Vector2(x + 80.0,peak))
            points.append(Vector2(x + 160.0,base_y))
        points.append(Vector2(1280,720))
        points.append(Vector2(0,720))
        draw_colored_polygon(points, [Color("#273c58",0.50),Color("#31415e",0.58),Color("#26364f",0.82)][layer])
    # A soft sunset disc behind the action.
    var sun_center := Vector2(640.0,300.0)
    draw_circle(sun_center,112.0,Color("#ffb8c9",0.045))
    draw_circle(sun_center,86.0,Color("#ffc4cb",0.10))
    draw_circle(sun_center,70.0,Color("#f6b6c8",0.20))
    for i in range(5):
        var cloud_x := fposmod(float(i) * 295.0 + background_time * (5.0 + float(i % 2) * 3.0), 1500.0) - 100.0
        var cloud_y := 130.0 + float((i * 47) % 155)
        draw_line(Vector2(cloud_x,cloud_y),Vector2(cloud_x+90.0,cloud_y-5.0),Color("#e4c6df",0.16),3.0,true)
        draw_line(Vector2(cloud_x+22.0,cloud_y+9.0),Vector2(cloud_x+122.0,cloud_y+4.0),Color("#f5d6e5",0.10),2.0,true)
    # Distant sakura branches frame the arena without covering the fighters.
    for side in [-1,1]:
        var root := Vector2(0.0 if side < 0 else 1280.0, 250.0)
        var tip := Vector2(190.0 if side < 0 else 1090.0, 105.0)
        draw_line(root,tip,Color("#3a304d",0.72),9.0,true)
        for twig in range(4):
            var start := root.lerp(tip,0.35 + float(twig) * 0.14)
            var finish := start + Vector2(35.0 if side < 0 else -35.0,-32.0 - float(twig%2)*18.0)
            draw_line(start,finish,Color("#59415f",0.70),4.0,true)
            for blossom in range(3):
                var p := finish + Vector2(float(blossom-1)*11.0,-float(blossom%2)*8.0)
                draw_circle(p,4.0,Color("#ffc8dc",0.30))
    # Warm arena horizon and restrained floor perspective.
    draw_line(Vector2(0,490),Vector2(1280,490),Color("#f4c0d3",0.22),2.0,true)
    for i in range(13):
        var x := float(i) * 106.0
        draw_line(Vector2(640,490),Vector2(x,700),Color("#a8c9e8",0.075),1.2,true)
    for i in range(5):
        var y := 525.0 + float(i) * 35.0
        draw_line(Vector2(0,y),Vector2(1280,y),Color("#d9c0df",0.055),1.0,true)

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
    _draw_anime_arena_backdrop()

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

    # Painted anime-fantasy platform: dark stone underside, warm lacquer top,
    # soft pink rim light and small decorative gold seams. Physics stays identical.
    var w := dimensions.x
    var h := dimensions.y
    var base := Polygon2D.new()
    base.polygon = PackedVector2Array([
        Vector2(-w*0.5,-h*0.5),Vector2(w*0.5,-h*0.5),
        Vector2(w*0.5,h*0.5),Vector2(-w*0.5,h*0.5)
    ])
    base.color = Color("#28334d")
    body.add_child(base)

    var front_face := Polygon2D.new()
    front_face.polygon = PackedVector2Array([
        Vector2(-w*0.5,h*0.5-2),Vector2(w*0.5,h*0.5-2),
        Vector2(w*0.5+8,h*0.5+9),Vector2(-w*0.5-8,h*0.5+9)
    ])
    front_face.color = Color("#171f35")
    body.add_child(front_face)

    var top := Polygon2D.new()
    top.polygon = PackedVector2Array([
        Vector2(-w*0.5+3,-h*0.5+2),Vector2(w*0.5-3,-h*0.5+2),
        Vector2(w*0.5-9,-h*0.5+h*0.48),Vector2(-w*0.5+9,-h*0.5+h*0.48)
    ])
    top.color = Color("#52627d")
    body.add_child(top)

    var rim_glow := Line2D.new()
    rim_glow.points = PackedVector2Array([Vector2(-w*0.5,-h*0.5),Vector2(w*0.5,-h*0.5)])
    rim_glow.width = 10.0
    rim_glow.default_color = Color("#ffb9d1",0.18)
    rim_glow.antialiased = true
    body.add_child(rim_glow)

    var rim := Line2D.new()
    rim.points = PackedVector2Array([Vector2(-w*0.5,-h*0.5+1),Vector2(w*0.5,-h*0.5+1)])
    rim.width = 3.0
    rim.default_color = Color("#f3c6d6",0.92)
    rim.antialiased = true
    body.add_child(rim)

    var lower_edge := Line2D.new()
    lower_edge.points = PackedVector2Array([Vector2(-w*0.5-6,h*0.5+8),Vector2(w*0.5+6,h*0.5+8)])
    lower_edge.width = 2.0
    lower_edge.default_color = Color("#a8c9ec",0.45)
    lower_edge.antialiased = true
    body.add_child(lower_edge)

    for mark in range(clampi(int(w / 110.0),1,6)):
        var px := -w*0.5 + 28.0 + float(mark) * (w - 56.0) / float(maxi(1,clampi(int(w / 110.0),1,6)-1))
        var seam := Line2D.new()
        seam.points = PackedVector2Array([Vector2(px,-h*0.5+5),Vector2(px+12,-h*0.5+5)])
        seam.width = 2.0
        seam.default_color = Color("#ffe1ac",0.62)
        body.add_child(seam)

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
        {"id":"kiwi_araga","name":"Киви Арага","color":"#e9c5a8","style":"kiwi_human"},
        {"name":"Неон","color":"#39d6c5"},{"name":"Лазурь","color":"#4b9cff"},
        {"name":"Аметист","color":"#b47cff"},{"name":"Золото","color":"#ffc857"},
        {"name":"Пульс","color":"#ff78b7"},{"name":"Коралловый","color":"#ff765e"},
        {"name":"Лайм","color":"#a8e650"},{"name":"Ледяной","color":"#a7eaff"},
        {"name":"Рубин","color":"#d93658"},{"name":"Сапфир","color":"#315edb"},
        {"name":"Мята","color":"#7fffd4"},{"name":"Манго","color":"#ffad42"},
        {"name":"Космос","color":"#6250a8"},{"name":"Графит","color":"#65717d"},
        {"name":"Снег","color":"#e7f2f5"},{"name":"Обсидиан","color":"#343a50"},
        {"name":"Клубника","color":"#ef476f"},{"name":"Черника","color":"#5965bd"},
        {"name":"Арбуз","color":"#4fbd79"},{"name":"Лава","color":"#f15a24"},
        {"name":"Полярная звезда","color":"#d2f3ff"},{"name":"Радиант","color":"#f4df6b"},
        {"name":"Токсик","color":"#8bd448"},{"name":"Электрик","color":"#42c9ff"},
        {"name":"Закат","color":"#ff8066"},{"name":"Рассвет","color":"#ffb8d2"},
        {"name":"Виноград","color":"#7446a8"},{"name":"Кибер","color":"#e34cff"},
        {"name":"Аквамарин","color":"#38c8b5"},{"name":"Медный","color":"#bd704b"},
        {"name":"Стальной","color":"#8da3b8"},{"name":"Песочный","color":"#d8b77b"},
        {"name":"Лепесток","color":"#f18bb7"},{"name":"Лесной","color":"#347653"},
        {"name":"Грозовой","color":"#586b9b"},{"name":"Мороз","color":"#76c9e8"},
        {"name":"Плазма","color":"#b94cff"},{"name":"Импульс","color":"#f3ed58"},
        {"name":"Спектр","color":"#ee6bce"},{"name":"Туман","color":"#9aa8b8"},
        {"name":"Дракон","color":"#b63838"},{"name":"Призрак","color":"#c7d4e5"},
        {"name":"Пиксель","color":"#58d4a0"},{"name":"Ретро","color":"#e6a15c"},
        {"name":"Галактика","color":"#7b65d8"},{"name":"Хром","color":"#b8c5ce"},
        {"name":"Вулкан","color":"#e64b32"},{"name":"Северное сияние","color":"#56d8bd"}
    ]
    for mod_skin in mod_loader.skins:
        var skin_id := str(mod_skin.get("id", "")).to_lower()
        var skin_name := str(mod_skin.get("name", "")).to_lower()
        if skin_id in ["kiwi_araga", "kiwi_mascot"] or skin_name in ["киви арага", "киви-маскот"]:
            continue
        skins.append(mod_skin)
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
    hud.add_theme_constant_override("outline_size", 3)
    hud.add_theme_color_override("font_outline_color", Color("#07111c", 0.96))
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
    fire_button.pressed.connect(player.shoot_once)
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
    bg.bg_color = Color("#081321", 0.96)
    bg.border_color = Color("#7894a8", 0.42)
    bg.set_border_width_all(1)
    bg.set_corner_radius_all(8)
    bg.shadow_color = Color("#000000", 0.35)
    bg.shadow_size = 5
    var fill := StyleBoxFlat.new()
    fill.bg_color = fill_color
    fill.border_color = fill_color.lightened(0.28)
    fill.set_border_width_all(1)
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
    label.add_theme_constant_override("outline_size", 2)
    label.add_theme_color_override("font_outline_color", Color("#07111c", 0.96))
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
        movement_joystick.position = Vector2(1090,526)
        aim_joystick.position = Vector2(22,526)
        fire_button.position = Vector2(22,448)
        reload_button.position = Vector2(930,648)
        jump_button.position = Vector2(930,526)
        ammo_label.position = Vector2(930,618)
    else:
        movement_joystick.position = Vector2(22,526)
        aim_joystick.position = Vector2(1090,526)
        fire_button.position = Vector2(1090,448)
        reload_button.position = Vector2(930,648)
        jump_button.position = Vector2(930,526)
        ammo_label.position = Vector2(930,618)
    movement_joystick.size = Vector2(168,168)
    aim_joystick.size = Vector2(168,168)
    fire_button.size = Vector2(132,58)
    fire_button.visible = true
    reload_button.size = Vector2(138,52)
    jump_button.size = Vector2(138,62)
    ammo_label.size = Vector2(152,26)
    for entry in [
        ["move", movement_joystick], ["aim", aim_joystick],
        ["fire", fire_button], ["jump", jump_button], ["reload", reload_button]
    ]:
        var saved: Variant = control_positions.get(entry[0], null)
        if saved is Vector2 and saved.x >= 0.0:
            entry[1].position = saved
    menu_button.position = Vector2(18,18)
    cards_button.position = Vector2(150,18)

func _open_control_editor() -> void:
    if control_edit_mode:
        return
    if phase == "fight":
        phase = "paused"
        player.set_physics_process(false)
        rival.set_physics_process(false)
    _clear_control_inputs()
    _close_overlay()
    control_edit_mode = true
    game_controls.visible = true
    for control in [movement_joystick, aim_joystick, fire_button, jump_button, reload_button]:
        control.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.015,0.035,0.065,0.58)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(shade)
    control_editor_overlay = shade
    var title := Label.new()
    title.text = "НАСТРОЙКА УПРАВЛЕНИЯ"
    title.position = Vector2(0,22)
    title.size = Vector2(1280,42)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",28)
    title.add_theme_color_override("font_color",Color("#f4f7ff"))
    shade.add_child(title)
    var hint := Label.new()
    hint.text = "ПЕРЕТАСКИВАЙ СТИКИ И КНОПКИ ПАЛЬЦЕМ. РАСПОЛОЖИ КАК УДОБНО."
    hint.position = Vector2(180,68)
    hint.size = Vector2(920,34)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size",15)
    hint.add_theme_color_override("font_color",Color("#8feee3"))
    shade.add_child(hint)
    var done := Button.new()
    done.text = "СОХРАНИТЬ РАСКЛАДКУ"
    done.position = Vector2(460,650)
    done.size = Vector2(360,48)
    done.add_theme_font_size_override("font_size",18)
    done.add_theme_stylebox_override("normal",_menu_button_style(Color("#244d58"),Color("#63eee0")))
    done.pressed.connect(_close_control_editor)
    shade.add_child(done)
    var reset := Button.new()
    reset.text = "СБРОСИТЬ"
    reset.position = Vector2(850,650)
    reset.size = Vector2(170,48)
    reset.add_theme_font_size_override("font_size",16)
    reset.add_theme_stylebox_override("normal",_menu_button_style(Color("#303644"),Color("#ff9b72")))
    reset.pressed.connect(_reset_control_layout)
    shade.add_child(reset)

func _input(event: InputEvent) -> void:
    if not control_edit_mode:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _begin_control_drag(event.position)
        else:
            _end_control_drag()
    elif event is InputEventScreenDrag and control_drag_target != null:
        _move_control_drag(event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _begin_control_drag(event.position)
        else:
            _end_control_drag()
    elif event is InputEventMouseMotion and control_drag_target != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _move_control_drag(event.position)

func _begin_control_drag(point: Vector2) -> void:
    var candidates: Array[Control] = [fire_button, reload_button, jump_button, aim_joystick, movement_joystick]
    for item in candidates:
        if is_instance_valid(item) and item.get_global_rect().has_point(point):
            control_drag_target = item
            control_drag_offset = point - item.position
            get_viewport().set_input_as_handled()
            return

func _move_control_drag(point: Vector2) -> void:
    if not is_instance_valid(control_drag_target):
        return
    var next_pos := point - control_drag_offset
    next_pos.x = clampf(next_pos.x, 0.0, 1280.0 - control_drag_target.size.x)
    next_pos.y = clampf(next_pos.y, 110.0, 720.0 - control_drag_target.size.y)
    control_drag_target.position = next_pos
    get_viewport().set_input_as_handled()

func _end_control_drag() -> void:
    if is_instance_valid(control_drag_target):
        var key := "move"
        if control_drag_target == aim_joystick: key = "aim"
        elif control_drag_target == fire_button: key = "fire"
        elif control_drag_target == jump_button: key = "jump"
        elif control_drag_target == reload_button: key = "reload"
        control_positions[key] = control_drag_target.position
    control_drag_target = null

func _close_control_editor() -> void:
    _end_control_drag()
    control_edit_mode = false
    for control in [movement_joystick, aim_joystick, fire_button, jump_button, reload_button]:
        control.mouse_filter = Control.MOUSE_FILTER_STOP
    if is_instance_valid(control_editor_overlay):
        control_editor_overlay.queue_free()
    control_editor_overlay = null
    _save_settings()
    if phase == "paused":
        _resume_game()
    else:
        _show_settings()

func _reset_control_layout() -> void:
    control_positions.clear()
    _apply_control_layout()

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
    _play_random_music()

func _play_random_music() -> void:
    if not is_instance_valid(music_player) or music_tracks.is_empty():
        return
    var choices: Array[int] = []
    for i in range(music_tracks.size()):
        if i != music_last_index:
            choices.append(i)
    if choices.is_empty():
        choices.append(0)
    choices.shuffle()
    _play_music_index(choices[0])

func _play_round_music() -> void:
    _play_random_music()

func _play_music_index(index: int) -> void:
    if not is_instance_valid(music_player) or music_tracks.is_empty():
        return
    music_last_index = posmod(index, music_tracks.size())
    var stream := load(music_tracks[music_last_index]) as AudioStream
    if stream == null:
        push_warning("Не удалось загрузить музыку: " + music_tracks[music_last_index])
        return
    music_player.stream = stream
    music_player.play()
    _update_music_track_button()

func _current_music_title() -> String:
    if music_last_index < 0 or music_last_index >= music_tracks.size():
        return "Музыка"
    return music_display_names[music_last_index] if music_last_index < music_display_names.size() else "Трек"

func _update_music_track_button() -> void:
    var track_name := _current_music_title()
    if is_instance_valid(music_track_button):
        music_track_button.text = "♫  " + track_name
        music_track_button.tooltip_text = "Открыть музыкальный плеер"
    if is_instance_valid(music_ticker_label):
        music_ticker_label.text = track_name
        music_ticker_label.position.x = 0.0

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
    if is_instance_valid(menu_record_disc):
        menu_record_disc.rotation = background_time * 0.72
    if is_instance_valid(music_modal_disc):
        music_modal_disc.rotation = background_time * 0.72
    if is_instance_valid(music_ticker_label):
        music_ticker_label.position.x -= delta * 42.0
        if music_ticker_label.position.x + music_ticker_label.size.x < 0.0:
            music_ticker_label.position.x = 0.0
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
    _play_random_music()
    phase = "menu"
    skin_return_to_game = false
    player.set_physics_process(false)
    rival.set_physics_process(false)
    game_controls.visible = false
    hud.visible = false
    _close_overlay()

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#070b18")
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shade.modulate.a = 0.0
    ui.add_child(shade)
    overlay = shade

    _create_menu_bot_preview(shade)
    _create_menu_record(shade)

    # Brawl-like layout: one dominant play action, compact navigation, no mode picker.
    var logo_shadow := Label.new()
    logo_shadow.text = "KIWI"
    logo_shadow.position = Vector2(46, 34)
    logo_shadow.size = Vector2(430, 92)
    logo_shadow.add_theme_font_size_override("font_size", 76)
    logo_shadow.add_theme_color_override("font_color", Color("#020711", 0.8))
    shade.add_child(logo_shadow)

    var logo := Label.new()
    logo.text = "KIWI"
    logo.position = Vector2(40, 26)
    logo.size = Vector2(430, 92)
    logo.add_theme_font_size_override("font_size", 76)
    logo.add_theme_color_override("font_color", Color("#f4fbff"))
    shade.add_child(logo)

    var subtitle := Label.new()
    subtitle.text = "ROUNDS"
    subtitle.position = Vector2(54, 105)
    subtitle.size = Vector2(240, 32)
    subtitle.add_theme_font_size_override("font_size", 22)
    subtitle.add_theme_color_override("font_color", Color("#52f6ef"))
    shade.add_child(subtitle)

    var season := Label.new()
    season.text = "NEON CITY  •  SEASON 01"
    season.position = Vector2(44, 151)
    season.size = Vector2(300, 24)
    season.add_theme_font_size_override("font_size", 13)
    season.add_theme_color_override("font_color", Color("#b6c9e6"))
    shade.add_child(season)

    var play_shadow := Panel.new()
    play_shadow.position = Vector2(420, 552)
    play_shadow.size = Vector2(440, 104)
    var shadow_style := StyleBoxFlat.new()
    shadow_style.bg_color = Color("#08101e", 0.94)
    shadow_style.border_color = Color("#07101b")
    shadow_style.set_border_width_all(3)
    shadow_style.set_corner_radius_all(24)
    play_shadow.add_theme_stylebox_override("panel", shadow_style)
    shade.add_child(play_shadow)

    var play := _add_button("ИГРАТЬ", Vector2(430, 540), Vector2(420, 96), shade)
    play.add_theme_font_size_override("font_size", 38)
    play.add_theme_color_override("font_color", Color("#07141e"))
    play.add_theme_stylebox_override("normal", _menu_button_style(Color("#48f2dc"), Color("#c5fff7")))
    play.add_theme_stylebox_override("hover", _menu_button_style(Color("#8affee"), Color.WHITE))
    play.add_theme_stylebox_override("pressed", _menu_button_style(Color("#22cbbd"), Color("#e1fffa")))
    play.pressed.connect(func(): _start_game("bot"))

    var nav_y := 650.0
    var nav_specs := [
        ["НОВОСТИ", Vector2(270, nav_y), Vector2(170, 48), Callable(self, "_open_news")],
        ["КАРТОЧКИ", Vector2(455, nav_y), Vector2(170, 48), Callable(self, "_open_training_cards")],
        ["ОБЛИКИ", Vector2(640, nav_y), Vector2(170, 48), Callable(self, "_open_skins")],
        ["НАСТРОЙКИ", Vector2(825, nav_y), Vector2(170, 48), Callable(self, "_show_settings")]
    ]
    for spec in nav_specs:
        var nav := _add_button(spec[0], spec[1], spec[2], shade)
        nav.add_theme_font_size_override("font_size", 14)
        nav.add_theme_color_override("font_color", Color("#edf8ff"))
        nav.add_theme_stylebox_override("normal", _menu_button_style(Color("#111c30", 0.94), Color("#36d9e8", 0.78)))
        nav.add_theme_stylebox_override("hover", _menu_button_style(Color("#1b3150"), Color("#ff4fd8")))
        nav.pressed.connect(spec[3])

    var profile_tag := Label.new()
    profile_tag.text = "PLAYER 01"
    profile_tag.position = Vector2(44, 202)
    profile_tag.size = Vector2(180, 22)
    profile_tag.add_theme_font_size_override("font_size", 12)
    profile_tag.add_theme_color_override("font_color", Color("#ff66d9"))
    shade.add_child(profile_tag)

    var settings_hint := Label.new()
    settings_hint.text = "NEON ARENA  /  READY TO FIGHT"
    settings_hint.position = Vector2(0, 704)
    settings_hint.size = Vector2(1280, 12)
    settings_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    settings_hint.add_theme_font_size_override("font_size", 9)
    settings_hint.add_theme_color_override("font_color", Color("#7894b5"))
    shade.add_child(settings_hint)
    _animate_overlay_in(shade)


func _open_news() -> void:
    _close_overlay()
    game_controls.visible = false
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color("#080d1b")
    ui.add_child(shade)
    overlay = shade
    _add_menu_ornaments(shade)

    var title := Label.new()
    title.text = "НОВОСТИ"
    title.position = Vector2(0, 34)
    title.size = Vector2(1280, 64)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", Color("#f3f8ff"))
    shade.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "ПОСЛЕДНИЕ СОБЫТИЯ KIWI ROUNDS"
    subtitle.position = Vector2(0, 100)
    subtitle.size = Vector2(1280, 26)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", Color("#4fe8e2"))
    shade.add_child(subtitle)

    var news_data := [
        ["01  /  NEON CITY", "НОВАЯ АРЕНА", "Неоновые улицы, светящиеся вывески и новые места для перестрелок."],
        ["02  /  COMBAT", "БОЕВАЯ СИСТЕМА", "Карточки усилений меняют каждый раунд. Собирай комбинации и адаптируйся."],
        ["03  /  CUSTOM", "ОБЛИКИ", "Выбирай внешний вид бойца и собирай свою коллекцию."]
    ]
    for i in range(news_data.size()):
        var x := 120.0 + float(i) * 350.0
        var card := Panel.new()
        card.position = Vector2(x, 205)
        card.size = Vector2(320, 330)
        var style := StyleBoxFlat.new()
        style.bg_color = Color("#101d32", 0.98)
        style.border_color = [Color("#40f0df"), Color("#ff4fd8"), Color("#7d8cff")][i]
        style.set_border_width_all(2)
        style.set_corner_radius_all(20)
        style.shadow_color = Color("#000000", 0.42)
        style.shadow_size = 18
        card.add_theme_stylebox_override("panel", style)
        shade.add_child(card)

        var stripe := ColorRect.new()
        stripe.position = Vector2(18, 18)
        stripe.size = Vector2(284, 5)
        stripe.color = [Color("#40f0df"), Color("#ff4fd8"), Color("#7d8cff")][i]
        card.add_child(stripe)

        var number := Label.new()
        number.text = news_data[i][0]
        number.position = Vector2(22, 46)
        number.size = Vector2(276, 24)
        number.add_theme_font_size_override("font_size", 12)
        number.add_theme_color_override("font_color", Color("#9cb2d1"))
        card.add_child(number)

        var heading := Label.new()
        heading.text = news_data[i][1]
        heading.position = Vector2(22, 105)
        heading.size = Vector2(276, 70)
        heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        heading.add_theme_font_size_override("font_size", 24)
        heading.add_theme_color_override("font_color", Color("#f5fbff"))
        card.add_child(heading)

        var body := Label.new()
        body.text = news_data[i][2]
        body.position = Vector2(22, 190)
        body.size = Vector2(276, 112)
        body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        body.add_theme_font_size_override("font_size", 16)
        body.add_theme_color_override("font_color", Color("#b9c9df"))
        card.add_child(body)

    var back := _add_button("НАЗАД", Vector2(510, 600), Vector2(260, 58), shade)
    back.add_theme_font_size_override("font_size", 18)
    back.add_theme_stylebox_override("normal", _menu_button_style(Color("#14243a"), Color("#40e9e1")))
    back.pressed.connect(_show_main_menu)
    _animate_overlay_in(shade)


func _animate_overlay_in(target: Control) -> void:
    if not is_instance_valid(target):
        return
    target.modulate.a = 0.0
    var entrance := create_tween()
    entrance.set_trans(Tween.TRANS_CUBIC)
    entrance.set_ease(Tween.EASE_OUT)
    entrance.tween_property(target, "modulate:a", 1.0, 0.24)


func _create_menu_banner(parent: Control) -> void:
    var banner := TextureRect.new()
    banner.name = "KiwiNeonBanner"
    banner.texture = load("res://assets/1795552443370.jpg") as Texture2D
    banner.set_anchors_preset(Control.PRESET_CENTER)
    banner.offset_left = -240.0
    banner.offset_top = -350.0
    banner.offset_right = 240.0
    banner.offset_bottom = -80.0
    banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    banner.z_index = 2

    var key_shader := Shader.new()
    key_shader.code = "shader_type canvas_item;\nvoid fragment() { vec4 c = texture(TEXTURE, UV) * COLOR; float v = max(max(c.r, c.g), c.b); float a = smoothstep(0.012, 0.075, v); COLOR = vec4(c.rgb, c.a * a); }"
    var key_material := ShaderMaterial.new()
    key_material.shader = key_shader
    banner.material = key_material
    parent.add_child(banner)

func _create_menu_record(parent: Control) -> void:
    var dock := Panel.new()
    dock.name = "MusicPlayerDock"
    dock.position = Vector2(1032, 20)
    dock.size = Vector2(228, 132)
    dock.clip_contents = true
    dock.mouse_filter = Control.MOUSE_FILTER_STOP
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#0b1422", 0.94)
    style.border_color = Color("#36e6df", 0.68)
    style.set_border_width_all(1)
    style.set_corner_radius_all(20)
    style.shadow_color = Color("#000000", 0.38)
    style.shadow_size = 16
    dock.add_theme_stylebox_override("panel", style)
    dock.gui_input.connect(func(event: InputEvent):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _open_music_player()
    )
    parent.add_child(dock)
    var caption := Label.new()
    caption.text = "NOW PLAYING"
    caption.position = Vector2(8, 5)
    caption.size = Vector2(212, 14)
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.add_theme_font_size_override("font_size", 8)
    caption.add_theme_color_override("font_color", Color("#91a7bb"))
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dock.add_child(caption)
    menu_record_disc = _make_vinyl_disc(dock, Vector2(78, 22), 72)
    var ticker_frame := Panel.new()
    ticker_frame.position = Vector2(12, 99)
    ticker_frame.size = Vector2(204, 22)
    ticker_frame.clip_contents = true
    ticker_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var ticker_style := StyleBoxFlat.new()
    ticker_style.bg_color = Color("#111e2c")
    ticker_style.set_corner_radius_all(8)
    ticker_frame.add_theme_stylebox_override("panel", ticker_style)
    dock.add_child(ticker_frame)
    music_ticker_label = Label.new()
    music_ticker_label.position = Vector2(0, 1)
    music_ticker_label.size = Vector2(460, 20)
    music_ticker_label.text = _current_music_title()
    music_ticker_label.add_theme_font_size_override("font_size", 11)
    music_ticker_label.add_theme_color_override("font_color", Color("#eaf2fb"))
    music_ticker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ticker_frame.add_child(music_ticker_label)
    var hint := Label.new()
    hint.text = "ОТКРЫТЬ ПЛЕЕР"
    hint.position = Vector2(8, 122)
    hint.size = Vector2(212, 9)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 7)
    hint.add_theme_color_override("font_color", Color("#71879a"))
    hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dock.add_child(hint)
    _update_music_track_button()

func _make_vinyl_disc(parent: Control, pos: Vector2, diameter: float) -> Control:
    var record := Panel.new()
    record.position = pos
    record.size = Vector2(diameter, diameter)
    record.pivot_offset = record.size * 0.5
    record.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var disc_style := StyleBoxFlat.new()
    disc_style.bg_color = Color("#101820")
    disc_style.border_color = Color("#526779")
    disc_style.set_border_width_all(2)
    disc_style.set_corner_radius_all(diameter * 0.5)
    record.add_theme_stylebox_override("panel", disc_style)
    parent.add_child(record)
    for i in range(3):
        var ring_size := diameter - 18.0 - float(i) * 20.0
        var ring := Panel.new()
        ring.position = Vector2((diameter - ring_size) * 0.5, (diameter - ring_size) * 0.5)
        ring.size = Vector2(ring_size, ring_size)
        ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var ring_style := StyleBoxFlat.new()
        ring_style.bg_color = Color(0, 0, 0, 0)
        ring_style.border_color = Color("#718095", 0.4)
        ring_style.set_border_width_all(1)
        ring_style.set_corner_radius_all(ring_size * 0.5)
        ring.add_theme_stylebox_override("panel", ring_style)
        record.add_child(ring)
    var center_size := diameter * 0.34
    var center := Panel.new()
    center.position = Vector2((diameter - center_size) * 0.5, (diameter - center_size) * 0.5)
    center.size = Vector2(center_size, center_size)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var center_style := StyleBoxFlat.new()
    center_style.bg_color = Color("#36bfc0")
    center_style.border_color = Color("#b5fff4")
    center_style.set_border_width_all(2)
    center_style.set_corner_radius_all(center_size * 0.5)
    center.add_theme_stylebox_override("panel", center_style)
    record.add_child(center)
    return record

func _open_music_player() -> void:
    if is_instance_valid(music_modal):
        return
    music_modal = ColorRect.new()
    music_modal.name = "MusicPlayerOverlay"
    music_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    music_modal.color = Color(0.015, 0.025, 0.045, 0.88)
    music_modal.mouse_filter = Control.MOUSE_FILTER_STOP
    music_modal.z_index = 50
    ui.add_child(music_modal)
    var panel := Panel.new()
    panel.position = Vector2(390, 118)
    panel.size = Vector2(500, 484)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#101b2a")
    panel_style.border_color = Color("#36e6df", 0.72)
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(24)
    panel.add_theme_stylebox_override("panel", panel_style)
    music_modal.add_child(panel)
    var close := Button.new()
    close.text = "✕"
    close.position = Vector2(444, 14)
    close.size = Vector2(38, 38)
    close.pressed.connect(_close_music_player)
    panel.add_child(close)
    var heading := Label.new()
    heading.text = "МУЗЫКА"
    heading.position = Vector2(30, 20)
    heading.size = Vector2(420, 30)
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 17)
    heading.add_theme_color_override("font_color", Color("#a9bdce"))
    panel.add_child(heading)
    music_modal_disc = _make_vinyl_disc(panel, Vector2(184, 72), 132)
    var title := Label.new()
    title.position = Vector2(34, 220)
    title.size = Vector2(432, 34)
    title.text = _current_music_title()
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("#f4f7fb"))
    title.clip_text = true
    panel.add_child(title)
    var sub := Label.new()
    sub.text = "KIWI ROUNDS • PLAYLIST"
    sub.position = Vector2(34, 258)
    sub.size = Vector2(432, 22)
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 10)
    sub.add_theme_color_override("font_color", Color("#71879a"))
    panel.add_child(sub)
    var visualizer := Control.new()
    visualizer.position = Vector2(62, 306)
    visualizer.size = Vector2(376, 48)
    visualizer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(visualizer)
    for i in range(30):
        var bar := ColorRect.new()
        bar.position = Vector2(float(i) * 12.0, 20.0)
        bar.size = Vector2(5.0, 18.0)
        bar.color = Color("#36e6df") if i % 3 != 0 else Color("#8b67ff")
        bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        visualizer.add_child(bar)
        music_visualizer_bars.append(bar)

    var pause := Button.new()
    pause.text = "Ⅱ  ПАУЗА"
    pause.position = Vector2(52, 376)
    pause.size = Vector2(174, 54)
    pause.add_theme_font_size_override("font_size", 14)
    pause.add_theme_stylebox_override("normal", _menu_button_style(Color("#172b43"), Color("#8b67ff")))
    pause.add_theme_stylebox_override("hover", _menu_button_style(Color("#263d60"), Color("#b69cff")))
    pause.add_theme_color_override("font_color", Color("#f0f5ff"))
    pause.pressed.connect(func():
        if is_instance_valid(music_player):
            if not music_player.playing:
                music_player.play()
                music_player.stream_paused = false
            else:
                music_player.stream_paused = not music_player.stream_paused
            pause.text = "▶  ПРОДОЛЖИТЬ" if music_player.stream_paused else "Ⅱ  ПАУЗА"
    )
    panel.add_child(pause)

    var skip := Button.new()
    skip.text = "⏭  СЛЕДУЮЩИЙ"
    skip.position = Vector2(238, 376)
    skip.size = Vector2(210, 54)
    skip.add_theme_font_size_override("font_size", 14)
    skip.add_theme_stylebox_override("normal", _menu_button_style(Color("#36e6df"), Color("#b5fff4")))
    skip.add_theme_stylebox_override("hover", _menu_button_style(Color("#73fff0"), Color.WHITE))
    skip.add_theme_color_override("font_color", Color("#07151d"))
    skip.pressed.connect(func():
        _play_next_music()
        title.text = _current_music_title()
        pause.text = "Ⅱ  ПАУЗА"
    )
    panel.add_child(skip)
    var footer := Label.new()
    footer.text = "Случайный трек при входе в меню и каждом раунде"
    footer.position = Vector2(24, 448)
    footer.size = Vector2(452, 20)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 10)
    footer.add_theme_color_override("font_color", Color("#71879a"))
    panel.add_child(footer)

func _close_music_player() -> void:
    if is_instance_valid(music_modal):
        music_modal.queue_free()
    music_modal = null
    music_modal_disc = null

func _create_menu_bot_preview(parent: Control) -> void:
    # Three rotating neon-city backdrops, built from layered geometry for a faux-3D scene.
    var backdrop := Control.new()
    backdrop.name = "MenuBattleBackdrop"
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(backdrop)
    parent.move_child(backdrop, 0)

    var variant := randi_range(0, 2)
    var palettes := [
        [Color("#070b1c"), Color("#101b38"), Color("#162d4c"), Color("#35f0e2"), Color("#ff4fd8")],
        [Color("#10091f"), Color("#25143f"), Color("#351b50"), Color("#a56bff"), Color("#42e9ff")],
        [Color("#06151d"), Color("#0c2935"), Color("#123c4b"), Color("#40f0bd"), Color("#ffb64a")]
    ]
    var p: Array = palettes[variant]

    var sky := ColorRect.new()
    sky.size = Vector2(1280, 720)
    sky.color = p[0]
    sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backdrop.add_child(sky)

    for y in range(8):
        var haze := ColorRect.new()
        haze.position = Vector2(0, float(y) * 42.0 + 100.0)
        haze.size = Vector2(1280, 48)
        haze.color = Color(p[1], 0.12 - float(y) * 0.009)
        haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
        backdrop.add_child(haze)

    # Distant skyline with glowing windows.
    for i in range(12):
        var w := 58.0 + float((i * 19) % 54)
        var h := 150.0 + float((i * 47) % 170)
        var x := float(i) * 112.0 - 20.0
        var building := Polygon2D.new()
        building.polygon = PackedVector2Array([
            Vector2(x, 420.0-h), Vector2(x+w, 420.0-h-22.0),
            Vector2(x+w+10.0, 420.0), Vector2(x-8.0, 420.0)
        ])
        building.color = p[1].darkened(0.25)
        backdrop.add_child(building)
        for row in range(4):
            for col in range(2):
                var window := ColorRect.new()
                window.position = Vector2(x + 10.0 + float(col)*22.0, 270.0 - h*0.42 + float(row)*27.0)
                window.size = Vector2(8, 13)
                window.color = Color(p[3] if (i+row+col)%2==0 else p[4], 0.52)
                window.mouse_filter = Control.MOUSE_FILTER_IGNORE
                backdrop.add_child(window)

    # Giant neon architecture frames the combat without hiding the fighters.
    var left_wall := Polygon2D.new()
    left_wall.polygon = PackedVector2Array([Vector2(0,0),Vector2(250,0),Vector2(385,570),Vector2(0,650)])
    left_wall.color = Color("#0b1427", 0.96)
    backdrop.add_child(left_wall)
    var right_wall := Polygon2D.new()
    right_wall.polygon = PackedVector2Array([Vector2(1010,0),Vector2(1280,0),Vector2(1280,650),Vector2(895,570)])
    right_wall.color = Color("#0a1325", 0.96)
    backdrop.add_child(right_wall)

    for side in [-1, 1]:
        var glow := Line2D.new()
        glow.points = PackedVector2Array([
            Vector2(20 if side < 0 else 1260, 30),
            Vector2(115 if side < 0 else 1165, 270),
            Vector2(185 if side < 0 else 1095, 520)
        ])
        glow.width = 8.0
        glow.default_color = Color(p[3], 0.88)
        glow.antialiased = true
        backdrop.add_child(glow)
        var glow_core := Line2D.new()
        glow_core.points = glow.points
        glow_core.width = 2.0
        glow_core.default_color = Color.WHITE
        glow_core.antialiased = true
        backdrop.add_child(glow_core)

    # Perspective floor converges behind the firefight.
    var floor := Polygon2D.new()
    floor.polygon = PackedVector2Array([
        Vector2(0, 490), Vector2(1280, 490), Vector2(1280, 720), Vector2(0, 720)
    ])
    floor.color = Color("#080f20")
    backdrop.add_child(floor)

    for i in range(17):
        var x := float(i) * 80.0
        var grid_line := Line2D.new()
        grid_line.points = PackedVector2Array([Vector2(640, 490), Vector2(x, 720)])
        grid_line.width = 2.0
        grid_line.default_color = Color(p[3], 0.28)
        grid_line.antialiased = true
        backdrop.add_child(grid_line)
    for i in range(6):
        var horizon := Line2D.new()
        var y := 500.0 + float(i*i) * 6.0
        horizon.points = PackedVector2Array([Vector2(0, y), Vector2(1280, y)])
        horizon.width = 1.5
        horizon.default_color = Color(p[4], 0.16)
        horizon.antialiased = true
        backdrop.add_child(horizon)

    # Floating signs and light panels create a layered cyberpunk city depth.
    for i in range(4):
        var sign := Panel.new()
        sign.position = Vector2(70.0 + float(i)*300.0, 115.0 + float(i%2)*62.0)
        sign.size = Vector2(150, 48)
        var sign_style := StyleBoxFlat.new()
        sign_style.bg_color = Color("#091322", 0.9)
        sign_style.border_color = p[4] if i%2==0 else p[3]
        sign_style.set_border_width_all(2)
        sign_style.set_corner_radius_all(7)
        sign.add_theme_stylebox_override("panel", sign_style)
        backdrop.add_child(sign)
        var sign_text := Label.new()
        sign_text.text = ["KIWI", "NEON", "ROUNDS", "CITY"][i]
        sign_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        sign_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        sign_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        sign_text.add_theme_font_size_override("font_size", 17)
        sign_text.add_theme_color_override("font_color", Color("#f4fbff"))
        sign.add_child(sign_text)

    # Neon cover blocks make the hiding position readable.
    var cover_shadow := Polygon2D.new()
    cover_shadow.polygon = PackedVector2Array([
        Vector2(670, 440), Vector2(890, 405), Vector2(925, 520), Vector2(695, 560)
    ])
    cover_shadow.color = Color("#030711", 0.86)
    backdrop.add_child(cover_shadow)
    var cover_face := Polygon2D.new()
    cover_face.polygon = PackedVector2Array([
        Vector2(680, 420), Vector2(880, 390), Vector2(905, 500), Vector2(700, 535)
    ])
    cover_face.color = Color("#13243d")
    backdrop.add_child(cover_face)
    var cover_edge := Line2D.new()
    cover_edge.points = PackedVector2Array([Vector2(680,420),Vector2(880,390),Vector2(905,500)])
    cover_edge.width = 5.0
    cover_edge.default_color = Color(p[3])
    cover_edge.antialiased = true
    backdrop.add_child(cover_edge)

    for i in range(28):
        var spark := ColorRect.new()
        spark.position = Vector2(float((i*97)%1280), float((i*53)%460)+35.0)
        spark.size = Vector2(3,3)
        spark.color = Color(p[4] if i%2==0 else p[3], 0.7)
        spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
        backdrop.add_child(spark)

    _add_menu_battle_scene(backdrop)


func _add_menu_battle_scene(parent: Control) -> void:
    # Character 1 is under fire; character 3 keeps low behind cover farther back.
    # A third fighter fires from the foreground. All poses are frozen for a clean poster-like scene.
    var far_cover := Polygon2D.new()
    far_cover.polygon = PackedVector2Array([
        Vector2(705, 380), Vector2(865, 380), Vector2(850, 495), Vector2(690, 495)
    ])
    far_cover.color = Color("#263d52", 0.94)
    parent.add_child(far_cover)

    var far_cover_edge := Line2D.new()
    far_cover_edge.points = PackedVector2Array([Vector2(705,380),Vector2(865,380),Vector2(850,495),Vector2(690,495),Vector2(705,380)])
    far_cover_edge.width = 3.0
    far_cover_edge.default_color = Color("#6fe7dc", 0.48)
    far_cover_edge.antialiased = true
    parent.add_child(far_cover_edge)

    var character_3: ArenaPlayer = PLAYER_SCRIPT.new()
    character_3.name = "MenuCharacter3Hiding"
    character_3.body_color = Color("#79d85d")
    character_3.skin_style = "kiwi"
    character_3.position = Vector2(780, 435)
    character_3.facing = -1.0
    character_3.aim_input = Vector2(-1, -0.15)
    character_3.scale = Vector2(0.66, 0.66)
    character_3.set_physics_process(false)
    character_3.set_process(false)
    parent.add_child(character_3)
    character_3.set_physics_process(false)
    character_3.set_process(false)

    var near_cover_shadow := Polygon2D.new()
    near_cover_shadow.polygon = PackedVector2Array([
        Vector2(250, 560), Vector2(535, 560), Vector2(565, 690), Vector2(220, 690)
    ])
    near_cover_shadow.color = Color("#070d18", 0.72)
    parent.add_child(near_cover_shadow)

    var near_cover := Polygon2D.new()
    near_cover.polygon = PackedVector2Array([
        Vector2(255, 520), Vector2(525, 520), Vector2(550, 675), Vector2(235, 675)
    ])
    near_cover.color = Color("#30495e", 0.98)
    parent.add_child(near_cover)

    var near_cover_top := Polygon2D.new()
    near_cover_top.polygon = PackedVector2Array([
        Vector2(255,520), Vector2(525,520), Vector2(535,535), Vector2(250,535)
    ])
    near_cover_top.color = Color("#9ab5bd", 0.9)
    parent.add_child(near_cover_top)

    var character_1: ArenaPlayer = PLAYER_SCRIPT.new()
    character_1.name = "MenuCharacter1UnderFire"
    character_1.body_color = Color("#e8bd9c")
    character_1.skin_style = "kiwi_human"
    character_1.position = Vector2(410, 535)
    character_1.facing = 1.0
    character_1.aim_input = Vector2(0.85, -0.2)
    character_1.scale = Vector2(0.92, 0.92)
    character_1.set_physics_process(false)
    character_1.set_process(false)
    parent.add_child(character_1)
    character_1.set_physics_process(false)
    character_1.set_process(false)

    var shooter: ArenaPlayer = PLAYER_SCRIPT.new()
    shooter.name = "MenuForegroundShooter"
    shooter.body_color = Color("#ff786f")
    shooter.skin_style = "kiwi"
    shooter.position = Vector2(1015, 545)
    shooter.facing = -1.0
    shooter.aim_input = Vector2(-0.88, -0.30)
    shooter.scale = Vector2(1.18, 1.18)
    shooter.set_physics_process(false)
    shooter.set_process(false)
    parent.add_child(shooter)
    shooter.set_physics_process(false)
    shooter.set_process(false)

    # Layered projectile trail points toward character 1, with a soft muzzle flash.
    var trail_glow := Line2D.new()
    trail_glow.points = PackedVector2Array([Vector2(985, 515), Vector2(820, 505), Vector2(670, 520), Vector2(545, 545)])
    trail_glow.width = 15.0
    trail_glow.default_color = Color("#ff9b72", 0.18)
    trail_glow.antialiased = true
    parent.add_child(trail_glow)

    var trail := Line2D.new()
    trail.points = PackedVector2Array([Vector2(985, 515), Vector2(820, 505), Vector2(670, 520), Vector2(545, 545)])
    trail.width = 3.5
    trail.default_color = Color("#ffe8a1", 0.82)
    trail.antialiased = true
    parent.add_child(trail)

    var muzzle_glow := Polygon2D.new()
    muzzle_glow.polygon = PackedVector2Array([
        Vector2(970,495), Vector2(1002,506), Vector2(978,520), Vector2(1010,535),
        Vector2(970,532), Vector2(954,548), Vector2(958,520), Vector2(940,505)
    ])
    muzzle_glow.color = Color("#ffd978", 0.72)
    parent.add_child(muzzle_glow)

    # Foreground silhouette frames the action and reinforces the perspective.
    var foreground := Polygon2D.new()
    foreground.polygon = PackedVector2Array([
        Vector2(0, 660), Vector2(1280, 660), Vector2(1280, 720), Vector2(0, 720)
    ])
    foreground.color = Color("#080f1b", 0.34)
    parent.add_child(foreground)

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
        ["НАСТРОЙКА МАТЧА",Callable(self,"_show_match_settings")],
        ["НАЗАД",Callable(self,"_show_main_menu")]
    ],"До победы в матче: %d раундов" % match_rounds_to_win)

func _show_difficulty_menu() -> void:
    _show_panel("СЛОЖНОСТЬ БОТОВ",[
        ["ЛЁГКАЯ",Callable(self,"_set_easy")],
        ["ОБЫЧНАЯ",Callable(self,"_set_normal")],
        ["СЛОЖНАЯ",Callable(self,"_set_hard")],
        ["НАЗАД",Callable(self,"_show_mode_menu")]
    ],"Сейчас: " + bot_difficulty.to_upper())

func _show_match_settings() -> void:
    _show_panel("НАСТРОЙКА МАТЧА",[
        ["3 РАУНДА",Callable(self,"_set_match_rounds").bind(3)],
        ["5 РАУНДОВ",Callable(self,"_set_match_rounds").bind(5)],
        ["7 РАУНДОВ",Callable(self,"_set_match_rounds").bind(7)],
        ["9 РАУНДОВ",Callable(self,"_set_match_rounds").bind(9)],
        ["НАЗАД",Callable(self,"_show_mode_menu")]
    ],"Сейчас: до %d побед" % match_rounds_to_win)

func _set_match_rounds(value: int) -> void:
    match_rounds_to_win = clampi(value, 1, 15)
    _show_match_settings()

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
            _start_online_match(str(data.get("hostId", "")), int(data.get("roundsToWin", 5)))
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
        _online_send({"type":"start_match", "roundsToWin":match_rounds_to_win})

func _start_online_match(host_id: String, rounds_to_win: int = 5) -> void:
    match_rounds_to_win = clampi(rounds_to_win, 1, 15)
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
        ["НАСТРОИТЬ РАСПОЛОЖЕНИЕ КНОПОК",Callable(self,"_open_control_editor")],
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
    title.text = "МАГАЗИН ОБЛИКОВ"
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
    fighter.position = Vector2(250, 265)
    fighter.scale = Vector2(0.96, 0.96)
    fighter.set_physics_process(false)
    fighter.set_process(false)
    fighter.velocity = Vector2.ZERO
    fighter.z_index = 2
    preview_area.add_child(fighter)

    var name_label := Label.new()
    name_label.text = str(skin.get("name", skin.get("id", "MOD"))).to_upper() + "  •  ОБЛИК " + str(skin_index + 1)
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
    shade.modulate.a = 0.0
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
    _animate_overlay_in(shade)

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
    elif score_player >= match_rounds_to_win or score_bot >= match_rounds_to_win:
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
