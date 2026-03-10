extends CanvasLayer

var pause_panel
var resume_button
var menu_button
var quit_button
var settings_button_pause
var overlay

var settings_panel
var close_button
var volume_slider
var sfx_slider

const MAIN_MENU = "res://scenese/main_menu.tscn"

func _ready():
	pause_panel = get_node_or_null("PausePanel")
	resume_button = get_node_or_null("PausePanel/ResumeButton")
	menu_button = get_node_or_null("PausePanel/MenuButton")
	quit_button = get_node_or_null("PausePanel/QuitButton")
	settings_button_pause = get_node_or_null("PausePanel/SettingsButton")

	settings_panel = get_node_or_null("SettingsPanel")
	close_button = get_node_or_null("SettingsPanel/CloseButton")
	volume_slider = get_node_or_null("SettingsPanel/VBoxContainer/VolumeRow/VolumeSlider")
	sfx_slider = get_node_or_null("SettingsPanel/VBoxContainer/SFXRow/SFXSlider")

	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.position = Vector2(0, 0)
	overlay.visible = false
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	move_child(overlay, 0)

	if pause_panel:
		pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_panel.visible = false
		style_pause_panel()

	if resume_button:
		resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
		resume_button.pressed.connect(_on_resume_pressed)
		style_button(resume_button, "RESUME")

	if settings_button_pause:
		settings_button_pause.process_mode = Node.PROCESS_MODE_ALWAYS
		settings_button_pause.pressed.connect(_on_settings_button_pressed)
		style_button(settings_button_pause, "SETTINGS")

	if menu_button:
		menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
		menu_button.pressed.connect(_on_menu_pressed)
		style_button(menu_button, "MENU")

	if quit_button:
		quit_button.process_mode = Node.PROCESS_MODE_ALWAYS
		quit_button.pressed.connect(_on_quit_pressed)
		style_button(quit_button, "QUIT")

	if settings_panel:
		settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		settings_panel.visible = false
		setup_settings_panel()

	if volume_slider:
		volume_slider.process_mode = Node.PROCESS_MODE_ALWAYS
		if volume_slider.value_changed.is_connected(_on_volume_changed):
			volume_slider.value_changed.disconnect(_on_volume_changed)
		volume_slider.value_changed.connect(_on_volume_changed)

	if sfx_slider:
		sfx_slider.process_mode = Node.PROCESS_MODE_ALWAYS
		if sfx_slider.value_changed.is_connected(_on_sfx_changed):
			sfx_slider.value_changed.disconnect(_on_sfx_changed)
		sfx_slider.value_changed.connect(_on_sfx_changed)

	if close_button:
		close_button.process_mode = Node.PROCESS_MODE_ALWAYS
		if close_button.pressed.is_connected(_on_close_settings_pressed):
			close_button.pressed.disconnect(_on_close_settings_pressed)
		close_button.pressed.connect(_on_close_settings_pressed)
		style_close_button()

	await get_tree().process_frame
	var sfx_lbl = get_node_or_null("SettingsPanel/VBoxContainer/SFXRow/SFXLabel")
	if sfx_lbl:
		sfx_lbl.add_theme_font_size_override("font_size", 20)
		sfx_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 1.0, 1))

	var vol_lbl = get_node_or_null("SettingsPanel/VBoxContainer/VolumeRow/VolumeLabel")
	if vol_lbl:
		vol_lbl.add_theme_font_size_override("font_size", 20)
		vol_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 1.0, 1))

	load_settings()

# -----------------------------------
# PAUSE PANEL SETUP
# -----------------------------------

func style_pause_panel():
	if pause_panel == null:
		return

	var screen_size = get_viewport().get_visible_rect().size
	var panel_w = 450.0
	var panel_h = 580.0
	pause_panel.custom_minimum_size = Vector2(panel_w, panel_h)
	pause_panel.position = Vector2(
		(screen_size.x - panel_w) / 2,
		(screen_size.y - panel_h) / 2
	)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.12, 0.98)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.25, 0.25, 0.4, 1)
	pause_panel.add_theme_stylebox_override("panel", style)

	var title = get_node_or_null("PausePanel/PausedTitle")
	if title:
		title.text = "PAUSED"
		title.position = Vector2(0, 24)
		title.custom_minimum_size = Vector2(panel_w, 0)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 54)
		title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0, 1))

	var btn_y = [110.0, 220.0, 330.0, 440.0]
	var buttons = [resume_button, settings_button_pause, menu_button, quit_button]
	for i in range(buttons.size()):
		if buttons[i]:
			buttons[i].position = Vector2(50, btn_y[i])
			buttons[i].custom_minimum_size = Vector2(350, 85)

# -----------------------------------
# SETTINGS PANEL SETUP
# -----------------------------------

func setup_settings_panel():
	if settings_panel == null:
		return

	var panel_w = 600.0
	var panel_h = 400.0
	settings_panel.custom_minimum_size = Vector2(panel_w, panel_h)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.12, 0.98)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.25, 0.25, 0.4, 1)
	settings_panel.add_theme_stylebox_override("panel", style)

	if close_button:
		close_button.custom_minimum_size = Vector2(32, 32)
		close_button.position = Vector2(panel_w - 50, 6)

	var title = get_node_or_null("SettingsPanel/SettingsTitle")
	if title:
		title.position = Vector2(0, 15)
		title.custom_minimum_size = Vector2(panel_w, 0)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 32)
		title.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0, 1))

	var vbox = get_node_or_null("SettingsPanel/VBoxContainer")
	if vbox:
		vbox.process_mode = Node.PROCESS_MODE_ALWAYS
		vbox.position = Vector2(40, 80)
		vbox.custom_minimum_size = Vector2(panel_w - 80, 0)
		vbox.add_theme_constant_override("separation", 20)

# -----------------------------------
# BUTTON STYLING
# -----------------------------------

func style_button(btn: Button, label: String):
	if btn == null:
		return
	btn.text = label

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.12, 0.12, 0.2, 1)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_color = Color(0.3, 0.3, 0.55, 1)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.18, 0.18, 0.35, 1)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_color = Color(0.5, 0.5, 0.9, 1)
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.06, 0.06, 0.12, 1)
	style_pressed.corner_radius_top_left = 8
	style_pressed.corner_radius_top_right = 8
	style_pressed.corner_radius_bottom_left = 8
	style_pressed.corner_radius_bottom_right = 8
	style_pressed.border_width_top = 2
	style_pressed.border_width_bottom = 2
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_color = Color(0.2, 0.2, 0.4, 1)
	btn.add_theme_stylebox_override("pressed", style_pressed)

	btn.add_theme_color_override("font_color", Color(0.75, 0.75, 1.0, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.5, 0.5, 0.8, 1))
	btn.add_theme_font_size_override("font_size", 32)

func style_close_button():
	if close_button == null:
		return
	close_button.text = "X"

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.8, 0.1, 0.1, 1)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	close_button.add_theme_stylebox_override("normal", style_normal)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(1.0, 0.2, 0.2, 1)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	close_button.add_theme_stylebox_override("hover", style_hover)

	close_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	close_button.add_theme_font_size_override("font_size", 14)

# -----------------------------------
# PROCESS
# -----------------------------------

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	if Input.is_action_just_pressed("resume"):
		if get_tree().paused:
			toggle_pause()

func toggle_pause():
	if pause_panel == null:
		return

	if get_tree().paused:
		get_tree().paused = false
		pause_panel.visible = false
		if settings_panel:
			settings_panel.visible = false
		overlay.visible = false
	else:
		var screen_size = get_viewport().get_visible_rect().size
		overlay.size = screen_size
		pause_panel.position = Vector2(
			(screen_size.x - pause_panel.custom_minimum_size.x) / 2,
			(screen_size.y - pause_panel.custom_minimum_size.y) / 2
		)
		get_tree().paused = true
		overlay.visible = true
		pause_panel.visible = true
		pause_panel.modulate = Color(1, 1, 1, 0)
		overlay.modulate = Color(1, 1, 1, 0)
		var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(overlay, "modulate", Color(1, 1, 1, 1), 0.2)
		tween.tween_property(pause_panel, "modulate", Color(1, 1, 1, 1), 0.2)

# -----------------------------------
# BUTTON CALLBACKS
# -----------------------------------

func _on_resume_pressed():
	toggle_pause()

func _on_settings_button_pressed():
	if settings_panel == null:
		return
	var screen_size = get_viewport().get_visible_rect().size
	var panel_w = settings_panel.custom_minimum_size.x
	var panel_h = settings_panel.custom_minimum_size.y
	settings_panel.position = Vector2(
		(screen_size.x - panel_w) / 2,
		(screen_size.y - panel_h) / 2
	)
	pause_panel.visible = false
	settings_panel.visible = true
	settings_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(settings_panel, "modulate", Color(1, 1, 1, 1), 0.2)

func _on_close_settings_pressed():
	if settings_panel == null:
		return
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(settings_panel, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished
	settings_panel.visible = false
	pause_panel.visible = true
	save_settings()

func _on_menu_pressed():
	var scene_path = get_tree().current_scene.scene_file_path
	print("Saving scene: ", scene_path)
	var config = ConfigFile.new()
	config.set_value("save", "last_scene", scene_path)
	config.save("user://savegame.cfg")
	print("Saved to: ", "user://savegame.cfg")
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)

func _on_quit_pressed():
	get_tree().quit()

# -----------------------------------
# AUDIO
# -----------------------------------

func _on_volume_changed(value: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_sfx_changed(value: float):
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))

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
			_on_volume_changed(volume_slider.value)
		if sfx_slider:
			sfx_slider.value = config.get_value("audio", "sfx_volume", 1.0)
			_on_sfx_changed(sfx_slider.value)
	else:
		if volume_slider:
			volume_slider.value = 1.0
		if sfx_slider:
			sfx_slider.value = 1.0
