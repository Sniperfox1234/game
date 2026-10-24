extends RefCounted
# Quest data, quest state helpers, and the dialogue each NPC gives for them.
# State lives in GameState.quests: id -> {"state": "active" | "done", "progress": int}.
# A quest's "track" is either "item:<GameState var>" (hand in items), "have:<GameState var>" (reach a value, nothing is taken)
# or "kill:<enemy kind>".
# "kill:raider" counts monsters that attack at night.
# "event:<name>" quests finish when the game reports that event (a fish caught, a gallery score...).

# The flag set when each boss is first defeated.
const BOSS_FLAGS := {
	"king": "boss_defeated", "titan": "titan_defeated", "pharaoh": "pharaoh_defeated",
	"blackjaw": "blackjaw_defeated", "morwen": "morwen_defeated",
}

const ORDER := ["crops", "shrooms", "fish", "raiders", "slimes", "goblins", "boss", "picnic", "bats", "bigcatch", "gallery20", "firemagic", "chef", "cold", "titan",
	"knighting", "ogres", "courier_d", "courier_h", "pharaoh_q", "blackjaw_q", "morwen_q", "hero"]

const DEFS := {
	"knighting": {
		"title": "Prove Yourself", "giver": "aldric", "needs": "", "goal": 6, "unit": "hero level", "track": "have:level",
		"reward": {"gold": 200, "potions": 2},
		"offer": [
			"Another hero comes to Highgarden. Brave, no doubt. But the Crown does not knight on bravery alone.",
			"Reach level 6 and return. Then we shall speak of real duties.",
		],
		"remind": "You are not yet strong enough. Reach level 6, then come back.",
		"thanks": [
			"You carry yourself like a knight now. Highgarden will remember you.",
		],
	},
	"ogres": {
		"title": "The Ogre Menace", "giver": "gareth", "needs": "knighting", "goal": 5, "unit": "ogres", "track": "kill:ogre",
		"reward": {"gold": 300, "damage": 1},
		"offer": [
			"Hail, hero. I am Sir Gareth, Captain of the Guard. Ogres have been lumbering up from the Mossbrook caves.",
			"Slay 5 of them. They hit hard but move slowly, so strike and step back.",
		],
		"remind": "{n} more ogres. Look on cave floor 2.",
		"thanks": [
			"Five ogres felled! The Crown owes you, hero.",
		],
	},
	"courier_d": {
		"title": "The Desert Dispatch", "giver": "wilm", "needs": "knighting", "goal": 1, "unit": "desert visited", "track": "event:visit_desert",
		"reward": {"gold": 200, "potions": 1},
		"offer": [
			"I am Herald Wilm. The Crown needs eyes in Sunscar Desert. A scholar is stranded there with a message for His Majesty.",
			"Take Rolf's carriage to the desert. Just arriving will be enough. I will count it as delivered.",
		],
		"remind": "Take the carriage to Sunscar Desert and look around.",
		"thanks": [
			"You went and returned! The desert is as dangerous as they say. Thank you.",
		],
	},
	"courier_h": {
		"title": "The Harbour Letter", "giver": "wilm", "needs": "courier_d", "goal": 1, "unit": "harbor visited", "track": "event:visit_harbor",
		"reward": {"gold": 250, "potions": 2},
		"offer": [
			"Another errand. A harbourmaster in Port Saltmere has sent urgent word about pirates.",
			"Travel there by carriage and see for yourself. Then return.",
		],
		"remind": "Take the carriage to Port Saltmere.",
		"thanks": [
			"Pirates in the cove, as feared. The King will want to hear this.",
		],
	},
	"pharaoh_q": {
		"title": "Wake of the Pharaoh", "giver": "idris", "needs": "", "goal": 1, "unit": "Pharaoh", "track": "kill:pharaoh",
		"reward": {"gold": 600, "max_hp": 4},
		"offer": [
			"The tomb below the pyramid has opened. The Pharaoh walks again, bound in gold and old rage.",
			"Slay him in his sanctum. Scarabs and mummies guard the way, and his curse slows whoever it strikes.",
		],
		"remind": "The Pharaoh still waits in the lowest chamber of the pyramid.",
		"thanks": [
			"The sands are quiet at last. You have done what no one dared.",
		],
	},
	"blackjaw_q": {
		"title": "Blackjaw's Bounty", "giver": "harbourmaster", "needs": "", "goal": 1, "unit": "Captain Blackjaw", "track": "kill:blackjaw",
		"reward": {"gold": 700, "max_hp": 4},
		"offer": [
			"Captain Blackjaw and his crew have terrorised Port Saltmere for years.",
			"Sail, er, walk into Smugglers' Cove and bring him down. Beware his charge and the cannoneers!",
		],
		"remind": "Blackjaw is still at large, in the lowest part of Smugglers' Cove.",
		"thanks": [
			"Blackjaw is finished! The docks are safe. Here is the bounty.",
		],
	},
	"morwen_q": {
		"title": "Morwen's End", "giver": "elda", "needs": "", "goal": 1, "unit": "Witch Morwen", "track": "kill:morwen",
		"reward": {"gold": 800, "max_hp": 5},
		"offer": [
			"Morwen was once a healer like me. The marsh twisted her. Her cauldron poisons every pool for miles.",
			"Defeat her in the Rotting Bog. Stay out of the green sludge and carry antidotes!",
		],
		"remind": "Morwen is still brewing in the depths of the Rotting Bog.",
		"thanks": [
			"Hee hee, the marsh is breathing again. Thank you, dear.",
		],
	},
	"hero": {
		"title": "Hero of the Realm", "giver": "aldric", "needs": "morwen_q", "goal": 12, "unit": "hero level", "track": "have:level",
		"reward": {"gold": 2000, "potions": 5, "max_hp": 6},
		"offer": [
			"You have laid low a Pharaoh, a pirate and a witch. The realm has never had a champion like you.",
			"Reach level 12 and return. I shall name you Hero of the Realm before the entire court.",
		],
		"remind": "Reach level 12 and I will name you Hero of the Realm.",
		"thanks": [
			"Kneel, and rise as Hero of the Realm! Let the whole kingdom hear it.",
		],
	},
	"cold": {
		"title": "Cold Snap", "giver": "captain", "needs": "boss", "goal": 6, "unit": "ice slimes", "track": "kill:frostslime",
		"reward": {"gold": 150, "potions": 2},
		"offer": [
			"Hero, bad news. With the King Slime gone, a frozen stairway opened beneath his chamber.",
			"Ice slimes are creeping up from the Frostfang depths. Defeat 6 of them down there. They slow you down on touch, so keep moving!",
		],
		"remind": "{n} more ice slimes. Take the frozen stairs at the east end of the King's chamber.",
		"thanks": ["The cold is receding already. Well done, hero."],
	},
	"titan": {
		"title": "The Frost Titan", "giver": "gus", "needs": "cold", "goal": 1, "unit": "Frost Titan", "track": "kill:titan",
		"reward": {"gold": 500, "max_hp": 4},
		"offer": [
			"The ice slimes answer to something far bigger. A Frost Titan sleeps in the deepest chamber of the Frostfang depths.",
			"Slay it and Mossbrook is safe for good. I'll pay 500 gold and give you a heart charm. Beware its slam: stay out of the red circle!",
		],
		"remind": "The Frost Titan still sleeps in the lowest chamber of the frozen caves.",
		"thanks": ["You... you slew the Titan?! Mossbrook owes you everything."],
	},
	"chef": {
		"title": "Finn's Recipe", "giver": "finn", "needs": "", "goal": 1, "unit": "dish cooked", "track": "event:cook",
		"reward": {"gold": 60, "potions": 1},
		"offer": [
			"Ah, a hero with an appetite for adventure! I'm Finn.",
			"Cooked meals make you 'well fed' for ages, much longer than anything I sell. Cook any dish, at the campfire by your house or in my kitchen, and I'll reward you.",
			"Fish, mushrooms, crops, meat and steak all go in the pot. A legendary fish makes the best feast!",
		],
		"remind": "Cook any dish at a campfire (by your farmhouse) or in my kitchen over there!",
		"thanks": ["Delicious work! Welcome to the kitchen, chef."],
	},
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
	"rolf": ["Where to, hero? The king's road runs from Highgarden to the desert, the sea and the swamp.", "Thirty gold a trip to the far lands. Worth every coin!"],
	"aldric": ["Highgarden is at your service, hero. Visit the armoury, the banquet hall, or take a stroll in the gardens."],
	"wilm": ["Hear ye! The king receives all heroes in the throne room."],
	"gareth": ["Keep your blade sharp. The Crown's enemies are everywhere."],
	"squire": ["I'm training to be a knight. Sir Gareth says I swing like a wet noodle!"],
	"guard1": ["Halt! ...Oh, it's you. Carry on. Highgarden is safe thanks to heroes like you."],
	"guard2": ["The moat has never been crossed by an enemy. Not once!"],
	"cecile": ["The gardens are lovely at this hour. Do admire the roses."],
	"pemberton": ["I am Lord Pemberton. I have no job. I am very busy."],
	"ivo": ["The roses need weeding, the hedges need trimming, and the fountain needs a good scrub."],
	"jingles": ["Why did the slime cross the road? To get to the other slime! Hee hee!"],
	"dob": ["The horses are restless. They can smell the swamp from here."],
	"vera": ["Poison, burns, a nasty cough. I have a remedy for everything. For a price."],
	"bastien": ["The King's Feast heals you fully and fills you with rage. Eat, hero, eat!"],
	"royce": ["Only the finest steel leaves the Royal Armoury."],
	"counsellor": ["His Majesty listens to those who have proven themselves. Prove yourself."],
	"lord_a": ["Pass the pheasant, would you?"],
	"lady_a": ["The banquet is simply delightful."],
	"jester_b": ["Knock knock! Who's there? A very hungry jester!"],
	"zahra": ["Welcome, traveller! The tomb's treasures will make you rich, if you survive."],
	"idris": ["The pyramid shifts with the wind. Even I cannot find the door twice."],
	"pell": ["I have catalogued four hundred hieroglyphs. The Pharaoh is on all of them."],
	"camelboy": ["My camel's name is Sir Spits-a-Lot."],
	"salty": ["Every sailor needs a good coat and a better harpoon."],
	"marta": ["The sea's full of fish. A silver rod helps, and a quick hand more."],
	"harbourmaster": ["Mind the cannoneers. They fire in threes."],
	"sailor1": ["I've sailed every sea. None as rough as Blackjaw's temper."],
	"sailor2": ["I just swab the deck. Don't tell the captain I said that."],
	"elda": ["An antidote a day keeps the poison at bay. Hee hee!"],
	"trapper": ["The mud sucks at your boots. The wisps suck at your health."],
	"frogboy": ["Ribbit! I found a really big frog. Do you want to see?"],
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
	"tess": [
		"These pies are the best in the valley. Don't tell Finn I said so!",
		"I come here every morning. The honey cake gives you a real spring in your step.",
	],
	"bo": [
		"Mmm. The breakfast platter turns grown adults into lions.",
		"I'm saving my appetite for the harvest festival.",
	],
	"mina": [
		"I hear the bard sings a tune that makes your sword feel lighter.",
		"Finn burned the first batch today. We don't talk about it.",
	],
	"bea": ["The treasury is safe, and your savings earn interest every morning!"],
	"orin": [
		"Shhh. This is a library. Well, a very small library.",
		"Every monster you defeat gets written in the bestiary. Knowledge is power!",
	],
	"tam": [
		"I pin up every job in Mossbrook. The board is never empty!",
		"Check the board often. New villagers post new requests.",
	],
	"brix": [
		"Councilman Brix. We're debating whether to build a second fountain.",
		"The town has never been richer. Your doing, no doubt.",
	],
	"oona": [
		"Councilwoman Oona. I voted to pay the hero double. I lost 4 to 3.",
		"Mind the marble. We polish it daily.",
	],
	"mel": [
		"I'm a tourist! This town has a bank, a fountain AND a dummy you can hit. Lovely!",
		"Is it true there's a slime the size of a house?",
	],
	"pru": [
		"I've lived in Mossbrook for ninety years. The town hall used to be a barn!",
		"Back in my day, the King Slime was just a regular slime. Kids these days.",
	],
	"ned": [
		"Hear ye, hear ye!",
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
	if (tr[0] == "item" or tr[0] == "have") and state(id) == "active":
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


static func is_available(id: String) -> bool:
	if state(id) != "none":
		return false
	var d: Dictionary = DEFS[id]
	if d.needs == "spell":
		return GameState.spell >= 1
	return d.needs == "" or state(d.needs) == "done"


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
	# A kill quest for a boss you have already beaten starts out complete.
	var tr := _track(id)
	if tr[0] == "kill" and BOSS_FLAGS.has(tr[1]) and GameState.flags.get(BOSS_FLAGS[tr[1]], false):
		start = DEFS[id].goal
	GameState.quests[id] = {"state": "active", "progress": start}
	Audio.sfx("quest_accept")
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
	Audio.sfx("quest_done")
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
	if BOSS_FLAGS.has(kind):
		GameState.flags[BOSS_FLAGS[kind]] = true
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
			return "Talk to Rosa (Town Hall), Gus and Pip for jobs!"
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
