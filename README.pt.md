# ✨ Grimoire Echoes · 秘法回响

> **🔮 Idiomas:** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · Português · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## Português

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** é um jogo de ação roguelite do tipo survivors, para um jogador e offline. Assuma o papel de um mago elemental, sobreviva às hordas de criaturas das trevas, monte combinações de feitiços únicas por meio da fusão elemental e encare um combate frenético no melhor estilo bullet heaven.

### 🎮 Jogabilidade principal

- **Conjuração automática + posicionamento manual**: os feitiços equipados disparam sozinhos; você foca em esquivar e em recolher os itens
- **Seis elementos**: 🔥 Fogo / ❄️ Gelo / ⚡ Raio / 🌿 Natureza / 💀 Sombra / ✨ Arcano
- **Fusão elemental**: equipe feitiços de elementos diferentes para desbloquear **15 feitiços de fusão** (explosão de vapor, chama negra, nevasca…)
- **Progressão roguelite**: melhorias com três opções de escolha e patamares **Comum / Raro / Épico / Lendário**, 12 melhorias na loja e sistema de relíquias
- **Ondas de eventos**: baús do tesouro, altares amaldiçoados (vida em troca de poder) e elites com recompensa
- **Modo Boss Rush**: uma sequência sem fim de chefes que ficam cada vez mais difíceis
- **Três magos**: Piromante (explosão) / Hidromante (controle) / Tempestário (velocidade)

### 🕹️ Controles

| Tecla | Ação |
|-------|------|
| `WASD` | Mover |
| `Shift` | Esquiva (frames de invencibilidade) |
| `E` | Pegar / interagir |
| `C` | Painel de atributos |
| `ESC` | Pausar / sair da loja |
| `Tab` / `M` | Alternar a velocidade do jogo |

### 🛠️ Como executar

```bash
# Requer Godot 4.7+ (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Abra o project.godot no editor do Godot e pressione F5
```

Ou baixe a build de Windows já pronta na página de Releases: basta descompactar e jogar.

### 🧰 Destaques técnicos

- **Pipeline de renderização**: modelos de alta fidelidade KayKit CC0 → subdivisão da malha ×2 → reconstrução de normais suaves → iluminação de estúdio de três pontos → render supersamplado em 512 px
- **Atmosfera**: iluminação 2D dinâmica, brilho HDR, correção de cor em tela cheia e partículas arcanas geradas proceduralmente
- **Áudio**: 22 efeitos sonoros totalmente sintetizados (seno / dente de serra / ruído + deslizes de tom + envelopes)
- **Testes**: 8 suítes de teste automatizadas (unitários / fumaça de cenas / todos os feitiços / regressão de funcionalidades / estresse / simulação de usuário)

### 📄 Licença

O código e a arte são publicados sob a licença **CC0 (domínio público)** — consulte o arquivo [LICENSE](LICENSE).

---

*Outros idiomas: [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Русский](README.ru.md) | Português | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
