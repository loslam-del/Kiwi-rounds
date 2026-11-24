extends Control
class_name VirtualActionButton

signal button_down
signal button_up
signal pressed

@export var caption := "ACTION"
@export var fill_color := Color("#263b5b")
@export var accent_color := Color("#8ba66a")

var active_touch := -1
var mouse_active := false
var label_node: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    focus_mode = Control.FOCUS_NONE
    label_node = Label.new()
    label_node.text = caption
    label_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label_node.add_theme_font_size_override("font_size", 19)
    label_node.add_theme_color_override("font_color", Color.WHITE)
    add_child(label_node)
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and active_touch == -1:
            active_touch = event.index
            button_down.emit()
            queue_redraw()
            accept_event()
        elif not event.pressed and event.index == active_touch:
            active_touch = -1
            button_up.emit()
            pressed.emit()
            queue_redraw()
            accept_event()
    elif event is InputEventScreenDrag and event.index == active_touch:
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed and not mouse_active:
            mouse_active = true
            button_down.emit()
            queue_redraw()
        elif not event.pressed and mouse_active:
            mouse_active = false
            button_up.emit()
            pressed.emit()
            queue_redraw()
        accept_event()

func _draw() -> void:
    var active := active_touch != -1 or mouse_active
    var rect := Rect2(Vector2.ZERO, size)
    draw_style_box(_make_style(Color("#3d638e") if active else fill_color), rect)

func _make_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = accent_color
    style.set_border_width_all(3)
    style.set_corner_radius_all(14)
    return style
