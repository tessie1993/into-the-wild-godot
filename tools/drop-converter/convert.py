#!/usr/bin/env python3
"""Convert the design-lane generated content drops into engine-legal game data.

Reads  docs/design-lane/generated/{creatures,deck,items,quests}.json  (verbatim
design-lane output) and writes game/data/{creatures_wild,wild_deck,items_catalog,
quests_bottleneck}.json in the schemas the Godot engine loads.

The drops were generated against an 8-biome world with their own resource ids
and VP/Light numbers on a different scale than canon. This script is the
"debug" step: every id is mapped onto something the engine actually has, and
every number is rescaled to the canon ranges (VP 0-20, Light -10..+10 — see
docs/design-lane/reviews/Q6.md for why the scales must match).

Deterministic: run it again and the outputs are byte-identical.
"""
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
SRC = os.path.join(ROOT, "docs", "design-lane", "generated")
DST = os.path.join(ROOT, "game", "data")

# biome (drop world) -> element (game world)
BIOME_ELEMENT = {
    "wooded_lake": "wood",
    "grasslands": "grain",
    "rocky_ridge": "stone",
    "volcano": "stone",
    "desert": "grain",
    "sinking_bog": "ether",
    "frost_peak": "water",
    "ancient_ruins": "spirit",
}
# drop tier (1/2/3) -> canon creature tier + F number (canon F guide: C 3-4, U 4-5, R 5-7)
TIER = {1: ("common", 3), 2: ("uncommon", 5), 3: ("rare", 7)}

# bottleneck giver -> guardian element the quest belongs to
GIVER_ELEMENT = {
    "furnace_heat": "stone",
    "wool_shortage": "grain",
    "ancient_seal": "spirit",
    "cooking_fuel": "wood",
    "ruin_barrier": "ether",
}

# reward rescale divisors (drop VP 10-23 / canon VP source 1-8; drop Light 5-14 / canon shift 1-4)
VP_DIV = 3
LIGHT_DIV = 2
DARK_LIGHT_DIV = 3

RARITY = {"Common": "common", "Uncommon": "uncommon", "Rare": "rare", "Legendary": "legendary"}
# consumable use effects by rarity (energy cap is 5; light bounded per Q6 scale)
CONSUME = {"common": (1, 0), "uncommon": (2, 0), "rare": (2, 1), "legendary": (3, 1)}
# relic offering VP by rarity (canon VP faucet range 1-8)
RELIC_VP = {"common": 2, "uncommon": 3, "rare": 5, "legendary": 8}


def load(name):
    with open(os.path.join(SRC, name)) as f:
        return json.load(f)


def save(name, data):
    path = os.path.join(DST, name)
    with open(path, "w") as f:
        json.dump(data, f, indent=2, sort_keys=False)
        f.write("\n")
    print("wrote", path)


def convert_creatures():
    out = []
    for c in load("creatures.json"):
        element = BIOME_ELEMENT[c["biomes"][0]]
        tier, f = TIER[c["tier"]]
        k = c["karma_interactions"]
        gift_id = k["exalted_light"].get("item_reward", "")
        reward_id = k["harmonious_light"].get("item_reward", "")
        demand_n = int(k["neutral"].get("cost", {}).get("qty", 1))
        take_n = max(1, c["tier"] - 1)
        damage = int(k["exalted_dark"].get("damage", 1))
        entry = {
            "id": c["id"],
            "name": c["name"],
            "element": element,
            "tier": tier,
            "f": f,
            "field_move": c.get("field_move", ""),
            # neutral challenge cost (nonexistent berry ids in the drop) -> any-commons demand
            "demand": {"type": "common", "n": demand_n},
            # exalted gift: pristine_X -> the uncommon card version
            "gift": {"op": "gain_card", "id": gift_id, "tier": "uncommon",
                     "element": element, "desc": k["exalted_light"]["flavor"]},
            # harmonious reward: the plain common
            "reward": {"op": "gain_common", "id": reward_id, "n": 1,
                       "desc": k["harmonious_light"]["flavor"]},
            # dark_aligned take: snatches commons from the pack
            "take": {"op": "lose_common", "n": take_n,
                     "desc": k["dark_aligned"]["flavor"]},
            # exalted_dark attack: drains energy by drop damage
            "bite": {"op": "energy", "n": -damage,
                     "desc": k["exalted_dark"]["flavor"]},
            "flavor": {
                "radiant": k["exalted_light"]["flavor"],
                "kind": k["harmonious_light"]["flavor"],
                "neutral": k["neutral"]["flavor"],
                "shadowed": k["dark_aligned"]["flavor"],
                "dark": k["exalted_dark"]["flavor"],
            },
        }
        out.append(entry)
    save("creatures_wild.json", {
        "_comment": "Wild roster - 50 creatures converted from the design-lane drop "
                    "(docs/design-lane/generated/creatures.json) by tools/drop-converter/convert.py. "
                    "Biomes mapped to elements; gifts/rewards use the drop's resource ids "
                    "(registered in resources_digital.json); demands are any-commons at the "
                    "drop's qty; light_change values are carried by the engine's existing "
                    "band flows, not duplicated here. Regenerate with the converter, do not hand-edit.",
        "creatures": out,
    })


def convert_items():
    items = []
    for it in load("items.json"):
        rarity = RARITY[it["rarity"]]
        t = it["type"].lower()
        entry = {
            "id": it["item_id"],
            "name": it["name"],
            "type": t,
            "rarity": rarity,
            "desc": it["properties"].get("description", ""),
        }
        p = it["properties"]
        if t == "tool":
            # harvest_multiplier applies to the 2-common gather base; durability/25 = uses
            entry["bonus_commons"] = max(1, round(2 * (float(p.get("harvest_multiplier", 1.5)) - 1.0)))
            entry["uses"] = max(2, int(p.get("durability", 75)) // 25)
        elif t == "gear":
            entry["immunity_element"] = BIOME_ELEMENT.get(p.get("immunity", ""), "")
            entry["armor"] = int(p.get("armor_value", 1))
        elif t == "consumable":
            e, l = CONSUME[rarity]
            entry["use_energy"] = e
            entry["use_light"] = l
        elif t == "relic":
            entry["offer_vp"] = RELIC_VP[rarity]
        items.append(entry)
    # the bottleneck-quest reward tokens are relics too, offerable at guardian sites
    for i, tier in enumerate(("t1", "t2", "t3"), start=1):
        items.append({"id": "harmony_token_%s" % tier, "name": "Harmony Token %s" % ("I" * i),
                      "type": "relic", "rarity": ("common", "uncommon", "rare")[i - 1],
                      "offer_vp": (2, 4, 6)[i - 1],
                      "desc": "Proof of a bottleneck trial resolved in harmony."})
        items.append({"id": "shatter_shard_%s" % tier, "name": "Shatter Shard %s" % ("I" * i),
                      "type": "relic", "rarity": ("common", "uncommon", "rare")[i - 1],
                      "offer_vp": (2, 4, 6)[i - 1],
                      "desc": "A cold splinter from a trial resolved by force."})
    save("items_catalog.json", {
        "_comment": "Item catalog - 150 items converted from the design-lane drop "
                    "(docs/design-lane/generated/items.json) plus the 6 bottleneck trial tokens. "
                    "Tools: bonus_commons on Gather for `uses` gathers. Gear: T2 step-cost immunity "
                    "in its element + armor reduces creature bites. Consumables: eaten in the Care "
                    "phase. Relics: consumed by guardian offerings for offer_vp. "
                    "Names are the drop's placeholders. Regenerate with the converter.",
        "items": items,
    })


def convert_deck():
    # 20 unique cards; ops in the engine vocabulary resolved by game.gd
    unique = {}
    for card in load("deck.json"):
        base = card["id"].rsplit("_", 1)[0]
        if base in unique:
            unique[base]["count"] += 1
            continue
        unique[base] = {
            "id": base,
            "name": card["name"],
            "req": card["karma_requirement"],
            "text": card["description"],
            "count": 1,
        }
    OPS = {
        # Action/Fate cards go to the hand and are played from the Wild Cards menu
        "action_double_down": {"kind": "fate", "play": "double_down"},
        "action_unshackled": {"kind": "fate", "play": "unshackled"},
        "action_focus_shift": {"kind": "fate", "play": "focus_shift"},
        "action_swift_step": {"kind": "fate", "play": "swift_step"},
        # Encounters resolve immediately on draw
        "encounter_swamp_ambush": {"kind": "encounter", "ops": [{"op": "creature", "element": "ether"}]},
        "encounter_sinking_quagmire": {"kind": "encounter", "ops": [
            {"op": "unless_heart", "heart": "water", "ops": [{"op": "energy", "n": -2}, {"op": "slow", "n": 1}]}]},
        "encounter_guardian's_whispers": {"kind": "encounter", "ops": [
            {"op": "if_band_kind", "then": [{"op": "draw_ward"}], "else": [{"op": "light", "n": -2}]}]},
        "encounter_raging_tempest": {"kind": "encounter", "ops": [
            {"op": "unless_item", "item": "campfire", "ops": [{"op": "energy", "n": -2}]}]},
        "encounter_ancient_trap": {"kind": "encounter", "ops": [
            {"op": "fate_check", "vs": 4, "fail": [{"op": "craft_lock"}]}]},
        "encounter_mirage": {"kind": "encounter", "ops": [{"op": "mirage", "radius": 2}]},
        "encounter_eclipse": {"kind": "encounter", "ops": [{"op": "dark_aggression", "rounds": 2}]},
        # Loot resolves immediately on draw
        "loot_rich_loom": {"kind": "loot", "ops": [
            {"op": "if_element", "elements": ["wood", "grain"],
             "then": [{"op": "gain_common", "id": "plant_fiber", "n": 3}],
             "else": [{"op": "gain_common", "n": 1}]}]},
        "loot_flint_deposit": {"kind": "loot", "ops": [
            {"op": "if_element", "elements": ["stone"],
             "then": [{"op": "gain_common", "id": "flint", "n": 2}],
             "else": [{"op": "gain_common", "n": 1}]}]},
        "loot_luminous_algae_pool": {"kind": "loot", "ops": [
            {"op": "light", "n": 1}, {"op": "gain_common", "id": "luminous_algae", "n": 2}]},
        "loot_hidden_chest": {"kind": "loot", "ops": [{"op": "chest"}]},
        "loot_scrap_metal_pile": {"kind": "loot", "ops": [
            {"op": "gain_common", "id": "ancient_gear", "n": 2},
            {"op": "gain_card", "id": "copper_ore", "tier": "uncommon", "element": "stone"}]},
        # Wards go to the hand; playing one arms the ward (positive karma only)
        "ward_mist_ward": {"kind": "ward", "ward": "mist_ward", "turns": 3},
        "ward_thermal_cloak_blessing": {"kind": "ward", "ward": "thermal_cloak", "turns": 5},
        "ward_aura_shield": {"kind": "ward", "ward": "aura_shield", "turns": 3},
        "ward_sanctum_key": {"kind": "ward", "ward": "sanctum_key", "turns": 1},
    }
    cards = []
    for base, card in unique.items():
        card.update(OPS[base])
        cards.append(card)
    save("wild_deck.json", {
        "_comment": "The Wild Deck - 200 cards (20 unique) converted from the design-lane drop "
                    "(docs/design-lane/generated/deck.json). Drawn on tile reveals at "
                    "config.wild.card_chance. fate/ward cards go to the hand; encounter/loot "
                    "resolve on draw. Ops are the engine vocabulary in game.gd/_apply_wild_ops. "
                    "Regenerate with the converter.",
        "cards": cards,
    })


def convert_quests():
    out = []
    for q in load("quests.json"):
        lp, dp = q["light_path"], q["dark_path"]
        out.append({
            "id": q["quest_id"],
            "title": q["title"],
            "giver": q["giver_npc"],
            "element": GIVER_ELEMENT[q["trigger_bottleneck"]],
            "desc": q["description"],
            "light": {
                "objective": lp["objective"],
                "cost_commons": 5,
                "vp": max(1, round(lp["reward"]["vp"] / VP_DIV)),
                "light": max(1, round(lp["reward"]["light"] / LIGHT_DIV)),
                "item": lp["reward"]["items"][0],
            },
            "dark": {
                "objective": dp["objective"],
                "rage": 2,
                "vp": max(1, round(dp["reward"]["vp"] / VP_DIV)),
                "light": min(-1, round(dp["reward"]["light"] / DARK_LIGHT_DIV)),
                "item": dp["reward"]["items"][0],
            },
        })
    save("quests_bottleneck.json", {
        "_comment": "Bottleneck trials - 50 dual-path quests converted from the design-lane drop "
                    "(docs/design-lane/generated/quests.json). Offered at guardian sites, matched "
                    "by element (giver mapping in the converter). Rewards rescaled to canon: "
                    "VP/3, Light/2 (dark Light/3) per reviews/Q6.md. The light path costs "
                    "5 commons (the 'peaceful deposit'); the dark path is free but adds Rage "
                    "and the scaled Light loss. Regenerate with the converter.",
        "quests": out,
    })


if __name__ == "__main__":
    convert_creatures()
    convert_items()
    convert_deck()
    convert_quests()
