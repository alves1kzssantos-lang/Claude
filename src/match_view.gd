extends Control
# Central da partida: pré-jogo, jogo ao vivo (com GOOOL!) e fim.

const SPEEDS := [0.5, 1.2, 3.0]      # minutos de jogo por segundo (campo ao vivo)
const SPEED_NAMES := ["1×", "2×", "6×"]

var m
var sim: MatchSim
var state: String = "pre"   # pre / live / done
var my_side: int = 0
var speed: int = 1
var paused: bool = false
var acc: float = 0.0
var goal_t: float = 0.0
var sub_out: int = -1
var lances: bool = true      # jogar os lances em campo
var lance: LanceView = null
var field: FieldView = null     ## partida ao vivo no campo inteiro
var _lists_sig: String = ""   ## evita remontar as listas de jogadores todo minuto
var pro: bool = false         ## modo carreira de jogador: só os lances do seu jogador
var me_id: int = -1
var mt_info: Dictionary = {}    ## competição e fase (para a abertura com a logo)

var score_l: Label
var status_l: Label
var info_l: Array = [null, null]
var lists: Array = [null, null]
var pitch: PitchView
var poss_l: Label
var poss_bar: ProgressBar
var comment_l: Label
var controls: HBoxContainer
var goal_layer: Control
var goal_min: Label
var goal_name: Label
var goal_club: Label


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mt: Dictionary = Game.next_user_match()
	mt_info = mt
	sim = MatchSim.new(mt["h"], mt["a"])
	my_side = 0 if mt["h"] == Game.S["club"] else 1
	var hc: Dictionary = Game.club(mt["h"])
	var std: String = DataPack.stadium(int(hc.get("li", Game.S.get("league", 0))), int(hc.get("ci", mt["h"])))
	if mt["kind"] == "trial":
		std = "Campo da comunidade • olheiros na arquibancada"
	pro = Pro.is_pro()
	if pro:
		me_id = int(Pro.P()["me"])
		std = "%s • você: %s" % [std if std != "" else "", Pro.status_line()]
	m.head("Central da partida", "%s • %s • %s" % [mt["comp"], mt["label"], std if std != "" else "confira as escalações"])
	_build()
	_update()


func _team_panel(side: int) -> Control:
	var p := UI.panel(UI.PANEL, 10)
	UI.expand(p)
	var h := UI.hbox(10)
	p.add_child(h)
	var v := UI.vbox(0)
	UI.expand(v)
	var nm := UI.label(Game.club_name(sim.cid(side)), 21, UI.TXT, true)
	var tg := UI.label("MANDANTE" if side == 0 else "VISITANTE", 11, UI.MUTED, true)
	var inf := UI.label("", 13, UI.MUTED)
	inf.clip_text = true
	info_l[side] = inf
	if side == 1:
		for l in [nm, tg, inf]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(nm)
	v.add_child(tg)
	v.add_child(inf)
	if side == 0:
		h.add_child(Crest.make(sim.cid(side), 52))
		h.add_child(v)
	else:
		h.add_child(v)
		h.add_child(Crest.make(sim.cid(side), 52))
	return p


func _build() -> void:
	var v := UI.vbox(8)
	add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var top := UI.hbox(12)
	top.add_child(_team_panel(0))
	var sv := UI.vbox(0)
	sv.custom_minimum_size = Vector2(200, 0)
	score_l = UI.center(UI.label("0 : 0", 40, UI.TXT, true))
	status_l = UI.center(UI.label("PRÉ-JOGO", 13, UI.MUTED, true))
	sv.add_child(score_l)
	sv.add_child(status_l)
	top.add_child(sv)
	top.add_child(_team_panel(1))
	v.add_child(top)

	var mid := UI.hbox(12)
	UI.vexpand(mid)
	v.add_child(mid)
	for side in 2:
		var lp := UI.panel(UI.PANEL, 10)
		lp.custom_minimum_size = Vector2(250, 0)
		var lv := UI.vbox(1)
		lp.add_child(lv)
		lists[side] = lv
		if side == 0:
			mid.add_child(lp)
			var cv := UI.vbox(6)
			UI.expand(cv)
			pitch = PitchView.new()
			pitch.mode = "match"
			pitch.sim = sim
			pitch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UI.vexpand(pitch)
			cv.add_child(pitch)
			var ph := UI.hbox()
			ph.add_child(UI.expand(UI.label("POSSE DE BOLA", 12, UI.MUTED, true)))
			poss_l = UI.label("50% / 50%", 14, UI.TXT, true)
			ph.add_child(poss_l)
			cv.add_child(ph)
			poss_bar = UI.bar(0.5, Color("5aa2f2"), 5)
			poss_bar.add_theme_stylebox_override("background", UI.sbox(Color("f0a05e"), 3))
			cv.add_child(poss_bar)
			var cp := UI.panel(Color(1, 1, 1, 0.06), 10, 8)
			cp.custom_minimum_size = Vector2(0, 62)
			comment_l = UI.wrap(UI.label("Relatório do auxiliar: time pronto para entrar em campo.", 15))
			cp.add_child(comment_l)
			cv.add_child(cp)
			mid.add_child(cv)
		else:
			mid.add_child(lp)

	controls = UI.hbox(10)
	v.add_child(controls)

	# camada do GOOOL!
	goal_layer = ColorRect.new()
	goal_layer.color = Color(0.02, 0.07, 0.05, 0.9)
	goal_layer.visible = false
	add_child(goal_layer)
	goal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gv := UI.vbox(6)
	gv.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_layer.add_child(gv)
	gv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gv.add_child(UI.center(UI.label("GOOOL!", 56, UI.GOLD, true)))
	var ball := Control.new()
	ball.custom_minimum_size = Vector2(120, 120)
	ball.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ball.draw.connect(func():
		var c := Vector2(60, 60)
		ball.draw_circle(c, 56, Color("f4f6fa"))
		ball.draw_circle(c, 17, Color("1a1f2c"))
		for i in 5:
			var ang := -PI / 2 + TAU * i / 5.0
			ball.draw_circle(c + Vector2(cos(ang), sin(ang)) * 43, 12, Color("1a1f2c")))
	gv.add_child(ball)
	goal_min = UI.center(UI.label("", 22, Color("8fc0ff"), true))
	goal_name = UI.center(UI.label("", 32, UI.TXT, true))
	goal_club = UI.center(UI.label("", 16, UI.MUTED))
	gv.add_child(goal_min)
	gv.add_child(goal_name)
	gv.add_child(goal_club)
	_build_controls()


func _build_controls() -> void:
	UI.clear(controls)
	if state == "pre":
		if not pro:
			controls.add_child(UI.fixed(UI.button("Escalar meu time", "dark", func(): m.go("lineup")), 250))
		controls.add_child(UI.expand(UI.button("INICIAR PARTIDA", "blue", _start, 19, 50)))
		controls.add_child(UI.fixed(UI.button("Simular", "dark", _to_end), 250))
	elif state == "live":
		if not pro:
			controls.add_child(UI.fixed(UI.button("Substituições (%d/5)" % sim.subs[my_side], "dark", _open_subs), 240))
		controls.add_child(UI.expand(UI.button("Continuar" if paused else "Pausar", "dark", func():
			paused = not paused
			_build_controls())))
		controls.add_child(UI.fixed(UI.button("Lances: %s" % ("SIM" if lances else "NÃO"), "blue" if lances else "dark", func():
			lances = not lances
			sim.interactive = lances
			_build_controls()), 170))
		controls.add_child(UI.fixed(UI.button(SPEED_NAMES[speed], "dark", func():
			speed = (speed + 1) % SPEEDS.size()
			_build_controls()), 90))
		controls.add_child(UI.expand(UI.button("Ir ao fim  »", "dark", _to_end)))
	else:
		controls.add_child(UI.spacer())
		controls.add_child(UI.fixed(UI.button("Continuar  ›", "gold", _finish, 19, 50), 380))
		controls.add_child(UI.spacer())


func _start() -> void:
	# abertura: logo do campeonato animada, depois a bola rola
	state = "intro"
	UI.clear(controls)
	var it := CompIntro.new()
	it.title = str(mt_info.get("comp", Game.LEAGUE))
	it.sub = str(mt_info.get("label", ""))
	it.tex = CompIntro.logo_for(mt_info)
	it.h = sim.h
	it.a = sim.a
	m.overlay.add_child(it)
	it.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	it.done.connect(_kickoff)


## Placas do datapack para este jogo (Libertadores tem as dela; senão, as do país do mandante).
func _ads() -> Array:
	var cup_name := ""
	if mt_info.get("kind", "") == "cup":
		cup_name = str(mt_info.get("comp", ""))
	var hc: Dictionary = Game.club(sim.h)
	var li: int = int(hc.get("li", Game.S.get("league", 0)))
	return DataPack.adboards_for(cup_name, str(World.LEAGUES[li]["country"]))


func _kickoff() -> void:
	state = "live"
	sim.interactive = lances
	m.head("Central da partida", "%s • Transmissão acelerada" % Game.LEAGUE, false)
	_build_controls()
	_open_field()


## Partida ao vivo: o campo inteiro cobre a tela até o fim do jogo.
func _open_field() -> void:
	field = FieldView.new()
	field.setup_field(sim)
	field.me_pid = me_id
	field.stage_label = str(mt_info.get("label", ""))
	field.ads = _ads()
	m.overlay.add_child(field)
	m.overlay.move_child(field, 0)
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field.pause_pressed.connect(_on_pause)


func _close_field() -> void:
	if field != null and is_instance_valid(field):
		field.queue_free()
	field = null


func _on_pause() -> void:
	if paused:
		paused = false
		field.paused_view = false
		m.close_modal()
		return
	paused = true
	field.paused_view = true
	_pause_menu()


## Menu de pausa (como nos jogos de futebol de celular).
func _pause_menu() -> void:
	var p := UI.panel(UI.PANEL, 22)
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(UI.center(UI.label("PARTIDA PAUSADA • %d'" % sim.minute, 22, UI.GOLD, true)))
	v.add_child(UI.center(UI.label("%s %d × %d %s" % [Game.club_name(sim.h), sim.score[0], sim.score[1], Game.club_name(sim.a)], 18, UI.TXT, true)))
	v.add_child(UI.button("Continuar", "gold", _on_pause, 19, 52))
	if not pro:
		v.add_child(UI.button("Substituições (%d/5)" % sim.subs[my_side], "dark", _open_subs))
	var row := UI.hbox(10)
	row.add_child(UI.expand(UI.button("Velocidade: %s" % SPEED_NAMES[speed], "dark", func():
		speed = (speed + 1) % SPEEDS.size()
		_pause_menu())))
	row.add_child(UI.expand(UI.button("Lances: %s" % ("SIM" if lances else "NÃO"), "blue" if lances else "dark", func():
		lances = not lances
		sim.interactive = lances
		_pause_menu())))
	v.add_child(row)
	v.add_child(UI.button("Ir ao fim  »", "dark", func():
		m.close_modal()
		_to_end()))
	v.add_child(UI.spacer())
	m.modal(p)


func _to_end() -> void:
	if state == "pre":
		m.head("Central da partida", "%s • Transmissão acelerada" % Game.LEAGUE, false)
	sim.interactive = false
	_close_field()
	paused = false
	while not sim.finished:
		sim.step()
	goal_layer.visible = false
	goal_t = 0.0
	state = "done"
	comment_l.text = "Fim de jogo!"
	_update()
	_build_controls()


func _finish() -> void:
	if pro:
		Game.play_next(sim)
		m.replace("pro_post")
		return
	Game.play_next(sim)
	m.replace("postmatch", Game.S["last_user"])


func _process(delta: float) -> void:
	if state != "live" or lance != null:
		return
	if goal_t > 0.0:
		goal_t -= delta
		if goal_t <= 0.0:
			goal_layer.visible = false
		return
	if paused:
		return
	acc += delta * SPEEDS[speed]
	while acc >= 1.0 and state == "live":
		acc -= 1.0
		var stop := false
		for e in sim.step():
			if e["type"] == "lance":
				_play_lance(e)
				stop = true
			else:
				stop = _show_event(e) or stop
		if field != null:
			field.feed_minute(sim.last_side)
		if sim.finished and lance == null:
			_end_live()
		_update()
		if stop:
			acc = 0.0
			break


func _end_live() -> void:
	_close_field()
	paused = false
	state = "done"
	comment_l.text = "Fim de jogo!"
	_build_controls()


func _show_event(e: Dictionary) -> bool:
	comment_l.text = "%d'  %s" % [e["min"], e["text"]]
	if e["type"] == "card":
		_lists_sig = ""   # expulsão muda a lista de jogadores em campo
		if field != null:
			field.show_banner(e["text"], 1.6)
			if e.get("red", false):
				field.rebuild_teams()
		return false
	if e["type"] == "sub":
		_lists_sig = ""
		if field != null:
			field.rebuild_teams()
			field.show_banner(e["text"], 1.8)
		return false
	if e["type"] == "chance" and field != null:
		field.show_chance(e["side"])
		return false
	if e["type"] != "goal":
		return false
	if field != null:
		field.show_banner("GOOOL!  %s  %d'" % [e["name"], e["min"]], 1.8, true)
		field.celebrate(str(e["name"]), int(e["side"]))
		field.kickoff(1 - e["side"])
		goal_t = 2.4 if speed < 2 else 1.5
		return true
	goal_min.text = "%d'" % e["min"]
	goal_name.text = e["name"]
	goal_club.text = Game.club_name(sim.cid(e["side"]))
	goal_layer.visible = true
	goal_t = 1.6 if speed < 2 else 0.9
	return true


# abre o lance em campo (tela cheia). No seu ataque, você joga.
func _play_lance(e: Dictionary) -> void:
	if field != null:
		field.visible = false
	lance = LanceView.new()
	lance.me_pid = me_id
	lance.stage_label = str(mt_info.get("label", ""))
	lance.ads = _ads()
	lance.setup(sim, e["side"], e["side"] == my_side)
	m.overlay.add_child(lance)
	lance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lance.finished.connect(_lance_done)


func _lance_done(res: Dictionary) -> void:
	if lance != null:
		lance.queue_free()
		lance = null
	var e: Dictionary = sim.resolve_lance(res)
	if field != null:
		field.visible = true
		field.rebuild_teams()
		if not res.get("goal", false):
			field.keeper_ball(1 - int(e["side"]))
	_show_event(e)
	if sim.finished:
		_end_live()
	_update()


func _exit_tree() -> void:
	if lance != null and is_instance_valid(lance):
		lance.queue_free()
	_close_field()


func _update() -> void:
	score_l.text = "%d : %d" % [sim.score[0], sim.score[1]]
	if state == "pre":
		status_l.text = "PRÉ-JOGO"
	elif state == "done":
		status_l.text = "FIM DE JOGO"
	else:
		status_l.text = "%d'" % sim.minute
	var ph: int = sim.possession(0)
	poss_l.text = "%d%% / %d%%" % [ph, 100 - ph]
	poss_bar.value = ph / 100.0
	for side in 2:
		var txt := ""
		for s in sim.scorers:
			if s["side"] == side:
				txt += "%s %d'  " % [s["name"], s["min"]]
		if txt == "":
			var r: Dictionary = sim.r[side]
			txt = "DEF %d  MEI %d  ATQ %d  GER %d" % [r["def"], r["mei"], r["atq"], r["ger"]]
		if sim.reds[side] > 0:
			txt += "  •  %d expulso(s)" % sim.reds[side]
		info_l[side].text = txt
	# as listas só mudam com substituição, cartão ou expulsão
	var sig := "%s|%s|%s|%s" % [Game.club(sim.h)["xi"], Game.club(sim.a)["xi"], sim.sent_off, sim.cards]
	if sig != _lists_sig:
		_lists_sig = sig
		_rebuild_lists()
	pitch.queue_redraw()


func _rebuild_lists() -> void:
	for side in 2:
		var lv: VBoxContainer = lists[side]
		UI.clear(lv)
		var c: Dictionary = Game.club(sim.cid(side))
		lv.add_child(UI.center(UI.label("ESCALAÇÃO • %s" % c["formation"], 12, UI.MUTED, true)))
		var slots: Array = Game.FORMATIONS[c["formation"]]
		for i in c["xi"].size():
			var pid: int = c["xi"][i]
			var p: Dictionary = Game.player(pid)
			var off: bool = sim.is_out_of_play(pid)
			var h := UI.hbox(6)
			h.add_child(UI.col(slots[i][0], 36, 11, UI.pos_color(slots[i][0]), true, HORIZONTAL_ALIGNMENT_LEFT))
			var nl := UI.label(p["name"], 14, UI.MUTED if off else UI.TXT)
			nl.clip_text = true
			h.add_child(UI.expand(nl))
			if off or int(sim.cards.get(pid, 0)) > 0:
				var card := ColorRect.new()
				card.color = Color("d7263d") if off else Color("f2d21f")
				card.custom_minimum_size = Vector2(9, 13)
				card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				card.mouse_filter = Control.MOUSE_FILTER_IGNORE
				h.add_child(card)
			h.add_child(UI.label(str(p["ovr"]), 14, UI.GOLD, true))
			UI.vexpand(h)
			lv.add_child(h)


# ------------------------------------------------------------ substituições
func _open_subs() -> void:
	paused = true
	_build_controls()
	sub_out = -1
	_subs_modal()


func _subs_modal() -> void:
	var cid: int = sim.cid(my_side)
	var c: Dictionary = Game.club(cid)
	var slots: Array = Game.FORMATIONS[c["formation"]]
	var p := UI.panel(UI.PANEL, 18)
	var v := UI.vbox(10)
	p.add_child(v)
	var th := UI.hbox()
	th.add_child(UI.expand(UI.label("Substituições (%d/5)" % sim.subs[my_side], 22, UI.TXT, true)))
	th.add_child(UI.fixed(UI.button("Fechar", "dark", func(): m.close_modal(), 16, 40), 130))
	v.add_child(th)
	v.add_child(UI.label("1) toque em quem SAI   2) toque em quem ENTRA", 14, UI.MUTED))
	var hb := UI.hbox(14)
	UI.vexpand(hb)
	v.add_child(hb)
	for col in 2:
		var cv := UI.vbox(4)
		UI.expand(cv)
		cv.add_child(UI.label("EM CAMPO" if col == 0 else "RESERVAS", 13, UI.GOLD, true))
		var sc := UI.scroll()
		cv.add_child(sc)
		var lv := UI.vbox(3)
		UI.expand(lv)
		sc.add_child(lv)
		if col == 0:
			for i in c["xi"].size():
				var pl: Dictionary = Game.player(c["xi"][i])
				lv.add_child(_sub_row(pl, slots[i][0], func():
					sub_out = i
					_subs_modal(), i == sub_out))
		else:
			for pl in Game.bench(cid):
				if pl["id"] in sim.out:
					continue
				lv.add_child(_sub_row(pl, pl["pos"], _sub_in.bind(pl["id"]), false))
		hb.add_child(cv)
	m.modal(p)


func _sub_row(pl: Dictionary, pos: String, cb: Callable, selected: bool) -> Button:
	var h := UI.hbox(8)
	h.add_child(UI.pos_tag(pos, 12))
	var nl := UI.label(pl["name"], 15, UI.DARKTXT if selected else UI.TXT, true)
	nl.clip_text = true
	h.add_child(UI.expand(nl))
	h.add_child(UI.label("%d%%" % int(pl["energy"]), 13, UI.DARKTXT if selected else UI.MUTED))
	h.add_child(UI.label(str(pl["ovr"]), 16, UI.DARKTXT if selected else UI.GOLD, true))
	return UI.row_button(h, cb, 40, "gold" if selected else "flat", 8)


func _sub_in(pid: int) -> void:
	if sub_out < 0:
		m.toast("Escolha primeiro quem sai.")
		return
	var out_name: String = Game.player(Game.club(sim.cid(my_side))["xi"][sub_out])["name"]
	var res := sim.substitute(my_side, sub_out, pid)
	if res != "":
		m.toast(res)
		return
	comment_l.text = "%d'  Substituição: sai %s, entra %s." % [sim.minute, out_name, Game.player(pid)["name"]]
	sub_out = -1
	m.close_modal()
	if field != null:
		field.rebuild_teams()
	_update()
	_build_controls()
