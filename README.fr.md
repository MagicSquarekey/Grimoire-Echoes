# ✨ Grimoire Echoes · 秘法回响

> **🔮 Langues :** [English](README.en.md) · [简体中文](README.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · Français · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Português](README.pt.md) · [Italiano](README.it.md) · [العربية](README.ar.md) · [اردو](README.ur.md) · [हिन्दी](README.hi.md) · [বাংলা](README.bn.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Türkçe](README.tr.md)

---

## Français

![version](https://img.shields.io/badge/version-v0.0.1-gold) ![engine](https://img.shields.io/badge/Godot-4.7-blue) ![platform](https://img.shields.io/badge/platform-Windows-purple) ![license](https://img.shields.io/badge/license-CC0-green)

**Grimoire Echoes** est un jeu d'action roguelite de type survivors, en solo et en local. Incarnez un mage élémentaire, survivez aux hordes de créatures des ténèbres, composez des builds de sorts uniques grâce à la fusion des éléments et plongez dans des combats frénétiques de type bullet heaven.

### 🎮 Gameplay principal

- **Incantation automatique + déplacement manuel** : vos sorts équipés se déclenchent tout seuls ; à vous de vous esquiver et de ramasser le butin
- **Six éléments** : 🔥 Feu / ❄️ Glace / ⚡ Foudre / 🌿 Nature / 💀 Ombre / ✨ Arcan
- **Fusion élémentaire** : équipez des sorts d'éléments différents pour déverrouiller **15 sorts de fusion** (explosion de vapeur, flamme noire, blizzard…)
- **Progression roguelite** : améliorations à choix triple avec les rangs **Commun / Rare / Épique / Légendaire**, 12 améliorations en boutique et un système de reliques
- **Vagues d'événements** : coffres au trésor, autels maudits (des PV contre du pouvoir) et élites à prime
- **Mode Boss Rush** : un enchaînement sans fin de boss qui ne cessent de gagner en puissance
- **Trois mages** : Pyromancien (dégâts explosifs) / Hydromancien (contrôle) / Conjurateur d'orages (vitesse)

### 🕹️ Commandes

| Touche | Action |
|--------|--------|
| `WASD` | Se déplacer |
| `Shift` | Esquive (frames d'invincibilité) |
| `E` | Ramasser / interagir |
| `C` | Panneau des statistiques |
| `ESC` | Pause / quitter la boutique |
| `Tab` / `M` | Alterner la vitesse de jeu |

### 🛠️ Lancer le jeu

```bash
# Nécessite Godot 4.7+ (https://godotengine.org/download)
git clone https://github.com/MagicSquarekey/Grimoire-Echoes.git
cd Grimoire-Echoes/game
# Ouvrez project.godot dans l'éditeur Godot et appuyez sur F5
```

Vous pouvez aussi télécharger la build Windows prête à l'emploi sur la page Releases : il suffit de la décompresser pour jouer.

### 🧰 Points forts techniques

- **Pipeline de rendu** : modèles haute résolution KayKit CC0 → subdivision du maillage ×2 → reconstruction des normales lisses → éclairage studio trois points → rendu suréchantillonné à 512 px
- **Ambiance** : éclairage 2D dynamique, halo HDR, étalonnage couleur plein écran et particules arcanes générées de façon procédurale
- **Audio** : 22 effets sonores entièrement synthétisés (sinus / dents de scie / bruit + glissements de hauteur + enveloppes)
- **Tests** : 8 suites automatisées (tests unitaires / fumée de scènes / tous les sorts / régression fonctionnelle / stress / simulation d'utilisateur)

### 📄 Licence

Le code et les ressources graphiques sont publiés sous licence **CC0 (domaine public)** — voir le fichier [LICENSE](LICENSE).

---

*Autres langues : [English](README.en.md) | [简体中文](README.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | Français | [Deutsch](README.de.md) | [Русский](README.ru.md) | [Português](README.pt.md) | [Italiano](README.it.md) | [العربية](README.ar.md) | [اردو](README.ur.md) | [हिन्दी](README.hi.md) | [বাংলা](README.bn.md) | [Bahasa Indonesia](README.id.md) | [Tiếng Việt](README.vi.md) | [Türkçe](README.tr.md)*
