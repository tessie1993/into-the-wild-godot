class_name TradeSystem
extends RefCounted
## Bilateral Trading System (GDD §6.4 & canon/actions.json §4.3).
## Allows players to propose and execute resource/card/item exchanges.
## Computes Crafting Equivalent (CE) parity:
## Common = 1 CE, Uncommon = 3 CE, Rare = 9 CE, Legendary = 27 CE.
## If initiator offers >= 3 CE net surplus to receiver, grants +1 Light (generous trade).

const CE_BY_TIER: Dictionary = {
	"common": 1,
	"uncommon": 3,
	"rare": 9,
	"legendary": 27,
}


## Calculates total CE value of a proposed bundle {commons: {id: count}, cards: [card_indices_or_dicts]}.
static func calculate_bundle_ce(bundle: Dictionary) -> int:
	var total := 0
	var commons: Dictionary = bundle.get("commons", {})
	for cid in commons.keys():
		total += int(commons[cid]) * int(CE_BY_TIER.get("common", 1))
	
	var cards: Array = bundle.get("cards", [])
	for c in cards:
		if c is Dictionary:
			var tier := String((c as Dictionary).get("tier", "common"))
			total += int(CE_BY_TIER.get(tier, 1))
	return total


## Validates whether a player possesses all elements of a proposed bundle.
static func can_fulfill_bundle(p: PlayerState, bundle: Dictionary) -> bool:
	var commons: Dictionary = bundle.get("commons", {})
	for cid in commons.keys():
		if not p.has_common(String(cid), int(commons[cid])):
			return false
	
	var cards: Array = bundle.get("cards", [])
	var p_cards_copy := p.cards.duplicate(true)
	for c in cards:
		if c is Dictionary:
			var card_id := String((c as Dictionary).get("id", ""))
			var found := false
			for i in p_cards_copy.size():
				if String(p_cards_copy[i].get("id", "")) == card_id:
					p_cards_copy.remove_at(i)
					found = true
					break
			if not found:
				return false
	return true


## Executes the bilateral trade between player A and player B.
## Returns {success: bool, generous_a: bool, delta_ce: int, message: String}.
static func execute_trade(p_a: PlayerState, p_b: PlayerState, offer_a: Dictionary, offer_b: Dictionary) -> Dictionary:
	if not can_fulfill_bundle(p_a, offer_a) or not can_fulfill_bundle(p_b, offer_b):
		return {"success": false, "generous_a": false, "delta_ce": 0, "message": "Trade failed: missing materials."}
	
	var ce_a := calculate_bundle_ce(offer_a)
	var ce_b := calculate_bundle_ce(offer_b)
	var delta_ce := ce_a - ce_b
	var generous_a := delta_ce >= 3

	# Transfer A -> B
	_transfer_bundle(p_a, p_b, offer_a)
	# Transfer B -> A
	_transfer_bundle(p_b, p_a, offer_b)

	# Light bonus if generous and within phase rules
	if generous_a and not p_a.care_gift_used:
		var blocked := p_a.character_id == "outcast" and p_a.fought_recently
		if not blocked:
			Game.shift_light(p_a, "gift_card")
		p_a.care_gift_used = true

	if Game.quest_engine != null:
		if ce_a > 0:
			Game.quest_engine.on_gift_given(p_a, p_b, "trade_bundle", false, Game.players.size())
		if ce_b > 0:
			Game.quest_engine.on_gift_given(p_b, p_a, "trade_bundle", false, Game.players.size())

	EventBus.inventory_changed.emit(p_a.index)
	EventBus.inventory_changed.emit(p_b.index)

	return {
		"success": true,
		"generous_a": generous_a,
		"delta_ce": delta_ce,
		"message": "Trade completed successfully (%d CE for %d CE)." % [ce_a, ce_b],
	}


static func _transfer_bundle(from_p: PlayerState, to_p: PlayerState, bundle: Dictionary) -> void:
	var commons: Dictionary = bundle.get("commons", {})
	for cid in commons.keys():
		var count := int(commons[cid])
		from_p.spend_common(String(cid), count)
		to_p.add_common(String(cid), count)
	
	var cards: Array = bundle.get("cards", [])
	for c in cards:
		if c is Dictionary:
			var card_id := String((c as Dictionary).get("id", ""))
			for i in from_p.cards.size():
				if String(from_p.cards[i].get("id", "")) == card_id:
					var card_data: Dictionary = from_p.cards[i]
					from_p.cards.remove_at(i)
					to_p.add_card(card_data)
					break
