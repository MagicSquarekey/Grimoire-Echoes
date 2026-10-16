# ✨ Grimoire Echoes · 秘法回响

> **🔮 भाषाएँ:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · हिन्दी · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## हिन्दी

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** (秘法回响) Godot 4.7 पर आधारित एक single-player, local survivors-like roguelite action game है। एक elemental mage की भूमिका में, dark creatures के झुंड से बचकर जीवित रहें, elemental fusion के ज़रिये अपनी अनोखी spell बनाएँ और तेज़ bullet-heaven combat का आनंद लें।

### 🎮 मूल गेमप्ले

- **स्वतः Casting + मैनुअल हलचल**: सज्जित spells स्वयं चलती हैं — आप केवल dodging और looting पर ध्यान केंद्रित करते हैं
- **छह तत्व**: 🔥 अग्नि / ❄️ बर्फ / ⚡ विद्युत / 🌿 प्रकृति / 💀 छाया / ✨ गूढ़
- **तत्वीय Fusion**: भिन्न तत्वों की spells सज्जित करके **15 fusion spells** अनलॉक करें (Steam Explosion, Dark Flame, Blizzard…)
- **Roguelite प्रगति**: तीन विकल्पों वाले upgrade, **Common/Rare/Epic/Legendary** tiers, 12 shop enhancements, relic system
- **Event waves**: treasure chests, cursed altars (HP बदले शक्ति), bounty elites
- **Boss Rush मोड**: लगातार मज़बूत होते Bosses की अनंत लड़ाई
- **तीन mages**: Pyromancer (burst) / Hydromancer (control) / Stormcaller (speed)

### 🕹️ नियन्त्रण

| कुंजी | क्रिया |
|-------|--------|
| `WASD` | चलना |
| `Shift` | Dodge (i-frames) |
| `E` | उठाना / संवाद |
| `C` | Stats panel |
| `ESC` | Pause / shop से बाहर निकलना |
| `Tab` / `M` | Game speed टगल |

### 🛠️ चलाने का तरीका

```bash
# Godot 4.7+ आवश्यक (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Godot editor में project.godot खोलें और F5 दबाएँ
```

या Releases page से पूर्वनिर्मित Windows package डाउनलोड करें — unzip करते ही खेलने योग्य।

### 🧰 कारीगरी विशेषताएँ

- **Render pipeline**: KayKit CC0 high-detail models → mesh subdivision ×2 → smooth normal reconstruction → three-point studio lighting → 512px supersampled render
- **माहौल**: dynamic 2D lighting, HDR glow, full-screen color grading, procedural arcane motes
- **ध्वनि**: 22 पूरी तरह synthesized SFX (sine/saw/noise + pitch slides + envelopes)
- **परीक्षण**: 8 automated suites (unit / scene smoke / all-spells / feature regression / stress / user simulation)

### 📄 लाइसेंस

कोड और कला **CC0 (public domain)** के अंतर्गत प्रकाशित हैं — [LICENSE](LICENSE) देखें।

---

*अन्य भाषाएँ: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | हिन्दी | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
