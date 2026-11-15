extends RefCounted
# Central do clube (hub), tabela, calendário, resultados, finanças,
# notícias, mercado da bola e fim de temporada.

var m
var cal_y: int = 0
var cal_m: int = 0

const TABS := ["01  JOGOS", "02  EQUIPE", "03  CLUBE", "04  COMPETIÇÕES", "05  MANAGER"]
const WEEK := ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SÁB"]


func _init(main) -> void:
	m = main


func _nav(title: String, desc: String, cb: Callable) -> Button:
	var v := UI.vbox(2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.label(title, 21, UI.TXT, true))
	v.add_child(UI.label(desc, 14, UI.MUTED))
	var b := UI.row_button(v, cb, 96, "dark", 18)
	UI.expand(b)
	return b


func _card(title: String, big: String, small: String, cb: Callable, big_color: Color = UI.TXT) -> Button:
	var v := UI.vbox(2)
	var th := UI.hbox()
	th.add_child(UI.expand(UI.card_title(title)))
	th.add_child(UI.label("›", 18, UI.MUTED, true))
	v.add_child(th)
	v.add_child(UI.label(big, 21, big_color, true))
	if small != "":
		v.add_child(UI.label(small, 14, UI.MUTED))
	var b := UI.row_button(v, cb, 92, "dark", 14)
	UI.expand(b)
	return b


# ------------------------------------------------------------ hub
func hub(root: Control, _arg) -> void:
	var me: Dictionary = Game.my_club()
	m.head(me["name"], "CARREIRA • %d • Rodada %d de %d • %s" % [Game.S["year"], mini(Game.S["round"] + 1, Game.S["fixtures"].size()), Game.S["fixtures"].size(), Game.fmt_date(Game.S["day"])], false)
	var v := UI.vbox(12)
	root.add_child(v)
	var content := UI.hbox(14)
	UI.vexpand(content)
	v.add_child(content)
	match m.hub_tab:
		0:
			_tab_games(content)
		1:
			var g := UI.grid(2, 14)
			UI.expand(g)
			g.add_child(_nav("Escalação", "Monte o time titular e a formação", func(): m.go("lineup")))
			g.add_child(_nav("Elenco", "%d jogadores • veja o perfil de cada um" % Game.squad(Game.S["club"]).size(), func(): m.go("squad")))
			g.add_child(_nav("Base do clube", "%d jovens esperando uma chance" % Game.squad(Game.YOUTH).size(), func(): m.go("youth")))
			content.add_child(g)
		2:
			var g2 := UI.grid(2, 14)
			UI.expand(g2)
			g2.add_child(_nav("Contratar jogadores", "Jogadores livres e destaques dos outros clubes", func(): m.go("market")))
			g2.add_child(_nav("Propostas e vendas", "%d proposta(s) na mesa" % Game.S["offers"].size(), func(): m.go("offers")))
			g2.add_child(_nav("Finanças", "Caixa: %s" % Game.money(Game.S["money"]), func(): m.go("finance")))
			g2.add_child(_nav("Apoio da torcida: %d%%" % Game.S["support"], "Vitórias aumentam, derrotas e venda de ídolos derrubam", Callable()))
			content.add_child(g2)
		3:
			var g3 := UI.grid(2, 14)
			UI.expand(g3)
			g3.add_child(_nav("Tabela", "%s • %dº lugar" % [Game.LEAGUE, Game.position_of(Game.S["club"])], func(): m.go("table")))
			g3.add_child(_nav("Resultados", "Placar de todas as rodadas", func(): m.go("results", {"round": maxi(Game.S["last_round"], 0), "next": false})))
			g3.add_child(_nav("Calendário", "Seus jogos mês a mês", func(): m.go("calendar")))
			g3.add_child(_nav("Mercado da bola", "Contratações dos outros clubes", func(): m.go("transfers")))
			for ci in Game.S.get("cups", []).size():
				var cc: Dictionary = Game.S["cups"][ci]
				var stt := Cups.my_status(ci)
				var desc := "Campeão: %s" % Game.club_name(cc["champion"]) if cc["champion"] >= 0 else \
					("Próxima fase: %s" % Cups.stage_name(cc, cc["next"]))
				desc += {"campeão": "  •  VOCÊ É CAMPEÃO", "vivo": "  •  você está vivo", "eliminado": "  •  você caiu", "fora": "  •  não classificado"}[stt]
				g3.add_child(_nav(cc["name"], desc, func(): m.go("cup", {"cup": ci, "next": false})))
			content.add_child(g3)
		4:
			_tab_manager(content)
	var tabs := UI.hbox(8)
	for i in TABS.size():
		var b := UI.button(TABS[i], "gold" if i == m.hub_tab else "dark", _set_tab.bind(i), 16, 46)
		UI.expand(b)
		tabs.add_child(b)
	v.add_child(tabs)


func _set_tab(i: int) -> void:
	m.hub_tab = i
	m.refresh()


func _tab_games(content: Control) -> void:
	var cid: int = Game.S["club"]
	var me: Dictionary = Game.my_club()
	Game.validate_xi(cid)
	var rt: Dictionary = Game.ratings(cid)
	var left := UI.vbox(12)
	UI.expand(left, 1.5)
	content.add_child(left)

	var lp := UI.panel(UI.PANEL, 14)
	var lv := UI.vbox(6)
	lp.add_child(lv)
	lv.add_child(UI.card_title("GERENCIAR ESCALAÇÃO"))
	var en := Game.energy_avg(cid)
	lv.add_child(UI.label("%s • Energia %d%%" % [me["formation"], en], 21, UI.TXT, true))
	lv.add_child(UI.bar(en / 100.0))
	lv.add_child(UI.label("DEF %d    MEI %d    ATQ %d    GER %d" % [rt["def"], rt["mei"], rt["atq"], rt["ger"]], 18, UI.MUTED, true))
	var lh := UI.hbox(8)
	lh.add_child(UI.expand(UI.label("Apoio da torcida %d%%" % Game.S["support"], 14, UI.MUTED)))
	lh.add_child(UI.fixed(UI.button("Escalação", "dark", func(): m.go("lineup"), 16, 42), 150))
	lh.add_child(UI.fixed(UI.button("Autoescalar", "dark", func():
		Game.auto_lineup(Game.S["club"])
		Game.save()
		m.refresh()
		m.toast("Melhor time escalado."), 16, 42), 150))
	lv.add_child(lh)
	left.add_child(lp)

	var row := UI.hbox(12)
	row.add_child(_card("COMPRAR", "Reforços", "Mercado aberto", func(): m.go("market"), UI.GOLD))
	row.add_child(_card("VENDER", "%d proposta(s)" % Game.S["offers"].size(), "", func(): m.go("offers")))
	left.add_child(row)
	left.add_child(_card("TABELA • " + Game.LEAGUE, "%dº lugar" % Game.position_of(cid), "%d pts em %d jogos" % [me["pts"], me["j"]], func(): m.go("table")))

	var right := UI.vbox(12)
	UI.expand(right, 1.0)
	content.add_child(right)
	var np := UI.panel(UI.PANEL, 14)
	var nv := UI.vbox(6)
	np.add_child(nv)
	if Game.S["season_over"]:
		nv.add_child(UI.card_title("TEMPORADA ENCERRADA"))
		nv.add_child(UI.label("%dº lugar no %s" % [Game.position_of(cid), Game.LEAGUE], 20, UI.GOLD, true))
		nv.add_child(UI.button("Ver resumo da temporada  ›", "gold", func(): m.go("season_end")))
	else:
		var mt: Dictionary = Game.next_user_match()
		var home: bool = mt["h"] == cid
		var opp: int = mt["a"] if home else mt["h"]
		var ort: Dictionary = Game.ratings(opp)
		nv.add_child(UI.card_title("PRÓXIMA PARTIDA"))
		nv.add_child(UI.label(mt["comp"], 15, UI.GOLD, true))
		nv.add_child(UI.label("%s • %s" % [mt["label"], Game.fmt_date(mt["day"])], 13, UI.MUTED))
		var oh := UI.hbox(10)
		oh.add_child(Crest.make(opp, 44))
		var ov := UI.vbox(0)
		ov.add_child(UI.label("%s (%s)" % [Game.club_name(opp), "C" if home else "F"], 20, UI.TXT, true))
		ov.add_child(UI.label("DEF %d   MEI %d   ATQ %d" % [ort["def"], ort["mei"], ort["atq"]], 14, UI.MUTED))
		oh.add_child(ov)
		nv.add_child(oh)
		var bh := UI.hbox(8)
		bh.add_child(UI.expand(UI.button("Jogar", "gold", func(): m.go("match"))))
		bh.add_child(UI.expand(UI.button("Simular", "dark", _simulate)))
		nv.add_child(bh)
	right.add_child(np)

	var cv := UI.vbox(4)
	var ch := UI.hbox()
	ch.add_child(UI.expand(UI.card_title("CALENDÁRIO")))
	ch.add_child(UI.label("›", 18, UI.MUTED, true))
	cv.add_child(ch)
	var shown := 0
	for u in _upcoming(4):
		var h2: bool = u["h"] == cid
		var o2: int = u["a"] if h2 else u["h"]
		var rh := UI.hbox(8)
		rh.add_child(UI.col(Game.fmt_short(u["day"]), 52, 15, UI.MUTED, true, HORIZONTAL_ALIGNMENT_LEFT))
		rh.add_child(Crest.make(o2, 24))
		var tl := UI.label("%s (%s)%s" % [Game.club_name(o2), "C" if h2 else "F", "  •  " + u["comp"] if u["kind"] == "cup" else ""], 15)
		tl.clip_text = true
		rh.add_child(UI.expand(tl))
		cv.add_child(rh)
		shown += 1
	if shown == 0:
		cv.add_child(UI.label("Sem jogos até a próxima temporada", 15, UI.MUTED))
	var cb := UI.row_button(cv, func(): m.go("calendar"), 170, "dark", 14)
	UI.vexpand(cb)
	right.add_child(cb)


func _simulate() -> void:
	Game.play_next(null)
	m.go("postmatch", Game.S["last_user"])


## Próximos jogos do clube: rodadas do campeonato e confrontos de copa já sorteados.
func _upcoming(n: int) -> Array:
	var out: Array = []
	var cid: int = Game.S["club"]
	for r in range(Game.S["round"], mini(Game.S["round"] + n + 2, Game.S["fixtures"].size())):
		var fx: Dictionary = Game.my_match(r)
		out.append({"kind": "league", "day": Game.S["fixtures"][r]["day"], "h": fx["h"], "a": fx["a"], "comp": Game.LEAGUE})
	for i in Game.S.get("cups", []).size():
		var c: Dictionary = Game.S["cups"][i]
		if c["champion"] >= 0 or not (cid in c["alive"]) or c["next"] >= c["days"].size():
			continue
		var t := Cups.my_tie(i)
		if not t.is_empty():
			var st: Array = Cups.stages(c)
			var leg2: bool = c["next"] < st.size() and int(st[c["next"]]["leg"]) == 2
			# no jogo de volta o mando inverte
			out.append({"kind": "cup", "day": c["days"][c["next"]], "h": t["a"] if leg2 else t["h"], "a": t["h"] if leg2 else t["a"], "comp": c["name"]})
	out.sort_custom(func(x, y): return x["day"] < y["day"])
	return out.slice(0, n)


func _tab_manager(content: Control) -> void:
	var co: Dictionary = Game.S["coach"]
	var left := UI.panel(UI.PANEL, 16)
	left.custom_minimum_size = Vector2(280, 0)
	var lv := UI.vbox(4)
	left.add_child(lv)
	var av := CoachAvatar.new()
	av.coach = co
	av.custom_minimum_size = Vector2(200, 220)
	UI.vexpand(av)
	lv.add_child(av)
	lv.add_child(UI.center(UI.label(co["name"], 20, UI.TXT, true)))
	lv.add_child(UI.center(UI.label("%d anos • %s" % [co["age"], co["nat"]], 14, UI.MUTED)))
	lv.add_child(UI.center(UI.label("Reputação %.1f / 10" % co["rep"], 15, UI.GOLD, true)))
	content.add_child(left)

	var right := UI.panel(UI.PANEL, 16)
	UI.expand(right)
	var rv := UI.vbox(8)
	right.add_child(rv)
	rv.add_child(UI.card_title("TÍTULOS DO TÉCNICO"))
	if Game.S["trophies"].is_empty():
		rv.add_child(UI.label("Nenhum título ainda. A galeria está esperando.", 16, UI.MUTED))
	else:
		for t in Game.S["trophies"]:
			rv.add_child(UI.label("%s • %d" % [t["name"], t["year"]], 18, UI.GOLD, true))
	rv.add_child(UI.card_title("HISTÓRICO"))
	var sc := UI.scroll()
	var hv := UI.vbox(4)
	UI.expand(hv)
	sc.add_child(hv)
	if Game.S["history"].is_empty():
		hv.add_child(UI.label("Primeira temporada em andamento.", 16, UI.MUTED))
	for h in Game.S["history"]:
		hv.add_child(UI.label("%d — %dº lugar (campeão: %s)" % [h["year"], h["pos"], h["champion"]], 16))
	rv.add_child(sc)
	var bh := UI.hbox()
	bh.add_child(UI.spacer())
	bh.add_child(UI.fixed(UI.button("Salvar e sair", "dark", func():
		Game.save()
		Game.S = {}
		Game.slot = -1
		m.reset("careers")), 220))
	rv.add_child(bh)
	content.add_child(right)


# ------------------------------------------------------------ tabela
func table(root: Control, _arg) -> void:
	m.head(Game.LEAGUE, "Classificação • Temporada %d" % Game.S["season"])
	var v := UI.vbox(6)
	root.add_child(v)
	var cols := ["P", "J", "V", "E", "D", "GP", "GC", "SG"]
	var hh := UI.hbox(6)
	hh.add_child(UI.col("#", 44, 13, UI.MUTED, true))
	hh.add_child(UI.fixed(Control.new(), 30))
	hh.add_child(UI.expand(UI.label("CLUBE", 13, UI.MUTED, true)))
	for c in cols:
		hh.add_child(UI.col(c, 54, 13, UI.MUTED, true))
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 12)
	hm.add_theme_constant_override("margin_right", 12)
	hm.add_child(hh)
	v.add_child(hm)
	var sc := UI.scroll()
	v.add_child(sc)
	var lv := UI.vbox(4)
	UI.expand(lv)
	sc.add_child(lv)
	var tb := Game.sorted_table()
	for i in tb.size():
		var c: Dictionary = Game.club(tb[i])
		var mine: bool = tb[i] == Game.S["club"]
		var p := UI.panel(Color(UI.GOLD, 0.22) if mine else Color(1, 1, 1, 0.045), 6, 6)
		var st: StyleBoxFlat = p.get_theme_stylebox("panel")
		st.content_margin_left = 12
		st.content_margin_right = 12
		var h := UI.hbox(6)
		p.add_child(h)
		var pc := UI.TXT
		if i == 0:
			pc = UI.GOLD
		elif i >= 16:
			pc = Color("ff8b8b")
		h.add_child(UI.col(str(i + 1), 44, 17, pc, true))
		h.add_child(Crest.make(tb[i], 30))
		h.add_child(UI.expand(UI.label(c["name"], 17, UI.TXT, mine)))
		var vals := [c["pts"], c["j"], c["v"], c["e"], c["d"], c["gp"], c["gc"], c["gp"] - c["gc"]]
		for k in vals.size():
			h.add_child(UI.col(str(vals[k]), 54, 17, UI.TXT if k == 0 else UI.MUTED, k == 0))
		lv.add_child(p)


# ------------------------------------------------------------ calendário
func calendar(root: Control, _arg) -> void:
	m.head("Calendário", "Seus jogos na temporada")
	var today: Dictionary = Game.date_of(Game.S["day"])
	if cal_y == 0 or cal_y < int(today["year"]) - 1 or cal_y > int(today["year"]) + 1:
		cal_y = today["year"]
		cal_m = today["month"]
	var cid: int = Game.S["club"]
	var by_day := {}
	for r in Game.S["fixtures"].size():
		by_day[int(Game.S["fixtures"][r]["day"])] = Game.my_match(r)
	for u in _upcoming(12):
		if u["kind"] == "cup":
			by_day[int(u["day"])] = {"h": u["h"], "a": u["a"], "hg": -1, "ag": -1, "cup": true}
	var p := UI.panel(UI.PANEL, 12)
	root.add_child(p)
	var v := UI.vbox(6)
	p.add_child(v)
	var top := UI.hbox(12)
	top.add_child(UI.fixed(UI.button("‹", "dark", _cal_move.bind(-1), 22, 40), 54))
	top.add_child(UI.expand(UI.label("%s %d" % [Game.MONTHS[cal_m - 1], cal_y], 24, UI.TXT, true)))
	top.add_child(UI.label("Hoje: %s" % Game.fmt_date(Game.S["day"]), 15, UI.MUTED, true))
	top.add_child(UI.fixed(UI.button("›", "dark", _cal_move.bind(1), 22, 40), 54))
	v.add_child(top)
	var g := UI.grid(7, 6)
	UI.vexpand(g)
	v.add_child(g)
	for w in WEEK:
		g.add_child(UI.expand(UI.center(UI.label(w, 13, UI.MUTED, true))))
	var first := Game.day_of(cal_y, cal_m, 1)
	var start: int = first - int(Game.date_of(first)["weekday"])
	for i in 42:
		var day := start + i
		var d: Dictionary = Game.date_of(day)
		var inm: bool = int(d["month"]) == cal_m
		var col := Color(0.07, 0.12, 0.24, 0.9 if inm else 0.4)
		var fx: Dictionary = by_day.get(day, {})
		var has: bool = not fx.is_empty()
		var home := false
		if has:
			home = fx["h"] == cid
			if fx["hg"] >= 0:
				col = Color("5a2a4a")
			elif home:
				col = Color("1f7a52")
			else:
				col = Color("2a4a9a")
		var cell := UI.panel(col, 6, 6)
		if day == int(Game.S["day"]):
			cell.add_theme_stylebox_override("panel", UI.sbox(col, 6, 6, UI.GOLD, 2))
		UI.expand(cell)
		UI.vexpand(cell)
		var ch := UI.hbox(4)
		cell.add_child(ch)
		var cv := UI.vbox(0)
		UI.expand(cv)
		cv.add_child(UI.label(str(d["day"]), 17, UI.TXT if inm else UI.MUTED, true))
		if has:
			var txt := "CASA" if home else "FORA"
			if fx["hg"] >= 0:
				txt = "%d x %d" % [fx["hg"], fx["ag"]]
			cv.add_child(UI.label(txt, 13, UI.TXT, true))
			ch.add_child(cv)
			ch.add_child(Crest.make(fx["a"] if home else fx["h"], 30))
		else:
			ch.add_child(cv)
		g.add_child(cell)


func _cal_move(d: int) -> void:
	cal_m += d
	if cal_m < 1:
		cal_m = 12
		cal_y -= 1
	elif cal_m > 12:
		cal_m = 1
		cal_y += 1
	m.refresh()


# ------------------------------------------------------------ resultados
func results(root: Control, arg) -> void:
	var r: int = clampi(int(arg["round"]), 0, Game.S["fixtures"].size() - 1)
	var rd: Dictionary = Game.S["fixtures"][r]
	m.head(Game.LEAGUE, "Resultados • Rodada %d • %s" % [r + 1, Game.fmt_date(rd["day"])], not arg["next"])
	var v := UI.vbox(8)
	root.add_child(v)
	var sc := UI.scroll()
	v.add_child(sc)
	var lv := UI.vbox(5)
	UI.expand(lv)
	sc.add_child(lv)
	for mt in rd["m"]:
		var mine: bool = mt["h"] == Game.S["club"] or mt["a"] == Game.S["club"]
		var p := UI.panel(Color(UI.GOLD, 0.2) if mine else Color(1, 1, 1, 0.045), 7, 6)
		var h := UI.hbox(10)
		p.add_child(h)
		h.add_child(Crest.make(mt["h"], 30))
		h.add_child(UI.expand(UI.label(Game.club_name(mt["h"]), 17, UI.TXT, mine)))
		h.add_child(UI.col("%d : %d" % [mt["hg"], mt["ag"]] if mt["hg"] >= 0 else "x", 90, 19, UI.GOLD, true))
		var al := UI.label(Game.club_name(mt["a"]), 17, UI.TXT, mine)
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(UI.expand(al))
		h.add_child(Crest.make(mt["a"], 30))
		lv.add_child(p)
	var bh := UI.hbox(10)
	if arg["next"]:
		bh.add_child(UI.spacer())
		bh.add_child(UI.fixed(UI.button("Próximo", "gold", func(): m.home()), 320))
		bh.add_child(UI.spacer())
	else:
		bh.add_child(UI.fixed(UI.button("‹  Rodada anterior", "dark", func(): m.replace("results", {"round": r - 1, "next": false})), 240))
		bh.add_child(UI.spacer())
		bh.add_child(UI.fixed(UI.button("Próxima rodada  ›", "dark", func(): m.replace("results", {"round": r + 1, "next": false})), 240))
	v.add_child(bh)


func _stat_row(name: String, a: int, b: int) -> Control:
	var v := UI.vbox(3)
	var h := UI.hbox()
	h.add_child(UI.col(str(a), 60, 22, UI.TXT, true, HORIZONTAL_ALIGNMENT_LEFT))
	h.add_child(UI.expand(UI.center(UI.label(name, 16, UI.MUTED))))
	h.add_child(UI.col(str(b), 60, 22, UI.TXT, true, HORIZONTAL_ALIGNMENT_RIGHT))
	v.add_child(h)
	var bars := UI.hbox(0)
	var tot: float = maxf(float(a + b), 1.0)
	var ba := ColorRect.new()
	ba.color = Color("5aa2f2")
	ba.custom_minimum_size = Vector2(0, 5)
	UI.expand(ba, maxf(a / tot, 0.02))
	var bb := ColorRect.new()
	bb.color = Color("f0a05e")
	bb.custom_minimum_size = Vector2(0, 5)
	UI.expand(bb, maxf(b / tot, 0.02))
	bars.add_child(ba)
	bars.add_child(bb)
	v.add_child(bars)
	return v


func postmatch(root: Control, arg) -> void:
	var mt: Dictionary = arg if typeof(arg) == TYPE_DICTIONARY else Game.S["last_user"]
	var r: int = int(mt.get("round", 0))
	m.head(str(mt["comp"]), "Fim de jogo • %s • %s" % [mt["label"], Game.fmt_date(mt["day"])], false)
	var v := UI.vbox(12)
	root.add_child(v)
	var top := UI.hbox(14)
	top.add_child(Crest.make(mt["h"], 58))
	var hv := UI.vbox(0)
	UI.expand(hv)
	hv.add_child(UI.label(Game.club_name(mt["h"]), 22, UI.TXT, true))
	hv.add_child(UI.label("MANDANTE", 12, UI.MUTED, true))
	top.add_child(hv)
	var score_txt := "%d × %d" % [mt["hg"], mt["ag"]]
	if not mt.get("pens", []).is_empty():
		score_txt += "\n(pên. %d × %d)" % [mt["pens"][0], mt["pens"][1]]
	top.add_child(UI.center(UI.label(score_txt, 44 if mt.get("pens", []).is_empty() else 32, UI.TXT, true)))
	var avb := UI.vbox(0)
	UI.expand(avb)
	var an := UI.label(Game.club_name(mt["a"]), 22, UI.TXT, true)
	an.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var at := UI.label("VISITANTE", 12, UI.MUTED, true)
	at.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	avb.add_child(an)
	avb.add_child(at)
	top.add_child(avb)
	top.add_child(Crest.make(mt["a"], 58))
	v.add_child(top)
	# jogo de volta: agregado do confronto (mt["agg"] vem na visão de tie_h)
	if int(mt.get("leg", 1)) >= 2 and mt.has("agg"):
		var ag: Array = mt["agg"]
		var same: bool = int(mt.get("tie_h", mt["h"])) == int(mt["h"])
		var ah: int = int(ag[0]) if same else int(ag[1])
		var aa: int = int(ag[1]) if same else int(ag[0])
		var agp := UI.panel(Color(1, 1, 1, 0.06), 8, 10)
		agp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		agp.add_child(UI.center(UI.label("Agregado: %s %d × %d %s" % [Game.club_name(mt["h"]), ah, aa, Game.club_name(mt["a"])], 18, UI.GOLD, true)))
		v.add_child(agp)

	var mid := UI.hbox(14)
	UI.vexpand(mid)
	v.add_child(mid)
	var sp := UI.panel(UI.PANEL, 16)
	UI.expand(sp, 1.2)
	var sv := UI.vbox(6)
	sp.add_child(sv)
	sv.add_child(UI.card_title("ESTATÍSTICAS"))
	var st: Array = mt["st"]
	var tp: int = maxi(int(st[2][0]) + int(st[2][1]), 1)
	var ph := int(round(100.0 * st[2][0] / tp))
	sv.add_child(_stat_row("Jogadas de ataque", st[0][0], st[0][1]))
	sv.add_child(_stat_row("Chutes ao gol", st[1][0], st[1][1]))
	sv.add_child(_stat_row("Posse de bola (%)", ph, 100 - ph))
	if st.size() >= 7:
		sv.add_child(_stat_row("Faltas", st[3][0], st[3][1]))
		sv.add_child(_stat_row("Cartões amarelos", st[4][0], st[4][1]))
		sv.add_child(_stat_row("Cartões vermelhos", st[5][0], st[5][1]))
		sv.add_child(_stat_row("Impedimentos", st[6][0], st[6][1]))
	mid.add_child(sp)
	var gp := UI.panel(UI.PANEL, 16)
	UI.expand(gp, 1.0)
	var gv := UI.vbox(6)
	gp.add_child(gv)
	gv.add_child(UI.card_title("GOLS DA PARTIDA"))
	var gs := UI.scroll()
	var gl := UI.vbox(6)
	UI.expand(gl)
	gs.add_child(gl)
	gv.add_child(gs)
	if mt["sc"].is_empty():
		gl.add_child(UI.label("Sem gols.", 16, UI.MUTED))
	for s in mt["sc"]:
		var gh := UI.hbox(8)
		gh.add_child(Crest.make(mt["h"] if s["side"] == 0 else mt["a"], 24))
		gh.add_child(UI.col("%d'" % s["min"], 40, 15, UI.MUTED, true))
		var nm: String = s["name"]
		if s["aname"] != "":
			nm += "  (%s)" % s["aname"]
		gh.add_child(UI.label(nm, 16, UI.TXT, true))
		gl.add_child(gh)
	mid.add_child(gp)

	var bh := UI.hbox(10)
	bh.add_child(UI.fixed(UI.button("Ver classificação", "dark", func(): m.go("table")), 240))
	bh.add_child(UI.spacer())
	if mt.get("kind", "league") == "cup":
		bh.add_child(UI.fixed(UI.button("Resultados da fase  ›", "gold", func(): m.replace("cup_results", {"cup": mt["cup"], "stage": int(mt.get("stage", -1)), "next": true})), 340))
	else:
		bh.add_child(UI.fixed(UI.button("Resultados da rodada  ›", "gold", func(): m.replace("results", {"round": r, "next": true})), 340))
	v.add_child(bh)


# ------------------------------------------------------------ finanças
func finance(root: Control, _arg) -> void:
	m.head("Finanças", "Movimento da temporada")
	var p := UI.panel(UI.PANEL, 20)
	root.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var f: Dictionary = Game.S["fin"]
	var week := 0.0
	for pl in Game.squad(Game.S["club"]):
		week += float(pl["wage"])
	var rows := [["Caixa atual", Game.money(Game.S["money"]), UI.GOLD],
		["Folha salarial por semana", "$ %.1f mil" % week, UI.TXT],
		["Patrocínio", "+ " + Game.money(f["patrocinio"]), UI.GREEN_TXT],
		["Bilheteria", "+ " + Game.money(f["bilheteria"]), UI.GREEN_TXT],
		["Vendas de jogadores", "+ " + Game.money(f["vendas"]), UI.GREEN_TXT],
		["Premiações", "+ " + Game.money(f["premios"]), UI.GREEN_TXT],
		["Salários pagos", "− " + Game.money(f["salarios"]), Color("ff8b8b")],
		["Compras de jogadores", "− " + Game.money(f["compras"]), Color("ff8b8b")]]
	for r in rows:
		var h := UI.hbox()
		h.add_child(UI.expand(UI.label(r[0], 19)))
		h.add_child(UI.label(r[1], 20, r[2], true))
		v.add_child(h)
	v.add_child(UI.spacer())
	v.add_child(UI.wrap(UI.label("O caixa entra a cada rodada: patrocínio sempre, bilheteria nos jogos em casa (a torcida feliz enche mais o estádio). A premiação vem no fim do campeonato.", 14, UI.MUTED)))


# ------------------------------------------------------------ central (notícias)
func central(root: Control, _arg) -> void:
	m.head("Central", "Avisos e notícias do clube")
	Game.S["unread"] = 0
	m.central_b.text = "Central • 0"
	UI.style_button(m.central_b, "dark")
	var sc := UI.scroll()
	root.add_child(sc)
	var v := UI.vbox(6)
	UI.expand(v)
	sc.add_child(v)
	if Game.S["news"].is_empty():
		v.add_child(UI.label("Nada por aqui ainda.", 17, UI.MUTED))
	for n in Game.S["news"]:
		var p := UI.panel(Color(1, 1, 1, 0.05), 12, 8)
		var pv := UI.vbox(2)
		p.add_child(pv)
		var h := UI.hbox()
		h.add_child(UI.expand(UI.label(n["t"], 18, UI.GOLD, true)))
		h.add_child(UI.label(Game.fmt_date(n["day"]), 13, UI.MUTED))
		pv.add_child(h)
		pv.add_child(UI.wrap(UI.label(n["x"], 15)))
		v.add_child(p)


# ------------------------------------------------------------ mercado da bola
func transfers(root: Control, _arg) -> void:
	m.head("Mercado da bola", "Contratações dos outros clubes")
	var v := UI.vbox(6)
	root.add_child(v)
	var hh := UI.hbox(8)
	hh.add_child(UI.fixed(Control.new(), 56))
	hh.add_child(UI.expand(UI.label("JOGADOR / PAÍS", 13, UI.MUTED, true), 1.3))
	hh.add_child(UI.expand(UI.label("ORIGEM", 13, UI.MUTED, true)))
	hh.add_child(UI.expand(UI.label("DESTINO", 13, UI.MUTED, true)))
	hh.add_child(UI.col("VALOR", 120, 13, UI.MUTED, true, HORIZONTAL_ALIGNMENT_RIGHT))
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 10)
	hm.add_theme_constant_override("margin_right", 10)
	hm.add_child(hh)
	v.add_child(hm)
	var sc := UI.scroll()
	v.add_child(sc)
	var lv := UI.vbox(5)
	UI.expand(lv)
	sc.add_child(lv)
	if Game.S["transfers"].is_empty():
		lv.add_child(UI.label("Nenhuma negociação concluída ainda.", 17, UI.MUTED))
	for t in Game.S["transfers"]:
		var p := UI.panel(Color(1, 1, 1, 0.05), 10, 8)
		var h := UI.hbox(8)
		p.add_child(h)
		h.add_child(UI.pos_tag(t["pos"]))
		var nv := UI.vbox(0)
		UI.expand(nv, 1.3)
		nv.add_child(UI.label(t["name"], 17, UI.TXT, true))
		nv.add_child(UI.label("%s • Definitiva • %s" % [t["nat"], Game.fmt_date(t["day"])], 12, UI.MUTED))
		h.add_child(nv)
		for cid in [t["from"], t["to"]]:
			var ch := UI.hbox(6)
			UI.expand(ch)
			ch.add_child(Crest.make(cid, 30))
			ch.add_child(UI.label(Game.club_name(cid), 15))
			h.add_child(ch)
		h.add_child(UI.col("Livre" if t["value"] <= 0.0 else Game.money(t["value"]), 120, 17, UI.GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT))
		lv.add_child(p)


# ------------------------------------------------------------ fim de temporada
func season_end(root: Control, _arg) -> void:
	var sm: Dictionary = Game.season_summary()
	m.head("Fim de temporada", "%s • %d" % [Game.LEAGUE, Game.S["year"]])
	var hb := UI.hbox(14)
	root.add_child(hb)
	var lp := UI.panel(UI.PANEL, 20)
	UI.expand(lp, 1.2)
	var lv := UI.vbox(8)
	lp.add_child(lv)
	var champ: bool = sm["champion"] == Game.S["club"]
	lv.add_child(UI.label("CAMPEÃO!" if champ else "%dº LUGAR" % sm["pos"], 40, UI.GOLD, true))
	if champ and int(Game.S.get("league_celebrated", -1)) != int(Game.S["year"]):
		Game.S["league_celebrated"] = int(Game.S["year"])
		var llogo: Texture2D = DataPack.comp_logo_by_id(DataPack.comp_id(int(Game.S.get("league", 0))))
		CupScreens.celebrate(m.overlay, Game.LEAGUE, Game.club_name(Game.S["club"]), llogo, CupScreens.trophy_style(Game.LEAGUE))
	var ch := UI.hbox(10)
	ch.add_child(Crest.make(sm["champion"], 40))
	ch.add_child(UI.label("Campeão: %s" % Game.club_name(sm["champion"]), 19, UI.TXT, true))
	lv.add_child(ch)
	lv.add_child(UI.label("Premiação: %s" % Game.money(sm["prize"]), 19))
	var top: Dictionary = sm["top"]
	lv.add_child(UI.label("Artilheiro: %s (%s) — %d gols" % [top["name"], Game.club_name(top["club"]), top["gol"]], 17, UI.MUTED))
	for cc in Game.S.get("cups", []):
		if cc["champion"] >= 0:
			var crow := UI.hbox(8)
			crow.add_child(Crest.make(cc["champion"], 26))
			crow.add_child(UI.label("%s: %s" % [cc["name"], Game.club_name(cc["champion"])], 16, UI.GOLD if cc["champion"] == Game.S["club"] else UI.TXT, true))
			lv.add_child(crow)
	lv.add_child(UI.spacer())
	lv.add_child(UI.wrap(UI.label("Na virada do ano os jogadores evoluem ou caem com a idade, os mais velhos se aposentam e chegam novos garotos na base.", 14, UI.MUTED)))
	lv.add_child(UI.button("Iniciar nova temporada  ›", "gold", func():
		Game.new_season()
		m.hub_tab = 0
		m.home()
		m.toast("Temporada %d começou." % Game.S["season"]), 19, 52))
	hb.add_child(lp)
	var rp := UI.panel(UI.PANEL, 16)
	UI.expand(rp, 1.0)
	var rv := UI.vbox(5)
	rp.add_child(rv)
	rv.add_child(UI.card_title("CLASSIFICAÇÃO FINAL"))
	var tb: Array = sm["table"]
	for i in mini(8, tb.size()):
		var h := UI.hbox(8)
		h.add_child(UI.col(str(i + 1), 30, 16, UI.GOLD if i == 0 else UI.MUTED, true))
		h.add_child(Crest.make(tb[i], 26))
		h.add_child(UI.expand(UI.label(Game.club_name(tb[i]), 16, UI.TXT, tb[i] == Game.S["club"])))
		h.add_child(UI.label("%d pts" % Game.club(tb[i])["pts"], 16, UI.MUTED, true))
		rv.add_child(h)
	rv.add_child(UI.spacer())
	rv.add_child(UI.button("Tabela completa", "dark", func(): m.go("table"), 16, 42))
	hb.add_child(rp)


# ------------------------------------------------------------ copa (chaveamento)
## Chaveamento: agora montado em src/screens_cup.gd (tema da copa).
func cup(root: Control, arg) -> void:
	var f: Callable = m.screens["cup"]
	f.call(root, arg)
