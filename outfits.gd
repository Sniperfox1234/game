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
	"frost_crown": {
		"name": "Frost Titan's Crown", "price": 0, "unique": true, "y0": -3, "a": Color("bfe8ff"), "b": Color("ffffff"),
		"rows": [
			"....B..BB..B....",
			"....O..OO..O....",
			"....OAOAAOAO....",
			"....OAABBAAO....",
			"...OAAAAAAAAO...",
			"...OBBBBBBBBO...",
		],
	},
	"knight_helm": {
		"name": "Knight's Helm", "price": 500, "y0": -2, "a": Color("aeb8c8"), "b": Color("d63c3c"), "shop": "royal",
		"rows": [
			"......OBBO......",
			"....OOAAAAOO....",
			"...OAAAAAAAAO...",
			"...OAAAAAAAAO...",
			"...OOOOOOOOOO...",
		],
	},
	"pharaoh_crown": {
		"name": "Pharaoh's Nemes", "price": 0, "unique": true, "y0": -1, "a": Color("f2c14e"), "b": Color("2f7ab0"),
		"rows": [
			"....OOOOOOOO....",
			"...OABABABABO...",
			"...OAB....BAO...",
			"...OAB....BAO...",
			"...OAB....BAO...",
		],
	},
	"captain_hat": {
		"name": "Captain's Tricorn", "price": 0, "unique": true, "y0": -1, "a": Color("2c3a6a"), "b": Color("e8c872"),
		"rows": [
			"......OBBO......",
			"...OOOAAAAOOO...",
			"..OAAAABBAAAAO..",
			"...OOOOOOOOOO...",
		],
	},
	"witch_hat": {
		"name": "Morwen's Hat", "price": 0, "unique": true, "y0": -4, "a": Color("2f4a2a"), "b": Color("b8f07a"),
		"rows": [
			".......OO.......",
			"......OAAO......",
			".....OAAAAO.....",
			"....OAAAAAAO....",
			"...OAAAAAAAAO...",
			"...OBBBBBBBBO...",
			"..OOAAAAAAAAOO..",
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
	"royal_plate": {
		"name": "Royal Plate", "price": 1500, "def": 5, "shop": "royal",
		"torso": Color("e8d6a0"), "legs": Color("9a7a3a"), "trim": Color("d63c3c"),
	},
	"nomad": {
		"name": "Nomad Robes", "price": 320, "def": 2, "shop": "desert",
		"torso": Color("e8d9b0"), "legs": Color("b8935a"), "trim": Color("3fa89a"),
	},
	"sailor": {
		"name": "Sailor's Coat", "price": 360, "def": 2, "shop": "harbor",
		"torso": Color("3a5a9a"), "legs": Color("e8e8f0"), "trim": Color("f5f5f5"),
	},
	"pharaoh_gold": {
		"name": "Pharaoh's Gold", "price": 0, "def": 5, "unique": true,
		"torso": Color("f2c14e"), "legs": Color("2f7ab0"), "trim": Color("fff0b0"),
	},
	"captain_coat": {
		"name": "Captain's Coat", "price": 0, "def": 5, "unique": true,
		"torso": Color("8a2a3a"), "legs": Color("2a2a3a"), "trim": Color("e8c872"),
	},
	"mossweave": {
		"name": "Mossweave Robes", "price": 0, "def": 5, "unique": true,
		"torso": Color("4f8a4a"), "legs": Color("2e4a2a"), "trim": Color("b8f07a"),
	},
	"glacier": {
		"name": "Glacier Plate", "price": 0, "def": 4, "unique": true,
		"torso": Color("a8d8ff"), "legs": Color("6fa8d8"), "trim": Color("f2fbff"),
	},
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
