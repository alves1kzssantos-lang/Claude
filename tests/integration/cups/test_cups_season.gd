extends RefCounted
## Temporada inteira com copas (src/cups.gd): Brasil (Copa do Brasil + Libertadores)
## e Inglaterra (FA Cup + Champions). Todas as copas terminam com campeão antes do fim do campeonato.
## Ida e volta: Copa do Brasil (inclusive a final), Libertadores e Champions (final em jogo único);
## o agregado decide e pênaltis só com agregado empatado.


func _league_idx(name: String) -> int:
	for i in World.LEAGUES.size():
		if World.LEAGUES[i]["name"] == name:
			return i
	return -1


func run(t) -> void:
	if not DataPack.loaded():
		DataPack.import_zip("res://datapack.zip")
	var coach = {"name": "Teste", "age": 35, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}
	for lname in ["Brasileirão Série A", "Premier League"]:
		var li := _league_idx(lname)
		t.check(li >= 0, "liga %s existe" % lname)
		if li < 0:
			continue
		Game.rng.seed = 77
		Game.new_career(8, coach, 0, li)
		var ncups: int = Game.S["cups"].size()
		t.check(ncups >= 1, "%s tem copas" % lname, str(ncups))
		var cup_games := 0
		var guard := 0
		while not Game.S["season_over"] and guard < 200:
			guard += 1
			var mt := Game.next_user_match()
			if mt.is_empty():
				break
			Game.play_next(null)
			if Game.S["last_user"]["kind"] == "cup":
				cup_games += 1
				var lu: Dictionary = Game.S["last_user"]
				var c: Dictionary = Game.S["cups"][int(lu["cup"])]
				var nlegs := Cups.round_legs(c, int(lu["round"]))
				if int(lu["leg"]) == nlegs and lu["agg"][0] == lu["agg"][1]:
					t.check(not lu["pens"].is_empty(), "agregado empatado vai para os pênaltis")
				elif not lu["pens"].is_empty():
					t.check(false, "pênaltis sem agregado empatado", str(lu))
				if int(lu["leg"]) == 1 and nlegs == 1:
					t.check(lu["agg"] == [lu["hg"], lu["ag"]], "jogo único: agregado = placar")
		var names: Array = Game.S["cups"].map(func(c): return c["name"])
		for want in ({"Brasileirão Série A": ["Copa do Brasil", "Copa Libertadores"], "Premier League": ["Champions League"]}[lname]):
			t.check(want in names, "%s: tem %s" % [lname, want])
		_check_legs(t, lname)
		var all_done := true
		var champs: Array = []
		for c in Game.S["cups"]:
			if c["champion"] < 0:
				all_done = false
			else:
				champs.append("%s: %s" % [c["name"], Game.club_name(c["champion"])])
		t.check(Game.S["season_over"], "%s: temporada termina" % lname)
		var last_day: int = Game.S["fixtures"][Game.S["fixtures"].size() - 1]["day"]
		var clash := false
		var seen := {}
		var late := false
		for c in Game.S["cups"]:
			for d in c["days"]:
				if seen.has(d):
					clash = true
				seen[d] = true
				if int(d) >= last_day:
					late = true
		t.check(not clash, "%s: copas não dividem datas" % lname)
		t.check(not late, "%s: copas acabam antes da última rodada" % lname)
		t.check(all_done, "%s: todas as copas têm campeão" % lname, ", ".join(champs))
		t.check(cup_games >= 1, "%s: o clube joga copa" % lname, "%d jogos de copa" % cup_games)
		Game.new_season()
		t.check(Game.S["cups"].size() == ncups, "%s: copas sorteadas de novo na temporada seguinte" % lname)
	_old_save(t, coach)
	Game.delete_save(8)


## Confere cada copa: jogos por fase, agregado decide, pênaltis só com agregado empatado.
func _check_legs(t, lname: String) -> void:
	for ci in Game.S["cups"].size():
		var c: Dictionary = Game.S["cups"][ci]
		var cd: Dictionary = World.CUPS[int(c["def"])]
		var two: bool = int(cd.get("legs", 1)) == 2
		var nr: int = c["rounds"].size()
		var ok_legs := true
		var ok_agg := true
		var ok_pens := true
		for r in nr:
			var final_single: bool = (int(cd["size"]) >> r) == 2 and bool(cd.get("final_single", false))
			var want := 2 if (two and not final_single) else 1
			if Cups.round_legs(c, r) != want:
				ok_legs = false
			for tie in c["rounds"][r]:
				var L: Array = Cups.tie_legs(tie)
				if L.size() != want:
					ok_legs = false
					continue
				var x := 0
				var y := 0
				for g in L:
					x += int(g[0])
					y += int(g[1])
				if x != int(tie["hg"]) or y != int(tie["ag"]):
					ok_agg = false
				if x != y:
					if not tie["pens"].is_empty() or tie["w"] != (tie["h"] if x > y else tie["a"]):
						ok_agg = false
				elif tie["pens"].is_empty():
					ok_pens = false
		var tag := "%s/%s" % [lname, c["name"]]
		t.check(ok_legs, "%s: %s" % [tag, "fases com 2 jogos (ida e volta)" if two else "fases em jogo único"],
			"%d etapas, %d fases" % [Cups.stages(c).size(), nr])
		t.check(ok_agg, "%s: agregado decide o confronto" % tag)
		t.check(ok_pens, "%s: pênaltis só com agregado empatado" % tag)
		if c["name"] == "Copa Libertadores" or c["name"] == "Champions League":
			t.check(Cups.round_legs(c, nr - 1) == 1, "%s: final em jogo único" % tag)
		if c["name"] == "Copa do Brasil":
			t.check(Cups.round_legs(c, nr - 1) == 2, "%s: final em ida e volta" % tag)
		var last_st: int = int(c["next"]) - 1   # copa com menos clubes que "size" termina antes da última etapa agendada
		var res := Cups.stage_results(ci, last_st)
		t.check(res.size() == 1 and int(res[0]["w"]) == int(c["champion"]), "%s: resultados da última etapa apontam o campeão" % tag,
			Cups.stage_name(c, last_st))


## Save antigo (copa sem "stages", uma data por fase, confrontos sem "legs"): tratado como jogo único.
func _old_save(t, coach: Dictionary) -> void:
	Game.rng.seed = 5
	Game.new_career(8, coach, 0, _league_idx("Brasileirão Série A"))
	for c in Game.S["cups"]:
		var nd: Array = []
		var sz: int = World.CUPS[int(c["def"])]["size"]
		var n := 0
		while sz > 1:
			sz >>= 1
			nd.append(c["days"][mini(n * 2, c["days"].size() - 1)])
			n += 1
		c["days"] = nd
		c.erase("stages")
	var guard := 0
	while not Game.S["season_over"] and guard < 200:
		guard += 1
		if Game.next_user_match().is_empty():
			break
		Game.play_next(null)
	var ok := true
	for c in Game.S["cups"]:
		ok = ok and int(c["champion"]) >= 0 and Cups.round_legs(c, 0) == 1
	t.check(Game.S["season_over"] and ok, "save antigo sem etapas: copas em jogo único terminam com campeão")
