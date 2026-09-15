## MagnetPickup - 磁石
## 敌人概率掉落（0.5%），拾取后吸附全场经验宝石
extends PickupBase

## 初始化
func _init() -> void:
	pickup_name = "磁石"

## 应用效果：全场经验宝石进入超大磁吸范围并高速飞向玩家
func _apply_effect(_collector) -> void:
	var attracted := 0
	for p in get_tree().get_nodes_in_group("pickups"):
		if p == self or not is_instance_valid(p):
			continue
		# 只吸宝石（宝石/金币体系里 pickup_name 含"宝石"），磁石之间互不干扰
		if p is PickupBase and str(p.pickup_name).contains("宝石"):
			p.magnet_range = 100000.0
			p.magnet_speed = 900.0
			attracted += 1
	EventBus.pickup_collected.emit("magnet", attracted)
	EventBus.show_toast.emit("磁石！吸附全场宝石 x%d" % attracted, 1.2)
