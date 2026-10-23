extends RefCounted
# Recipes you can cook at a campfire or in Finn's kitchen. Eating a cooked meal gives a long-lasting
# "well fed" effect (only one meal at a time; a new one replaces the old).
#   needs: [ingredient, count]. fish = any fish, fish_rare/epic/legendary = that rarity or better.

const MEALS := {
	"stew": {"name": "Fish Stew", "dur": 90.0, "regen": 4.0, "desc": "Regenerate 1 HP every 4 seconds"},
	"soup": {"name": "Mushroom Soup", "dur": 90.0, "mana": 3.0, "desc": "Mana recharges 3x faster"},
	"plate": {"name": "Steak Plate", "dur": 90.0, "dmg": 2, "desc": "+2 sword damage"},
	"pie": {"name": "Garden Pie", "dur": 90.0, "def": 2, "desc": "+2 defense"},
	"skewers": {"name": "Golden Skewers", "dur": 90.0, "dmg": 1, "regen": 5.0, "desc": "+1 damage and regenerate 1 HP every 5 seconds"},
	"sashimi": {"name": "Moon Sashimi", "dur": 100.0, "dmg": 1, "def": 1, "swift": true, "desc": "+1 damage, +1 defense and faster movement"},
	"feast": {"name": "Dragon Feast", "dur": 150.0, "dmg": 2, "def": 2, "regen": 3.0, "mana": 2.0, "swift": true,
		"desc": "+2 damage, +2 defense, fast regen, faster mana and movement"},
}

const RECIPES := [
	{"meal": "stew", "needs": [["fish", 1], ["mushrooms", 1]]},
	{"meal": "soup", "needs": [["mushrooms", 3]]},
	{"meal": "pie", "needs": [["crops", 3]]},
	{"meal": "plate", "needs": [["steak", 1], ["crops", 1]]},
	{"meal": "skewers", "needs": [["fish_rare", 1], ["meat", 1]]},
	{"meal": "sashimi", "needs": [["fish_epic", 1]]},
	{"meal": "feast", "needs": [["fish_legendary", 1], ["steak", 1], ["crops", 2], ["mushrooms", 1]]},
]

const LABELS := {
	"fish": "fish", "fish_rare": "rare+ fish", "fish_epic": "epic+ fish", "fish_legendary": "legendary fish",
	"mushrooms": "mushrooms", "crops": "crops", "meat": "meat", "steak": "steak",
}


static func have(kind: String) -> int:
	match kind:
		"fish":
			return GameState.fish
		"fish_rare":
			return GameState.fish_at_least("rare")
		"fish_epic":
			return GameState.fish_at_least("epic")
		"fish_legendary":
			return GameState.fish_at_least("legendary")
	return int(GameState.get(kind))


static func can_cook(recipe: Dictionary) -> bool:
	for n in recipe.needs:
		if have(n[0]) < n[1]:
			return false
	return true


static func needs_text(recipe: Dictionary) -> String:
	var parts: Array[String] = []
	for n in recipe.needs:
		parts.append("%d %s" % [n[1], LABELS[n[0]]])
	return " + ".join(parts)


# Uses up the ingredients and starts the meal's effect. Returns false if something is missing.
static func cook(recipe: Dictionary) -> bool:
	if not can_cook(recipe):
		return false
	for n in recipe.needs:
		match n[0]:
			"fish":
				GameState.fish -= n[1]
			"fish_rare":
				GameState.take_fish_at_least("rare", n[1])
			"fish_epic":
				GameState.take_fish_at_least("epic", n[1])
			"fish_legendary":
				GameState.take_fish_at_least("legendary", n[1])
			_:
				GameState.set(n[0], int(GameState.get(n[0])) - n[1])
	GameState.start_meal(recipe.meal)
	return true
