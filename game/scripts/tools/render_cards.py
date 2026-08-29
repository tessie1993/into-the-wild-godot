"""
Card Asset Rendering Engine for 'Into the Wild'
Renders high-resolution (512x768) PNG card images for every card in the game:
- Action Cards (Explore, Craft, Creatures, Magic, Guardian) across levels 1-5
- Deck Cards (20 unique cards: Action/Fate, Ward/Blessing, Encounter, Resource/Loot)
- Event Cards (8 core island events)
- Quest Cards (Common and Guardian quests)
- Skill Cards (10 skill tree cards across tiers)
- Creature Cards (Canon and expanded creatures)
- Item Cards (150 tools, gear, consumables, weapons, wards, dark kit)
- Character Cards (4 player identities)
- Universal Card Back (Mystic island mandala)
"""

import os
import json
import math
from PIL import Image, ImageDraw, ImageFont

CARD_W = 512
CARD_H = 768

# Base output paths
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DATA_DIR = os.path.join(BASE_DIR, "data")
ASSETS_DIR = os.path.join(BASE_DIR, "assets", "cards")

# Colors
TIER_COLORS = {
    "common": {
        "border": (160, 140, 115),
        "frame_bg": (28, 25, 22),
        "header_bg": (45, 40, 35),
        "accent": (210, 185, 150),
        "badge": (120, 105, 85),
    },
    "uncommon": {
        "border": (70, 160, 120),
        "frame_bg": (18, 30, 24),
        "header_bg": (28, 52, 40),
        "accent": (110, 220, 165),
        "badge": (40, 110, 75),
    },
    "rare": {
        "border": (215, 165, 50),
        "frame_bg": (32, 28, 16),
        "header_bg": (60, 48, 20),
        "accent": (255, 215, 90),
        "badge": (160, 115, 25),
    },
    "legendary": {
        "border": (175, 90, 235),
        "frame_bg": (28, 16, 36),
        "header_bg": (55, 25, 75),
        "accent": (220, 145, 255),
        "badge": (125, 50, 175),
    },
}

TYPE_THEMES = {
    "action": {
        "gradient": [(30, 45, 60), (15, 25, 35)],
        "accent": (100, 190, 255),
        "border": (90, 150, 210),
        "icon": "A",
    },
    "craft": {
        "gradient": [(65, 45, 25), (35, 22, 12)],
        "accent": (245, 160, 80),
        "border": (200, 120, 50),
        "icon": "C",
    },
    "creatures": {
        "gradient": [(60, 25, 25), (30, 12, 12)],
        "accent": (245, 100, 100),
        "border": (195, 70, 70),
        "icon": "B",
    },
    "magic": {
        "gradient": [(45, 25, 65), (22, 12, 35)],
        "accent": (205, 120, 255),
        "border": (165, 80, 220),
        "icon": "M",
    },
    "guardian": {
        "gradient": [(55, 50, 25), (28, 24, 10)],
        "accent": (250, 220, 90),
        "border": (210, 175, 50),
        "icon": "G",
    },
    "deck": {
        "gradient": [(30, 38, 48), (16, 20, 26)],
        "accent": (130, 180, 230),
        "border": (90, 130, 175),
        "icon": "D",
    },
    "event": {
        "gradient": [(25, 45, 50), (12, 24, 28)],
        "accent": (80, 220, 210),
        "border": (50, 160, 150),
        "icon": "E",
    },
    "quest": {
        "gradient": [(50, 42, 28), (26, 20, 12)],
        "accent": (235, 195, 110),
        "border": (190, 145, 70),
        "icon": "Q",
    },
    "skill": {
        "gradient": [(28, 48, 42), (14, 26, 22)],
        "accent": (95, 225, 165),
        "border": (60, 165, 115),
        "icon": "S",
    },
    "item": {
        "gradient": [(42, 38, 32), (20, 18, 15)],
        "accent": (215, 190, 140),
        "border": (160, 135, 95),
        "icon": "I",
    },
    "character": {
        "gradient": [(40, 32, 55), (18, 14, 28)],
        "accent": (190, 160, 245),
        "border": (140, 110, 195),
        "icon": "U",
    },
}

def get_font(size: int, bold: bool = False, italic: bool = False) -> ImageFont.FreeTypeFont:
    font_names = []
    if bold:
        font_names = ["segoeuib.ttf", "arialbd.ttf", "georgiab.ttf", "calibrib.ttf"]
    elif italic:
        font_names = ["segoeuii.ttf", "ariali.ttf", "georgiai.ttf", "calibrii.ttf"]
    else:
        font_names = ["segoeui.ttf", "arial.ttf", "georgia.ttf", "calibri.ttf"]
    
    for fn in font_names:
        path = os.path.join("C:/Windows/Fonts", fn)
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()

def draw_rounded_rectangle(draw: ImageDraw.ImageDraw, xy, radius: int, fill=None, outline=None, width=1):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill, outline=outline, width=width)

def draw_gradient_rect(img: Image.Image, xy, top_color, bottom_color, radius: int = 0):
    x0, y0, x1, y1 = xy
    w = int(x1 - x0)
    h = int(y1 - y0)
    if w <= 0 or h <= 0:
        return
    
    grad = Image.new("RGBA", (w, h))
    g_draw = ImageDraw.Draw(grad)
    for i in range(h):
        ratio = i / float(h)
        r = int(top_color[0] * (1 - ratio) + bottom_color[0] * ratio)
        g = int(top_color[1] * (1 - ratio) + bottom_color[1] * ratio)
        b = int(top_color[2] * (1 - ratio) + bottom_color[2] * ratio)
        a = 255
        if len(top_color) > 3 and len(bottom_color) > 3:
            a = int(top_color[3] * (1 - ratio) + bottom_color[3] * ratio)
        g_draw.line([(0, i), (w, i)], fill=(r, g, b, a))
    
    if radius > 0:
        mask = Image.new("L", (w, h), 0)
        m_draw = ImageDraw.Draw(mask)
        m_draw.rounded_rectangle([0, 0, w, h], radius=radius, fill=255)
        img.paste(grad, (int(x0), int(y0)), mask)
    else:
        img.paste(grad, (int(x0), int(y0)))

def draw_art_frame(draw: ImageDraw.ImageDraw, img: Image.Image, xy, theme_key: str, rarity: str = "common"):
    x0, y0, x1, y1 = xy
    w = x1 - x0
    h = y1 - y0
    cx = (x0 + x1) / 2.0
    cy = (y0 + y1) / 2.0

    theme = TYPE_THEMES.get(theme_key, TYPE_THEMES["deck"])
    t_colors = TIER_COLORS.get(rarity.lower(), TIER_COLORS["common"])

    # Background art gradient
    bg_top = theme["gradient"][0]
    bg_bot = theme["gradient"][1]
    draw_gradient_rect(img, (x0, y0, x1, y1), bg_top, bg_bot, radius=12)

    # Stylized Art Backdrop (mandala / geometric rings / runes / silhouettes)
    art_img = Image.new("RGBA", (int(w), int(h)), (0, 0, 0, 0))
    a_draw = ImageDraw.Draw(art_img)
    acx = w / 2.0
    acy = h / 2.0

    accent = theme["accent"]
    accent_a = (accent[0], accent[1], accent[2], 60)
    accent_light = (accent[0], accent[1], accent[2], 120)

    # Outer decorative ring
    r_outer = min(w, h) * 0.42
    a_draw.ellipse([acx - r_outer, acy - r_outer, acx + r_outer, acy + r_outer], outline=accent_a, width=2)
    
    # Inner decorative ring
    r_inner = r_outer * 0.65
    a_draw.ellipse([acx - r_inner, acy - r_inner, acx + r_inner, acy + r_inner], outline=accent_light, width=2)

    # Radial spokes / diamond star
    num_spokes = 8
    for i in range(num_spokes):
        angle = (i * 2 * math.pi) / num_spokes
        px0 = acx + math.cos(angle) * (r_inner * 0.3)
        py0 = acy + math.sin(angle) * (r_inner * 0.3)
        px1 = acx + math.cos(angle) * (r_outer * 0.95)
        py1 = acy + math.sin(angle) * (r_outer * 0.95)
        a_draw.line([(px0, py0), (px1, py1)], fill=accent_a, width=1)

    # Center diamond glyph
    d_size = r_inner * 0.5
    diamond = [
        (acx, acy - d_size),
        (acx + d_size, acy),
        (acx, acy + d_size),
        (acx - d_size, acy)
    ]
    a_draw.polygon(diamond, fill=(accent[0], accent[1], accent[2], 40), outline=accent_light, width=2)

    # Category icon / symbol in center
    icon_font = get_font(36, bold=True)
    icon_char = theme.get("icon", "*")
    bbox = icon_font.getbbox(icon_char)
    iw = bbox[2] - bbox[0]
    ih = bbox[3] - bbox[1]
    a_draw.text((acx - iw / 2, acy - ih / 2 - 2), icon_char, fill=(255, 255, 255, 220), font=icon_font)

    # Inner art box corner filigree
    corner_size = 14
    for cx_c, cy_c in [(0, 0), (w, 0), (0, h), (w, h)]:
        sgn_x = 1 if cx_c == 0 else -1
        sgn_y = 1 if cy_c == 0 else -1
        a_draw.line([(cx_c, cy_c + sgn_y * corner_size), (cx_c + sgn_x * corner_size, cy_c)], fill=t_colors["accent"], width=2)

    img.paste(art_img, (int(x0), int(y0)), art_img)

    # Art frame border
    draw.rounded_rectangle([x0, y0, x1, y1], radius=12, outline=t_colors["border"], width=2)


def wrap_text(text: str, font: ImageFont.FreeTypeFont, max_width: int) -> list:
    words = text.split()
    lines = []
    current_line = []

    for word in words:
        test_line = " ".join(current_line + [word])
        bbox = font.getbbox(test_line)
        w = bbox[2] - bbox[0]
        if w <= max_width:
            current_line.append(word)
        else:
            if current_line:
                lines.append(" ".join(current_line))
                current_line = [word]
            else:
                lines.append(word)
                current_line = []
    if current_line:
        lines.append(" ".join(current_line))
    return lines


def render_card(card_data: dict, output_path: str):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    img = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Determine theme and rarity
    category = card_data.get("category", "deck").lower()
    rarity = card_data.get("rarity", "common").lower()
    if rarity not in TIER_COLORS:
        rarity = "common"
    
    t_colors = TIER_COLORS[rarity]
    theme = TYPE_THEMES.get(category, TYPE_THEMES["deck"])

    # 1. Base Card Body
    pad = 8
    card_rect = [pad, pad, CARD_W - pad, CARD_H - pad]
    radius = 24

    # Background gradient for whole card
    draw_gradient_rect(img, card_rect, t_colors["frame_bg"], (12, 10, 14), radius=radius)

    # Ornate Outer Border
    draw.rounded_rectangle(card_rect, radius=radius, outline=t_colors["border"], width=3)
    inner_rect = [pad + 4, pad + 4, CARD_W - pad - 4, CARD_H - pad - 4]
    draw.rounded_rectangle(inner_rect, radius=radius - 2, outline=(t_colors["border"][0]//2, t_colors["border"][1]//2, t_colors["border"][2]//2), width=1)

    # 2. Card Header
    header_h = 70
    hx0, hy0, hx1, hy1 = pad + 10, pad + 10, CARD_W - pad - 10, pad + 10 + header_h
    draw_gradient_rect(img, (hx0, hy0, hx1, hy1), t_colors["header_bg"], (20, 18, 22), radius=10)
    draw.rounded_rectangle([hx0, hy0, hx1, hy1], radius=10, outline=t_colors["accent"], width=1)

    # Title
    title_font = get_font(24, bold=True)
    title_text = str(card_data.get("name", "Card Name"))
    # Truncate if too long
    while title_font.getbbox(title_text)[2] > (hx1 - hx0 - 90) and len(title_text) > 8:
        title_text = title_text[:-4] + "..."
    
    draw.text((hx0 + 16, hy0 + 10), title_text, fill=(255, 255, 255), font=title_font)

    # Subtitle / Category
    sub_font = get_font(13, italic=True)
    sub_text = str(card_data.get("type", category.capitalize()))
    draw.text((hx0 + 16, hy0 + 42), sub_text, fill=theme["accent"], font=sub_font)

    # Header Badges (Cost / Tier / Level)
    cost = card_data.get("cost")
    level = card_data.get("level")
    tier_num = card_data.get("tier")
    badge_text = ""
    if level is not None:
        badge_text = f"LVL {level}"
    elif cost is not None:
        badge_text = f"{cost} CE" if isinstance(cost, int) else str(cost)
    elif tier_num is not None:
        badge_text = f"T{tier_num}"
    elif rarity != "common":
        badge_text = rarity.upper()[:3]
    
    if badge_text:
        b_font = get_font(14, bold=True)
        bw = b_font.getbbox(badge_text)[2] + 16
        bx0 = hx1 - bw - 12
        by0 = hy0 + 16
        bx1 = hx1 - 12
        by1 = hy0 + 50
        draw.rounded_rectangle([bx0, by0, bx1, by1], radius=6, fill=t_colors["badge"], outline=t_colors["accent"], width=1)
        draw.text((bx0 + 8, by0 + 7), badge_text, fill=(255, 255, 255), font=b_font)

    # 3. Card Art Window
    art_y0 = hy1 + 10
    art_h = 240
    art_rect = (pad + 14, art_y0, CARD_W - pad - 14, art_y0 + art_h)
    draw_art_frame(draw, img, art_rect, theme_key=category, rarity=rarity)

    # 4. Ribbon Divider
    ribbon_y = art_y0 + art_h + 10
    rx0, ry0, rx1, ry1 = pad + 14, ribbon_y, CARD_W - pad - 14, ribbon_y + 32
    draw.rounded_rectangle([rx0, ry0, rx1, ry1], radius=6, fill=(22, 20, 26), outline=t_colors["border"], width=1)
    
    ribbon_font = get_font(13, bold=True)
    type_display = card_data.get("rarity", rarity).upper() + " • " + card_data.get("type", category.title()).upper()
    draw.text((rx0 + 14, ry0 + 7), type_display, fill=t_colors["accent"], font=ribbon_font)

    vp_val = card_data.get("vp")
    if vp_val:
        vp_font = get_font(13, bold=True)
        vp_str = f"★ {vp_val} VP"
        vpw = vp_font.getbbox(vp_str)[2]
        draw.text((rx1 - vpw - 14, ry0 + 7), vp_str, fill=(255, 220, 90), font=vp_font)

    # 5. Text Box / Rules & Flavor
    text_y0 = ry1 + 10
    text_h = 300
    tx0, ty0, tx1, ty1 = pad + 14, text_y0, CARD_W - pad - 14, text_y0 + text_h
    draw_gradient_rect(img, (tx0, ty0, tx1, ty1), (18, 16, 22), (10, 8, 12), radius=10)
    draw.rounded_rectangle([tx0, ty0, tx1, ty1], radius=10, outline=(60, 55, 65), width=1)

    curr_y = ty0 + 14
    max_text_w = (tx1 - tx0) - 28

    # Rules / Description
    desc_font = get_font(16, bold=False)
    desc_text = card_data.get("description", card_data.get("desc", ""))
    if desc_text:
        lines = wrap_text(desc_text, desc_font, max_text_w)
        for line in lines:
            if curr_y + 22 > ty1 - 60:
                break
            draw.text((tx0 + 14, curr_y), line, fill=(235, 235, 240), font=desc_font)
            curr_y += 24
        curr_y += 10

    # Perks / Special Mechanics
    perks = card_data.get("perk_summary") or card_data.get("special")
    if perks:
        p_font = get_font(14, bold=True)
        p_lines = wrap_text(f"Effect: {perks}", p_font, max_text_w)
        for line in p_lines:
            if curr_y + 20 > ty1 - 45:
                break
            draw.text((tx0 + 14, curr_y), line, fill=t_colors["accent"], font=p_font)
            curr_y += 20
        curr_y += 8

    # Flavor / Lore text
    flavor = card_data.get("flavor") or card_data.get("personality") or card_data.get("lore")
    if flavor and curr_y < ty1 - 40:
        f_font = get_font(13, italic=True)
        f_lines = wrap_text(f'"{flavor}"', f_font, max_text_w)
        curr_y = max(curr_y, ty1 - len(f_lines) * 18 - 35)
        for line in f_lines:
            if curr_y + 18 > ty1 - 10:
                break
            draw.text((tx0 + 14, curr_y), line, fill=(160, 155, 165), font=f_font)
            curr_y += 18

    # Karma / Light requirement badge if present
    req = card_data.get("karma_requirement") or card_data.get("requires")
    if req and req != "any":
        req_str = f"Req: {req}"
        r_font = get_font(12, bold=True)
        draw.text((tx0 + 14, ty1 - 24), req_str, fill=(140, 180, 220), font=r_font)

    # 6. Card Footer
    card_id = str(card_data.get("id", card_data.get("item_id", card_data.get("quest_id", "001"))))
    foot_font = get_font(11)
    foot_text = f"ITW #{card_id} • {category.upper()}"
    draw.text((pad + 20, CARD_H - pad - 18), foot_text, fill=(100, 95, 105), font=foot_font)

    # Save
    img.save(output_path, "PNG")


def render_card_back(output_path: str):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    pad = 8
    card_rect = [pad, pad, CARD_W - pad, CARD_H - pad]
    radius = 24

    # Background gradient
    draw_gradient_rect(img, card_rect, (24, 20, 36), (10, 8, 16), radius=radius)

    # Gold filigree outer frame
    draw.rounded_rectangle(card_rect, radius=radius, outline=(215, 175, 75), width=4)
    inner_rect = [pad + 6, pad + 6, CARD_W - pad - 6, CARD_H - pad - 6]
    draw.rounded_rectangle(inner_rect, radius=radius - 2, outline=(130, 95, 35), width=1)
    in2_rect = [pad + 14, pad + 14, CARD_W - pad - 14, CARD_H - pad - 14]
    draw.rounded_rectangle(in2_rect, radius=radius - 6, outline=(180, 140, 60), width=2)

    # Mystic Mandala Pattern
    cx = CARD_W / 2.0
    cy = CARD_H / 2.0

    mandala = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    m_draw = ImageDraw.Draw(mandala)

    gold = (235, 195, 90, 180)
    gold_dim = (180, 140, 50, 90)
    cyan = (100, 220, 240, 140)

    # Concentric rings
    for r in [220, 180, 140, 100, 60, 30]:
        m_draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=gold_dim, width=2)
    
    # 12-point star compass
    points = 12
    for i in range(points):
        angle = (i * 2 * math.pi) / points
        x0 = cx + math.cos(angle) * 30
        y0 = cy + math.sin(angle) * 30
        x1 = cx + math.cos(angle) * 210
        y1 = cy + math.sin(angle) * 210
        m_draw.line([(x0, y0), (x1, y1)], fill=gold, width=2)

        # Star petal diamonds
        mid_r = 130
        mx = cx + math.cos(angle) * mid_r
        my = cy + math.sin(angle) * mid_r
        m_draw.ellipse([mx - 12, my - 12, mx + 12, my + 12], fill=cyan, outline=gold, width=2)

    # Central Island Emblem
    m_draw.ellipse([cx - 48, cy - 48, cx + 48, cy + 48], fill=(20, 16, 32, 240), outline=gold, width=3)
    
    # Title on Card Back
    font_back = get_font(26, bold=True)
    title_1 = "INTO THE WILD"
    b1 = font_back.getbbox(title_1)
    w1 = b1[2] - b1[0]
    m_draw.text((cx - w1 / 2, cy - 14), title_1, fill=(255, 235, 160), font=font_back)

    sub_back = get_font(13, bold=True)
    title_2 = "A LIVING RPG BOARD GAME"
    b2 = sub_back.getbbox(title_2)
    w2 = b2[2] - b2[0]
    m_draw.text((cx - w2 / 2, cy + 18), title_2, fill=(180, 210, 240), font=sub_back)

    img.paste(mandala, (0, 0), mandala)
    img.save(output_path, "PNG")


def load_json_safe(filename: str):
    path = os.path.join(DATA_DIR, filename)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def generate_all_cards():
    print("=== INTO THE WILD: Card Rendering Engine ===")
    os.makedirs(ASSETS_DIR, exist_ok=True)

    # 0. Render Universal Card Back
    back_path = os.path.join(ASSETS_DIR, "card_back.png")
    print(f"Rendering Card Back -> {back_path}")
    render_card_back(back_path)

    # 1. Action Cards (5 cards x 5 levels = 25 card images)
    print("\n--- Rendering Action Cards ---")
    action_defs = [
        {
            "id": "explore",
            "name": "Explore / Gather",
            "category": "action",
            "type": "Action Card",
            "description": "Move across the island, flip unexplored hexes, and gather elemental resources.",
            "levels": {
                1: "Lvl 1: Standard movement & gathering.",
                2: "Lvl 2: +1 Move speed; +1 common on gathers.",
                3: "Lvl 3: +1 card draw when revealing face-down tiles.",
                4: "Lvl 4: Immune to Tier 2 movement cost penalty.",
                5: "Lvl 5: Master Explorer (double gather without exhaust)."
            },
            "flavor": "Every step uncovers the uncharted pulse of the wild."
        },
        {
            "id": "craft",
            "name": "Building / Craft",
            "category": "craft",
            "type": "Action Card",
            "description": "Craft items, equipment, and shared public buildings across the island.",
            "levels": {
                1: "Lvl 1: Common crafts without workbench.",
                2: "Lvl 2: Crafting discount (1 less common on U recipes).",
                3: "Lvl 3: Can build field benches anywhere.",
                4: "Lvl 4: Rare crafts gain +1 bonus durability.",
                5: "Lvl 5: Legendary craft anywhere without Workshop."
            },
            "flavor": "Shape the raw elements into instruments of survival."
        },
        {
            "id": "creatures",
            "name": "Creatures",
            "category": "creatures",
            "type": "Action Card",
            "description": "Interact with living island creatures (befriend, fight, or exploit).",
            "levels": {
                1: "Lvl 1: Standard creature encounters.",
                2: "Lvl 2: +1 bonus to Fate combat rolls.",
                3: "Lvl 3: Befriend demands cost 1 fewer common.",
                4: "Lvl 4: Tamed familiar (+1 Energy boost).",
                5: "Lvl 5: Master Beast Whisperer."
            },
            "flavor": "The island's beasts sense the heart within your chest."
        },
        {
            "id": "magic",
            "name": "Magic / Learning",
            "category": "magic",
            "type": "Action Card",
            "description": "Cast character signature magic and learn persistent skill perks.",
            "levels": {
                1: "Lvl 1: Character signature ability.",
                2: "Lvl 2: Skill learning costs -1 CE.",
                3: "Lvl 3: Sponsor perk (+1 common upon meditation).",
                4: "Lvl 4: Signature ability costs 0 Energy once per round.",
                5: "Lvl 5: Ascended Magic mastery."
            },
            "flavor": "Channel the ancient ley-lines weaving through the earth."
        },
        {
            "id": "guardian",
            "name": "Guardian / Association",
            "category": "guardian",
            "type": "Action Card",
            "description": "Visit ancient Guardian sites, make offerings, and empower action cards.",
            "levels": {
                1: "Lvl 1: Standard Guardian offerings.",
                2: "Lvl 2: Offerings grant +1 extra VP.",
                3: "Lvl 3: Unlocks Free Action Trading & empowers actions.",
                4: "Lvl 4: Guardian Blessing active (+2 Light).",
                5: "Lvl 5: Sanctum Ascension."
            },
            "flavor": "Pay homage to the island's eternal sentinels."
        }
    ]

    action_dir = os.path.join(ASSETS_DIR, "actions")
    for act in action_defs:
        for lvl in range(1, 6):
            rarity_map = {1: "common", 2: "common", 3: "uncommon", 4: "rare", 5: "legendary"}
            c_data = {
                "id": f"action_{act['id']}_lvl{lvl}",
                "name": act["name"],
                "category": act["category"],
                "type": f"Action (Level {lvl})",
                "level": lvl,
                "rarity": rarity_map[lvl],
                "description": act["description"],
                "perk_summary": act["levels"][lvl],
                "flavor": act["flavor"]
            }
            out_file = os.path.join(action_dir, f"{act['id']}_lvl{lvl}.png")
            render_card(c_data, out_file)
        # Also render standard base card
        out_base = os.path.join(action_dir, f"{act['id']}.png")
        act_base_data = {
            "id": f"action_{act['id']}",
            "name": act["name"],
            "category": act["category"],
            "type": "Action Card",
            "level": 1,
            "rarity": "common",
            "description": act["description"],
            "perk_summary": act["levels"][1],
            "flavor": act["flavor"]
        }
        render_card(act_base_data, out_base)
    print(f"Rendered {len(action_defs) * 6} action card assets.")

    # 2. Deck Cards (20 unique cards)
    print("\n--- Rendering Deck Cards ---")
    deck_cards = load_json_safe("deck.json") or []
    unique_deck = {}
    for c in deck_cards:
        name = c.get("name")
        if name and name not in unique_deck:
            unique_deck[name] = c
    
    deck_dir = os.path.join(ASSETS_DIR, "deck")
    for name, c in unique_deck.items():
        c_type = c.get("type", "Deck")
        cid = c.get("id", name.lower().replace(" ", "_"))
        # Strip trailing numeric index
        clean_id = "_".join(cid.split("_")[:-1]) if cid.split("_")[-1].isdigit() else cid
        
        rarity = "common"
        if "Blessing" in c_type or "Ward" in c_type:
            rarity = "rare"
        elif "Fate" in c_type or "Loot" in c_type:
            rarity = "uncommon"
        elif "Encounter" in c_type:
            rarity = "common"

        c_data = {
            "id": clean_id,
            "name": name,
            "category": "deck",
            "type": c_type,
            "rarity": rarity,
            "description": c.get("description", ""),
            "karma_requirement": c.get("karma_requirement", "any"),
            "flavor": "A twist of island fate waiting in the deck."
        }
        out_file = os.path.join(deck_dir, f"{clean_id}.png")
        render_card(c_data, out_file)
    print(f"Rendered {len(unique_deck)} unique deck card assets.")

    # 3. Event Cards (8 events)
    print("\n--- Rendering Event Cards ---")
    events_data = load_json_safe("events.json") or {}
    events_list = events_data.get("events", [])
    event_dir = os.path.join(ASSETS_DIR, "events")
    for ev in events_list:
        c_data = {
            "id": ev.get("id"),
            "name": ev.get("name"),
            "category": "event",
            "type": "Island Event",
            "rarity": ev.get("rarity", "common"),
            "description": ev.get("desc", ""),
            "perk_summary": f"Effect: {ev.get('type', '').replace('_', ' ').title()} (Amount: {ev.get('amount', 1)})",
            "flavor": "The island stirs with unpredictable winds."
        }
        out_file = os.path.join(event_dir, f"{ev.get('id')}.png")
        render_card(c_data, out_file)
    print(f"Rendered {len(events_list)} event card assets.")

    # 4. Quest Cards (Common and Guardian quests)
    print("\n--- Rendering Quest Cards ---")
    quests_data = load_json_safe("quests.json") or {}
    quest_dir = os.path.join(ASSETS_DIR, "quests")
    
    # Common quests
    for difficulty, q_list in quests_data.get("common", {}).items():
        for q in q_list:
            rarity = "common" if difficulty == "easy" else ("uncommon" if difficulty == "medium" else "rare")
            c_data = {
                "id": q.get("id"),
                "name": q.get("name"),
                "category": "quest",
                "type": f"Common Quest ({difficulty.title()})",
                "rarity": rarity,
                "vp": q.get("vp", 2),
                "description": q.get("desc", ""),
                "flavor": "A communal trial open to all island wanderers."
            }
            out_file = os.path.join(quest_dir, f"{q.get('id')}.png")
            render_card(c_data, out_file)

    # Guardian quests
    for q in quests_data.get("guardian", []):
        c_data = {
            "id": q.get("id"),
            "name": q.get("name"),
            "category": "guardian",
            "type": "Guardian Quest",
            "rarity": "rare",
            "vp": q.get("vp", 3),
            "description": q.get("desc", ""),
            "perk_summary": f"+{q.get('light', 1)} Light reward upon completion",
            "flavor": "A sacred charge bestowed by the island's ancient keepers."
        }
        out_file = os.path.join(quest_dir, f"{q.get('id')}.png")
        render_card(c_data, out_file)
    print(f"Rendered core quest cards.")

    # 5. Skill Cards (10 skills)
    print("\n--- Rendering Skill Cards ---")
    skills_data = load_json_safe("skills.json") or {}
    skills_list = skills_data.get("skills", [])
    skill_dir = os.path.join(ASSETS_DIR, "skills")
    for sk in skills_list:
        c_data = {
            "id": sk.get("id"),
            "name": sk.get("name"),
            "category": "skill",
            "type": "Skill Tree Perk",
            "rarity": sk.get("tier", "common"),
            "cost": sk.get("ce_cost", 3),
            "description": sk.get("desc", ""),
            "requires": ", ".join(sk.get("requires", [])) if sk.get("requires") else None,
            "flavor": f"Requires Meditation. Energy Cost: {sk.get('energy_cost', 0)}"
        }
        out_file = os.path.join(skill_dir, f"{sk.get('id')}.png")
        render_card(c_data, out_file)
    print(f"Rendered {len(skills_list)} skill card assets.")

    # 6. Creature Cards (Canon & Expanded)
    print("\n--- Rendering Creature Cards ---")
    creatures_canon = (load_json_safe("creatures_canon.json") or {}).get("creatures", [])
    creature_dir = os.path.join(ASSETS_DIR, "creatures")
    for cr in creatures_canon:
        tier = cr.get("tier", 1)
        rarity_map = {1: "common", 2: "uncommon", 3: "rare", 4: "legendary"}
        c_data = {
            "id": cr.get("id"),
            "name": cr.get("name"),
            "category": "creatures",
            "type": f"Tier {tier} Creature",
            "rarity": rarity_map.get(tier, "common"),
            "tier": tier,
            "description": f"Light: {cr.get('light_interaction', {}).get('verb', 'Befriend')} -> {cr.get('light_interaction', {}).get('reward', '')}\nDark: {cr.get('dark_interaction', {}).get('verb', 'Fight')} -> {cr.get('dark_interaction', {}).get('reward', '')}",
            "flavor": f"Native of {cr.get('biome', 'the wild')}. Element: {cr.get('element', 'neutral').title()}"
        }
        out_file = os.path.join(creature_dir, f"{cr.get('id')}.png")
        render_card(c_data, out_file)

    # Expanded creatures sample/prominent
    creatures_exp = load_json_safe("creatures_expanded.json") or []
    for cr in creatures_exp:
        tier = cr.get("tier", 1)
        rarity_map = {1: "common", 2: "uncommon", 3: "rare", 4: "legendary"}
        cid = cr.get("id", "")
        if not cid:
            continue
        c_data = {
            "id": cid,
            "name": cr.get("name", "Wild Creature"),
            "category": "creatures",
            "type": f"Tier {tier} Beast",
            "rarity": rarity_map.get(tier, "common"),
            "tier": tier,
            "description": cr.get("description", ""),
            "perk_summary": f"Field Move: {cr.get('field_move', '')}",
            "flavor": f"Biomes: {', '.join(cr.get('biomes', []))}"
        }
        out_file = os.path.join(creature_dir, f"{cid}.png")
        render_card(c_data, out_file)
    print(f"Rendered creature card assets.")

    # 7. Item Cards (150 items across gear, tools, consumables, weapons, wards)
    print("\n--- Rendering Item Cards ---")
    items_list = load_json_safe("items.json") or []
    item_dir = os.path.join(ASSETS_DIR, "items")
    for it in items_list:
        iid = it.get("item_id", "")
        if not iid:
            continue
        props = it.get("properties", {})
        prop_str = ", ".join([f"{k}: {v}" for k, v in props.items()]) if props else ""
        c_data = {
            "id": iid,
            "name": it.get("name", "Item"),
            "category": "item",
            "type": it.get("type", "Equipment"),
            "rarity": it.get("rarity", "common").lower(),
            "description": it.get("desc", it.get("description", f"Crafted {it.get('type', 'gear')} item.")),
            "perk_summary": prop_str if prop_str else None,
            "flavor": f"Weight: {it.get('weight', 1)} slot(s)."
        }
        out_file = os.path.join(item_dir, f"{iid}.png")
        render_card(c_data, out_file)
    print(f"Rendered {len(items_list)} item card assets.")

    # 8. Character Cards (4 player identities)
    print("\n--- Rendering Character Cards ---")
    chars_data = (load_json_safe("characters.json") or {}).get("characters", [])
    char_dir = os.path.join(ASSETS_DIR, "characters")
    for ch in chars_data:
        cid = ch.get("id", "")
        perk = ch.get("perk", {})
        weakness = ch.get("weakness", {})
        c_data = {
            "id": cid,
            "name": ch.get("name", "Wanderer"),
            "category": "character",
            "type": "Player Character",
            "rarity": "rare",
            "description": f"Perk: {perk.get('name', '')} — {perk.get('desc', '')}\nWeakness: {weakness.get('name', '')} — {weakness.get('desc', '')}",
            "personality": ch.get("personality", ""),
            "flavor": f"Move: {ch.get('move', 3)} | Pack: {ch.get('pack_size', 4)} | Hand: {ch.get('hand_limit', 7)} | Heart: {ch.get('heart', '')} | Cross: {ch.get('cross', '')}"
        }
        out_file = os.path.join(char_dir, f"{cid}.png")
        render_card(c_data, out_file)
    print(f"Rendered {len(chars_data)} character card assets.")

    print("\n==============================================")
    print("ALL CARDS SUCCESSFULLY RENDERED AS PNG ASSETS!")
    print(f"Target directory: {ASSETS_DIR}")
    print("==============================================")


if __name__ == "__main__":
    generate_all_cards()
