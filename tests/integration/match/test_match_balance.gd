extends RefCounted
## Equilíbrio da partida: temporada simulada e lances jogados sozinhos.


func run(t) -> void:
	Game.rng.seed = 12345
	var coach = {"name": "Teste", "age": 35, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}
	Game.new_career(8, coach, 3, 0)
	var t0 := Time.get_ticks_msec()
	while not Game.S["season_over"]:
		Game.play_round(null)
	var ms_round := (Time.get_ticks_msec() - t0) / float(Game.S["fixtures"].size())
	var g := 0
	var f := 0
	var y := 0
	var r := 0
	var o := 0
	var n := 0
	for rd in Game.S["fixtures"]:
		for m in rd["m"]:
			n += 1
			g += m["hg"] + m["ag"]
			f += m["st"][3][0] + m["st"][3][1]
			y += m["st"][4][0] + m["st"][4][1]
			r += m["st"][5][0] + m["st"][5][1]
			o += m["st"][6][0] + m["st"][6][1]
	var gpg := g / float(n)
	t.check(gpg > 2.0 and gpg < 3.4, "gols por jogo", "%.2f" % gpg)
	t.check(f / float(n) > 18.0 and f / float(n) < 32.0, "faltas por jogo", "%.1f" % (f / float(n)))
	t.check(y / float(n) > 2.5 and y / float(n) < 6.0, "amarelos por jogo", "%.2f" % (y / float(n)))
	t.check(r / float(n) > 0.05 and r / float(n) < 0.45, "vermelhos por jogo", "%.2f" % (r / float(n)))
	t.check(o / float(n) > 1.0 and o / float(n) < 6.0, "impedimentos por jogo", "%.2f" % (o / float(n)))
	t.check(ms_round < 120.0, "rodada simulada rápida", "%.1f ms por rodada" % ms_round)
	var susp_ok := true
	for c in Game.S["clubs"].size():
		for pid in Game.club(c)["xi"]:
			if int(Game.player(pid).get("susp", 0)) > 0:
				susp_ok = false
	t.check(susp_ok, "suspenso nunca fica escalado")
	Game.new_season()

	# lances jogados sozinhos: ataque do jogador com decisões automáticas
	var stats := {}
	var frames := 0
	var t1 := Time.get_ticks_usec()
	var n_lances := 600   # amostra grande: a taxa de gol não oscila com a ordem do sorteio
	for k in n_lances:
		var sim := MatchSim.new(Game.S["club"], (Game.S["club"] + 1 + k % 19) % 20)
		sim.minute = 30
		sim.pending = {"side": 0, "pg": 0.3}
		var lv := LanceView.new()
		lv.size = Vector2(1280, 720)
		lv.setup(sim, 0, true)
		var guard := 0
		while lv.state != "done" and guard < 2000:
			guard += 1
			if lv.state == "decide":
				_auto_play(lv)
			lv._process(1.0 / 60.0)
			frames += 1
		var kind: String = lv.result.get("kind", "travou")
		if lv.result.get("pen", false):
			kind += "_pen"
		stats[kind] = int(stats.get(kind, 0)) + 1
		lv.free()
	var us_frame := (Time.get_ticks_usec() - t1) / float(maxi(frames, 1))
	var goals := int(stats.get("goal", 0)) + int(stats.get("goal_pen", 0))
	print("    resultados dos lances: ", stats)
	t.check(not stats.has("travou"), "nenhum lance trava")
	t.check(goals > n_lances / 10 and goals < n_lances * 0.47, "lances do jogador viram gol na medida", "%d de %d" % [goals, n_lances])
	t.check(int(stats.get("save", 0)) > 15, "goleiro defende", str(stats.get("save", 0)))
	t.check(int(stats.get("lost", 0)) > 20, "zaga corta e desarma", str(stats.get("lost", 0)))
	t.check(int(stats.get("offside", 0)) > 2, "impedimento acontece", str(stats.get("offside", 0)))
	t.check(us_frame < 2000.0, "lógica do lance leve", "%.0f µs por quadro" % us_frame)
	Game.delete_save(8)


## Jogador automático: passa para frente uma ou duas vezes e chuta no canto.
func _auto_play(lv: LanceView) -> void:
	var c: Dictionary = lv.att[lv.carrier]
	if not lv.shot_only and c["pos"].y > 17.0 and lv.moments < 2:
		var best := -1
		var bo := -1.0
		for i in lv.att.size():
			if i == lv.carrier or lv.att[i]["pos"].y > c["pos"].y - 2.0:
				continue
			var free := 99.0
			for d in lv.dfn:
				free = minf(free, d["pos"].distance_to(lv.att[i]["pos"]))
			if free > bo:
				bo = free
				best = i
		if best >= 0:
			var lofted := absf(c["pos"].x) > 14.0 and Referee.in_box(lv.att[best]["pos"])
			lv._do_pass(best, lofted)
			return
	var corner := 2.7 if lv.gk["pos"].x <= 0.0 else -2.7
	lv._do_shot(corner, 0.6, 0.6)
