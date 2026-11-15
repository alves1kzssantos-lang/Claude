extends RefCounted
## Partida inteira no campo ao vivo (src/field_view.gd), sem lances, a 1×.


func run(t) -> void:
	Game.rng.seed = 321
	var coach = {"name": "Teste", "age": 35, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}
	Game.new_career(8, coach, 2, 0)
	var sim := MatchSim.new(0, 1)
	var fv := FieldView.new()
	fv.size = Vector2(1280, 720)
	fv.setup_field(sim)
	var dt := 1.0 / 30.0
	var acc := 0.0
	var frames := 0
	var agree := 0
	var changes := 0
	var last_owner := 1
	var outside := 0
	var passes := 0
	var last_state := ""
	var t0 := Time.get_ticks_usec()
	while not sim.finished:
		acc += dt * 0.5
		while acc >= 1.0 and not sim.finished:
			acc -= 1.0
			for e in sim.step():
				if e["type"] == "chance":
					fv.show_chance(e["side"])
				elif e["type"] == "goal":
					fv.kickoff(1 - e["side"])
				elif e["type"] == "card" and e.get("red", false):
					fv.rebuild_teams()   # como a tela da partida faz na expulsão
			fv.feed_minute(sim.last_side)
		fv._process(dt)
		frames += 1
		if fv.owner_side == 0:
			agree += 1
		if fv.owner_side != last_owner:
			changes += 1
			last_owner = fv.owner_side
		if absf(fv.bp.pos.x) > 40.0 or fv.bp.pos.y < -6.0 or fv.bp.pos.y > 111.0:
			outside += 1
		if fv.ball_state == "pass" and last_state != "pass":
			passes += 1
		last_state = fv.ball_state
	var us := (Time.get_ticks_usec() - t0) / float(frames)
	var screen_pct := 100.0 * agree / frames
	t.check(frames > 5000, "partida inteira rodou", "%d quadros (%.0f s a 1×)" % [frames, frames * dt])
	t.check(absf(screen_pct - sim.possession(0)) < 12.0, "posse na tela bate com a simulação", "tela %.0f%%, simulação %d%%" % [screen_pct, sim.possession(0)])
	t.check(changes > 12 and changes < 160, "troca de posse num ritmo de jogo", "%d trocas" % changes)
	t.check(outside == 0, "bola nunca sai do mapa", str(outside))
	t.check(passes > 30, "time troca passes", "%d passes" % passes)
	t.check(fv.teams[0].size() == 11 - sim.reds[0] and fv.teams[1].size() == 11 - sim.reds[1], "22 em campo (menos expulsos)", "%d+%d em campo, %d+%d expulsos" % [fv.teams[0].size(), fv.teams[1].size(), sim.reds[0], sim.reds[1]])
	t.check(us < 3000.0, "campo ao vivo leve", "%.0f µs por quadro" % us)
	fv.free()
	Game.delete_save(8)
