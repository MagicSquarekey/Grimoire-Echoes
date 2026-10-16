# ✨ گرِمور ایکوز · 秘法回响

> **🔮 زبانیں:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · اردو · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## اردو

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**گرِمور ایکوز (Grimoire Echoes / 秘法回响)** ایک سنگل پلیئر، مقامی rogue-lite ایکشن گیم ہے جس کا انداز survivors-like ہے۔ عناصر کے جادو کو قابو کرنے والے جادوگر کا کردار ادا کریں، اندھیری مخلوق کے گروہوں کے خلاف زندہ رہیں، اور عنصری amalgamation کے ذریعے منفرد جادوئی ترکیبیں بنائیں۔

### 🎮 بنیادی گیم پلی

- **خودکار جادو + دستی حرکت**: آرڈر کی ہوئی جادو خودکار طور پر چلتی ہیں، آپ کو صرف بچاؤ اور اٹھانے پر توجہ دینی ہے
- **چھ عناصر**: 🔥 آگ / ❄️ برف / ⚡ بجلی / 🌿 قدرت / 💀 سایہ / ✨ اسرار
- **عنصری امتزاج**: مختلف عناصر کے جادو لگا کر **15 فیوژن جادو** فعال کریں (بخار دھماکہ، اندھیری شعلہ بم، برفانی طوفان…)
- **Roguelite ترقی**: تین میں سے ایک اپ گریڈ (عام / نایاب / حماسی / حالانکہ درجات)، دکان میں 12 اضافے، اور relic نظام
- **واقعہ کی لہریں**: نایاب خزانے، ملعون مذبح (خون کے بدلے طاقت)، اور انعامی elite
- **Boss Rush موڈ**: بے نهاية زعماء کا چیلنج جو ہر بار مشکل ہوتا جاتا ہے
- **تین جادوگر**: آتش جادوگر (دھماکہ) / آب جادوگر (قابو) / برقی جادوگر (تیز رفتار)

### 🕹️ کنٹرولز

| کلید | کام |
|------|-----|
| `WASD` | حرکت |
| `Shift` | بچاؤ (غیر قابل زخمی فریم) |
| `E` | اٹھانا / تعامل |
| `C` | خصوصیات پینل |
| `ESC` | وقفہ / دکان سے نکلنا |
| `Tab` / `M` | گیم کی رفتار تبدیل |

### 🛠️ چلانے کا طریقہ

```bash
# Godot 4.7+ درکار ہے (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Godot ایڈیٹر میں project.godot کھولیں اور F5 دبائیں
```

یا Releases صفحے سے تیار Windows بلڈ ڈاؤن لوڈ کریں، unzip کریں اور کھیلنا شروع کریں۔

### 🧰 تکنیکی خصوصیات

- **رینڈر پائپ لائن**: KayKit CC0 اعلیٰ تفصیلی ماڈل → میش سب ڈویژن ×2 → ہموار نارملز کی دوبارہ تعمیر → تین نقتہ اسٹوڈیو روشنی → 512px supersampled رینڈر
- **ماحول**: متحرک 2D روشنی، HDR glow، پوری اسکرین کا رنگنی، اور طریقہ کار سے پیدا ہونے والا جادوئی غبار
- **آواز**: 22 مکمل طور پر ترکیب دیے گئے SFX (sine/saw/noise + پچ سلائیڈ + لفافے)
- **ٹیسٹنگ**: 8 خودکار ٹیسٹ سوٹ (یونٹ / منظر دھواں / تمام جادو / خصوصیات ریگریشن / دباؤ / صارف کی نقل)

### 📄 لائسنس

کوڈ اور آرٹ دونوں **CC0 (عوامی ڈومین)** کے تحت جاری کیے گئے ہیں — تفصیل کے لیے [LICENSE](LICENSE) دیکھیں۔

---

*دیگر زبانیں: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | اردو | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
