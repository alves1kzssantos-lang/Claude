extends RefCounted
# Escalação, elenco, perfil do jogador, base, mercado, contrato e vendas.

var m
var sel_slot: int = -1
var mk_tab: int = 0
var mk_pos: int = -1
var c_pid: int = -1
var c_fee: float = 0.0
var c_wage: float = 0.0
var c_years: int = 3


func _init(main) -> void:
	m = main


# ------------------------------------------------------------ escalação
func lineup(root: Control, _arg) -> void:
	var cid: int = Game.S["club"]
	var me: Dictionary = Game.my_club()
	Game.validate_xi(cid)
	m.head("Escalação", "Toque em um jogador no campo e depois em outro (ou num reserva) para trocar")
	var hb := UI.hbox(16)
	root.add_child(hb)
	var rt: Dictionary = Game.ratings(cid)

	var left := UI.vbox(8)
	UI.expand(left, 1.0)
	hb.add_child(left)
	var fh := UI.hbox(8)
	fh.add_child(UI.fixed(UI.button("‹", "dark", _formation.bind(-1), 22, 40), 50))
	fh.add_child(UI.fixed(UI.center(UI.label(me["formation"], 21, UI.TXT, true)), 110))
	fh.add_child(UI.fixed(UI.button("›", "dark", _formation.bind(1), 22, 40), 50))
	fh.add_child(UI.spacer())
	fh.add_child(UI.label("GER %d" % rt["ger"], 21, UI.GOLD, true))
	left.add_child(fh)
	var pitch := PitchView.new()
	pitch.mode = "lineup"
	pitch.cid = cid
	pitch.selected = sel_slot
	UI.vexpand(pitch)
	pitch.slot_pressed.connect(_slot)
	left.add_child(pitch)

	var right := UI.vbox(8)
	UI.expand(right, 1.0)
	hb.add_child(right)
	right.add_child(UI.label("RESERVAS", 14, UI.MUTED, true))
	var sc := UI.scroll()
	right.add_child(sc)
	var g := UI.grid(3, 8)
	UI.expand(g)
	sc.add_child(g)
	for p in Game.bench(cid):
		var v := UI.vbox(2)
		var h := UI.hbox(8)
		h.add_child(UI.pos_tag(p["pos"], 13))
		h.add_child(UI.label(str(p["ovr"]), 21, UI.TXT, true))
		v.add_child(h)
		var nl := UI.label(p["name"], 13, UI.MUTED)
		nl.clip_text = true
		v.add_child(nl)
		v.add_child(UI.bar(float(p["energy"]) / 100.0, UI.GREEN if p["energy"] > 60.0 else UI.RED, 4))
		var b := UI.row_button(v, _bench.bind(p["id"]), 78, "dark", 8)
		UI.expand(b)
		g.add_child(b)
	right.add_child(UI.label("DEF %d    MEI %d    ATQ %d" % [rt["def"], rt["mei"], rt["atq"]], 18, UI.TXT, true))
	var bh := UI.hbox(8)
	if sel_slot >= 0 and sel_slot < me["xi"].size():
		var sp: Dictionary = Game.player(me["xi"][sel_slot])
		bh.add_child(UI.expand(UI.label("Selecionado: %s" % sp["name"], 15, UI.GOLD, true)))
		bh.add_child(UI.fixed(UI.button("Perfil", "dark", func(): m.go("player", sp["id"]), 16, 44), 110))
	else:
		bh.add_child(UI.expand(UI.label("Borda vermelha = fora de posição", 14, UI.MUTED)))
	bh.add_child(UI.fixed(UI.button("Escalar melhor", "blue", func():
		Game.auto_lineup(Game.S["club"])
		sel_slot = -1
		Game.save()
		m.refresh(), 16, 44), 170))
	right.add_child(bh)


func _formation(d: int) -> void:
	var me: Dictionary = Game.my_club()
	var i: int = Game.FORMATION_NAMES.find(me["formation"])
	me["formation"] = Game.FORMATION_NAMES[posmod(i + d, Game.FORMATION_NAMES.size())]
	Game.auto_lineup(Game.S["club"])
	sel_slot = -1
	Game.save()
	m.refresh()


func _slot(i: int) -> void:
	var xi: Array = Game.my_club()["xi"]
	if sel_slot < 0:
		sel_slot = i
	elif sel_slot == i:
		sel_slot = -1
	else:
		var t = xi[sel_slot]
		xi[sel_slot] = xi[i]
		xi[i] = t
		sel_slot = -1
		Game.save()
	m.refresh()


func _bench(pid: int) -> void:
	if sel_slot < 0:
		m.go("player", pid)
		return
	Game.my_club()["xi"][sel_slot] = pid
	sel_slot = -1
	Game.save()
	m.refresh()


# ------------------------------------------------------------ listas de jogadores
func _list_header(cols: Array) -> Control:
	var hh := UI.hbox(8)
	hh.add_child(UI.fixed(Control.new(), 50))
	hh.add_child(UI.expand(UI.label("JOGADOR", 13, UI.MUTED, true)))
	for c in cols:
		hh.add_child(UI.col(c[0], c[1], 13, UI.MUTED, true))
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 10)
	hm.add_theme_constant_override("margin_right", 10)
	hm.add_child(hh)
	return hm


func _player_row(p: Dictionary, cells: Array, cb: Callable, suffix: String = "") -> Button:
	var h := UI.hbox(8)
	h.add_child(UI.pos_tag(p["pos"]))
	var nv := UI.vbox(0)
	UI.expand(nv)
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	var nl := UI.label(str(p["name"]) + suffix, 17, UI.TXT, true)
	nl.clip_text = true
	nv.add_child(nl)
	h.add_child(nv)
	for c in cells:
		h.add_child(UI.col(c[0], c[1], 16, c[2] if c.size() > 2 else UI.TXT, c.size() > 2))
	return UI.row_button(h, cb, 48, "flat", 10)


func squad(root: Control, _arg) -> void:
	var list := Game.squad(Game.S["club"])
	m.head("Elenco", "%d jogadores • toque para ver o perfil" % list.size())
	var v := UI.vbox(6)
	root.add_child(v)
	v.add_child(_list_header([["PAÍS", 56], ["IDADE", 60], ["GER", 56], ["ENERGIA", 80], ["J", 44], ["G", 44], ["A", 44], ["VALOR", 110]]))
	var sc := UI.scroll()
	v.add_child(sc)
	var lv := UI.vbox(4)
	UI.expand(lv)
	sc.add_child(lv)
	for p in list:
		var nm_extra := "  (à venda)" if p["listed"] else ""
		lv.add_child(_player_row(p, [[p["nat"], 56], [str(p["age"]), 60], [str(p["ovr"]), 56, UI.GOLD], ["%d%%" % int(p["energy"]), 80],
			[str(p["g"]), 44], [str(p["gol"]), 44], [str(p["ass"]), 44], [Game.money(p["value"]), 110]], func(): m.go("player", p["id"]), nm_extra))


# ------------------------------------------------------------ perfil
func player(root: Control, arg) -> void:
	var pid: int = int(arg)
	if not Game.S["players"].has(pid):
		m.head("Jogador", "")
		root.add_child(UI.label("Este jogador não está mais disponível.", 18, UI.MUTED))
		return
	var p: Dictionary = Game.player(pid)
	var mine: bool = p["club"] == Game.S["club"]
	m.head(p["name"], "História, conquistas e vínculo com a torcida")
	var hb := UI.hbox(14)
	root.add_child(hb)

	var lp := UI.panel(UI.PANEL, 20)
	UI.expand(lp, 1.25)
	var lv := UI.vbox(8)
	lp.add_child(lv)
	var st: String = Game.status(p) if p["club"] >= 0 else ("JOVEM DA BASE" if p["club"] == Game.YOUTH else "JOGADOR LIVRE")
	lv.add_child(UI.label(st, 32, UI.GOLD, true))
	var th := UI.hbox(8)
	th.add_child(UI.pos_tag(p["pos"]))
	th.add_child(UI.label("%d anos • %s • %s" % [p["age"], p["nat"], Game.club_name(p["club"])], 16, UI.MUTED))
	lv.add_child(th)
	if p["club"] >= 0:
		lv.add_child(UI.label("Tempo de clube: %d ano(s)" % (Game.S["season"] - int(p["joined"])), 20, UI.TXT, true))
		lv.add_child(UI.label("Participação: %d min • %d gols • %d assistências" % [p["cmin"], p["cgol"], p["cass"]], 17))
		lv.add_child(UI.label("%d título(s)" % p["titles"].size(), 19, UI.TXT, true))
	var g := UI.grid(4, 10)
	var pot_txt: String = str(p["pot"])
	if p["age"] < 24:
		pot_txt = "%d–%d" % [int(p["pot"]) - 2, mini(int(p["pot"]) + 2, 99)]
	var attrs := [["GER", str(p["ovr"])], ["POTENCIAL", pot_txt], ["ENERGIA", "%d%%" % int(p["energy"])], ["CONTRATO", "%d ano(s)" % p["contract"]],
		["VALOR", Game.money(p["value"])], ["SALÁRIO/SEM", "$ %.1fk" % p["wage"]]]
	for a in attrs:
		var ap := UI.panel(Color(1, 1, 1, 0.05), 8, 8)
		UI.expand(ap)
		var av := UI.vbox(0)
		ap.add_child(av)
		av.add_child(UI.label(a[0], 12, UI.MUTED, true))
		av.add_child(UI.label(a[1], 18, UI.TXT, true))
		g.add_child(ap)
	lv.add_child(g)
	lv.add_child(UI.spacer())
	if mine:
		lv.add_child(UI.label("Ídolos exigem tempo e feitos históricos.", 14, UI.MUTED))
		lv.add_child(UI.label("Vender um ídolo: −25 de apoio da torcida.", 14, Color("f0a57a"), true))
	hb.add_child(lp)

	var rp := UI.panel(UI.PANEL, 20)
	UI.expand(rp, 1.0)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	rv.add_child(UI.label("TÍTULOS", 20, UI.TXT, true))
	if p["titles"].is_empty():
		rv.add_child(UI.label("Nenhum título pelo clube ainda.", 15, UI.MUTED))
	else:
		var cnt := {}
		for t in p["titles"]:
			cnt[t] = int(cnt.get(t, 0)) + 1
		for t in cnt.keys():
			var h := UI.hbox(8)
			h.add_child(UI.label("%d×" % cnt[t], 22, UI.GOLD, true))
			h.add_child(UI.label(t, 17))
			rv.add_child(h)
	rv.add_child(UI.label("NESTA TEMPORADA", 14, UI.MUTED, true))
	rv.add_child(UI.label("%d jogos • %d min • %d gols • %d assistências" % [p["g"], p["min"], p["gol"], p["ass"]], 16))
	rv.add_child(UI.spacer())
	if mine:
		rv.add_child(UI.button("Retirar da lista de venda" if p["listed"] else "Colocar à venda", "dark" if p["listed"] else "gold", func():
			p["listed"] = not p["listed"]
			Game.save()
			m.refresh()
			m.toast("Os clubes interessados vão mandar propostas nas próximas rodadas." if p["listed"] else "Jogador retirado da lista.")))
	elif p["club"] == Game.YOUTH:
		rv.add_child(UI.button("Promover ao profissional", "gold", _promote.bind(pid)))
	else:
		rv.add_child(UI.button("Negociar  ›", "blue", func(): m.go("contract", pid)))
	hb.add_child(rp)


func _promote(pid: int) -> void:
	var res := Game.promote_youth(pid)
	if res == "":
		m.back()
		m.toast("Jovem promovido ao elenco profissional.")
	else:
		m.toast(res)


# ------------------------------------------------------------ base
func youth(root: Control, _arg) -> void:
	var list := Game.squad(Game.YOUTH)
	m.head("Base do clube", "%s • %d jovens na base" % [Game.my_club()["name"], list.size()])
	var v := UI.vbox(6)
	root.add_child(v)
	v.add_child(UI.label("NOVOS JOVENS A CADA 6 MESES", 14, UI.GOLD, true))
	v.add_child(UI.label("Você decide quem sobe ao profissional. Quem fica continua evoluindo até os 20 anos.", 14, UI.MUTED))
	v.add_child(_list_header([["IDADE", 60], ["GER", 60], ["POTENCIAL", 110], ["EVOLUÇÃO", 130], ["", 130]]))
	var sc := UI.scroll()
	v.add_child(sc)
	var lv := UI.vbox(5)
	UI.expand(lv)
	sc.add_child(lv)
	if list.is_empty():
		lv.add_child(UI.label("Nenhum jovem no momento. A próxima captação traz novos nomes.", 16, UI.MUTED))
	list.sort_custom(func(a, b): return a["pot"] > b["pot"])
	for p in list:
		var pn := UI.panel(Color(1, 1, 1, 0.05), 8, 8)
		var st: StyleBoxFlat = pn.get_theme_stylebox("panel")
		st.content_margin_left = 10
		st.content_margin_right = 10
		var h := UI.hbox(8)
		pn.add_child(h)
		h.add_child(UI.pos_tag(p["pos"]))
		var nv := UI.vbox(0)
		UI.expand(nv)
		nv.add_child(UI.label(p["name"], 17, UI.TXT, true))
		nv.add_child(UI.label(p["nat"], 12, UI.MUTED))
		h.add_child(nv)
		h.add_child(UI.col(str(p["age"]), 60, 16))
		h.add_child(UI.col(str(p["ovr"]), 60, 18, UI.TXT, true))
		h.add_child(UI.col("%d–%d" % [int(p["pot"]) - 2, int(p["pot"]) + 2], 110, 16, UI.GOLD, true))
		var stars := UI.hbox(4)
		stars.custom_minimum_size = Vector2(130, 0)
		stars.alignment = BoxContainer.ALIGNMENT_CENTER
		var n: int = clampi(int((int(p["pot"]) - int(p["ovr"])) / 5.0), 1, 5)
		for i in 5:
			var cr := ColorRect.new()
			cr.color = UI.GOLD if i < n else Color(1, 1, 1, 0.12)
			cr.custom_minimum_size = Vector2(16, 8)
			cr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stars.add_child(cr)
		h.add_child(stars)
		h.add_child(UI.fixed(UI.button("Promover", "blue", _promote_here.bind(p["id"]), 15, 38), 130))
		lv.add_child(pn)


func _promote_here(pid: int) -> void:
	var res := Game.promote_youth(pid)
	if res == "":
		m.refresh()
		m.toast("Jovem promovido ao elenco profissional.")
	else:
		m.toast(res)


# ------------------------------------------------------------ mercado
func market(root: Control, _arg) -> void:
	m.head("Contratar jogadores", "Observe o atleta e envie uma proposta")
	var v := UI.vbox(8)
	root.add_child(v)
	var top := UI.hbox(8)
	var names := ["Livres", "Destaques", "Meu elenco"]
	for i in names.size():
		top.add_child(UI.fixed(UI.button(names[i], "gold" if i == mk_tab else "dark", _mk_tab.bind(i), 16, 42), 160))
	top.add_child(UI.spacer())
	var ptxt := "Todas" if mk_pos < 0 else str(Game.POS_ORDER[mk_pos])
	top.add_child(UI.fixed(UI.button("Posição: %s  ›" % ptxt, "dark", func():
		mk_pos += 1
		if mk_pos >= Game.POS_ORDER.size():
			mk_pos = -1
		m.refresh(), 16, 42), 220))
	v.add_child(top)
	v.add_child(_list_header([["PAÍS", 56], ["GER", 56], ["IDADE", 60], ["VALOR", 120], ["CLUBE", 170]]))
	var sc := UI.scroll()
	v.add_child(sc)
	var lv := UI.vbox(4)
	UI.expand(lv)
	sc.add_child(lv)
	var list: Array = []
	if mk_tab == 0:
		list = Game.squad(Game.FREE)
	elif mk_tab == 2:
		list = Game.squad(Game.S["club"])
	else:
		for p in Game.S["players"].values():
			if p["club"] >= 0 and p["club"] != Game.S["club"]:
				list.append(p)
	if mk_pos >= 0:
		list = list.filter(func(p): return p["pos"] == Game.POS_ORDER[mk_pos])
	list.sort_custom(func(a, b):
		if a["ovr"] != b["ovr"]:
			return a["ovr"] > b["ovr"]
		return a["id"] < b["id"])
	if list.size() > 40:
		list = list.slice(0, 40)
	if list.is_empty():
		lv.add_child(UI.label("Ninguém encontrado com esse filtro.", 16, UI.MUTED))
	for p in list:
		var val := "Livre" if p["club"] == Game.FREE else Game.money(p["value"])
		var target := "player" if mk_tab == 2 else "contract"
		lv.add_child(_player_row(p, [[p["nat"], 56], [str(p["ovr"]), 56, UI.GOLD], [str(p["age"]), 60], [val, 120], [Game.club_name(p["club"]), 170]],
			func(): m.go(target, p["id"])))


func _mk_tab(i: int) -> void:
	mk_tab = i
	m.refresh()


# ------------------------------------------------------------ contrato
func contract(root: Control, arg) -> void:
	var pid: int = int(arg)
	var p: Dictionary = Game.player(pid)
	var free: bool = p["club"] == Game.FREE
	if c_pid != pid:
		c_pid = pid
		c_fee = 0.0 if free else float(p["value"])
		c_wage = float(p["wage"])
		c_years = 3
	m.head("Contrato com o jogador", "Atleta livre • negocie salário e duração direto com ele" if free else "Negocie com o %s e com o atleta" % Game.club_name(p["club"]))
	var v := UI.vbox(12)
	root.add_child(v)
	var hb := UI.hbox(14)
	UI.vexpand(hb)
	v.add_child(hb)

	var lp := UI.panel(UI.PANEL, 18)
	lp.custom_minimum_size = Vector2(330, 0)
	var lv := UI.vbox(6)
	lp.add_child(lv)
	var th := UI.hbox()
	th.add_child(UI.pos_tag(p["pos"]))
	lv.add_child(th)
	lv.add_child(UI.label(p["name"], 22, UI.TXT, true))
	lv.add_child(UI.label("%d anos • %s" % [p["age"], p["nat"]], 15, UI.MUTED))
	lv.add_child(UI.label("GER %d" % p["ovr"], 20, UI.GOLD, true))
	lv.add_child(UI.label(Game.club_name(p["club"]), 15, UI.MUTED))
	lv.add_child(UI.spacer())
	lv.add_child(UI.label("Valor de mercado: %s" % Game.money(p["value"]), 14, UI.MUTED))
	lv.add_child(UI.label("Salário atual: $ %.1fk / semana" % p["wage"], 14, UI.MUTED))
	lv.add_child(UI.button("Ver perfil", "dark", func(): m.go("player", pid), 15, 40))
	hb.add_child(lp)

	var rp := UI.panel(UI.PANEL, 18)
	UI.expand(rp)
	var rv := UI.vbox(12)
	rp.add_child(rv)
	if free:
		rv.add_child(UI.label("NEGOCIAÇÃO DIRETA", 15, UI.GOLD, true))
		rv.add_child(UI.label("Sem pagamento a outro clube e sem luvas.", 14, UI.MUTED))
	else:
		var step: float = maxf(snappedf(float(p["value"]) * 0.05, 0.01), 0.01)
		rv.add_child(UI.field("PROPOSTA AO CLUBE", UI.stepper(Game.money(c_fee), _fee.bind(-step), _fee.bind(step), 190)))
	var ws: float = maxf(snappedf(float(p["wage"]) * 0.05, 0.1), 0.1)
	var row := UI.hbox(30)
	row.add_child(UI.field("SALÁRIO / SEMANA", UI.stepper("$ %.1fk" % c_wage, _wage.bind(-ws), _wage.bind(ws), 150)))
	row.add_child(UI.field("DURAÇÃO", UI.stepper("%d ano(s)" % c_years, _years.bind(-1), _years.bind(1), 120)))
	rv.add_child(row)
	rv.add_child(UI.spacer())
	rv.add_child(UI.label("Seu caixa: %s" % Game.money(Game.S["money"]), 16, UI.MUTED, true))
	hb.add_child(rp)

	var bh := UI.hbox(12)
	bh.add_child(UI.fixed(UI.button("Cancelar negociação", "dark", func(): m.back()), 280))
	bh.add_child(UI.expand(UI.button("Enviar contrato ao jogador", "blue", _send.bind(pid))))
	v.add_child(bh)


func _fee(d: float) -> void:
	c_fee = maxf(snappedf(c_fee + d, 0.01), 0.0)
	m.refresh()


func _wage(d: float) -> void:
	c_wage = maxf(snappedf(c_wage + d, 0.1), 0.5)
	m.refresh()


func _years(d: int) -> void:
	c_years = clampi(c_years + d, 1, 5)
	m.refresh()


func _send(pid: int) -> void:
	var res := Game.sign_player(pid, c_fee, c_wage, c_years)
	if res == "":
		c_pid = -1
		m.back()
		m.toast("Negócio fechado! O jogador já está no seu elenco.")
	else:
		m.toast(res)


# ------------------------------------------------------------ propostas e vendas
func offers(root: Control, _arg) -> void:
	m.head("Propostas e vendas", "Decida o que fazer com cada proposta")
	var sc := UI.scroll()
	root.add_child(sc)
	var v := UI.vbox(6)
	UI.expand(v)
	sc.add_child(v)
	v.add_child(UI.label("PROPOSTAS NA MESA", 14, UI.GOLD, true))
	if Game.S["offers"].is_empty():
		v.add_child(UI.label("Nenhuma proposta no momento.", 16, UI.MUTED))
	for i in Game.S["offers"].size():
		var o: Dictionary = Game.S["offers"][i]
		if not Game.S["players"].has(o["pid"]):
			continue
		var p: Dictionary = Game.player(o["pid"])
		var pn := UI.panel(Color(1, 1, 1, 0.05), 10, 8)
		var h := UI.hbox(10)
		pn.add_child(h)
		h.add_child(UI.pos_tag(p["pos"]))
		var nv := UI.vbox(0)
		UI.expand(nv)
		nv.add_child(UI.label("%s • GER %d" % [p["name"], p["ovr"]], 17, UI.TXT, true))
		nv.add_child(UI.label("%s • valor de mercado %s" % [Game.status(p), Game.money(p["value"])], 13, UI.MUTED))
		h.add_child(nv)
		h.add_child(Crest.make(o["club"], 30))
		h.add_child(UI.col(Game.money(o["value"]), 130, 18, UI.GOLD, true))
		h.add_child(UI.fixed(UI.button("Aceitar", "green", _accept.bind(i), 15, 40), 110))
		h.add_child(UI.fixed(UI.button("Recusar", "dark", _reject.bind(i), 15, 40), 110))
		v.add_child(pn)
	v.add_child(UI.label("JOGADORES À VENDA", 14, UI.GOLD, true))
	var any := false
	for p in Game.squad(Game.S["club"]):
		if p["listed"]:
			any = true
			v.add_child(_player_row(p, [[str(p["ovr"]), 56, UI.GOLD], [str(p["age"]), 60], [Game.money(p["value"]), 120]], func(): m.go("player", p["id"])))
	if not any:
		v.add_child(UI.label("Ninguém na lista. Abra o perfil de um jogador no Elenco e toque em \"Colocar à venda\".", 15, UI.MUTED))
	v.add_child(UI.fixed(UI.button("Abrir elenco", "dark", func(): m.go("squad"), 16, 44), 0))


func _accept(i: int) -> void:
	var res := Game.accept_offer(i)
	m.refresh()
	m.toast("Venda concluída." if res == "" else res)


func _reject(i: int) -> void:
	Game.reject_offer(i)
	m.refresh()
