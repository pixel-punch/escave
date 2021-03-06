class_name StateMachine
extends Node

export var initial_state := NodePath()
onready var state = get_node(initial_state)

var disabled: bool = false setget set_disabled

signal transitioned(old_state, new_state)

func _ready() -> void:
	yield(owner, "ready")
	for child in get_children():
		child.state_machine = self
	state.enter()

func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)

func _process(delta: float) -> void:
	state.update(delta)

func _physics_process(delta: float) -> void:
	state.physics_update(delta)

func transition_to(state_name: String, msg := {}) -> void:
	if not has_node(state_name):
		return
	state.leave()
	var old_state = state.name
	state = get_node(state_name)
	state.enter(msg)
	emit_signal("transitioned", old_state, state_name)

func set_disabled(value: bool) -> void:
	set_process(!value)
	set_physics_process(!value)
	set_process_input(!value)
	set_process_unhandled_input(!value)
	set_process_unhandled_key_input(!value)
