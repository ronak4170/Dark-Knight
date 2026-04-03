extends Node2D

const GAME_SCENE = "res://scenese/Level_1_Scene/level_1.tscn"

var title
var start_button
var continue_button
var quit_button
var animation_player
var settings_button
var settings_panel
var volume_slider
var sfx_slider
var close_button
var references_button
var references_panel
var close_ref_button

func _ready():
	title = get_node_or_null("Title")
	start_button = get_node_or_null("StartButton")
	continue_button = get_node_or_null("ContinueButton")
	print("Continue button found: ", continue_button)
	quit_button = get_node_or_null("QuitButton")
	animation_player = get_node_or_null("AnimationPlayer")
	settings_button = get_node_or_null("Settings")
	settings_panel = get_node_or_null("SettingsPanel")
	volume_slider = get_node_or_null("SettingsPanel/VBoxContainer/VolumeRow/VolumeSlider")
	sfx_slider = get_node_or_null("SettingsPanel/VBoxContainer/SFXRow/SFXSlider")
	close_button = get_node_or_null("SettingsPanel/CloseButton")
	references_button = get_node_or_null("references")
	references_panel = get_node_or_null("ReferencesPanel")
	close_ref_button = get_node_or_null("ReferencesPanel/CloseButtonRef")
	if close_ref_button == null:
		close_ref_button = get_node_or_null("ReferencesPanel/CloseButton")

	modulate = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.0)

	if settings_panel:
		settings_panel.visible = false
		resize_settings_panel()

	if references_panel:
		references_panel.visible = false
		resize_references_panel()

	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
		start_button.mouse_entered.connect(_on_start_hover)
		start_button.mouse_exited.connect(_on_start_unhover)

	if continue_button:
		# Remove grey box — match start/quit style
		var style_empty = StyleBoxEmpty.new()
		continue_button.add_theme_stylebox_override("normal", style_empty)
		continue_button.add_theme_stylebox_override("hover", style_empty)
		continue_button.add_theme_stylebox_override("pressed", style_empty)
		continue_button.add_theme_stylebox_override("focus", style_empty)
		continue_button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.02, 1.0))
		continue_button.add_theme_color_override("font_hover_color", Color(1, 0.2, 0.2, 1))
		continue_button.add_theme_color_override("font_pressed_color", Color(1, 0.2, 0.2, 1))
		continue_button.add_theme_font_size_override("font_size", 100)

		var config = ConfigFile.new()
		var err = config.load("user://savegame.cfg")
		if err == OK:
			var last_scene = config.get_value("save", "last_scene", "")
			print("Found saved scene: ", last_scene)
			if last_scene != "":
				continue_button.visible = true
				if not continue_button.pressed.is_connected(_on_continue_button_pressed):
					continue_button.pressed.connect(_on_continue_button_pressed)
				if not continue_button.mouse_entered.is_connected(_on_continue_hover):
					continue_button.mouse_entered.connect(_on_continue_hover)
				if not continue_button.mouse_exited.is_connected(_on_continue_unhover):
					continue_button.mouse_exited.connect(_on_continue_unhover)
			else:
				continue_button.visible = false
		else:
			print("No savegame found")
			continue_button.visible = false

	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
		quit_button.mouse_entered.connect(_on_quit_hover)
		quit_button.mouse_exited.connect(_on_quit_unhover)

	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

	if close_button:
		close_button.pressed.connect(_on_close_settings_pressed)
		style_close_button(close_button)

	if references_button:
		references_button.pressed.connect(_on_references_pressed)

	if close_ref_button:
		close_ref_button.pressed.connect(_on_close_references_pressed)
		style_close_button(close_ref_button)

	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_slider_changed)

	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	setup_instructions()
	setup_references_content()
	load_settings()

# -----------------------------------
# RESIZE SETTINGS PANEL
# -----------------------------------

func resize_settings_panel():
	if settings_panel == null:
		return

	var screen_size = get_viewport().get_visible_rect().size
	var panel_w = screen_size.x * 0.55
	var panel_h = screen_size.y * 0.65
	settings_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	settings_panel.position = Vector2(
		(screen_size.x - panel_w) / 2,
		(screen_size.y - panel_h) / 2
	)

	if close_button:
		close_button.custom_minimum_size = Vector2(40, 40)
		close_button.position = Vector2(panel_w - 46, 6)

	var title_label = get_node_or_null("SettingsPanel/SettingsTitle")
	if title_label:
		title_label.position = Vector2(0, 18)
		title_label.custom_minimum_size = Vector2(panel_w, 0)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 62)
		title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	var vbox = get_node_or_null("SettingsPanel/VBoxContainer")
	if vbox:
		vbox.position = Vector2(30, 100)
		vbox.custom_minimum_size = Vector2(panel_w - 60, 0)
		vbox.add_theme_constant_override("separation", 24)

	var vol_label = get_node_or_null("SettingsPanel/VBoxContainer/VolumeRow/VolumeLabel")
	if vol_label:
		vol_label.custom_minimum_size = Vector2(160, 50)
		vol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vol_label.add_theme_font_size_override("font_size", 48)

	var sfx_label_node = get_node_or_null("SettingsPanel/VBoxContainer/SFXRow/SFXLabel")
	if sfx_label_node:
		sfx_label_node.custom_minimum_size = Vector2(160, 50)
		sfx_label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sfx_label_node.add_theme_font_size_override("font_size", 58)

	if volume_slider:
		volume_slider.custom_minimum_size = Vector2(panel_w - 230, 50)

	if sfx_slider:
		sfx_slider.custom_minimum_size = Vector2(panel_w - 230, 50)

# -----------------------------------
# RESIZE REFERENCES PANEL
# -----------------------------------

func resize_references_panel():
	if references_panel == null:
		return

	var screen_size = get_viewport().get_visible_rect().size
	var panel_w = screen_size.x * 0.55
	var panel_h = screen_size.y * 0.65
	references_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	references_panel.position = Vector2(
		(screen_size.x - panel_w) / 2,
		(screen_size.y - panel_h) / 2
	)

	if close_ref_button:
		close_ref_button.custom_minimum_size = Vector2(40, 40)
		close_ref_button.position = Vector2(panel_w - 46, 6)

	var vbox = get_node_or_null("ReferencesPanel/VBoxContainer")
	if vbox:
		vbox.position = Vector2(30, 70)
		vbox.custom_minimum_size = Vector2(panel_w - 60, 0)
		vbox.add_theme_constant_override("separation", 16)

# -----------------------------------
# REFERENCES PANEL CONTENT
# -----------------------------------
	
func setup_references_content():
	
	var panel = get_node_or_null("ReferencesPanel")
	if panel:
		panel.anchor_left = 0.05
		panel.anchor_top = 0.02
		panel.anchor_right = 0.95
		panel.anchor_bottom = 0.95
		panel.offset_left = 0
		panel.offset_top = 0
		panel.offset_right = 0
		panel.offset_bottom = 0

	var vbox = get_node_or_null("ReferencesPanel/VBoxContainer")
	if vbox == null:
		return
	
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 20
	vbox.offset_top = 30
	vbox.offset_right = -20
	vbox.offset_bottom = -100
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for child in vbox.get_children():
		child.queue_free()

	# Title
	var ref_title = Label.new()
	ref_title.text = "References"
	ref_title.add_theme_font_size_override("font_size", 50)
	ref_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	ref_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(ref_title)

	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(separator)

	# Tab Container
	var tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.anchor_left = 0.0
	tabs.anchor_top = 0.0
	tabs.anchor_right = 1.0
	tabs.anchor_bottom = 1.0
	tabs.offset_left = 10
	tabs.offset_right = -10
	tabs.offset_bottom = -10
	tabs.add_theme_font_size_override("font_size", 32)
	vbox.add_child(tabs)

	var sections = {
		"Main Menu": "Wallpaper:\nhttps://www.wallpaperflare.com/samurai-digital-wallpaper-sword-blood-fantasy-armor-weapon-wallpaper-qenjy\n\nFont (Cinzel-Decorative/Regular):\nhttps://www.1001fonts.com/cinzel-font.html\n\nSettings Icon:\nhttps://pngtree.com/freepng/settings-glyph-black-icon_3755352.html\n\nScroll Icon:\nhttps://www.flaticon.com/free-icon/scrolls_5234879\n\nBackground Music:\nhttps://egorkin531.itch.io/japanese-journey",

		"Characters": "Hero Samurai:\nhttps://craftpix.net/freebies/free-samurai-pixel-art-sprite-sheets/\n\nEnemy Samurai:\nhttps://craftpix.net/freebies/free-samurai-pixel-art-sprite-sheets/\n\nBat:\nhttps://monopixelart.itch.io/dark-fantasy-enemies-asset-pack",

		"Level 1": "TileMap:\nhttps://raou.itch.io/dark-dun\n\nBackground Music:\nhttps://junyua.itch.io/japanese-vibe\n\nMemory Fragment:\nhttps://pngtree.com/freepng/futuristic-red-and-black-neon-circle-glow_20774084.html\n\nFootstep Audio Cue:\nAI Generated from https://elevenlabs.io/app/sound-effects",

		"Level 2": "TileMap:\nhttps://free-game-assets.itch.io/free-dungeon-platformer-game-tileset-pixel-art\n\nBackground Music:\nhttps://junyua.itch.io/japanese-vibe\n\nJump Audio Cue:\nhttps://youtu.be/uRozyfP1cEE?si=iEJGL8qBr4KSHm2Q",

		"Level 3": "TileMap:\nhttps://ansimuz.itch.io/sunnyland-fort-of-illusion\n\nBackground Music:\nhttps://junyua.itch.io/japanese-vibe\n\nBat Hurt Audio Cue:\nhttps://youtu.be/rs75ptsPHFM?si=NrFvKw9Ch40kNQF7\n\nAttack Audio Cue:\nAI Generated from https://elevenlabs.io/app/sound-effects",

		"Level 4": "TileMap:\nhttps://raou.itch.io/dark-dun\n\nBackground Music:\nhttps://egorkin531.itch.io/japanese-journey\n\nSwitch On/Off Sound:\nAI Generated from https://elevenlabs.io/app/sound-effects\n\nTile Breaking Sound:\nAI Generated from https://elevenlabs.io/app/sound-effects",

		"Level 5": "TileMap:\nhttps://raftenmg.itch.io/dark-environment-decoration-pack\n\nBackground Music:\nAI Generated from https://elevenlabs.io/app/sound-effects\n\nLantern:\nhttps://karsiori.itch.io/free-pixel-art-lantern-pack\n\nSpikes:\nhttps://www.rolimons.com/item/18510739029",

		"Level 6": "Everything is exactly the same as Level 4.",

		"Level 7": "TileMap:\nhttps://szadiart.itch.io/pixel-platformer-world\nhttps://raou.itch.io/dark-dun\n\nBackground Music:\nhttps://jinseig.itch.io/ayakashi",

		"Level 8": "Background Music:\nhttps://jinseig.itch.io/ayakashi\n\nEnemy Attack Audio Cues:\nAI Generated from https://elevenlabs.io/app/sound-effects\n\nEnemy Attack Spells:\nhttps://craftpix.net/freebies/free-pixel-magic-sprite-effects-pack/"
	}

	for section_name in sections:
		var scroll = ScrollContainer.new()
		scroll.name = section_name
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var label = Label.new()
		label.text = sections[section_name]
		label.add_theme_font_size_override("font_size", 38)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		scroll.add_child(label)
		tabs.add_child(scroll)

# -----------------------------------
# INSTRUCTIONS LABEL
# -----------------------------------

func setup_instructions():
	var vbox = get_node_or_null("SettingsPanel/VBoxContainer")
	if vbox == null:
		return

	var children = vbox.get_children()
	if children.size() > 3:
		return

	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(separator)

	var instructions_title = Label.new()
	instructions_title.text = "Controls"
	instructions_title.add_theme_font_size_override("font_size", 40)
	instructions_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	vbox.add_child(instructions_title)

	var instructions = Label.new()
	instructions.text = """A  —  Move Left
D  —  Move Right
Space  —  Jump
Space x2  —  Double Jump
L Shift  —  Defense
J  —  Attack 1
K  —  Attack 2
L  —  Attack 3"""
	instructions.add_theme_font_size_override("font_size", 35)
	instructions.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(instructions)

# -----------------------------------
# CLOSE BUTTON STYLING
# -----------------------------------

func style_close_button(btn: Button):
	if btn == null:
		return
	btn.text = "X"

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.8, 0.1, 0.1, 1)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(1.0, 0.2, 0.2, 1)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.6, 0.0, 0.0, 1)
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("pressed", style_pressed)

	btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn.add_theme_font_size_override("font_size", 36)

# -----------------------------------
# START, CONTINUE AND QUIT
# -----------------------------------

func _on_start_button_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_continue_button_pressed():
	var config = ConfigFile.new()
	var err = config.load("user://savegame.cfg")
	print("Continue pressed - load error: ", err)
	if err == OK:
		var last_scene = config.get_value("save", "last_scene", "")
		print("Continuing to: ", last_scene)
		if last_scene != "":
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color(0, 0, 0, 0), 0.5)
			await tween.finished
			get_tree().change_scene_to_file(last_scene)

func _on_quit_button_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	get_tree().quit()

# -----------------------------------
# SETTINGS PANEL
# -----------------------------------

func _on_settings_pressed():
	if settings_panel == null:
		return
	if references_panel and references_panel.visible:
		references_panel.visible = false
	resize_settings_panel()
	settings_panel.visible = true
	settings_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(settings_panel, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_close_settings_pressed():
	if settings_panel == null:
		return
	var tween = create_tween()
	tween.tween_property(settings_panel, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished
	settings_panel.visible = false
	save_settings()

# -----------------------------------
# REFERENCES PANEL
# -----------------------------------

func _on_references_pressed():
	if references_panel == null:
		return
	if settings_panel and settings_panel.visible:
		settings_panel.visible = false
	resize_references_panel()
	references_panel.visible = true
	references_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(references_panel, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_close_references_pressed():
	if references_panel == null:
		return
	var tween = create_tween()
	tween.tween_property(references_panel, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished
	references_panel.visible = false

func _on_volume_slider_changed(value: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_sfx_slider_changed(value: float):
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))

# -----------------------------------
# SAVE AND LOAD SETTINGS
# -----------------------------------

func save_settings():
	var config = ConfigFile.new()
	if volume_slider:
		config.set_value("audio", "volume", volume_slider.value)
	if sfx_slider:
		config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		if volume_slider:
			volume_slider.value = config.get_value("audio", "volume", 1.0)
			_on_volume_slider_changed(volume_slider.value)
		if sfx_slider:
			sfx_slider.value = config.get_value("audio", "sfx_volume", 1.0)
			_on_sfx_slider_changed(sfx_slider.value)
	else:
		if volume_slider:
			volume_slider.value = 1.0
		if sfx_slider:
			sfx_slider.value = 1.0

# -----------------------------------
# HOVER EFFECTS
# -----------------------------------

func _on_start_hover():
	if start_button == null:
		return
	start_button.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_start_unhover():
	if start_button == null:
		return
	start_button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.02, 1.0))
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_continue_hover():
	if continue_button == null:
		return
	continue_button.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
	var tween = create_tween()
	tween.tween_property(continue_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_continue_unhover():
	if continue_button == null:
		return
	continue_button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.02, 1.0))
	var tween = create_tween()
	tween.tween_property(continue_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_quit_hover():
	if quit_button == null:
		return
	quit_button.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
	var tween = create_tween()
	tween.tween_property(quit_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_quit_unhover():
	if quit_button == null:
		return
	quit_button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.02, 1.0))
	var tween = create_tween()
	tween.tween_property(quit_button, "scale", Vector2(1.0, 1.0), 0.1)

func _input(event):
	var settings_open = settings_panel != null and settings_panel.visible
	var references_open = references_panel != null and references_panel.visible

	if event.is_action_pressed("ui_accept"):
		if not settings_open and not references_open:
			_on_start_button_pressed()

	if event.is_action_pressed("ui_cancel"):
		if settings_open:
			_on_close_settings_pressed()
		elif references_open:
			_on_close_references_pressed()
