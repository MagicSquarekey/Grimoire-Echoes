# ✨ 그림리어 에코즈 · 秘法回响

> **🔮 언어:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](#한국어)

---

## 한국어

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**그림리어 에코즈(秘法回响)** 는 싱글플레이 로컬 서바이벌 로그라이크 액션 게임입니다. 원소 마법을 다루는 마법사가 되어 어둠의 생물 무리를 상대로 살아남고, 원소 융합으로 고유한 스펠 빌드를 만들어 쾌감 있는 탄막 전투를 경험하세요.

### 🎮 핵심 게임플레이

- **자동 시전 + 수동 회피**: 장착한 스펠은 자동 발동 — 플레이어는 회피와 습득에 집중
- **6가지 원소**: 🔥 화염 / ❄️ 빙결 / ⚡ 번개 / 🌿 자연 / 💀 그림자 / ✨ 비술
- **원소 융합**: 다른 원소의 스펠을 장착하면 **15종의 융합 스펠** 해금 (증기 폭발, 다크 플레임, 블리자드…)
- **로그라이크 성장**: 3선택 업그레이드(일반/희귀/영웅/전설 품질), 12종 상점 강화, 렐릭 시스템
- **이벤트 웨이브**: 보물상자, 저주받은 제단(HP로 힘과 교환), 현상금 엘리트
- **보스 러시 모드**: 끝없이 강해지는 보스 연전
- **3인의 마법사**: 화염 마법사(폭발) / 물 마법사(제어) / 번개 마법사(속도)

### 🕹️ 조작법

| 키 | 동작 |
|----|------|
| `WASD` | 이동 |
| `Shift` | 회피(무적 프레임) |
| `E` | 획득 / 상호작용 |
| `C` | 속성 패널 |
| `ESC` | 일시정지 / 상점 나가기 |
| `Tab` / `M` | 게임 속도 전환 |

### 🛠️ 실행 방법

```bash
# Godot 4.7+ 필요 (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Godot 에디터에서 project.godot을 열고 F5
```

또는 Releases 페이지의 Windows 빌드를 다운로드해 압축 해제하면 바로 플레이 가능합니다.

### 🧰 기술적 특징

- **렌더링 파이프라인**: KayKit CC0 고정밀 모델 → 메시 세분화 ×2 → 스무스 법선 재구성 → 3점 스튜디오 조명 → 512px 슈퍼샘플링
- **연출**: 동적 2D 라이팅, HDR 글로우, 전체 화면 색보정, 절차적 비법 입자
- **오디오**: 22개 효과음을 모두 합성(사인/톱니/노이즈 + 피치 슬라이드 + 엔벨로프)
- **테스트**: 8개 자동화 테스트 스위트(유닛 / 씬 스모크 / 전체 스펠 / 기능 회귀 / 스트레스 / 유저 시뮬레이션)

### 📄 라이선스

코드와 아트는 **CC0(퍼블릭 도메인)** 으로 공개되었습니다. [LICENSE](LICENSE) 참조.

---

*[English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md)*
