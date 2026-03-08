extends CanvasLayer

var settings_panel
var close_button
var volume_slider
var sfx_slider
var overlay

func _ready():
	settings_panel = get_node_or_null("SettingsPanel")
	close_button = get_node_or_null("SettingsPanel/CloseButton")
	volume_slider = get_node_or_null("SettingsPanel/VBoxContainer/VolumeRow/VolumeSlider")
	sfx_slider = get_node_or_null("SettingsPanel/VBoxContainer/SFXRow/SFXSlider")

	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.position = Vector2(0, 0)
	overlay.visible = false
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	move_child(overlay, 0)

	if settings_panel:
		settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS
		settings_panel.visible = false
		settings_panel.custom_minimum_size = Vector2(650, 550)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.4, 0.4, 0.5, 1)
		settings_panel.add_theme_stylebox_override("panel", style)

		center_panel()

	var title = get_node_or_null("SettingsPanel/SettingsTitle")
	if title:
		title.process_mode = Node.PROCESS_MODE_ALWAYS
		title.position = Vector2(0, 12)
		title.custom_minimum_size = Vector2(520, 20)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	if close_button:
		close_button.process_mode = Node.PROCESS_MODE_ALWAYS
		close_button.custom_minimum_size = Vector2(28, 28)
		close_button.position = Vector2(600, 5)
		if close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.disconnect(_on_close_pressed)
		if close_button.pressed.is_connected(_on_close_button_pressed):
			close_button.pressed.disconnect(_on_close_button_pressed)
		close_button.pressed.connect(_on_close_pressed)
		style_close_button()

	var vbox = get_node_or_null("SettingsPanel/VBoxContainer")
	if vbox:
		vbox.process_mode = Node.PROCESS_MODE_ALWAYS
		vbox.position = Vector2(40, 55)
		vbox.custom_minimum_size = Vector2(285, 0)

	var volume_label = get_node_or_null("SettingsPanel/VBoxContainer/VolumeRow/VolumeLabel")
	if volume_label:
		volume_label.custom_minimum_size = Vector2(100, 25)
		volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var sfx_label = get_node_or_null("SettingsPanel/VBoxContainer/SFXRow/SFXLabel")
	if sfx_label:
		sfx_label.custom_minimum_size = Vector2(100, 25)
		sfx_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if volume_slider:
		volume_slider.process_mode = Node.PROCESS_MODE_ALWAYS
		volume_slider.custom_minimum_size = Vector2(450, 35)
		if volume_slider.value_changed.is_connected(_on_volume_changed):
			volume_slider.value_changed.disconnect(_on_volume_changed)
		volume_slider.value_changed.connect(_on_volume_changed)

	if sfx_slider:
		sfx_slider.process_mode = Node.PROCESS_MODE_ALWAYS
		sfx_slider.custom_minimum_size = Vector2(450, 35)
		if sfx_slider.value_changed.is_connected(_on_sfx_changed):
			sfx_slider.value_changed.disconnect(_on_sfx_changed)
		sfx_slider.value_changed.connect(_on_sfx_changed)

	load_settings()

func center_panel():
	if settings_panel == null:
		return
	var screen_size = get_viewport().get_visible_rect().size
	var panel_size = settings_panel.custom_minimum_size
	settings_panel.position = Vector2(
		(screen_size.x - panel_size.x) / 2,
		(screen_size.y - panel_size.y) / 2
	)

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if settings_panel == null:
		return

	if get_tree().paused:
		get_tree().paused = false
		settings_panel.visible = false
		overlay.visible = false
	else:
		var screen_size = get_viewport().get_visible_rect().size
		overlay.size = screen_size
		overlay.position = Vector2(0, 0)

		center_panel()
		get_tree().paused = true
		overlay.visible = true
		settings_panel.visible = true
		settings_panel.modulate = Color(1, 1, 1, 0)
		overlay.modulate = Color(1, 1, 1, 0)
		var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(overlay, "modulate", Color(1, 1, 1, 1), 0.2)
		tween.tween_property(settings_panel, "modulate", Color(1, 1, 1, 1), 0.2)

func _on_close_pressed():
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(settings_panel, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished
	settings_panel.visible = false
	overlay.visible = false
	get_tree().paused = false
	save_settings()

func _on_close_button_pressed():
	_on_close_pressed()

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
	close_button.add_theme_font_size_override("font_size", 12)
