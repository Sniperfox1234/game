extends RefCounted
# Swords and axes sold at Tilda's Smithy. A weapon adds damage on top of your sharpening level.
#   dmg: bonus damage    reach: extra reach in px    cd: attack cooldown multiplier (lower is faster)
#   arc: swing width     effect: burn (fire), freeze (slow), shock (chain lightning), drain (heals you)

const SHOP_ORDER := ["iron", "rapier", "flame", "frost", "thunder", "axe"]

const WEAPONS := {
	"training": {
		"name": "Training Sword", "dmg": 0, "reach": 0.0, "cd": 1.0, "arc": 0.9, "price": 0, "effect": "",
		"color": Color("ffffff"), "desc": "A plain, trusty blade.",
	},
	"iron": {
		"name": "Iron Sword", "dmg": 1, "reach": 2.0, "cd": 1.0, "arc": 0.95, "price": 80, "effect": "",
		"color": Color("dfe6ee"), "desc": "Solid and dependable. +1 damage.",
	},
	"rapier": {
		"name": "Quick Rapier", "dmg": 1, "reach": 5.0, "cd": 0.62, "arc": 0.6, "price": 160, "effect": "",
		"color": Color("f5f5f5"), "desc": "Strikes much faster, with long reach.",
	},
	"flame": {
		"name": "Flame Blade", "dmg": 2, "reach": 3.0, "cd": 1.0, "arc": 1.0, "price": 320, "effect": "burn",
		"color": Color("ff8a2a"), "desc": "Sets enemies on fire. They keep burning after the hit.",
	},
	"frost": {
		"name": "Frost Brand", "dmg": 2, "reach": 3.0, "cd": 1.0, "arc": 1.0, "price": 320, "effect": "freeze",
		"color": Color("7fd8ff"), "desc": "Slows enemies to a crawl so you can keep your distance.",
	},
	"thunder": {
		"name": "Thunder Edge", "dmg": 2, "reach": 3.0, "cd": 1.0, "arc": 1.0, "price": 480, "effect": "shock",
		"color": Color("ffe14a"), "desc": "Lightning jumps to another enemy nearby.",
	},
	"axe": {
		"name": "Battle Axe", "dmg": 4, "reach": 6.0, "cd": 1.7, "arc": 1.6, "price": 420, "effect": "",
		"color": Color("c9d1d9"), "desc": "A huge, slow swing that hits hard and wide.",
	},
	"slimeblade": {
		"name": "Slimeblade", "dmg": 3, "reach": 7.0, "cd": 0.9, "arc": 1.2, "price": 0, "effect": "drain", "unique": true,
		"color": Color("5de08a"), "desc": "Won from the King Slime. Hits can heal you.",
	},
}


static func effect_text(effect: String) -> String:
	match effect:
		"burn":
			return "burns"
		"freeze":
			return "slows"
		"shock":
			return "chain lightning"
		"drain":
			return "heals you"
	return ""
