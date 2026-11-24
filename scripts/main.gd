extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PULSE_SCRIPT = preload("res://scripts/pulse.gd")
const JOYSTICK_SCRIPT = preload("res://scripts/virtual_joystick.gd")
const MOD_LOADER_SCRIPT = preload("res://scripts/mod_loader.gd")

const DEFAULT_UPGRADES := [
    {"id": "swift", "name": "Лёгкие ноги", "desc": "Скорость движения +16%", "effect": "swift"},
    {"id": "spring", "name": "Пружинный прыжок", "desc": "Прыжок становится выше", "effect": "spring"},
    {"id": "wave", "name": "Сильная волна", "desc": "Импульс сильнее отталкивает", "effect": "wave"},
    {"id": "rapid", "name": "Быстрая перезарядка", "desc": "Импульсы доступны чаще", "effect": "rapid"},
    {"id": "sturdy", "name": "Разгон", "desc": "Немного скорости и силы", "effect": "sturdy"}
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
var overlay: PanelContainer
var platform_nodes: Array[StaticBody2D] = []
var mod_loader: GameModLoader
var all_maps: Array[Dictionary] = []
var all_upgrades: Array[Dictionary] = []
var map_index := 0
var score_player := 0
var score_bot := 0
var round_index := 1
var phase := "fight"

func _ready() -> void:
    randomize()
    mod_loader = MOD_LOADER_SCRIPT.new()
    mod_loader.load_all()
    all_maps = DEFAULT_MAPS.duplicate(true)
    all_maps.append_array(mod_loader.maps)
    all_upgrades = DEFAULT_UPGRADES.duplicate(true)
    all_upgrades.append_array(mod_loader.upgrades)
    _make_arena(0)
    _make_players()
    _make_ui()
    _update_hud()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#10182d"))
    for i in range(18):
        draw_circle(Vector2(float((i * 97) % 1280), float((i * 61) % 560)), 2.0, Color("#263653"))
    draw_rect(Rect2(0, 690, 1280, 30), Color("#18243c"))

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
            if typeof(item) != TYPE_DICTIONARY:
                continue
            _add_platform(Vector2(float(item.get("x", 640)), float(item.get("y", 500))), Vector2(float(item.get("w", 180)), float(item.get("h", 22))))

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
    visual.polygon = PackedVector2Array([
        Vector2(-dimensions.x / 2, -dimensions.y / 2),
        Vector2(dimensions.x / 2, -dimensions.y / 2),
        Vector2(dimensions.x / 2, dimensions.y / 2),
        Vector2(-dimensions.x / 2, dimensions.y / 2)
    ])
    visual.color = Color("#354766")
    body.add_child(visual)
    var stripe := Line2D.new()
    stripe.points = PackedVector2Array([Vector2(-dimensions.x / 2, -dimensions.y / 2), Vector2(dimensions.x / 2, -dimensions.y / 2)])
    stripe.width = 4.0
    stripe.default_color = Color("#6f91b9")
    body.add_child(stripe)

func _make_players() -> void:
    player = PLAYER_SCRIPT.new()
    player.body_color = Color("#39d6c5")
    if not mod_loader.skins.is_empty():
        var skin: Dictionary = mod_loader.skins[0]
        player.body_color = Color.from_string(str(skin.get("color", "#39d6c5")), Color("#39d6c5"))
    player.position = Vector2(350, 390)
    player.pulse_requested.connect(_spawn_pulse)
    add_child(player)
    rival = PLAYER_SCRIPT.new()
    rival.is_bot = true
    rival.body_color = Color("#ff786f")
    rival.position = Vector2(930, 390)
    rival.target = player
    rival.pulse_requested.connect(_spawn_pulse)
    add_child(rival)

func _spawn_pulse(origin: Vector2, direction: Vector2, force: float, tint: Color) -> void:
    var pulse: EnergyPulse = PULSE_SCRIPT.new()
    pulse.configure(direction, force, tint)
    pulse.global_position = origin
    add_child(pulse)

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(ui)

    hud = Label.new()
    hud.position = Vector2(0, 18)
    hud.size = Vector2(1280, 50)
    hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud.add_theme_font_size_override("font_size", 28)
    hud.add_theme_color_override("font_color", Color("#f4f7ff"))
    ui.add_child(hud)

    var movement_joystick: VirtualJoystick = JOYSTICK_SCRIPT.new()
    movement_joystick.position = Vector2(35, 535)
    movement_joystick.size = Vector2(150, 150)
    movement_joystick.value_changed.connect(player.set_move)
    ui.add_child(movement_joystick)

    var fire_button := _add_button("ВОЛНА", Vector2(205, 585), Vector2(125, 88))
    fire_button.button_down.connect(player.set_fire.bind(true))
    fire_button.button_up.connect(player.set_fire.bind(false))

    var aim_joystick: VirtualJoystick = JOYSTICK_SCRIPT.new()
    aim_joystick.position = Vector2(1080, 535)
    aim_joystick.size = Vector2(150, 150)
    aim_joystick.value_changed.connect(player.set_aim)
    ui.add_child(aim_joystick)

    var jump_button := _add_button("ПРЫЖОК", Vector2(1090, 405), Vector2(130, 82))
    jump_button.button_down.connect(player.set_jump.bind(true))
    jump_button.button_up.connect(player.set_jump.bind(false))

func _add_button(caption: String, at: Vector2, dimensions: Vector2) -> Button:
    var button := Button.new()
    button.text = caption
    button.position = at
    button.size = dimensions
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_color_override("font_color", Color("#ffffff"))
    button.add_theme_stylebox_override("normal", _button_style(Color("#263b5b")))
    button.add_theme_stylebox_override("pressed", _button_style(Color("#3d638e")))
    ui.add_child(button)
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

func _process(_delta: float) -> void:
    if phase != "fight":
        return
    if player.global_position.y > 850:
        _finish_round(false)
    elif rival.global_position.y > 850:
        _finish_round(true)

func _finish_round(player_won: bool) -> void:
    if phase != "fight":
        return
    phase = "upgrade"
    if player_won:
        score_player += 1
    else:
        score_bot += 1
    _update_hud()
    if score_player >= 3 or score_bot >= 3:
        _show_match_end()
    else:
        _show_upgrade_panel()

func _update_hud() -> void:
    if is_instance_valid(hud):
        hud.text = "РАУНД %d     ТЫ  %d : %d  CPU" % [round_index, score_player, score_bot]

func _show_upgrade_panel() -> void:
    _remove_overlay()
    overlay = PanelContainer.new()
    overlay.position = Vector2(330, 170)
    overlay.size = Vector2(620, 390)
    overlay.add_theme_stylebox_override("panel", _button_style(Color("#172943")))
    ui.add_child(overlay)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    overlay.add_child(column)
    var title := Label.new()
    title.text = "ВЫБЕРИ УЛУЧШЕНИЕ"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    column.add_child(title)
    var choices: Array = all_upgrades.duplicate(true)
    choices.shuffle()
    var count := mini(3, choices.size())
    for i in range(count):
        var item: Dictionary = choices[i]
        var button := Button.new()
        button.text = "%s\n%s" % [str(item.get("name", item.get("id", "Upgrade"))), str(item.get("desc", ""))]
        button.custom_minimum_size = Vector2(570, 82)
        button.add_theme_font_size_override("font_size", 19)
        button.add_theme_stylebox_override("normal", _button_style(Color("#294467")))
        button.pressed.connect(_choose_upgrade.bind(str(item.get("effect", item.get("id", "")))))
        column.add_child(button)

func _choose_upgrade(upgrade_id: String) -> void:
    if phase != "upgrade":
        return
    player.apply_upgrade(upgrade_id)
    var bot_choice: Dictionary = all_upgrades.pick_random()
    rival.apply_upgrade(str(bot_choice.get("effect", bot_choice.get("id", ""))))
    _remove_overlay()
    round_index += 1
    _make_arena(round_index - 1)
    player.reset_round(Vector2(350, 390))
    rival.reset_round(Vector2(930, 390))
    phase = "fight"
    _update_hud()

func _show_match_end() -> void:
    _remove_overlay()
    overlay = PanelContainer.new()
    overlay.position = Vector2(390, 230)
    overlay.size = Vector2(500, 250)
    overlay.add_theme_stylebox_override("panel", _button_style(Color("#172943")))
    ui.add_child(overlay)
    var column := VBoxContainer.new()
    overlay.add_child(column)
    var title := Label.new()
    title.text = "ПОБЕДА!" if score_player >= 3 else "ПОБЕДИЛ CPU"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 34)
    column.add_child(title)
    var again := Button.new()
    again.text = "СЫГРАТЬ ЕЩЁ"
    again.custom_minimum_size = Vector2(460, 90)
    again.pressed.connect(_restart_match)
    column.add_child(again)

func _restart_match() -> void:
    score_player = 0
    score_bot = 0
    round_index = 1
    player.move_speed = 430.0
    player.jump_speed = -735.0
    player.pulse_force = 610.0
    player.pulse_interval = 0.78
    rival.move_speed = 430.0
    rival.jump_speed = -735.0
    rival.pulse_force = 610.0
    rival.pulse_interval = 0.78
    _remove_overlay()
    _make_arena(0)
    player.reset_round(Vector2(350, 390))
    rival.reset_round(Vector2(930, 390))
    phase = "fight"
    _update_hud()

func _remove_overlay() -> void:
    if is_instance_valid(overlay):
        overlay.queue_free()
    overlay = null
