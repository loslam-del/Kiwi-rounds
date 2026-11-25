extends Control
class_name VirtualJoystick

signal value_changed(value: Vector2)
signal released

@export var deadzone := 0.12
@export var knob_limit := 72.0
@export var base_color := Color(0.05, 0.24, 0.34, 0.72)
@export var knob_color := Color(0.43, 0.96, 0.91, 0.94)

var value := Vector2.ZERO
var active_index := -1
var mouse_active := false

func _ready() -> void:
    custom_minimum_size = Vector2(116, 116)
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and active_index == -1:
            active_index = event.index
            _set_from_position(event.position)
            accept_event()
        elif not event.pressed and event.index == active_index:
            active_index = -1
            _reset_value()
            released.emit()
            accept_event()
    elif event is InputEventScreenDrag and event.index == active_index:
        _set_from_position(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        mouse_active = event.pressed
        if mouse_active:
            _set_from_position(event.position)
        else:
            _reset_value()
            released.emit()
        accept_event()
    elif event is InputEventMouseMotion and mouse_active:
        _set_from_position(event.position)
        accept_event()

func cancel_input() -> void:
    active_index = -1
    mouse_active = false
    _reset_value()

func _set_from_position(local_position: Vector2) -> void:
    var center := size * 0.5
    var offset := local_position - center
    var radius := minf(size.x, size.y) * 0.5
    var normalized := offset / maxf(radius, 1.0)
    if normalized.length() > 1.0:
        normalized = normalized.normalized()
    if normalized.length() < deadzone:
        normalized = Vector2.ZERO
    value = normalized
    value_changed.emit(value)
    queue_redraw()

func _reset_value() -> void:
    value = Vector2.ZERO
    value_changed.emit(value)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var radius := minf(size.x, size.y) * 0.46
    # Compact twin-ring joystick with a clear directional thumb pad.
    draw_circle(center, radius * 1.10, Color(0.10,0.92,0.88,0.055))
    draw_circle(center + Vector2(0,4), radius, Color(0.015,0.035,0.065,0.72))
    draw_circle(center, radius, base_color)
    draw_arc(center, radius, 0.0, TAU, 72, Color(0.22,0.96,0.91,0.92), 3.0, true)
    draw_arc(center, radius * 0.70, 0.0, TAU, 56, Color(0.60,0.98,0.90,0.26), 1.6, true)
    for angle in [0.0, PI*0.5, PI, PI*1.5]:
        var a := Vector2(cos(angle),sin(angle))
        draw_line(center + a * (radius*0.76), center + a * (radius*0.88), Color(0.58,1.0,0.92,0.52), 1.4, true)
    var knob_center := center + value * knob_limit
    draw_circle(knob_center + Vector2(0,2), radius * 0.29, Color(0.01,0.04,0.07,0.58))
    draw_circle(knob_center, radius * 0.27, Color(0.62,0.78,0.94,0.92))
    draw_arc(knob_center, radius * 0.27, 0.0, TAU, 40, Color(0.82,1.0,0.96,0.96), 1.5, true)
    draw_circle(knob_center + Vector2(-radius*0.07,-radius*0.08), radius*0.075, Color(1,1,1,0.30))
