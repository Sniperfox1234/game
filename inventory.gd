extends CanvasLayer
# The inventory screen, opened with I or Tab anywhere. Tabs for your equipment (swap weapon, armor
# and hat), your items (drink potions, eat food), your quests, and your look.

const UiStyle := preload("res://ui_style.gd")
const Outfits := preload("res://outfits.gd")
const Weapons := preload("res://weapons.gd")
const Fish := preload("res://fish.gd")
const Quests := preload("res://quests.gd")
const AvatarScript := preload("res://avatar.gd")

const SKIN := ["f8d8b8", "f1c27d", "e0ac69", "c68642", "8d5524", "5c3a1e"]
const HAIR := ["1a1a1a", "4a2c17", "8b5a2b", "d9b44a", "c0392b", "6c8ebf"]
const SHIRT := ["4f9dde", "e86a6a", "6abf69", "f2c14e", "a66cd8", "f5f5f5"]
const TABS := [["gear", "Equipment"], ["items", "Items"], ["quests", "Quests"], ["look", "Look"]]

var active := false
var area: Node # the area that opened this, so it can freeze the player
var tab := "gear"

var dim := ColorRect.new()
var panel := PanelContainer.new()
var tab_row := HBoxContainer.new()
var scroll := ScrollContainer.new()
var content := VBoxContainer.new()
var side := VBoxContainer.new()
var preview_slot := Control.new()
var preview := Node2D.new()
var status := Label.new()
var tab_buttons := {}


func _ready() -> void:
	layer = 7
	visible = false
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	panel.theme = UiStyle.menu_theme()
	panel.position = Vector2(96, 30)
	panel.custom_minimum_size = Vector2(960, 588)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)
	var title := Label.new()
	title.text = "Backpack"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UiStyle.BORDER)
	title.custom_minimum_size = Vector2(160, 0)
	head.add_child(title)
	tab_row.add_theme_constant_override("separation", 6)
	head.add_child(tab_row)
	for t in TABS:
		var b := Button.new()
		b.text = t[1]
		b.custom_minimum_size = Vector2(120, 0)
		b.pressed.connect(_switch_tab.bind(t[0]))
		tab_row.add_child(b)
		tab_buttons[t[0]] = b

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	scroll.custom_minimum_size = Vector2(620, 440)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	content.add_theme_constant_override("separation", 6)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	side.add_theme_constant_override("separation", 4)
	side.custom_minimum_size = Vector2(250, 0)
	body.add_child(side)
	preview_slot.custom_minimum_size = Vector2(250, 190)
	side.add_child(preview_slot)

	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", UiStyle.BORDER)
	status.custom_minimum_size = Vector2(0, 22)
	root.add_child(status)
	var close := Button.new()
	close.text = "Close   (I or Esc)"
	close.pressed.connect(close_screen)
	root.add_child(close)

	preview.set_script(AvatarScript)
	preview.scale = Vector2(7, 7)
	preview.visible = false
	add_child(preview)
	GameState.equipment_changed.connect(func(): if active: refresh())


func open() -> void:
	if active:
		return
	active = true
	visible = true
	preview.visible = true
	Audio.sfx("open")
	status.text = ""
	if area:
		area.freeze(true)
	refresh()
	(tab_buttons[tab] as Button).grab_focus()


func close_screen() -> void:
	if not active:
		return
	active = false
	visible = false
	preview.visible = false
	Audio.sfx("close")
	if area:
		area.freeze(false)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		close_screen()


func _switch_tab(id: String) -> void:
	tab = id
	status.text = ""
	refresh()


func _say(text: String) -> void:
	status.text = text


# ---------- building the tabs ----------

func refresh() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	for k in tab_buttons:
		(tab_buttons[k] as Button).disabled = k == tab
	match tab:
		"gear":
			_build_gear()
		"items":
			_build_items()
		"quests":
			_build_quests()
		"look":
			_build_look()
	_build_side()
	_place_preview.call_deferred()


func _place_preview() -> void:
	preview.position = preview_slot.global_position + Vector2(125, 168)
	preview.queue_redraw()


func _heading(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", UiStyle.BORDER)
	content.add_child(l)


func _note(text: String, color: Color = UiStyle.MUTED) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(600, 0)
	content.add_child(l)
	return l


func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(g)
	return g


func _choice(grid: Container, text: String, equipped: bool, action: Callable) -> void:
	var b := Button.new()
	b.text = ("[On]  " if equipped else "") + text
	b.disabled = equipped
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	grid.add_child(b)


func _build_gear() -> void:
	var gs := GameState
	_heading("Weapon")
	var g := _grid()
	for id in Weapons.WEAPONS:
		if not id in gs.weapons:
			continue
		var w: Dictionary = Weapons.WEAPONS[id]
		var fx := Weapons.effect_text(w.effect)
		_choice(g, "%s  (+%d%s)" % [w.name, w.dmg, ", " + fx if fx != "" else ""], gs.weapon == id, _equip_weapon.bind(id))
	_note("%d of %d weapons found. Swords and axes are sold at Tilda's Smithy; the strongest are won from bosses." % [gs.weapons.size(), Weapons.WEAPONS.size()])

	_heading("Armor")
	g = _grid()
	_choice(g, "No armor", gs.armor == "", _equip_armor.bind(""))
	for id in Outfits.ARMOR:
		if id in gs.armors:
			var a: Dictionary = Outfits.ARMOR[id]
			_choice(g, "%s  (Def +%d)" % [a.name, a.def], gs.armor == id, _equip_armor.bind(id))
	_note("Armor is sold at Brann's Armory.")

	_heading("Hat")
	g = _grid()
	_choice(g, "No hat", gs.hat == "", _equip_hat.bind(""))
	for id in Outfits.HATS:
		if id in gs.hats:
			_choice(g, Outfits.HATS[id].name, gs.hat == id, _equip_hat.bind(id))
	_note("Hats are sold at Brann's Armory. A few special ones are prizes.")


func _equip_weapon(id: String) -> void:
	GameState.weapon = id
	_say("You wield the %s." % Weapons.WEAPONS[id].name)
	refresh()


func _equip_armor(id: String) -> void:
	GameState.armor = id
	GameState.equipment_changed.emit()
	_say("You put on %s." % Outfits.ARMOR[id].name if id != "" else "You take your armor off.")


func _equip_hat(id: String) -> void:
	GameState.hat = id
	GameState.equipment_changed.emit()
	_say("You put on the %s." % Outfits.HATS[id].name if id != "" else "You take your hat off.")


func _row(label: String, value: String, color: Color = UiStyle.CREAM, button_text := "", action := Callable(), disabled := false) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", color)
	l.custom_minimum_size = Vector2(220, 0)
	h.add_child(l)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 16)
	v.add_theme_color_override("font_color", UiStyle.MUTED)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	if button_text != "":
		var b := Button.new()
		b.text = button_text
		b.disabled = disabled
		b.custom_minimum_size = Vector2(150, 0)
		b.pressed.connect(action)
		h.add_child(b)
	content.add_child(h)


func _build_items() -> void:
	var gs := GameState
	_heading("Supplies")
	_row("Healing potions", str(gs.potions), UiStyle.CREAM, "Drink  (Q)", _use.bind("potion"), gs.potions <= 0 or gs.hp >= gs.max_hp)
	_row("Mana potions", str(gs.mana_potions), UiStyle.CREAM, "Drink  (M)", _use.bind("mana"), gs.mana_potions <= 0 or gs.mp >= gs.max_mp())
	_row("Roast meat", str(gs.meat), UiStyle.CREAM, "Eat  (E)", _use.bind("eat"), (gs.meat + gs.steak) <= 0 or gs.hp >= gs.max_hp)
	_row("Prime steak", str(gs.steak))
	if gs.meal_time > 0.0:
		_row("Well fed", "%s, %ds left" % [gs.meal_data().name, ceili(gs.meal_time)], UiStyle.BORDER)
	_heading("Money")
	_row("Gold", str(gs.gold))
	_row("Bank savings", str(gs.bank))
	_heading("Materials and harvest")
	_row("Seeds", str(gs.seeds))
	_row("Crops", str(gs.crops))
	_row("Mushrooms", str(gs.mushrooms))
	_row("Wood", str(gs.wood))
	_row("Stone", str(gs.stone))
	_heading("Fish   (worth %d gold in all)" % gs.fish_value())
	for r in Fish.RARITIES:
		var info: Dictionary = Fish.INFO[r]
		_row(info.name, "%d    (%d gold each)" % [gs.fish_stock[r], info.price], info.color)
	_heading("Companions")
	_row("Pet", PetNames.get(gs.pet, "none"))
	_row("Fishing rod", Fish.RODS[gs.rod].name)
	_row("Spells", ["none learned", "Fireball", "Fireball II"][gs.spell])


const PetNames := {"dog": "Biscuit the dog", "bat": "Flit the bat", "ghost": "Boo the ghost"}


func _use(what: String) -> void:
	match what:
		"potion":
			if GameState.use_potion():
				Audio.sfx("potion")
				_say("Glug! +5 HP")
		"mana":
			var got := GameState.drink_mana()
			if got > 0:
				Audio.sfx("potion")
				_say("Glug! +%d mana" % got)
		"eat":
			var healed := GameState.eat()
			if healed > 0:
				Audio.sfx("eat")
				_say("Yum! +%d HP" % healed)
	refresh()


func _build_quests() -> void:
	var active_lines: Array[String] = []
	var done := 0
	for id in Quests.ORDER:
		var d: Dictionary = Quests.DEFS[id]
		match Quests.state(id):
			"done":
				done += 1
			"active":
				if Quests.is_ready(id):
					active_lines.append("%s  -  READY! Report back to %s." % [d.title, str(d.giver).capitalize()])
				else:
					active_lines.append("%s  -  %d / %d %s   (from %s)" % [d.title, Quests.progress(id), d.goal, d.unit, str(d.giver).capitalize()])
	_heading("Jobs in progress")
	if active_lines.is_empty():
		_note("Nothing right now. The quest board in the Town Hall lists every job and who gives it.")
	for line in active_lines:
		_note(line, UiStyle.CREAM)
	_heading("Completed")
	_note("%d of %d jobs done." % [done, Quests.ORDER.size()])


func _build_look() -> void:
	var gs := GameState
	_heading("Your look")
	_note("Change your skin, hair and clothes. Armor and hats still show on top of them.", UiStyle.CREAM)
	var g := _grid()
	_choice(g, "Skin tone  (%d of %d)" % [_index_of(SKIN, gs.skin_color) + 1, SKIN.size()], false, _cycle.bind("skin"))
	_choice(g, "Hair colour  (%d of %d)" % [_index_of(HAIR, gs.hair_color) + 1, HAIR.size()], false, _cycle.bind("hair"))
	_choice(g, "Outfit colour  (%d of %d)" % [_index_of(SHIRT, gs.shirt_color) + 1, SHIRT.size()], false, _cycle.bind("shirt"))


func _index_of(palette: Array, color: Color) -> int:
	for k in palette.size():
		if Color(palette[k]).is_equal_approx(color):
			return k
	return 0


func _cycle(part: String) -> void:
	var gs := GameState
	match part:
		"skin":
			gs.skin_color = Color(SKIN[(_index_of(SKIN, gs.skin_color) + 1) % SKIN.size()])
		"hair":
			gs.hair_color = Color(HAIR[(_index_of(HAIR, gs.hair_color) + 1) % HAIR.size()])
		"shirt":
			gs.shirt_color = Color(SHIRT[(_index_of(SHIRT, gs.shirt_color) + 1) % SHIRT.size()])
	gs.equipment_changed.emit()
	preview.queue_redraw()
	if area and area.player:
		area.player.get_node("Avatar").queue_redraw()
	refresh()


# ---------- the side column: preview and stats ----------

func _build_side() -> void:
	# Keep the preview slot (first child); rebuild the stat labels after it.
	while side.get_child_count() > 1:
		var c := side.get_child(1)
		side.remove_child(c)
		c.queue_free()
	var gs := GameState
	var lines := [
		[gs.player_name, UiStyle.BORDER, 20],
		["Level %d   (%d / %d XP)" % [gs.level, gs.xp, gs.xp_needed()], UiStyle.CREAM, 16],
		["HP  %d / %d" % [gs.hp, gs.max_hp], Color("ff8a9a"), 16],
		["Mana  %d / %d" % [gs.mp, gs.max_mp()], Color("8fb8ff"), 16],
		["Damage  %d" % gs.attack_damage(), UiStyle.CREAM, 16],
		["Defense  %d" % gs.defense(), UiStyle.CREAM, 16],
		["Weapon: %s" % gs.weapon_data().name, UiStyle.MUTED, 14],
		["Day %d     Gold %d" % [gs.day, gs.gold], UiStyle.MUTED, 14],
	]
	for l in lines:
		var label := Label.new()
		label.text = l[0]
		label.add_theme_color_override("font_color", l[1])
		label.add_theme_font_size_override("font_size", l[2])
		side.add_child(label)
