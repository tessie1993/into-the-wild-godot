class_name Crafting
## v2 crafting against the CE-legal recipes (data/recipes.json).
## Cost model: cost.commons {id:n} + cost.any_commons n + cost.any_cards {tier:n}.
## Bench gating per canon/crafting.json: Uncommon+ needs a bench (Homebase) on
## your tile; Legendary needs bench + Workshop.
## PERK — Blacksmith "Durable Construction": one common cost reduced by 1
## (total spend never below 1).


static func bench_ok(recipe: Dictionary, tile_has_bench: bool, tile_has_workshop: bool) -> bool:
	var tier := String(recipe.get("tier", "common"))
	if tier == "common":
		return true
	if tier == "legendary":
		return tile_has_bench and tile_has_workshop
	return tile_has_bench


static func can_craft(recipe: Dictionary, p: PlayerState) -> bool:
	var cost: Dictionary = recipe.get("cost", {})
	var discount := _discount(recipe, p)
	var fixed: Dictionary = cost.get("commons", {})
	var pouch: Dictionary = p.commons.duplicate()
	for id in fixed.keys():
		var need := int(fixed[id])
		if discount > 0 and need > 0:
			need -= 1
			discount = 0
		if int(pouch.get(id, 0)) < need:
			return false
		pouch[id] = int(pouch.get(id, 0)) - need
	var any_n := int(cost.get("any_commons", 0))
	if discount > 0 and any_n > 0:
		any_n -= 1
	var loose := 0
	for id in pouch.keys():
		loose += int(pouch[id])
	if loose < any_n:
		return false
	var need_cards: Dictionary = cost.get("any_cards", {})
	for tier in need_cards.keys():
		var have := 0
		for c in p.cards:
			if String(c.get("tier", "")) == String(tier):
				have += 1
		if have < int(need_cards[tier]):
			return false
	return true


## Spends the cost and adds the result. Buildings are returned as "building"
## so the caller can place them on the tile instead of the pack.
static func craft(recipe: Dictionary, p: PlayerState, rng: RandomNumberGenerator) -> String:
	if not can_craft(recipe, p):
		return ""
	if String(recipe.get("kind", "item")) == "item" and p.items.size() >= p.pack_size:
		return ""  # pack full — refuse BEFORE spending materials
	var cost: Dictionary = recipe.get("cost", {})
	var discount := _discount(recipe, p)
	var fixed: Dictionary = cost.get("commons", {})
	for id in fixed.keys():
		var need := int(fixed[id])
		if discount > 0 and need > 0:
			need -= 1
			discount = 0
		p.spend_common(String(id), need)
	var any_n := int(cost.get("any_commons", 0))
	if discount > 0 and any_n > 0:
		any_n -= 1
	p.spend_any_commons(any_n, rng)
	var need_cards: Dictionary = cost.get("any_cards", {})
	for tier in need_cards.keys():
		for i in int(need_cards[tier]):
			p.remove_card_of_tier(String(tier))
	var kind := String(recipe.get("kind", "item"))
	if kind == "item":
		if p.items.size() < p.pack_size:
			p.items.append(String(recipe["id"]))
		else:
			return ""  # pack full; caller should have checked
	return kind


static func _discount(recipe: Dictionary, p: PlayerState) -> int:
	if p.character_id != "blacksmith":
		return 0
	var cost: Dictionary = recipe.get("cost", {})
	var total := int(cost.get("any_commons", 0))
	var fixed: Dictionary = cost.get("commons", {})
	for id in fixed.keys():
		total += int(fixed[id])
	return 1 if total > 1 else 0


static func cost_text(recipe: Dictionary, decks: Decks) -> String:
	var parts: Array = []
	var cost: Dictionary = recipe.get("cost", {})
	var fixed: Dictionary = cost.get("commons", {})
	for id in fixed.keys():
		parts.append("%dx %s" % [int(fixed[id]), decks.display_name_of(String(id))])
	var any_n := int(cost.get("any_commons", 0))
	if any_n > 0:
		parts.append("%dx any common" % any_n)
	var need_cards: Dictionary = cost.get("any_cards", {})
	for tier in need_cards.keys():
		parts.append("%dx %s card" % [int(need_cards[tier]), String(tier)])
	return ", ".join(parts)
