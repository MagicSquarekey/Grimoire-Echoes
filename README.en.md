# ✨ Grimoire Echoes · 秘法回响

> **🔮 Languages:** [English](#english) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

---

## English

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** is a single-player, local survivors-like roguelite action game. Play as a elemental mage, survive against hordes of dark creatures, craft unique spell builds through elemental fusion, and enjoy frantic bullet-heaven combat.

### 🎮 Core Gameplay

- **Auto-cast + manual positioning**: your equipped spells fire automatically — you focus on dodging and looting
- **Six elements**: 🔥 Fire / ❄️ Ice / ⚡ Lightning / 🌿 Nature / 💀 Shadow / ✨ Arcane
- **Elemental Fusion**: equip spells of different elements to unlock **15 fusion spells** (Steam Explosion, Dark Flame, Blizzard…)
- **Roguelite progression**: 3-choice upgrades with **Common/Rare/Epic/Legendary** tiers, 12 shop enhancements, relic system
- **Event waves**: treasure chests, cursed altars (HP for power), bounty elites
- **Boss Rush mode**: endless boss gauntlet that scales forever
- **Three mages**: Pyromancer (burst) / Hydromancer (control) / Stormcaller (speed)

### 🕹️ Controls

| Key | Action |
|-----|--------|
| `WASD` | Move |
| `Shift` | Dodge (i-frames) |
| `E` | Pick up / interact |
| `C` | Stats panel |
| `ESC` | Pause / leave shop |
| `Tab` / `M` | Game speed toggle |

### 🛠️ Running

```bash
# Requires Godot 4.7+ (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Open project.godot in the Godot editor and press F5
```

Or download the prebuilt Windows package from the Releases page — unzip and play.

### 🧰 Technical Highlights

- **Render pipeline**: KayKit CC0 high-detail models → mesh subdivision ×2 → smooth normal reconstruction → three-point studio lighting → 512px supersampled render
- **Atmosphere**: dynamic 2D lighting, HDR glow, full-screen color grading, procedural arcane motes
- **Audio**: 22 fully synthesized SFX (sine/saw/noise + pitch slides + envelopes)
- **Testing**: 8 automated suites (unit / scene smoke / all-spells / feature regression / stress / user simulation)

### 📄 License

Code and art are released under **CC0 (public domain)** — see [LICENSE](LICENSE).

---

*[简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md)*
