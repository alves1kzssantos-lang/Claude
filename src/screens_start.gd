extends RefCounted
# Telas iniciais: carreiras, criar técnico e escolher clube.

var m
var coach: Dictionary = {}
var new_slot: int = 0
var sel_club: int = -1
var coach_tab: int = 0
var sel_league: int = 0
var dp_tab: int = 0
var dp_query: String = ""


func _init(main) -> void:
	m = main


# ------------------------------------------------------------ carreiras
func careers(root: Control, _arg) -> void:
	m.head("Minhas carreiras", "Até quatro carreiras independentes", false)
	var v := UI.vbox(12)
	root.add_child(v)
	var th := UI.hbox(10)
	th.add_child(UI.fixed(Control.new(), 230))
	th.add_child(UI.expand(UI.center(UI.label("CRAQUE MANAGER", 34, UI.GOLD, true))))
	th.add_child(UI.fixed(UI.button("Datapack: %s" % ("ativo" if DataPack.loaded() else "nenhum"), "blue" if DataPack.loaded() else "dark", func(): m.go("datapack"), 15, 40), 230))
	v.add_child(th)
	var g := UI.grid(2, 14)
	UI.vexpand(g)
	v.add_child(g)
	for i in 4:
		var p := UI.panel(UI.PANEL, 18)
		UI.expand(p)
		UI.vexpand(p)
		var pv := UI.vbox(8)
		p.add_child(pv)
		pv.add_child(UI.label("Carreira %d" % (i + 1), 21, UI.TXT, true))
		var info: Dictionary = Game.peek_save(i)
		if info.is_empty():
			pv.add_child(UI.label("Espaço disponível para uma nova história", 15, UI.MUTED))
			pv.add_child(UI.spacer())
			var hb := UI.hbox(10)
			hb.add_child(UI.expand(UI.button("Carreira de técnico", "blue", _new.bind(i))))
			hb.add_child(UI.expand(UI.button("Carreira de jogador", "gold", func(): m.go("pro_create", {"slot": i}))))
			pv.add_child(hb)
		else:
			var ih := UI.hbox(12)
			ih.add_child(Crest.make_raw(info["short"], info["c1"], info["c2"], 54, info["li"], info["club"]))
			var iv := UI.vbox(0)
			if info.get("mode", "") == "pro":
				iv.add_child(UI.label("%s • %s %d" % [info.get("player", ""), info.get("pos", ""), info.get("ovr", 0)], 20, UI.GOLD, true))
				var where: String = "Peneira" if info.get("stage", "") == "peneira" else info["name"]
				iv.add_child(UI.label("JOGADOR • %s • Temporada %d • %d" % [where, info["season"], info["year"]], 15, UI.MUTED))
			else:
				iv.add_child(UI.label(info["name"], 20, UI.GOLD, true))
				iv.add_child(UI.label("TÉCNICO • %s • Temporada %d • %d" % [info["league"], info["season"], info["year"]], 15, UI.MUTED))
			ih.add_child(iv)
			pv.add_child(ih)
			pv.add_child(UI.spacer())
			var hb2 := UI.hbox()
			hb2.add_child(UI.fixed(UI.button("Carregar", "gold", _load.bind(i)), 200))
			hb2.add_child(UI.spacer())
			var del := UI.button("Excluir", "red")
			del.custom_minimum_size = Vector2(190, 46)
			del.pressed.connect(_delete.bind(i, del))
			hb2.add_child(del)
			pv.add_child(hb2)
		g.add_child(p)


func _new(i: int) -> void:
	new_slot = i
	sel_club = -1
	coach_tab = 0
	coach = {"name": "Novo técnico", "age": 35, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}
	m.go("coach")


func _load(i: int) -> void:
	if Game.load_career(i):
		m.hub_tab = 0
		m.home()
	else:
		m.toast("Não foi possível carregar esta carreira.")


func _delete(i: int, b: Button) -> void:
	if b.text == "Excluir":
		b.text = "Confirmar exclusão"
		return
	Game.delete_save(i)
	m.refresh()


# ------------------------------------------------------------ técnico
func coach_screen(root: Control, _arg) -> void:
	m.head("Crie seu técnico", "Defina a identidade, o visual e a reputação inicial")
	var hb := UI.hbox(16)
	root.add_child(hb)

	var left := UI.panel(UI.PANEL, 16)
	left.custom_minimum_size = Vector2(300, 0)
	var lv := UI.vbox(6)
	left.add_child(lv)
	lv.add_child(UI.center(UI.label("SEU TÉCNICO", 13, UI.MUTED, true)))
	var av := CoachAvatar.new()
	av.coach = coach
	av.custom_minimum_size = Vector2(220, 260)
	UI.vexpand(av)
	lv.add_child(av)
	var name_l := UI.center(UI.label(coach["name"], 20, UI.TXT, true))
	lv.add_child(name_l)
	lv.add_child(UI.center(UI.label("%d anos • %s" % [coach["age"], coach["nat"]], 14, UI.MUTED)))
	hb.add_child(left)

	var right := UI.panel(UI.PANEL, 18)
	UI.expand(right)
	var rv := UI.vbox(14)
	right.add_child(rv)
	var tabs := UI.hbox(8)
	tabs.add_child(UI.fixed(UI.button("Identidade", "gold" if coach_tab == 0 else "dark", _tab.bind(0)), 170))
	tabs.add_child(UI.fixed(UI.button("Aparência", "gold" if coach_tab == 1 else "dark", _tab.bind(1)), 170))
	rv.add_child(tabs)
	if coach_tab == 0:
		var le := LineEdit.new()
		le.text = coach["name"]
		le.max_length = 22
		le.custom_minimum_size = Vector2(320, 46)
		le.add_theme_font_size_override("font_size", 19)
		le.add_theme_stylebox_override("normal", UI.sbox(UI.PANEL2, 8, 10))
		le.add_theme_stylebox_override("focus", UI.sbox(UI.PANEL2, 8, 10, UI.GOLD, 2))
		le.text_changed.connect(func(t: String):
			coach["name"] = t.strip_edges() if t.strip_edges() != "" else "Novo técnico"
			name_l.text = coach["name"])
		var r1 := UI.hbox(24)
		r1.add_child(UI.field("Nome", le))
		r1.add_child(UI.field("Idade", UI.stepper("%d anos" % coach["age"], _step.bind("age", -1, 25, 75), _step.bind("age", 1, 25, 75))))
		rv.add_child(r1)
		var ni: int = Game.COACH_NATS.find(coach["nat"])
		rv.add_child(UI.field("Nacionalidade", UI.fixed(UI.button(str(coach["nat"]) + "  ›", "dark", func():
			coach["nat"] = Game.COACH_NATS[(ni + 1) % Game.COACH_NATS.size()]
			m.refresh()), 320)))
		rv.add_child(UI.field("Reputação inicial", UI.stepper("%.1f / 10" % coach["rep"], _stepf.bind(-0.5), _stepf.bind(0.5))))
	else:
		var g := UI.grid(2, 18)
		g.add_child(UI.field("Tom de pele", _cycle("Tom %d" % (int(coach["skin"]) + 1), "skin", CoachAvatar.SKINS.size())))
		g.add_child(UI.field("Cabelo", _cycle(CoachAvatar.HAIR_NAMES[coach["hair"]], "hair", CoachAvatar.HAIR_NAMES.size())))
		g.add_child(UI.field("Barba", _cycle(CoachAvatar.BEARD_NAMES[coach["beard"]], "beard", CoachAvatar.BEARD_NAMES.size())))
		g.add_child(UI.field("Cor do cabelo", _cycle(CoachAvatar.HAIR_COLOR_NAMES[coach["haircolor"]], "haircolor", CoachAvatar.HAIR_COLOR_NAMES.size())))
		g.add_child(UI.field("Vestimenta", _cycle(CoachAvatar.SUIT_NAMES[coach["suit"]], "suit", CoachAvatar.SUIT_NAMES.size())))
		rv.add_child(g)
	rv.add_child(UI.spacer())
	var bh := UI.hbox()
	bh.add_child(UI.spacer())
	bh.add_child(UI.fixed(UI.button("Escolher clube  ›", "gold", func(): m.go("clubs")), 260))
	rv.add_child(bh)
	hb.add_child(right)


func _tab(t: int) -> void:
	coach_tab = t
	m.refresh()


func _step(key: String, d: int, lo: int, hi: int) -> void:
	coach[key] = clampi(int(coach[key]) + d, lo, hi)
	m.refresh()


func _stepf(d: float) -> void:
	coach["rep"] = clampf(float(coach["rep"]) + d, 1.0, 10.0)
	m.refresh()


func _cycle(text: String, key: String, count: int) -> Button:
	var b := UI.button(text + "  ›", "dark", func():
		coach[key] = (int(coach[key]) + 1) % count
		m.refresh())
	b.custom_minimum_size = Vector2(280, 46)
	return b


# ------------------------------------------------------------ clube
func clubs(root: Control, _arg) -> void:
	var lg: Dictionary = World.LEAGUES[sel_league]
	var infos: Array = lg["clubs"]
	m.head("Nova carreira", "Escolha a liga e o clube que você vai comandar")
	var v := UI.vbox(10)
	root.add_child(v)
	var lh := UI.hbox(10)
	lh.add_child(UI.fixed(UI.button("‹", "dark", _league.bind(-1), 22, 44), 56))
	var lv := UI.vbox(0)
	UI.expand(lv)
	var lt := UI.hbox(10)
	lt.alignment = BoxContainer.ALIGNMENT_CENTER
	var clogo := DataPack.comp_logo_by_id(DataPack.comp_id(sel_league))
	if clogo != null:
		var tr := TextureRect.new()
		tr.texture = clogo
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(34, 34)
		lt.add_child(tr)
	lt.add_child(UI.label(DataPack.comp_name(sel_league, lg["name"]), 22, UI.GOLD, true))
	lv.add_child(lt)
	lv.add_child(UI.center(UI.label("%s • %d clubes • liga %d de %d" % [lg["country"], infos.size(), sel_league + 1, World.LEAGUES.size()], 13, UI.MUTED)))
	lh.add_child(lv)
	lh.add_child(UI.fixed(UI.button("›", "dark", _league.bind(1), 22, 44), 56))
	v.add_child(lh)
	var sc := UI.scroll()
	v.add_child(sc)
	var g := UI.grid(4, 8)
	UI.expand(g)
	sc.add_child(g)
	for c in infos.size():
		var info: Array = infos[c]
		var h := UI.hbox(10)
		h.add_child(Crest.make_raw(info[1], info[2], info[3], 42, sel_league, c))
		var tv := UI.vbox(0)
		var nl := UI.label(DataPack.club_name(sel_league, c, info[0]), 17, UI.TXT, true)
		nl.clip_text = true
		tv.add_child(nl)
		UI.expand(tv)
		tv.add_child(UI.label("Força %d • Caixa %s" % [info[4], Game.money((float(info[4]) - 58.0) * 2.0)], 12, UI.MUTED))
		h.add_child(tv)
		var b := UI.row_button(h, _pick.bind(c), 64, "gold" if c == sel_club else "flat")
		if c == sel_club:
			for l in tv.get_children():
				l.add_theme_color_override("font_color", UI.DARKTXT)
		UI.expand(b)
		g.add_child(b)
	var bh := UI.hbox(12)
	var txt := "Toque em um clube para escolher"
	if sel_club >= 0:
		txt = "Selecionado: %s" % DataPack.club_name(sel_league, sel_club, infos[sel_club][0])
	bh.add_child(UI.expand(UI.label(txt, 17, UI.MUTED)))
	var go_b := UI.button("Começar carreira  ›", "gold", _start)
	go_b.custom_minimum_size = Vector2(280, 50)
	go_b.disabled = sel_club < 0
	bh.add_child(go_b)
	v.add_child(bh)


func _league(d: int) -> void:
	sel_league = posmod(sel_league + d, World.LEAGUES.size())
	sel_club = -1
	m.refresh()


func _pick(c: int) -> void:
	sel_club = c
	m.refresh()


func _start() -> void:
	if sel_club < 0:
		return
	Game.new_career(new_slot, coach.duplicate(), sel_club, sel_league)
	m.hub_tab = 0
	m.home()
	m.toast("Bem-vindo ao %s. Seu elenco está no centro de treinamento." % Game.my_club()["name"])


# ------------------------------------------------------------ datapack
func datapack(root: Control, _arg) -> void:
	m.head("Datapack", "Nomes oficiais, escudos, estádios e elencos vindos de um pacote seu")
	var hb := UI.hbox(14)
	root.add_child(hb)
	var lp := UI.panel(UI.PANEL, 18)
	UI.expand(lp, 1.1)
	var lv := UI.vbox(8)
	lp.add_child(lv)
	lv.add_child(UI.card_title("SITUAÇÃO"))
	if DataPack.loaded():
		var d: Dictionary = DataPack.info
		lv.add_child(UI.label("Datapack ativo", 24, UI.GOLD, true))
		if str(d.get("author", "")) != "":
			lv.add_child(UI.label("Autor do pacote: %s" % d["author"], 14, UI.MUTED))
		var lk: Array = DataPack.linked_count()
		var rows := [["Clubes importados", str(d["clubs"].size())],
			["Escudos de clubes", str(d["logos"])],
			["Estádios", str(d["stadiums"].size())],
			["Competições (com %d logos)" % d["comp_logos"], str(d["comps"].size())],
			["Jogadores (nomes)", str(d["n_players"])],
			["Clubes das ligas do jogo ligados ao pacote", "%d de %d" % [lk[0], lk[1]]],
			["Clubes com elenco próprio (elencos.csv)", str(d["rosters"].size())]]
		for r in rows:
			var h := UI.hbox()
			h.add_child(UI.expand(UI.label(r[0], 16)))
			h.add_child(UI.label(r[1], 16, UI.TXT, true))
			lv.add_child(h)
		lv.add_child(UI.wrap(UI.label("Vale para carreiras novas. Carreiras antigas ganham os escudos, mas mantêm os nomes que já tinham.", 13, UI.MUTED)))
	else:
		lv.add_child(UI.label("Nenhum datapack importado", 24, UI.TXT, true))
		lv.add_child(UI.wrap(UI.label("O jogo está usando escudos desenhados e nomes padrão.", 15, UI.MUTED)))
	lv.add_child(UI.spacer())
	var src := DataPack.find_source()
	var ib := UI.button("Importar datapack.zip" if src != "" else "datapack.zip não encontrado", "gold", func(): _import(DataPack.find_source()), 18, 50)
	ib.disabled = src == ""
	lv.add_child(ib)
	var bh := UI.hbox(8)
	bh.add_child(UI.expand(UI.button("Escolher arquivo…", "dark", _pick_file)))
	if DataPack.loaded():
		bh.add_child(UI.expand(UI.button("Ver banco de dados", "blue", func(): m.go("dp_browse"))))
		bh.add_child(UI.expand(UI.button("Remover datapack", "red", func():
			DataPack.remove()
			m.refresh()
			m.toast("Datapack removido."))))
	lv.add_child(bh)
	hb.add_child(lp)

	var rp := UI.panel(UI.PANEL, 18)
	UI.expand(rp, 1.0)
	var rv := UI.vbox(8)
	rp.add_child(rv)
	rv.add_child(UI.card_title("COMO USAR"))
	for t in ["1. Copie o arquivo do datapack para a pasta do projeto e renomeie para datapack.zip (ou use \"Escolher arquivo\").",
			"2. Toque em Importar. Entra tudo: clubes, escudos, estádios, competições e jogadores. O jogo liga sozinho os clubes do pacote aos das ligas.",
			"3. Crie uma carreira nova: ela já nasce com os nomes, escudos e estádios do pacote."]:
		rv.add_child(UI.wrap(UI.label(t, 15)))
	rv.add_child(UI.card_title("ELENCOS REAIS (OPCIONAL)"))
	rv.add_child(UI.wrap(UI.label("Pacotes no formato \"id,nome\" não dizem em que clube cada jogador joga. Para ter elencos reais, coloque dentro do zip um arquivo elencos.csv com uma linha por jogador:", 14, UI.MUTED)))
	rv.add_child(UI.label("Clube;Jogador;Posição;Idade;Nota;País", 15, UI.GOLD, true))
	rv.add_child(UI.label("Flamengo;Nome do Jogador;AC;27;84;BRA", 14, UI.TXT))
	rv.add_child(UI.wrap(UI.label("Posições: GOL ZAG LD LE VOL MEI PD PE AC. Clube com 11 ou mais linhas usa o seu elenco; o que faltar o jogo completa.", 13, UI.MUTED)))
	hb.add_child(rp)


func _import(path: String) -> void:
	if path == "":
		return
	m.toast("Importando o datapack… pode levar até 1 minuto.")
	await m.get_tree().process_frame
	await m.get_tree().process_frame
	await m.get_tree().process_frame
	var res := DataPack.import_zip(path)
	m.refresh()
	if res == "":
		m.toast("Datapack importado: %d clubes, %d escudos, %d jogadores." % [DataPack.info["clubs"].size(), DataPack.info["logos"], DataPack.info["n_players"]])
	else:
		m.toast(res)


func _pick_file() -> void:
	var fd := FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = true
	fd.filters = PackedStringArray(["*.zip ; Datapack"])
	fd.title = "Escolha o datapack (.zip)"
	fd.file_selected.connect(func(p: String):
		_import(p)
		fd.queue_free())
	fd.canceled.connect(fd.queue_free)
	m.add_child(fd)
	fd.popup_centered(Vector2i(900, 560))


# ------------------------------------------------------------ banco de dados do datapack
func dp_browse(root: Control, _arg) -> void:
	m.head("Banco de dados do datapack", "Tudo o que foi importado do pacote")
	var v := UI.vbox(8)
	root.add_child(v)
	var top := UI.hbox(8)
	var names := ["Clubes", "Competições", "Jogadores"]
	for i in names.size():
		top.add_child(UI.fixed(UI.button(names[i], "gold" if i == dp_tab else "dark", func():
			dp_tab = i
			m.refresh(), 16, 42), 170))
	var le := LineEdit.new()
	le.text = dp_query
	le.placeholder_text = "Buscar pelo nome e apertar Enter"
	le.custom_minimum_size = Vector2(0, 42)
	le.add_theme_font_size_override("font_size", 17)
	le.add_theme_stylebox_override("normal", UI.sbox(UI.PANEL2, 8, 10))
	le.add_theme_stylebox_override("focus", UI.sbox(UI.PANEL2, 8, 10, UI.GOLD, 2))
	le.text_submitted.connect(func(t: String):
		dp_query = t.strip_edges()
		m.refresh())
	top.add_child(UI.expand(le))
	v.add_child(top)
	var sc := UI.scroll()
	v.add_child(sc)
	var g := UI.grid(3, 6)
	UI.expand(g)
	sc.add_child(g)
	var q := DataPack.norm(dp_query)
	var shown := 0
	var total := 0
	var d: Dictionary = DataPack.info
	if dp_tab == 2:
		var pl := DataPack.players()
		total = pl.size()
		for nm in pl:
			if q != "" and not DataPack.norm(nm).contains(q):
				continue
			if shown >= 90:
				break
			var p := UI.panel(Color(1, 1, 1, 0.05), 8, 6)
			UI.expand(p)
			p.add_child(UI.label(nm, 15))
			g.add_child(p)
			shown += 1
	else:
		var table: Dictionary = d["clubs"] if dp_tab == 0 else d["comps"]
		total = table.size()
		var ids: Array = table.keys()
		ids.sort()
		for id in ids:
			var nm2: String = table[id]
			if q != "" and not DataPack.norm(nm2).contains(q):
				continue
			if shown >= 60:
				break
			var p2 := UI.panel(Color(1, 1, 1, 0.05), 8, 6)
			UI.expand(p2)
			var h := UI.hbox(8)
			p2.add_child(h)
			var tex: Texture2D = DataPack.logo_by_id(id) if dp_tab == 0 else DataPack.comp_logo_by_id(id)
			var tr := TextureRect.new()
			tr.texture = tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(34, 34)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(tr)
			var tv := UI.vbox(0)
			UI.expand(tv)
			var nl := UI.label(nm2, 15, UI.TXT, true)
			nl.clip_text = true
			tv.add_child(nl)
			var sub := "ID %d" % id
			if dp_tab == 0 and d["stadiums"].has(id):
				sub += " • " + str(d["stadiums"][id])
			var sl := UI.label(sub, 11, UI.MUTED)
			sl.clip_text = true
			tv.add_child(sl)
			h.add_child(tv)
			g.add_child(p2)
			shown += 1
	v.add_child(UI.label("Mostrando %d de %d. Use a busca para achar o resto." % [shown, total], 13, UI.MUTED))
