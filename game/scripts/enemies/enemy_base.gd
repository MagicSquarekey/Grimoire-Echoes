## EnemyBase - 敌人基类
## 所有敌人的基类，定义敌人的基本属性和行为
class_name EnemyBase
extends CharacterBody2D

# 敌人属性
@export var enemy_name = ""
@export var enemy_type = ""
@export var max_health = 30.0
@export var attack_damage = 8.0
@export var move_speed = 120.0
@export var exp_reward = 10
@export var gold_reward = 1

# 当前状态
var current_health = 30.0
var is_alive = true
var target = null

# 精英/Boss 标记（由 EnemySpawner 在生成时调用 make_elite/make_boss 设置）
var is_elite = false
var is_boss = false

# Boss 技能状态（冲锋 + 召唤）
var _boss_charge_timer = 6.0      # 冲锋技能倒计时
var _boss_summon_timer = 14.0     # 召唤技能倒计时（召唤频率压低，避免无限小怪吸干输出）
var _boss_charging = false        # 正在冲锋
var _boss_telegraphing = false    # 冲锋前摇（蓄力闪烁）

# AI状态枚举
enum AIState {
	IDLE,
	CHASE,
	ATTACK,
	DEAD
}
var current_ai_state = AIState.IDLE

# 组件引用
@onready var body = $Body
@onready var collision_shape = $CollisionShape2D
@onready var hitbox = $Hitbox
@onready var hurtbox = $Hurtbox
@onready var detection_area = $DetectionArea
@onready var ai_timer = $AITimer

# 信号
signal enemy_died(enemy)
signal enemy_hit(attacker, damage)

const GEM_SCENE = preload("res://scenes/pickups/experience_gem.tscn")
const COIN_SCENE = preload("res://scenes/pickups/gold_coin.tscn")
const POTION_SCENE = preload("res://scenes/pickups/health_potion.tscn")
const MAGNET_SCENE = preload("res://scenes/pickups/magnet_pickup.tscn")

func _ready() -> void:
	current_health = max_health
	# 信号由 .tscn 的 [connection] 段连接，不在脚本中重复连接
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_process_ai(delta)

## 受到伤害
func take_damage(damage: float, attacker = null) -> void:
	if not is_alive:
		return
	
	current_health -= damage
	enemy_hit.emit(attacker, damage)
	
	_on_hit_effect()
	
	if current_health <= 0:
		_die()

## 应用状态效果
func apply_status_effect(effect_type, value, duration) -> void:
	pass

## 应用击退效果
func apply_knockback(direction: Vector2, force: float) -> void:
	velocity = direction * force
	move_and_slide()

## 死亡处理
func _die() -> void:
	if not is_alive:
		return
	is_alive = false
	current_ai_state = AIState.DEAD
	
	collision_shape.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	
	_on_death_animation()
	enemy_died.emit(self)
	# Boss 死亡广播（Boss 血条监听后隐藏）
	if is_boss:
		EventBus.boss_defeated.emit(enemy_name)
	# 掉落物含 Area2D；_die 常由物理回调(弹体body_entered)触发，
	# 在物理flush期间直接add_child会报 "Can't change this state while flushing queries"，改为延迟执行
	_drop_rewards.call_deferred()
	
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		queue_free()

## 掉落奖励：经验宝石 + 概率金币
func _drop_rewards() -> void:
	EventBus.enemy_killed.emit(enemy_name, exp_reward, gold_reward)
	
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return
	
	# 掉落经验宝石（承载敌人经验值）
	if GEM_SCENE:
		var gem = GEM_SCENE.instantiate()
		gem.pickup_value = exp_reward
		scene_root.add_child(gem)
		# add_child之后再设置位置，否则赋值丢失
		gem.global_position = global_position
	
	# 40% 概率掉落金币（精英/Boss 必掉金币堆）
	var guaranteed: bool = is_elite or is_boss
	if COIN_SCENE and (guaranteed or randf() < 0.4):
		var coin = COIN_SCENE.instantiate()
		coin.pickup_value = gold_reward
		scene_root.add_child(coin)
		coin.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))

	# 回血药剂：3% 概率，Boss 必掉（续航保障）
	if POTION_SCENE and (is_boss or randf() < 0.03):
		var potion = POTION_SCENE.instantiate()
		scene_root.add_child(potion)
		potion.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))

	# 磁石：0.5% 概率（拾取后吸附全场宝石）
	if MAGNET_SCENE and not is_boss and randf() < 0.005:
		var magnet = MAGNET_SCENE.instantiate()
		scene_root.add_child(magnet)
		magnet.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12))

## AI逻辑处理
func _process_ai(delta: float) -> void:
	if is_boss:
		_boss_skill_tick(delta)
	if _boss_charging:
		# 冲锋期间速度由技能 tween 控制，跳过常规移动 AI
		move_and_slide()
		return
	match current_ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.CHASE:
			_process_chase(delta)
		AIState.ATTACK:
			_process_attack(delta)

## ---------- 精英/Boss 生成标记 ----------

const RING_TEXTURE = preload("res://assets/fx/ring_glow.png")

## 精英：血量×8、伤害×1.5、金色外观 + 1.25x 缩放 + 脚下金环；必掉金币堆+大量经验
func make_elite() -> void:
	if is_boss:
		return
	is_elite = true
	max_health *= 8.0
	current_health = max_health
	attack_damage *= 1.5
	exp_reward *= 5
	gold_reward *= 5
	modulate = Color(1.0, 0.85, 0.25)
	_apply_body_scale_mult(1.25)
	_add_ground_ring(Color(1.0, 0.8, 0.2, 0.85), 1.3)

## Boss：血量×8（以 5 波玩家实战命中率校准：Boss 战 60-90 秒，不会卡死波次推进；
## 10/15 波 Boss 随玩家成长自然回到这个体感时长）、
## 伤害×2、暗红外观 + 指定缩放，注册 boss 分组并广播血条
func make_boss(scale_mult: float = 2.2) -> void:
	is_boss = true
	max_health *= 8.0
	current_health = max_health
	attack_damage *= 2.0
	move_speed *= 1.15  # Boss 需要跟得上玩家（冲锋技能负责爆发位移）
	exp_reward = 200
	gold_reward = 50
	modulate = Color(0.75, 0.25, 0.25)
	_apply_body_scale_mult(scale_mult)
	_add_ground_ring(Color(0.9, 0.2, 0.15, 0.9), 1.6)
	add_to_group("boss")
	# 此时尚未入树，延迟广播（Boss 血条监听该信号显示）
	EventBus.boss_spawned.emit.call_deferred(enemy_name)

## 缩放视觉身体并等比放大碰撞半径（根节点缩放会干扰物理，故直接改半径）
func _apply_body_scale_mult(mult: float) -> void:
	if body:
		body.scale *= mult
	for shape_holder in [collision_shape, hitbox, hurtbox]:
		if shape_holder and shape_holder.get_child_count() > 0:
			var cs = shape_holder.get_child(0)
			if cs is CollisionShape2D and cs.shape is CircleShape2D:
				cs.shape = cs.shape.duplicate()
				cs.shape.radius *= mult

## 脚下光环（纯视觉）：加法混合的环形贴图
func _add_ground_ring(color: Color, ring_scale: float) -> void:
	var ring = Sprite2D.new()
	ring.name = "EliteRing"
	ring.texture = RING_TEXTURE
	ring.modulate = color
	ring.position = Vector2(0, 10)
	ring.scale = Vector2(ring_scale, ring_scale * 0.62)
	ring.z_index = -1
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ring.material = mat
	add_child(ring)

## ---------- Boss 专属技能：周期冲锋 + 召唤暗影仆从 ----------

func _boss_skill_tick(delta: float) -> void:
	if _boss_telegraphing or _boss_charging:
		return
	if not target or not is_instance_valid(target):
		return

	_boss_charge_timer -= delta
	_boss_summon_timer -= delta

	if _boss_summon_timer <= 0.0:
		_boss_summon_timer = 14.0
		_boss_summ_minions()
	if _boss_charge_timer <= 0.0:
		_boss_charge_timer = 5.0
		_boss_start_charge()

func _boss_start_charge() -> void:
	if not target or not is_instance_valid(target):
		return
	_boss_telegraphing = true
	# 前摇：闪烁提示 0.6s（纯视觉，不改逻辑）
	var tween = create_tween()
	tween.tween_property(body, "modulate", Color(1.0, 0.3, 0.3), 0.15)
	tween.tween_property(body, "modulate", Color.WHITE, 0.15)
	tween.tween_property(body, "modulate", Color(1.0, 0.3, 0.3), 0.15)
	tween.tween_property(body, "modulate", Color.WHITE, 0.15)
	await tween.finished
	if not is_instance_valid(self) or not is_alive:
		return
	_boss_telegraphing = false
	_boss_charging = true
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed * 5.0
	var t2 = create_tween()
	t2.tween_property(self, "velocity", Vector2.ZERO, 0.55)
	await t2.finished
	if is_instance_valid(self):
		_boss_charging = false

func _boss_summ_minions() -> void:
	var scene = load("res://scenes/enemies/shadow_servant.tscn")
	if scene == null:
		return
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return
	for i in 2:
		var minion = scene.instantiate() as EnemyBase
		if minion == null:
			continue
		if minion.has_method("set_difficulty"):
			minion.set_difficulty(get_difficulty_scale())
		var angle = TAU * float(i) / 2.0
		var pos = global_position + Vector2(cos(angle), sin(angle)) * 140.0
		scene_root.add_child(minion)
		minion.global_position = pos
		# 召唤物计入波次存活数，保持 WaveManager 账目平衡
		WaveManager.enemies_alive += 1
		# 召唤传送门（纯视觉，与常规出怪一致）
		FxLib.spawn_portal(minion, pos)

func get_difficulty_scale() -> float:
	return 1.0 + float(WaveManager.current_wave) * 0.1

## 空闲状态
## 幸存者类标准：生成即仇恨玩家（出生环带在探测半径 300px 之外，
## 若等 DetectionArea 触发，环形合围/狼群包会原地罚站，压力闭环断裂）
func _process_idle(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
	if target:
		current_ai_state = AIState.CHASE

## 追踪状态
func _process_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_ai_state = AIState.IDLE
		return
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	var distance = global_position.distance_to(target.global_position)
	if distance < 50.0:
		current_ai_state = AIState.ATTACK

## 攻击状态（子类重写）
func _process_attack(delta: float) -> void:
	pass

## 受击特效
var _flash_tween: Tween

func _on_hit_effect() -> void:
	if body:
		# 受击反馈：白闪（HDR 提亮配合辉光）+ 体积微缩放
		if _flash_tween and _flash_tween.is_valid():
			_flash_tween.kill()
		body.modulate = Color(1.9, 1.9, 1.9, 1.0)
		var base_scale: Vector2 = body.scale
		body.scale = base_scale * 1.14
		_flash_tween = create_tween()
		_flash_tween.set_parallel(true)
		_flash_tween.tween_property(body, "modulate", Color.WHITE, 0.14)
		_flash_tween.tween_property(body, "scale", base_scale, 0.14)

## 死亡动画
func _on_death_animation() -> void:
	FxLib.death_dissipate(self)  # 视觉：死亡消散粒子（纯视觉调用，不改逻辑）
	if body:
		var tween = create_tween()
		tween.tween_property(body, "modulate:a", 0.0, 0.3)

## 受击区域检测
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		var attacker = area.get_parent()
		if attacker.has_method("get_damage"):
			take_damage(attacker.get_damage(), attacker)

## 检测区域检测
func _on_detection_area_body_entered(body_node: Node2D) -> void:
	if body_node.is_in_group("player"):
		target = body_node

## AI计时器超时
func _on_ai_timer_timeout() -> void:
	if target and not is_instance_valid(target):
		target = null
		current_ai_state = AIState.IDLE

## 获取伤害
func get_damage() -> float:
	return attack_damage

## 设置难度系数
func set_difficulty(multiplier: float) -> void:
	max_health *= multiplier
	current_health = max_health
	attack_damage *= multiplier
	move_speed *= (1.0 + (multiplier - 1.0) * 0.2)
