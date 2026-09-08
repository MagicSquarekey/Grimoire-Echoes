## ExperienceGem - 经验宝石
## 击杀敌人后掉落的经验值物品，靠近自动吸取
extends PickupBase

## 初始化
func _init() -> void:
	pickup_name = "经验宝石"

## 应用效果：直接把经验加到玩家属性
func _apply_effect(collector) -> void:
	if collector and collector.has_method("get_stats"):
		var stats = collector.get_stats()
		if stats:
			stats.add_exp(pickup_value)
	EventBus.exp_gem_collected.emit(int(pickup_value))
