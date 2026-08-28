class_name Duality
## The Path of Duality (player-facing name: the Light track).
## Numbers come from data/canon/duality.json — the lane-tested canon:
## track -10..+10, five bands, an explicit shift table, and the hypocrisy
## penalty (success without giving eats your Care-phase energy gains).

enum Band { MAX_DARK, DARK, NEUTRAL, LIGHT, MAX_LIGHT }

const BAND_IDS: Array[String] = ["max_dark", "dark", "neutral", "light", "max_light"]
const BAND_NAMES: Dictionary = {
	Band.MAX_DARK: "Deep Dark",
	Band.DARK: "Dark",
	Band.NEUTRAL: "Neutral",
	Band.LIGHT: "Light",
	Band.MAX_LIGHT: "Radiant",
}

static var _canon: Dictionary = {}


static func setup(canon: Dictionary) -> void:
	_canon = canon


static func track_min() -> int:
	return int(_canon.get("track", {}).get("min", -10))


static func track_max() -> int:
	return int(_canon.get("track", {}).get("max", 10))


static func band_for(light: int) -> Band:
	var bands: Array = _canon.get("bands", [])
	for b in bands:
		var r: Array = b.get("range", [0, 0])
		if light >= int(r[0]) and light <= int(r[1]):
			var idx := BAND_IDS.find(String(b.get("id", "neutral")))
			if idx >= 0:
				return (idx as Band)
	return Band.NEUTRAL


static func band_name(b: Band) -> String:
	return String(BAND_NAMES.get(b, "Neutral"))


## Delta for a named trigger from the canon shift table (0 if unknown).
static func shift_delta(trigger: String) -> int:
	for s in _canon.get("shifts", []):
		if String(s.get("trigger", "")) == trigger:
			return int(s.get("delta", 0))
	return 0


## Hypocrisy penalty (canon): if VP - Light >= 5, lose 1 Care-phase energy
## gain per full 5 points of disparity. Deep Dark is exempt.
static func hypocrisy_energy_penalty(vp: int, light: int) -> int:
	if band_for(light) == Band.MAX_DARK:
		return 0
	var h: Dictionary = _canon.get("hypocrisy_penalty", {})
	var threshold := int(h.get("threshold", 5))
	var disparity := vp - light
	if disparity < threshold:
		return 0
	return int(floor(float(disparity) / float(threshold)))


## Guardian Gate: the Sanctum/4D ring opens only at MAX_LIGHT (canon band effect).
static func sanctum_open(b: Band) -> bool:
	return b == Band.MAX_LIGHT


## Corrupt Gate (synthesis S3): the Dark path's endgame door opens at MAX_DARK.
static func corrupt_gate_open(b: Band) -> bool:
	return b == Band.MAX_DARK
