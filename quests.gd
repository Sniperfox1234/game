extends RefCounted
# Quest data, quest state helpers, and the dialogue each NPC gives for them.
# State lives in GameState.quests: id -> {"state": "active" | "done", "progress": int}.
# A quest's "track" is either "item:<GameState var>" (hand in items) or "kill:<enemy kind>".
# "kill:raider" counts monsters that attack at night.

const ORDER := ["crops", "shrooms", "fish", "raiders", "slimes", "goblins", "boss"]

const DEFS := {
	"crops": {
		"title": "Harvest Help", "giver": "rosa", "needs": "", "goal": 5, "unit": "crops", "track": "item:crops",
		"reward": {"gold": 50},
		"offer": [
			"Welcome to Mossbrook! I'm Rosa, the mayor.",
			"Our pantry is nearly empty. Could you bring me 5 crops from your farm? It's just west of town.",
		],
		"remind": "I still need {n} more crops. Your farm is just west of town.",
		"thanks": ["Wonderful! These will feed the whole village."],
	},
	"shrooms": {
		"title": "Mushroom Soup", "giver": "rosa", "needs": "crops", "goal": 3, "unit": "mushrooms", "track": "item:mushrooms",
		"reward": {"gold": 40, "potions": 1},
		"offer": [
			"I'm making mushroom soup for the harvest festival.",
			"Red mushrooms grow in the grass around the farm and town. Bring me 3? Press Space next to one to pick it.",
		],
		"remind": "{n} more mushrooms, please. Look in the grass around the farm and town.",
		"thanks": ["Perfect! This soup will be delicious."],
	},
	"fish": {
		"title": "Pond Fishing", "giver": "pip", "needs": "", "goal": 3, "unit": "fish", "track": "item:fish",
		"reward": {"gold": 30},
		"offer": [
			"Psst! Wanna catch fish? There's a pond by your farm and another one here in town.",
			"Stand next to the water and press Space. When you see a bite, press Space again, fast!",
			"Bring me 3 fish and I'll give you 30 gold. Don't ask what I'll do with them.",
		],
		"remind": "{n} more fish! Try the pond by your farm or the one in town.",
		"thanks": ["Whoa, real fish! Thanks!"],
	},
	"raiders": {
		"title": "Night Watch", "giver": "pip", "needs": "fish", "goal": 4, "unit": "raiders", "track": "kill:raider",
		"reward": {"gold": 60, "potions": 1},
		"offer": [
			"Monsters sneak out at night and attack the farm and town!",
			"Beat 4 of them after dark and I'll pay you 60 gold and a potion. Sleeping at home skips the night, so be quick.",
		],
		"remind": "{n} more night raiders. They come out when it gets dark.",
		"thanks": ["You scared them off! You're my hero."],
	},
	"slimes": {
		"title": "Slime Trouble", "giver": "gus", "needs": "", "goal": 5, "unit": "slimes", "track": "kill:slime",
		"reward": {"gold": 60, "damage": 1},
		"offer": [
			"Halt! Oh, you're the new farmer. I'm Gus, the town guard.",
			"Slimes have taken over the old cave to the east. Defeat 5 of them and I'll pay you 60 gold.",
			"Press Space or X to swing your sword, and Shift to dash out of the way. Watch your health!",
		],
		"remind": "{n} more slimes to go. Keep at it.",
		"thanks": ["Five slimes down! You're a natural.", "I've sharpened your sword for you. It hits harder now."],
	},
	"goblins": {
		"title": "Goblin Trouble", "giver": "gus", "needs": "slimes", "goal": 4, "unit": "goblins", "track": "kill:goblin",
		"reward": {"gold": 100, "max_hp": 2},
		"offer": [
			"Goblins have moved into the cave. Defeat 4 of them.",
			"They wind up and charge when they spot you. Dash sideways with Shift!",
			"I'll give you 100 gold and a heart charm.",
		],
		"remind": "{n} more goblins. Remember to dodge their charge.",
		"thanks": ["Four goblins! Take this charm, it'll keep you on your feet."],
	},
	"boss": {
		"title": "King of Slime", "giver": "gus", "needs": "goblins", "goal": 1, "unit": "King Slime", "track": "kill:king",
		"reward": {"gold": 250},
		"offer": [
			"There's one more problem...",
			"A huge King Slime lurks in his own chamber at the bottom of the cave. Take the ladders down at the east end of floors 1 and 2.",
			"Defeat it and I'll give you 250 gold, and whatever treasure he guards is yours. Bring potions and food, and be at full health.",
		],
		"remind": "The King Slime is still down there, in the chamber below cave floor 2.",
		"thanks": ["You beat the King Slime?! Mossbrook is saved!"],
	},
}

const IDLE := {
	"rosa": ["Thank you again, {name}. Mossbrook is lucky to have you."],
	"gus": ["The cave is quiet now. Thanks to you."],
	"pip": [
		"Crops take 3 days to grow. Sleep in your house to skip ahead!",
		"Slimes and goblins drop gold, and sometimes a potion.",
		"Gus says the cave goes even deeper than the second floor.",
		"Sell your crops, fish and mushrooms at Mara's stall in the plaza!",
		"I want to be a hero when I grow up. Like you!",
		"Wren at the pet yard gives pets to heroes who are level 3!",
	],
	"captain": [
		"Captain Vale, town watch. Quiet night so far... too quiet.",
		"Armor reduces every hit you take. Brann's Armory has some good sets.",
		"Monsters raid the farm at night. Sleeping at home is the safest cure.",
	],
	"tilda": [
		"Hammering since dawn. A sharper sword makes all the difference.",
		"Mara handles my sword upgrades. Tell her Tilda sent you!",
		"Stone from the cave makes the best building material. Ask Bram.",
	],
	"bram": [
		"Need a bigger house? That takes wood, stone and gold.",
		"Chop small trees for wood. Mine the brown rocks in the cave for stone.",
	],
	"finn": [
		"Fresh bread! ...Sold out, sorry. The farm crops are going to the festival.",
		"I heard the cave has treasure chests. Don't tell anyone I told you.",
		"Mushroom soup is Mayor Rosa's secret weapon. Gunnar the butcher sells meat if you need a snack in the cave.",
	],
	"odo": [
		"Shh! You'll scare the fish.",
		"Wait for the bite, then reel quick. Patience, young one.",
		"Caught a boot once. Wore it for a year.",
	],
	"merlo": [
		"Ah, a hero! The fountain has magic. Toss a coin and see.",
		"Ghosts pass through walls. Bats are fast. Goblins charge. Know your enemy!",
		"The King Slime fires rings of bolts. Dash through the gaps!",
	],
	"wren": ["Pets are just the best, aren't they?"],
	"durin": [
		"Stone and ore, that's all a dwarf needs.",
		"The cave's second floor is full of ogres. Hit hard, dash away.",
	],
}


static func state(id: String) -> String:
	return GameState.quests.get(id, {}).get("state", "none")


static func _track(id: String) -> PackedStringArray:
	return String(DEFS[id].track).split(":")


static func progress(id: String) -> int:
	var tr := _track(id)
	if tr[0] == "item" and state(id) == "active":
		return mini(int(GameState.get(tr[1])), DEFS[id].goal)
	return int(GameState.quests.get(id, {}).get("progress", 0))


static func is_ready(id: String) -> bool:
	return state(id) == "active" and progress(id) >= DEFS[id].goal


# The quest this NPC is currently offering, waiting on, or ready to complete; "" if none.
static func active_for(npc: String) -> String:
	for id in ORDER:
		var d: Dictionary = DEFS[id]
		if d.giver != npc or state(id) == "done":
			continue
		if d.needs != "" and state(d.needs) != "done":
			continue
		return id
	return ""


static func marker(npc: String) -> String:
	var id := active_for(npc)
	if id == "":
		return ""
	if state(id) == "none":
		return "!"
	return "?" if is_ready(id) else ""


static func talk(npc: String) -> Dictionary:
	var id := active_for(npc)
	if id == "":
		var idle: Array = IDLE.get(npc, ["..."])
		var line: String = idle[randi() % idle.size()]
		return {"lines": [line.replace("{name}", GameState.player_name)]}
	var d: Dictionary = DEFS[id]
	if state(id) == "none":
		return {"lines": d.offer, "after": func(): return accept(id)}
	if is_ready(id):
		return {"lines": d.thanks + ["Here's your reward: %s." % _reward_text(d.reward)], "after": func(): return turn_in(id)}
	return {"lines": [d.remind.replace("{n}", str(d.goal - progress(id)))]}


static func accept(id: String) -> String:
	var start := 0
	if id == "boss" and GameState.flags.get("boss_defeated", false):
		start = 1
	GameState.quests[id] = {"state": "active", "progress": start}
	return "New quest: %s" % DEFS[id].title


static func turn_in(id: String) -> String:
	var d: Dictionary = DEFS[id]
	var tr := _track(id)
	if tr[0] == "item":
		GameState.set(tr[1], int(GameState.get(tr[1])) - d.goal)
	var r: Dictionary = d.reward
	GameState.gold += r.get("gold", 0)
	GameState.potions += r.get("potions", 0)
	GameState.damage += r.get("damage", 0)
	GameState.max_hp += r.get("max_hp", 0)
	GameState.hp += r.get("max_hp", 0)
	GameState.quests[id] = {"state": "done", "progress": d.goal}
	return "Quest complete: %s" % d.title


static func _reward_text(r: Dictionary) -> String:
	var parts: Array[String] = []
	if r.has("gold"):
		parts.append("%d gold" % r.gold)
	if r.has("potions"):
		parts.append("%d healing potion" % r.potions)
	if r.has("damage"):
		parts.append("a sharper sword")
	if r.has("max_hp"):
		parts.append("+%d max HP" % r.max_hp)
	return ", ".join(parts)


# Call on every enemy kill. Returns a status line for the last quest it advanced, or "".
static func on_kill(kind: String, raider: bool) -> String:
	if kind == "king":
		GameState.flags["boss_defeated"] = true
	var msg := ""
	for id in ORDER:
		var tr := _track(id)
		if state(id) != "active" or tr[0] != "kill":
			continue
		if tr[1] != kind and not (tr[1] == "raider" and raider):
			continue
		var d: Dictionary = DEFS[id]
		var p := mini(int(GameState.quests[id].get("progress", 0)) + 1, d.goal)
		GameState.quests[id]["progress"] = p
		if p >= d.goal:
			msg = "%s: done! Report back to %s." % [d.title, str(d.giver).capitalize()]
		else:
			msg = "%s: %d/%d" % [d.title, p, d.goal]
	return msg


# One line per active quest, for the HUD tracker.
static func tracker_text() -> String:
	if GameState.quests.is_empty():
		if GameState.flags.get("seen_town", false):
			return "Talk to Rosa, Gus and Pip for jobs!"
		return "Head east along the road to Mossbrook!"
	var lines: Array[String] = []
	for id in ORDER:
		if state(id) != "active":
			continue
		var d: Dictionary = DEFS[id]
		if is_ready(id):
			lines.append("%s - return to %s" % [d.title, str(d.giver).capitalize()])
		else:
			lines.append("%s: %d/%d %s" % [d.title, progress(id), d.goal, d.unit])
	return "\n".join(lines)
