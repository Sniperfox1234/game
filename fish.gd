extends RefCounted
# Fish rarities, species, rods, and the catch roll. Faster reflexes and better rods find rarer fish.

const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]

const INFO := {
	"common": {"name": "Common", "price": 6, "color": Color("c9d1d9"), "weight": 55.0, "species": ["Minnow", "Perch", "Sunfish"]},
	"uncommon": {"name": "Uncommon", "price": 14, "color": Color("6bdc7a"), "weight": 28.0, "species": ["Trout", "Bass", "Catfish"]},
	"rare": {"name": "Rare", "price": 32, "color": Color("5aa9ff"), "weight": 12.0, "species": ["Golden Carp", "Pike", "Glowfin"]},
	"epic": {"name": "Epic", "price": 75, "color": Color("c06bff"), "weight": 4.0, "species": ["Crystal Koi", "Moon Eel", "Ruby Trout"]},
	"legendary": {"name": "Legendary", "price": 220, "color": Color("ffb43a"), "weight": 1.0, "species": ["Dragon Koi", "Abyssal Angler", "Sunken Crownfish"]},
}

# Gold for discovering every species of a rarity (claimed at Odo's).
const BOOK_REWARDS := {"common": 30, "uncommon": 60, "rare": 120, "epic": 250, "legendary": 600}

const RODS := [
	{"name": "Wooden Rod", "price": 0, "luck": 0.0},
	{"name": "Silver Rod", "price": 150, "luck": 0.6},
	{"name": "Golden Rod", "price": 500, "luck": 1.3},
]


static func price(rarity: String) -> int:
	return INFO[rarity].price


static func all_species() -> Array:
	var out: Array = []
	for r in RARITIES:
		for s in INFO[r].species:
			out.append(s)
	return out


# `speed_bonus` is 0..1 (how fast you hit Space after the bite); `rod` indexes RODS.
static func roll(speed_bonus: float, rod: int) -> Dictionary:
	var m: float = RODS[clampi(rod, 0, RODS.size() - 1)].luck + speed_bonus
	var weights := {
		"common": INFO.common.weight * maxf(0.4, 1.0 - 0.15 * m),
		"uncommon": INFO.uncommon.weight * (1.0 + 0.5 * m),
		"rare": INFO.rare.weight * (1.0 + m),
		"epic": INFO.epic.weight * (1.0 + 2.0 * m),
		"legendary": INFO.legendary.weight * (1.0 + 3.0 * m),
	}
	var total := 0.0
	for r in RARITIES:
		total += weights[r]
	var pick := randf() * total
	var chosen := "common"
	for r in RARITIES:
		pick -= weights[r]
		if pick <= 0.0:
			chosen = r
			break
	var species: Array = INFO[chosen].species
	return {"rarity": chosen, "species": species[randi() % species.size()]}
