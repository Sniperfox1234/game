extends RefCounted
# Hats (cosmetic) and armor (reduces damage) sold at Mara's outfitter.
# Hat rows are 16-wide pixel rows drawn over the hero's head starting at row y0 (can be negative).
# O is the sprite outline, A the hat's main colour, B its accent.

const HATS := {
	"straw": {
		"name": "Straw Hat", "price": 30, "y0": 0, "a": Color("e2c75a"), "b": Color("b8963a"),
		"rows": [
			"................",
			"....OAAAAAAO....",
			"..OOBBBBBBBBOO..",
		],
	},
	"cap": {
		"name": "Red Cap", "price": 60, "y0": 0, "a": Color("d64545"), "b": Color("a02c2c"),
		"rows": [
			"................",
			"....OAAAAAAO....",
			"...OAAAAAAAAO...",
			"...OBBBBBBBBO...",
		],
	},
	"wizard": {
		"name": "Wizard Hat", "price": 150, "y0": -3, "a": Color("5b3fa0"), "b": Color("f2c14e"),
		"rows": [
			".......OO.......",
			"......OAAO......",
			".....OAAAAO.....",
			"....OAAAAAAO....",
			"...OBBBBBBBBO...",
			"..OOAAAAAAAAOO..",
		],
	},
	"viking": {
		"name": "Viking Helm", "price": 220, "y0": -1, "a": Color("9aa5b5"), "b": Color("f5f5f5"),
		"rows": [
			"..B..........B..",
			"..BOAAAAAAAAOB..",
			"...OAAAAAAAAO...",
			"...OOOOOOOOOO...",
		],
	},
	"archer": {
		"name": "Feathered Cap", "price": 0, "unique": true, "y0": -2, "a": Color("4f9d4f"), "b": Color("e84a5f"),
		"rows": [
			"..........OBO...",
			"....OAAAAAABO...",
			"...OAAAAAAAAO...",
			"...OAAAAAAAAO...",
			"..OOOOOOOOOOOO..",
		],
	},
	"slime_crown": {
		"name": "Slime King's Crown", "price": 0, "unique": true, "y0": -2, "a": Color("f2c14e"), "b": Color("5de08a"),
		"rows": [
			"....O..OO..O....",
			"....OAOAAOAO....",
			"....OAABBAAO....",
			"...OAAAAAAAAO...",
			"...OBBBBBBBBO...",
		],
	},
	"crown": {
		"name": "Golden Crown", "price": 400, "y0": -1, "a": Color("f2c14e"), "b": Color("e84a5f"),
		"rows": [
			"....O..OO..O....",
			"....OAOAAOAO....",
			"....OAABBAAO....",
			"....OOOOOOOO....",
		],
	},
}

# `torso` and `legs` replace the shirt and pants colours; `trim` colours the shoulders and gloves.
const ARMOR := {
	"leather": {
		"name": "Leather Vest", "price": 100, "def": 1,
		"torso": Color("8a5a2b"), "legs": Color("5a3b1e"), "trim": Color("5a3b1e"),
	},
	"chain": {
		"name": "Chain Mail", "price": 260, "def": 2,
		"torso": Color("a9b3c1"), "legs": Color("6b7685"), "trim": Color("6b7685"),
	},
	"plate": {
		"name": "Plate Armor", "price": 600, "def": 3,
		"torso": Color("d7dde6"), "legs": Color("8c97a8"), "trim": Color("f2c14e"),
	},
}
