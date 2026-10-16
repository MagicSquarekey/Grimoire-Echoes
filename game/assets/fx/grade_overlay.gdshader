// 全屏后处理调色：饱和度 / 对比度 / 柔和暗角（对下半所有画布生效）
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float saturation : hint_range(0.0, 2.0) = 1.16;
uniform float contrast : hint_range(0.5, 1.5) = 1.07;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.26;

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;
	// 饱和度
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, saturation);
	// 对比度
	col = clamp((col - 0.5) * contrast + 0.5, 0.0, 1.0);
	// 柔和暗角（微带紫调，融入秘法夜色）
	float d = distance(SCREEN_UV, vec2(0.5));
	float vig = smoothstep(0.45, 0.92, d) * vignette_strength;
	col = mix(col, col * vec3(0.72, 0.66, 0.92), vig);
	COLOR = vec4(col, 1.0);
}
