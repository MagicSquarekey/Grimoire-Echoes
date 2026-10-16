# ✨ Grimoire Echoes · 秘法回响

> **🔮 Diller:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · Türkçe

---

## Türkçe

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** (秘法回响), tek oyunculu ve yerel olarak oynanan, survivors tarzı bir roguelite aksiyon oyunudur. Elemental bir büyücü olarak karanlık yaratık sürülerine karşı hayatta kalın, element birleşimiyle kendine özgü büyü yapıları kurun ve tempolu bir mermi cenneti savaşının tadını çıkarın.

Oyun Godot 4.7 ile geliştirilmiştir; Windows x64 için yayınlanmıştır ve CC0 lisansı altındadır.

### 🎮 Temel Oynanış

- **Otomatik büyü + manevra**: kuşandığın büyüler kendiliğinden ateşlenir — sen kaçınmaya ve eşya toplamaya odaklanırsın
- **Altı element**: 🔥 Ateş / ❄️ Buz / ⚡ Yıldırım / 🌿 Doğa / 💀 Gölge / ✨ Gizem
- **Element Birleşimi**: farklı elementlerin büyülerini birlikte kuşanarak **15 birleşim büyüsünün** kilidini aç (Steam Explosion, Dark Flame Bomb, Blizzard…)
- **Roguelite ilerleyişi**: üç seçenekten birini alma yükseltmeler, **Common/Rare/Epic/Legendary** kademeleri, 12 dükkân güçlendirmesi ve tur içi olay dalgaları
- **Olay dalgaları**: nadir hazineler, lanetli sunaklar (güç karşılığında can), ödüllü elit düşmanlar
- **Boss Rush modu**: gittikçe zorlaşan, hiç bitmeyen patron savaşı serisi
- **Üç büyücü**: Pyromancer (patlama) / Hydromancer (kontrol) / Stormcaller (hız)

### 🕹️ Kontroller

| Tuş | İşlev |
|-----|-------|
| `WASD` | Hareket |
| `Shift` | Kaçınma (dokunulmazlık kareleri) |
| `E` | Toplama / etkileşim |
| `C` | Özellik paneli |
| `ESC` | Duraklat / dükkândan çık |
| `Tab` / `M` | Oyun hızı değiştirici |

### 🛠️ Çalıştırma

```bash
# Godot 4.7+ gerektirir (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# project.godot dosyasını Godot editöründe açıp F5'e basın
```

Ya da Releases sayfasından Windows için hazır yapıyı indirin — arşivi açmanız yeterli.

### 🧰 Teknik Öne Çıkanlar

- **Render boru hattı**: KayKit CC0 yüksek detaylı modeller → ağ alt bölünmesi ×2 → yumuşak normal yeniden oluşturma → üç noktalı stüdyo aydınlatması → 512px süper örneklemeli render
- **Atmosfer**: dinamik 2D aydınlatma, HDR parıltı, tam ekran renk düzenleme, prosedürel gizemli toz zerreleri
- **Ses**: tamamı sentezlenmiş 22 ses efekti (sine/saw/noise + perde kayması + zarf eğrileri)
- **Test**: 8 otomatik test paketi (birim / sahne duman testi / tüm büyüler / özellik regresyonu / stres / kullanıcı simülasyonu)

### 📄 Lisans

Kod ve görsel varlıklar **CC0 (kamu malı)** altında yayınlanmıştır — bkz. [LICENSE](LICENSE).

---

*Diğer diller: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | Türkçe*
