## HealingWind - 治愈之风
## 自然系治疗法术
class_name HealingWind
extends BuffSpell

# 治愈之风特有属性
@export var heal_percent: float = 0.08  # 恢复最大生命值8%
@export var hot_percent: float = 0.03  # 持续回复3%
@export var hot_duration: float = 4.0  # 持续回复时间

func _init() -> void:
	spell_name = "治愈之风"
	spell_element = "nature"
	spell_type = SpellType.BUFF
	damage = 0
	cooldown = 10.0
	mana_cost = 20.0
	buff_type = "heal"
	buff_duration = hot_duration

## 重写施放逻辑
func _on_cast(target: Node2D = null) -> void:
	# 应用治愈效果
	_apply_healing_effect(target if target else owner_node)

## 应用治愈效果
func _apply_healing_effect(target: Node2D) -> void:
	# 计算治疗量
	var player_stats = _get_owner_stats()
	if player_stats:
		var instant_heal = player_stats.max_health * heal_percent
		var hot_heal_per_second = player_stats.max_health * hot_percent / hot_duration
		
		# 立即治疗
		if target.has_method("heal"):
			target.heal(instant_heal)
		
		# 应用持续治疗效果
		_apply_heal_over_time(target, hot_heal_per_second, hot_duration)
	
	# 播放治愈视觉效果
	_play_healing_visual(target)
	
	# 开始持续时间计时
	is_active = true
	active_timer = hot_duration

## 应用持续治疗效果
func _apply_heal_over_time(target: Node2D, heal_per_second: float, duration: float) -> void:
	var elapsed = 0.0
	while elapsed < duration:
		# 等待1秒
		await get_tree().create_timer(1.0).timeout
		elapsed += 1.0
		
		# 应用治疗
		if target.has_method("heal"):
			target.heal(heal_per_second)

## 播放治愈视觉效果
func _play_healing_visual(target: Node2D) -> void:
	# 创建治愈精灵
	var heal_sprite = Sprite2D.new()
	heal_sprite.name = "HealingWindSprite"
	heal_sprite.modulate = Color(0.3, 1.0, 0.3, 0.6)  # 绿色
	heal_sprite.scale = Vector2(1.5, 1.5)
	target.add_child(heal_sprite)
	
	# 创建粒子效果
	var particles = GPUParticles2D.new()
	particles.name = "HealingWindParticles"
	particles.emitting = true
	particles.lifetime = hot_duration
	particles.amount = 15
	target.add_child(particles)

## 重写法术升级
func _on_upgrade() -> void:
	heal_percent *= 1.08
	
	match spell_level:
		5:
			# Lv.5: 治疗+3%
			heal_percent += 0.03
			print("治愈之风升级: 治疗量增加")
		10:
			# Lv.10: 移除debuff
			print("治愈之风升级: 移除减益效果")
		15:
			# Lv.15: 净化领域
			print("治愈之风升级: 净化领域")