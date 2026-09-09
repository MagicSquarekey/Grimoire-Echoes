## sprite_body.gd - 精灵身体视觉控制（仅视觉表现，不碰游戏逻辑）
## 挂在场景里的 "Body" AnimatedSprite2D 节点上（父节点为 CharacterBody2D）。
## 职责：
##   1. 根据父节点 velocity 切换 idle / run 动画
##   2. 根据 velocity.x 左右翻转（flip_h）
##   3. 玩家模式（auto_variant=true）下按 GameManager.current_character
##      自动加载对应配色变体的 SpriteFrames（fire/water/lightning）
extends AnimatedSprite2D

## 移动状态播放的动画名（虫类等可改 "walk"——.tres 里统一叫 "run"）
@export var run_anim: String = "run"
@export var idle_anim: String = "idle"
## 低于该速度视为站立（px/s）
@export var speed_threshold: float = 8.0
## 渲染素材默认朝向为右时填 false；若素材朝左则填 true
@export var base_flip_h: bool = false
## 玩家用：按 GameManager.current_character 自动切换配色变体
@export var auto_variant: bool = false

var _parent_body: Node2D


func _ready() -> void:
	_parent_body = get_parent() as Node2D
	if auto_variant:
		_apply_character_variant()
	if sprite_frames:
		if sprite_frames.has_animation(idle_anim):
			play(idle_anim)
		elif sprite_frames.get_animation_names().size() > 0:
			play(sprite_frames.get_animation_names()[0])


## 玩家配色变体：fire_mage / water_mage / lightning_mage → player_<元素>.tres
func _apply_character_variant() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or not ("current_character" in gm):
		return
	var char_id := str(gm.current_character)
	if char_id.is_empty():
		return  # 保留场景里默认指定的 SpriteFrames
	var variant := char_id.trim_suffix("_mage")  # fire_mage → fire
	var path := "res://assets/sprites/gen/player_%s.tres" % variant
	if ResourceLoader.exists(path):
		var frames := load(path)
		if frames is SpriteFrames:
			sprite_frames = frames


func _physics_process(_delta: float) -> void:
	if _parent_body == null or not is_instance_valid(_parent_body):
		return
	var v := Vector2.ZERO
	if _parent_body is CharacterBody2D:
		v = (_parent_body as CharacterBody2D).velocity
	elif "velocity" in _parent_body:
		v = _parent_body.velocity

	var moving := v.length_squared() > speed_threshold * speed_threshold
	var target := run_anim if moving else idle_anim
	if animation != target and sprite_frames and sprite_frames.has_animation(target):
		play(target)

	# 侧视素材：默认朝右，向左移动时水平翻转
	if absf(v.x) > 1.0:
		flip_h = (v.x < 0.0) != base_flip_h
