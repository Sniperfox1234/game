extends RefCounted
# Farmhouse upgrade tiers. Bram the builder upgrades the house for wood, stone and gold.
# `rows` are tile indices (roof, roof, wall, windows and door); the house grows wider each tier.

const TIERS := [
	{
		"name": "Cottage", "wood": 0, "stone": 0, "gold": 0, "max_hp": 0,
		"perk": "A cosy start.",
		"rows": [[52, 53, 53, 54], [64, 65, 65, 66], [76, 77, 77, 79], [88, 90, 91, 88]],
	},
	{
		"name": "Big Cottage", "wood": 40, "stone": 0, "gold": 150, "max_hp": 2,
		"perk": "+2 max HP, and a free potion in the pantry every morning.",
		"rows": [
			[52, 53, 53, 53, 53, 54], [64, 65, 65, 65, 65, 66],
			[76, 77, 77, 77, 77, 79], [88, 88, 90, 91, 88, 88],
		],
	},
	{
		"name": "Manor", "wood": 80, "stone": 40, "gold": 500, "max_hp": 4,
		"perk": "+4 max HP, and two free potions every morning.",
		"rows": [
			[48, 49, 49, 49, 49, 49, 49, 50], [60, 61, 61, 61, 61, 61, 61, 62],
			[76, 77, 77, 77, 77, 77, 77, 79], [88, 88, 89, 90, 91, 89, 88, 88],
		],
	},
]


static func tier_data(tier: int) -> Dictionary:
	return TIERS[clampi(tier, 1, TIERS.size()) - 1]


static func can_afford(next: Dictionary) -> bool:
	return GameState.wood >= next.wood and GameState.stone >= next.stone and GameState.gold >= next.gold


# Pays for and applies the next tier. Returns false if you can't afford it or it's already maxed.
static func upgrade() -> bool:
	if GameState.house_tier >= TIERS.size():
		return false
	var next: Dictionary = TIERS[GameState.house_tier]
	if not can_afford(next):
		return false
	GameState.wood -= next.wood
	GameState.stone -= next.stone
	GameState.gold -= next.gold
	GameState.house_tier += 1
	GameState.max_hp = mini(GameState.max_hp + next.max_hp, GameState.MAX_HP_CAP)
	GameState.hp = GameState.max_hp
	GameState.flags["house_new"] = true
	return true
