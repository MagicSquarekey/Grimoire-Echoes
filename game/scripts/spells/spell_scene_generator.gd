## SpellSceneGenerator - 法术场景生成器
## 为每个法术生成对应的.tscn场景文件
class_name SpellSceneGenerator
extends RefCounted

## 法术场景数据
class SpellSceneData:
    var spell_name: String
    var script_path: String
    var scene_path: String
    var node_type: String  # "Node2D" or "Area2D"
    var collision_radius: float
    var visual_scale: Vector2
    var visual_color: Color
    var lifetime: float
    
    func _init(
        _spell_name: String,
        _script_path: String,
        _scene_path: String,
        _node_type: String = "Node2D",
        _collision_radius: float = 20.0,
        _visual_scale: Vector2 = Vector2(1, 1),
        _visual_color: Color = Color.WHITE,
        _lifetime: float = 3.0
    ) -> void:
        spell_name = _spell_name
        script_path = _script_path
        scene_path = _scene_path
        node_type = _node_type
        collision_radius = _collision_radius
        visual_scale = _visual_scale
        visual_color = _visual_color
        lifetime = _lifetime

## 法术场景数据表
const SPELL_SCENE_DATA: Array[SpellSceneData] = [
    # 火焰系
    SpellSceneData.new(
        "FlameWave", "res://scripts/spells/flame_wave.gd", "res://scenes/spells/flame_wave.tscn",
        "Node2D", 200.0, Vector2(2, 1), Color(1, 0.5, 0, 1), 2.5
    ),
    SpellSceneData.new(
        "MeteorStrike", "res://scripts/spells/meteor_strike.gd", "res://scenes/spells/meteor_strike.tscn",
        "Node2D", 100.0, Vector2(3, 3), Color(1, 0.5, 0, 1), 8.0
    ),
    SpellSceneData.new(
        "FireShield", "res://scripts/spells/fire_shield.gd", "res://scenes/spells/fire_shield.tscn",
        "Node2D", 80.0, Vector2(1.5, 1.5), Color(1, 0.3, 0, 1), 5.0
    ),
    SpellSceneData.new(
        "FireMark", "res://scripts/spells/fire_mark.gd", "res://scenes/spells/fire_mark.tscn",
        "Node2D", 250.0, Vector2(0.5, 0.5), Color(1, 0.2, 0, 1), 6.0
    ),
    
    # 水流系
    SpellSceneData.new(
        "IceSpikeArray", "res://scripts/spells/ice_spike_array.gd", "res://scenes/spells/ice_spike_array.tscn",
        "Node2D", 150.0, Vector2(2, 2), Color(0.7, 0.9, 1, 1), 3.0
    ),
    SpellSceneData.new(
        "WaterShield", "res://scripts/spells/water_shield.gd", "res://scenes/spells/water_shield.tscn",
        "Node2D", 100.0, Vector2(1.5, 1.5), Color(0.3, 0.5, 1, 1), 6.0
    ),
    SpellSceneData.new(
        "TidalWave", "res://scripts/spells/tidal_wave.gd", "res://scenes/spells/tidal_wave.tscn",
        "Node2D", 250.0, Vector2(2, 1), Color(0.3, 0.7, 1, 1), 3.0
    ),
    
    # 雷电系
    SpellSceneData.new(
        "LightningBolt", "res://scripts/spells/lightning_bolt.gd", "res://scenes/spells/lightning_bolt.tscn",
        "Area2D", 20.0, Vector2(1, 0.1), Color(1, 1, 0.5, 1), 1.0
    ),
    SpellSceneData.new(
        "Thunderstorm", "res://scripts/spells/thunderstorm.gd", "res://scenes/spells/thunderstorm.tscn",
        "Node2D", 120.0, Vector2(2, 2), Color(1, 1, 0, 1), 4.0
    ),
    SpellSceneData.new(
        "ChainLightning", "res://scripts/spells/chain_lightning.gd", "res://scenes/spells/chain_lightning.tscn",
        "Node2D", 200.0, Vector2(1, 0.1), Color(1, 1, 0.5, 1), 4.0
    ),
    SpellSceneData.new(
        "StaticField", "res://scripts/spells/static_field.gd", "res://scenes/spells/static_field.tscn",
        "Node2D", 100.0, Vector2(2, 2), Color(1, 1, 0, 1), 0.0
    ),
    SpellSceneData.new(
        "ThunderStrike", "res://scripts/spells/thunder_strike.gd", "res://scenes/spells/thunder_strike.tscn",
        "Node2D", 300.0, Vector2(1, 0.2), Color(1, 1, 0.5, 1), 6.0
    ),
    
    # 自然系
    SpellSceneData.new(
        "VineEntangle", "res://scripts/spells/vine_entangle.gd", "res://scenes/spells/vine_entangle.tscn",
        "Node2D", 200.0, Vector2(2, 0.5), Color(0.2, 0.8, 0.2, 1), 3.0
    ),
    SpellSceneData.new(
        "HealingWind", "res://scripts/spells/healing_wind.gd", "res://scenes/spells/healing_wind.tscn",
        "Node2D", 100.0, Vector2(1.5, 1.5), Color(0.3, 1, 0.3, 1), 4.0
    ),
    SpellSceneData.new(
        "PollenBomb", "res://scripts/spells/pollen_bomb.gd", "res://scenes/spells/pollen_bomb.tscn",
        "Node2D", 100.0, Vector2(2, 2), Color(0.8, 0.9, 0.2, 1), 5.0
    ),
    SpellSceneData.new(
        "VineGuard", "res://scripts/spells/vine_guard.gd", "res://scenes/spells/vine_guard.tscn",
        "Node2D", 30.0, Vector2(1, 1), Color(0.2, 0.8, 0.2, 1), 15.0
    ),
    SpellSceneData.new(
        "ThornArmor", "res://scripts/spells/thorn_armor.gd", "res://scenes/spells/thorn_armor.tscn",
        "Node2D", 100.0, Vector2(1.5, 1.5), Color(0.4, 0.8, 0.2, 1), 6.0
    ),
    
    # 暗影系
    SpellSceneData.new(
        "ShadowBolt", "res://scripts/spells/shadow_bolt.gd", "res://scenes/spells/shadow_bolt.tscn",
        "Area2D", 15.0, Vector2(1, 1), Color(0.3, 0, 0.5, 1), 1.5
    ),
    SpellSceneData.new(
        "ShadowTouch", "res://scripts/spells/shadow_touch.gd", "res://scenes/spells/shadow_touch.tscn",
        "Node2D", 150.0, Vector2(2, 1), Color(0.3, 0, 0.5, 1), 3.0
    ),
    SpellSceneData.new(
        "LifeSiphon", "res://scripts/spells/life_siphon.gd", "res://scenes/spells/life_siphon.tscn",
        "Node2D", 150.0, Vector2(2, 2), Color(0.5, 0, 0.5, 1), 1.0
    ),
    SpellSceneData.new(
        "CurseMark", "res://scripts/spells/curse_mark.gd", "res://scenes/spells/curse_mark.tscn",
        "Node2D", 250.0, Vector2(0.5, 0.5), Color(0.3, 0, 0.5, 1), 6.0
    ),
    SpellSceneData.new(
        "ShadowClone", "res://scripts/spells/shadow_clone.gd", "res://scenes/spells/shadow_clone.tscn",
        "Node2D", 25.0, Vector2(1, 1), Color(0.2, 0, 0.3, 1), 12.0
    ),
    
    # 风暴系
    SpellSceneData.new(
        "WindBlade", "res://scripts/spells/wind_blade.gd", "res://scenes/spells/wind_blade.tscn",
        "Area2D", 15.0, Vector2(1, 0.1), Color(0.8, 0.9, 1, 1), 0.6
    ),
    SpellSceneData.new(
        "Tornado", "res://scripts/spells/tornado.gd", "res://scenes/spells/tornado.tscn",
        "Node2D", 120.0, Vector2(2, 2), Color(0.8, 0.9, 1, 1), 3.0
    ),
    SpellSceneData.new(
        "Dash", "res://scripts/spells/dash.gd", "res://scenes/spells/dash.tscn",
        "Node2D", 50.0, Vector2(2, 0.5), Color(0.8, 0.9, 1, 1), 4.0
    ),
    SpellSceneData.new(
        "WindWall", "res://scripts/spells/wind_wall.gd", "res://scenes/spells/wind_wall.tscn",
        "Node2D", 150.0, Vector2(3, 2), Color(0.8, 0.9, 1, 1), 5.0
    ),
    SpellSceneData.new(
        "CycloneBlast", "res://scripts/spells/cyclone_blast.gd", "res://scenes/spells/cyclone_blast.tscn",
        "Node2D", 150.0, Vector2(2, 2), Color(0.8, 0.9, 1, 1), 6.0
    )
]

## 生成法术场景文件
static func generate_spell_scene(spell_data: SpellSceneData) -> bool:
    var scene_content = _create_scene_content(spell_data)
    
    # 写入文件
    var file = FileAccess.open(spell_data.scene_path, FileAccess.WRITE)
    if file == null:
        push_error("无法创建场景文件: " + spell_data.scene_path)
        return false
    
    file.store_string(scene_content)
    file.close()
    
    return true

## 创建场景内容
static func _create_scene_content(spell_data: SpellSceneData) -> String:
    var content = "[gd_scene load_steps=4 format=3 uid=\"uid://%s_scene\"]\n\n" % spell_data.spell_name.to_lower()
    
    # 外部资源
    content += "[ext_resource type=\"Script\" path=\"%s\" id=\"1\"]\n\n" % spell_data.script_path
    
    # 子资源：碰撞形状
    content += "[sub_resource type=\"CircleShape2D\" id=\"CircleShape2D_%s\"]\n" % spell_data.spell_name.to_lower()
    content += "radius = %.1f\n\n" % spell_data.collision_radius
    
    # 子资源：生命周期计时器
    content += "[sub_resource type=\"CircleShape2D\" id=\"CircleShape2D_lifetime\"]\n"
    content += "wait_time = %.1f\n" % spell_data.lifetime
    content += "one_shot = true\n\n"
    
    # 主节点
    content += "[node name=\"%s\" type=\"%s\"]\n" % [spell_data.spell_name, spell_data.node_type]
    content += "script = ExtResource(\"1\")\n\n"
    
    # 视觉节点
    content += "[node name=\"Sprite2D\" type=\"Sprite2D\" parent=\".\"]\n"
    content += "modulate = Color(%.1f, %.1f, %.1f, %.1f)\n" % [
        spell_data.visual_color.r,
        spell_data.visual_color.g,
        spell_data.visual_color.b,
        spell_data.visual_color.a
    ]
    content += "scale = Vector2(%.1f, %.1f)\n\n" % [spell_data.visual_scale.x, spell_data.visual_scale.y]
    
    # 碰撞形状节点
    content += "[node name=\"CollisionShape2D\" type=\"CollisionShape2D\" parent=\".\"]\n"
    content += "shape = SubResource(\"CircleShape2D_%s\")\n\n" % spell_data.spell_name.to_lower()
    
    # 生命周期计时器节点
    content += "[node name=\"LifetimeTimer\" type=\"Timer\" parent=\".\"]\n"
    content += "wait_time = %.1f\n" % spell_data.lifetime
    content += "one_shot = true\n"
    content += "autostart = true\n"
    
    return content

## 生成所有法术场景文件
static func generate_all_spell_scenes() -> Dictionary:
    var results = {}
    
    for spell_data in SPELL_SCENE_DATA:
        var success = generate_spell_scene(spell_data)
        results[spell_data.spell_name] = success
    
    return results

## 获取法术场景数据
static func get_spell_scene_data(spell_name: String) -> SpellSceneData:
    for data in SPELL_SCENE_DATA:
        if data.spell_name == spell_name:
            return data
    return null

## 获取所有法术场景数据
static func get_all_spell_scene_data() -> Array[SpellSceneData]:
    return SPELL_SCENE_DATA