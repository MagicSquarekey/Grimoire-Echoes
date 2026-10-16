## StatsText - 属性面板文本构建（暂停菜单 / 局内属性面板共用）
class_name StatsText
extends Object

## 由玩家节点构建完整属性 + 法术清单（BBCode）
static func build(player: Node) -> String:
	if player == null or not is_instance_valid(player):
		return "[color=#a08fd8]暂无属性数据[/color]"
	var s = player.get_node_or_null("PlayerStats")
	if s == null:
		return "[color=#a08fd8]暂无属性数据[/color]"

	var lines: Array[String] = []
	lines.append("[color=#f0c969][b]◆ 当前属性[/b][/color]")
	lines.append("等级 [b]Lv.%d[/b]　　波次 [b]%d[/b]" % [s.current_level, WaveManager.current_wave])
	lines.append("生命 [b]%d / %d[/b]" % [int(s.current_health), int(s.get_max_health())])
	lines.append("攻击 [b]×%.2f[/b]　　元素伤害 [b]+%.0f%%[/b]" % [s.get_attack_multiplier(), s.element_damage_bonus * 100.0])
	lines.append("暴击 [b]%.0f%%[/b]（伤害 ×%.2f）" % [s.get_crit_rate() * 100.0, s.get_crit_damage()])
	lines.append("防御 [b]×%.2f[/b]　　冷却缩减 [b]%.0f%%[/b]" % [s.get_defense_multiplier(), s.cooldown_reduction * 100.0])
	lines.append("移速 [b]%.0f[/b]　　拾取范围 [b]+%.0f[/b]" % [s.get_move_speed(), s.magnet_bonus])
	if s.life_steal > 0.0:
		lines.append("生命偷取 [color=#9be08a][b]%.0f%%[/b][/color]" % (s.life_steal * 100.0))

	var sc = player.get_node_or_null("SpellCaster")
	if sc:
		lines.append("")
		lines.append("[color=#a08fd8][b]◆ 装备法术[/b][/color]")
		for spell in sc.spell_slots:
			if spell:
				lines.append("[color=#9be08a]%s Lv.%d[/color]　伤害 ×%.2f　冷却 %.2fs" % [
					spell.spell_name, spell.spell_level, spell.damage, spell.cooldown])
	return "\n".join(lines)
