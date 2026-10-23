extends RefCounted
# Quest data, quest state helpers, and the dialogue each NPC gives for them.
# State lives in GameState.quests: id -> {"state": "active" | "done", "progress": int}.

const ORDER := ["crops", "slimes", "boss"]

const DEFS := {
	"crops": {
		"title": "Harvest Help", "giver": "rosa", "needs": "", "goal": 5, "reward": 50, "unit": "crops",
		"offer": [
			"Welcome to Mossbrook! I'm Rosa, the mayor.",
			"Our pantry is nearly empty. Could you bring me 5 crops from your farm? It's just west of town.",
		],
		"remind": "I still need {n} more crops. Your farm is just west of town.",
		"thanks": [
			"Wonderful! These will feed the whole village.",
			"Here's 50 gold for your trouble.",
		],
	},
	"slimes": {
		"title": "Slime Trouble", "giver": "gus", "needs": "", "goal": 5, "reward": 60, "unit": "slimes",
		"offer": [
			"Halt! Oh, you're the new farmer. I'm Gus, the town guard.",
			"Slimes have taken over the old cave to the east. Defeat 5 of them and I'll pay you 60 gold.",
			"Press Space in there to swing your sword. Watch your health!",
		],
		"remind": "{n} more slimes to go. Keep at it.",
		"thanks": [
			"Five slimes down! You're a natural.",
			"Here's 60 gold, and I've sharpened your sword. It hits harder now.",
		],
	},
	"boss": {
		"title": "King of Slime", "giver": "gus", "needs": "slimes", "goal": 1, "reward": 200, "unit": "King Slime",
		"offer": [
			"There's one more problem...",
			"A huge King Slime lurks deep in the cave. Defeat it and I'll give you 200 gold.",
			"It's tough. Make sure you're at full health first. Sleeping in your house heals you.",
		],
		"remind": "The King Slime is still out there, deep in the cave.",
		"thanks": [
			"You beat the King Slime?! Mossbrook is saved!",
			"Here's 200 gold. You've earned it, hero.",
		],
	},
}

const IDLE := {
	"rosa": ["Thank you again, {name}. Mossbrook is lucky to have you."],
	"gus": ["The cave is quiet now. Thanks to you."],
	"pip": [
		"Crops take 3 days to grow. Sleep in your house to skip ahead!",
		"Slimes in the cave drop gold, and sometimes a heart.",
		"Gus says the cave goes deeper than anyone's been.",
		"Sell your crops at the market stall by your farm!",
		"I want to be a hero when I grow up. Like you!",
	],
}


static func state(id: String) -> String:
	return GameState.quests.get(id, {}).get("state", "none")


static func progress(id: String) -> int:
	if id == "crops" and state(id) == "active":
		return mini(GameState.crops, DEFS[id].goal)
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
		return {"lines": d.thanks, "after": func(): return turn_in(id)}
	return {"lines": [d.remind.replace("{n}", str(d.goal - progress(id)))]}


static func accept(id: String) -> String:
	var start := 0
	if id == "boss" and GameState.flags.get("boss_defeated", false):
		start = 1
	GameState.quests[id] = {"state": "active", "progress": start}
	return "New quest: %s" % DEFS[id].title


static func turn_in(id: String) -> String:
	var d: Dictionary = DEFS[id]
	GameState.gold += d.reward
	if id == "crops":
		GameState.crops -= d.goal
	elif id == "slimes":
		GameState.damage += 1
	GameState.quests[id] = {"state": "done", "progress": d.goal}
	return "Quest complete: %s (+%d gold)" % [d.title, d.reward]


# Returns a status line for the quest the kill advanced, or "".
static func on_kill(kind: String) -> String:
	var id := "boss" if kind == "boss" else "slimes"
	if kind == "boss":
		GameState.flags["boss_defeated"] = true
	if state(id) != "active":
		return ""
	var d: Dictionary = DEFS[id]
	var p := mini(progress(id) + 1, d.goal)
	GameState.quests[id]["progress"] = p
	if p >= d.goal:
		return "%s: done! Report back to %s." % [d.title, str(d.giver).capitalize()]
	return "%s: %d/%d" % [d.title, p, d.goal]


# One line per active quest, for the HUD tracker.
static func tracker_text() -> String:
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
