extends RefCounted
# Quest data, quest state helpers, and the dialogue each NPC gives for them.
# State lives in GameState.quests: id -> {"state": "active" | "done", "progress": int}.
# A quest's "track" is either "item:<GameState var>" (hand in items) or "kill:<enemy kind>".
# "kill:raider" counts monsters that attack at night.
# "event:<name>" quests finish when the game reports that event (a fish caught, a gallery score...).

const ORDER := ["crops", "shrooms", "fish", "raiders", "slimes", "goblins", "boss", "picnic", "bats", "bigcatch", "gallery20", "firemagic"]

const DEFS := {
	"picnic": {
		"title": "Lila's Picnic", "giver": "lila", "needs": "", "goal": 2, "unit": "meat", "track": "item:meat",
		"reward": {"gold": 40},
		"offer": [
			"Hi! I'm Lila. I'm having a picnic by the fountain but I forgot the food!",
			"Could you bring me 2 pieces of meat? Gunnar's Butchery sells it, up by the east houses.",
		],
		"remind": "{n} more meat, please! Gunnar's Butchery has plenty.",
		"thanks": ["Yum, picnic time! Thank you so much!"],
	},
	"bats": {
		"title": "Hank's Bat Problem", "giver": "hank", "needs": "", "goal": 4, "unit": "bats", "track": "kill:bat",
		"reward": {"gold": 60, "potions": 1},
		"offer": [
			"Howdy! Hank's the name, farming's my game.",
			"Those cave bats keep flying out and spooking my cows. Take down 4 of them, would ya?",
			"They're quick and weave about. Wait for them to come at you, then swing!",
		],
		"remind": "{n} more bats. Let them come to you and time your swing.",
		"thanks": ["Peace and quiet at last! Thanks, hero."],
	},
	"bigcatch": {
		"title": "Odo's Big Catch", "giver": "odo", "needs": "", "goal": 1, "unit": "epic fish", "track": "event:epic",
		"reward": {"gold": 100, "rod": 1},
		"offer": [
			"Fish come in rarities, you know. Common, uncommon, rare, epic and legendary.",
			"Land an EPIC fish or better and I'll give you my old Silver Rod. React fast when the bite comes, and a better rod helps too!",
		],
		"remind": "Still waiting on that epic fish. Be quick on the bite!",
		"thanks": ["An epic fish! You're a natural. Take my old Silver Rod."],
	},
	"gallery20": {
		"title": "Dusty's Challenge", "giver": "dusty", "needs": "", "goal": 1, "unit": "round of 20+", "track": "event:gallery",
		"reward": {"gold": 80},
		"offer": [
			"Step right up! Think you can shoot?",
			"Score 20 points or more in a single round at my gallery and I'll hand you 80 gold. Bullseyes are worth 5, and the golden targets are worth 10!",
		],
		"remind": "Score 20 or more in one round. Go for bullseyes and the golden targets!",
		"thanks": ["Sharpshooter! Here's your prize money."],
	},
	"firemagic": {
		"title": "Merlo's Magic Test", "giver": "merlo", "needs": "spell", "goal": 1, "unit": "fireball hit", "track": "event:fireball",
		"reward": {"gold": 50, "mana_potions": 3},
		"offer": [
			"Ah, you've learned the fireball! Wonderful.",
			"Hit a monster with one, and I'll reward you with some mana potions. Press F to cast. You'll need mana, which slowly recharges.",
		],
		"remind": "Cast a fireball at a monster with F. Wait for your mana to recharge if it's low!",
		"thanks": ["Magnificent! Here, take these."],
	},
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
		"The King Slime's chamber is at the bottom of the cave. Take the ladders down!",
		"Sell your crops, fish and mushrooms at Mara's stall in the plaza!",
		"I want to be a hero when I grow up. Like you!",
		"Wren at the pet yard gives pets to heroes who are level 3!",
	],
	"captain": [
		"Captain Vale, town watch. Quiet night so far... too quiet.",
		"Armor reduces every hit you take. Brann's Armory has some good sets.",
		"Monsters raid the farm at night. Sleeping at home is the safest cure.",
		"Tilda's Smithy sells swords that burn, freeze and shock. Try them on the boss!",
	],
	"mara": [
		"Seeds, potions, sharpening and heart charms, all in one stall!",
		"I buy crops, fish and mushrooms. Rarer fish fetch a lot more gold!",
	],
	"tilda": [
		"Hammering since dawn. A sharper sword makes all the difference.",
		"Burn them, freeze them, shock them. There's a blade for every fight.",
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
		"Wait for the bite, then reel quick. The faster you are, the better the fish.",
		"Legendary fish are real. I've seen a Dragon Koi. Once.",
	],
	"merlo": [
		"Ah, a hero! The fountain has magic, you know. Toss a coin and see.",
		"Ghosts pass through walls. Bats are fast. Goblins charge. Know your enemy!",
		"The King Slime fires rings of bolts. Dash through the gaps, and burn him with fire!",
	],
	"wren": ["Pets are just the best, aren't they?"],
	"durin": [
		"Stone and ore, that's all a dwarf needs.",
		"The cave's second floor is full of ogres. Hit hard, dash away.",
	],
	"jun": [
		"I'm Tilda's apprentice. Someday I'll forge a legendary sword!",
		"Flame Blade, Frost Brand, Thunder Edge... Tilda makes them all.",
		"Every hammer strike is a lesson. Ow, my thumb!",
	],
	"moss": [
		"I've seen this town grow from three huts and a goat. Look at it now!",
		"They say the King Slime guards a treasure no one has ever claimed.",
		"Rest your feet by the fountain, young one. Adventure can wait a minute.",
	],
	"penny": [
		"Letters, parcels, and a little gift for every hero who stops by each day!",
		"I deliver all over Mossbrook. Nobody sends mail to the cave, though.",
	],
	"hank": [
		"Fresh air, good soil, and no bats. That's the life.",
		"Plant on day one, harvest on day four. Patience pays.",
		"A scarecrow would be nice, but the slimes just laugh at it.",
	],
	"lila": [
		"I'm going to catch a legendary fish one day!",
		"Pip says he's a hero. But YOU are the real hero.",
		"Meat sandwiches are the best sandwiches.",
	],
	"brine": [
		"I sailed the seven seas, and the best fishing is right here in this pond.",
		"Legendary fish? Aye, I saw a Sunken Crownfish once. Gave me the shivers.",
		"A golden rod tempts the rarest catches. Ask Odo.",
	],
	"rue": [
		"Flowers need sun, water and kind words. Mostly kind words.",
		"These planters are my pride and joy. Don't pick the daisies!",
	],
	"lark": [
		"La la laaa! A tune for every hero.",
		"I once sang a ballad so powerful a goblin cried.",
	],
	"hazel": [
		"Hazel's Clinic: broken bones, scraped knees and bruised egos, all patched up.",
		"A little rest, a little tea, and you're good as new.",
	],
	"dusty": [
		"Step right up, step right up! Twelve arrows, big prizes!",
		"Bullseyes are worth five. Golden targets are worth ten, but they're quick!",
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
		if d.needs == "spell":
			if GameState.spell < 1:
				continue
		elif d.needs != "" and state(d.needs) != "done":
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
	GameState.mana_potions += r.get("mana_potions", 0)
	GameState.rod = maxi(GameState.rod, r.get("rod", 0))
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
	if r.has("mana_potions"):
		parts.append("%d mana potions" % r.mana_potions)
	if r.has("rod"):
		parts.append("a Silver Rod")
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


# Reports a game event (a fish caught, a gallery score...). Returns a status line, or "".
static func event(name: String) -> String:
	var msg := ""
	for id in ORDER:
		var tr := _track(id)
		if state(id) != "active" or tr[0] != "event" or tr[1] != name:
			continue
		if progress(id) >= DEFS[id].goal:
			continue
		GameState.quests[id]["progress"] = DEFS[id].goal
		msg = "%s: done! Report back to %s." % [DEFS[id].title, str(DEFS[id].giver).capitalize()]
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
