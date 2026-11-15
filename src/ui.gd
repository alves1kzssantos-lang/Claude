class_name UI
# Atalhos para montar a interface por código (cores, botões, painéis).

# Paleta "noite de estádio": verde-gramado escuro com dourado.
const BG := Color("06120d")
const BG2 := Color("0f2c21")
const PANEL := Color("123528")
const PANEL2 := Color("1b4a38")
const HEADER := Color("e6c56a")
const HEADER2 := Color("0a1d16")
const GOLD := Color("e6c56a")
const BLUE := Color("2463b8")   # contraste 5,3:1 com texto branco
const TXT := Color("eef2fa")
const MUTED := Color("9fbfb0")
const RED := Color("ad3450")    # 5,5:1
const GREEN := Color("237a47")  # 4,7:1 (fundo de botão)
const GREEN_TXT := Color("6fdc97")  ## verde para texto sobre fundo escuro
const RED_TXT := Color("ff8b8b")    ## vermelho para texto sobre fundo escuro
const DARKTXT := Color("0c1f17")

static var _bold: FontVariation


static func bold() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.8
	return _bold


static func sbox(color: Color, radius: int = 12, pad: int = 0, border: Color = Color(0, 0, 0, 0), bw: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.corner_detail = 10   # cantos bem redondos
	s.anti_aliasing = true
	s.set_content_margin_all(pad)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	return s


static func label(text: String, size: int = 18, color: Color = TXT, is_bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if is_bold:
		l.add_theme_font_override("font", bold())
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func button(text: String, kind: String = "dark", cb: Callable = Callable(), size: int = 18, min_h: int = 46) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_h)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.clip_text = true
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_font_override("font", bold())
	style_button(b, kind)
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func style_button(b: Button, kind: String) -> void:
	var bg := PANEL2
	var fg := TXT
	match kind:
		"gold":
			bg = GOLD
			fg = DARKTXT
		"blue":
			bg = BLUE
		"red":
			bg = RED
		"green":
			bg = GREEN
		"flat":
			bg = Color(1, 1, 1, 0.04)
	b.add_theme_stylebox_override("normal", sbox(bg, 14, 10))
	b.add_theme_stylebox_override("hover", sbox(bg.lightened(0.08), 14, 10))
	b.add_theme_stylebox_override("pressed", sbox(bg.darkened(0.15), 14, 10))
	b.add_theme_stylebox_override("disabled", sbox(Color(bg, 0.35), 14, 10))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.5))


static func panel(color: Color = PANEL, pad: int = 14, radius: int = 18) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sbox(color, radius, pad))
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p


static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	return h


static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	return v


static func grid(cols: int, sep: int = 8) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", sep)
	g.add_theme_constant_override("v_separation", sep)
	g.mouse_filter = Control.MOUSE_FILTER_PASS
	return g


static func expand(c: Control, ratio: float = 1.0) -> Control:
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = ratio
	return c


static func vexpand(c: Control) -> Control:
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func fixed(c: Control, w: float, h: float = 0.0) -> Control:
	c.custom_minimum_size = Vector2(w, h)
	return c


static func scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return s


static func pos_color(pos: String) -> Color:
	if pos == "GOL":
		return Color("e79a3c")
	if pos in ["ZAG", "LD", "LE"]:
		return Color("e0c25c")
	if pos in ["VOL", "MEI"]:
		return Color("6fca8a")
	return Color("7fb4ee")


static func pos_tag(pos: String, size: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sbox(pos_color(pos), 5, 3))
	p.custom_minimum_size = Vector2(size * 3.4, 0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(center(label(pos, size, DARKTXT, true)))
	return p


static func col(text: String, w: float, size: int = 16, color: Color = TXT, is_bold: bool = false, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := label(text, size, color, is_bold)
	l.custom_minimum_size = Vector2(w, 0)
	l.horizontal_alignment = align
	l.clip_text = true
	return l


static func card_title(text: String) -> Label:
	return label(text, 14, MUTED, true)


static func clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


static func _ignore(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore(c)


# Botão que leva qualquer conteúdo dentro (linha de lista, cartão clicável)
static func row_button(content: Control, cb: Callable = Callable(), min_h: int = 50, kind: String = "flat", pad: int = 10) -> Button:
	var b := button("", kind, cb, 16, min_h)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", pad)
	mc.add_theme_constant_override("margin_right", pad)
	mc.add_theme_constant_override("margin_top", 4)
	mc.add_theme_constant_override("margin_bottom", 4)
	b.add_child(mc)
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_child(content)
	_ignore(mc)
	return b


static func stepper(text: String, minus: Callable, plus: Callable, w: float = 150.0) -> HBoxContainer:
	var h := hbox(6)
	h.add_child(fixed(button("−", "dark", minus, 22), 52))
	var l := center(label(text, 19, TXT, true))
	l.custom_minimum_size = Vector2(w, 0)
	h.add_child(l)
	h.add_child(fixed(button("+", "dark", plus, 22), 52))
	return h


static func field(title: String, c: Control) -> VBoxContainer:
	var v := vbox(4)
	v.add_child(label(title, 13, MUTED))
	v.add_child(c)
	return v


static func bar(frac: float, color: Color = GOLD, h: float = 6.0) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.min_value = 0.0
	pb.max_value = 1.0
	pb.value = clampf(frac, 0.0, 1.0)
	pb.custom_minimum_size = Vector2(0, h)
	pb.add_theme_stylebox_override("background", sbox(Color(1, 1, 1, 0.1), 3))
	pb.add_theme_stylebox_override("fill", sbox(color, 3))
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb
