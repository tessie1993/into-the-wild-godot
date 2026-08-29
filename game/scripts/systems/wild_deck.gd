class_name WildDeck
extends RefCounted
## The Wild Deck (content drop integration) — 200 cards, 20 unique, four kinds:
## fate (hand, playable), encounter (immediate), loot (immediate), ward (hand,
## playable at Kind+ karma). Definitions live in data/wild_deck.json; draw is a
## shuffled bag that reshuffles when exhausted, so print counts are honored.

var defs: Dictionary = {}       ## id -> card definition
var _bag: Array = []            ## shuffled card ids remaining this cycle
var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator, data: Dictionary) -> void:
	_rng = rng
	for c in data.get("cards", []):
		defs[String(c["id"])] = c
	_reshuffle()


func _reshuffle() -> void:
	_bag.clear()
	for id in defs.keys():
		for i in int(defs[id].get("count", 1)):
			_bag.append(id)
	# Fisher-Yates with the game rng so draws are seed-stable
	for i in range(_bag.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: Variant = _bag[i]
		_bag[i] = _bag[j]
		_bag[j] = tmp


func size_left() -> int:
	return _bag.size()


## Draw the top card definition. Reshuffles the spent deck automatically.
func draw() -> Dictionary:
	if _bag.is_empty():
		_reshuffle()
	if _bag.is_empty():
		return {}
	var id: String = String(_bag.pop_back())
	return defs.get(id, {})


## Draw the first ward card in the bag (Guardian's Whispers blessing draw).
func draw_ward() -> Dictionary:
	if _bag.is_empty():
		_reshuffle()
	for i in _bag.size():
		var d: Dictionary = defs.get(String(_bag[i]), {})
		if String(d.get("kind", "")) == "ward":
			_bag.remove_at(i)
			return d
	# none left in this cycle — take any ward definition
	for id in defs.keys():
		if String(defs[id].get("kind", "")) == "ward":
			return defs[id]
	return {}


func to_dict() -> Dictionary:
	return {"bag": _bag.duplicate()}


func restore(d: Dictionary) -> void:
	var bag: Array = d.get("bag", [])
	if not bag.is_empty():
		_bag = bag.duplicate()
