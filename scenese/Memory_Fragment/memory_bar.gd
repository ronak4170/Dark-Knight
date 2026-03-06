extends CanvasLayer

@onready var progress_bar: ProgressBar = $Control/VBoxContainer/ProgressBar
@onready var counter_label: Label = $Control/VBoxContainer/HBoxContainer/CounterLabel
@onready var title_label: Label = $Control/VBoxContainer/HBoxContainer/TitleLabel
@onready var panel: Panel = $Control/Panel

func _ready():
	await get_tree().process_frame

	if not Global.memory_updated.is_connected(_on_memory_updated):
		Global.memory_updated.connect(_on_memory_updated)

	_setup_styles()

	var total = max(Global.memory_total, 1)
	progress_bar.max_value = total
	progress_bar.value = Global.memory_collected
	_update_display(Global.memory_collected, Global.memory_total)

func _setup_styles():
	if not panel or not progress_bar:
		return

	# panel dark background with purple border
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.04, 0.1, 0.9)
	panel_style.set_corner_radius_all(10)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.5, 0.2, 0.9, 1.0)
	panel_style.shadow_color = Color(0.5, 0.2, 0.9, 0.5)
	panel_style.shadow_size = 6
	# add padding inside panel
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", panel_style)

	# bar empty background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.08, 0.15, 1.0)
	bg_style.set_corner_radius_all(8)
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Color(0.3, 0.1, 0.6, 0.8)
	progress_bar.add_theme_stylebox_override("background", bg_style)

	# bar fill — bright purple glow
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.5, 0.15, 1.0, 1.0)
	fill_style.set_corner_radius_all(8)
	fill_style.shadow_color = Color(0.6, 0.3, 1.0, 0.8)
	fill_style.shadow_size = 4
	progress_bar.add_theme_stylebox_override("fill", fill_style)

	# BIGGER font sizes
	if title_label:
		title_label.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0, 1.0))
		title_label.add_theme_font_size_override("font_size", 18)  # ← bigger
	if counter_label:
		counter_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		counter_label.add_theme_font_size_override("font_size", 18)  # ← bigger

func _on_memory_updated(current: int, total: int):
	progress_bar.max_value = max(total, 1)
	# smooth fill animation
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", float(current), 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# flash effect on collect
	_flash_panel()
	_update_display(current, total)

func _flash_panel():
	# brief white flash when collecting
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
	tween.tween_property(panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func _update_display(current: int, total: int):
	if counter_label:
		counter_label.text = "%d / %d" % [current, total]
