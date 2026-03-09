extends Node2D

const GAME_SCENE = "res://scenese/Level_1_Scene/level_1.tscn"

var title
var start_button
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
	quit_button = get_node_or_null("QuitButton")
	animation_player = get_node_or_null("AnimationPlayer")
	settings_button = get_node_or_null("Settings")
	settings_panel = get_node_or_null("SettingsPanel")
	volume_slider = get_node_or_null("SettingsPanel/VBoxContainer/VolumeRow/VolumeSlider")
	sfx_slider = get_node_or_null("SettingsPanel/VBoxContainer/SFXRow/SFXSlider")
	close_button = get_node_or_null("SettingsPanel/CloseButton")
	references_button = get_node_or_null("references")
	references_panel = get_node_or_null("ReferencesPanel")

	# Try both possible close button names
	close_ref_button = get_node_or_null("ReferencesPanel/CloseButtonRef")
	if close_ref_button == null:
		close_ref_button = get_node_or_null("ReferencesPanel/CloseButton")

	modulate = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 1.0)

	if settings_panel:
		settings_panel.visible = false

	if references_panel:
		references_panel.visible = false

	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
		start_button.mouse_entered.connect(_on_start_hover)
		start_button.mouse_exited.connect(_on_start_unhover)

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
	else:
		push_error("ReferencesPanel close button not found — check node is named CloseButtonRef or CloseButton")

	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_slider_changed)

	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	setup_instructions()
	setup_references_content()
	load_settings()

# -----------------------------------
# REFERENCES PANEL CONTENT
# -----------------------------------

func setup_references_content():
	var vbox = get_node_or_null("ReferencesPanel/VBoxContainer")
	if vbox == null:
		push_error("ReferencesPanel/VBoxContainer not found")
		return

	# Clear any existing children to avoid duplicates on reload
	for child in vbox.get_children():
		child.queue_free()

	# Force VBoxContainer to be wide enough
	vbox.custom_minimum_size = Vector2(260, 0)

	var ref_title = Label.new()
	ref_title.text = "References"
	ref_title.add_theme_font_size_override("font_size", 16)
	ref_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	ref_title.custom_minimum_size = Vector2(260, 0)
	vbox.add_child(ref_title)

	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(260, 10)
	vbox.add_child(separator)

	var content = Label.new()
	content.text = "Art Assets:\\ndungeon_sidescroller by Raou\\n\\nCharacter Sprites:\\nDark Knight by Pixel Artist\\n\\nMusic & SFX:\\nFree Game Assets"
	content.add_theme_font_size_override("font_size", 12)
	content.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	content.autowrap_mode = TextServer.AUTOWRAP_WORD
	content.custom_minimum_size = Vector2(260, 0)
	vbox.add_child(content)

# -----------------------------------
# INSTRUCTIONS LABEL
# -----------------------------------

func setup_instructions():
	var vbox = get_node_or_null("SettingsPanel/VBoxContainer")
	if vbox == null:
		return

	# Clear existing dynamic children to avoid duplicates
	var static_count = 3 # SettingsTitle, VolumeRow, SFXRow
	var children = vbox.get_children()
	if children.size() > static_count:
		return

	var separator = HSeparator.new()
	vbox.add_child(separator)

	var instructions_title = Label.new()
	instructions_title.text = "Controls"
	instructions_title.add_theme_font_size_override("font_size", 14)
	instructions_title.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	vbox.add_child(instructions_title)

	var instructions = Label.new()
	instructions.text = "A  —  Move Left\\nD  —  Move Right\\nSpace  —  Jump\\nSpace x2  —  Double Jump\\nL Shift  —  Defense\\nMouse Click  —  Attack 1\\nMouse Click x2  —  Attack 2\\nMouse Click x3  —  Attack 3"
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(instructions)

# -----------------------------------
# CLOSE BUTTON STYLING
# -----------------------------------

func style_close_button(btn : Button):
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
	btn.add_theme_font_size_override("font_size", 14)

# -----------------------------------
# START AND QUIT
# -----------------------------------

func _on_start_button_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	get_tree().change_scene_to_file(GAME_SCENE)

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
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_start_unhover():
	if start_button == null:
		return
	var tween = create_tween()
	tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_quit_hover():
	if quit_button == null:
		return
	var tween = create_tween()
	tween.tween_property(quit_button, "scale", Vector2(1.1, 1.1), 0.1)

func _on_quit_unhover():
	if quit_button == null:
		return
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
