shader_type canvas_item;

// 轻微上下浮动 + 呼吸明暗（用于立绘等装饰图）

uniform float bob_amount = 7.0;
uniform float bob_speed = 1.6;
uniform float glow_amount = 0.05;

void vertex() {
	VERTEX.y += sin(TIME * bob_speed) * bob_amount;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = c;
	COLOR.rgb *= 1.0 + glow_amount * sin(TIME * bob_speed * 1.25);
}
