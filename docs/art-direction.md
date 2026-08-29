# Art Direction — Into the Wild (designer-approved 2026-08-28)

**Style: painterly storybook.** Soft watercolor/gouache, warm natural light,
gentle edges, visible brush texture. Wonder over grit. The island should feel
alive and benevolent-by-default — darkness reads as *cold absence of warmth*,
never gore.

Palette anchors (match `data/resources_digital.json` tile colors):
Jungle #2f7d4a · Meadow #c9a227 · Mountain #b3452e · Lakeshore #2e6fae ·
Swamp #7a5fae · Spirit #cfc4e8 · face-down tiles: slate blue-greys.

## Asset list (v1)

1. 12 hex tile paintings: 6 elements × T1/T2 (seamless flat-top hex, top-down ¾)
2. 15 creature portraits (card format, 3:4) — roster in `data/creatures_canon.json`
3. 4 character portraits: Cartographer, Botanist, Blacksmith, Outcast
4. Guardian sigil set (5) + Corrupt Gate motif
5. App icon 512×512: the island as a spiral of light in a hex
6. Feature graphic 1024×500 for Play Store

## Prompt pack (Google Flow / Imagen / SDXL)

Base style suffix — append to every prompt:
> …, painterly storybook illustration, soft watercolor and gouache, warm
> diffused light, visible brush texture, gentle rounded shapes, wondrous and
> serene, no text, no watermark

- **Tile (example, Deep Jungle T2):** "dense ancient jungle seen from above at
  a slight angle, giant mossy roots and shafts of golden light, hexagonal
  composition, deep greens (#1c5432), …"
- **Creature (example, Moss Stag):** "a gentle stag whose antlers are grown
  over with moss and tiny flowers, standing in dappled forest light, looking
  at the viewer with calm ancient eyes, card portrait, …"
- **Character (example, The Botanist):** "a weathered ship's physician turned
  island botanist, satchel of herbs and glass vials, kind tired eyes, jungle
  backdrop, storybook character portrait, …"
- **App icon:** "a lush island seen from above forming a spiral of glowing
  light inside a hexagon, tiny creatures at its edges, …"

Consistency tips: generate each category in one session with the same seed
family; upscale to 2048 then downscale; keep one reference image pinned as
style anchor across Flow sessions.

## UI style guide (in-engine, mockup pass 2026-08-28)

The mockups (title screen, character select, board HUD, karma track) are
implemented in code via `game/scripts/ui/ui_theme.gd` — one visual language
until painted assets land:

- **Ground:** deep forest ink `#0b1712`; panels `rgba` dark green-teal with
  2px bronze `#8a6d3b` borders, radius 10–16.
- **Text:** parchment `#e8dcc0` body, dim `#b7ab8d`; titles gold `#f2d06b`
  with soft ink shadow; section headings `❖ SMALL CAPS ❖` in `#c9a227`.
- **CTAs:** deep leaf green with gold border and gold text ("Wash Ashore",
  "Begin Action", "End Turn"); danger accents `#d16a5a`.
- **Selection/glow:** teal `#57d8c4` (Sanctum pulse), player-color card glow.
- **Board:** facedown hexes slate blue-grey with faint rune etchings;
  explored hexes keep the element palette anchors above; the Sanctum
  breathes a teal glow.
- **Karma track:** violet-to-gold ribbon, ☾/☀ ends, band-boundary ticks,
  glowing marker (`karma_track.gd`).

Painted replacements from the asset list slot in per element/screen without
layout changes.
