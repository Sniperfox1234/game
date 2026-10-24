extends RefCounted
# Every dungeon in the game as data. dungeon.gd builds whichever one GameState.dungeon names.
#
# A dungeon has "floors" keyed by floor number, an "exit_scene" and "exit_spawn" (where floor 1's
# west door leads). A floor has:
#   name, theme, light (colour wash), rocks / ore (tile positions), spawns {kind: [tiles]},
#   chest {tile, flag, gold, potions}, stairs (a way down), arena (a boss room), boss {...}.
# Tiles are (x, y) on the 30x22 map.

const BOSS_SPOT := Vector2i(21, 11)
const PILLARS := [Vector2i(5, 5), Vector2i(5, 16), Vector2i(26, 4), Vector2i(26, 17), Vector2i(11, 3), Vector2i(11, 18), Vector2i(17, 3), Vector2i(17, 18)]

# How each kind of dungeon looks and sounds.
const THEMES := {
	"cave": {"floor": "tiles", "ground": Color.WHITE, "rock": Color.WHITE, "torch": Color(1.0, 0.62, 0.25),
		"music": "mus_cave", "ambience": "amb_cave", "ambient": "dust"},
	"frost": {"floor": "ice", "ground": Color(0.75, 0.9, 1.25), "rock": Color(0.7, 0.9, 1.4), "torch": Color(0.65, 0.88, 1.0),
		"music": "mus_frost", "ambience": "amb_wind", "ambient": "snow"},
	"tomb": {"floor": "sand", "ground": Color(1.15, 0.95, 0.7), "rock": Color(1.2, 1.0, 0.7), "torch": Color(1.0, 0.8, 0.35),
		"music": "mus_tomb", "ambience": "amb_cave", "ambient": "sand"},
	"cove": {"floor": "wood", "ground": Color(0.75, 0.82, 0.95), "rock": Color(0.7, 0.8, 0.95), "torch": Color(1.0, 0.7, 0.3),
		"music": "mus_cove", "ambience": "amb_waves", "ambient": "spray"},
	"bog": {"floor": "mud", "ground": Color(0.7, 0.95, 0.7), "rock": Color(0.7, 0.9, 0.7), "torch": Color(0.55, 1.0, 0.55),
		"music": "mus_swamp", "ambience": "amb_swamp", "ambient": "spores"},
}

# What a boss's chest gives you. "chest" is the look of the chest (see PixelArt.royal_chest).
const PRIZES := {
	"king": {
		"title": "Royal Chest", "flag": "royal_chest", "chest": "royal", "gold": 400, "potions": 3, "xp": 150,
		"weapon": "slimeblade", "hat": "slime_crown", "set_flag": "slimeblade",
		"lines": [
			"The lid creaks open and golden light pours out...",
			"You found the SLIMEBLADE! A legendary sword that glows green: +3 damage, longer reach, and its hits can heal you!",
			"You found the SLIME KING'S CROWN! It sparkles with every step.",
			"Plus 400 gold, 3 potions and a rush of experience!",
		],
		"toast": "Slimeblade and Slime King's Crown acquired!",
	},
	"titan": {
		"title": "Frozen Chest", "flag": "frost_chest", "chest": "frost", "gold": 800, "potions": 4, "xp": 400,
		"weapon": "frostaxe", "armor": "glacier", "hat": "frost_crown",
		"lines": [
			"The ice cracks and the lid swings open in a cloud of frost...",
			"You found the TITAN'S FROSTAXE! A giant axe that freezes whatever it hits: +6 damage and a huge swing!",
			"You found GLACIER PLATE! The best armor in the land: +4 defense.",
			"You found the FROST TITAN'S CROWN, and 800 gold, 4 potions and a huge rush of experience!",
		],
		"toast": "Frostaxe, Glacier Plate and the Frost Crown acquired!",
	},
	"pharaoh": {
		"title": "Golden Sarcophagus", "flag": "pharaoh_chest", "chest": "sand", "gold": 900, "potions": 4, "xp": 450,
		"weapon": "khopesh", "armor": "pharaoh_gold", "hat": "pharaoh_crown",
		"lines": [
			"The golden lid slides aside with a groan of ancient stone...",
			"You found the PHARAOH'S KHOPESH! A golden sickle-sword that sets enemies ablaze.",
			"You found PHARAOH'S GOLD, armour fit for a god-king, and the PHARAOH'S NEMES headdress!",
			"Plus 900 gold, 4 potions and a huge rush of experience!",
		],
		"toast": "Khopesh, Pharaoh's Gold and the Nemes acquired!",
	},
	"blackjaw": {
		"title": "Pirate's Hoard", "flag": "blackjaw_chest", "chest": "sea", "gold": 1100, "potions": 4, "xp": 500,
		"weapon": "cutlass", "armor": "captain_coat", "hat": "captain_hat",
		"lines": [
			"The barnacled lid bursts open on a heap of treasure...",
			"You found BLACKJAW'S CUTLASS! A quick blade, and its hits can heal you.",
			"You found the CAPTAIN'S COAT and the CAPTAIN'S HAT!",
			"Plus 1100 gold, 4 potions and a huge rush of experience!",
		],
		"toast": "Cutlass, Captain's Coat and Captain's Hat acquired!",
	},
	"morwen": {
		"title": "Witch's Cauldron Chest", "flag": "morwen_chest", "chest": "bog", "gold": 1200, "potions": 5, "xp": 600,
		"weapon": "witchstaff", "armor": "mossweave", "hat": "witch_hat",
		"lines": [
			"The mossy lid creaks open and green mist pours out...",
			"You found MORWEN'S BOGSTAFF! A gnarled staff whose hits poison what they touch.",
			"You found MOSSWEAVE ROBES and the WITCH'S HAT!",
			"Plus 1200 gold, 5 potions and a huge rush of experience!",
		],
		"toast": "Bogstaff, Mossweave Robes and the Witch's Hat acquired!",
	},
}

const DUNGEONS := {
	"cave": {
		"exit_scene": "res://town.tscn", "exit_spawn": "cave",
		"floors": {
			1: {
				"name": "Cave, floor 1", "theme": "cave", "light": Color(0.72, 0.72, 0.85),
				"rocks": [Vector2i(7, 6), Vector2i(12, 13), Vector2i(15, 5), Vector2i(19, 15), Vector2i(10, 17), Vector2i(23, 7), Vector2i(21, 18), Vector2i(17, 10)],
				"ore": [Vector2i(5, 8), Vector2i(9, 19), Vector2i(13, 3), Vector2i(24, 9), Vector2i(27, 13), Vector2i(6, 15)],
				"spawns": {
					"slime": [Vector2i(8, 4), Vector2i(11, 9), Vector2i(14, 16), Vector2i(17, 7), Vector2i(18, 18), Vector2i(21, 12)],
					"bat": [Vector2i(22, 4), Vector2i(12, 4), Vector2i(24, 16)],
					"goblin": [Vector2i(20, 9), Vector2i(25, 6), Vector2i(25, 15)],
				},
				"chest": {"tile": Vector2i(26, 19), "flag": "chest_1", "gold": 40, "potions": 2},
				"stairs": true,
			},
			2: {
				"name": "Cave, floor 2", "theme": "cave", "light": Color(0.58, 0.58, 0.78),
				"toast": "Floor 2. It's darker and meaner down here...",
				"rocks": [Vector2i(8, 7), Vector2i(11, 15), Vector2i(14, 4), Vector2i(17, 17), Vector2i(19, 9), Vector2i(22, 14), Vector2i(12, 10), Vector2i(23, 5)],
				"ore": [Vector2i(5, 10), Vector2i(10, 5), Vector2i(16, 13), Vector2i(20, 19), Vector2i(25, 17), Vector2i(25, 7), Vector2i(9, 18)],
				"spawns": {
					"goblin": [Vector2i(7, 5), Vector2i(8, 17), Vector2i(12, 12), Vector2i(21, 4)],
					"wizard": [Vector2i(15, 6), Vector2i(16, 18), Vector2i(21, 10)],
					"ghost": [Vector2i(19, 5), Vector2i(18, 14)],
					"ogre": [Vector2i(14, 9), Vector2i(21, 16)],
				},
				"chest": {"tile": Vector2i(27, 4), "flag": "chest_2", "gold": 150, "potions": 3},
				"stairs": true,
				"boss_gate": true,
			},
			3: {
				"name": "The King's Chamber", "theme": "cave", "light": Color(0.5, 0.44, 0.72),
				"rocks": PILLARS, "ore": [], "spawns": {"king": [BOSS_SPOT]},
				"arena": true, "stairs_after_boss": true,
				"boss": {
					"kind": "king", "flag": "boss_defeated", "prize": "king",
					"announce": "WARNING: The King Slime awaits! Heal up, then fight!",
					"quiet": "The chamber is quiet. A stairway of ice leads down at the east end...",
					"defeat": "THE KING SLIME IS DEFEATED!  A royal chest appears, and a frozen stairway opens...",
					"opens_stairs": true, "stairs_label": "FROZEN STAIRS", "stairs_color": Color("a8e4ff"),
					"stairs_sign": [
						"With the King Slime gone, a stairway of ice has opened here.",
						"The Frostfang depths lie below: ice slimes, wraiths and yetis, and something far bigger at the very bottom.",
					],
				},
			},
			4: {
				"name": "Frostfang Hollow", "theme": "frost", "light": Color(0.62, 0.78, 1.0),
				"toast": "Frostfang Hollow. Ice slimes and wraiths slow you down. Keep moving!",
				"rocks": [Vector2i(7, 5), Vector2i(10, 14), Vector2i(14, 7), Vector2i(17, 16), Vector2i(21, 5), Vector2i(23, 12), Vector2i(19, 10), Vector2i(8, 18)],
				"ore": [Vector2i(5, 9), Vector2i(12, 4), Vector2i(15, 18), Vector2i(26, 8), Vector2i(25, 17), Vector2i(9, 11)],
				"spawns": {
					"frostslime": [Vector2i(8, 8), Vector2i(12, 11), Vector2i(15, 15), Vector2i(20, 8), Vector2i(23, 15), Vector2i(17, 4)],
					"frostbat": [Vector2i(10, 6), Vector2i(22, 10), Vector2i(14, 18)],
					"snowgob": [Vector2i(18, 13), Vector2i(24, 6), Vector2i(7, 15)],
					"wraith": [Vector2i(16, 9), Vector2i(21, 17)],
					"yeti": [Vector2i(13, 12), Vector2i(25, 12)],
				},
				"chest": {"tile": Vector2i(27, 19), "flag": "chest_4", "gold": 250, "potions": 3},
				"stairs": true,
			},
			5: {
				"name": "The Frost Titan's Lair", "theme": "frost", "light": Color(0.5, 0.66, 0.95),
				"rocks": PILLARS, "ore": [], "spawns": {"titan": [BOSS_SPOT]},
				"arena": true,
				"boss": {
					"kind": "titan", "flag": "titan_defeated", "prize": "titan",
					"announce": "WARNING: The Frost Titan awakens! Stay out of the red circle!",
					"quiet": "The lair is silent. The Frost Titan is no more.",
					"defeat": "THE FROST TITAN IS DEFEATED!  A frozen chest rises from the ice...",
				},
			},
		},
	},
	"tomb": {
		"exit_scene": "res://desert.tscn", "exit_spawn": "dungeon",
		"floors": {
			1: {
				"name": "Sunken Tomb, floor 1", "theme": "tomb", "light": Color(0.85, 0.78, 0.7),
				"rocks": [Vector2i(7, 6), Vector2i(12, 13), Vector2i(15, 5), Vector2i(19, 15), Vector2i(10, 17), Vector2i(23, 7), Vector2i(21, 18), Vector2i(17, 10)],
				"ore": [Vector2i(5, 8), Vector2i(9, 19), Vector2i(13, 3), Vector2i(24, 9), Vector2i(27, 13), Vector2i(6, 15)],
				"spawns": {
					"scarab": [Vector2i(8, 4), Vector2i(11, 9), Vector2i(14, 16), Vector2i(17, 7), Vector2i(18, 18)],
					"scorpion": [Vector2i(20, 9), Vector2i(25, 6), Vector2i(25, 15), Vector2i(12, 12)],
					"sandwisp": [Vector2i(22, 4), Vector2i(24, 16)],
				},
				"chest": {"tile": Vector2i(26, 19), "flag": "tomb_chest_1", "gold": 90, "potions": 2},
				"stairs": true,
			},
			2: {
				"name": "Sunken Tomb, floor 2", "theme": "tomb", "light": Color(0.7, 0.62, 0.62),
				"toast": "Deeper in the tomb. The air is thick with dust and old curses...",
				"rocks": [Vector2i(8, 7), Vector2i(11, 15), Vector2i(14, 4), Vector2i(17, 17), Vector2i(19, 9), Vector2i(22, 14), Vector2i(12, 10), Vector2i(23, 5)],
				"ore": [Vector2i(5, 10), Vector2i(10, 5), Vector2i(16, 13), Vector2i(20, 19), Vector2i(25, 17), Vector2i(25, 7), Vector2i(9, 18)],
				"spawns": {
					"scarab": [Vector2i(7, 5), Vector2i(12, 12), Vector2i(21, 4)],
					"cursed": [Vector2i(15, 6), Vector2i(16, 18), Vector2i(21, 10)],
					"mummy": [Vector2i(14, 9), Vector2i(21, 16), Vector2i(8, 17)],
					"sandwisp": [Vector2i(19, 5)],
				},
				"chest": {"tile": Vector2i(27, 4), "flag": "tomb_chest_2", "gold": 260, "potions": 3},
				"stairs": true,
				"boss_gate": true,
			},
			3: {
				"name": "The Pharaoh's Sanctum", "theme": "tomb", "light": Color(0.8, 0.62, 0.45),
				"rocks": PILLARS, "ore": [], "spawns": {"pharaoh": [BOSS_SPOT]},
				"arena": true,
				"boss": {
					"kind": "pharaoh", "flag": "pharaoh_defeated", "prize": "pharaoh",
					"announce": "WARNING: The Pharaoh rises! Watch for his shockwaves and spear volleys!",
					"quiet": "The sanctum is silent. The Pharaoh sleeps forever.",
					"defeat": "THE PHARAOH IS DEFEATED!  A golden sarcophagus opens...",
				},
			},
		},
	},
	"cove": {
		"exit_scene": "res://harbor.tscn", "exit_spawn": "dungeon",
		"floors": {
			1: {
				"name": "Smugglers' Cove, floor 1", "theme": "cove", "light": Color(0.78, 0.82, 0.95),
				"rocks": [Vector2i(7, 6), Vector2i(12, 13), Vector2i(15, 5), Vector2i(19, 15), Vector2i(10, 17), Vector2i(23, 7), Vector2i(21, 18), Vector2i(17, 10)],
				"ore": [Vector2i(5, 8), Vector2i(9, 19), Vector2i(13, 3), Vector2i(24, 9), Vector2i(27, 13), Vector2i(6, 15)],
				"spawns": {
					"crab": [Vector2i(8, 4), Vector2i(11, 9), Vector2i(14, 16), Vector2i(17, 7)],
					"pirate": [Vector2i(20, 9), Vector2i(25, 6), Vector2i(25, 15), Vector2i(12, 12)],
					"parrot": [Vector2i(22, 4), Vector2i(12, 4), Vector2i(24, 16)],
				},
				"chest": {"tile": Vector2i(26, 19), "flag": "cove_chest_1", "gold": 120, "potions": 2},
				"stairs": true,
			},
			2: {
				"name": "Smugglers' Cove, floor 2", "theme": "cove", "light": Color(0.62, 0.68, 0.88),
				"toast": "Deeper in the cove. Cannons echo off the wet walls...",
				"rocks": [Vector2i(8, 7), Vector2i(11, 15), Vector2i(14, 4), Vector2i(17, 17), Vector2i(19, 9), Vector2i(22, 14), Vector2i(12, 10), Vector2i(23, 5)],
				"ore": [Vector2i(5, 10), Vector2i(10, 5), Vector2i(16, 13), Vector2i(20, 19), Vector2i(25, 17), Vector2i(25, 7), Vector2i(9, 18)],
				"spawns": {
					"pirate": [Vector2i(7, 5), Vector2i(8, 17), Vector2i(12, 12)],
					"cannoneer": [Vector2i(15, 6), Vector2i(16, 18), Vector2i(21, 10)],
					"crab": [Vector2i(14, 9), Vector2i(21, 16)],
					"parrot": [Vector2i(19, 5)],
				},
				"chest": {"tile": Vector2i(27, 4), "flag": "cove_chest_2", "gold": 300, "potions": 3},
				"stairs": true,
				"boss_gate": true,
			},
			3: {
				"name": "Captain Blackjaw's Quarters", "theme": "cove", "light": Color(0.55, 0.55, 0.78),
				"rocks": PILLARS, "ore": [], "spawns": {"blackjaw": [BOSS_SPOT]},
				"arena": true,
				"boss": {
					"kind": "blackjaw", "flag": "blackjaw_defeated", "prize": "blackjaw",
					"announce": "WARNING: Captain Blackjaw draws his cutlass! Watch his charge!",
					"quiet": "The cabin is quiet. Blackjaw's flag hangs limp.",
					"defeat": "CAPTAIN BLACKJAW IS DEFEATED!  His hoard glitters in the lamplight...",
				},
			},
		},
	},
	"bog": {
		"exit_scene": "res://swamp.tscn", "exit_spawn": "dungeon",
		"floors": {
			1: {
				"name": "Rotting Bog, floor 1", "theme": "bog", "light": Color(0.72, 0.9, 0.72),
				"rocks": [Vector2i(7, 6), Vector2i(12, 13), Vector2i(15, 5), Vector2i(19, 15), Vector2i(10, 17), Vector2i(23, 7), Vector2i(21, 18), Vector2i(17, 10)],
				"ore": [Vector2i(5, 8), Vector2i(9, 19), Vector2i(13, 3), Vector2i(24, 9), Vector2i(27, 13), Vector2i(6, 15)],
				"spawns": {
					"bogslime": [Vector2i(8, 4), Vector2i(11, 9), Vector2i(14, 16), Vector2i(17, 7)],
					"bogdog": [Vector2i(20, 9), Vector2i(25, 6), Vector2i(25, 15)],
					"wisp": [Vector2i(22, 4), Vector2i(24, 16)],
				},
				"chest": {"tile": Vector2i(26, 19), "flag": "bog_chest_1", "gold": 150, "potions": 2},
				"stairs": true,
			},
			2: {
				"name": "Rotting Bog, floor 2", "theme": "bog", "light": Color(0.6, 0.78, 0.65),
				"toast": "Deeper in the bog. Poison hangs in the air. Keep moving!",
				"rocks": [Vector2i(8, 7), Vector2i(11, 15), Vector2i(14, 4), Vector2i(17, 17), Vector2i(19, 9), Vector2i(22, 14), Vector2i(12, 10), Vector2i(23, 5)],
				"ore": [Vector2i(5, 10), Vector2i(10, 5), Vector2i(16, 13), Vector2i(20, 19), Vector2i(25, 17), Vector2i(25, 7), Vector2i(9, 18)],
				"spawns": {
					"zombie": [Vector2i(14, 9), Vector2i(21, 16), Vector2i(8, 17)],
					"wisp": [Vector2i(15, 6), Vector2i(16, 18), Vector2i(21, 10)],
					"bogdog": [Vector2i(7, 5), Vector2i(12, 12), Vector2i(21, 4)],
					"bogslime": [Vector2i(19, 5)],
				},
				"chest": {"tile": Vector2i(27, 4), "flag": "bog_chest_2", "gold": 330, "potions": 3},
				"stairs": true,
				"boss_gate": true,
			},
			3: {
				"name": "Morwen's Lair", "theme": "bog", "light": Color(0.5, 0.75, 0.55),
				"rocks": PILLARS, "ore": [], "spawns": {"morwen": [BOSS_SPOT]},
				"arena": true,
				"boss": {
					"kind": "morwen", "flag": "morwen_defeated", "prize": "morwen",
					"announce": "WARNING: Witch Morwen cackles! Avoid the poison pools!",
					"quiet": "The lair is still. Morwen's cauldron has gone cold.",
					"defeat": "WITCH MORWEN IS DEFEATED!  Her cauldron chest bubbles open...",
				},
			},
		},
	},
}
