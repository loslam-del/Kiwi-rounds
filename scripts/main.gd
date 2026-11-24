extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PULSE_SCRIPT = preload("res://scripts/pulse.gd")

const UPGRADES := [
    {"id": "swift", "name": "Лёгкие ноги", "desc": "Скорость движения +16%"},
    {"id": "spring", "name": "Пружинный прыжок", "desc": "Прыжок становится выше"},
    {"id": "wave", "name": "Сильная волна", "desc": "Импульс сильнее отталкивает"},
    {"id": "rapid", "name": "Быстрая перезарядка", "desc": "Импульсы доступны чаще"},
    {"id": "sturdy", "name": "Разгон", "desc": "Немного скорости и силы"}
]

var player: ArenaPlayer
var rival: ArenaPlayer
var ui: Control
var hud: Label
var overlay: PanelContainer
var platform_nodes: Array[StaticBody2D] = []
var score_player := 0
var score_bot := 0
var round_index := 1
var phase := "fight"

func _ready() -> void:
    randomize()
    _make_arena(0)
    _make_players()
    _make_ui()
    _update_hud()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#10182d"))
    for i in range(18):
        draw_circle(Vector2(float((i * 97) % 1280), float((i * 61) % 560)), 2.0, Color("#263653"))
    draw_rect(Rect2(0, 690, 1280, 30), Color("#18243c"))

func _make_arena(map_id: int) -> void:
    for old_platform in platform_nodes:
        if is_instance_valid(old_platform):
            old_platform.queue_free()
    platform_nodes.clear()
    _add_platform(Vector2(640, 700), Vector2(1400, 50))
    match map_id % 3:
        0:
            _add_platform(Vector2(330, 545), Vector2(250, 24))
            _add_platform(Vector2(950, 545), Vector2(250, 24))
            _add_platform(Vector2(640, 420), Vector2(190, 22))
            _add_platform(Vector2(130, 635), Vector2(170, 20))
            _add_platform(Vector2(1150, 635), Vector2(170, 20))
        1:
            _add_platform(Vector2(250, 560), Vector2(210, 22))
            _add_platform(Vector2(500, 455), Vector2(180, 22))
            _add_platform(Vector2(780, 455), Vector2(180, 22))
            _add_platform(Vector2(1030, 560), Vector2(210, 22))
            _add_platform(Vector2(640, 330), Vector2(210, 22))
        2:
            _add_platform(Vector2(200, 600), Vector2(180, 22))
            _add_platform(Vector2(420, 495), Vector2(190, 22))
            _add_platform(Vector2(640, 590), Vector2(190, 22))
            _add_platform(Vector2(860, 495), Vector2(190, 22))
            _add_platform(Vector2(1080, 600), Vector2(180, 22))
            _add_platform(Vector2(640, 390), Vector2(150, 22))

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

func _spawn_pulse(origin: Vector2, direction: float, force: float, tint: Color) -> void:
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
    _add_hold_button("◀", Vector2(28, 575), Vector2(105, 105), Callable(player, "set_left"))
    _add_hold_button("▶", Vector2(145, 575), Vector2(105, 105), Callable(player, "set_right"))
    _add_hold_button("ПРЫЖОК", Vector2(900, 575), Vector2(145, 105), Callable(player, "set_jump"))
    _add_hold_button("ВОЛНА", Vector2(1060, 575), Vector2(185, 105), Callable(player, "set_fire"))

func _add_hold_button(caption: String, at: Vector2, dimensions: Vector2, setter: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.position = at
    button.size = dimensions
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 22)
    button.add_theme_color_override("font_color", Color("#ffffff"))
    button.add_theme_stylebox_override("normal", _button_style(Color("#263b5b")))
    button.add_theme_stylebox_override("pressed", _button_style(Color("#3d638e")))
    button.button_down.connect(setter.bind(true))
    button.button_up.connect(setter.bind(false))
    ui.add_child(button)

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
    var choices: Array = UPGRADES.duplicate()
    choices.shuffle()
    for i in range(3):
        var item: Dictionary = choices[i]
        var button := Button.new()
        button.text = "%s\n%s" % [item.name, item.desc]
        button.custom_minimum_size = Vector2(570, 82)
        button.add_theme_font_size_override("font_size", 19)
        button.add_theme_stylebox_override("normal", _button_style(Color("#294467")))
        button.pressed.connect(_choose_upgrade.bind(item.id))
        column.add_child(button)

func _choose_upgrade(upgrade_id: String) -> void:
    if phase != "upgrade":
        return
    player.apply_upgrade(upgrade_id)
    var bot_choice: Dictionary = UPGRADES.pick_random()
    rival.apply_upgrade(bot_choice.id)
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
