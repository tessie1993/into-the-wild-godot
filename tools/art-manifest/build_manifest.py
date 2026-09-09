#!/usr/bin/env python3
"""Build the art-generation manifest for Into the Wild.

Reads  game/data/*.json and the placeholder card set in game/assets/cards/, and
writes docs/art/manifest.json (one job per asset — feed it to an image-
generation agent such as Google Flow / Nano Banana Pro) plus
docs/art/prompt-sheet.md (the same jobs, readable).

Every card job is derived from the data the engine loads, so the names,
rarities, elements and descriptions in the prompts are the game's own. The
non-card jobs (UI chrome, icons, hex tiles, sigils, screens, store art) are
declared as data below; the colors and geometry they quote come from
game/scripts/ui/ui_theme.gd, game/scripts/game/game.gd,
game/scripts/ui/karma_track.gd, game/scripts/core/hex.gd and
game/scripts/tools/render_cards.py. The style contract is the designer-approved
one in docs/art-direction.md.

Deterministic: run it again and the outputs are byte-identical.
"""
import json
import os

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
DATA = os.path.join(ROOT, "game", "data")
CARDS = os.path.join(ROOT, "game", "assets", "cards")
OUT_DIR = os.path.join(ROOT, "docs", "art")
ART = "art"  # repo-relative raw drop folder for generator output; nothing in it ships

# --- geometry quoted from the engine ---------------------------------------
CARD_W, CARD_H = 512, 768                 # render_cards.py CARD_W / CARD_H
ART_WINDOW = (22, 98, 490, 338)           # render_cards.py art_rect: pad 8, header 70, art_h 240
ART_W = ART_WINDOW[2] - ART_WINDOW[0]     # 468
ART_H = ART_WINDOW[3] - ART_WINDOW[1]     # 240
PANEL_PX = [ART_W * 4, ART_H * 4]         # 1872x960 — 4x the art window
HEX_ORIENTATION = "pointy-top"            # hex.gd: corners at 60*i - 30 degrees
VIEWPORT = [1920, 1080]                   # project.godot viewport

# Verified for Nano Banana Pro (Gemini 3 Pro Image); see the prompt sheet's sources.
ASPECTS = ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]

# --- style contract (docs/art-direction.md, designer-approved 2026-08-28) ----
STYLE_NAME = "Painterly storybook — soft watercolor/gouache, warm natural light, wonder over grit"
BASE_SUFFIX = (
    "painterly storybook illustration, soft watercolor and gouache, warm diffused natural light, "
    "visible brush texture, gentle rounded shapes, wondrous and serene, no text, no letters, no watermark"
)
ICON_SUFFIX = (
    "flat game-UI icon, one centered symbol, bold clean silhouette that stays readable at 32 pixels, "
    "warm gold #f2d06b with bronze #8a6d3b inner shading on a flat deep-forest-ink #0b1712 background, "
    "faint parchment grain, storybook-ornament feel, no text"
)
CHROME_SUFFIX = (
    "flat front-facing game-UI element, perfectly symmetrical and centered, no perspective, "
    "hand-painted storybook ornament, bronze #8a6d3b and gold #f2d06b filigree on deep-forest-ink #0b1712, "
    "faint parchment grain, crisp edges, no text"
)
NEGATIVE = (
    "text, letters, words, captions, logo, watermark, signature, photorealistic, 3D render, plastic, glossy, "
    "neon, lens flare, harsh black shadows, gore, blood, horror, grimdark, oversaturated, cluttered background, "
    "deformed anatomy, extra limbs, duplicate subject, cropped subject"
)
NEGATIVE_FLAT = NEGATIVE + ", perspective, scenery, landscape background, drop shadow"

STYLE_RULES = [
    "Darkness reads as cold absence of warmth — never gore, never horror.",
    "The island is benevolent by default: creatures look gentle and curious unless the prompt says otherwise.",
    "One shared light: warm, diffused, golden-hour. No neon, no lens flare, no hard black shadows.",
    "No text inside any image. Titles, stats and card text are rendered by the engine / render_cards.py.",
    "Color is never the only carrier of information (asset-pipeline.md): every element also has its own icon and shape.",
    "Proposed art rule (not in data): creature scale reads tier — common small, uncommon mid-sized, rare large.",
]

# --- palette quoted from code ------------------------------------------------
PALETTE = {
    "ui_mockup_pass (ui_theme.gd MOCKUP-PASS API)": {
        "ink": "#0b1712", "parchment": "#e8dcc0", "parchment_dim": "#b7ab8d", "gold": "#f2d06b",
        "gold_deep": "#c9a227", "bronze": "#8a6d3b", "glow": "#57d8c4", "leaf": "#2f7d4a",
        "leaf_deep": "#1f4a30", "danger": "#d16a5a", "rune_faint": "#8ca3a8 @55%",
    },
    "ui_storybook (ui_theme.gd storybook constants)": {
        "bg_deep": "#0b130e", "bg_dark": "#121d16", "bg_panel": "#17261d", "parchment_light": "#f5eedc",
        "parchment_dark_panel": "#232c25", "text_light": "#f4eedb", "text_muted": "#9ab0a0",
        "text_gold": "#f2d06b", "emerald": "#7ce8a6", "amber": "#e89a5c", "crimson": "#e8685c",
        "violet": "#bfa4f0",
    },
    "players (ui_theme.gd PLAYER_COLORS)": {
        "p1_amber_gold": "#e4b74a", "p2_terracotta": "#d16a5a", "p3_azure": "#5aa7d1", "p4_amethyst": "#9a6ad1",
    },
    "rarity (ui_theme.gd RARITY_COLORS)": {
        "common": "#8da895", "uncommon": "#4ebd78", "rare": "#4a9ee4", "legendary": "#f2a438",
    },
    "facedown_tiles (game.gd FACEDOWN_COLORS)": {"tier1": "#28322e", "tier2": "#202824", "tier3": "#1a1f26"},
    "karma_bands (karma_track.gd)": {
        "max_light": "#f2d06b", "light": "#9fdc7f", "neutral": "#e8dcc0", "dark": "#9a6ad1", "max_dark": "#6b5a9e",
        "ribbon": "#463a63 -> #c9a227", "moon_end": "#8f7fc9",
    },
}

GENERATOR = {
    "model": "Nano Banana Pro (Gemini 3 Pro Image) — in Google Flow or through the Gemini API",
    "aspect_ratios": ASPECTS,
    "references": (
        "Attach the batch's style anchor (and the category anchor named in each job's `references`) as reference "
        "images on every job. Keep reference sets small — 2 to 4 clean, consistent images; large mismatched sets drift."
    ),
    "resolution": (
        "Request 2K for icons and chrome, 4K (API: image_size \"4K\") for tiles, cards and screens; "
        "downscale to each job's target_px on import."
    ),
    "flow": "In Google Flow, save each anchor as an Ingredient and reference it from every job in the batch.",
    "seeds": "Generate each batch in one session with one seed family; regenerate a job with its neighbours' seed before changing the prompt.",
}

BATCHES = [
    ("0-anchors", "Style anchors", "Generate first and approve by eye. Every later job references one of these."),
    ("A-chrome", "UI chrome", "9-slice frames, buttons and HUD widgets. All UI is currently drawn in code (StyleBoxFlat) — these replace it visually without layout changes."),
    ("B-icons", "Icon vocabulary", "One icon per glyph the code currently draws as an emoji or Unicode symbol (dock buttons, HUD stats, tile markers, runes)."),
    ("C-board", "Board", "Hex terrain tiles (pointy-top), face-down tiles, the Sanctum glow, the Guardian-site overlay and the pawn token."),
    ("D-sigils", "Guardian sigils and gates", "One sigil per element plus the Corrupt Gate (max-dark band) and the Guardian Gate (max-light band)."),
    ("E-cards", "Card illustrations", "One art panel per existing card PNG (composited into the card frame by render_cards.py) plus the full-bleed card back."),
    ("F-screens", "Screen backgrounds", "Menu, character select, board backdrop, winner chronicle, modal texture."),
    ("G-store", "Store and ship assets", "App icon, adaptive icon layers, Play Store feature graphic, splash."),
]

# --- data ----------------------------------------------------------------------

def load(name):
    with open(os.path.join(DATA, name), encoding="utf-8") as f:
        return json.load(f)


def first_list(d):
    return d if isinstance(d, list) else next(v for v in d.values() if isinstance(v, list))


def card_files(sub):
    return sorted(f[:-4] for f in os.listdir(os.path.join(CARDS, sub)) if f.endswith(".png"))


ELEMENTS = {e["id"]: e for e in load("resources_digital.json")["elements"]}
DOMAIN = {e["id"]: e["domain"] for e in load("canon/elements.json")["elements"]}
ELEMENT_ORDER = [e["id"] for e in load("resources_digital.json")["elements"]]

SCENERY_T1 = {
    "wood": "dense green jungle, mossy roots, shafts of golden light",
    "grain": "a sunlit meadow of tall grain, reeds and wildflowers",
    "stone": "red-rock mountain slopes with flint scree and clay",
    "water": "a glassy lakeshore with shells, kelp and drifting mist",
    "ether": "a violet-misted swamp of glowing mushrooms and peat pools",
    "spirit": "a pale spirit grove where motes of light drift between white trees",
}
SCENERY_T2 = {
    "wood": "ancient deep jungle, giant roots, cathedral light",
    "grain": "a sun-scorched meadow bleached gold, cactus and heat shimmer",
    "stone": "the black slopes and glowing vents of a sleeping volcano",
    "water": "wild waters — storm-lit surf, frost shards and sea spray",
    "ether": "the deep swamp — moonshroom light, wisp essence, still black water",
    "spirit": "the Sanctum — a hexagonal heart of teal-white light, breathing",
}
# The content drop's 8-biome world (docs/design-lane/generated) as scenery phrases.
BIOME_SCENERY = {
    "wooded_lake": "a wooded lake shore where luminous algae glows in the shallows",
    "grasslands": "open sunlit grasslands",
    "rocky_ridge": "a red-rock ridge of flint and clay",
    "volcano": "the warm black slopes of a sleeping volcano",
    "desert": "sun-scorched dunes at the meadow's edge",
    "sinking_bog": "a violet-misted sinking bog",
    "frost_peak": "a frost-rimed peak above icy wild waters",
    "ancient_ruins": "moss-grown ancient ruins lit by faint spirit light",
}
TIER_SCALE = {
    "common": "small — palm-to-dog sized, endearing",
    "uncommon": "mid-sized and distinctive",
    "rare": "large and majestic, ancient",
    "legendary": "vast and luminous, a living landmark",
}
RARITY_CUE = {
    "common": "plain honest materials, no glow",
    "uncommon": "well made, with a touch of fresh green (#4ebd78) accent",
    "rare": "fine craftsmanship with a cool blue (#4a9ee4) shimmer",
    "legendary": "radiant and otherworldly, lit from within by warm amber (#f2a438)",
}

# --- job helpers -----------------------------------------------------------------

def job(jid, batch, kind, name, output, aspect, target_px, prompt, *, engine_target="", status="proposed",
        refs=(), negative=NEGATIVE, notes=""):
    assert aspect in ASPECTS, (jid, aspect)
    return {
        "id": jid,
        "batch": batch,
        "kind": kind,
        "name": name,
        "output": output,
        "engine_target": engine_target,
        "engine_target_status": status,
        "aspect_ratio": aspect,
        "target_px": list(target_px),
        "references": list(refs),
        "prompt": prompt,
        "negative_prompt": negative,
        "notes": notes,
    }


def scene(subject):
    return f"{subject} {BASE_SUFFIX}"


def icon(subject, color_note=""):
    return f"{subject}. {ICON_SUFFIX}" + (f". {color_note}" if color_note else "")


def chrome(subject):
    return f"{subject}. {CHROME_SUFFIX}"


PANEL_COMPOSITION = (
    "Wide landscape card-art panel: subject centered, calm uncluttered edges, everything important inside the "
    "central 85% of the height (the panel is center-cropped to about 2:1 and composited into the card frame)."
)
PANEL_NOTE = (
    f"Card art panel: crop to {PANEL_PX[0]}x{PANEL_PX[1]} (4x the {ART_W}x{ART_H} art window at "
    f"({ART_WINDOW[0]},{ART_WINDOW[1]}) of the {CARD_W}x{CARD_H} card). render_cards.py still paints a procedural "
    "art frame — pasting panels into the window is the pending integration step."
)


def panel(sub, cid, name, subject, refs=(), extra_note=""):
    return job(
        f"card_{sub}_{cid}", "E-cards", "card_panel", name,
        output=f"{ART}/cards/{sub}/{cid}.png", aspect="16:9", target_px=PANEL_PX,
        prompt=f"{subject} {PANEL_COMPOSITION} {BASE_SUFFIX}",
        engine_target=f"game/assets/cards/{sub}/{cid}.png",
        status="exists — placeholder card; the panel is composited into it",
        refs=("anchor_scene", *refs),
        notes=(PANEL_NOTE + (" " + extra_note if extra_note else "")),
    )


# --- batch 0: anchors -------------------------------------------------------------

def anchor_jobs():
    return [
        job("anchor_scene", "0-anchors", "anchor", "Style anchor — island vista",
            f"{ART}/anchors/anchor_scene.png", "16:9", [1920, 1080],
            scene("A wide view of a lush uncharted island from a hilltop at golden hour: green jungle canopy, a sunlit "
                  "grain meadow, a red-rock mountain with a sleeping volcano, a glassy lake shore, a violet-misted swamp, "
                  "and at the island's heart a pale grove breathing teal-white light; a small wrecked wooden ship on the "
                  "beach; tiny gentle creatures at the edges of the scene."),
            notes="Approve this first. It fixes the brush, the light and the six terrain colors for every scene job."),
        job("anchor_creature", "0-anchors", "anchor", "Style anchor — creature rendering (Mosskit)",
            f"{ART}/anchors/anchor_creature.png", "2:3", [1365, 2048],
            scene("Mosskit, a small round kitten-like creature with moss for fur and two sprouting leaves for ear tufts, "
                  "napping on a traveler's canvas backpack in dappled jungle light, one eye half open, calm and trusting."),
            refs=("anchor_scene",),
            notes="Fixes creature proportions, fur/foliage handling and the 'gentle by default' expression."),
        job("anchor_ui", "0-anchors", "anchor", "Style anchor — UI material",
            f"{ART}/anchors/anchor_ui.png", "1:1", [1024, 1024],
            chrome("A rectangular game-UI panel: dark green-teal parchment interior (#17261d), a 2px bronze border "
                   "with small gold filigree corner ornaments, rounded corners, and a single empty gold-bordered "
                   "button below it"),
            negative=NEGATIVE_FLAT,
            notes="Fixes the bronze/gold/ink material for every chrome and icon job."),
    ]


# --- batch A: chrome ---------------------------------------------------------------

def chrome_jobs():
    common_note = "9-slice source: keep the corners in the outer 12% of each edge; the middle must be flat and stretchable."
    specs = [
        ("ui_panel_frame", "HUD panel frame", "1:1", [1024, 1024],
         "HUD panel frame: deep green-ink fill (#17261d), a 2px sage-bronze border (#598566), corner radius 12 with tiny "
         "gold corner leaves, empty stretchable interior", common_note + " Used by game.gd _panel() for every HUD panel."),
        ("ui_panel_parchment_dark", "Parchment panel (dark)", "1:1", [1024, 1024],
         "Dark parchment panel: near-black green fill (#1f2921), a 2px antique-gold border (#d4a337), corner radius 12, "
         "faint aged-paper mottling, empty interior", common_note + " ui_theme.make_parchment_style(is_dark=true)."),
        ("ui_panel_parchment_light", "Parchment panel (light)", "1:1", [1024, 1024],
         "Light parchment panel: warm storybook paper (#f5eedc) with fibrous grain, a 2px antique-gold border (#d4a337), "
         "corner radius 12, empty interior", common_note + " ui_theme.make_parchment_style(is_dark=false)."),
        ("ui_modal_frame", "Encounter modal frame", "4:3", [1360, 1020],
         "Storybook encounter frame: deep ink fill (#1a241c), a 3px gold border (#d9b859) with ornate corner scrollwork, "
         "corner radius 16, empty interior", common_note + " game.gd modal_panel, 680x480 minimum."),
        ("ui_winner_frame", "Chronicle (winner) frame", "3:2", [1440, 960],
         "Chronicle frame for the end-of-game overlay: deep ink fill (#17241c), a 3px bright gold border (#f2cc59) with "
         "laurel-and-leaf corner ornaments, corner radius 18, empty interior", common_note + " game.gd winner_panel, 720x480."),
        ("ui_button_primary", "Button — primary (emerald)", "3:2", [768, 512],
         "Rounded game button, empty label area: deep emerald fill (#1a3824), a 2px bright leaf-green border (#66d185), "
         "corner radius 8, soft inner glow", "States (hover/pressed/disabled) are tinted in code; one texture."),
        ("ui_button_secondary", "Button — secondary", "3:2", [768, 512],
         "Rounded game button, empty label area: muted green-slate fill (#1f2924), a 2px sage border (#6b8c75), corner radius 8",
         "ui_theme.apply_button_style('secondary')."),
        ("ui_button_gold", "Button — gold", "3:2", [768, 512],
         "Rounded game button, empty label area: dark bronze fill (#423314), a 2px bright gold border (#f2cc59), "
         "corner radius 8, faint gilded sheen", "ui_theme.apply_button_style('gold') — Trade & Gift, Guardian, Give Back, Wild."),
        ("ui_button_danger", "Button — danger", "3:2", [768, 512],
         "Rounded game button, empty label area: dark crimson fill (#381a1a), a 2px dull red border (#d95959), corner radius 8",
         "ui_theme.apply_button_style('danger') — Raid. Cold, not gory."),
        ("ui_pill_active", "Pill tab — active", "3:2", [768, 384],
         "Fully rounded pill tab, empty label area: fresh-green fill at 30% (#4ebd78), a 2px green border (#4ebd78)",
         "ui_theme.make_pill_style(is_active=true) — card gallery filters."),
        ("ui_pill_idle", "Pill tab — idle", "3:2", [768, 384],
         "Fully rounded pill tab, empty label area: dark fill (#1a211c), a 1px slate-green border (#4d6152)",
         "ui_theme.make_pill_style(is_active=false)."),
        ("ui_stat_chip", "Stat chip (shield)", "5:4", [720, 576],
         "Small shield-shaped stat chip, empty: near-black fill (#0a1412), a 2px bronze border (#8a6d3b), corner radius 8",
         "ui_theme.stat_chip(), 72x60 — character cards (Move, Pack, Hand, Energy)."),
        ("ui_medallion_ring", "Element medallion ring", "1:1", [512, 512],
         "A round medallion ring: 2px deep-gold rim (#c9a227) around a flat neutral disc to be tinted per element",
         "ui_theme.medallion(); the interior is filled with the element color at runtime."),
        ("ui_toast_banner", "Toast banner", "21:9", [1680, 720],
         "Wide low notification banner: deep green-ink fill (#17261d), a 2px sage-bronze border (#598566), corner radius 12, "
         "a small gold sparkle ornament at the left end, empty text area", "game.gd toast_panel (bottom-left)."),
        ("ui_dock_bar", "Action dock bar", "21:9", [2100, 900],
         "Wide dock panel that holds a row of buttons: deep green-ink fill (#17261d), a 2px sage-bronze border, corner "
         "radius 12, faint carved-wood grain, empty interior", "game.gd dock_panel (bottom-center): Care row and Action row."),
        ("ui_separator_ornament", "Section separator ornament", "21:9", [2100, 900],
         "A thin horizontal rule with a small four-petal gold ornament at its center and tapering bronze ends, on ink",
         "Replaces HSeparator + the '❖ HEADING ❖' flourish."),
        ("ui_card_highlight", "Selected-card highlight", "2:3", [1024, 1536],
         "An empty rounded-rectangle outline the shape of a playing card: 3px bright gold (#f2d159) stroke, corner radius 10, "
         "with a soft outer gold glow, transparent interior on ink", "card_view.gd _highlight_panel. Key the ink to alpha."),
        ("ui_karma_ribbon", "Karma Track ribbon", "21:9", [2100, 900],
         "A long horizontal ribbon that shades from deep violet (#463a63) at the left to deep gold (#c9a227) at the right, "
         "framed by a 2px bronze edge, with four faint tick marks at 10%, 40%, 60% and 90% of its length, a crescent "
         "moon at the left end (#8f7fc9) and a radiant sun at the right end (#f2d06b)",
         "karma_track.gd: track -10..+10, band ticks at -8, -2, +2, +8. Marker is a separate sprite."),
        ("ui_karma_marker", "Karma Track marker", "1:1", [256, 256],
         "A small glowing round medallion with a thin dark rim and a soft halo, neutral parchment (#e8dcc0), on ink",
         "karma_track.gd marker; tinted per band at runtime (gold / #9fdc7f / parchment / #9a6ad1 / #6b5a9e)."),
    ]
    return [
        job(jid, "A-chrome", "ui_chrome", name, f"{ART}/ui/{jid}.png", aspect, px, chrome(subject),
            engine_target=f"game/assets/ui/{jid}.png", refs=("anchor_ui",), negative=NEGATIVE_FLAT, notes=note)
        for jid, name, aspect, px, subject, note in specs
    ]


# --- batch B: icons ------------------------------------------------------------------

def icon_jobs():
    specs = []  # (id, name, subject, color_note, replaces)
    element_symbols = {
        "wood": "a curling jungle leaf with a small root",
        "grain": "a wheat ear crossed by a small sun",
        "stone": "a mountain peak with an ember flame at its heart",
        "water": "a cresting wave under a gull-wing sky",
        "ether": "a glowing mushroom cap under a crescent moon",
        "spirit": "a rising wisp of light with a prismatic halo",
    }
    for el in ELEMENT_ORDER:
        e = ELEMENTS[el]
        specs.append((f"icon_element_{el}", f"Element — {e['name']} ({el})",
                      f"{element_symbols[el]} — the {e['name']} element, domain of {DOMAIN[el]}",
                      f"Fill in the element color {e['color']} instead of gold; keep the bronze shading.",
                      "Element medallions (ui_theme.MEDALLIONS) and resource lists."))
    for r, sym in [("common", "a plain smooth river pebble"), ("uncommon", "a budding two-leaf sprout"),
                   ("rare", "a faceted crystal"), ("legendary", "a radiant sunstone with rays")]:
        specs.append((f"icon_rarity_{r}", f"Rarity — {r}", f"{sym} — the {r} rarity class",
                      f"Fill in the rarity color {PALETTE['rarity (ui_theme.gd RARITY_COLORS)'][r]} instead of gold.",
                      "Card tier letters [C]/[U]/[R]/[L] in the pouch list."))
    for jid, name, sym, col, rep in [
        ("icon_energy", "Energy", "a lightning-spark bolt", "", "⚡ in the HUD stats line and Care buttons"),
        ("icon_vp", "Victory Points", "a five-point star", "", "★ in the HUD stats line"),
        ("icon_light", "Light", "a four-point sparkle star", "", "✦ (Light / Give Back / quest headers)"),
        ("icon_rage", "Island Rage", "a cracked island silhouette with a thread of smoke", "Use the danger color #d16a5a instead of gold.", "'Island Rage n/10' — text only today"),
        ("icon_hypocrisy", "Hypocrisy penalty", "a warning triangle holding a small split mask", "Use the danger color #d16a5a instead of gold.", "⚠ Hypocrisy in the HUD"),
        ("icon_move", "Moves", "a pair of boot prints", "", "'Moves: n' — text only today"),
        ("icon_action_explore", "Action — Explore / Gather", "a compass rose with a pathfinder's needle", "", "🧭"),
        ("icon_action_craft", "Action — Building / Craft", "a crossed hammer and hatchet over a small bench", "", "🔨"),
        ("icon_action_creatures", "Action — Creatures", "a stag's head with mossy antlers", "", "🦌"),
        ("icon_action_magic", "Action — Magic / Learning", "three sparkles above an open book", "", "✨"),
        ("icon_action_guardian", "Action — Guardian / Association", "a rounded shield bearing a standing-stone sigil", "", "🛡"),
        ("icon_action_give_back", "Action — Give Back", "two open hands releasing a spark of light", "", "Give Back ✦"),
        ("icon_action_raid", "Action — Raid", "a cracked skull-shaped mask", "Use the danger color #d16a5a instead of gold; cold, not gory.", "☠"),
        ("icon_action_trade", "Trade & Gift", "two curved arrows exchanging a leaf and a stone", "", "⇄"),
        ("icon_action_wild", "Wild cards", "a fanned playing card with a spark", "", "🃏"),
        ("icon_action_end_turn", "End Turn", "a hand passing a small token to the left", "", "'End Turn' — pass to the player on your left"),
        ("icon_care_eat", "Care — Eat", "a wooden bowl of berries with a curl of steam", "", "'Eat (⚡)'"),
        ("icon_care_sleep", "Care — Sleep", "a rolled bedroll beneath three small stars", "", "'Sleep (+2⚡)'"),
        ("icon_care_meditate", "Care — Meditate", "a seated figure in meditation with a halo of motes", "", "🧘"),
        ("icon_tile_guardian_site", "Tile marker — Guardian site", "a ring of standing stones with a glowing center", "", "✦ on explored tiles (game.gd _refresh_tile)"),
        ("icon_tile_homebase", "Tile marker — Homebase", "a small thatched hut", "", "⌂"),
        ("icon_tile_workshop", "Tile marker — Workshop", "an anvil with a hammer", "", "⚒"),
        ("icon_tile_exhausted", "Tile marker — Exhausted", "a withered stump on cracked ground", "", "×"),
    ]:
        specs.append((jid, name, sym, col, rep))
    rune_note = "Etched in pale slate-teal #8ca3a8 at about 55% opacity on face-down slate #28322e instead of gold on ink."
    for i, (glyph, sym) in enumerate([("✧", "a four-point spark"), ("❖", "a diamond with four petals"),
                                       ("◇", "a hollow diamond"), ("△", "an upward triangle"),
                                       ("▽", "a downward triangle"), ("✕", "two crossed strokes")], start=1):
        specs.append((f"icon_rune_{i:02d}", f"Face-down rune {i} ({glyph})", f"a faint etched arcane glyph: {sym}",
                      rune_note, f"UITheme.RUNES[{i - 1}] on unexplored tiles"))
    specs += [
        ("icon_karma_moon", "Karma Track — dark end", "a crescent moon", "Use lavender #8f7fc9 instead of gold.", "☾ (karma_track.gd)"),
        ("icon_karma_sun", "Karma Track — light end", "a radiant sun", "", "☀ (karma_track.gd)"),
        ("icon_creature_demand", "Creature — Demand", "an outstretched paw waiting for a berry", "", "creature Demand line in encounters"),
        ("icon_creature_gift", "Creature — Gift", "a leaf-wrapped bundle glowing softly", "", "creature Gift line"),
        ("icon_creature_bite", "Creature — Bite", "a bramble-thorn snap mark, no blood", "", "creature Bite line"),
        ("icon_nav_compendium", "Menu — Island Compendium", "an open storybook with a leaf bookmark", "", "🕮"),
        ("icon_nav_continue", "Menu — Continue Journey", "an hourglass with sand mid-fall", "", "⌛"),
        ("icon_nav_return", "Return to Shore", "a small sailboat on a wave", "", "⛵"),
        ("icon_nav_chevron", "Chevron", "a single right-pointing chevron", "", "▸ / ◂ (mirror in code)"),
        ("icon_inv_pouch", "Pouch", "a leather satchel with a buckle", "", "🎒"),
        ("icon_inv_cards", "Hand of cards", "a fan of three cards", "", "'Cards (n/limit)' — text only today"),
        ("icon_inv_item_slot", "Item slot", "an empty leather loop slot", "", "'Items (n/pack)' — text only today"),
    ]
    return [
        job(jid, "B-icons", "icon", name, f"{ART}/icons/{jid}.png", "1:1", [1024, 1024], icon(subject, col),
            engine_target=f"game/assets/icons/{jid}.png", refs=("anchor_ui",), negative=NEGATIVE_FLAT,
            notes=f"Replaces: {rep.rstrip('.')}. Deliver at 1024, ship at 64 and 128.")
        for jid, name, subject, col, rep in specs
    ]


# --- batch C: board ---------------------------------------------------------------------

HEX_RULE = (
    f"The painting fills a {HEX_ORIENTATION} hexagon — a vertex at the top and at the bottom, flat sides left and "
    "right — spanning the full frame height on a flat deep-forest-ink #0b1712 background to be keyed to alpha. "
    "The hexagon's edges must read as soft seamless terrain so neighbouring tiles blend; no border, no outline, no glyphs."
)


def board_jobs():
    jobs = []
    for el in ELEMENT_ORDER:
        e = ELEMENTS[el]
        for tier, name, color, scenery in [(1, e["name"], e["color"], SCENERY_T1[el]),
                                           (2, e["t2_name"], e["t2_color"], SCENERY_T2[el])]:
            jid = f"tile_{el}_t{tier}"
            jobs.append(job(
                jid, "C-board", "hex_tile", f"Hex tile — {name} (T{tier}, {el})",
                f"{ART}/tiles/{jid}.png", "1:1", [1024, 1024],
                scene(f"Hex terrain tile — {name}, Tier {tier} of the {e['name']} element ({el}, domain of {DOMAIN[el]}): "
                      f"{scenery}. Seen from above at a slight three-quarter angle. Dominant color {color}. {HEX_RULE}"),
                engine_target=f"game/assets/tiles/{jid}.png", refs=("anchor_scene",),
                notes=f"Tile fill color today: {color} (resources_digital.json). Tier 2 is the harsher inner ring."))
    for tier, color in [(1, "#28322e"), (2, "#202824"), (3, "#1a1f26")]:
        jid = f"tile_facedown_t{tier}"
        jobs.append(job(
            jid, "C-board", "hex_tile", f"Face-down hex tile — ring tier {tier}",
            f"{ART}/tiles/{jid}.png", "1:1", [1024, 1024],
            scene(f"Unexplored, face-down hex tile: weathered slate stone in {color}, thin drifting mist, a faint etched "
                  f"rune at the center in pale slate-teal #8ca3a8 at half opacity. {HEX_RULE}"),
            engine_target=f"game/assets/tiles/{jid}.png", refs=("anchor_scene",),
            notes="game.gd FACEDOWN_COLORS; the rune glyph itself is drawn in code (UITheme.rune_for)."))
    jobs.append(job(
        "tile_overlay_sanctum_glow", "C-board", "overlay", "Sanctum glow overlay",
        f"{ART}/tiles/tile_overlay_sanctum_glow.png", "1:1", [1024, 1024],
        scene("A soft teal (#57d8c4) radial glow with a gentle hexagonal falloff and a few drifting motes, on a flat "
              "deep-forest-ink #0b1712 background to be keyed to alpha; nothing else in frame."),
        engine_target="game/assets/tiles/tile_overlay_sanctum_glow.png", refs=("anchor_scene",),
        notes="game.gd _add_sanctum_glow(): breathes 10%–26% alpha over the center hex."))
    jobs.append(job(
        "tile_overlay_guardian_site", "C-board", "overlay", "Guardian-site overlay",
        f"{ART}/tiles/tile_overlay_guardian_site.png", "1:1", [1024, 1024],
        scene("A small ring of five mossy standing stones with a faint gold sigil glowing between them, seen from above "
              "at a slight angle, on a flat deep-forest-ink #0b1712 background to be keyed to alpha."),
        engine_target="game/assets/tiles/tile_overlay_guardian_site.png", refs=("anchor_scene",),
        notes="Guardian sites sit on Tier 2 tiles (tile.has_guardian). Today: a gold ✦ glyph."))
    jobs.append(job(
        "pawn_token", "C-board", "sprite", "Player pawn token",
        f"{ART}/tiles/pawn_token.png", "1:1", [512, 512],
        scene("A small carved-wood traveler token with a round base, neutral warm wood, front view, on a flat "
              "deep-forest-ink #0b1712 background to be keyed to alpha."),
        engine_target="game/assets/tiles/pawn_token.png", refs=("anchor_ui",),
        notes="Tinted with the player color at runtime (UITheme.PLAYER_COLORS). Today: a colored dot with a glow ring."))
    return jobs


# --- batch D: sigils -----------------------------------------------------------------------

def sigil_jobs():
    motifs = {
        "wood": "a great tree whose roots and crown form one ring",
        "grain": "a sun-wheel of bound wheat",
        "stone": "a mountain within a ring of flame",
        "water": "a spiral wave beneath a gull",
        "ether": "a crescent moon over a mushroom ring",
        "spirit": "an eye of light within a hexagon",
    }
    jobs = []
    for el in ELEMENT_ORDER:
        e = ELEMENTS[el]
        jid = f"sigil_guardian_{el}"
        jobs.append(job(
            jid, "D-sigils", "sigil", f"Guardian sigil — {e['name']} ({el})",
            f"{ART}/sigils/{jid}.png", "1:1", [1024, 1024],
            chrome(f"A circular Guardian sigil for the {e['name']} Guardian ({el}, domain of {DOMAIN[el]}): "
                   f"{motifs[el]}, engraved-stone feel, gold #f2d06b line-work with a tint of {e['color']}"),
            engine_target=f"game/assets/sigils/{jid}.png", refs=("anchor_ui",), negative=NEGATIVE_FLAT,
            notes="Guardians have no names or ids in game/data — sigils are per element. docs/art-direction.md says 5 "
                  "sigils, docs/design-lane/proposals/guardians.md says 6: open designer decision; drop one if 5."))
    jobs.append(job(
        "sigil_corrupt_gate", "D-sigils", "sigil", "Corrupt Gate motif",
        f"{ART}/sigils/sigil_corrupt_gate.png", "2:3", [1365, 2048],
        scene("The Corrupt Gate — the door the dark path opens: a cracked stone archway lit only by cold violet "
              "(#6b5a9e) light, warmth drained from the moss around it, mist pooling at its foot; unsettling through "
              "absence and cold, never gore."),
        engine_target="game/assets/sigils/sigil_corrupt_gate.png", refs=("anchor_scene",),
        notes="canon/duality.json max_dark band (-10..-8): 'Corrupt Gate unlocked'."))
    jobs.append(job(
        "sigil_guardian_gate", "D-sigils", "sigil", "Guardian Gate motif",
        f"{ART}/sigils/sigil_guardian_gate.png", "2:3", [1365, 2048],
        scene("The Guardian Gate — a radiant archway of living wood and gold light opening onto the Sanctum's teal "
              "(#57d8c4) glow, motes drifting through, welcoming."),
        engine_target="game/assets/sigils/sigil_guardian_gate.png", refs=("anchor_scene",),
        notes="canon/duality.json max_light band (8..10): 'Guardian Gate unlocked'."))
    return jobs


# --- batch E: cards ------------------------------------------------------------------------

def card_back_job():
    return job(
        "card_back", "E-cards", "card_full", "Universal card back",
        f"{ART}/cards/card_back.png", "2:3", [1024, 1536],
        scene("A playing-card back, full bleed: deep violet-ink ground (#181424 shading to #0a0810), a gold filigree "
              "triple frame with rounded corners, and a centered mandala — six concentric gold rings, a twelve-point "
              "compass star, twelve small teal gem petals (#64dcf0) on the middle ring, and a round island emblem at "
              "the heart; symmetrical, ornamental, no text."),
        engine_target="game/assets/cards/card_back.png", status="exists — loaded whole by card_view.gd",
        refs=("anchor_ui",),
        notes="Keeps the motif render_cards.py draws today (compass mandala). Used face-down for every card, so it is "
              "the one card job delivered as a full 2:3 image, not a panel.")


def character_jobs():
    chars = {c["id"]: c for c in load("characters.json")["characters"]}
    portraits = {
        "cartographer": ("a former ship's navigator turned island wayfinder, studying a hand-drawn chart of the island, "
                         "a brass sextant at hand, rolled charts in a satchel, weathered sailor's coat; confident, curious, "
                         "kind eyes", "Brass Sextant"),
        "botanist": ("a weathered ship's physician turned island botanist, a satchel of herbs and glass vials, a stone "
                     "herbalist's mortar, kind tired eyes", "Herbalist's Mortar"),
        "blacksmith": ("a ship's carpenter and metalworker — steady, patient and strong, a small pocket bellows and a "
                       "hammer at the belt, warm forge-light on the face", "Pocket Bellows"),
        "outcast": ("a stowaway and scavenger who survives by guile — wary and sharp-eyed, wrapped in patched layers, a "
                    "thief's prybar tucked at the hip; lonely and resourceful, not villainous", "Thief's Prybar"),
    }
    jobs = []
    for cid in card_files("characters"):
        c = chars[cid]
        look, item = portraits[cid]
        heart = ELEMENTS[c["heart"]]
        subject = (f"{c['name']}: {look}. Personality: {c['personality']} Backdrop: {SCENERY_T1[c['heart']]} — their beloved "
                   f"element, {heart['name']}. Waist-up storybook character portrait, face in the lower-middle of the frame.")
        jobs.append(panel("characters", cid, c["name"], subject, refs=("anchor_creature",),
                          extra_note=(f"Signature item from docs/design-lane/characters/{cid}/{cid}.md: {item}. Age, gender and "
                                      "ethnicity are not in the data — decide once, then pin the result as a reference. "
                                      "character_select.gd shows the card cropped to a 328x220 landscape window "
                                      "(KEEP_ASPECT_COVERED), so the face must sit low in the panel until that screen gets a "
                                      "dedicated portrait slot.")))
    return jobs


ACTION_SCENES = {
    "explore": ("a traveler with a compass and a walking staff at the edge of mist-covered, face-down hex tiles", {
        1: "at dawn, one tile flipping to reveal green jungle beneath the mist",
        2: "striding lighter and faster, a clear path opening, an extra handful of gathered commons in the pack",
        3: "a flipped tile releasing a glowing card into the air",
        4: "walking easily into harsh Tier 2 ground — deep jungle roots and volcanic slope — where others would slow",
        5: "the whole island vista opening before a master explorer as the land offers its bounty freely",
    }),
    "craft": ("a maker at a workbench of driftwood and stone", {
        1: "whittling a simple common tool by a campfire, no bench",
        2: "an orderly bench with materials to spare, a finished uncommon item",
        3: "a portable field bench unfolded in the wild, far from any camp",
        4: "a rare item glowing cool blue as it is finished, built to last",
        5: "a legendary artifact forged under the open sky, amber light, no workshop needed",
    }),
    "creatures": ("a traveler meeting island creatures", {
        1: "kneeling to meet a small curious creature for the first time",
        2: "a bone die and a fate card on the ground between traveler and creature",
        3: "offering a single berry, the creature already leaning in",
        4: "a tamed familiar riding on the traveler's shoulder, lending warmth and energy",
        5: "a master beast-whisperer seated calmly among creatures of every element",
    }),
    "magic": ("a traveler with cupped hands and an open skill book", {
        1: "a first spark of their signature ability rising from cupped hands",
        2: "an open skill book, its lesson coming easily",
        3: "meditating with a gentle spirit presence at their shoulder — a sponsor",
        4: "the signature ability blazing effortlessly, costing nothing",
        5: "ascended magic — an aurora of prismatic light over the island",
    }),
    "guardian": ("a traveler at a ring of standing stones — a Guardian site", {
        1: "laying an offering bundle at the stones",
        2: "the Guardian's approving light answering the offering",
        3: "a circle of travelers trading and sharing around the stones — a community",
        4: "a Guardian blessing settling on the traveler like warm light",
        5: "the Sanctum's teal glow opening at the island's heart — ascension",
    }),
}


def action_jobs():
    # Level perk text quoted from scripts/systems/action_cards.gd get_perks_text().
    perks = {
        "explore": ["Standard movement & gathering.", "+1 Move speed; +1 common on gathers.",
                    "+1 card draw when revealing face-down tiles.", "Immune to Tier 2 movement cost penalty.",
                    "Master Explorer (double gather without exhaust)."],
        "craft": ["Common crafts without bench.", "Crafting discount (1 less common on U recipes).",
                  "Can build field benches anywhere.", "Rare crafts gain +1 bonus durability.",
                  "Legendary craft anywhere without Workshop."],
        "creatures": ["Standard encounters.", "+1 bonus to Fate combat rolls.", "Befriend demands cost 1 fewer common.",
                      "Tamed familiar (+1 Energy boost).", "Master Beast Whisperer."],
        "magic": ["Character signature ability.", "Skill learning costs -1 CE.", "Sponsor perk (+1 common upon meditation).",
                  "Signature ability costs 0 Energy once per round.", "Ascended Magic."],
        "guardian": ["Standard Guardian offerings.", "Offerings grant +1 extra VP.",
                     "Unlocks Free Action Trading & empowers action cards.", "Guardian Blessing active.", "Sanctum Ascension."],
    }
    names = {"explore": "Explore / Gather", "craft": "Building / Craft", "creatures": "Creatures",
             "magic": "Magic / Learning", "guardian": "Guardian / Association"}
    descs = {
        "explore": "Move across the island, flip unexplored hexes, and gather element resources.",
        "craft": "Craft items, equipment, and shared public buildings.",
        "creatures": "Interact with living island creatures (befriend, fight, or exploit).",
        "magic": "Cast character signature magic and learn persistent skill perks.",
        "guardian": "Visit ancient Guardian sites, make offerings, and empower action cards.",
    }
    jobs = []
    for cid in card_files("actions"):
        aid, _, lvl = cid.partition("_lvl")
        base, levels = ACTION_SCENES[aid]
        if lvl:
            level = int(lvl)
            subject = (f"Action card '{names[aid]}', level {level} of 5: {base}, {levels[level]}. "
                       f"What the level grants: {perks[aid][level - 1]} The five levels are one scene growing richer; "
                       f"keep the same traveler, place and palette across levels.")
            name = f"{names[aid]} — level {level}"
        else:
            subject = (f"Action card '{names[aid]}' (base emblem): {base}, shown as a calm painted vignette. "
                       f"{descs[aid]}")
            name = f"{names[aid]} — base"
        jobs.append(panel("actions", cid, name, subject,
                          extra_note="Generate the five levels in one session from the base image as reference."))
    return jobs


def creature_jobs():
    canon = {c["id"]: c for c in load("creatures_canon.json")["creatures"]}
    wild = {c["id"]: c for c in first_list(load("creatures_wild.json"))}
    expanded = {c["id"]: c for c in first_list(load("creatures_expanded.json"))}
    jobs = []
    for cid in card_files("creatures"):
        if cid in canon:
            c = canon[cid]
            hook = f"Its gift: {c['gift']['desc']} Its bite: {c['bite']['desc']}"
            if c.get("quirk"):
                hook += f" Quirk: {c['quirk']}"
            scenery = SCENERY_T1[c["element"]]
            source = "creatures_canon.json"
        else:
            c = wild[cid]
            biomes = expanded.get(cid, {}).get("biomes", [])
            scenery = "; ".join(BIOME_SCENERY[b] for b in biomes) or SCENERY_T1[c["element"]]
            hook = f"Its field move is '{c['field_move']}' — show it mid-move."
            source = "creatures_wild.json + creatures_expanded.json"
        el, tier = c["element"], c["tier"]
        subject = (f"{c['name']}, a {tier} creature of the {ELEMENTS[el]['name']} ({el}, domain of {DOMAIN[el]}) — design a "
                   f"creature that fits its name. {hook} Setting: {scenery}. Scale: {TIER_SCALE[tier]}. Expression: gentle "
                   f"and curious, never threatening — the island is benevolent by default.")
        jobs.append(panel("creatures", cid, c["name"], subject, refs=("anchor_creature",),
                          extra_note=f"Data: {source}."))
    return jobs


def item_jobs():
    catalog = {i["id"]: i for i in load("items_catalog.json")["items"]}
    composition = {
        "tool": ("tool", "laid on a worn canvas cloth on a wooden bench, showing the marks of honest use"),
        "gear": ("piece of wearable gear", "displayed on a simple wooden stand"),
        "consumable": ("food or elixir", "set on a broad leaf or in a clay bowl"),
        "relic": ("spirit relic", "resting on a mossy stone altar, an offering meant for the Guardians"),
    }
    jobs = []
    for cid in card_files("items"):
        i = catalog[cid]
        noun, placement = composition[i["type"]]
        extra = ""
        if i["type"] == "gear" and i.get("immunity_element") in ELEMENTS:
            extra = f" Made for travel through {ELEMENTS[i['immunity_element']]['t2_name']}."
        if i["type"] == "consumable" and int(i.get("use_light", 0)) > 0:
            extra = " It carries a faint inner Light."
        if i["type"] == "relic":
            extra = f" Worth {i.get('offer_vp', 0)} VP when offered."
        subject = (f"{i['name']}: a single {i['rarity']} {noun}, {placement}. {RARITY_CUE[i['rarity']].capitalize()}.{extra} "
                   f"Still-life close-up, nothing else in frame.")
        jobs.append(panel("items", cid, i["name"], subject,
                          extra_note=f"items_catalog.json: {i['type']} / {i['rarity']}. Names are the content drop's placeholders."))
    return jobs


def deck_jobs():
    deck = {c["id"]: c for c in first_list(load("wild_deck.json"))}
    frame = {
        "fate": "a moment of fate on the island, a hand-held card catching the light",
        "encounter": "a sudden island encounter",
        "loot": "a discovered cache of island bounty",
        "ward": "a protective ward of island magic",
    }
    jobs = []
    for cid in card_files("deck"):
        c = deck[cid]
        subject = (f"{c['name']} — {frame[c['kind']]}. Card text: \"{c['text']}\" Paint the scene this describes, warm "
                   f"and legible from across a table.")
        note = f"wild_deck.json kind: {c['kind']}."
        if "'" in cid:
            note += " The filename contains an apostrophe — quote it in shell commands."
        jobs.append(panel("deck", cid, c["name"], subject, extra_note=note))
    return jobs


def event_jobs():
    events = {e["id"]: e for e in first_list(load("events.json"))}
    return [panel("events", cid, events[cid]["name"],
                  f"{events[cid]['name']} — \"{events[cid]['desc']}\" Paint this moment on the island.",
                  extra_note="events.json.")
            for cid in card_files("events")]


def quest_jobs():
    q = load("quests.json")
    lookup = {}
    for diff, lst in q["common"].items():
        for it in lst:
            lookup[it["id"]] = (f"common quest, {diff}", it)
    for it in q["guardian"]:
        lookup[it["id"]] = ("guardian quest", it)
    return [panel("quests", cid, lookup[cid][1]["name"],
                  f"{lookup[cid][1]['name']} ({lookup[cid][0]}): \"{lookup[cid][1]['desc']}\" Paint the deed being done, "
                  f"warmly — giving is the point.",
                  extra_note=f"quests.json, {lookup[cid][1].get('vp', 0)} VP.")
            for cid in card_files("quests")]


def skill_jobs():
    skills = {s["id"]: s for s in load("skills.json")["skills"]}
    return [panel("skills", cid, skills[cid]["name"],
                  f"{skills[cid]['name']} ({skills[cid]['tier']} skill): \"{skills[cid]['desc']}\" An emblematic scene of "
                  f"this ability in use. {RARITY_CUE[skills[cid]['tier']].capitalize()}.",
                  extra_note="skills.json.")
            for cid in card_files("skills")]


# --- batch F: screens ------------------------------------------------------------------------

def screen_jobs():
    specs = [
        ("screen_title", "Title screen background", "16:9", VIEWPORT,
         "The main-menu ground: a night-to-dawn island vista in deep forest ink (#0b1712) with the first gold light on "
         "the horizon, low contrast so gold titles read over it, drifting spirit motes in soft green, gold, mist-blue "
         "and violet", "main_menu.gd: title 'INTO THE WILD' and a 580x680 center panel sit over it."),
        ("screen_character_select", "Character select background", "16:9", VIEWPORT,
         "A beach at dawn with the broken hull of a wooden ship, four sets of footprints leading inland into jungle, "
         "quiet and hopeful", "character_select.gd."),
        ("screen_board_backdrop", "Board backdrop (ocean, tileable)", "1:1", [2048, 2048],
         "Calm open ocean seen from above, deep blue-green (#0b1712 toward #1d4b79), subtle wave texture, seamless "
         "and tileable on all four edges", "game.gd world_bg: an 8000x8000 rect behind the island."),
        ("screen_winner_chronicle", "Winner chronicle background", "16:9", VIEWPORT,
         "The island at golden hour from a hilltop, the Sanctum glowing at its heart, a closing-storybook mood",
         "game.gd winner_overlay ('CHRONICLE OF THE ISLAND')."),
        ("screen_modal_backdrop", "Modal backdrop texture (tileable)", "1:1", [1024, 1024],
         "A dark ink-and-parchment texture, mottled, seamless and tileable", "game.gd modal_backdrop (85% ink over the board)."),
    ]
    return [job(jid, "F-screens", "screen", name, f"{ART}/screens/{jid}.png", aspect, px, scene(subject + "."),
                engine_target=f"game/assets/screens/{jid}.png", refs=("anchor_scene",), notes=note)
            for jid, name, aspect, px, subject, note in specs]


# --- batch G: store -----------------------------------------------------------------------------

def store_jobs():
    icon_subject = ("A lush island seen from above forming a spiral of glowing light inside a hexagon, tiny creatures at "
                    "its edges")
    return [
        job("store_app_icon", "G-store", "store", "App icon", f"{ART}/store/store_app_icon.png", "1:1", [1024, 1024],
            scene(icon_subject + ", centered, bold and readable at 48 pixels."),
            engine_target="game/icon.png (replaces icon.svg)", refs=("anchor_scene",),
            notes="Play Store: 512x512 PNG. Prompt from docs/art-direction.md."),
        job("store_adaptive_fg", "G-store", "store", "Adaptive icon — foreground", f"{ART}/store/store_adaptive_fg.png",
            "1:1", [1024, 1024],
            scene(icon_subject + ", the island alone inside the central 66% of the frame, on a flat deep-forest-ink "
                  "#0b1712 background to be keyed to alpha."),
            engine_target="android adaptive icon foreground", refs=("store_app_icon",),
            notes="Android masks the outer third; keep everything inside the safe zone."),
        job("store_adaptive_bg", "G-store", "store", "Adaptive icon — background", f"{ART}/store/store_adaptive_bg.png",
            "1:1", [1024, 1024],
            scene("A flat deep-forest-ink #0b1712 field with a very faint honeycomb of hexagons and a soft teal glow at the "
                  "center, no subject."),
            engine_target="android adaptive icon background", refs=("store_app_icon",), notes=""),
        job("store_feature_graphic", "G-store", "store", "Play Store feature graphic", f"{ART}/store/store_feature_graphic.png",
            "16:9", [1024, 500],
            scene("The island vista at golden hour with the four travelers small on the beach beside their wrecked ship, "
                  "creatures watching gently from the treeline, generous empty sky on the left for a title overlay."),
            engine_target="Play Store listing", refs=("anchor_scene",),
            notes="Generate 16:9, center-crop to 1024x500 (keeps ~87% of the height)."),
        job("store_splash", "G-store", "store", "Splash screen", f"{ART}/store/store_splash.png", "16:9", VIEWPORT,
            scene("The app icon's island-spiral emblem small at the center of a calm deep-forest-ink field with a few "
                  "drifting motes; quiet, loads fast."),
            engine_target="project.godot boot splash", refs=("store_app_icon",),
            notes="Landscape: project.godot handheld/orientation=4 (sensor landscape)."),
    ]


# --- assemble, validate, write ----------------------------------------------------------------------

def build():
    jobs = (anchor_jobs() + chrome_jobs() + icon_jobs() + board_jobs() + sigil_jobs()
            + [card_back_job()] + character_jobs() + action_jobs() + creature_jobs() + item_jobs()
            + deck_jobs() + event_jobs() + quest_jobs() + skill_jobs()
            + screen_jobs() + store_jobs())

    ids = [j["id"] for j in jobs]
    assert len(ids) == len(set(ids)), "duplicate job ids"
    outputs = [j["output"] for j in jobs]
    assert len(outputs) == len(set(outputs)), "duplicate outputs"
    known = {j["id"] for j in jobs}
    for j in jobs:
        assert j["prompt"].strip(), j["id"]
        for r in j["references"]:
            assert r in known, (j["id"], r)

    # Every placeholder card PNG gets exactly one job, and no job points at a card that does not exist.
    existing = {"game/assets/cards/card_back.png"}
    for sub in ("actions", "characters", "creatures", "deck", "events", "items", "quests", "skills"):
        existing |= {f"game/assets/cards/{sub}/{c}.png" for c in card_files(sub)}
    targeted = {j["engine_target"] for j in jobs if j["batch"] == "E-cards"}
    assert targeted == existing, (sorted(existing - targeted), sorted(targeted - existing))

    counts = {b[0]: sum(1 for j in jobs if j["batch"] == b[0]) for b in BATCHES}
    return {
        "_comment": "Generated by tools/art-manifest/build_manifest.py — do not hand-edit; change the script or the game data and re-run.",
        "game": "Into the Wild",
        "style": {
            "name": STYLE_NAME,
            "source": "docs/art-direction.md (designer-approved 2026-08-28)",
            "scene_suffix": BASE_SUFFIX,
            "icon_suffix": ICON_SUFFIX,
            "chrome_suffix": CHROME_SUFFIX,
            "negative_prompt": NEGATIVE,
            "negative_prompt_flat": NEGATIVE_FLAT,
            "rules": STYLE_RULES,
            "palette": PALETTE,
        },
        "engine": {
            "card_px": [CARD_W, CARD_H],
            "card_art_window": {"x": ART_WINDOW[0], "y": ART_WINDOW[1], "w": ART_W, "h": ART_H},
            "card_panel_px": PANEL_PX,
            "hex_orientation": HEX_ORIENTATION,
            "viewport_px": VIEWPORT,
            "card_path_rule": "res://assets/cards/<category>/<id>.png; action cards <id>_lvl<n>.png (card_view.gd get_card_texture_path)",
        },
        "generator": GENERATOR,
        "batches": [{"id": b[0], "title": b[1], "purpose": b[2], "count": counts[b[0]]} for b in BATCHES],
        "job_count": len(jobs),
        "jobs": jobs,
    }


SOURCES = [
    ("Nano Banana Pro (Gemini 3 Pro Image) — Google DeepMind", "https://deepmind.google/models/gemini-image/pro/"),
    ("Nano Banana Pro announcement — Google", "https://blog.google/innovation-and-ai/products/nano-banana-pro/"),
    ("Aspect-ratio guide (10 ratios, 1:1 … 21:9)", "https://www.aifreeapi.com/en/posts/nano-banana-pro-aspect-ratio-guide"),
    ("Reference images: slots, drift fixes", "https://www.aifreeapi.com/en/posts/nano-banana-pro-reference-images"),
    ("Developer guide (4K via image_size)", "https://dev.to/akaranjkar08/nano-banana-pro-gemini-3-pro-image-developer-guide-api-2026-104c"),
    ("Nano Banana in Google Flow — Ingredients", "https://whiskailabs.net/what-is-nano-banana-google-flow-ai/"),
]


def write_markdown(m, path):
    L = []
    w = L.append
    w("# Into the Wild — art generation prompt sheet")
    w("")
    w("*Generated by `tools/art-manifest/build_manifest.py`. Do not hand-edit — change the script or `game/data/` and re-run.*")
    w("")
    w(f"{m['job_count']} jobs in {len(m['batches'])} batches. The same list is `manifest.json` (one object per job) — feed that "
      "to the image-generation agent; this sheet is for reading.")
    w("")
    w("## How to run it")
    w("")
    w("1. Generate batch **0-anchors** first and approve the three images by eye. They set the brush, the light and the UI material.")
    w("2. For every later job, attach the anchors named in its `references` as reference images "
      "(in Google Flow: save each anchor as an *Ingredient* and reference it). Keep reference sets to 2–4 images.")
    w("3. Run one batch per session with one seed family. Use each job's `aspect_ratio` as given; request 2K for icons/chrome "
      "and 4K for tiles, cards and screens, then downscale to `target_px`.")
    w("4. Save to the job's `output` path (repo-relative, under `art/`). Nothing under `art/` ships.")
    w("5. Cards: every job in **E-cards** except `card_back` is an *art panel* for the 468×240 window of the 512×768 card "
      "(`render_cards.py`), generated at 16:9 and center-cropped to 1872×960. Pasting panels into that window is the "
      "pending integration step in `render_cards.py`; `card_back` is delivered whole.")
    w("6. Non-card assets have a proposed `engine_target`; no code loads them yet (all UI is drawn in code today).")
    w("7. Paste each prompt verbatim, then the batch's negative prompt. Regenerate with a neighbour's seed before rewording.")
    w("")
    w("## Style contract")
    w("")
    w(f"**{m['style']['name']}** — {m['style']['source']}.")
    w("")
    w("| Use | Suffix appended to every prompt |")
    w("|---|---|")
    w(f"| Scenes, tiles, cards, screens | {m['style']['scene_suffix']} |")
    w(f"| Icons | {m['style']['icon_suffix']} |")
    w(f"| UI chrome, sigils | {m['style']['chrome_suffix']} |")
    w("")
    w(f"**Negative prompt (all jobs):** {m['style']['negative_prompt']}")
    w("")
    w(f"**Negative prompt (icons, chrome):** {m['style']['negative_prompt_flat']}")
    w("")
    for r in m["style"]["rules"]:
        w(f"- {r}")
    w("")
    w("### Palette (quoted from code)")
    w("")
    for group, cols in m["style"]["palette"].items():
        w(f"- **{group}:** " + " · ".join(f"{k} `{v}`" for k, v in cols.items()))
    w("- **elements (resources_digital.json):** " + " · ".join(
        f"{ELEMENTS[e]['name']} `{ELEMENTS[e]['color']}` / {ELEMENTS[e]['t2_name']} `{ELEMENTS[e]['t2_color']}`" for e in ELEMENT_ORDER))
    w("")
    w("### Engine geometry")
    w("")
    eng = m["engine"]
    w(f"- Card {eng['card_px'][0]}×{eng['card_px'][1]}; art window {eng['card_art_window']['w']}×{eng['card_art_window']['h']} at "
      f"({eng['card_art_window']['x']}, {eng['card_art_window']['y']}); panels delivered at {eng['card_panel_px'][0]}×{eng['card_panel_px'][1]}.")
    w(f"- Hex tiles: **{eng['hex_orientation']}** (`hex.gd`). Viewport {eng['viewport_px'][0]}×{eng['viewport_px'][1]}, landscape.")
    w(f"- Card lookup: `{eng['card_path_rule']}`.")
    w("")
    w("### Generator notes (Nano Banana Pro)")
    w("")
    g = m["generator"]
    w(f"- Model: {g['model']}.")
    w(f"- Aspect ratios: {', '.join(g['aspect_ratios'])}.")
    w(f"- References: {g['references']}")
    w(f"- Resolution: {g['resolution']}")
    w(f"- Flow: {g['flow']}")
    w(f"- Seeds: {g['seeds']}")
    w("")
    w("## Batches")
    w("")
    w("| Batch | Title | Jobs | Purpose |")
    w("|---|---|---:|---|")
    for b in m["batches"]:
        w(f"| {b['id']} | {b['title']} | {b['count']} | {b['purpose']} |")
    w("")
    for b in m["batches"]:
        w(f"## {b['id']} — {b['title']} ({b['count']})")
        w("")
        w(b["purpose"])
        w("")
        for j in m["jobs"]:
            if j["batch"] != b["id"]:
                continue
            w(f"### `{j['id']}` — {j['name']}")
            w("")
            refs = ", ".join(f"`{r}`" for r in j["references"]) or "—"
            w(f"- **Aspect** {j['aspect_ratio']} · **target** {j['target_px'][0]}×{j['target_px'][1]} · **references** {refs}")
            w(f"- **Save to** `{j['output']}` → engine: `{j['engine_target']}` ({j['engine_target_status']})")
            if j["notes"]:
                w(f"- **Notes** {j['notes']}")
            w("")
            w(f"> {j['prompt']}")
            w("")
    w("## Sources")
    w("")
    for title, url in SOURCES:
        w(f"- [{title}]({url})")
    w("")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    m = build()
    with open(os.path.join(OUT_DIR, "manifest.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(m, f, indent=2, ensure_ascii=False)
        f.write("\n")
    write_markdown(m, os.path.join(OUT_DIR, "prompt-sheet.md"))
    print(f"{m['job_count']} jobs -> docs/art/manifest.json, docs/art/prompt-sheet.md")
    for b in m["batches"]:
        print(f"  {b['id']:12} {b['count']:4}  {b['title']}")


if __name__ == "__main__":
    main()
