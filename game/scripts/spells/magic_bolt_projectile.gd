## MagicBoltProjectile - 奥术飞弹投射物
## 玩家初始攻击手段：自动索敌发射的魔法弹
extends Area2D

## 飞行参数
var direction = Vector2.RIGHT
var speed = 520.0
var damage = 12.0
var lifetime = 1.2
var caster = null

func _ready() -> void:
	# 碰撞设置：只检测敌人层
	collision_layer = 0
	collision_mask = 2
	
	# 视觉：青色菱形弹体 + 淡色拖尾
	var trail = Polygon2D.new()
	trail.polygon = PackedVector2Array([
		Vector2(-4, -2), Vector2(-18, 0), Vector2(-4, 2)
	])
	trail.color = Color(0.4, 0.9, 1.0, 0.35)
	add_child(trail)
	
	var body_visual = Polygon2D.new()
	body_visual.polygon = PackedVector2Array([
		Vector2(-5, -3), Vector2(5, -3), Vector2(8, 0), Vector2(5, 3), Vector2(-5, 3)
	])
	body_visual.color = Color(0.5, 0.95, 1.0)
	add_child(body_visual)
	
	var core = Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(-2, -1.5), Vector2(2, -1.5), Vector2(2, 1.5), Vector2(-2, 1.5)
	])
	core.color = Color(1, 1, 1, 0.9)
	add_child(core)
	
	# 碰撞形状
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)
	
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body) -> void:
	if body and is_instance_valid(body):
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			var attacker = caster if (caster and is_instance_valid(caster)) else null
			body.take_damage(damage, attacker)
			queue_free()
