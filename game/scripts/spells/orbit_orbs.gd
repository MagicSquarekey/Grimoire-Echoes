## OrbitOrbs - 环绕法书
## 奥术系环绕法术：召唤 2-4 颗奥术光球绕玩家旋转（半径约 70px），
## 光球为加法混合光晕 + 微型拖尾，接触敌人造成伤害；每个敌人 0.5s 内不重复受伤。
## 施法刷新光球（数量随等级提升），持续 orbit_duration 后消散。
class_name OrbitOrbs
extends BaseSpell

## 环绕参数
@export var orbit_radius: float = 70.0
@export var orbit_speed: float = 2.6  # rad/s
@export var orbit_duration: float = 8.0
@export var hit_radius: float = 24.0
@export var hit_interval: float = 0.5  # 每个敌人受击间隔

## 控制器节点（管理光球旋转与命中）
var _controller: Node2D = null

func _init() -> void:
	spell_name = "环绕法书"
	spell_element = "arcane"
	spell_type = SpellType.RING
	damage = 10.0
	cooldown = orbit_duration
	mana_cost = 0.0  # 自动战斗法术不消耗法力
	max_level = 20

## 当前光球数量：2 → 4（每 3 级 +1）
func _orb_count() -> int:
	return clampi(2 + (spell_level - 1) / 3, 2, 4)

## 施放：刷新环绕光球
func _on_cast(_target = null) -> void:
	# 旧的控制器还在就先刷新时长，否则新建
	if _controller != null and is_instance_valid(_controller):
		_controller.refresh(orbit_duration, _orb_count(), damage)
		return
	_controller = preload("res://scripts/spells/orbit_orbs_controller.gd").new()
	get_tree().current_scene.add_child.call_deferred(_controller)
	# 延迟入树后初始化（跟随玩家）
	_controller.setup_deferred(owner_node, orbit_radius, orbit_speed, orbit_duration,
			_orb_count(), damage, hit_radius, hit_interval)

func _on_upgrade() -> void:
	damage *= 1.15

func get_spell_info() -> Dictionary:
	var info := super.get_spell_info()
	info["orbs"] = _orb_count()
	return info
