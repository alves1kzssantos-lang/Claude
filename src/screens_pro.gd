extends RefCounted
# Telas do modo carreira de jogador (regras em src/pro_career.gd).

const TABS := ["01  JOGOS", "02  CARREIRA", "03  REDE SOCIAL", "04  EMPRESÁRIO", "05  VIDA"]

var m
var prof: Dictionary = {}
var slot: int = 0
var create_tab: int = 0
var tab: int = 0


func _init(main) -> void:
	m = main


## Boneco grande do seu jogador (mesmo desenho do campo).
class ProAvatar extends LanceView:
	var look: Dictionary = {}
	var kit_c: Array = [Color("2f6fd6"), Color("f2f2f2"), false]
	var ent: Dictionary = {}

	func _ready() -> void:
		set_process(false)

	func _w2s(w: Vector2) -> Vector2:
		return Vector2(size.x / 2.0 + w.x * s, size.y * 0.9)

	func _draw() -> void:
		s = size.y / 3.3
		draw_circle(Vector2(size.x / 2.0, size.y * 0.55), size.y * 0.42, Color(1, 1, 1, 0.05))
		var p := {"id": 7, "ovr": 70, "pos": "MEI"}
		for k in look.keys():
			p[k] = look[k]
		var e := _ent(p, Vector2.ZERO, int(look.get("num", 10)))
		e["face"] = 1.0
		e["ph"] = 0.0
		_draw_player(e, kit_c, false)


func _avatar(look: Dictionary, h: float, kit: Array = []) -> Control:
	var av := ProAvatar.new()
	av.look = look
	if not kit.is_empty():
		av.kit_c = kit
	av.custom_minimum_size = Vector2(h * 0.8, h)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return av


func _club_kit(cid: int) -> Array:
	var c: Dictionary = Game.club(cid)
	return [Color(str(c["c1"])), Color(str(c["c2"])), LanceView.striped(c)]


func _look_of(p: Dictionary) -> Dictionary:
	var out := {}
	for k in ["look_skin", "look_hstyle", "look_hcolor", "look_beard", "look_boots", "num"]:
		if p.has(k):
			out[k] = p[k]
	return out


func _card(title: String) -> Array:
	var p := UI.panel(UI.PANEL, 14)
	var v := UI.vbox(8)
	p.add_child(v)
	if title != "":
		v.add_child(UI.card_title(title))
	return [p, v]


func _stat_row(v: Control, name: String, val: String, col: Color = UI.TXT) -> void:
	var h := UI.hbox(6)
	h.add_child(UI.expand(UI.label(name, 15, UI.MUTED)))
	h.add_child(UI.label(val, 15, col, true))
	v.add_child(h)


func _rating_color(r: float) -> Color:
	if r < 0.0:
		return UI.MUTED
	if r >= 7.5:
		return UI.GREEN_TXT
	if r >= 6.5:
		return UI.GOLD
	if r >= 5.8:
		return Color("f0a05e")
	return UI.RED_TXT


# ------------------------------------------------------------ criação
func create(root: Control, arg) -> void:
	if arg is Dictionary and arg.has("slot"):
		slot = int(arg["slot"])
		if prof.is_empty() or arg.get("fresh", true):
			prof = Pro.new_profile()
			create_tab = 0
			arg["fresh"] = false
	if prof.is_empty():
		prof = Pro.new_profile()
	m.head("Crie seu jogador", "Ele começa numa peneira com olheiros. A nota decide as propostas.")
	var hb := UI.hbox(16)
	root.add_child(hb)
	var left := UI.panel(UI.PANEL, 16)
	left.custom_minimum_size = Vector2(300, 0)
	var lv := UI.vbox(6)
	left.add_child(lv)
	lv.add_child(UI.center(UI.label("SEU JOGADOR", 13, UI.MUTED, true)))
	var look := {"look_skin": prof["skin"], "look_hstyle": prof["hstyle"], "look_hcolor": prof["hcolor"], "look_beard": prof["beard"],
		"look_boots": Pro.BOOTS[int(prof["boots"])], "num": prof["num"]}
	var av := _avatar(look, 280)
	UI.vexpand(av)
	lv.add_child(av)
	lv.add_child(UI.center(UI.label("%s  #%d" % [prof["name"], prof["num"]], 20, UI.TXT, true)))
	lv.add_child(UI.center(UI.label("%s • %d anos • %s" % [Pro.POS_NAMES[prof["pos"]], prof["age"], prof["nat"]], 14, UI.MUTED)))
	hb.add_child(left)

	var right := UI.panel(UI.PANEL, 18)
	UI.expand(right)
	var rv := UI.vbox(14)
	right.add_child(rv)
	var tabs := UI.hbox(8)
	tabs.add_child(UI.fixed(UI.button("Identidade", "gold" if create_tab == 0 else "dark", func():
		create_tab = 0
		m.refresh()), 170))
	tabs.add_child(UI.fixed(UI.button("Visual", "gold" if create_tab == 1 else "dark", func():
		create_tab = 1
		m.refresh()), 170))
	rv.add_child(tabs)
	if create_tab == 0:
		var le := LineEdit.new()
		le.text = prof["name"]
		le.max_length = 20
		le.custom_minimum_size = Vector2(300, 46)
		le.add_theme_font_size_override("font_size", 19)
		le.add_theme_stylebox_override("normal", UI.sbox(UI.PANEL2, 8, 10))
		le.add_theme_stylebox_override("focus", UI.sbox(UI.PANEL2, 8, 10, UI.GOLD, 2))
		le.text_changed.connect(func(t: String): prof["name"] = t.strip_edges() if t.strip_edges() != "" else "Novo Craque")
		var r1 := UI.hbox(24)
		r1.add_child(UI.field("Nome", le))
		r1.add_child(UI.field("Idade", UI.stepper("%d anos" % prof["age"], _step.bind("age", -1, 16, 19), _step.bind("age", 1, 16, 19))))
		rv.add_child(r1)
		var r2 := UI.hbox(24)
		r2.add_child(UI.field("Posição", UI.fixed(UI.button(Pro.POS_NAMES[prof["pos"]] + "  ›", "dark", _cycle_list.bind("pos", Pro.POSITIONS)), 300)))
		r2.add_child(UI.field("Número", UI.stepper("#%d" % prof["num"], _step.bind("num", -1, 1, 99), _step.bind("num", 1, 1, 99))))
		rv.add_child(r2)
		var r3 := UI.hbox(24)
		r3.add_child(UI.field("Nacionalidade", UI.fixed(UI.button(str(prof["nat"]) + "  ›", "dark", _cycle_list.bind("nat", Pro.NATS)), 300)))
		r3.add_child(UI.field("Pé bom", UI.fixed(UI.button(str(prof["foot"]) + "  ›", "dark", _cycle_list.bind("foot", ["Direito", "Esquerdo", "Ambidestro"])), 250)))
		rv.add_child(r3)
		var li := Pro.home_league(str(prof["nat"]))
		rv.add_child(UI.wrap(UI.label("A peneira acontece no país do jogador (%s). Olheiros de clubes pequenos, grandes e até de fora vão assistir." % World.LEAGUES[li]["country"], 14, UI.MUTED)))
	else:
		var g := UI.grid(2, 18)
		g.add_child(UI.field("Tom de pele", _cyc_btn("Tom %d" % (int(prof["skin"]) + 1), "skin", LanceView.SKINS.size())))
		g.add_child(UI.field("Cabelo", _cyc_btn(Pro.HAIR_STYLES[int(prof["hstyle"])], "hstyle", Pro.HAIR_STYLES.size())))
		g.add_child(UI.field("Cor do cabelo", _cyc_btn("Cor %d" % (int(prof["hcolor"]) + 1), "hcolor", LanceView.HAIRS.size())))
		g.add_child(UI.field("Barba", UI.fixed(UI.button("Com barba" if prof["beard"] else "Sem barba", "dark", func():
			prof["beard"] = not prof["beard"]
			m.refresh()), 260)))
		g.add_child(UI.field("Chuteira", _cyc_btn(Pro.BOOT_NAMES[int(prof["boots"])], "boots", Pro.BOOTS.size())))
		rv.add_child(g)
	rv.add_child(UI.spacer())
	var bh := UI.hbox()
	bh.add_child(UI.spacer())
	bh.add_child(UI.fixed(UI.button("Ir para a peneira  ›", "gold", _begin, 19, 52), 340))
	rv.add_child(bh)
	hb.add_child(right)


func _cyc_btn(text: String, key: String, n: int) -> Control:
	return UI.fixed(UI.button(text + "  ›", "dark", func():
		prof[key] = (int(prof[key]) + 1) % n
		m.refresh()), 260)


func _cycle_list(key: String, arr: Array) -> void:
	prof[key] = arr[(arr.find(prof[key]) + 1) % arr.size()]
	if key == "pos":
		prof["num"] = {"AC": 9, "PD": 7, "PE": 11, "MEI": 10, "VOL": 5, "LD": 2, "LE": 6, "ZAG": 4}.get(prof["pos"], 10)
	m.refresh()


func _step(key: String, d: int, lo: int, hi: int) -> void:
	prof[key] = clampi(int(prof[key]) + d, lo, hi)
	m.refresh()


func _begin() -> void:
	Pro.start(slot, prof)
	prof = {}
	m.reset("pro_trial")


# ------------------------------------------------------------ peneira
func trial(root: Control, _arg) -> void:
	var p := Pro.me()
	m.head("Peneira", "Jogo festivo com olheiros • %s" % Game.fmt_date(Game.S["day"]), false)
	var hb := UI.hbox(14)
	root.add_child(hb)
	var lc := _card("VOCÊ")
	lc[0].custom_minimum_size = Vector2(300, 0)
	var av := _avatar(_look_of(p), 260, _club_kit(Game.S["club"]))
	UI.vexpand(av)
	lc[1].add_child(av)
	lc[1].add_child(UI.center(UI.label(p["name"], 20, UI.TXT, true)))
	lc[1].add_child(UI.center(UI.label("%s • força %d • %d anos" % [Pro.POS_NAMES[p["pos"]], p["ovr"], p["age"]], 14, UI.MUTED)))
	hb.add_child(lc[0])
	var rc := _card("OLHEIROS NA ARQUIBANCADA")
	UI.expand(rc[0])
	rc[1].add_child(UI.wrap(UI.label("Cada olheiro tem uma exigência: os clubes maiores só fazem proposta se você jogar muito. Nos lances, a seta dourada é você — a bola só obedece quando está no seu pé.", 15, UI.MUTED)))
	var need0 := Pro.cfg("peneira", "nota_minima_base", 5.6)
	var per := Pro.cfg("peneira", "nota_por_ponto_de_forca", 0.075)
	var ref := Pro.cfg("peneira", "forca_referencia", 60)
	for sc in Pro.P()["scouts"]:
		var h := UI.hbox(10)
		h.add_child(Crest.make_raw(sc["short"], sc["c1"], sc["c2"], 36, sc["li"], sc["ci"]))
		var nv := UI.vbox(0)
		nv.add_child(UI.label(sc["name"], 17, UI.TXT, true))
		nv.add_child(UI.label("%s • %s" % [sc["league"], sc["country"]], 13, UI.MUTED))
		h.add_child(UI.expand(nv))
		h.add_child(UI.label("nota %.1f+" % (need0 + (float(sc["str"]) - ref) * per), 15, UI.GOLD, true))
		rc[1].add_child(h)
	rc[1].add_child(UI.spacer())
	var bh := UI.hbox(10)
	bh.add_child(UI.expand(UI.button("ENTRAR EM CAMPO", "gold", func(): m.go("match"), 19, 52)))
	bh.add_child(UI.fixed(UI.button("Simular", "dark", func():
		Game.play_next(null)
		m.reset("pro_post")), 200))
	rc[1].add_child(bh)
	hb.add_child(rc[0])


# ------------------------------------------------------------ pós-jogo
func post(root: Control, _arg) -> void:
	var pr: Dictionary = Pro.P()
	var L: Dictionary = pr["last"]
	if L.is_empty():
		m.home()
		return
	m.head(str(L["comp"]), "Fim de jogo • %s • %s" % [L["label"], Game.fmt_date(int(L["day"]))], false)
	var v := UI.vbox(12)
	root.add_child(v)
	var top := UI.hbox(14)
	top.add_child(Crest.make(int(L["h"]), 56))
	top.add_child(UI.expand(UI.label(Game.club_name(int(L["h"])), 20, UI.TXT, true)))
	var sc := "%d × %d" % [L["hg"], L["ag"]]
	if not L.get("pens", []).is_empty():
		sc += "  (pên. %d × %d)" % [L["pens"][0], L["pens"][1]]
	top.add_child(UI.label(sc, 36, UI.TXT, true))
	var an := UI.label(Game.club_name(int(L["a"])), 20, UI.TXT, true)
	an.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(UI.expand(an))
	top.add_child(Crest.make(int(L["a"]), 56))
	v.add_child(top)
	var mid := UI.hbox(14)
	UI.vexpand(mid)
	v.add_child(mid)
	var rc := _card("SUA NOTA")
	rc[0].custom_minimum_size = Vector2(300, 0)
	var r: float = float(L["rating"])
	rc[1].add_child(UI.center(UI.label("%.1f" % r if r >= 0.0 else "—", 72, _rating_color(r), true)))
	rc[1].add_child(UI.center(UI.label("Não saiu do banco" if r < 0.0 else ("Craque do jogo!" if r >= 8.0 else ("Boa atuação" if r >= 7.0 else ("Regular" if r >= 6.0 else "Atuação ruim"))), 17, UI.MUTED, true)))
	_stat_row(rc[1], "Minutos", str(L["min"]))
	_stat_row(rc[1], "Gols", str(L["gol"]), UI.GOLD if int(L["gol"]) > 0 else UI.TXT)
	_stat_row(rc[1], "Assistências", str(L["ass"]))
	_stat_row(rc[1], "Lances jogados", str(L["lances"]))
	_stat_row(rc[1], "Chutes no gol / fora", "%d / %d" % [L["on"], L["off"]])
	_stat_row(rc[1], "Perdas de bola", str(L["lost"]))
	if int(L["card"]) > 0 or L["red"]:
		_stat_row(rc[1], "Cartão", "VERMELHO" if L["red"] else "amarelo", UI.RED_TXT if L["red"] else UI.GOLD)
	mid.add_child(rc[0])
	var fc := _card("REDE SOCIAL • O QUE ESTÃO FALANDO")
	UI.expand(fc[0])
	var shown := 0
	for post_d in pr["feed"]:
		if shown >= 5:
			break
		fc[1].add_child(_post_row(post_d, false))
		shown += 1
	fc[1].add_child(UI.spacer())
	mid.add_child(fc[0])
	var bh := UI.hbox(10)
	bh.add_child(UI.fixed(UI.button("Abrir rede social", "dark", func():
		tab = 2
		m.home()), 300))
	bh.add_child(UI.spacer())
	var nxt := "Ver propostas  ›" if pr["stage"] in ["propostas", "livre"] else "Continuar  ›"
	bh.add_child(UI.fixed(UI.button(nxt, "gold", func():
		tab = 0
		m.home(), 19, 50), 340))
	v.add_child(bh)


# ------------------------------------------------------------ propostas
func offers(root: Control, _arg) -> void:
	var pr: Dictionary = Pro.P()
	var first: bool = pr["stage"] in ["propostas", "livre"]
	m.head("Propostas" if not first else ("Escolha seu clube" if pr["stage"] == "propostas" else "Livre no mercado"),
		"Aceite, negocie (o empresário ajuda) ou recuse", not first)
	var v := UI.vbox(10)
	root.add_child(v)
	if pr["offers"].is_empty():
		var c := _card("")
		c[1].add_child(UI.label("Nenhuma proposta na mesa.", 20, UI.TXT, true))
		c[1].add_child(UI.wrap(UI.label("Jogue bem, ganhe fama e contrate um empresário melhor: as propostas chegam no meio e no fim da temporada.", 15, UI.MUTED)))
		v.add_child(c[0])
		return
	var sc := UI.scroll()
	UI.vexpand(sc)
	v.add_child(sc)
	var list := UI.vbox(10)
	UI.expand(list)
	sc.add_child(list)
	for i in pr["offers"].size():
		var o: Dictionary = pr["offers"][i]
		var p := UI.panel(UI.PANEL, 14)
		var h := UI.hbox(14)
		p.add_child(h)
		h.add_child(Crest.make_raw(o["short"], o["c1"], o["c2"], 64, o["li"], o["ci"]))
		var nv := UI.vbox(2)
		nv.add_child(UI.label(("RENOVAÇÃO • " if o.get("renewal", false) else "") + str(o["name"]), 20, UI.GOLD, true))
		nv.add_child(UI.label("%s • %s • força do time %d" % [o["league"], o["country"], o["str"]], 14, UI.MUTED))
		nv.add_child(UI.label("Papel: %s   •   Salário: %s/sem   •   %d anos" % [Pro.role_name(o["role"]), Pro._k(o["wage"]), o["years"]], 16, UI.TXT, true))
		nv.add_child(UI.label("Luvas: %s   •   Multa rescisória: %s" % [Game.money(o["luvas"]), Game.money(o["clause"])], 14, UI.MUTED))
		h.add_child(UI.expand(nv))
		var bv := UI.vbox(6)
		bv.add_child(UI.fixed(UI.button("Aceitar", "gold", _accept.bind(i)), 170))
		bv.add_child(UI.fixed(UI.button("Negociar", "blue", func():
			m.toast(Pro.negotiate(i))
			m.refresh()), 170))
		if not first or pr["offers"].size() > 1:
			bv.add_child(UI.fixed(UI.button("Recusar", "dark", func():
				Pro.reject(i)
				m.refresh()), 170))
		h.add_child(bv)
		list.add_child(p)


func _accept(i: int) -> void:
	var msg := Pro.accept(i)
	m.toast(msg)
	tab = 0
	m.home()


# ------------------------------------------------------------ hub
func hub(root: Control, _arg) -> void:
	var p := Pro.me()
	var pr: Dictionary = Pro.P()
	if pr["stage"] == "aposentado":
		_retired(root)
		return
	m.head("%s  #%d" % [p["name"], int(p.get("num", 10))], "%s • %s • força %d • %d anos • Temporada %d" % [Game.club_name(Game.S["club"]),
		Pro.POS_NAMES[p["pos"]], p["ovr"], p["age"], Game.S["season"]], false)
	var v := UI.vbox(12)
	root.add_child(v)
	var content := UI.hbox(14)
	UI.vexpand(content)
	v.add_child(content)
	match tab:
		0:
			_tab_games(content)
		1:
			_tab_career(content)
		2:
			_tab_social(content)
		3:
			_tab_agent(content)
		4:
			_tab_life(content)
	var tabs := UI.hbox(8)
	tabs.add_child(UI.fixed(UI.button("Menu", "dark", _menu, 16, 46), 110))
	for i in TABS.size():
		var b := UI.button(TABS[i], "gold" if i == tab else "dark", func():
			tab = i
			m.refresh(), 16, 46)
		UI.expand(b)
		tabs.add_child(b)
	v.add_child(tabs)


## Menu da carreira: continuar ou salvar e voltar às carreiras.
func _menu() -> void:
	var v := UI.vbox(12)
	v.custom_minimum_size = Vector2(420, 0)
	v.add_child(UI.center(UI.label("Menu", 24, UI.GOLD, true)))
	v.add_child(UI.button("Continuar", "gold", func(): m.close_modal(), 18, 56))
	v.add_child(UI.button("Salvar e voltar às carreiras", "dark", func():
		m.close_modal()
		Game.save()
		Game.S = {}
		Game.slot = -1
		m.reset("careers"), 18, 56))
	m.modal(v)


func _tab_games(content: Control) -> void:
	var pr: Dictionary = Pro.P()
	var lv := UI.vbox(12)
	UI.expand(lv)
	content.add_child(lv)
	var nc := _card("PRÓXIMA PARTIDA")
	UI.vexpand(nc[0])
	if Game.S["season_over"]:
		nc[1].add_child(UI.label("Temporada encerrada", 22, UI.GOLD, true))
		nc[1].add_child(UI.label("Veja os prêmios, os títulos e o seu futuro.", 15, UI.MUTED))
		nc[1].add_child(UI.spacer())
		nc[1].add_child(UI.button("Fim de temporada  ›", "gold", func(): m.go("pro_season"), 19, 52))
	else:
		var mt: Dictionary = Game.next_user_match()
		var home: bool = mt["h"] == Game.S["club"]
		var opp: int = mt["a"] if home else mt["h"]
		nc[1].add_child(UI.label(mt["comp"], 15, UI.GOLD, true))
		nc[1].add_child(UI.label("%s • %s" % [mt["label"], Game.fmt_date(mt["day"])], 13, UI.MUTED))
		var oh := UI.hbox(10)
		oh.add_child(Crest.make(opp, 52))
		var ov := UI.vbox(0)
		ov.add_child(UI.label("%s (%s)" % [Game.club_name(opp), "C" if home else "F"], 21, UI.TXT, true))
		ov.add_child(UI.label("Força %d" % Game.ratings(opp)["ger"], 14, UI.MUTED))
		oh.add_child(ov)
		nc[1].add_child(oh)
		var st := Pro.status_line()
		nc[1].add_child(UI.label("Você: %s" % st, 18, UI.GREEN_TXT if st == "TITULAR" else (UI.GOLD if st == "NO BANCO" else UI.RED_TXT), true))
		if st == "NO BANCO":
			nc[1].add_child(UI.wrap(UI.label("O técnico pode te colocar no segundo tempo. Confiança do técnico: %d%%" % int(pr["coach"]), 13, UI.MUTED)))
		nc[1].add_child(UI.spacer())
		var bh := UI.hbox(10)
		bh.add_child(UI.expand(UI.button("Jogar", "gold", func(): m.go("match"), 19, 50)))
		bh.add_child(UI.expand(UI.button("Simular", "dark", func():
			Game.play_next(null)
			m.go("pro_post"), 19, 50)))
		nc[1].add_child(bh)
	lv.add_child(nc[0])
	var tc := _card("TREINO DA SEMANA")
	var th := UI.hbox(8)
	for k in [["leve", "Leve"], ["normal", "Normal"], ["intenso", "Intenso"]]:
		th.add_child(UI.expand(UI.button(k[1], "gold" if pr["train"] == k[0] else "dark", func():
			Pro.set_training(k[0])
			m.refresh(), 16, 42)))
	tc[1].add_child(th)
	tc[1].add_child(UI.label("Evolução: %d / %d XP • intenso evolui mais e machuca mais" % [int(pr["xp"]), int(Pro.xp_needed())], 13, UI.MUTED))
	tc[1].add_child(UI.bar(float(pr["xp"]) / Pro.xp_needed(), UI.BLUE, 7))
	lv.add_child(tc[0])

	var rv := UI.vbox(12)
	rv.custom_minimum_size = Vector2(520, 0)
	content.add_child(rv)
	var fc := _card("FASE • ÚLTIMAS NOTAS")
	var fh := UI.hbox(8)
	var rs: Array = pr["ratings"]
	for i in range(maxi(rs.size() - 6, 0), rs.size()):
		var pb := UI.panel(Color(_rating_color(float(rs[i])), 0.25), 6, 6)
		pb.add_child(UI.center(UI.label("%.1f" % float(rs[i]), 18, _rating_color(float(rs[i])), true)))
		pb.custom_minimum_size = Vector2(64, 0)
		fh.add_child(pb)
	if rs.is_empty():
		fh.add_child(UI.label("Ainda sem jogos", 15, UI.MUTED))
	fc[1].add_child(fh)
	var ss: Dictionary = pr["season"]
	fc[1].add_child(UI.label("Temporada: %d jogos • %d gols • %d assist. • média %.2f" % [ss["g"], ss["gol"], ss["ass"], Pro.avg_rating()], 15, UI.TXT))
	rv.add_child(fc[0])
	var sc := _card("CAMPEONATO")
	UI.vexpand(sc[0])
	sc[1].add_child(UI.label("%s • %dº lugar" % [Game.LEAGUE, Game.position_of(Game.S["club"])], 17, UI.TXT, true))
	var g := UI.grid(2, 8)
	UI.expand(g)
	g.add_child(UI.expand(UI.button("Tabela", "dark", func(): m.go("table"), 16, 42)))
	g.add_child(UI.expand(UI.button("Calendário", "dark", func(): m.go("calendar"), 16, 42)))
	for ci in Game.S.get("cups", []).size():
		var cc: Dictionary = Game.S["cups"][ci]
		g.add_child(UI.expand(UI.button(cc["name"], "dark", func(): m.go("cup", {"cup": ci, "next": false}), 15, 42)))
	g.add_child(UI.expand(UI.button("Notícias (%d)" % Game.S["unread"], "gold" if Game.S["unread"] > 0 else "dark", func(): m.go("central"), 16, 42)))
	sc[1].add_child(g)
	rv.add_child(sc[0])


func _tab_career(content: Control) -> void:
	var p := Pro.me()
	var pr: Dictionary = Pro.P()
	var lc := _card("")
	lc[0].custom_minimum_size = Vector2(290, 0)
	var av := _avatar(_look_of(p), 230, _club_kit(Game.S["club"]))
	UI.vexpand(av)
	lc[1].add_child(av)
	lc[1].add_child(UI.center(UI.label("FORÇA %d" % p["ovr"], 26, UI.GOLD, true)))
	var stars := 1 + clampi(int((int(p["pot"]) - 60) / 7.0), 0, 4)
	if Pro.agent_level() >= 2:
		lc[1].add_child(UI.center(UI.label("Potencial: " + "★".repeat(stars) + "☆".repeat(5 - stars), 17, UI.GOLD)))
	else:
		lc[1].add_child(UI.center(UI.label("Potencial: ? (um bom empresário avalia)", 13, UI.MUTED)))
	content.add_child(lc[0])
	var mc := _card("ATRIBUTOS")
	mc[0].custom_minimum_size = Vector2(330, 0)
	var at := Game.attrs(p)
	for k in [["vel", "Velocidade"], ["pas", "Passe"], ["chu", "Chute"], ["des", "Desarme"]]:
		var h := UI.hbox(8)
		h.add_child(UI.fixed(UI.label(k[1], 15, UI.MUTED), 110))
		var b := UI.bar(float(at[k[0]]) / 99.0, UI.BLUE if int(at[k[0]]) < 75 else UI.GOLD, 10)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(UI.expand(b))
		h.add_child(UI.label(str(at[k[0]]), 16, UI.TXT, true))
		mc[1].add_child(h)
	mc[1].add_child(UI.card_title("CONFIANÇA"))
	for k in [["coach", "Técnico", UI.BLUE], ["fans", "Torcida", UI.GREEN], ["fame", "Fama", UI.GOLD]]:
		mc[1].add_child(UI.label("%s: %d" % [k[1], int(pr[k[0]])], 14, UI.MUTED))
		mc[1].add_child(UI.bar(float(pr[k[0]]) / 100.0, k[2], 8))
	mc[1].add_child(UI.label("Seleção: %d jogos, %d gols" % [pr["caps"], pr["ngoals"]], 15, UI.TXT, true))
	content.add_child(mc[0])
	var rc := _card("HISTÓRICO, TÍTULOS E PRÊMIOS")
	UI.expand(rc[0])
	var sc := UI.scroll()
	UI.vexpand(sc)
	var sv := UI.vbox(4)
	UI.expand(sv)
	sc.add_child(sv)
	rc[1].add_child(sc)
	if pr["history"].is_empty():
		sv.add_child(UI.label("Primeira temporada em andamento.", 15, UI.MUTED))
	for hst in pr["history"]:
		sv.add_child(UI.label("%d • %s — %d jogos, %d gols, %d assist., média %.2f" % [hst["year"], hst["club"], hst["g"], hst["gol"], hst["ass"], hst["avg"]], 14, UI.TXT))
	for t in pr["titles"]:
		sv.add_child(UI.label("Título: %s %d (%s)" % [t["name"], t["year"], t["club"]], 15, UI.GOLD, true))
	for a in pr["awards"]:
		sv.add_child(UI.label("Prêmio: %s %d" % [a["name"], a["year"]], 15, UI.GOLD))
	if Pro.can_retire():
		var rb := UI.button("Pendurar as chuteiras", "red", Callable(), 15, 40)
		rb.pressed.connect(func():
			if rb.text != "Confirmar aposentadoria":
				rb.text = "Confirmar aposentadoria"
				return
			Pro.retire()
			m.refresh())
		rc[1].add_child(rb)
	content.add_child(rc[0])


func _fmt_n(n: int) -> String:
	if n >= 1000000:
		return "%.1f mi" % (n / 1000000.0)
	if n >= 1000:
		return "%.1f mil" % (n / 1000.0)
	return str(n)


func _post_row(post_d: Dictionary, with_reply: bool) -> Control:
	var col: Color = {"xingamento": Color("ff8b8b"), "elogio": Color("8fe0a8"), "zoeira": Color("f0a05e"), "manchete": Color("8fc0ff"), "meu": UI.GOLD}.get(post_d["kind"], UI.TXT)
	var p := UI.panel(Color(1, 1, 1, 0.05), 10, 8)
	var v := UI.vbox(3)
	p.add_child(v)
	var h := UI.hbox(8)
	h.add_child(UI.label(str(post_d["user"]), 14, col, true))
	h.add_child(UI.spacer())
	h.add_child(UI.label("♥ %s" % _fmt_n(int(post_d["likes"])), 13, UI.MUTED))
	v.add_child(h)
	v.add_child(UI.wrap(UI.label(str(post_d["text"]), 16)))
	if str(post_d["reply"]) != "":
		v.add_child(UI.wrap(UI.label("↳ você: %s" % post_d["reply"], 14, UI.GOLD)))
	elif with_reply and Pro.can_reply(post_d):
		var rh := UI.hbox(6)
		for st in [["humilde", "Humilde", "green"], ["provocar", "Provocar", "blue"], ["xingar", "Xingar de volta", "red"], ["ignorar", "Ignorar", "dark"]]:
			rh.add_child(UI.expand(UI.button(st[1], st[2], func():
				m.toast(Pro.reply(int(post_d["id"]), st[0]))
				m.refresh(), 14, 36)))
		v.add_child(rh)
	return p


func _tab_social(content: Control) -> void:
	var pr: Dictionary = Pro.P()
	var p := Pro.me()
	var lc := _card("SEU PERFIL")
	lc[0].custom_minimum_size = Vector2(330, 0)
	lc[1].add_child(UI.label("@" + str(p["name"]).to_lower().replace("", ""), 20, UI.GOLD, true))
	lc[1].add_child(UI.label("%s seguidores" % _fmt_n(int(pr["followers"])), 18, UI.TXT, true))
	lc[1].add_child(UI.label("Fama %d • Torcida %d%%" % [int(pr["fame"]), int(pr["fans"])], 14, UI.MUTED))
	if int(pr["polemics"]) > 0:
		lc[1].add_child(UI.label("Polêmicas recentes: %d (com %d você é afastado)" % [pr["polemics"], int(Pro.cfg("redes", "polemicas_para_afastamento", 3))], 13, Color("ff8b8b")))
	lc[1].add_child(UI.card_title("POSTAR" + (" (já postou desde o último jogo)" if pr["posted"] else "")))
	for it in Pro.social().get("posts_proprios", []):
		lc[1].add_child(UI.button(it["rotulo"], "dark" if not pr["posted"] else "flat", func():
			m.toast(Pro.own_post(it["id"]))
			m.refresh(), 15, 38))
	lc[1].add_child(UI.wrap(UI.label("Responder xingando dá engajamento, mas pode render multa, perda de patrocínio e afastamento.", 12, UI.MUTED)))
	content.add_child(lc[0])
	var rc := _card("FEED")
	UI.expand(rc[0])
	var sc := UI.scroll()
	UI.vexpand(sc)
	var sv := UI.vbox(8)
	UI.expand(sv)
	sc.add_child(sv)
	rc[1].add_child(sc)
	if pr["feed"].is_empty():
		sv.add_child(UI.label("Ninguém falou de você ainda. Jogue!", 15, UI.MUTED))
	for post_d in pr["feed"]:
		sv.add_child(_post_row(post_d, true))
	content.add_child(rc[0])


func feed(root: Control, _arg) -> void:
	tab = 2
	m.home()


func _tab_agent(content: Control) -> void:
	var pr: Dictionary = Pro.P()
	var p := Pro.me()
	var lc := _card("CONTRATO ATUAL")
	lc[0].custom_minimum_size = Vector2(420, 0)
	lc[1].add_child(UI.label(Game.club_name(Game.S["club"]), 20, UI.GOLD, true))
	_stat_row(lc[1], "Salário", "%s/sem" % Pro._k(float(p["wage"])))
	_stat_row(lc[1], "Contrato", "%d temporada(s)" % int(p["contract"]))
	_stat_row(lc[1], "Multa rescisória", Game.money(float(pr.get("clause", 0.0))))
	_stat_row(lc[1], "Valor de mercado", Game.money(float(p["value"])))
	if not pr["pending_move"].is_empty():
		lc[1].add_child(UI.label("Acertado com %s para a próxima temporada" % pr["pending_move"]["name"], 15, UI.GREEN_TXT, true))
	lc[1].add_child(UI.spacer())
	lc[1].add_child(UI.button("Propostas na mesa (%d)" % pr["offers"].size(), "gold" if not pr["offers"].is_empty() else "dark", func(): m.go("pro_offers"), 17, 48))
	content.add_child(lc[0])
	var rc := _card("EMPRESÁRIO")
	UI.expand(rc[0])
	var ag := Pro.agent()
	if ag.is_empty():
		rc[1].add_child(UI.label("Você não tem empresário: poucas propostas e só de clubes perto.", 15, UI.MUTED))
	else:
		rc[1].add_child(UI.label("%s (nível %d) • comissão %d%%" % [ag["nome"], ag["nivel"], int(float(ag["comissao"]) * 100)], 17, UI.TXT, true))
		rc[1].add_child(UI.button("Demitir empresário", "red", func():
			Pro.fire_agent()
			m.refresh(), 14, 36))
	for a in Pro.life().get("empresarios", []):
		if a["id"] == pr["agent"]:
			continue
		var pp := UI.panel(Color(1, 1, 1, 0.05), 10, 8)
		var h := UI.hbox(8)
		pp.add_child(h)
		var nv := UI.vbox(0)
		nv.add_child(UI.label("%s • nível %d" % [a["nome"], a["nivel"]], 16, UI.TXT, true))
		nv.add_child(UI.wrap(UI.label("%s Comissão %d%% • salário +%d%% • exige fama %d" % [a["texto"], int(float(a["comissao"]) * 100), int(float(a["aumento_salario"]) * 100), int(a["fama_minima"])], 13, UI.MUTED)))
		h.add_child(UI.expand(nv))
		h.add_child(UI.fixed(UI.button("Contratar", "blue" if float(pr["fame"]) >= float(a["fama_minima"]) else "flat", func():
			m.toast(Pro.hire(a["id"]))
			m.refresh(), 15, 40), 150))
		rc[1].add_child(pp)
	content.add_child(rc[0])


func _tab_life(content: Control) -> void:
	var pr: Dictionary = Pro.P()
	var lc := _card("DINHEIRO")
	lc[0].custom_minimum_size = Vector2(380, 0)
	lc[1].add_child(UI.label(Game.money(float(pr["money"])), 30, UI.GOLD, true))
	var wi := Pro.weekly_income()
	_stat_row(lc[1], "Salário por semana", Game.money(wi["salario"]))
	_stat_row(lc[1], "Patrocínios por semana", Game.money(wi["patrocinio"]))
	_stat_row(lc[1], "Comissão do empresário", "− " + Game.money(wi["comissao"]))
	_stat_row(lc[1], "Líquido por semana", Game.money(wi["liquido"]), UI.GREEN_TXT)
	lc[1].add_child(UI.card_title("PATROCINADORES"))
	if pr["sponsors"].is_empty():
		lc[1].add_child(UI.wrap(UI.label("Nenhum ainda. Fama e empresário atraem marcas.", 14, UI.MUTED)))
	for s in pr["sponsors"]:
		_stat_row(lc[1], s["marca"], Game.money(float(s["semanal"])) + "/sem")
	content.add_child(lc[0])
	var rc := _card("COMPRAS")
	UI.expand(rc[0])
	var sc := UI.scroll()
	UI.vexpand(sc)
	var sv := UI.vbox(6)
	UI.expand(sv)
	sc.add_child(sv)
	rc[1].add_child(sc)
	for it in Pro.life().get("compras", []):
		var h := UI.hbox(8)
		var owned: bool = it["id"] in pr["owned"]
		h.add_child(UI.expand(UI.label(it["nome"], 16, UI.GOLD if owned else UI.TXT, owned)))
		h.add_child(UI.label(Game.money(float(it["preco"])), 15, UI.MUTED))
		if owned:
			h.add_child(UI.fixed(UI.label("✓ seu", 15, UI.GREEN_TXT, true), 120))
		else:
			h.add_child(UI.fixed(UI.button("Comprar", "blue" if float(pr["money"]) >= float(it["preco"]) else "flat", func():
				m.toast(Pro.buy(it["id"]))
				m.refresh(), 14, 36), 120))
		sv.add_child(h)
	content.add_child(rc[0])


# ------------------------------------------------------------ fim de temporada
func season(root: Control, _arg) -> void:
	var rep := Pro.close_season()
	var pr: Dictionary = Pro.P()
	m.head("Fim de temporada %d" % rep["year"], "%s • %dº lugar • campeão: %s" % [Game.LEAGUE, rep["pos"], rep["champion"]], false)
	var hb := UI.hbox(14)
	root.add_child(hb)
	var lc := _card("SUA TEMPORADA")
	UI.expand(lc[0])
	lc[1].add_child(UI.label("%d jogos • %d gols • %d assistências" % [rep["g"], rep["gol"], rep["ass"]], 20, UI.TXT, true))
	lc[1].add_child(UI.label("Média %.2f • %d vez(es) craque do jogo" % [rep["avg"], rep["mvp"]], 17, _rating_color(float(rep["avg"])), true))
	for t in rep["titles"]:
		lc[1].add_child(UI.label("CAMPEÃO: %s" % t, 19, UI.GOLD, true))
	if not rep.get("titles", []).is_empty() and not bool(rep.get("celebrated", false)):
		rep["celebrated"] = true
		var items: Array = []
		for t in rep["titles"]:
			var logo: Texture2D = null
			var skip := false
			if str(t) == Game.LEAGUE:
				logo = DataPack.comp_logo_by_id(DataPack.comp_id(int(Game.S.get("league", 0))))
			for c in Game.S.get("cups", []):
				if str(c["name"]) == str(t):
					skip = bool(c.get("celebrated", false))
					c["celebrated"] = true
					logo = CupScreens.cup_logo(c)
			if not skip:
				items.append({"comp": str(t), "logo": logo, "style": CupScreens.trophy_style(str(t))})
		CupScreens.celebrate_queue(m.overlay, Game.club_name(Game.S["club"]), items)
	for a in rep["awards"]:
		lc[1].add_child(UI.label("Prêmio: %s" % a, 18, UI.GOLD, true))
	lc[1].add_child(UI.label("Bola de Ouro: %s" % rep["bola"], 15, UI.MUTED))
	if rep["wc"] != "":
		lc[1].add_child(UI.label(rep["wc"], 17, UI.GOLD, true))
	if rep["contract"] != "":
		lc[1].add_child(UI.wrap(UI.label(rep["contract"], 16, UI.TXT)))
	hb.add_child(lc[0])
	var rc := _card("PRÓXIMO PASSO")
	rc[0].custom_minimum_size = Vector2(420, 0)
	rc[1].add_child(UI.label("%d proposta(s) na mesa" % pr["offers"].size(), 17, UI.TXT, true))
	rc[1].add_child(UI.button("Ver propostas", "blue", func(): m.go("pro_offers"), 17, 46))
	rc[1].add_child(UI.spacer())
	if pr["stage"] == "livre":
		rc[1].add_child(UI.wrap(UI.label("Sem contrato: escolha um clube nas propostas para continuar.", 15, Color("ff8b8b"))))
	else:
		rc[1].add_child(UI.button("Começar a próxima temporada  ›", "gold", func():
			Pro.next_season()
			tab = 0
			m.home(), 18, 52))
	hb.add_child(rc[0])


func _retired(root: Control) -> void:
	var p := Pro.me()
	var pr: Dictionary = Pro.P()
	m.head("Fim de carreira", "%s pendurou as chuteiras" % p["name"], false)
	var c := _card("UMA CARREIRA")
	root.add_child(c[0])
	var gol := 0
	var g := 0
	for h in pr["history"]:
		gol += int(h["gol"])
		g += int(h["g"])
	c[1].add_child(UI.label("%d jogos • %d gols • %d títulos • %d prêmios • seleção: %d jogos" % [g, gol, pr["titles"].size(), pr["awards"].size(), pr["caps"]], 22, UI.GOLD, true))
	for t in pr["titles"]:
		c[1].add_child(UI.label("Título: %s %d (%s)" % [t["name"], t["year"], t["club"]], 16, UI.TXT))
	c[1].add_child(UI.button("Voltar às carreiras", "dark", func():
		Game.S = {}
		m.reset("careers"), 17, 46))
