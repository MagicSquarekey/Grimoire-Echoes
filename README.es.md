# ✨ Grimoire Echoes · 秘法回响

> **🔮 Idiomas:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · Español · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## Español

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** es un juego de acción roguelite de tipo survivors, para un jugador y en local. Ponte en la piel de un mago elemental, sobrevive a las hordas de criaturas de las sombras, construye combinaciones de hechizos únicas mediante la fusión elemental y disfruta de un combate frenético al más puro estilo bullet heaven.

### 🎮 Jugabilidad principal

- **Lanzamiento automático + posicionamiento manual**: los hechizos equipados se disparan solos; tú te centras en esquivar y recoger botín
- **Seis elementos**: 🔥 Fuego / ❄️ Hielo / ⚡ Rayo / 🌿 Naturaleza / 💀 Sombra / ✨ Arcano
- **Fusión elemental**: equipa hechizos de elementos distintos para desbloquear **15 hechizos de fusión** (explosión de vapor, llama oscura, ventisca…)
- **Progresión roguelite**: mejoras a elegir entre tres opciones con rangos **Común / Raro / Épico / Legendario**, 12 mejoras de tienda y sistema de reliquias
- **Oleadas de eventos**: cofres del tesoro, altares malditos (vida a cambio de poder) y élites con recompensa
- **Modo Boss Rush**: una cadena infinita de jefes que se vuelve más y más exigente
- **Tres magos**: Piromante (explosión) / Hidromante (control) / Llamatormentas (velocidad)

### 🕹️ Controles

| Tecla | Función |
|-------|---------|
| `WASD` | Moverse |
| `Shift` | Esquiva (frames de invulnerabilidad) |
| `E` | Recoger / interactuar |
| `C` | Panel de atributos |
| `ESC` | Pausa / salir de la tienda |
| `Tab` / `M` | Alternar la velocidad de juego |

### 🛠️ Cómo ejecutarlo

```bash
# Requiere Godot 4.7+ (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Abre project.godot en el editor de Godot y pulsa F5
```

O descarga la build de Windows ya compilada desde la página de Releases: se descomprime y se juega.

### 🧰 Aspectos técnicos destacados

- **Pipeline de renderizado**: modelos de alta fidelidad KayKit CC0 → subdivisión de malla ×2 → reconstrucción de normales suaves → iluminación de estudio de tres puntos → render supersampleado a 512 px
- **Atmósfera**: iluminación 2D dinámica, resplandor HDR, corrección de color a pantalla completa y motas arcanas procedurales
- **Audio**: 22 efectos de sonido íntegramente sintetizados (seno / diente de sierra / ruido + deslizamientos de tono + envolventes)
- **Pruebas**: 8 suites de test automatizadas (unitarias / humo de escenas / todos los hechizos / regresión de funciones / estrés / simulación de usuario)

### 📄 Licencia

El código y el arte se publican bajo licencia **CC0 (dominio público)** — consulta el archivo [LICENSE](LICENSE).

---

*Otros idiomas: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | Español | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
