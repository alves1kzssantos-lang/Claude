class_name Cups
## Copas em mata-mata da carreira (definições em world_data.gd, World.CUPS).
## Estado guardado em Game.S["cups"]: lista de
##   {"def", "name", "comp", "alive": [clubes vivos], "rounds": [[confrontos]], "days": [dia de cada etapa],
##    "stages": [{"round", "leg"} de cada etapa, alinhado com "days"], "next": próxima etapa a jogar,
##    "champion": clube campeão ou -1}
## Uma fase em ida e volta (World.CUPS[..]["legs"] == 2) ocupa 2 etapas/datas; jogo único ocupa 1.
## Confronto: {"h", "a", "hg", "ag", "pens": [] ou [x, y], "w": vencedor, "sc", "st",
##   "legs": [[gols_h, gols_a] do jogo 1 (h em casa), [gols_h, gols_a] do jogo 2 (a em casa)]}
## "hg"/"ag" = agregado na visão de h; "pens" (visão de h) só se o agregado empatar (sem gol fora).
## Saves antigos sem "stages" são tratados como jogo único.
## Clubes de outras ligas entram como "convidados" no fim de Game.S["clubs"].

const ROUND_NAMES := {64: "32-avos de final", 32: "16-avos de final", 16: "Oitavas de final", 8: "Quartas de final", 4: "Semifinal", 2: "Final"}
## Nomes no estilo da tela de resultados ("Semi Finais - Segunda Partida").
const STAGE_NAMES := {64: "32-avos de Final", 32: "16-avos de Final", 16: "Oitavas de Final", 8: "Quartas de Final", 4: "Semi Finais", 2: "Final"}


## Nome da fase r (r = índice em cup["rounds"], não da etapa).
static func round_name(cup: Dictionary, r: int) -> String:
	var n: int = int(World.CUPS[cup["def"]]["size"]) >> r
	return ROUND_NAMES.get(n, "Fase %d" % (r + 1))


## Etapas da copa ({"round", "leg"} por data). Saves antigos: uma etapa por fase (jogo único).
static func stages(cup: Dictionary) -> Array:
	if not cup.has("stages"):
		var out: Array = []
		for r in cup["days"].size():
			out.append({"round": r, "leg": 1})
		cup["stages"] = out
	return cup["stages"]


## Quantos jogos tem a fase r (1 ou 2).
static func round_legs(cup: Dictionary, r: int) -> int:
	var n := 0
	for st in stages(cup):
		if int(st["round"]) == r:
			n += 1
	return maxi(n, 1)


## Nome da etapa: "Semi Finais - Segunda Partida", "Final" etc.
static func stage_name(cup: Dictionary, stage_index: int) -> String:
	var st: Dictionary = stages(cup)[stage_index]
	var r: int = st["round"]
	var n: int = int(World.CUPS[cup["def"]]["size"]) >> r
	var nm: String = STAGE_NAMES.get(n, "Fase %d" % (r + 1))
	if round_legs(cup, r) > 1:
		nm += " - Primeira Partida" if int(st["leg"]) == 1 else " - Segunda Partida"
	return nm


## Rótulo curto da partida: "Semifinal • Jogo de ida", "Semifinal • Jogo de volta" ou só "Final".
static func stage_label(cup: Dictionary, stage_index: int) -> String:
	var st: Dictionary = stages(cup)[stage_index]
	var nm := round_name(cup, int(st["round"]))
	if round_legs(cup, int(st["round"])) > 1:
		nm += " • Jogo de ida" if int(st["leg"]) == 1 else " • Jogo de volta"
	return nm


## Jogos já disputados do confronto, na visão de h (compatível com saves antigos).
static func tie_legs(t: Dictionary) -> Array:
	if t.has("legs"):
		return t["legs"]
	if int(t["hg"]) >= 0:
		return [[int(t["hg"]), int(t["ag"])]]
	return []


## Agregado [gols_h, gols_a] dos primeiros n jogos do confronto, na visão de h.
static func aggregate(t: Dictionary, n: int = 99) -> Array:
	var L := tie_legs(t)
	var x := 0
	var y := 0
	for i in mini(n, L.size()):
		x += int(L[i][0])
		y += int(L[i][1])
	return [x, y]


## Resultados de uma etapa (para a tela de resultados). Cada item, na visão do mandante DESTE jogo:
## {"h", "a", "hg", "ag" (-1 se não jogado), "agg_h", "agg_a" (agregado até este jogo),
##  "pens" ([] ou [x, y]), "w" (vencedor do confronto se esta etapa o decide, senão -1), "leg"}
static func stage_results(ci: int, stage_index: int) -> Array:
	var c: Dictionary = Game.S["cups"][ci]
	var sts := stages(c)
	if stage_index < 0 or stage_index >= sts.size():
		return []
	var r: int = sts[stage_index]["round"]
	var leg: int = sts[stage_index]["leg"]
	if r >= c["rounds"].size():
		return []
	var last := leg >= round_legs(c, r)
	var out: Array = []
	for t in c["rounds"][r]:
		var L := tie_legs(t)
		var played := L.size() >= leg
		var flip := leg == 2
		var g: Array = L[leg - 1] if played else [-1, -1]
		var ag := aggregate(t, leg if played else leg - 1)
		var pens: Array = t["pens"] if (played and last) else []
		var e := {"h": t["a"] if flip else t["h"], "a": t["h"] if flip else t["a"],
			"hg": g[1] if flip else g[0], "ag": g[0] if flip else g[1],
			"agg_h": ag[1] if flip else ag[0], "agg_a": ag[0] if flip else ag[1],
			"pens": [pens[1], pens[0]] if (flip and not pens.is_empty()) else pens.duplicate(),
			"w": t["w"] if (played and last) else -1, "leg": leg}
		out.append(e)
	return out


static func _league_index(name: String) -> int:
	for i in World.LEAGUES.size():
		if World.LEAGUES[i]["name"] == name:
			return i
	return -1


## Monta as copas da temporada. ranking = ordem final do campeonato anterior (ou vazio).
static func build_season(ranking: Array) -> void:
	var S: Dictionary = Game.S
	var my_league: String = World.LEAGUES[int(S["league"])]["name"]
	S["cups"] = []
	var used := {}   # intervalos entre rodadas já ocupados por alguma copa (evita duas copas na mesma data)
	for d in World.CUPS.size():
		var cd: Dictionary = World.CUPS[d]
		if not (my_league in cd["region"]):
			continue
		var teams: Array = []
		for k in cd["region"].size():
			var li := _league_index(cd["region"][k])
			if li < 0:
				continue
			var take: int = cd["take"][k]
			var only: Array = cd.get("only", [])   # copas regionais: só os clubes da lista
			if li == int(S["league"]):
				var order: Array = ranking.duplicate() if not ranking.is_empty() else _by_strength()
				if not only.is_empty():
					order = order.filter(func(cid): return _in_only(only, World.LEAGUES[li]["clubs"][Game.club(cid).get("ci", cid)][0], Game.club(cid)["name"]))
				for cid in order.slice(0, take):
					teams.append(cid)
			else:
				var got := 0
				for ci in World.LEAGUES[li]["clubs"].size():
					if got >= take:
						break
					var info: Array = World.LEAGUES[li]["clubs"][ci]
					if not only.is_empty() and not _in_only(only, info[0], info[0]):
						continue
					teams.append(Game.guest_club(li, ci))
					got += 1
		teams = teams.slice(0, int(cd["size"]))
		if teams.size() < int(cd["size"]):
			continue   # chave incompleta (faltam clubes elegíveis): a copa não é disputada nesta liga
		Game.rng_shuffle(teams)
		var cup := {"def": d, "name": cd["name"], "comp": cd["comp"], "alive": teams, "rounds": [], "days": [], "stages": [],
			"next": 0, "champion": -1}
		_schedule(cup, used)
		S["cups"].append(cup)


static func _in_only(only: Array, a: String, b: String) -> bool:
	for nm in only:
		if DataPack.norm(nm) == DataPack.norm(a) or DataPack.norm(nm) == DataPack.norm(b):
			return true
	return false


static func _by_strength() -> Array:
	var ids: Array = range(Game.n_league())
	ids.sort_custom(func(a, b): return Game.club(a)["str"] > Game.club(b)["str"])
	return ids


## Datas das etapas: no meio da semana, entre duas rodadas do campeonato, espalhadas pela temporada
## e sempre antes da última rodada. Jogo de volta vai no intervalo seguinte ao da ida.
## used = intervalos já ocupados por outras copas (é atualizado).
static func _schedule(cup: Dictionary, used: Dictionary) -> void:
	var fx: Array = Game.S["fixtures"]
	var n: int = fx.size()
	var gaps: int = n - 1   # intervalo i fica entre as rodadas i e i + 1
	var cd: Dictionary = World.CUPS[cup["def"]]
	var rounds := 0
	var sz: int = cd["size"]
	while sz > 1:
		rounds += 1
		sz >>= 1
	var legs: int = clampi(int(cd.get("legs", 1)), 1, 2)
	var sts: Array = []
	for r in rounds:
		var nl := legs
		if r == rounds - 1 and bool(cd.get("final_single", false)):
			nl = 1
		for l in nl:
			sts.append({"round": r, "leg": l + 1})
	cup["stages"] = sts
	cup["days"] = []
	var total: int = sts.size()
	var prev := -1
	for k in total:
		var hi: int = maxi(gaps - (total - k), prev + 1)   # deixa espaço para as etapas restantes
		var target: int = int(float(k + 1) * gaps / (total + 1)) if int(sts[k]["leg"]) == 1 else prev + 1
		target = clampi(target, prev + 1, hi)
		var g := -1
		for i in range(target, hi + 1):
			if not used.has(i):
				g = i
				break
		if g < 0:
			for i in range(target - 1, prev, -1):
				if not used.has(i):
					g = i
					break
		if g < 0:
			g = target   # sem intervalo livre: divide a data com outra copa
		g = clampi(g, 0, maxi(gaps - 1, 0))
		used[g] = true
		prev = g
		var d0: int = fx[g]["day"]
		var d1: int = fx[mini(g + 1, n - 1)]["day"]
		cup["days"].append(d0 + maxi(1, int((d1 - d0) / 2.0)))


## Próxima etapa de copa ainda não jogada: {"cup", "round", "leg", "stage", "day"} ou {}.
static func next_due() -> Dictionary:
	var best := {}
	var cups: Array = Game.S.get("cups", [])
	for i in cups.size():
		var c: Dictionary = cups[i]
		if c["champion"] >= 0 or c["next"] >= c["days"].size():
			continue
		var d: int = c["days"][c["next"]]
		if best.is_empty() or d < int(best["day"]):
			var st: Dictionary = stages(c)[c["next"]]
			best = {"cup": i, "round": int(st["round"]), "leg": int(st["leg"]), "stage": int(c["next"]), "day": d}
	return best


## Fase (índice em "rounds") da próxima etapa.
static func _cur_round(c: Dictionary) -> int:
	var sts := stages(c)
	if c["next"] >= sts.size():
		return c["rounds"].size()
	return int(sts[c["next"]]["round"])


## Sorteia os confrontos da fase da próxima etapa, se ainda não sorteou.
static func ensure_draw(ci: int) -> void:
	var c: Dictionary = Game.S["cups"][ci]
	if c["rounds"].size() > _cur_round(c):
		return
	var alive: Array = c["alive"].duplicate()
	var ties: Array = []
	for i in range(0, alive.size() - 1, 2):
		ties.append({"h": alive[i], "a": alive[i + 1], "hg": -1, "ag": -1, "pens": [], "w": -1, "sc": [], "st": [], "legs": []})
	c["rounds"].append(ties)


## Confronto do clube do jogador na fase da próxima etapa (ou {}).
static func my_tie(ci: int) -> Dictionary:
	ensure_draw(ci)
	var c: Dictionary = Game.S["cups"][ci]
	var r := _cur_round(c)
	if r >= c["rounds"].size():
		return {}
	for t in c["rounds"][r]:
		if t["h"] == Game.S["club"] or t["a"] == Game.S["club"]:
			return t
	return {}


## Joga a próxima etapa inteira (todos os jogos dela). user_sim = partida do jogador (ou null para simular).
## No jogo de volta o clube "a" do confronto manda em casa. O confronto é decidido no último jogo da fase.
static func play_round(ci: int, user_sim) -> void:
	ensure_draw(ci)
	var c: Dictionary = Game.S["cups"][ci]
	var cd: Dictionary = World.CUPS[c["def"]]
	var si: int = c["next"]
	var st: Dictionary = stages(c)[si]
	var r: int = st["round"]
	var leg: int = st["leg"]
	var last := leg >= round_legs(c, r)
	Game.S["day"] = c["days"][si]
	var winners: Array = []
	for t in c["rounds"][r]:
		var home: int = t["h"] if leg == 1 else t["a"]
		var away: int = t["a"] if leg == 1 else t["h"]
		var sim
		if user_sim != null and user_sim.h == home and user_sim.a == away:
			sim = user_sim
		else:
			sim = MatchSim.new(home, away)
		while not sim.finished:
			sim.step()
		Game.apply_players(sim)
		var L: Array = tie_legs(t).duplicate() if leg > 1 else []
		L.append([sim.score[0], sim.score[1]] if leg == 1 else [sim.score[1], sim.score[0]])
		t["legs"] = L
		var ag := aggregate(t)
		t["hg"] = ag[0]
		t["ag"] = ag[1]
		t["sc"] = sim.scorers
		t["st"] = [sim.att, sim.shots, sim.poss, sim.fouls, sim.yellows, sim.reds, sim.offsides]
		if not last:
			continue
		if t["hg"] != t["ag"]:
			t["w"] = t["h"] if t["hg"] > t["ag"] else t["a"]
		else:
			t["pens"] = _shootout(t["h"], t["a"])
			t["w"] = t["h"] if t["pens"][0] > t["pens"][1] else t["a"]
		winners.append(t["w"])
		# prêmio por avançar
		if t["w"] == Game.S["club"]:
			var pr: float = snappedf(float(cd["prize"]) * (0.25 + 0.25 * r), 0.01)
			Game.S["money"] += pr
			Game.S["fin"]["premios"] += pr
	c["next"] = si + 1
	if not last:
		return
	c["alive"] = winners
	if winners.size() == 1:
		c["champion"] = winners[0]
		_crown(c)
	else:
		var mine := my_status(ci)
		if mine == "eliminado" and _was_in_round(c, r):
			Game.add_news("Eliminado da %s" % c["name"], "O time caiu na %s." % round_name(c, r))


static func _was_in_round(c: Dictionary, r: int) -> bool:
	for t in c["rounds"][r]:
		if t["h"] == Game.S["club"] or t["a"] == Game.S["club"]:
			return true
	return false


static func _shootout(h: int, a: int) -> Array:
	var ph := 0.5 + (float(Game.club(h)["str"]) - float(Game.club(a)["str"])) / 80.0
	var x := 0
	var y := 0
	for k in 5:
		if Game.rng.randf() < 0.76:
			x += 1
		if Game.rng.randf() < 0.76:
			y += 1
	while x == y:
		if Game.rng.randf() < 0.76:
			x += 1
		if Game.rng.randf() < 0.76:
			y += 1
	if (x > y) != (Game.rng.randf() < clampf(ph, 0.3, 0.7)):
		var t := x
		x = y
		y = t
	return [x, y]


static func _crown(c: Dictionary) -> void:
	var champ: int = c["champion"]
	Game.club(champ)["titles"] = int(Game.club(champ).get("titles", 0)) + 1
	for p in Game.squad(champ):
		p["titles"].append(c["name"])
	if champ == Game.S["club"]:
		Game.S["trophies"].append({"name": c["name"], "year": Game.S["year"]})
		Game.S["support"] = mini(Game.S["support"] + 12, 100)
		Game.S["coach"]["rep"] = minf(float(Game.S["coach"]["rep"]) + 1.0, 10.0)
		var big: float = float(World.CUPS[c["def"]]["prize"])
		Game.S["money"] += big
		Game.S["fin"]["premios"] += big
		Game.add_news("CAMPEÃO DA %s!" % c["name"].to_upper(), "Título conquistado! Premiação de %s." % Game.money(big))
	else:
		Game.add_news("%s: campeão" % c["name"], "%s ficou com a taça." % Game.club_name(champ))


## Situação do clube do jogador na copa: "campeão", "vivo", "eliminado" ou "fora".
static func my_status(ci: int) -> String:
	var c: Dictionary = Game.S["cups"][ci]
	var me: int = Game.S["club"]
	if c["champion"] == me:
		return "campeão"
	if me in c["alive"]:
		return "vivo"
	for rd in c["rounds"]:
		for t in rd:
			if t["h"] == me or t["a"] == me:
				return "eliminado"
	return "fora"
