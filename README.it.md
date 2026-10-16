# ✨ Grimoire Echoes · 秘法回响

> **🔮 Lingue:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · Italiano · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## Italiano

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** è un action roguelite di tipo survivors, giocabile in singolo e in locale. Nei panni di un mago elementale, sopravvivi alle orde delle creature delle tenebre, costruisci build di incantesimi uniche grazie alla fusione elementale e lasciati travolgere da combattimenti frenetici in stile bullet heaven.

### 🎮 Gameplay principale

- **Lancio automatico + posizionamento manuale**: gli incantesimi equipaggiati si attivano da soli; tu pensi solo a schivare e a raccogliere il bottino
- **Sei elementi**: 🔥 Fuoco / ❄️ Ghiaccio / ⚡ Fulmine / 🌿 Natura / 💀 Ombra / ✨ Arcano
- **Fusione elementale**: equipaggia incantesimi di elementi diversi per sbloccare **15 incantesimi di fusione** (esplosione di vapore, fiamma oscura, tormenta…)
- **Progressione roguelite**: potenziamenti con tre scelte e gradi **Comune / Raro / Epico / Leggendario**, 12 potenziamenti in negozio e sistema di reliquie
- **Ondate di eventi**: forzieri del tesoro, altari maledetti (PV in cambio di potere) ed élite con taglia
- **Modalità Boss Rush**: una catena infinita di boss che diventano sempre più temibili
- **Tre maghi**: Piromante (danni a scoppio) / Idromante (controllo) / Evocatore di tempeste (velocità)

### 🕹️ Comandi

| Tasto | Azione |
|-------|--------|
| `WASD` | Muoversi |
| `Shift` | Schivata (frame di invincibilità) |
| `E` | Raccogliere / interagire |
| `C` | Pannello statistiche |
| `ESC` | Pausa / uscire dal negozio |
| `Tab` / `M` | Attivare la velocità di gioco |

### 🛠️ Come avviarlo

```bash
# Richiede Godot 4.7+ (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Apri project.godot nell'editor di Godot e premi F5
```

In alternativa puoi scaricare la build Windows già pronta dalla pagina delle Release: basta decomprimerla per giocare.

### 🧰 Punti di forza tecnici

- **Pipeline di rendering**: modelli ad alta definizione KayKit CC0 → suddivisione della mesh ×2 → ricostruzione delle normali smooth → illuminazione da studio a tre punti → render con supersampling a 512 px
- **Atmosfera**: illuminazione 2D dinamica, bagliore HDR, correzione del colore a schermo intero e particelle arcane generate in modo procedurale
- **Audio**: 22 effetti sonori interamente sintetizzati (sinusoidale / dente di sega / rumore + scivolamenti di tono + inviluppi)
- **Test**: 8 suite di test automatizzate (unit test / smoke test delle scene / tutti gli incantesimi / regressione delle funzionalità / stress / simulazione utente)

### 📄 Licenza

Codice e grafica sono rilasciati sotto licenza **CC0 (pubblico dominio)** — consulta il file [LICENSE](LICENSE).

---

*Altre lingue: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | Italiano | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
