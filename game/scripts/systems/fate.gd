class_name Fate
extends RefCounted
## The Fate Deck — the game's only gamble (canon/fate.json):
## 12 cards: [1,2,2,3,3,4,4,5,5,6] + 2 Spirit/Wild.
## Synthesis ruling S2: a Wild is NOT an auto-win — it resolves to a value
## set by your current Duality band (max_dark 1 .. max_light 5).
## Kindness literally changes your luck. Digital parity: identical distribution.

const WILD_BY_BAND: Dictionary = {
	Duality.Band.MAX_DARK: 1,
	Duality.Band.DARK: 2,
	Duality.Band.NEUTRAL: 3,
	Duality.Band.LIGHT: 4,
	Duality.Band.MAX_LIGHT: 5,
}

var _pile: Array = []
var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator, canon: Dictionary) -> void:
	_rng = rng
	_reset(canon)


func _reset(canon: Dictionary) -> void:
	_pile.clear()
	for v in canon.get("values", [1, 2, 2, 3, 3, 4, 4, 5, 5, 6]):
		_pile.append(int(v))
	for s in canon.get("specials", []):
		for i in int(s.get("count", 2)):
			_pile.append("wild")
	_shuffle()


func _shuffle() -> void:
	for i in range(_pile.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: Variant = _pile[i]
		_pile[i] = _pile[j]
		_pile[j] = tmp


## Draw one fate card. Returns {value:int, wild:bool}. Reshuffles when spent.
func draw(band: Duality.Band, canon: Dictionary) -> Dictionary:
	if _pile.is_empty():
		_reset(canon)
	var card: Variant = _pile.pop_back()
	if card is String:
		return {"value": int(WILD_BY_BAND.get(band, 3)), "wild": true}
	return {"value": int(card), "wild": false}
