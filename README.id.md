# ✨ Grimoire Echoes · 秘法回响

> **🔮 Bahasa:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · Bahasa Indonesia · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## Bahasa Indonesia

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** (秘法回响) adalah game aksi roguelite bergaya survivors yang dimainkan sendirian secara lokal. Berperan sebagai mage elemen, bertahan melawan gerombolan makhluk kegelapan, dan bangun gaya bermain spell yang unik lewat fusi elemen.

Game ini digerakkan oleh mesin Godot 4.7 dan dirilis untuk Windows x64 di bawah lisensi CC0.

### 🎮 Gameplay Inti

- **Auto-cast + pergerihan manual**: spell yang dipasang menembak otomatis — kamu fokus menghindar dan mengambil loot
- **Enam elemen**: 🔥 Api / ❄️ Es / ⚡ Petir / 🌿 Alam / 💀 Bayangan / ✨ Gaib
- **Fusi Elemen**: pasang spell dari elemen berbeda untuk membuka **15 fusion spells** (Steam Explosion, Dark Flame Bomb, Blizzard…)
- **Progresi roguelite**: upgrade pilih-satu-dari-tiga dengan tier **Common/Rare/Epic/Legendary**, 12 enhancement toko, dan gelombang event dalam run
- **Gelombang event**: peti harta langka, altar terkutuk (tukar HP dengan kekuatan), elite bounty
- **Mode Boss Rush**: rangkaian boss beruntun yang terus makin kuat
- **Tiga mage**: Pyromancer (burst) / Hydromancer (control) / Stormcaller (speed)

### 🕹️ Kontrol

| Tombol | Fungsi |
|--------|--------|
| `WASD` | Bergerak |
| `Shift` | Menghindar (i-frames) |
| `E` | Mengambil / berinteraksi |
| `C` | Panel statistik |
| `ESC` | Jeda / keluar dari toko |
| `Tab` / `M` | Pengalih kecepatan game |

### 🛠️ Menjalankan

```bash
# Membutuhkan Godot 4.7+ (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Buka project.godot di editor Godot lalu tekan F5
```

Atau unduh build Windows siap-pakai dari halaman Releases — cukup ekstrak lalu mainkan.

### 🧰 Sorotan Teknis

- **Pipeline render**: model KayKit CC0 detail-tinggi → subdivisi mesh ×2 → rekonstruksi normal halus → pencahayaan studio tiga titik → render supersampling 512px
- **Suasana**: pencahayaan 2D dinamis, HDR glow, color grading layar penuh, partikel debu gaib yang diproses secara prosedural
- **Audio**: 22 SFX sepenuhnya disintesis (sine/saw/noise + pitch slide + envelope)
- **Pengujian**: 8 suite tes otomatis (unit / smoke scene / seluruh spell / regresi fitur / stres / simulasi pengguna)

### 📄 Lisensi

Kode dan aset dirilis di bawah **CC0 (domain publik)** — lihat [LICENSE](LICENSE).

---

*Bahasa lain: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | Bahasa Indonesia | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
