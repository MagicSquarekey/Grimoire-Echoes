# ✨ 秘法回响 · Grimoire Echoes

> **🔮 语言 / Languages:** [English](README.en.md) · 简体中文 · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## 简体中文

![版本](https://img.shields.io/badge/version-v0.0.1-gold) ![引擎](https://img.shields.io/badge/Godot-4.7-blue) ![平台](https://img.shields.io/badge/platform-Windows-purple) ![许可证](https://img.shields.io/badge/license-CC0-green)

**秘法回响（Grimoire Echoes）** 是一款单人本地的类幸存者肉鸽动作游戏。扮演掌控元素魔法的巫师，在成群的黑暗生物中生存，通过元素融合创造独特的法术组合，体验爽快的弹幕割草。

### 🎮 核心玩法

- **自动施法 + 手动走位**：角色自动释放已装备的法术，你专注于走位与拾取
- **六元素体系**：🔥 火焰 / ❄️ 寒冰 / ⚡ 雷电 / 🌿 自然 / 💀 暗影 / ✨ 奥秘
- **元素融合**：收集不同元素的法术并装备，触发 **15 种融合法术**（蒸汽爆炸、暗焰爆弹、暴风雪……）
- **Roguelite 成长**：升级三选一（普通/稀有/史诗/传说品质）、12 种商店强化、遗物系统
- **局内事件波**：稀有宝箱、诅咒祭坛（以血换力）、悬赏精英
- **Boss 连战模式**：无尽 Boss 挑战，越战越强
- **三位法师**：火焰法师（爆发）/ 水流法师（控制）/ 雷电法师（极速）

### 🕹️ 操作

| 按键 | 功能 |
|------|------|
| `WASD` | 移动 |
| `Shift` | 闪避（无敌帧） |
| `E` | 拾取 / 互动 |
| `C` | 属性面板 |
| `ESC` | 暂停 / 离开商店 |
| `Tab`/`M` | 游戏速度切换 |

### 🛠️ 运行

```bash
# 需要 Godot 4.7+（https://godotengine.org/download）
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# 用 Godot 编辑器打开 project.godot，按 F5 运行
```

或下载发布页的 Windows 构建版本，解压即玩。

### 🧰 技术特性

- 渲染管线：KayKit CC0 高精度模型 → 网格细分 ×2 → 平滑法线重建 → 三点摄影棚灯光 → 512px 超采样渲染
- 氛围：动态 2D 光照、HDR 辉光、全屏调色、程序化秘法光尘
- 音频：全程序化合成的 22 个音效（正弦/锯齿/噪声 + 音高滑动 + 包络）
- 测试：8 套自动化测试（单元 / 场景冒烟 / 全量法术 / 功能回归 / 压力 / 用户模拟）

### 📄 许可证

代码与美术资源均基于 **CC0（公有领域）** 分发，详见 [LICENSE](LICENSE)。

---

***🔮 语言 / Languages:** [English](README.en.md) · 简体中文 · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)*
