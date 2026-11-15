class_name FieldView
extends LanceView
## A partida inteira em campo: os 22 jogadores, a bola e a câmera seguindo a jogada.
## O resultado continua vindo da simulação (MatchSim); aqui a tela só mostra o jogo
## acontecendo e obedece à simulação (quem está com a bola, chances, gols).
## Reaproveita os bonecos, a bola, o gol, o placar e a física do LanceView.
##
## Campo: x = largura (-34 a 34), y = comprimento (0 a 105).
## O mandante (lado 0) ataca o gol de baixo (y = 0); o visitante ataca o de cima (y = 105).
##
## Estados da bola: "dribble" (alguém conduz), "pass" (passe no ar/chão),
## "shot" (finalização que a simulação já sabe que não é gol), "loose" (dividida).

signal pause_pressed

const LENGTH := 105.0
const HALF_W := 34.0
const OWN_GOAL := [LENGTH, 0.0]    ## gol que cada lado defende
const FWD := [-1.0, 1.0]           ## direção de ataque de cada lado (em y)

var teams: Array = [[], []]        ## entidades de cada time (o goleiro tem "keeper" = true)
var want_side: int = 0             ## quem a simulação diz que está com a bola
var owner_side: int = 0
var holder: int = -1                ## índice do jogador com a bola no time owner_side (-1 = ninguém)
var ball_state: String = "dribble"
var pass_target: int = -1
var next_pass: float = 1.2
var cam_x: float = 0.0
var paused_view: bool = false      ## só para desenhar o botão de pausa como "continuar"
var banner_gold: bool = false
var steal_t: float = 0.0
var recent: Array = []             ## lados com a bola nos últimos minutos da simulação
var _teams_all: Array = []         ## os dois times juntos (cache para separar os jogadores)
var _fl_lines := PackedVector2Array()   ## linhas retas do campo inteiro, em metros (montadas uma vez)


func _init() -> void:
	y_sign = -1.0   # aqui o y do mundo cresce para cima na tela (o mandante ataca o gol de baixo)


## Recebe quem ficou com a bola no minuto da simulação. A posse na tela só troca
## quando o outro time domina dois minutos seguidos (evita trocar a cada segundo).
func feed_minute(sd: int) -> void:
	recent.append(sd)
	if recent.size() > 2:
		recent.pop_front()
	if recent.size() == 2 and recent[0] == recent[1]:
		want_side = sd


## Monta o campo a partir da simulação da partida.
func setup_field(sim_: MatchSim) -> void:
	sim = sim_
	ref = Referee.new(Game.rng)
	bp = BallPhysics.new()
	state = "field"
	user_ctrl = false
	var hc: Dictionary = Game.club(sim.h)
	var ac: Dictionary = Game.club(sim.a)
	var hm := Color(str(hc["c1"]))
	var am := Color(str(ac["c1"]))
	var at := Color(str(ac["c2"]))
	if _close(hm, am):
		am = Color(str(ac["c2"]))
		at = Color(str(ac["c1"]))
		if _close(hm, am):
			am = Color("f0a419")
	var lg: Array = World.LEAGUES[int(Game.S.get("league", 0))]["clubs"]
	kits = [[hm, Color(str(hc["c2"])), striped(hc)],
		[am, at, striped(ac) and am == Color(str(ac["c1"]))]]
	rebuild_teams()
	referee = {"p": {"id": 3}, "pos": Vector2(10, 50), "num": 0, "ph": 0.0, "moving": false, "dir": Vector2(0, -1),
		"face": 1.0, "skin": SKINS[1], "hair": HAIRS[0]}
	kickoff(1)
	cam_y = 52.5 - 10.0


## (Re)monta os dois times com a escalação atual (depois de substituição ou expulsão).
func rebuild_teams() -> void:
	var old := [{}, {}]
	for sd in 2:
		for e in teams[sd]:
			old[sd][e["p"]["id"]] = e["pos"]
	teams = [[], []]
	for sd in 2:
		var c: Dictionary = Game.club(sim.cid(sd))
		var slots: Array = Game.FORMATIONS[c["formation"]]
		var nums := _numbers(slots)
		for i in mini(11, c["xi"].size()):
			var pid: int = c["xi"][i]
			if sim.is_out_of_play(pid):
				continue
			var e := _ent(Game.player(pid), Vector2.ZERO, nums[i])
			e["slot"] = slots[i]
			e["keeper"] = slots[i][0] == "GOL"
			e["pos"] = old[sd].get(pid, _home(sd, e, Vector2(0, 52.5)))
			e["face"] = FWD[sd]
			teams[sd].append(e)
	holder = -1 if holder >= teams[owner_side].size() else holder
	_teams_all = teams[0] + teams[1]
	_ro_sig = -1   # refaz a ordem de desenho com as entidades novas


## Posição da formação de um jogador, acompanhando a bola em bloco.
func _home(sd: int, e: Dictionary, ball: Vector2) -> Vector2:
	var sl: Array = e["slot"]
	var g: float = OWN_GOAL[sd]
	var u_ball: float = absf(ball.y - g)
	if e.get("keeper", false):
		var u_gk := clampf(u_ball * 0.06 + 1.4, 1.2, 6.0)
		return Vector2(clampf(ball.x * 0.12, -3.0, 3.0), g + FWD[sd] * u_gk)
	var attacking: bool = owner_side == sd and holder >= 0
	var depth: float = float(sl[2])
	var u: float = depth * 56.0 + 7.0 + (u_ball - 52.5) * 0.55 + (6.0 if attacking else -4.0)
	u = clampf(u, 5.0, 98.0)
	var spread := 1.0 if attacking else 0.82
	var x: float = (float(sl[1]) - 0.5) * 58.0 * spread * (1.0 if sd == 0 else -1.0) + ball.x * 0.3
	return Vector2(clampf(x, -HALF_W + 2.0, HALF_W - 2.0), g + FWD[sd] * u)


## Saída de bola no meio-campo para o lado sd.
func kickoff(sd: int) -> void:
	owner_side = sd
	want_side = sd
	recent = [sd, sd]
	var best := 0
	var bd := 1e9
	for i in teams[sd].size():
		var dd: float = absf(float(teams[sd][i]["slot"][2]) - 0.85)
		if dd < bd and not teams[sd][i].get("keeper", false):
			bd = dd
			best = i
	holder = best
	for s2 in 2:
		for e in teams[s2]:
			e["pos"] = _home(s2, e, Vector2(0, 52.5))
			# ninguém no campo do adversário na saída
			if s2 == 0:
				e["pos"].y = maxf(e["pos"].y, 53.5)
			else:
				e["pos"].y = minf(e["pos"].y, 51.5)
	teams[sd][holder]["pos"] = Vector2(0, 52.5 - FWD[sd] * 0.6)
	bp.place(Vector2(0, 52.5))
	ball_state = "dribble"
	next_pass = 0.9


## Bola com o goleiro de quem defende (depois de chance perdida ou defesa).
func keeper_ball(sd: int) -> void:
	for i in teams[sd].size():
		if teams[sd][i].get("keeper", false):
			owner_side = sd
			want_side = sd
			recent = [sd, sd]
			holder = i
			bp.place(teams[sd][i]["pos"] + Vector2(0, FWD[sd] * 0.5))
			ball_state = "dribble"
			next_pass = 1.0
			return
	kickoff(sd)


## A simulação teve uma chance que não virou gol: mostra um chute de quem ataca.
func show_chance(sd: int) -> void:
	want_side = sd
	recent = [sd, sd]
	if owner_side != sd or holder < 0 or ball_state != "dribble":
		return
	var c: Dictionary = teams[sd][holder]
	var gy: float = OWN_GOAL[1 - sd]
	var miss: float = [-5.5, 5.5, -1.0, 1.0][Game.rng.randi_range(0, 3)]
	var target := Vector2(miss, gy + FWD[sd] * 0.3)
	var d: Vector2 = target - bp.pos
	bp.kick_shot(d, 24.0, 2.2 + Game.rng.randf() * 2.0)
	c["kick"] = 0.32
	ball_state = "shot"
	holder = -1


## Mostra uma faixa no meio da tela (gol, cartão...).
func show_banner(text: String, dur: float, gold: bool = false) -> void:
	banner = text
	banner_t = dur
	banner_gold = gold


func _nearest(sd: int, p: Vector2, skip_keeper: bool = true) -> int:
	var best := -1
	var bd := 1e9
	for i in teams[sd].size():
		if skip_keeper and teams[sd][i].get("keeper", false):
			continue
		var dd: float = teams[sd][i]["pos"].distance_to(p)
		if dd < bd:
			bd = dd
			best = i
	return best


func _pick_pass(sd: int) -> int:
	var c: Dictionary = teams[sd][holder]
	var opts: Array = []
	for i in teams[sd].size():
		if i == holder:
			continue
		var e: Dictionary = teams[sd][i]
		var dist: float = e["pos"].distance_to(c["pos"])
		if dist < 6.0 or dist > 34.0:
			continue
		var fwd_gain: float = (e["pos"].y - c["pos"].y) * FWD[sd]
		var w := 1.0 + clampf(fwd_gain / 10.0, -0.7, 2.0)
		if e.get("keeper", false):
			w *= 0.15
		opts.append([i, w])
	if opts.is_empty():
		return -1
	var tot := 0.0
	for o in opts:
		tot += o[1]
	var x := Game.rng.randf() * tot
	for o in opts:
		x -= o[1]
		if x <= 0.0:
			return o[0]
	return opts[0][0]


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	ad_t += delta
	if cel_t > 0.0:
		cel_t += delta
		if cel_t > 2.4:
			cel_t = 0.0
	if banner_t > 0.0:
		banner_t -= delta
		if banner_t <= 0.0:
			banner = ""
	if paused_view:
		queue_redraw()
		return
	t += delta
	for sd in 2:
		for e in teams[sd]:
			if float(e.get("kick", 0.0)) > 0.0:
				e["kick"] = float(e["kick"]) - delta
	var ball_ref: Vector2 = bp.pos
	# todos se posicionam em bloco
	for sd in 2:
		for i in teams[sd].size():
			var e: Dictionary = teams[sd][i]
			if sd == owner_side and i == holder and ball_state == "dribble":
				continue
			if ball_state == "pass" and sd == owner_side and i == pass_target:
				continue
			var tgt := _home(sd, e, ball_ref)
			_move(e, tgt, _spd(e) * 0.62, delta)
	# quem tem a bola conduz para o ataque
	match ball_state:
		"dribble":
			if holder < 0 or holder >= teams[owner_side].size():
				keeper_ball(owner_side)
			var c: Dictionary = teams[owner_side][holder]
			var goal_y: float = OWN_GOAL[1 - owner_side]
			var tgt2 := Vector2(c["pos"].x * 0.9, c["pos"].y + FWD[owner_side] * 8.0)
			if absf(c["pos"].y - goal_y) < 22.0:
				tgt2 = Vector2(c["pos"].x * 0.6, c["pos"].y)   # perto da área segura e espera a chance
			_move(c, tgt2, _spd(c) * (0.55 if c.get("keeper", false) else 0.72), delta)
			var touch: float = 0.3 + 0.22 * (0.5 + 0.5 * sin(float(c["ph"]) * 0.5))
			bp.place(c["pos"] + c["dir"] * touch)
			next_pass -= delta
			# a simulação mudou a posse: o adversário mais perto vai buscar
			if want_side != owner_side:
				steal_t += delta
				var o := _nearest(want_side, bp.pos)
				if o >= 0:
					var oe: Dictionary = teams[want_side][o]
					_move(oe, bp.pos, _spd(oe) * 1.05, delta)
					if oe["pos"].distance_to(bp.pos) < 1.2 or steal_t > 2.5:
						oe["kick"] = 0.25
						owner_side = want_side
						holder = o
						steal_t = 0.0
						next_pass = 0.8
			elif next_pass <= 0.0:
				var to := _pick_pass(owner_side)
				if to >= 0:
					var r: Dictionary = teams[owner_side][to]
					var lead: Vector2 = r["dir"] * 2.0 if r["moving"] else Vector2.ZERO
					var aim: Vector2 = r["pos"] + lead
					var dist: float = aim.distance_to(bp.pos)
					c["kick"] = 0.28
					if dist > 26.0:
						bp.kick_lofted(aim, 5.0)
					else:
						bp.kick_ground(aim, clampf(dist * 0.9 + 8.0, 13.0, 24.0))
					pass_target = to
					ball_state = "pass"
				next_pass = Game.rng.randf_range(0.7, 1.6)
		"pass":
			bp.step(delta)
			var r2: Dictionary = teams[owner_side][pass_target]
			var go: Vector2 = bp.pos if (not bp.in_air() and bp.pos.distance_to(r2["pos"]) < 6.0) else bp.pos + bp.vel * 0.4
			_move(r2, go, _spd(r2), delta)
			# se a posse virou, o adversário corta
			var cutter := -1
			if want_side != owner_side:
				cutter = _nearest(want_side, bp.pos)
				if cutter >= 0:
					var ce: Dictionary = teams[want_side][cutter]
					_move(ce, bp.pos, _spd(ce), delta)
					if ce["pos"].distance_to(bp.pos) < 1.3 and bp.z < 2.0:
						owner_side = want_side
						holder = cutter
						ball_state = "dribble"
						next_pass = 0.9
			if ball_state == "pass" and r2["pos"].distance_to(bp.pos) < 1.3 and bp.z < 2.0:
				holder = pass_target
				ball_state = "dribble"
				bp.place(r2["pos"])
			elif ball_state == "pass" and not bp.in_air() and bp.speed() < 0.5:
				ball_state = "loose"
		"loose":
			bp.step(delta)
			var o2 := _nearest(want_side, bp.pos)
			var e2: Dictionary = teams[want_side][o2]
			_move(e2, bp.pos, _spd(e2), delta)
			if e2["pos"].distance_to(bp.pos) < 1.2:
				owner_side = want_side
				holder = o2
				ball_state = "dribble"
				next_pass = 0.9
		"shot":
			bp.step(delta)
			var gy2: float = OWN_GOAL[1 - owner_side]
			if (bp.pos.y - gy2) * FWD[owner_side] >= 0.0 or bp.speed() < 0.5:
				keeper_ball(1 - owner_side)
	_separate(_teams_all)
	# árbitro acompanha de perto
	_move(referee, Vector2(clampf(bp.pos.x + 9.0, -30.0, 30.0), clampf(bp.pos.y + 7.0, 3.0, 102.0)), 6.5, delta)
	# câmera segue a bola
	var vh: float = size.y / maxf(s, 1.0)
	var vw: float = size.x / maxf(s, 1.0)
	var ty: float = clampf(bp.pos.y - vh * 0.5, -4.0, LENGTH + 4.0 - vh)
	var tx: float = clampf(bp.pos.x * 0.85, -(HALF_W + 3.0 - vw / 2.0), HALF_W + 3.0 - vw / 2.0)
	cam_y = lerpf(cam_y, ty, clampf(delta * 3.0, 0.0, 1.0))
	cam_x = lerpf(cam_x, tx, clampf(delta * 3.0, 0.0, 1.0))
	queue_redraw()


# ------------------------------------------------------------ tela
func _w2s(w: Vector2) -> Vector2:
	return Vector2(size.x / 2.0 + (w.x - cam_x) * s, size.y - (w.y - cam_y) * s)


func _s2w(p: Vector2) -> Vector2:
	return Vector2((p.x - size.x / 2.0) / s + cam_x, cam_y + (size.y - p.y) / s)


func _w2s_xf() -> Transform2D:
	return Transform2D(Vector2(s, 0.0), Vector2(0.0, -s), Vector2(size.x / 2.0 - cam_x * s, size.y + cam_y * s))


func _pause_rect() -> Rect2:
	return Rect2(size.x - 92, size.y - 104, 68, 68)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if _pause_rect().grow(12).has_point(e.position):
			pause_pressed.emit()


func _draw_field() -> void:
	_pitch_bands()
	_draw_adboards(LENGTH, -1.0)
	_draw_adboards(0.0, 1.0)
	var lw: float = maxf(0.12 * s, 2.0)
	# todas as linhas retas numa chamada só
	_lines_buf = _w2s_xf() * _field_lines()
	draw_multiline(_lines_buf, LINE_COL, lw)
	draw_arc(_w2s(Vector2(0, 52.5)), 9.15 * s, 0, TAU, 64, LINE_COL, lw)
	draw_circle(_w2s(Vector2(0, 52.5)), 3.0, LINE_COL)
	for g in [0.0, LENGTH]:
		var dirv := 1.0 if g == 0.0 else -1.0
		draw_circle(_w2s(Vector2(0, g + dirv * 11.0)), 3.0, LINE_COL)
		var a0 := -PI + 0.645 if g == 0.0 else 0.645
		var a1 := -0.645 if g == 0.0 else PI - 0.645
		draw_arc(_w2s(Vector2(0, g + dirv * 11.0)), 9.15 * s, a0, a1, 32, LINE_COL, lw)


## Pares de pontos (metros) das linhas retas: bordas, meio-campo e as áreas dos dois lados.
func _field_lines() -> PackedVector2Array:
	if _fl_lines.is_empty():
		var segs: Array = [Vector2(-HALF_W, 0), Vector2(HALF_W, 0), Vector2(-HALF_W, LENGTH), Vector2(HALF_W, LENGTH),
			Vector2(-HALF_W, 0), Vector2(-HALF_W, LENGTH), Vector2(HALF_W, 0), Vector2(HALF_W, LENGTH),
			Vector2(-HALF_W, 52.5), Vector2(HALF_W, 52.5)]
		for g in [0.0, LENGTH]:
			var dirv := 1.0 if g == 0.0 else -1.0
			for box in [[20.16, 16.5], [9.16, 5.5]]:
				var bx: float = box[0]
				var by: float = g + dirv * float(box[1])
				segs.append_array([Vector2(-bx, g), Vector2(-bx, by), Vector2(bx, g), Vector2(bx, by), Vector2(-bx, by), Vector2(bx, by)])
		_fl_lines = PackedVector2Array(segs)
	return _fl_lines


## Quem entra no desenho: os dois times, o árbitro e a bola (refeito quando o elenco muda).
func _sync_roster() -> void:
	var sig: int = teams[0].size() * 1000 + teams[1].size()
	if sig == _ro_sig:
		return
	_ro_sig = sig
	_ro_reset()
	for sd in 2:
		for e in teams[sd]:
			_ro_add(e, sd)
	_ro_add(referee, 3)
	_ro_add(null, 4)
	_ro_done()


func _draw() -> void:
	if sim == null or teams[0].is_empty():
		return
	s = size.x / CAMERA_WIDTH_M
	gk_tilt = 0.0
	var f := UI.bold()
	_draw_field()
	_draw_goal_far(LENGTH, 1.0)   # gol de cima: rede atrás, mais longe da câmera
	_draw_goal(false)
	_draw_people()
	_draw_goal(true)
	_draw_scoreboard(f)
	var mid := size.x / 2.0
	if holder >= 0 and holder < teams[owner_side].size():
		_draw_card(f, teams[owner_side][holder])
	_draw_field_minimap(f)
	_draw_possession(f, 380.0, size.x - 500.0)
	# botão de pausa (quadrado arredondado)
	var pr := _pause_rect()
	_rbox(pr, Color(0, 0, 0, 0.38), 16)
	if paused_view:
		draw_colored_polygon(PackedVector2Array([pr.position + Vector2(26, 18), pr.position + Vector2(26, 50), pr.position + Vector2(50, 34)]), Color.WHITE)
	else:
		_rbox(Rect2(pr.position + Vector2(21, 18), Vector2(9, 32)), Color.WHITE, 3)
		_rbox(Rect2(pr.position + Vector2(38, 18), Vector2(9, 32)), Color.WHITE, 3)
	if banner != "" and cel_t <= 0.0:
		var bw := 640.0
		_rbox(Rect2(mid - bw / 2, size.y * 0.36, bw, 84), Color("e6c56a") if banner_gold else Color(0.03, 0.06, 0.05, 0.86), 22)
		draw_string(f, Vector2(mid - bw / 2, size.y * 0.36 + 56), banner, HORIZONTAL_ALIGNMENT_CENTER, bw, 34 if banner_gold else 24,
			Color("14203a") if banner_gold else Color.WHITE)
	_draw_celebration(f)


## Gol na partida ao vivo: o autor aparece grande comemorando.
func celebrate(scorer_name: String, sd: int) -> void:
	for e in teams[sd]:
		if str(e["p"]["name"]) == scorer_name:
			start_celebration(e, kits[sd], scorer_name)
			return
	if not teams[sd].is_empty():
		start_celebration(teams[sd][teams[sd].size() - 1], kits[sd], scorer_name)


func _draw_field_minimap(f: Font) -> void:
	var m := Rect2(30, 104, 74, 112)
	var en := 1.0
	if holder >= 0 and holder < teams[owner_side].size():
		en = float(teams[owner_side][holder]["p"].get("energy", 100.0)) / 100.0
	draw_string(f, Vector2(m.position.x, m.position.y - 18), "Energia", HORIZONTAL_ALIGNMENT_LEFT, 80, 11, Color(1, 1, 1, 0.9))
	draw_rect(Rect2(m.position.x, m.position.y - 12, m.size.x, 7), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(m.position.x + 1, m.position.y - 11, (m.size.x - 2) * en, 5), Color("3ddc6a"))
	_rbox(m.grow(5), Color(0, 0, 0, 0.3), 10)
	draw_rect(m, PITCH.darkened(0.12))
	var a := _to_map(m, _s2w(Vector2(0, 0)), LENGTH)
	var b := _to_map(m, _s2w(size), LENGTH)
	var vis := Rect2(Vector2(clampf(a.x, m.position.x, m.end.x), clampf(a.y, m.position.y, m.end.y)), Vector2.ZERO)
	vis = vis.expand(Vector2(clampf(b.x, m.position.x, m.end.x), clampf(b.y, m.position.y, m.end.y)))
	draw_rect(vis, Color(1, 1, 1, 0.22))
	draw_rect(m, Color(1, 1, 1, 0.85), false, 1.5)
	draw_line(Vector2(m.position.x, m.position.y + m.size.y / 2), Vector2(m.end.x, m.position.y + m.size.y / 2), Color(1, 1, 1, 0.7), 1.0)
	draw_arc(m.position + m.size / 2, 7.0, 0, TAU, 20, Color(1, 1, 1, 0.7), 1.0)
	_lk = 1.0
	for sd in 2:
		for e in teams[sd]:
			_q_circle(_to_map(m, e["pos"], LENGTH), 2.2, KEEPER_SHIRT if e.get("keeper", false) else kits[sd][0])
	_q_circle(_to_map(m, bp.pos, LENGTH), 1.8, Color.WHITE)
	_flush()
