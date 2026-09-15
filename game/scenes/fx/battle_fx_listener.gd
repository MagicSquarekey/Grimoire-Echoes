## BattleFxListener - 战斗视觉监听（纯视觉节点，不改任何游戏逻辑）
## 挂在 game.tscn 根下（process_mode = ALWAYS），监听：
##  - EventBus.player_level_up  → 玩家脚下金色光环扩散 + 金色粒子喷发
##  - SpellCaster.spell_cast    → 玩家处元素色施法闪光（EventBus.spell_cast 目前无发射方，直连施放器信号）
##  - 玩家跑动                  → 脚下偶发小尘点（可选轻量特效）
## 所有闪光/光环使用预置复用节点 + Tween，无逐次分配，无泄漏。
extends Node2D

const GOLD := Color(1.0, 0.85, 0.3)
const DUST_INTERVAL := 0.26

var _player: Node2D
var _ring: Sprite2D
var _flash: Sprite2D
var _ring_tw: Tween
var _flash_tw: Tween
var _dust_cd: float = 0.0
var _find_tries: int = 0


func _ready() -> void:
	EventBus.player_level_up.connect(_on_level_up)
	# EventBus.spell_cast 当前无发射方，仍预留监听以兼容未来发射者
	EventBus.spell_cast.connect(_on_event_bus_spell_cast)
	_make_visuals.call_deferred()


## 预置复用视觉节点（只创建一次）
func _make_visuals() -> void:
	var glow_tex: Texture2D = load("res://assets/fx/glow_soft.png")
	var ring_tex: Texture2D = load("res://assets/fx/ring_glow.png")
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_flash = Sprite2D.new()
	_flash.texture = glow_tex
	_flash.material = mat
	_flash.visible = false
	_flash.z_index = 5
	add_child(_flash)

	_ring = Sprite2D.new()
	_ring.texture = ring_tex
	_ring.material = mat
	_ring.visible = false
	_ring.z_index = 5
	add_child(_ring)

	_find_player()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null and _find_tries < 5:
		_find_tries += 1
		_find_player.call_deferred()
		return
	if _player and is_instance_valid(_player):
		var sc := _player.get_node_or_null("SpellCaster")
		if sc and not sc.spell_cast.is_connected(_on_spell_cast):
			sc.spell_cast.connect(_on_spell_cast)


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_dust_cd -= delta
	if _dust_cd > 0.0 or _player == null or not is_instance_valid(_player):
		return
	# 跑动尘土：极轻量（3 粒/次，0.35s 消亡）
	if _player.velocity.length() > 40.0:
		_dust_cd = DUST_INTERVAL
		FxLib.hit_burst(self, _player.global_position + Vector2(0, 14),
				Color(0.62, 0.58, 0.5, 0.5), 3, 14.0, 34.0, 0.35, Vector2(0, -18))


## 施法闪光（SpellCaster.spell_cast(spell, slot_index)）
func _on_spell_cast(spell, _slot_index = 0) -> void:
	if _flash == null:
		return
	var element: String = spell.spell_element if spell != null and "spell_element" in spell else ""
	var pos := Vector2(960, 540)
	if _player and is_instance_valid(_player):
		pos = _player.global_position
	_flash_at(pos + Vector2(0, -12), FxLib.color_for(element))


## 兼容未来 EventBus.spell_cast(spell_data, caster) 的发射方
func _on_event_bus_spell_cast(spell_data, caster) -> void:
	if _flash == null:
		return
	var element: String = spell_data.spell_element if spell_data != null and "spell_element" in spell_data else ""
	var pos: Vector2 = caster.global_position if caster != null and is_instance_valid(caster) else Vector2(960, 540)
	_flash_at(pos + Vector2(0, -12), FxLib.color_for(element))


func _flash_at(pos: Vector2, col: Color) -> void:
	_flash.global_position = pos
	_flash.modulate = Color(col.r, col.g, col.b, 0.0)
	_flash.visible = true
	_flash.scale = Vector2(0.7, 0.7)
	if _flash_tw and _flash_tw.is_valid():
		_flash_tw.kill()
	_flash_tw = create_tween()
	_flash_tw.set_parallel(true)
	_flash_tw.tween_property(_flash, "scale", Vector2(1.5, 1.5), 0.2)
	_flash_tw.tween_property(_flash, "modulate:a", 0.85, 0.06)
	_flash_tw.chain().tween_property(_flash, "modulate:a", 0.0, 0.16)
	_flash_tw.chain().tween_callback(func(): _flash.visible = false)


## 升级特效：脚下金色光环扩散 + 金色粒子喷发
func _on_level_up(_level: int) -> void:
	if _ring == null:
		return
	var pos := Vector2(960, 540)
	if _player and is_instance_valid(_player):
		pos = _player.global_position
	_ring.global_position = pos + Vector2(0, 10)
	_ring.visible = true
	_ring.scale = Vector2(0.3, 0.3)
	_ring.modulate = Color(GOLD.r, GOLD.g, GOLD.b, 0.95)
	if _ring_tw and _ring_tw.is_valid():
		_ring_tw.kill()
	_ring_tw = create_tween()
	# 升级会暂停树（升级面板），光环用 PROCESS 模式确保能播完
	_ring_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_ring_tw.set_parallel(true)
	_ring_tw.tween_property(_ring, "scale", Vector2(2.4, 2.4), 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_ring_tw.tween_property(_ring, "modulate:a", 0.0, 0.6) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_ring_tw.chain().tween_callback(func(): _ring.visible = false)
	# 金色粒子喷发（挂在监听节点下，暂停期间也能播完）
	FxLib.hit_burst(self, pos + Vector2(0, 8), GOLD, 16, 60.0, 150.0, 0.5, Vector2(0, -140), self)
