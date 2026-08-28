class_name Rage
## Island Rage — a SHARED track 0..10 (canon/rage.json). The island itself
## keeps score: +1 every round (temporal pressure), + exploits and dark acts;
## soothed by Guardian quest steps and giving back.
## High Rage makes every fight harder and setbacks meaner — for everyone.

static var _canon: Dictionary = {}


static func setup(canon: Dictionary) -> void:
	_canon = canon


static func track_max() -> int:
	return int(_canon.get("track", {}).get("max", 10))


static func delta_for(trigger: String) -> int:
	for f in _canon.get("faucets", []):
		if String(f.get("trigger", "")) == trigger:
			return int(f.get("delta", 0))
	for s in _canon.get("sinks", []):
		if String(s.get("trigger", "")) == trigger:
			return int(s.get("delta", 0))
	return 0


## Extra F added to every creature fight at this Rage level.
static func f_bonus(rage: int) -> int:
	for row in _canon.get("fight_modifier", []):
		var r: Array = row.get("range", [0, 0])
		if rage >= int(r[0]) and rage <= int(r[1]):
			return int(row.get("f_bonus", 0))
	return 0


## Extra discards suffered on setbacks at this Rage level.
static func setback_discard(rage: int) -> int:
	for row in _canon.get("setback_discard", []):
		var r: Array = row.get("range", [0, 0])
		if rage >= int(r[0]) and rage <= int(r[1]):
			return int(row.get("extra_discard", 0))
	return 0
