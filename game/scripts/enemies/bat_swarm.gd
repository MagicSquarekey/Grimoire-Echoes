## BatSwarm - 蝙蝠群（E12，飞行群体）
## 单个脆到一发带走，靠数量和航线压人：collision_mask = 0，直接越过所有单位与地形，
## 飞行轨迹叠了垂直于前进方向的正弦摆动，所以玩家的直线预判弹很难白嫖到它。
## 成批出场用 spawner 的 flight 阵型（同侧宽扇区、更远出生距离，模拟"从空中扑过来"）。
class_name BatSwarm
extends EnemyBase

@export var bite_interval: float = 0.8
@export var wobble_amplitude: float = 90.0  # 横摆速度（px/s）
@export var wobble_frequency: float = 3.4

var _bite_timer := 0.0
var _phase := 0.0

func _init() -> void:
	enemy_name = "蝙蝠群"
	enemy_type = "swarm"
	max_health = 8.0
	attack_damage = 4.0
	move_speed = 165.0
	exp_reward = 5
	gold_reward = 1

func _process_ai(delta: float) -> void:
	if not target or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
		if target == null:
			return

	var to_target = target.global_position - global_position
	var distance = to_target.length()
	var direction: Vector2 = to_target.normalized()

	_phase += delta * wobble_frequency
	if distance > 34.0:
		velocity = direction * move_speed + direction.orthogonal() * sin(_phase) * wobble_amplitude
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_bite_timer -= delta
		if _bite_timer <= 0.0:
			_bite_timer = bite_interval
			if target.has_method("take_damage"):
				target.take_damage(attack_damage, self)
