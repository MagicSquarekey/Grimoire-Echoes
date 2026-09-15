## TreasureChest - 稀有宝箱（事件波实体）
## 波次开始时由 GameController 放置在玩家附近屏内；触碰开启：
## 金币 + 经验宝石迸发 + 回血药剂，随后播放开启动画并消失
extends Area2D

const GEM_SCENE = preload("res://scenes/pickups/experience_gem.tscn")
const POTION_SCENE = preload("res://scenes/pickups/health_potion.tscn")

const GOLD_REWARD := 60
const GEM_COUNT := 6
const GEM_VALUE := 15

var _opened := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 宝箱待机浮动（只动视觉子节点，避免与外部定位互相打架）
	var visual = get_node_or_null("Visual")
	if visual is Node2D:
		var base_y: float = visual.position.y
		var tw = create_tween().set_loops()
		tw.tween_property(visual, "position:y", base_y - 6.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(visual, "position:y", base_y, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if _opened or not body.is_in_group("player"):
		return
	_opened = true
	set_deferred("monitoring", false)

	# 奖励：金币入账（掉落物涉及物理节点，需延迟到物理 flush 之外生成）
	GameManager.add_gold(GOLD_REWARD)
	EventBus.gold_changed.emit(GameManager.total_gold)
	EventBus.show_toast.emit("宝箱开启：+%d 金币！" % GOLD_REWARD, 1.8)
	AudioManager.play_named("chest_open", 0.8)
	_spawn_rewards.call_deferred()

	# 开启动画：弹跳放大后收缩消失
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.08)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

## 生成散落奖励（不能在物理回调内直接 add_child 物理节点）
func _spawn_rewards() -> void:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return
	for i in GEM_COUNT:
		var gem = GEM_SCENE.instantiate()
		gem.pickup_value = GEM_VALUE
		scene_root.add_child(gem)
		gem.global_position = global_position + Vector2(randf_range(-46, 46), randf_range(-40, 40))
	if POTION_SCENE:
		var potion = POTION_SCENE.instantiate()
		scene_root.add_child(potion)
		potion.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(10, 30))
