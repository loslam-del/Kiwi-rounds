extends Control
class_name VirtualJoystick

signal value_changed(value: Vector2)

@export var deadzone := 0.12
@export var knob_limit := 52.0
@export var base_color := Color(0.20, 0.32, 0.48, 0.55)
@export var knob_color := Color(0.72, 0.86, 1.0, 0.82)

var value := Vector2.ZERO
var active_index := -1
var mouse_active := false

func _ready() -> void:
    custom_minimum_size = Vector2(150, 150)
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
        accept_event()
    elif event is InputEventMouseMotion and mouse_active:
        _set_from_position(event.position)
        accept_event()

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
    draw_circle(center, minf(size.x, size.y) * 0.47, base_color)
    draw_arc(center, minf(size.x, size.y) * 0.47, 0.0, TAU, 64, Color(0.65, 0.79, 0.96, 0.7), 3.0)
    draw_circle(center + value * knob_limit, minf(size.x, size.y) * 0.19, knob_color)
