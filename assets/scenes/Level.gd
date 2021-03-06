extends Node2D

export(Color, RGB) var clear_color

onready var rooms = $Rooms.get_children()
onready var player = $Player
onready var current_room = $Rooms/Room1
onready var current_respawn = $Rooms/Room1/Respawns/R1
onready var monolog = $Monolog

var Death = preload("res://assets/scenes/effects/Death.tscn")
var Respawn = preload("res://assets/scenes/effects/Respawn.tscn")
var current_color = Color("b8b5d0")

func _ready() -> void:
	BackgroundMusic.autoplay = true
	BackgroundMusic.stream_paused = false
	BackgroundMusic.play()
	VisualServer.set_default_clear_color(clear_color)
	$EndLayer/Endfade.color = Color("00ffffff")

func _on_Area2D_body_entered(body: Node) -> void:
	if body is Player:
		$Monolog.play("bottomless")

func _find_nearest_respawn() -> void:
	var last_distance: float = 1000000
	var nearest_respawn = null
	for respawn in current_room.get_node("Respawns").get_children():
		var distance = respawn.get_position().distance_to($Player.position)
		if distance < last_distance:
			nearest_respawn = respawn
			last_distance = distance

		if nearest_respawn != current_respawn && nearest_respawn != null:
			current_respawn = nearest_respawn

func _activate_room(room: Camera2D) -> void:
	current_room = room
	room.make_current()
	_find_nearest_respawn()

func _on_Roomchecker_timeout() -> void:
	if player == null:
		return
	if current_room.rect.has_point(player.position):
		#still in old room.. this way, overlapping will work ;-)
		return
	for room in rooms:
		if room.rect.has_point(player.position):
			_activate_room(room)

### shake logic ##
export var decay = 0.8  # How quickly the shaking stops [0, 1].
export var max_offset = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
export var max_roll = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

func set_trauma(amount):
	trauma = min(amount, 1.0)

func _process(delta):
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		_shake_current_room()

func _shake_current_room():
	var amount = pow(trauma, trauma_power)
	current_room.rotation = max_roll * amount * rand_range(-1, 1)
	current_room.offset.x = max_offset.x * amount * rand_range(-1, 1)
	current_room.offset.y = max_offset.y * amount * rand_range(-1, 1)

func _on_Player_dash() -> void:
	set_trauma(0.18)

func _on_MoodChange_body_entered(body: Node) -> void:
	if body is Player:
		current_color = Color("#e16e1a")
		$CanvasModulate.set_color(current_color)

func _on_MoodChange3_body_entered(body: Node) -> void:
	if body is Player:
		current_color = Color("b8b5d0")
		$CanvasModulate.set_color(current_color)

func end() -> void:
	var err: = get_tree().change_scene("res://assets/scenes/Credits.tscn")
	if err:
		printerr(err)

func _on_Player_dead(p: Player) -> void:
	var death = Death.instance()
	death.global_position = p.global_position
	add_child(death)
	yield(death, "done")

	var respawn = Respawn.instance()
	respawn.global_position = current_respawn.global_position
	add_child(respawn)
	yield(respawn, "done")
	p.respawn(current_respawn.global_position)

func _on_Dash_collected() -> void:
	current_respawn = get_node("Rooms/Room13/Respawns/R2")
	monolog.play("can_dash")

func _on_DoubleDash_collected() -> void:
	monolog.play("can_ddash")

func _on_FastWalk_collected() -> void:
	monolog.play("can_walk_fast")

func _on_MirrorPiece_Jump_collected() -> void:
	monolog.play("can_jump")
