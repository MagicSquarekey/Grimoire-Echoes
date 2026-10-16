# ✨ Grimoire-Echos · 秘法回响

> **🔮 Sprachen:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · Deutsch · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## Deutsch

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire-Echos** ist ein Einzelspieler-Actionspiel im Survivors-like-Roguelite-Stil, das komplett lokal läuft. Schlüpfe in die Rolle einer Elementarmagierin, überlebe gegen Horden dunkler Kreaturen, baue dir durch Elementarfusion einzigartige Zauber-Builds auf und erlebe rasante Bullet-Heaven-Kämpfe.

### 🎮 Kern-Gameplay

- **Automatisches Wirken + manuelle Bewegung**: Ausgerüstete Zauber werden automatisch ausgelöst — du konzentrierst dich aufs Ausweichen und Einsammeln
- **Sechs Elemente**: 🔥 Feuer / ❄️ Eis / ⚡ Blitz / 🌿 Natur / 💀 Schatten / ✨ Arkane Magie
- **Elementarfusion**: Zauber verschiedener Elemente ausrüsten, um **15 Fusionszauber** freizuschalten (Dampfexplosion, Dunkle Flamme, Schneesturm …)
- **Roguelite-Fortschritt**: Upgrade mit drei Wahlmöglichkeiten in den Stufen **Gewöhnlich / Selten / Episch / Legendär**, 12 Shop-Verbesserungen, Wellen zufälliger Ereignisse
- **Ereigniswellen**: Schatzkisten, verfluchte Altäre (Lebenspunkte gegen Stärke), Elite-Gegner mit Kopfgeld
- **Boss-Rush-Modus**: endlose Kette von Bosskämpfen, die immer weiter skaliert
- **Drei Magier**: Feuermagier (Explosionsschaden) / Wassermagier (Kontrolle) / Blitzmagier (Tempo)

### 🕹️ Steuerung

| Taste | Funktion |
|-------|----------|
| `WASD` | Bewegen |
| `Shift` | Ausweichen (Unverwundbarkeit) |
| `E` | Aufheben / Interagieren |
| `C` | Werte-Panel |
| `ESC` | Pause / Shop verlassen |
| `Tab` / `M` | Spielgeschwindigkeit umschalten |

### 🛠️ Starten

```bash
# Benötigt Godot 4.7+ (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# project.godot im Godot-Editor öffnen und F5 drücken
```

Oder lade den fertigen Windows-Build von der Releases-Seite herunter — einfach entpacken und losspielen.

### 🧰 Technische Besonderheiten

- **Render-Pipeline**: KayKit-CC0-Modelle mit hoher Detailtreue → Netzunterteilung ×2 → Rekonstruktion glatter Normalen → Dreipunkt-Studio-Beleuchtung → Supersampling-Render mit 512 px
- **Atmosphäre**: dynamische 2D-Beleuchtung, HDR-Glow, Vollbild-Farbkorrektur, prozedurale arkane Lichtpartikel
- **Audio**: 22 vollständig synthetisierte Soundeffekte (Sinus / Sägezahn / Rauschen + Tonhöhen-Gleiten + Hüllkurven)
- **Tests**: 8 automatisierte Test-Suites (Unit / Szenen-Smoke / alle Zauber / Funktions-Regression / Stresstest / Nutzersimulation)

### 📄 Lizenz

Code und Grafik stehen unter **CC0 (Gemeinfreiheit / Public Domain)** — siehe [LICENSE](LICENSE).

---

*Andere Sprachen: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | Deutsch | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
