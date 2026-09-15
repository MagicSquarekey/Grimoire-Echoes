## SpellRegistry - 法术中心注册表（id → 名称/元素/脚本/攻击方式描述）
## 供玩家开局装备、升级池随机、HUD 图标共用；纯数据，无逻辑。
class_name SpellRegistry
extends Object

## 全量已接入法术（script 必须能 .new() 独立运行；attack 用于升级卡描述攻击方式）
const SPELLS := {
	"magic_bolt": {
		"name": "奥术飞弹", "element": "arcane",
		"script": "res://scripts/spells/magic_bolt.gd",
		"attack": "自动朝最近敌人发射奥术飞弹",
	},
	"fireball": {
		"name": "火球术", "element": "fire",
		"script": "res://scripts/spells/fireball.gd",
		"attack": "发射火球撞击敌人，火焰爆炸并点燃",
	},
	"tidal_wave": {
		"name": "潮汐冲击", "element": "water",
		"script": "res://scripts/spells/tidal_wave.gd",
		"attack": "朝目标方向推出扇形水浪，伤害并击退敌人",
	},
	"chain_lightning": {
		"name": "连锁闪电", "element": "lightning",
		"script": "res://scripts/spells/chain_lightning.gd",
		"attack": "闪电命中敌人后在敌群间连续弹射",
	},
	"frost_nova": {
		"name": "寒冰新星", "element": "water",
		"script": "res://scripts/spells/frost_nova.gd",
		"attack": "以自身为中心爆发冰环，冻结周围敌人",
	},
	"meteor_strike": {
		"name": "陨石坠落", "element": "fire",
		"script": "res://scripts/spells/meteor_strike.gd",
		"attack": "标记目标区域，延迟后陨石砸落范围爆炸",
	},
	"pollen_bomb": {
		"name": "花粉炸弹", "element": "nature",
		"script": "res://scripts/spells/pollen_bomb.gd",
		"attack": "布下花粉云毒区，持续伤害并概率致盲敌人",
	},
	"shadow_bolt": {
		"name": "暗影弹", "element": "shadow",
		"script": "res://scripts/spells/shadow_bolt.gd",
		"attack": "发射高速暗影飞弹，命中诅咒敌人",
	},
	"thunderstorm": {
		"name": "雷暴领域", "element": "lightning",
		"script": "res://scripts/spells/thunderstorm.gd",
		"attack": "召唤雷暴领域，持续随机落雷劈打敌人",
	},
	"flame_wave": {
		"name": "烈焰波", "element": "fire",
		"script": "res://scripts/spells/flame_wave.gd",
		"attack": "朝目标方向喷出锥形火浪，点燃沿途敌人",
	},
	"ice_spike_array": {
		"name": "冰锥阵列", "element": "water",
		"script": "res://scripts/spells/ice_spike_array.gd",
		"attack": "目标区域升起冰锥阵列，持续伤害并减速",
	},
	"orbit_orbs": {
		"name": "环绕法书", "element": "arcane",
		"script": "res://scripts/spells/orbit_orbs.gd",
		"attack": "召唤奥术光球环绕自身旋转，接触敌人持续伤害",
	},
	"arcane_beam": {
		"name": "穿透光束", "element": "arcane",
		"script": "res://scripts/spells/arcane_beam.gd",
		"attack": "朝最近敌人瞬发直线穿透光束，命中线上所有敌人",
	},
}

## 角色开局签名法术（槽1；槽0 固定 magic_bolt）
const CHARACTER_STARTER := {
	"fire_mage": "fireball",
	"water_mage": "tidal_wave",
	"lightning_mage": "chain_lightning",
}

## 升级池「获得新法术」待选池（剔除已有后随机）
const UNLOCKABLE := [
	"frost_nova", "meteor_strike", "pollen_bomb", "shadow_bolt",
	"thunderstorm", "flame_wave", "ice_spike_array",
	"orbit_orbs", "arcane_beam",
]
