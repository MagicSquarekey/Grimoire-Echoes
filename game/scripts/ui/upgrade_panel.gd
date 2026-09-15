## UpgradePanel - 升级选择面板
## 玩家升级时显示的法术选择界面（含金币重投）
class_name UpgradePanel
extends Control

## 组件引用
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var card_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/CardContainer
@onready var description_label: RichTextLabel = $Panel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var reroll_button: Button = $Panel/MarginContainer/VBoxContainer/RerollButton

## 升级选项场景
var upgrade_card_scene: PackedScene = preload("res://scenes/ui/upgrade_card.tscn")

## 当前选项
var current_options = []

## 本次面板已重投次数（价格翻倍递增，面板关闭后重置）
var _reroll_count: int = 0

## 信号
signal option_selected(option_index: int)
signal reroll_requested

## 初始化
func _ready() -> void:
	# 连接信号
	visible = false
	reroll_button.pressed.connect(_on_reroll_pressed)

## 重投价格：基础 20 金币，每次翻倍（20 → 40 → 80 …）
static func reroll_cost(uses: int) -> int:
	return 20 * int(pow(2.0, uses))

## 当前重投所需金币
func get_reroll_cost() -> int:
	return reroll_cost(_reroll_count)

## 显示升级选项（新面板：重投计数归零）
func show_upgrade_options(options) -> void:
	_reroll_count = 0
	current_options = options
	visible = true

	_rebuild_cards(options)

	# 入场动画
	_play_entrance_animation()

## 重投：重建卡片但保留重投计数（调用方已完成金币扣减）
func apply_reroll(options) -> void:
	_reroll_count += 1
	current_options = options

	_rebuild_cards(options)

	# 入场动画
	_play_entrance_animation()

## 重建选项卡片
func _rebuild_cards(options) -> void:
	# 清空旧卡片
	for child in card_container.get_children():
		child.queue_free()

	# 生成新卡片
	# 注意：必须先 add_child 再 setup —— 卡片的 Label 引用是 @onready，
	# 入树前为 null，先 setup 会全部跳过赋值，留下场景里的占位文本
	for i in range(options.size()):
		var option = options[i]
		var card = upgrade_card_scene.instantiate()
		if card:
			card_container.add_child(card)
			card.setup(option)
			card.option_selected.connect(_on_option_selected.bind(i))

	_refresh_reroll_button()

## 刷新重投按钮文案与可用状态
func _refresh_reroll_button() -> void:
	var cost := get_reroll_cost()
	reroll_button.text = "🔄 重投（%d 金币）" % cost
	reroll_button.disabled = GameManager.total_gold < cost
	reroll_button.tooltip_text = "花费 %d 金币刷新本组升级选项，每次重投价格翻倍" % cost

## 重投按钮按下 → 交由玩家控制器扣金币并生成新选项
func _on_reroll_pressed() -> void:
	reroll_requested.emit()
	_refresh_reroll_button()

## 选择选项
func _on_option_selected(index: int) -> void:
	option_selected.emit(index)
	hide_panel()

## 隐藏面板
func hide_panel() -> void:
	visible = false
	current_options.clear()

## 入场动画
func _play_entrance_animation() -> void:
	var cards = card_container.get_children()
	for i in range(cards.size()):
		var card = cards[i]
		card.modulate.a = 0.0
		card.scale = Vector2(0.8, 0.8)

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(i * 0.1)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3).set_delay(i * 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

## 获取选项信息
func get_option_info(index: int) -> Dictionary:
	if index >= 0 and index < current_options.size():
		return current_options[index]
	return {}
