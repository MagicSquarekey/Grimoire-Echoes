## RangedWeapon - 远程武器
## 远程武器的具体实现
class_name RangedWeapon
extends WeaponBase

## 远程属性
@export var projectile_scene: PackedScene  # 投射物场景
@export var projectile_speed: float = 400.0
@export var projectile_count: int = 1
@export var spread_angle: float = 10.0  # 散射角度

## 攻击逻辑
func _on_attack() -> void:
	# 生成投射物
	_fire_projectiles()
	
	# 调用父类攻击逻辑
	super._on_attack()

## 发射投射物
func _fire_projectiles() -> void:
	if projectile_scene == null:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	# 计算射击方向
	var direction = (player.global_position - global_position).normalized()
	
	for i in range(projectile_count):
		var projectile = projectile_scene.instantiate()
		if projectile:
			# 计算散射角度
			var angle_offset = 0.0
			if projectile_count > 1:
				angle_offset = (i - projectile_count / 2.0) * deg_to_rad(spread_angle)
			
			# 设置投射物方向
			var final_direction = direction.rotated(angle_offset)
			
			# 初始化投射物
			if projectile.has_method("setup"):
				projectile.setup(
					damage,
					projectile_speed,
					final_direction,
					"",
					0,
					knockback_force,
					1,
					get_parent()
				)
			
			# 设置位置
			projectile.global_position = global_position
			
			# 添加到场景
			get_tree().current_scene.add_child(projectile)
