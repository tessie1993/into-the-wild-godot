# Asset pipeline — free and open-source tools

> Researched 2026-08-28. Everything here is free; the licence column says what you
> actually get. **Into the Wild ships on cardboard first**, so card/tile layout tools
> matter more than 3D or engine assets — the digital build reuses the same art.

## 1. Card and tile layout — the part that actually blocks print-and-play

This is the pipeline that turns `canon/*.json` into printable cards. Because the
design already lives as structured data, a **data-driven** tool is worth far more
here than a GUI one: change a Fight number in canon, re-render the deck.

| Tool | What it is | Licence | Fit for us |
|---|---|---|---|
| [**Squib**](http://squib.rocks/) ([repo](https://github.com/andymeneely/squib)) | Ruby DSL for prototyping card games — define stats, compile to print-and-play or print-on-demand images | MIT, open source | **Best fit.** Reads CSV/data, renders decks programmatically. Exports straight to Tabletop Simulator sheets. Pairs directly with `canon/*.json`. |
| [**nanDECK**](http://www.nand.it/nandeck/) | Windows scripting language for deck design, free since 2006, no limitations | Freeware (not OSS) | The genre standard. Huge feature set, spreadsheet-driven, but Windows-only and closed. Good fallback if Ruby is a barrier. |
| [**cards.py**](https://github.com/jhauberg/cards.py) | Python, generates print-and-play cards from a CSV | MIT | Lightest option. Python is already in this repo — no new runtime. |
| [**Deckard**](https://github.com/jonagill/Deckard) | Unity-based card layout tool | Open source | Only worth it if the digital build lands in Unity. |

**Recommendation:** `cards.py` for a first paper prototype (no new toolchain — this
repo is already Python), then Squib if the deck outgrows it. Both consume the CSV a
small exporter can produce from `canon/`.

## 2. Ready-made art — CC0, no attribution, commercially safe

| Source | Contents | Licence |
|---|---|---|
| [**Kenney**](https://kenney.nl) | 40,000+ assets — sprites, tilesets, UI packs. Consistent style across packs, so they mix without looking like a ransom note | CC0 |
| [**game-icons.net**](https://game-icons.net) | 4,000+ SVG game icons — weapons, potions, spells, status effects, inventory | CC0 / CC-BY |
| [**OpenGameArt**](https://opengameart.org/content/cc0-resources) | Decade-old library of 2D art, 3D models, music, SFX | CC0 / CC-BY / GPL — **check per asset** |
| [**itch.io CC0 assets**](https://itch.io/game-assets/assets-cc0/tag-vector) | Community packs; Pixel Frog and Ansimuz release complete animated sets | CC0 |

**game-icons.net is the immediate win.** Into the Wild needs a large icon vocabulary —
6 elements, 4 tiers, Duality states, Rage, Energy, 6 actions, creature Demand/Love/
Distrust markers — and this is exactly that, as SVG, free of attribution.

## 3. AI generation — open weights, run locally

Relevant for creature and tile illustration where consistency across ~100 cards matters.

| Model | Why | Notes |
|---|---|---|
| **FLUX.1 Kontext [dev]** | Iterative character design with visual consistency — the named top pick for game asset creation in 2026 | Open weights. Consistency is the hard problem for a 100-card creature deck |
| **FLUX.2** | Frontier-quality — realistic texture, stable lighting, coherent composition | Heaviest VRAM demand |
| **Stable Diffusion 3.5 Large** | Deepest ecosystem — thousands of LoRAs and fine-tunes from years of community work | Best if you want to train a LoRA on one house style |
| **Sana** | Runs on an 8GB GPU | The low-VRAM option |
| **Qwen-Image**, **HunyuanImage 3.0** | Also open-weight contenders | |

[**ComfyUI**](https://github.com/comfyanonymous/ComfyUI) — node-based interface for
building the generation pipeline visually. The right harness for "same style, 100
different creatures": build the graph once, vary the prompt.

**Hugging Face** hosts all of these plus datasets and Spaces — see connector note below.

## 4. Editing and vector

| Tool | Use | Licence |
|---|---|---|
| **Krita** | Digital painting, best-in-class free brush engine | GPL |
| **Inkscape** | Vector — hex tiles, icons, card frames, anything that must scale to print DPI | GPL |
| **GIMP** | Raster editing, batch processing | GPL |
| **Blender** | 3D — only if the digital build needs it; also useful for rendering isometric tile art | GPL |

## 5. Print specs to respect from the start

Re-rendering 100 cards because the bleed was wrong is the classic cost here.

- **300 DPI minimum** for anything going to a printer.
- **3mm bleed** on every edge, with a matching safe margin inside the cut line.
- **CMYK** for print-on-demand; RGB stays fine for Tabletop Simulator and the digital build.
- Standard poker card: 63×88mm. Hex tiles: pick one size early and never change it.
- Colour-blind safety is a **design** constraint, not a cosmetic one — the 6 elements
  are colour-coded (green/gold/red/blue/purple/white) and Duality is a red-to-white
  axis. Never let colour be the only carrier of information; every element needs a
  distinct icon and shape too.

---

## Sources

- [Three Waves of Card Game Design Tools](https://bennycheung.github.io/three-waves-of-card-game-design-tools)
- [Squib](http://squib.rocks/) · [Squib repo](https://github.com/andymeneely/squib)
- [nanDECK](http://www.nand.it/nandeck/)
- [cards.py](https://github.com/jhauberg/cards.py)
- [Deckard](https://github.com/jonagill/Deckard)
- [OpenGameArt CC0 resources](https://opengameart.org/content/cc0-resources)
- [Best Open-Source Models For Game Asset Creation in 2026](https://www.siliconflow.com/articles/best-open-source-models-for-game-asset-creation)
- [The Best Open-Source Image Generation Models in 2026](https://www.bentoml.com/blog/a-guide-to-open-source-image-generation-models)
- [FLUX.2, Stable Diffusion, Qwen and beyond](https://www.sevenlabs.site/blogs/open-source-image-generation-models-2026)
- [Best Free 2D Sprites, Pixel Art and Tilesets](https://app.cinevva.com/guides/free-2d-sprites-tilesets)
