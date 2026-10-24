extends RefCounted
# Swords and axes sold at Tilda's Smithy. A weapon adds damage on top of your sharpening level.
#   dmg: bonus damage    reach: extra reach in px    cd: attack cooldown multiplier (lower is faster)
#   arc: swing width     effect: burn (fire), freeze (slow), shock (chain lightning), drain (heals you)

const SHOP_ORDER := ["iron", "rapier", "flame", "frost", "thunder", "axe"]
const ROYAL_ORDER := ["royal_sword", "lance", "knight_axe"]
const DESERT_ORDER := ["scimitar"]
const HARBOR_ORDER := ["harpoon"]

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
	"royal_sword": {
		"name": "Royal Longsword", "dmg": 5, "reach": 6.0, "cd": 0.9, "arc": 1.1, "price": 1400, "effect": "",
		"color": Color("fff1b8"), "desc": "Forged for the King's own knights. Fast, long and sharp.",
	},
	"lance": {
		"name": "Knight's Lance", "dmg": 4, "reach": 16.0, "cd": 1.1, "arc": 0.5, "price": 1000, "effect": "",
		"color": Color("e8eef5"), "desc": "A very long reach. It hits in a narrow line.",
	},
	"knight_axe": {
		"name": "Executioner's Axe", "dmg": 7, "reach": 7.0, "cd": 1.8, "arc": 1.7, "price": 1800, "effect": "",
		"color": Color("d8d8e8"), "desc": "A monstrous slow swing that hits harder than anything for sale.",
	},
	"scimitar": {
		"name": "Desert Scimitar", "dmg": 3, "reach": 5.0, "cd": 0.7, "arc": 1.2, "price": 650, "effect": "",
		"color": Color("ffd98a"), "desc": "A curved blade that cuts fast.",
	},
	"harpoon": {
		"name": "Sea Harpoon", "dmg": 4, "reach": 13.0, "cd": 1.2, "arc": 0.7, "price": 900, "effect": "",
		"color": Color("9fd8ff"), "desc": "Long reach, made for spearing big things.",
	},
	"khopesh": {
		"name": "Pharaoh's Khopesh", "dmg": 5, "reach": 6.0, "cd": 0.85, "arc": 1.4, "price": 0, "effect": "burn", "unique": true,
		"color": Color("ffc84a"), "desc": "A golden sickle-sword from the tomb. It sets enemies ablaze.",
	},
	"cutlass": {
		"name": "Blackjaw's Cutlass", "dmg": 5, "reach": 5.0, "cd": 0.7, "arc": 1.3, "price": 0, "effect": "drain", "unique": true,
		"color": Color("dfe8f2"), "desc": "A pirate captain's blade. Quick, and hits can heal you.",
	},
	"witchstaff": {
		"name": "Morwen's Bogstaff", "dmg": 4, "reach": 12.0, "cd": 1.0, "arc": 1.0, "price": 0, "effect": "poison", "unique": true,
		"color": Color("9be86a"), "desc": "A gnarled staff from the witch's lair. It poisons what it touches.",
	},
	"frostaxe": {
		"name": "Titan's Frostaxe", "dmg": 6, "reach": 8.0, "cd": 1.4, "arc": 1.7, "price": 0, "effect": "freeze", "unique": true,
		"color": Color("9fe8ff"), "desc": "Torn from the Frost Titan. A massive, freezing swing.",
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
		"poison":
			return "poisons"
	return ""
