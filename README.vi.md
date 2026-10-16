# ✨ Grimoire Echoes · 秘法回响

> **🔮 Ngôn ngữ:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · Tiếng Việt · [Türkçe](README.tr.md)

---

## Tiếng Việt

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** (秘法回响) là game hành động roguelite thể loại survivors, chơi đơn, hoàn toàn offline. Hóa thân thành pháp sư nguyên tố, sống sót qua đợt tấn công của đại quân sinh vật bóng tối, tự tay dựng nên bộ đòn phép độc nhất qua hệ thống dung hợp nguyên tố.

Game chạy trên Godot 4.7, phát hành cho Windows x64 và được phát hành dưới giấy phép CC0.

### 🎮 Lối chơi cốt lõi

- **Tự động thi pháp + di chuyển thủ công**: các phép thuật đã trang bị sẽ tự bắn — bạn chỉ việc lo né đòn và nhặt vật phẩm
- **Sáu nguyên tố**: 🔥 Hỏa / ❄️ Băng / ⚡ Lôi / 🌿 Thiên nhiên / 💀 Bóng tối / ✨ Bí thuật
- **Dung hợp nguyên tố**: trang bị phép thuật của các nguyên tố khác nhau để mở khóa **15 phép dung hợp** (Steam Explosion, Dark Flame Bomb, Blizzard…)
- **Tiến triển roguelite**: nâng cấp chọn 1 trong 3 với bậc **Common/Rare/Epic/Legendary**, 12 cường hóa trong cửa hàng, và các đợt sự kiện trong ván đấu
- **Đợt sự kiện**: rương báu hiếm, tế đàn bị nguyền rủa (đổi HP lấy sức mạnh), tinh anh treo thưởng
- **Chế độ Boss Rush**: chuỗi liên chiến boss liên tiếp không ngừng leo thang độ khó
- **Ba pháp sư**: Pyromancer (bùng nổ) / Hydromancer (khống chế) / Stormcaller (tốc độ)

### 🕹️ Điều khiển

| Phím | Chức năng |
|------|-----------|
| `WASD` | Di chuyển |
| `Shift` | Né đòn (i-frames) |
| `E` | Nhặt / tương tác |
| `C` | Bảng thuộc tính |
| `ESC` | Tạm dừng / thoát khỏi cửa hàng |
| `Tab` / `M` | Chuyển tốc độ game |

### 🛠️ Chạy game

```bash
# Cần Godot 4.7+ (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Mở project.godot trong editor Godot rồi nhấn F5
```

Hoặc tải bản dựng Windows dựng sẵn từ trang Releases — chỉ cần giải nén là chơi được.

### 🧰 Điểm nhấn kỹ thuật

- **Pipeline render**: mô hình KayKit CC0 chi tiết cao → phân chia lưới ×2 → tái tạo normal mượt → đèn studio ba điểm → render siêu lấy mẫu 512px
- **Không khí**: chiếu sáng 2D động, HDR glow, hiệu chỉnh màu toàn màn hình, hạt bụi bí thuật sinh theo thủ tục
- **Âm thanh**: 22 hiệu ứng âm thanh được tổng hợp hoàn toàn (sine/saw/noise + pitch slide + envelope)
- **Kiểm thử**: 8 bộ kiểm thử tự động (đơn vị / smoke scene / toàn bộ phép / hồi quy chức năng / stress / mô phỏng người dùng)

### 📄 Giấy phép

Mã nguồn và tài nguyên được phát hành dưới **CC0 (public domain)** — xem [LICENSE](LICENSE).

---

*Các ngôn ngữ khác: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | Tiếng Việt | [Türkçe](README.tr.md)*
