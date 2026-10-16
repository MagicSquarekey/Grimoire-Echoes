## Shop - 商店系统
## 在波次间购买强化（WaveManager 波次完成后开门营业，关闭后开下一波）
extends CanvasLayer

# 商店物品数据
var shop_items: Array[Dictionary] = []
var purchased_items: Array[String] = []

# UI引用
@onready var item_list: VBoxContainer = $MarginContainer/VBoxContainer/ItemList
@onready var gold_label: Label = $MarginContainer/VBoxContainer/GoldLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	# WaveManager 通过该组在波次间隙找到商店
	add_to_group("shop_ui")
	close_button.pressed.connect(_on_close_pressed)
	hide()

## 显示商店
func show_shop() -> void:
	# 生成商店物品
	_generate_shop_items()
	
	# 更新金币显示
	_update_gold_display()
	
	show()
	get_tree().paused = true

## 生成商店物品
func _generate_shop_items() -> void:
	# 清空现有物品
	for child in item_list.get_child_count():
		item_list.get_child(child).queue_free()
	
	# 生成3个随机物品
	shop_items = _get_random_items(3)
	
	for item in shop_items:
		var price := _item_price(item)
		var button = Button.new()
		button.text = "%s - %d金币" % [item["name"], price]
		button.custom_minimum_size = Vector2(350, 50)

		# 金币不足则置灰（不禁止重复购买：同名商品可叠加，价格递增）
		if GameManager.total_gold < price:
			button.disabled = true

		# 连接信号
		var item_data = item
		button.pressed.connect(func(): _on_item_pressed(item_data))

		item_list.add_child(button)

## 获取随机商品（可重复购买：同名价格递增 1.25^n，永不枯竭）
func _get_random_items(count: int) -> Array[Dictionary]:
	var all_items = [
		{"id": "damage_boost", "name": "伤害提升+10%", "price": 50, "type": "stat", "value": 0.1},
		{"id": "health_boost", "name": "生命提升+20%", "price": 40, "type": "stat", "value": 0.2},
		{"id": "speed_boost", "name": "移动速度+15%", "price": 45, "type": "stat", "value": 0.15},
		{"id": "crit_boost", "name": "暴击率+10%", "price": 60, "type": "stat", "value": 0.1},
		{"id": "life_steal", "name": "生命偷取+5%", "price": 80, "type": "stat", "value": 0.05},
		{"id": "cooldown_reduction", "name": "冷却减少+10%", "price": 55, "type": "stat", "value": 0.1},
		{"id": "crit_damage", "name": "暴击伤害+25%", "price": 65, "type": "stat", "value": 0.25},
		{"id": "max_health_flat", "name": "生命上限+30", "price": 35, "type": "stat_flat", "value": 30},
		{"id": "magnet_range", "name": "拾取范围+40", "price": 30, "type": "stat_flat", "value": 40},
		{"id": "defense_boost", "name": "护甲+8%", "price": 60, "type": "stat", "value": 0.08},
		{"id": "attack_power", "name": "攻击力+12%", "price": 70, "type": "stat", "value": 0.12},
		{"id": "element_power", "name": "元素伤害+15%", "price": 75, "type": "stat", "value": 0.15},
	]
	# 每次随机抽 3 件（允许重复出现，购买价格递增形成金币回收曲线）
	var pool := all_items.duplicate(true)
	pool.shuffle()
	var picked: Array = pool.slice(0, mini(count, pool.size()))
	var result: Array[Dictionary] = []
	for item in picked:
		result.append(item)
	return result

## 更新金币显示
func _update_gold_display() -> void:
	gold_label.text = "金币: %d" % GameManager.total_gold

## 商品现价：基础价 × 1.25^(同名已购次数)，形成金币回收曲线防止金币溢出
func _item_price(item: Dictionary) -> int:
	var bought := 0
	for pid in purchased_items:
		if pid == item["id"]:
			bought += 1
	return int(round(item["price"] * pow(1.25, bought)))

## 购买物品
func _on_item_pressed(item: Dictionary) -> void:
	var price := _item_price(item)
	if GameManager.total_gold >= price:
		# 扣除金币
		GameManager.total_gold -= price

		# 应用效果
		_apply_item_effect(item)

		# 记录已购买（用于价格递增）
		purchased_items.append(item["id"])

		# 更新显示（同步 HUD 金币）
		EventBus.gold_changed.emit(GameManager.total_gold)
		_update_gold_display()
		_generate_shop_items()

		# 显示提示
		EventBus.show_toast.emit("购买成功: %s" % item["name"], 1.5)

## 应用物品效果
func _apply_item_effect(item: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var stats = player.get_node_or_null("PlayerStats")
	if not stats:
		return

	match item["id"]:
		"damage_boost":
			stats.attack_damage_bonus += item["value"]
		"health_boost":
			stats.max_health *= (1.0 + item["value"])
			stats.current_health = stats.max_health
		"speed_boost":
			stats.move_speed_bonus += item["value"]
		"crit_boost":
			stats.crit_rate_bonus += item["value"]
		"life_steal":
			stats.life_steal += item["value"]
		"cooldown_reduction":
			stats.cooldown_reduction += item["value"]
		"crit_damage":
			stats.crit_damage_bonus += item["value"]
		"max_health_flat":
			stats.max_health += item["value"]
			stats.current_health = mini(stats.current_health + item["value"], stats.max_health)
		"magnet_range":
			stats.magnet_bonus += item["value"]
		"defense_boost":
			stats.defense_bonus += item["value"]
		"attack_power":
			stats.attack_bonus += item["value"]
		"element_power":
			stats.element_damage_bonus += item["value"]

## 关闭商店（按钮 / 游戏内 ESC 共用）：恢复游戏并通知波次管理器开下一波
func close_shop() -> void:
	get_tree().paused = false
	hide()
	# 通知游戏继续
	EventBus.shop_closed.emit()

## 关闭商店
func _on_close_pressed() -> void:
	close_shop()
