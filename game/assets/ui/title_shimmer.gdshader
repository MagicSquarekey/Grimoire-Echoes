shader_type canvas_item;

// 标题流光：金色光带周期性扫过文字（SCREEN_UV 屏幕空间扫描）
// 注意：Godot 着色器注释只支持 //，不支持 #
uniform float speed : hint_range(0.05, 1.0) = 0.22;
uniform float band_width : hint_range(0.1, 0.6) = 0.32;
uniform vec3 shimmer_color : source_color = vec3(1.0, 0.88, 0.55);

void fragment() {
	// 字形图集是白色，金色来自顶点色（主题字体色），必须相乘保留
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	float band = fract(SCREEN_UV.x * 0.85 - TIME * speed);
	float shimmer = smoothstep(0.0, band_width * 0.5, band) * smoothstep(band_width, band_width * 0.5, band);
	vec4 c = tex;
	c.rgb = mix(c.rgb, shimmer_color, shimmer * 0.85 * tex.a);
	// 轻微提亮波峰
	c.rgb += shimmer * 0.12 * tex.a;
	COLOR = c;
}
