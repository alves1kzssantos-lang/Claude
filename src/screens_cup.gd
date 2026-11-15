class_name CupScreens
extends RefCounted
## Telas de copa no estilo "resultados da fase": faixa de cabeçalho com a logo do
## campeonato, aba COMPETIÇÃO, fundo temático animado, faixas de resultado e ticker.
## Telas: cup_results (resultados de uma etapa) e cup (chaveamento).

var m

## Fundos temáticos (desenhados em Backdrop).
const BG_STRIPES := "listras"   # Copa do Brasil
const BG_RAIN := "chuva"        # Libertadores
const BG_STARS := "estrelas"    # Champions League
const BG_PITCH := "gramado"     # demais copas e ligas

const STRIP := Color("c9cad2")
const STRIP_EDGE := Color("a9abb6")
const WIN_TXT := Color("1b1d22")
const LOSE_TXT := Color("6b6e78")


func _init(main) -> void:
	m = main


# ============================================================ tema
## Paleta e fundo da competição pelo nome.
static func theme_for(comp_name: String) -> Dictionary:
	var n := comp_name.to_lower()
	if "copa do brasil" in n:
		return {"bg": BG_STRIPES, "bg1": Color("15164a"), "bg2": Color("34376e"),
			"head": Color("f4f5f8"), "head2": Color("e4e5ea"), "title": Color("1537a3"), "sub": Color("1537a3"),
			"btn": Color("1b2f7a"), "btn2": Color("0d1850"), "btn_txt": Color.WHITE,
			"tab": Color("e4e5ea"), "tab_txt": Color("1537a3"), "accent": Color("c99a3a"), "icon": Color("1b3f9a")}
	if "libertadores" in n:
		return {"bg": BG_RAIN, "bg1": Color("080a3c"), "bg2": Color("0e1260"),
			"head": Color("1c1c1c"), "head2": Color("141414"), "title": Color("e6bf62"), "sub": Color("e6bf62"),
			"btn": Color("13c27a"), "btn2": Color("1f8f3e"), "btn_txt": Color.WHITE,
			"tab": Color("101010"), "tab_txt": Color("e6bf62"), "accent": Color("c99a3a"), "icon": Color("1c1c1c")}
	if "champions" in n:
		return {"bg": BG_STARS, "bg1": Color("040b2c"), "bg2": Color("0b1a55"),
			"head": Color("0a1442"), "head2": Color("071034"), "title": Color.WHITE, "sub": Color("8fb3ff"),
			"btn": Color("2f7de1"), "btn2": Color("1a4fb0"), "btn_txt": Color.WHITE,
			"tab": Color("071034"), "tab_txt": Color("cfe0ff"), "accent": Color("8fb3ff"), "icon": Color("1a3a8a")}
	return {"bg": BG_PITCH, "bg1": UI.BG, "bg2": UI.BG2,
		"head": UI.HEADER2, "head2": Color("07160f"), "title": UI.GOLD, "sub": UI.MUTED,
		"btn": UI.GOLD, "btn2": Color("c9a54a"), "btn_txt": UI.DARKTXT,
		"tab": UI.HEADER2, "tab_txt": UI.GOLD, "accent": UI.GOLD, "icon": UI.PANEL2}


## Logo da copa no datapack (ou null).
static func cup_logo(c: Dictionary) -> Texture2D:
	var cid: int = int(World.CUPS[int(c["def"])].get("comp", -1))
	return DataPack.comp_logo_by_id(cid) if cid >= 0 else null


## Estilo da taça na celebração: prata para as continentais.
static func trophy_style(comp_name: String) -> String:
	var n := comp_name.to_lower()
	return "prata" if ("libertadores" in n or "champions" in n) else "ouro"


## Toca a celebração do título (src/trophy_celebration.gd) sem depender dele na compilação.
static func celebrate(parent: Control, comp_name: String, club_name: String, logo: Texture2D, style: String) -> Object:
	var path := "res://src/trophy_celebration.gd"
	if parent == null or not ResourceLoader.exists(path):
		return null
	var sc: Script = load(path)
	if sc == null:
		return null
	return sc.call("play", parent, comp_name, club_name, logo, style)


## Celebra uma lista de títulos em sequência: [{"comp", "logo", "style"}].
static func celebrate_queue(parent: Control, club_name: String, items: Array) -> void:
	if items.is_empty():
		return
	var it: Dictionary = items[0]
	var rest: Array = items.slice(1)
	var tc: Object = celebrate(parent, str(it["comp"]), club_name, it.get("logo"), str(it["style"]))
	if tc != null and not rest.is_empty() and tc.has_signal("done"):
		tc.connect("done", func(): celebrate_queue(parent, club_name, rest), CONNECT_ONE_SHOT)


## Celebra a copa ci se o clube do jogador é o campeão e ainda não celebrou.
func maybe_celebrate_cup(ci: int) -> void:
	var c: Dictionary = Game.S["cups"][ci]
	if int(c["champion"]) != int(Game.S["club"]) or bool(c.get("celebrated", false)):
		return
	c["celebrated"] = true
	celebrate(m.overlay, str(c["name"]), Game.club_name(Game.S["club"]), cup_logo(c), trophy_style(str(c["name"])))


# ============================================================ dados (tolerante a versões de Cups)
static func _cups_has(method: String) -> bool:
	for d in (Cups as Script).get_script_method_list():
		if str(d.get("name", "")) == method:
			return true
	return false


## Chama uma função estática de Cups pelo nome (pode não existir em versões antigas).
static func _cups_call(method: String, args: Array) -> Variant:
	var sc: Object = Cups as Script
	return sc.callv(method, args)


## Quantas etapas a copa tem (datas).
static func stage_count(c: Dictionary) -> int:
	if _cups_has("stages"):
		var arr: Array = _cups_call("stages", [c])
		return arr.size()
	return c["days"].size()


## Nome da etapa para o cabeçalho.
static func stage_title(c: Dictionary, stage: int) -> String:
	if _cups_has("stage_name"):
		return str(_cups_call("stage_name", [c, stage]))
	return Cups.round_name(c, stage)


## Resultados normalizados da etapa: lista de {"h","a","hg","ag","agg_h","agg_a","pens","w","leg"}.
static func stage_rows(ci: int, stage: int) -> Array:
	if _cups_has("stage_results"):
		var res: Array = _cups_call("stage_results", [ci, stage])
		return res
	var c: Dictionary = Game.S["cups"][ci]
	var out: Array = []
	if stage < 0 or stage >= c["rounds"].size():
		return out
	for t in c["rounds"][stage]:
		out.append({"h": t["h"], "a": t["a"], "hg": int(t["hg"]), "ag": int(t["ag"]), "agg_h": int(t["hg"]), "agg_a": int(t["ag"]),
			"pens": t.get("pens", []), "w": int(t.get("w", -1)), "leg": 1})
	return out


# ============================================================ montagem comum
## Palco que ocupa a tela toda abaixo do cabeçalho do jogo (passa por cima das margens do body).
func _stage(root: Control, th: Dictionary) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(holder)
	var full := Control.new()
	full.mouse_filter = Control.MOUSE_FILTER_PASS
	full.clip_contents = true
	holder.add_child(full)
	full.anchor_right = 1.0
	full.anchor_bottom = 1.0
	full.offset_left = -float(root.get_theme_constant("margin_left"))
	full.offset_right = float(root.get_theme_constant("margin_right"))
	full.offset_top = -float(root.get_theme_constant("margin_top"))
	full.offset_bottom = float(root.get_theme_constant("margin_bottom"))
	var bd := Backdrop.new()
	bd.kind = str(th["bg"])
	bd.c1 = th["bg1"]
	bd.c2 = th["bg2"]
	bd.accent = th["accent"]
	full.add_child(bd)
	bd.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return full


## Faixa do cabeçalho + aba COMPETIÇÃO. Devolve a VBox de conteúdo abaixo.
func _frame(full: Control, th: Dictionary, logo: Texture2D, title: String, sub: String, btn_text: String, btn_cb: Callable,
		tab_cb: Callable) -> VBoxContainer:
	var v := UI.vbox(0)
	full.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var band := HeadBand.new()
	band.c1 = th["head"]
	band.c2 = th["head2"]
	band.custom_minimum_size = Vector2(0, 92)
	v.add_child(band)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 40)
	mc.add_theme_constant_override("margin_right", 40)
	mc.mouse_filter = Control.MOUSE_FILTER_PASS
	band.add_child(mc)
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var hb := UI.hbox(18)
	mc.add_child(hb)
	var lg := LogoMark.new()
	lg.tex = logo
	lg.accent = th["accent"]
	lg.ink = th["title"]
	lg.custom_minimum_size = Vector2(74, 74)
	lg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(lg)
	var tv := UI.vbox(-4)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.expand(tv)
	var tl := UI.label(title, 32, th["title"], true)
	tl.clip_text = true
	var sl := UI.label(sub, 21, th["sub"], true)
	sl.clip_text = true
	tv.add_child(tl)
	tv.add_child(sl)
	hb.add_child(tv)
	if btn_text != "":
		hb.add_child(_continue_button(btn_text, th, btn_cb))
	# aba pendurada + cantinho dourado
	var tabrow := Control.new()
	tabrow.custom_minimum_size = Vector2(0, 40)
	tabrow.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(tabrow)
	var tab := Button.new()
	tab.text = "COMPETIÇÃO"
	tab.focus_mode = Control.FOCUS_NONE
	tab.add_theme_font_override("font", UI.bold())
	tab.add_theme_font_size_override("font_size", 16)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		tab.add_theme_color_override(k, th["tab_txt"])
	for st in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = th["tab"] if st == "normal" else (th["tab"] as Color).lightened(0.06)
		sb.corner_radius_bottom_left = 8
		sb.corner_radius_bottom_right = 8
		sb.corner_detail = 8
		sb.anti_aliasing = true
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		tab.add_theme_stylebox_override(st, sb)
	tab.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if tab_cb.is_valid():
		tab.pressed.connect(tab_cb)
	else:
		tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabrow.add_child(tab)
	tab.position = Vector2(80, 0)
	tab.size = Vector2(0, 38)
	var corner := Corner.new()
	corner.color = th["accent"]
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tabrow.add_child(corner)
	corner.anchor_left = 1.0
	corner.anchor_right = 1.0
	corner.offset_left = -30
	corner.offset_bottom = 30
	var body := UI.vbox(0)
	UI.vexpand(body)
	v.add_child(body)
	return body


func _continue_button(text: String, th: Dictionary, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(260, 58)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", UI.bold())
	b.add_theme_font_size_override("font_size", 25)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, th["btn_txt"])
	var states := {"normal": th["btn"], "hover": (th["btn"] as Color).lightened(0.08), "pressed": th["btn2"]}
	for st in states:
		var sb := UI.sbox(states[st], 8, 0)
		sb.content_margin_left = 30
		sb.content_margin_right = 52
		sb.border_color = th["btn2"]
		sb.border_width_bottom = 4
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if cb.is_valid():
		b.pressed.connect(cb)
	var tri := Arrow.new()
	tri.color = th["btn_txt"]
	tri.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tri)
	tri.anchor_left = 1.0
	tri.anchor_right = 1.0
	tri.anchor_top = 0.5
	tri.anchor_bottom = 0.5
	tri.offset_left = -46
	tri.offset_right = -26
	tri.offset_top = -12
	tri.offset_bottom = 10
	return b


## Ticker de notícia no rodapé.
func _ticker(body: Control, th: Dictionary, text: String) -> void:
	if text == "":
		return
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 80)
	mc.add_theme_constant_override("margin_bottom", 22)
	mc.add_theme_constant_override("margin_top", 8)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(mc)
	var h := UI.hbox(0)
	h.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mc.add_child(h)
	var ic := PanelContainer.new()
	var isb := StyleBoxFlat.new()
	isb.bg_color = th["icon"]
	isb.corner_radius_top_left = 6
	isb.corner_radius_bottom_left = 6
	isb.anti_aliasing = true
	ic.add_theme_stylebox_override("panel", isb)
	var lines := NewsIcon.new()
	lines.custom_minimum_size = Vector2(46, 36)
	ic.add_child(lines)
	h.add_child(ic)
	var tp := PanelContainer.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color("fbfbfd")
	tsb.corner_radius_top_right = 6
	tsb.corner_radius_bottom_right = 6
	tsb.anti_aliasing = true
	tsb.content_margin_left = 14
	tsb.content_margin_right = 16
	tp.add_theme_stylebox_override("panel", tsb)
	var l := UI.label(text, 19, Color("15171c"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tp.add_child(l)
	h.add_child(tp)
	h.modulate.a = 0.0
	var tw := h.create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(h, "modulate:a", 1.0, 0.4)


## "na Final", "nas Oitavas de final", "nos 16-avos de final".
static func _in_stage(stage_name: String) -> String:
	var low := stage_name.to_lower()
	if low.begins_with("oitavas") or low.begins_with("quartas") or low.begins_with("semi finais"):
		return "nas " + stage_name
	if "avos" in low:
		return "nos " + stage_name
	return "na " + stage_name


static func _round_only(stage_name: String) -> String:
	var i := stage_name.find(" - ")
	return stage_name.substr(0, i) if i >= 0 else stage_name


# ============================================================ cup_results
## Resultados de uma etapa da copa. arg {"cup": índice, "stage": etapa ou -1 (última jogada), "next": bool}.
func cup_results(root: Control, arg) -> void:
	var a: Dictionary = arg if typeof(arg) == TYPE_DICTIONARY else {}
	var ci: int = int(a.get("cup", 0))
	var c: Dictionary = Game.S["cups"][ci]
	var stage: int = int(a.get("stage", -1))
	if stage < 0:
		stage = int(c["next"]) - 1
	stage = clampi(stage, 0, maxi(stage_count(c) - 1, 0))
	var is_next: bool = bool(a.get("next", false))
	var sname := stage_title(c, stage)
	m.head(str(c["name"]), "Resultados • " + sname, not is_next)
	m.bare()
	var th := theme_for(str(c["name"]))
	var full := _stage(root, th)
	var cont := func():
		if is_next:
			m.home()
		else:
			m.back()
	var body := _frame(full, th, cup_logo(c), str(c["name"]), sname + " - Resultados", "CONTINUAR", cont,
		func(): m.go("cup", {"cup": ci, "next": false}))
	var rows := stage_rows(ci, stage)
	var many := rows.size() > 6
	var sc := UI.scroll()
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER if not many else ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(sc)
	var list := UI.vbox(6 if many else 10)
	list.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.expand(list)
	UI.vexpand(list)
	sc.add_child(list)
	if rows.is_empty():
		list.add_child(UI.center(UI.label("Os confrontos desta fase ainda não foram sorteados.", 20, Color(1, 1, 1, 0.75), true)))
	var mine := {}
	var i := 0
	for e in rows:
		var strip := _result_strip(e, 48 if many else 62)
		list.add_child(strip)
		strip.modulate.a = 0.0
		var tw := strip.create_tween()
		tw.tween_interval(0.08 + 0.05 * i)
		tw.tween_property(strip, "modulate:a", 1.0, 0.3)
		i += 1
		if int(e["h"]) == int(Game.S["club"]) or int(e["a"]) == int(Game.S["club"]):
			mine = e
	if not many:
		# empurra a lista para o meio, como na referência
		list.add_theme_constant_override("separation", 10)
	var feat: Dictionary = mine if not mine.is_empty() else (rows[rows.size() - 1] if not rows.is_empty() else {})
	var news := ""
	if not feat.is_empty() and int(feat["hg"]) >= 0:
		var hw: bool = int(feat["hg"]) > int(feat["ag"])
		if int(feat["hg"]) == int(feat["ag"]):
			hw = int(feat.get("w", -1)) != int(feat["a"])
		var n1: int = int(feat["h"]) if hw else int(feat["a"])
		var n2: int = int(feat["a"]) if hw else int(feat["h"])
		var g1: int = maxi(int(feat["hg"]), int(feat["ag"]))
		var g2: int = mini(int(feat["hg"]), int(feat["ag"]))
		news = "%s %d-%d %s %s da %s" % [Game.club_name(n1), g1, g2, Game.club_name(n2), _in_stage(_round_only(sname)), c["name"]]
	_ticker(body, th, news)
	if int(c["champion"]) >= 0 and stage >= stage_count(c) - 1:
		maybe_celebrate_cup(ci)


## Faixa cinza de ponta a ponta com um resultado.
func _result_strip(e: Dictionary, h: int) -> Control:
	var strip := Strip.new()
	strip.custom_minimum_size = Vector2(0, h)
	var row := UI.hbox(0)
	strip.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var played: bool = int(e["hg"]) >= 0
	var w: int = int(e.get("w", -1))
	# sem vencedor do confronto (jogo de ida): destaca quem ganhou a partida
	if w < 0 and played and int(e["hg"]) != int(e["ag"]):
		w = int(e["h"]) if int(e["hg"]) > int(e["ag"]) else int(e["a"])
	var fs := 25 if h >= 56 else 20
	var agg := ""
	if int(e.get("leg", 1)) >= 2 and played:
		agg = "(%d - %d)" % [int(e["agg_h"]), int(e["agg_a"])]
	row.add_child(UI.col(agg, 170, fs - 2, Color("3c3f48"), false))
	for k in 2:
		var cid: int = int(e["h"]) if k == 0 else int(e["a"])
		var win: bool = w == cid or w < 0
		var nl := UI.label(Game.club_name(cid), fs, WIN_TXT if win else LOSE_TXT, win)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if k == 0 else HORIZONTAL_ALIGNMENT_LEFT
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.clip_text = true
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UI.expand(nl)
		nl.size_flags_vertical = Control.SIZE_FILL
		var badge := _badge(cid, h + 4)
		if k == 0:
			row.add_child(nl)
			row.add_child(UI.fixed(Control.new(), 34))
			row.add_child(badge)
			var sv := UI.vbox(-6)
			sv.alignment = BoxContainer.ALIGNMENT_CENTER
			sv.custom_minimum_size = Vector2(150, 0)
			var score := "%d - %d" % [int(e["hg"]), int(e["ag"])] if played else "x"
			sv.add_child(UI.center(UI.label(score, fs + 2, WIN_TXT, true)))
			var pens: Array = e.get("pens", [])
			if played and pens.size() == 2:
				sv.add_child(UI.center(UI.label("pên. %d - %d" % [int(pens[0]), int(pens[1])], 13, Color("3c3f48"), true)))
			row.add_child(sv)
		else:
			row.add_child(badge)
			row.add_child(UI.fixed(Control.new(), 34))
			row.add_child(nl)
	row.add_child(UI.fixed(Control.new(), 170))
	return strip


## Escudo dentro de um círculo branco.
static func _badge(cid: int, d: int) -> Control:
	var b := Badge.new()
	b.custom_minimum_size = Vector2(d, d)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cr := Crest.make(cid, d * 0.66)
	b.add_child(cr)
	cr.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cr.offset_left = -d * 0.33
	cr.offset_top = -d * 0.33
	cr.offset_right = d * 0.33
	cr.offset_bottom = d * 0.33
	return b


# ============================================================ cup (chaveamento)
## Chaveamento da copa com o mesmo tema. arg {"cup": índice, "next": bool}.
func cup(root: Control, arg) -> void:
	var a: Dictionary = arg if typeof(arg) == TYPE_DICTIONARY else {}
	var ci: int = int(a.get("cup", 0))
	var c: Dictionary = Game.S["cups"][ci]
	var is_next: bool = bool(a.get("next", false))
	var champ: int = int(c["champion"])
	if champ < 0 and int(c["next"]) < c["days"].size():
		Cups.ensure_draw(ci)
	var sub := "Campeão: %s" % Game.club_name(champ) if champ >= 0 else format_text(c)
	m.head(str(c["name"]), sub, not is_next)
	m.bare()
	var th := theme_for(str(c["name"]))
	var full := _stage(root, th)
	var played_any: bool = int(c["next"]) > 0
	var btn := ""
	var cb := Callable()
	if is_next:
		btn = "CONTINUAR"
		cb = func(): m.home()
	elif played_any:
		btn = "RESULTADOS"
		cb = func(): m.go("cup_results", {"cup": ci, "stage": -1, "next": false})
	var body := _frame(full, th, cup_logo(c), str(c["name"]), sub, btn, cb, Callable())
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 40)
	mc.add_theme_constant_override("margin_right", 40)
	mc.add_theme_constant_override("margin_bottom", 18)
	UI.vexpand(mc)
	body.add_child(mc)
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mc.add_child(sc)
	var cols := UI.hbox(16)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.add_child(cols)
	var cur_round := _round_of_stage(c, int(c["next"]))
	for r in c["rounds"].size():
		var col := UI.vbox(8)
		col.custom_minimum_size = Vector2(290, 0)
		var hp := PanelContainer.new()
		hp.add_theme_stylebox_override("panel", UI.sbox(th["head"], 8, 8))
		var hh := UI.hbox(8)
		hh.add_child(UI.expand(UI.label(Cups.round_name(c, r).to_upper(), 15, th["title"], true)))
		hh.add_child(UI.label(_round_dates(c, r), 13, th["sub"], true))
		hp.add_child(hh)
		col.add_child(hp)
		for t in c["rounds"][r]:
			col.add_child(_tie_card(c, r, t, th, r < cur_round))
		cols.add_child(col)
	if champ >= 0:
		var cp := UI.vbox(10)
		cp.custom_minimum_size = Vector2(240, 0)
		cp.alignment = BoxContainer.ALIGNMENT_CENTER
		cp.add_child(UI.center(UI.label("CAMPEÃO", 18, th["accent"], true)))
		var bh := UI.hbox()
		bh.alignment = BoxContainer.ALIGNMENT_CENTER
		bh.add_child(_badge(champ, 120))
		cp.add_child(bh)
		cp.add_child(UI.center(UI.label(Game.club_name(champ), 22, Color.WHITE, true)))
		cols.add_child(cp)
		maybe_celebrate_cup(ci)


## Formato da copa para o subtítulo ("Mata-mata em ida e volta • final em jogo único").
static func format_text(c: Dictionary) -> String:
	var cd: Dictionary = World.CUPS[int(c["def"])]
	if int(cd.get("legs", 1)) >= 2:
		var t := "Mata-mata em ida e volta"
		if bool(cd.get("final_single", false)):
			t += " • final em jogo único"
		return t + " • pênaltis se o agregado empatar"
	return "Mata-mata em jogo único • pênaltis no empate"


## Datas das etapas da fase r ("12/03 e 19/03").
static func _round_dates(c: Dictionary, r: int) -> String:
	var out: Array = []
	var sts: Array = _cups_call("stages", [c]) if _cups_has("stages") else []
	for i in c["days"].size():
		var rr: int = int(sts[i]["round"]) if i < sts.size() else i
		if rr == r:
			out.append(Game.fmt_date(int(c["days"][i])).substr(0, 5))
	return " e ".join(out)


## Fase (índice em rounds) de uma etapa.
static func _round_of_stage(c: Dictionary, stage: int) -> int:
	if _cups_has("stages"):
		var sts: Array = _cups_call("stages", [c])
		if stage >= sts.size():
			return c["rounds"].size()
		return int(sts[stage]["round"])
	return stage


## Cartão claro de um confronto no chaveamento (agregado, pênaltis, vencedor em negrito).
func _tie_card(c: Dictionary, r: int, t: Dictionary, th: Dictionary, done_round: bool) -> Control:
	var mine: bool = int(t["h"]) == int(Game.S["club"]) or int(t["a"]) == int(Game.S["club"])
	var sb := UI.sbox(Color("eceef3"), 10, 0)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	if mine:
		sb.border_color = th["accent"]
		sb.border_width_left = 6
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb)
	var tv := UI.vbox(2)
	p.add_child(tv)
	var legs: Array = t.get("legs", [])
	if legs.is_empty() and int(t["hg"]) >= 0:
		legs = [[int(t["hg"]), int(t["ag"])]]
	var w: int = int(t.get("w", -1))
	for k in 2:
		var cid: int = int(t["h"]) if k == 0 else int(t["a"])
		var h := UI.hbox(8)
		h.add_child(_badge(cid, 28))
		var won: bool = done_round and w == cid
		var lost: bool = done_round and w >= 0 and w != cid
		var nl := UI.label(Game.club_name(cid), 16, LOSE_TXT if lost else WIN_TXT, not lost)
		nl.clip_text = true
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		h.add_child(UI.expand(nl))
		for L in legs:
			h.add_child(UI.col(str(int(L[k])), 22, 15, Color("555863"), false))
		if legs.size() > 1:
			var tot: int = 0
			for L in legs:
				tot += int(L[k])
			h.add_child(UI.col(str(tot), 28, 16, WIN_TXT if won else LOSE_TXT, true))
		var pens: Array = t.get("pens", [])
		if pens.size() == 2 and done_round:
			h.add_child(UI.col("(%d)" % int(pens[k]), 34, 14, Color("555863"), true))
		tv.add_child(h)
	if r >= 0 and legs.is_empty():
		p.modulate = Color(1, 1, 1, 0.92)
	return p


# ============================================================ desenho
## Fundo animado do tema.
class Backdrop extends Control:
	var kind: String = "gramado"
	var c1: Color = Color.BLACK
	var c2: Color = Color.BLACK
	var accent: Color = Color.WHITE
	var t: float = 0.0
	var _seed: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 2070
		for i in 90:
			_seed.append(Vector4(rng.randf(), rng.randf(), rng.randf(), rng.randf()))

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# gradiente diagonal em 6 faixas horizontais
		var n := 24
		for i in n:
			var f := float(i) / float(n - 1)
			draw_rect(Rect2(0, h * i / n, w, h / n + 1.0), c1.lerp(c2, 0.5 + 0.5 * sin(f * PI * 0.9 - 0.2)))
		match kind:
			"listras":
				var band := 70.0
				var shift := fmod(t * 12.0, band * 2.0)
				var k := -int(h / band) - 2
				while k * band < w + h:
					var x := k * band * 2.0 + shift
					var a := 0.035 + 0.025 * (0.5 + 0.5 * sin(k * 1.7))
					draw_colored_polygon(PackedVector2Array([Vector2(x, h), Vector2(x + band, h), Vector2(x + band + h, 0), Vector2(x + h, 0)]), Color(1, 1, 1, a))
					k += 1
			"chuva":
				for s in _seed:
					var x: float = s.x * w
					var spd: float = 50.0 + s.z * 90.0
					var ln: float = 30.0 + s.w * 110.0
					var y: float = fmod(s.y * (h + ln) + t * spd, h + ln) - ln
					var a: float = 0.08 + 0.22 * s.w
					var col := Color(0.45, 0.6, 1.0, a)
					var seg := 6.0
					var yy := y
					while yy < y + ln:
						var fa: float = (yy - y) / ln
						draw_rect(Rect2(x, yy, 3.0, seg - 2.0), Color(col, a * fa))
						yy += seg
			"estrelas":
				for s in _seed:
					var p := Vector2(s.x * w, s.y * h)
					var tw: float = 0.5 + 0.5 * sin(t * (1.0 + s.z * 2.5) + s.w * TAU)
					var r: float = 0.8 + s.z * 1.8
					draw_circle(p, r, Color(1, 1, 1, 0.15 + 0.6 * tw))
					if s.w > 0.85:
						var L: float = r * (3.0 + 3.0 * tw)
						draw_line(p - Vector2(L, 0), p + Vector2(L, 0), Color(0.75, 0.85, 1.0, 0.4 * tw), 1.0)
						draw_line(p - Vector2(0, L), p + Vector2(0, L), Color(0.75, 0.85, 1.0, 0.4 * tw), 1.0)
			_:
				var band := w / 9.0
				for i in 12:
					if i % 2 == 0:
						var x := i * band - h * 0.35
						draw_colored_polygon(PackedVector2Array([Vector2(x, h), Vector2(x + band, h), Vector2(x + band + h * 0.35, 0), Vector2(x + h * 0.35, 0)]), Color(1, 1, 1, 0.022))
				var pulse := 0.5 + 0.5 * sin(t * 0.8)
				for k in 6:
					draw_circle(Vector2(w * 0.5, -h * 0.3), h * (0.55 + k * 0.12), Color(accent, 0.010 + 0.006 * pulse))


## Faixa do cabeçalho em dois tons (claro em cima, um pouco mais escuro embaixo).
class HeadBand extends Control:
	var c1: Color = Color.WHITE
	var c2: Color = Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), c1)
		draw_rect(Rect2(0, size.y * 0.5, size.x, size.y * 0.5), c2)
		draw_rect(Rect2(0, size.y - 2.0, size.x, 2.0), Color(0, 0, 0, 0.18))


## Logo do campeonato (textura do datapack ou emblema desenhado).
class LogoMark extends Control:
	var tex: Texture2D = null
	var accent: Color = Color.WHITE
	var ink: Color = Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		if tex != null:
			var ts := tex.get_size()
			var fit := (r * 2.0) / maxf(ts.x, ts.y)
			draw_set_transform(c, 0.0, Vector2(fit, fit))
			draw_texture(tex, -ts / 2.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
		# taça estilizada
		var cup := PackedVector2Array([c + Vector2(-r * 0.62, -r * 0.8), c + Vector2(r * 0.62, -r * 0.8), c + Vector2(r * 0.42, -r * 0.05),
			c + Vector2(r * 0.12, r * 0.22), c + Vector2(-r * 0.12, r * 0.22), c + Vector2(-r * 0.42, -r * 0.05)])
		draw_colored_polygon(cup, accent)
		draw_rect(Rect2(c.x - r * 0.1, c.y + r * 0.2, r * 0.2, r * 0.36), accent)
		draw_rect(Rect2(c.x - r * 0.45, c.y + r * 0.56, r * 0.9, r * 0.24), ink)
		draw_arc(c + Vector2(-r * 0.62, -r * 0.45), r * 0.28, PI * 0.5, PI * 1.5, 16, accent, 3.0)
		draw_arc(c + Vector2(r * 0.62, -r * 0.45), r * 0.28, -PI * 0.5, PI * 0.5, 16, accent, 3.0)
		draw_line(c + Vector2(-r * 0.3, -r * 0.62), c + Vector2(-r * 0.18, -r * 0.18), Color(1, 1, 1, 0.45), 3.0)


## Faixa cinza do resultado.
class Strip extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), CupScreens.STRIP)
		draw_rect(Rect2(0, 0, size.x, 4.0), CupScreens.STRIP_EDGE)
		draw_rect(Rect2(0, size.y - 4.0, size.x, 4.0), CupScreens.STRIP_EDGE)
		draw_rect(Rect2(0, 4.0, size.x, size.y * 0.35), Color(1, 1, 1, 0.08))


## Círculo branco atrás do escudo.
class Badge extends Control:
	func _draw() -> void:
		var r := minf(size.x, size.y) / 2.0
		draw_circle(size / 2.0 + Vector2(0, 1.5), r, Color(0, 0, 0, 0.18))
		draw_circle(size / 2.0, r, Color.WHITE)


## Seta do botão CONTINUAR.
class Arrow extends Control:
	var color: Color = Color.WHITE

	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(2, 0), Vector2(size.x, size.y / 2.0), Vector2(2, size.y)]), color)


## Cantinho dourado no canto superior direito.
class Corner extends Control:
	var color: Color = Color.WHITE

	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y)]), color)


## Ícone de notícia (linhas) do ticker.
class NewsIcon extends Control:
	func _draw() -> void:
		var x0 := size.x * 0.2
		var x1 := size.x * 0.8
		for i in 4:
			var y := size.y * (0.3 + 0.13 * i)
			draw_line(Vector2(x0 if i % 2 == 0 else x0 + 4.0, y), Vector2(x1, y), Color.WHITE, 1.6)
