# ✨ Grimoire Echoes · 秘法回响

> **🔮 ভাষাসমূহ:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · বাংলা · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## বাংলা

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** (秘法回响) হলো Godot 4.7 চালিত একটি single-player, local survivors-like roguelite action game। একটি elemental mage হিসেবে খেলুন, dark creaturesের দলকে তিরে টিকে থাকুন, elemental fusion-এর মাধ্যমে নিজের অনন্য spell তৈরি করুন এবং দ্রুত bullet-heaven combat উপভোগ করুন।

### 🎮 মূল গেমপ্লে

- **স্বয়ংক্রিয় Casting + ম্যানুয়াল চলাচল**: সজ্জিত spell-গুলো নিজে নিজে ছোড়া হয় — আপনাকে কেবল dodging আর looting-এর উপর মনোযোগ দিতে হয়
- **ছয়টি উপাদান**: 🔥 অগ্নি / ❄️ বরফ / ⚡ বিদ্যুৎ / 🌿 প্রকৃতি / 💀 ছায়া / ✨ অদ্বৈত
- **উপাদানিক Fusion**: ভিন্ন উপাদানের spell সজ্জিত করে **১৫টি fusion spell** আনলক করুন (Steam Explosion, Dark Flame, Blizzard…)
- **Roguelite অগ্রগতি**: তিন বিকল্পের upgrade, **Common/Rare/Epic/Legendary** tier, ১২টি shop enhancement, relic system
- **Event wave**: treasure chest, cursed altar (HP বদলে শক্তি), bounty elite
- **Boss Rush মোড**: ক্রমাগত শক্তিশালী হওয়া boss-দের অসীম মেলা
- **তিনজন mage**: Pyromancer (burst) / Hydromancer (control) / Stormcaller (speed)

### 🕹️ নিয়ন্ত্রণ

| কী | কাজ |
|----|-----|
| `WASD` | চলাচল |
| `Shift` | Dodge (i-frames) |
| `E` | তোলা / যোগাযোগ |
| `C` | Stats panel |
| `ESC` | Pause / shop থেকে বেরোনো |
| `Tab` / `M` | Game speed টগল |

### 🛠️ চালানোর নিয়ম

```bash
# Godot 4.7+ প্রয়োজন (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Godot editor-এ project.godot খুলে F5 চাপুন
```

অথবা Releases page থেকে পূর্বনির্মিত Windows package ডাউনলোড করুন — unzip করলেই খেলা যাবে।

### 🧰 কারিগরি বৈশিষ্ট্য

- **Render pipeline**: KayKit CC0 high-detail model → mesh subdivision ×2 → smooth normal reconstruction → three-point studio lighting → 512px supersampled render
- **বায়ুমণ্ডল**: dynamic 2D lighting, HDR glow, full-screen color grading, procedural arcane mote
- **শব্দ**: ২২টি সম্পূর্ণ synthesized SFX (sine/saw/noise + pitch slide + envelope)
- **পরীক্ষা**: ৮টি automated suite (unit / scene smoke / all-spells / feature regression / stress / user simulation)

### 📄 লাইসেন্স

কোড ও শিল্পকর্ম **CC0 (public domain)**-এ প্রকাশিত — [LICENSE](LICENSE) দেখুন।

---

*অন্যান্য ভাষা: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | বাংলা | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
