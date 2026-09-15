## sprite_body.gd - 精灵身体视觉控制（仅视觉表现，不碰游戏逻辑）
## 挂在场景里的 "Body" AnimatedSprite2D 节点上（父节点为 CharacterBody2D）。
## 职责：
##   1. 根据父节点 velocity 切换 idle / run 动画
##   2. 根据 velocity.x 左右翻转（flip_h）；竖直移动明显时改用
##      *_front（向下，面向镜头）/ *_back（向上，背对镜头）朝向动画，
##      对应动画不存在时自动回退侧视（兼容旧 .tres）
##   3. 玩家模式（auto_variant=true）下按 GameManager.current_character
##      自动加载对应配色变体的 SpriteFrames（fire/water/lightning）
extends AnimatedSprite2D

## 移动状态播放的动画名（虫类等可改 "walk"——.tres 里统一叫 "run"）
@export var run_anim: String = "run"
@export var idle_anim: String = "idle"
## 施法动画名（三向：cast / cast_front / cast_back；.tres 无此动画时自动跳过）
@export var cast_anim: String = "cast"
## 施法动作持续时间（秒）
@export var cast_duration: float = 0.4
## 低于该速度视为站立（px/s）
@export var speed_threshold: float = 8.0
## 渲染素材默认朝向为右时填 false；若素材朝左则填 true
@export var base_flip_h: bool = false
## 玩家用：按 GameManager.current_character 自动切换配色变体
@export var auto_variant: bool = false

var _parent_body: Node2D
# ---- 施法表现（仅玩家 auto_variant 启用）----
var _cast_timer: float = 0.0
var _last_vert := ""  # 最近一次纵向朝向："" / "_front" / "_back"
var _staff_tip_flash := true  # 施法瞬间法杖尖端元素闪光开关
# ---- 2.5D 动效：跑动起伏 + 站立呼吸 ----
## 跑动起伏幅度（px，作用于 sprite 的 offset.y，不影响节点 position/物理）
@export var bob_amplitude: float = 1.5
## 跑动起伏频率（rad/s）
@export var bob_speed: float = 13.0
var _bob_time: float = 0.0
var _breath_time: float = 0.0
var _base_scale := Vector2.ONE  # 玩家呼吸基准缩放（仅 auto_variant 修改 scale，避免与精英放大冲突）


func _ready() -> void:
	_parent_body = get_parent() as Node2D
	_base_scale = scale
	if auto_variant:
		_apply_character_variant()
		_bind_spell_cast()
	if sprite_frames:
		if sprite_frames.has_animation(idle_anim):
			play(idle_anim)
		elif sprite_frames.get_animation_names().size() > 0:
			play(sprite_frames.get_animation_names()[0])


## 玩家用：监听 SpellCaster.spell_cast → 播施法动画 + 法杖尖端元素闪光
func _bind_spell_cast() -> void:
	var sc := _parent_body.get_node_or_null("SpellCaster") if _parent_body else null
	if sc and not sc.spell_cast.is_connected(_on_spell_cast):
		sc.spell_cast.connect(_on_spell_cast)


func _on_spell_cast(spell, _slot_index = 0) -> void:
	# 有对应施法动画才播（旧 .tres 兼容）
	var has_cast := sprite_frames != null and (
		sprite_frames.has_animation(cast_anim)
		or sprite_frames.has_animation(cast_anim + "_front")
		or sprite_frames.has_animation(cast_anim + "_back"))
	if has_cast:
		_cast_timer = cast_duration
		_play_cast_variant()
	# 法杖尖端元素色闪光（纯视觉，复用 fx_lib 元素预设）
	if _staff_tip_flash:
		var element: String = str(spell.spell_element) if spell != null and "spell_element" in spell else "arcane"
		var side := -1.0 if flip_h else 1.0
		var tip := global_position + Vector2(24.0 * side, -26.0)
		FxLib.element_burst(self, tip, element, 0.45)


## 按最近纵向朝向播对应施法动画（缺失时回退侧视 cast）
func _play_cast_variant() -> void:
	var target := cast_anim + _last_vert
	if sprite_frames == null:
		return
	if not sprite_frames.has_animation(target):
		target = cast_anim
	if sprite_frames.has_animation(target):
		play(target)


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


func _physics_process(delta: float) -> void:
	if _parent_body == null or not is_instance_valid(_parent_body):
		return
	var v := Vector2.ZERO
	if _parent_body is CharacterBody2D:
		v = (_parent_body as CharacterBody2D).velocity
	elif "velocity" in _parent_body:
		v = _parent_body.velocity

	var moving := v.length_squared() > speed_threshold * speed_threshold
	var base := run_anim if moving else idle_anim

	# 2.5D 动效（在动画切换逻辑之前执行，施法分支的提前 return 也能带上）
	_update_motion_fx(delta, moving)

	# 施法计时：站立期间保持施法动画；一旦移动立即切回跑动
	if _cast_timer > 0.0:
		_cast_timer -= delta
		if not moving:
			# 施法中站立：保持施法动画，只更新镜像（与最近移动朝向一致）
			_apply_cast_flip()
			return
		_cast_timer = 0.0  # 移动打断施法动作 → 走正常切换

	var target := base

	# 竖直移动明显占优时改用朝向动画：向下=front（面向镜头）、向上=back
	if moving and absf(v.y) > 1.0 and absf(v.y) > absf(v.x) * 1.2:
		var vert := base + ("_front" if v.y > 0.0 else "_back")
		if sprite_frames and sprite_frames.has_animation(vert):
			target = vert
			_last_vert = "_front" if v.y > 0.0 else "_back"
	elif moving:
		_last_vert = ""

	if animation != target and sprite_frames and sprite_frames.has_animation(target):
		play(target)

	if target == base:
		# 侧视素材：默认朝右，向左移动时水平翻转
		if absf(v.x) > 1.0:
			flip_h = (v.x < 0.0) != base_flip_h
	else:
		# 正/背面视图不做左右镜像
		flip_h = base_flip_h


## 施法动画的镜像：跟随最近一次侧向移动方向
func _apply_cast_flip() -> void:
	if _last_vert != "":
		flip_h = base_flip_h
	# 侧视施法保持当前 flip_h（由最后一次移动决定）


## 2.5D 动效：跑动 sin 起伏（offset.y ±1.5px）+ 站立呼吸（scale 1.0→1.02，仅玩家）。
## 只动 sprite 的 offset/scale，不改父节点 position，物理零影响；
## 施法站定时起伏/呼吸平滑回正，保持施法姿势稳定。
func _update_motion_fx(delta: float, moving: bool) -> void:
	var casting_still := _cast_timer > 0.0 and not moving
	if moving:
		_bob_time += delta * bob_speed
		_breath_time = 0.0
		offset.y = sin(_bob_time) * bob_amplitude
		if auto_variant:
			scale = scale.lerp(_base_scale, minf(1.0, delta * 10.0))
	elif casting_still:
		# 施法中：起伏与呼吸都缓动归零（稳定施法姿势）
		_bob_time = 0.0
		offset.y = lerpf(offset.y, 0.0, minf(1.0, delta * 12.0))
		if auto_variant:
			scale = scale.lerp(_base_scale, minf(1.0, delta * 12.0))
	else:
		# 站立呼吸
		_bob_time = 0.0
		offset.y = lerpf(offset.y, 0.0, minf(1.0, delta * 10.0))
		if auto_variant:
			_breath_time += delta * 2.6
			var b := 1.0 + sin(_breath_time) * 0.01  # 1.0 → 1.02 波动
			scale = _base_scale * Vector2(b, b)
