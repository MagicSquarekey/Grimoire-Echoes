## probe_wave.gd - 潮汐冲击视觉隔离探针（窗口模式）
## 用法: Godot --path game res://tools/probe_wave.tscn
extends Node

var t := 0.0
var stage := 0
var game: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.start_new_game("water_mage", "forest")
	game = load("res://scenes/main/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)
	_setup.call_deferred(game)


func _setup(g: Node) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(g):
		return
	get_tree().current_scene = g
	game = g


func _process(delta: float) -> void:
	t += delta
	if stage == 0 and t >= 1.0:
		stage = 1
		var p = get_tree().get_first_node_in_group("player")
		if p:
			p.spell_caster.cooldowns[1] = 0.0
			if p.spell_caster.spell_slots[1]:
				p.spell_caster.spell_slots[1].current_cooldown = 0.0
			# 朝正右方施放一次潮汐冲击（无敌人干扰）
			p.spell_caster.cast_spell(1, p.global_position + Vector2(300, 0))
			print("[probe] wave cast")
	elif stage == 1 and t >= 1.15:
		var img := get_viewport().get_texture().get_image()
		img.save_png("C:/Users/10359/Desktop/Grimoire-Echoes/temp_shots/probe_wave.png")
		print("[probe] saved probe_wave.png")
		get_tree().quit()
