extends Control
# Tela principal: cabeçalho + área onde cada tela é montada.
# Para trocar de tela use  go("nome", argumento)  e  back().

const ScreensStart := preload("res://src/screens_start.gd")
const ScreensHub := preload("res://src/screens_hub.gd")
const ScreensTeam := preload("res://src/screens_team.gd")
const MatchView := preload("res://src/match_view.gd")
const ScreensPro := preload("res://src/screens_pro.gd")

var body: MarginContainer
var overlay: Control
var title_l: Label
var sub_l: Label
var date_l: Label
var central_b: Button
var money_l: Label
var money_p: Control
var back_b: Button
var crest_box: Control
var mid_box: Control

var stack: Array = []
var cur: Array = ["careers", null]
var hub_tab: int = 0
var screens: Dictionary = {}
var _modal: Control = null
var _keep: Array = []


func _ready() -> void:
	_build_chrome()
	var a = ScreensStart.new(self)
	var b = ScreensHub.new(self)
	var c = ScreensTeam.new(self)
	var d = ScreensPro.new(self)
	var e = CupScreens.new(self)
	_keep = [a, b, c, d, e]
	call_deferred("_first_run_import")
	screens = {
		"careers": a.careers, "coach": a.coach_screen, "clubs": a.clubs, "datapack": a.datapack, "dp_browse": a.dp_browse,
		"hub": b.hub, "table": b.table, "calendar": b.calendar, "results": b.results, "postmatch": b.postmatch,
		"finance": b.finance, "cup": e.cup, "cup_results": e.cup_results, "central": b.central, "transfers": b.transfers, "season_end": b.season_end,
		"lineup": c.lineup, "squad": c.squad, "player": c.player, "youth": c.youth,
		"market": c.market, "contract": c.contract, "offers": c.offers,
		"match": _match_screen,
		"pro_create": d.create, "pro_trial": d.trial, "pro_post": d.post, "pro_offers": d.offers, "pro_hub": d.hub,
		"pro_season": d.season, "pro_feed": d.feed,
	}
	_render()


func _build_chrome() -> void:
	var bg := TextureRect.new()
	var gr := Gradient.new()
	gr.set_color(0, UI.BG2)
	gr.set_color(1, UI.BG)
	var gt := GradientTexture2D.new()
	gt.gradient = gr
	gt.fill_from = Vector2(0.2, 0.0)
	gt.fill_to = Vector2(0.8, 1.0)
	gt.width = 64
	gt.height = 64
	bg.texture = gt
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# faixas do gramado bem suaves e um holofote no alto
	var deco := Control.new()
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func():
		var w: float = deco.size.x
		var h: float = deco.size.y
		var band: float = w / 9.0
		for i in 12:
			if i % 2 == 0:
				var x: float = i * band - h * 0.35
				deco.draw_colored_polygon(PackedVector2Array([Vector2(x, h), Vector2(x + band, h), Vector2(x + band + h * 0.35, 0), Vector2(x + h * 0.35, 0)]), Color(1, 1, 1, 0.018))
		for k in 6:
			deco.draw_circle(Vector2(w * 0.5, -h * 0.25), h * (0.55 + k * 0.12), Color(0.9, 0.85, 0.55, 0.012)))
	add_child(deco)
	deco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root := UI.vbox(0)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var head := PanelContainer.new()
	var hs := UI.sbox(UI.HEADER2, 0, 0)
	hs.content_margin_left = 18
	hs.content_margin_right = 18
	hs.content_margin_top = 8
	hs.content_margin_bottom = 8
	hs.border_color = UI.HEADER
	hs.border_width_top = 5
	head.add_theme_stylebox_override("panel", hs)
	root.add_child(head)
	var hb := UI.hbox(14)
	head.add_child(hb)
	crest_box = Control.new()
	crest_box.custom_minimum_size = Vector2(52, 52)
	hb.add_child(crest_box)
	var tv := UI.vbox(0)
	UI.expand(tv)
	title_l = UI.label("", 24, UI.TXT, true)
	sub_l = UI.label("", 14, UI.MUTED)
	sub_l.clip_text = true
	tv.add_child(title_l)
	tv.add_child(sub_l)
	hb.add_child(tv)
	var mv := UI.vbox(2)
	mid_box = mv
	date_l = UI.center(UI.label("", 17, UI.TXT, true))
	central_b = UI.button("Central", "dark", func(): go("central"), 15, 30)
	central_b.custom_minimum_size = Vector2(170, 30)
	mv.add_child(date_l)
	mv.add_child(central_b)
	hb.add_child(mv)
	hb.add_child(UI.expand(Control.new(), 0.6))
	money_p = UI.panel(UI.BG2, 8, 8)
	money_p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	money_l = UI.center(UI.label("", 19, UI.TXT, true))
	money_l.custom_minimum_size = Vector2(150, 0)
	money_p.add_child(money_l)
	hb.add_child(money_p)
	back_b = UI.button("Voltar", "dark", back, 17, 44)
	back_b.custom_minimum_size = Vector2(110, 44)
	back_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(back_b)

	body = MarginContainer.new()
	for k in ["margin_left", "margin_right"]:
		body.add_theme_constant_override(k, 22)
	body.add_theme_constant_override("margin_top", 14)
	body.add_theme_constant_override("margin_bottom", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Na primeira abertura, importa o datapack que vem dentro do jogo (res://datapack.zip).
## Depois disso fica salvo no aparelho e não precisa importar de novo.
func _first_run_import() -> void:
	if (DataPack.loaded() and not DataPack.outdated()) or not FileAccess.file_exists("res://datapack.zip"):
		return
	var cover := ColorRect.new()
	cover.color = Color(0.02, 0.06, 0.045, 0.97)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(cover)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := UI.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	cover.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_child(UI.center(UI.label("CRAQUE MANAGER", 34, UI.GOLD, true)))
	v.add_child(UI.center(UI.label("Preparando clubes, escudos e estádios…", 20, UI.TXT, true)))
	v.add_child(UI.center(UI.label("Isso só acontece na primeira vez e leva poucos segundos.", 15, UI.MUTED)))
	for i in 3:
		await get_tree().process_frame
	var res := DataPack.import_zip("res://datapack.zip")
	cover.queue_free()
	_render()
	if res != "":
		toast(res)


func _notification(what: int) -> void:
	# botão "voltar" do Android
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _modal != null and is_instance_valid(_modal):
		close_modal()          # janela aberta: fecha
	elif body.get_child_count() > 0 and body.get_child(0).has_method("_on_pause"):
		body.get_child(0).call("_on_pause")   # na partida: pausa
	elif back_b != null and back_b.visible:
		back()


# ------------------------------------------------------------ navegação
func go(screen: String, arg = null) -> void:
	stack.append(cur)
	cur = [screen, arg]
	_render()


func replace(screen: String, arg = null) -> void:
	cur = [screen, arg]
	_render()


func back() -> void:
	if stack.is_empty():
		return
	cur = stack.pop_back()
	_render()


func home() -> void:
	stack.clear()
	cur = ["hub", null]
	if Pro.is_pro():
		cur = [{"peneira": "pro_trial", "propostas": "pro_offers", "livre": "pro_offers"}.get(str(Pro.P()["stage"]), "pro_hub"), null]
	_render()


func reset(screen: String) -> void:
	stack.clear()
	cur = [screen, null]
	_render()


func refresh() -> void:
	_render()


func _render() -> void:
	close_modal()
	UI.clear(body)
	head(cur[0], "", true)
	var f: Callable = screens[cur[0]]
	f.call(body, cur[1])


func _match_screen(root: Control, _arg) -> void:
	var mv = MatchView.new()
	mv.m = self
	root.add_child(mv)


# Cabeçalho de cada tela
func head(title: String, sub: String = "", show_back: bool = true) -> void:
	title_l.text = title
	sub_l.text = sub
	sub_l.visible = sub != ""
	back_b.visible = show_back and not stack.is_empty()
	var in_career: bool = not Game.S.is_empty()
	UI.clear(crest_box)
	crest_box.visible = in_career
	mid_box.visible = in_career
	money_p.visible = in_career
	if in_career:
		var cr := Crest.make(Game.S["club"], 52)
		crest_box.add_child(cr)
		date_l.text = "%s • Temporada %d" % [Game.month_year(Game.S["day"]), Game.S["season"]]
		central_b.text = "Central • %d" % Game.S["unread"]
		UI.style_button(central_b, "gold" if Game.S["unread"] > 0 else "dark")
		var cash: float = float(Pro.P()["money"]) if Pro.is_pro() else float(Game.S["money"])
		money_l.text = Game.money(cash)
		money_l.add_theme_color_override("font_color", UI.TXT if cash >= 0.0 else Color("ff8b8b"))


# ------------------------------------------------------------ avisos e janelas
func toast(text: String) -> void:
	var p := UI.panel(Color("f4f6fa"), 14, 12)
	var l := UI.label(text, 18, UI.DARKTXT, true)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	p.position.y -= 90
	var tw := create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


func modal(content: Control) -> void:
	close_modal()
	_modal = ColorRect.new()
	_modal.color = Color(0.01, 0.05, 0.035, 0.82)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(_modal)
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mc := MarginContainer.new()
	for k in ["margin_left", "margin_right"]:
		mc.add_theme_constant_override(k, 120)
	for k in ["margin_top", "margin_bottom"]:
		mc.add_theme_constant_override(k, 50)
	_modal.add_child(mc)
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mc.add_child(content)


func close_modal() -> void:
	if _modal != null and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null
