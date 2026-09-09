shader_type canvas_item;

// 程序化星空 + 上升魔法光尘（用于深色秘法风菜单背景）

float star_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 px = UV * vec2(1920.0, 1080.0);
	vec2 cell = floor(px / 26.0);
	vec2 f = fract(px / 26.0);
	float h = star_hash(cell);
	float star = 0.0;
	if (h > 0.80) {
		vec2 sp = vec2(star_hash(cell + 0.7), star_hash(cell + 1.3));
		float tw = 0.5 + 0.5 * sin(TIME * (1.0 + h * 3.0) + h * 40.0);
		star = smoothstep(0.18, 0.0, distance(f, sp)) * tw;
	}
	vec2 muv = UV * vec2(960.0, 540.0);
	muv.y += TIME * 14.0;
	vec2 mcell = floor(muv / 90.0);
	vec2 mf = fract(muv / 90.0);
	float mh = star_hash(mcell + 5.0);
	float mote = 0.0;
	if (mh > 0.72) {
		vec2 mp = vec2(star_hash(mcell + 9.1), star_hash(mcell + 3.3));
		mote = smoothstep(0.12, 0.0, distance(mf, mp)) * (0.4 + 0.4 * sin(TIME * 2.0 + mh * 20.0));
	}
	vec3 star_col = vec3(1.0, 0.95, 0.8);
	vec3 mote_col = vec3(0.65, 0.5, 1.0);
	float a = clamp(star * 0.9 + mote * 0.85, 0.0, 1.0);
	COLOR = vec4(star_col * star + mote_col * mote, a);
}
