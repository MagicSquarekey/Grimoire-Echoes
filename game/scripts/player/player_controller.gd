## PlayerController - 玩家控制器
extends Node2D

# 依赖
@export var player_body = null
@export var stats = null

# 移动参数
var move_direction = Vector2.ZERO
var is_dodging = false
var dodge_cooldown = 0.0
var dodge_duration = 0.2
var dodge_speed_multiplier = 3.0
var dodge_cooldown_time = 1.0

# 信号
signal dodge_started()
signal dodge_ended()

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	
	if player_body == null:
		player_body = get_parent()
	
	if stats == null and player_body:
		stats = player_body.get_node_or_null("PlayerStats")
	
	if stats == null:
		stats = PlayerStats.new()
		if player_body:
			player_body.add_child(stats)

func _process(delta: float) -> void:
	if dodge_cooldown > 0:
		dodge_cooldown -= delta
	
	_handle_movement_input()
	_handle_dodge_input()

func _physics_process(delta: float) -> void:
	_apply_movement(delta)

func _handle_movement_input() -> void:
	if is_dodging:
		return
	
	move_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		move_direction.y -= 1
	if Input.is_action_pressed("move_down"):
		move_direction.y += 1
	if Input.is_action_pressed("move_left"):
		move_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		move_direction.x += 1
	
	move_direction = move_direction.normalized()

func _handle_dodge_input() -> void:
	if Input.is_action_just_pressed("dodge") and not is_dodging and dodge_cooldown <= 0:
		_start_dodge()

func _start_dodge() -> void:
	is_dodging = true
	dodge_cooldown = dodge_cooldown_time
	dodge_started.emit()
	
	# 使用 tween 替代 Timer 避免节点泄漏
	var tween = create_tween()
	tween.tween_callback(_end_dodge).set_delay(dodge_duration)

func _end_dodge() -> void:
	is_dodging = false
	dodge_ended.emit()

func _apply_movement(delta: float) -> void:
	if player_body == null or stats == null:
		return
	
	var velocity = Vector2.ZERO
	
	if is_dodging:
		velocity = move_direction * stats.get_move_speed() * dodge_speed_multiplier
	else:
		velocity = move_direction * stats.get_move_speed()
	
	player_body.velocity = velocity
	player_body.move_and_slide()

func get_move_direction() -> Vector2:
	return move_direction

func is_moving() -> bool:
	return move_direction.length() > 0

func get_is_dodging() -> bool:
	return is_dodging
