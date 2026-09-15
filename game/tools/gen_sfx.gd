## gen_sfx.gd - 程序化合成全套音效 WAV（无需外部音频素材）
## 用法: godot --headless --path . -s res://tools/gen_sfx.gd
## 输出: res://assets/audio/sfx/*.wav（44.1kHz 16bit 单声道）
## 合成语法：正弦/锯齿/噪声 + 音高滑动 + 包络 + 序列拼接
extends SceneTree

const OUT := "res://assets/audio/sfx"
const RATE := 44100
var _rng := RandomNumberGenerator.new()

func _initialize() -> void:
	_rng.seed = 20260911
	DirAccess.make_dir_recursive_absolute(OUT)

	# ---- 射击（按元素）----
	_save("shoot_arcane", _tone(0.12, 700, 1400, 0.55, "sine", 0.008))
	_save("shoot_fire", _mix(_noise(0.16, 0.30, 6.0), _tone(0.16, 240, 90, 0.7, "saw", 0.004)))
	_save("shoot_water", _mix(_tone(0.15, 480, 940, 0.6, "sine", 0.01), _tone(0.15, 960, 1880, 0.18, "sine", 0.01)))
	_save("shoot_lightning", _crackle(0.14))
	_save("shoot_ice", _mix(_tone(0.13, 920, 1500, 0.55, "sine", 0.006), _noise(0.1, 0.12, 9.0)))
	_save("shoot_shadow", _mix(_tone(0.16, 320, 140, 0.65, "sine", 0.012), _tone(0.16, 160, 70, 0.4, "saw", 0.012)))

	# ---- 命中与死亡 ----
	_save("hit", _mix(_noise(0.05, 0.5, 14.0), _tone(0.05, 210, 120, 0.5, "sine", 0.001)))
	_save("enemy_die", _mix(_tone(0.28, 320, 70, 0.6, "saw", 0.004), _noise(0.22, 0.3, 5.0)))
	_save("player_hurt", _mix(_tone(0.2, 130, 60, 0.85, "sine", 0.002), _noise(0.14, 0.28, 7.0)))

	# ---- 拾取 ----
	_save("pickup_gem", _seq([_tone(0.06, 880, 880, 0.5, "sine", 0.004), _tone(0.09, 1318, 1318, 0.5, "sine", 0.004)]))
	_save("pickup_coin", _seq([_tone(0.05, 1568, 1568, 0.45, "square", 0.002), _tone(0.1, 2093, 2093, 0.4, "square", 0.002)]))
	_save("pickup_potion", _tone(0.18, 300, 520, 0.55, "sine", 0.01))
	_save("pickup_magnet", _tone(0.2, 420, 1250, 0.5, "sine", 0.008))

	# ---- 成长与 UI ----
	_save("level_up", _seq([
		_tone(0.09, 523, 523, 0.5, "sine", 0.004),
		_tone(0.09, 659, 659, 0.5, "sine", 0.004),
		_tone(0.09, 784, 784, 0.5, "sine", 0.004),
		_tone(0.22, 1047, 1047, 0.6, "sine", 0.004),
	]))
	_save("upgrade_select", _tone(0.12, 660, 990, 0.5, "sine", 0.004))
	_save("shop_buy", _mix(_seq([_tone(0.05, 1568, 1568, 0.4, "square", 0.002), _tone(0.08, 2093, 2093, 0.35, "square", 0.002)]), _tone(0.16, 180, 120, 0.4, "sine", 0.004)))
	_save("ui_click", _tone(0.035, 1900, 1500, 0.35, "sine", 0.001))

	# ---- 波次 / Boss / 事件 ----
	_save("wave_start", _seq([_tone(0.18, 196, 196, 0.5, "saw", 0.02), _tone(0.3, 262, 262, 0.55, "saw", 0.02)]))
	_save("boss_spawn", _mix(_vibrato(1.05, 66, 10, 0.8, "saw"), _noise(0.9, 0.22, 2.5)))
	_save("chest_open", _seq([
		_tone(0.06, 784, 784, 0.45, "sine", 0.003),
		_tone(0.06, 988, 988, 0.45, "sine", 0.003),
		_tone(0.06, 1175, 1175, 0.45, "sine", 0.003),
		_tone(0.16, 1568, 1568, 0.55, "sine", 0.003),
	]))
	_save("altar_deal", _mix(_tone(0.5, 220, 180, 0.45, "sine", 0.03), _tone(0.5, 262, 215, 0.35, "sine", 0.03)))
	_save("bounty_ping", _seq([_tone(0.08, 1200, 1200, 0.45, "sine", 0.003), _pause(0.06), _tone(0.1, 1200, 1200, 0.5, "sine", 0.003)]))

	print("[sfx] 合成完成 -> ", OUT)
	quit(0)

# ---------- 合成基元 ----------

## 音高滑动单音：f0→f1Hz，attack 为起音占时长比例，指数衰减
func _tone(dur: float, f0: float, f1: float, vol: float, wave: String = "sine", attack: float = 0.008) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var f := lerpf(f0, f1, k)
		phase += f / RATE
		var s := _wave_sample(wave, phase)
		var env := _env(k, attack)
		out[i] = s * vol * env
	return _normalize(out)

## 颤音低鸣（Boss 吼叫）
func _vibrato(dur: float, f: float, vib: float, vol: float, wave: String) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var ff := f + sin(t * TAU * 5.0) * vib
		phase += ff / RATE
		var env := _env(k, 0.05) * (1.0 - k * 0.25)
		out[i] = _wave_sample(wave, phase) * vol * env
	return _normalize(out)

## 噪声爆裂（decay 越大衰减越快）
func _noise(dur: float, vol: float, decay: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var k := float(i) / n
		lp = lerpf(lp, _rng.randf_range(-1, 1), 0.55)
		out[i] = lp * vol * pow(1.0 - k, decay)
	return _normalize(out)

## 电击碎裂声：三段递减噪声簇
func _crackle(dur: float) -> PackedFloat32Array:
	var seg := dur / 3.0
	return _mix3(_noise(seg, 0.55, 8.0), _offset(_noise(seg, 0.45, 8.0), seg), _offset(_noise(seg, 0.35, 8.0), seg * 2.0))

## 静音段
func _pause(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	return out

func _env(k: float, attack_frac: float) -> float:
	var a := clampf(k / maxf(attack_frac, 0.02), 0.0, 1.0)
	return a * pow(1.0 - k, 1.6)

func _wave_sample(wave: String, phase: float) -> float:
	var t := fmod(phase, 1.0)
	match wave:
		"saw":
			return t * 2.0 - 1.0
		"square":
			return 1.0 if t < 0.5 else -1.0
	return sin(t * TAU)

# ---------- 混音工具 ----------

func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var x := a[i] if i < a.size() else 0.0
		var y := b[i] if i < b.size() else 0.0
		out[i] = x + y
	return _normalize(out)

func _mix3(a: PackedFloat32Array, b: PackedFloat32Array, c: PackedFloat32Array) -> PackedFloat32Array:
	return _mix(_mix(a, b), c)

func _offset(a: PackedFloat32Array, dur: float) -> PackedFloat32Array:
	var head := _pause(dur)
	head.append_array(a)
	return head

func _seq(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return _normalize(out)

## 峰值归一化到 0.85，防爆音
func _normalize(a: PackedFloat32Array) -> PackedFloat32Array:
	var peak := 0.001
	for v in a:
		peak = maxf(peak, absf(v))
	var g := 0.85 / peak
	for i in a.size():
		a[i] = clampf(a[i] * g, -1.0, 1.0)
	return a

# ---------- 保存 ----------

func _save(sfx_name: String, pcm: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(pcm.size() * 2)
	for i in pcm.size():
		var v := int(clampf(pcm[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	var path := "%s/%s.wav" % [OUT, sfx_name]
	var err := wav.save_to_wav(path)
	if err != OK:
		print("[sfx] ✗ 保存失败 %s: %d" % [sfx_name, err])
	else:
		print("[sfx] ✓ %s (%.2fs)" % [sfx_name, float(pcm.size()) / RATE])
