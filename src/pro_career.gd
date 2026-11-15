class_name Pro
extends RefCounted
## Modo carreira de jogador.
## Você cria um jogador, joga uma peneira (jogo festivo com olheiros), recebe propostas
## conforme a nota, assina com um clube e segue a carreira: técnico escala (ou não),
## nota por jogo, treino, lesões, fama, rede social com xingamentos e respostas,
## empresário, contratos, seleção, prêmios e vida fora de campo.
## Estado em Game.S["pro"]; o mundo (ligas, copas, clubes) é o mesmo do modo técnico.
## Números: assets/data/pro_career.json • textos: pro_social.json • vida: pro_life.json
## Regras explicadas em design/gdd/carreira-jogador.md

const POSITIONS := ["AC", "PD", "PE", "MEI", "VOL", "LD", "LE", "ZAG"]
const POS_NAMES := {"AC": "Centroavante", "PD": "Ponta direita", "PE": "Ponta esquerda", "MEI": "Meia", "VOL": "Volante",
	"LD": "Lateral direito", "LE": "Lateral esquerdo", "ZAG": "Zagueiro", "GOL": "Goleiro"}
const NATS := ["Brasil", "Argentina", "Portugal", "Colômbia", "Espanha", "Inglaterra", "França", "Itália", "Alemanha"]
const BOOTS := ["17171b", "f2f2f2", "e8c61c", "e0402f", "2f8fe0", "34c46b", "ff7ad9"]
const BOOT_NAMES := ["Preta", "Branca", "Dourada", "Vermelha", "Azul", "Verde", "Rosa"]
const HAIR_STYLES := ["Curto", "Topete", "Cheio", "Careca", "Raspado", "Franja"]
const BIG_NATIONS := ["Brasil", "Argentina", "França", "Espanha", "Inglaterra", "Alemanha", "Portugal"]

static var _cache: Dictionary = {}


# ------------------------------------------------------------ dados
static func _json(path: String) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	var d := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f != null:
		var parsed = JSON.parse_string(f.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			d = parsed
	_cache[path] = d
	return d


## Número de assets/data/pro_career.json (seção, chave), com valor padrão.
static func cfg(section: String, key: String, fallback: float) -> float:
	var sec = _json("res://assets/data/pro_career.json").get(section, {})
	if typeof(sec) == TYPE_DICTIONARY and sec.has(key):
		return float(sec[key])
	return fallback


static func cfg_sec(section: String) -> Dictionary:
	var sec = _json("res://assets/data/pro_career.json").get(section, {})
	return sec if typeof(sec) == TYPE_DICTIONARY else {}


static func social() -> Dictionary:
	return _json("res://assets/data/pro_social.json")


static func life() -> Dictionary:
	return _json("res://assets/data/pro_life.json")


# ------------------------------------------------------------ atalhos
static func is_pro() -> bool:
	return not Game.S.is_empty() and str(Game.S.get("mode", "")) == "pro" and Game.S.has("pro")


static func P() -> Dictionary:
	var pr: Dictionary = Game.S["pro"]
	if not pr.has("_v"):
		_migrate(pr)
	return pr


## Saves antigos: completa as chaves que versões novas passaram a usar.
static func _migrate(pr: Dictionary) -> void:
	var defaults := {"negotiated": {}, "season_closed": false, "pending_move": {}, "replied": false, "posted": false,
		"season_caps": 0, "clause": 0.0, "retired": false, "sponsors": [], "owned": [], "titles": [], "awards": [],
		"history": [], "feed": [], "next_post": 1, "offers": [], "polemics": 0, "banned": 0, "injury": "", "last": {}}
	for k in defaults.keys():
		if not pr.has(k):
			pr[k] = defaults[k]
	pr["_v"] = 2


static func me() -> Dictionary:
	return Game.player(int(P()["me"]))


static func _pick(arr: Array):
	return arr[Game.rng.randi_range(0, arr.size() - 1)]


static func _fmt(t: String) -> String:
	var opp := ""
	var lu: Dictionary = Game.S.get("last_user", {})
	if not lu.is_empty():
		opp = Game.club_name(lu["a"] if lu["h"] == Game.S["club"] else lu["h"])
	var nota: float = float(P().get("last", {}).get("rating", 6.0))
	return t.replace("{n}", str(me()["name"])).replace("{c}", Game.club_name(Game.S["club"])).replace("{r}", opp).replace("{nota}", "%.1f" % nota)


static func agent() -> Dictionary:
	for a in life().get("empresarios", []):
		if a["id"] == P()["agent"]:
			return a
	return {}


static func agent_level() -> int:
	return int(agent().get("nivel", 0))


static func avg_rating() -> float:
	var s: Dictionary = P()["season"]
	return float(s["sum"]) / float(s["g"]) if int(s["g"]) > 0 else 0.0


static func form(n: int = 5) -> float:
	var rs: Array = P()["ratings"]
	if rs.is_empty():
		return 6.0
	var t := 0.0
	var k := 0
	for i in range(rs.size() - 1, maxi(rs.size() - n, 0) - 1, -1):
		t += float(rs[i])
		k += 1
	return t / k


static func role_name(r: String) -> String:
	return {"titular": "Titular", "rotacao": "Rotação", "reserva": "Reserva", "base": "Time de base"}.get(r, r)


# ------------------------------------------------------------ criação e peneira
static func new_profile() -> Dictionary:
	return {"name": "Novo Craque", "age": 17, "nat": "Brasil", "pos": "AC", "foot": "Direito", "num": 9,
		"skin": 2, "hstyle": 1, "hcolor": 0, "beard": false, "boots": 0}


## Estaduais e copas regionais não contratam: o jogador assina com clubes das ligas nacionais.
static func signs_from(li: int) -> bool:
	var lg: Dictionary = World.LEAGUES[li]
	return not (lg["country"] == "Brasil" and str(lg["name"]).begins_with("Campeonato "))


## Liga do país do jogador (a de menor premiação, onde a peneira acontece).
static func home_league(nat: String) -> int:
	var best := -1
	for i in World.LEAGUES.size():
		if World.LEAGUES[i]["country"] == nat and signs_from(i):
			if best < 0 or float(World.LEAGUES[i]["prize"]) < float(World.LEAGUES[best]["prize"]):
				best = i
	return maxi(best, 0)


static func _stub_coach() -> Dictionary:
	return {"name": "Diretoria", "age": 50, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}


static func _apply_look(p: Dictionary, prof: Dictionary) -> void:
	p["look_skin"] = int(prof["skin"])
	p["look_hstyle"] = int(prof["hstyle"])
	p["look_hcolor"] = int(prof["hcolor"])
	p["look_beard"] = bool(prof["beard"])
	p["look_boots"] = BOOTS[int(prof["boots"])]
	p["num"] = int(prof["num"])
	p["foot"] = str(prof["foot"])


## Começa a carreira: monta o mundo do país do jogador e a peneira (dois times de garotos).
static func start(slot: int, prof: Dictionary) -> void:
	var li := home_league(str(prof["nat"]))
	Game.new_career(slot, _stub_coach(), 0, li)
	var S: Dictionary = Game.S
	S["mode"] = "pro"
	S["news"] = []
	S["unread"] = 0
	var teams: Array = []
	var names := [["Peneira Azul", "AZU", "2f6fd6", "f2f2f2"], ["Peneira Branca", "BRA", "f2f2f2", "1c3f8f"]]
	for k in 2:
		var cid: int = S["clubs"].size()
		S["clubs"].append({"id": cid, "name": names[k][0], "short": names[k][1], "c1": names[k][2], "c2": names[k][3], "str": 58,
			"li": li, "ci": -1, "guest": true, "trial": true, "formation": "4-3-3", "xi": [], "titles": 0,
			"pts": 0, "j": 0, "v": 0, "e": 0, "d": 0, "gp": 0, "gc": 0})
		for tp in Game.SQUAD_TEMPLATE.slice(0, 16):
			Game.make_player(tp, Game.rng.randi_range(50, 61), cid, Game.rng.randi_range(16, 19))
		teams.append(cid)
	var ovr_tab: Dictionary = cfg_sec("criacao").get("ovr_por_idade", {})
	var base: int = int(ovr_tab.get(str(prof["age"]), 54))
	var p := Game.make_player(str(prof["pos"]), base + Game.rng.randi_range(-1, 2), teams[0], int(prof["age"]))
	p["name"] = str(prof["name"])
	p["nat"] = str(prof["nat"])
	p["me"] = true
	p["pot"] = Game.rng.randi_range(int(cfg("criacao", "pot_min", 76)), int(cfg("criacao", "pot_max", 92)))
	p["wage"] = 0.0
	p["contract"] = 0
	_apply_look(p, prof)
	S["club"] = teams[0]
	S["pro"] = {
		"me": p["id"], "stage": "peneira", "trial_teams": teams, "scouts": _scouts(li, str(prof["nat"])),
		"fame": 0.0, "followers": 120, "fans": 50.0, "coach": cfg("tecnico", "confianca_inicial", 50), "money": 0.0,
		"agent": "", "offers": [], "feed": [], "next_post": 1, "posted": false, "polemics": 0, "banned": 0,
		"train": "normal", "xp": 0.0, "ratings": [], "season": _blank_season(), "history": [], "awards": [], "titles": [],
		"sponsors": [], "owned": [], "caps": 0, "ngoals": 0, "season_caps": 0, "injury": "", "pending_move": {}, "last": {},
		"negotiated": {}, "season_closed": false, "retired": false,
	}
	for t in teams:
		Game.auto_lineup(t)
	_force_into_xi(teams[0])
	Game.add_news("A peneira", "Hoje tem jogo festivo com olheiros de vários clubes na arquibancada. Capriche: a sua nota decide as propostas.")
	Game.save()


static func _blank_season() -> Dictionary:
	return {"g": 0, "gol": 0, "ass": 0, "sum": 0.0, "best": 0.0, "mvp": 0, "min": 0}


## Olheiros da peneira: clubes do país (de várias divisões) e alguns de fora.
static func _scouts(home_li: int, nat: String) -> Array:
	var pool_home: Array = []
	var pool_abroad: Array = []
	for li in World.LEAGUES.size():
		var lg: Dictionary = World.LEAGUES[li]
		if not signs_from(li):
			continue
		for ci in lg["clubs"].size():
			var it := [li, ci, int(lg["clubs"][ci][4])]
			if lg["country"] == nat:
				pool_home.append(it)
			elif float(lg["prize"]) >= 0.7:
				pool_abroad.append(it)
	Game.rng_shuffle(pool_home)
	Game.rng_shuffle(pool_abroad)
	var n: int = int(cfg("peneira", "olheiros", 6))
	var chosen: Array = []
	# escada de forças: do clube pequeno ao gigante
	pool_home.sort_custom(func(a, b): return a[2] < b[2])
	if not pool_home.is_empty():
		var step: float = float(pool_home.size() - 1) / maxf(float(n - 3), 1.0)
		for k in n - 2:
			var it: Array = pool_home[clampi(int(round(k * step)) + Game.rng.randi_range(-1, 1), 0, pool_home.size() - 1)]
			if not (it in chosen):
				chosen.append(it)
	for it in pool_abroad.slice(0, 2):
		chosen.append(it)
	var out: Array = []
	for it in chosen:
		out.append(_club_info(int(it[0]), int(it[1])))
	out.sort_custom(func(a, b): return int(a["str"]) < int(b["str"]))
	return out


static func _club_info(li: int, ci: int) -> Dictionary:
	var info: Array = World.LEAGUES[li]["clubs"][ci]
	return {"li": li, "ci": ci, "name": DataPack.club_name(li, ci, info[0]), "short": info[1], "c1": info[2], "c2": info[3],
		"str": int(info[4]), "league": DataPack.comp_name(li, World.LEAGUES[li]["name"]), "country": World.LEAGUES[li]["country"]}


static func trial_match() -> Dictionary:
	var t: Array = P()["trial_teams"]
	return {"kind": "trial", "h": t[0], "a": t[1], "comp": "Peneira", "label": "Jogo festivo com olheiros", "day": Game.S["day"]}


## Fim da peneira: nota → propostas dos clubes cujos olheiros gostaram.
static func finish_trial(sim) -> void:
	var t: Array = P()["trial_teams"]
	if sim == null:
		sim = MatchSim.new(t[0], t[1])
	while not sim.finished:
		sim.step()
	var r := rate(sim)
	_store_last(sim, r, "Peneira", "Jogo festivo")
	var need0 := cfg("peneira", "nota_minima_base", 5.6)
	var per := cfg("peneira", "nota_por_ponto_de_forca", 0.075)
	var ref := cfg("peneira", "forca_referencia", 60)
	var offers: Array = []
	var weakest: Dictionary = {}
	for sc in P()["scouts"]:
		if weakest.is_empty() or int(sc["str"]) < int(weakest["str"]):
			weakest = sc
		if r >= need0 + (float(sc["str"]) - ref) * per:
			offers.append(make_offer(int(sc["li"]), int(sc["ci"]), false))
	if offers.is_empty() and not weakest.is_empty():
		var o := make_offer(int(weakest["li"]), int(weakest["ci"]), false)
		o["role"] = "base"
		o["wage"] = snappedf(float(o["wage"]) * 0.6, 0.1)
		o["luvas"] = 0.0
		offers.append(o)
	P()["offers"] = offers
	P()["stage"] = "propostas"
	P()["ratings"].append(r)
	_social_after_match(r, sim)
	Game.add_news("Fim da peneira", "Você tirou nota %.1f. %d clube(s) fizeram proposta." % [r, offers.size()])
	Game.save()


static func _store_last(sim, r: float, comp: String, label: String) -> void:
	var pid: int = P()["me"]
	var g := 0
	var a := 0
	for s in sim.scorers:
		if int(s["pid"]) == pid:
			g += 1
		if int(s.get("apid", 0)) == pid:
			a += 1
	var lu: Dictionary = Game.S.get("last_user", {})
	P()["last"] = {"comp": comp, "label": label, "h": sim.h, "a": sim.a, "hg": sim.score[0], "ag": sim.score[1],
		"rating": r, "gol": g, "ass": a, "min": int(sim.mins.get(pid, 0)), "lances": sim.me["lances"], "on": sim.me["on"],
		"off": sim.me["off"], "lost": sim.me["lost"], "offside": sim.me["offside"], "card": int(sim.cards.get(pid, 0)),
		"red": pid in sim.sent_off, "day": int(lu.get("day", Game.S["day"])), "pens": lu.get("pens", [])}


# ------------------------------------------------------------ partida
## Chamado pelo MatchSim quando o jogo é do seu clube.
static func setup_sim(sim) -> void:
	sim.focus_pid = int(P()["me"])
	sim.focus_side = 0 if sim.h == Game.S["club"] else 1
	Game.last_sim = sim
	if P()["stage"] != "carreira":
		return
	var p := me()
	var xi: Array = Game.club(Game.S["club"])["xi"]
	if p["id"] in xi or int(p.get("susp", 0)) > 0 or int(P()["banned"]) > 0:
		return
	var ch: float = cfg("tecnico", "entra_do_banco_chance", 0.55) * (0.6 + float(P()["coach"]) / 100.0)
	if Game.rng.randf() < ch:
		sim.focus_sub_min = Game.rng.randi_range(55, 80)


## O técnico escala: seu jogador entra se for melhor (com bônus de confiança e fase).
static func pick_lineup() -> void:
	var cid: int = Game.S["club"]
	Game.auto_lineup(cid)
	var p := me()
	var c: Dictionary = Game.club(cid)
	var xi: Array = c["xi"]
	var out: bool = int(p.get("susp", 0)) > 0 or int(P()["banned"]) > 0 or p["club"] != cid
	if out:
		var k := xi.find(p["id"])
		if k >= 0:
			var slots: Array = Game.FORMATIONS[c["formation"]]
			var best = null
			var bv := -1.0
			for q in Game.bench(cid):
				if q["id"] == p["id"]:
					continue
				var v := Game.eff(q, slots[k][0])
				if v > bv:
					bv = v
					best = q
			if best != null:
				xi[k] = best["id"]
		return
	if p["id"] in xi:
		return
	var bonus: float = (float(P()["coach"]) - 50.0) * cfg("tecnico", "bonus_escalacao_por_ponto", 0.08) + (form(3) - 6.5) * 2.0
	var slots2: Array = Game.FORMATIONS[c["formation"]]
	var best_i := -1
	var gain := 0.0
	for i in xi.size():
		var sp: String = slots2[i][0]
		if sp == "GOL" or Game.fit(p["pos"], sp) < 0.93:
			continue
		var d: float = Game.eff(p, sp) + bonus - Game.eff(Game.player(xi[i]), sp)
		if d > gain:
			gain = d
			best_i = i
	if best_i >= 0:
		xi[best_i] = p["id"]


## Situação do seu jogador para o próximo jogo.
static func status_line() -> String:
	var p := me()
	if int(P()["banned"]) > 0:
		return "AFASTADO pela diretoria (%d jogo(s))" % int(P()["banned"])
	if str(P()["injury"]) != "" and int(p.get("susp", 0)) > 0:
		return "LESIONADO: %s (%d jogo(s))" % [P()["injury"], int(p["susp"]) - 1]
	if int(p.get("susp", 0)) > 0:
		return "SUSPENSO"
	if p["id"] in Game.club(Game.S["club"])["xi"]:
		return "TITULAR"
	return "NO BANCO"


## Nota do jogador na partida (−1 = não jogou).
static func rate(sim) -> float:
	var pid: int = P()["me"]
	var mins: int = int(sim.mins.get(pid, 0))
	if mins <= 0:
		return -1.0
	var N := cfg_sec("nota")
	var p := me()
	# força comparada com a do seu time: o garoto de 58 num time de 60 joga"normal"
	var team_ovr: float = float(Game.ratings(Game.S["club"])["ger"])
	var r: float = float(N.get("base", 6.0)) + (float(p["ovr"]) - team_ovr) * float(N.get("por_ponto_ovr", 0.04))
	r += Game.rng.randfn(0.0, float(N.get("ruido", 0.45)))
	for s in sim.scorers:
		if int(s["pid"]) == pid:
			r += float(N.get("gol", 1.1))
		if int(s.get("apid", 0)) == pid:
			r += float(N.get("assistencia", 0.7))
	r += sim.me["on"] * float(N.get("chute_no_gol", 0.15)) + sim.me["lost"] * float(N.get("perdeu_bola", -0.25))
	r += sim.me["offside"] * float(N.get("impedido", -0.15)) + sim.me["off"] * float(N.get("chute_fora", -0.05))
	var sd: int = sim.focus_side
	var mine: int = sim.score[sd]
	var other: int = sim.score[1 - sd]
	if mine > other:
		r += float(N.get("vitoria", 0.35))
	elif mine < other:
		r += float(N.get("derrota", -0.35))
	if p["pos"] in ["ZAG", "LD", "LE", "VOL"]:
		if other == 0:
			r += float(N.get("sem_sofrer_gols_defensor", 0.4))
		else:
			r += maxi(other - 1, 0) * float(N.get("gol_sofrido_defensor", -0.15))
	if pid in sim.sent_off:
		r += float(N.get("vermelho", -1.5))
	elif int(sim.cards.get(pid, 0)) > 0:
		r += float(N.get("amarelo", -0.3))
	if mins < 30:
		r = lerpf(6.0, r, float(mins) / 30.0 * 0.7 + 0.3)
	return snappedf(clampf(r, float(N.get("min", 3.0)), float(N.get("max", 10.0))), 0.1)


## Depois de cada jogo do clube (liga ou copa): nota, fama, treino, lesão, salário, redes, janela, seleção.
static func after_match() -> void:
	if P()["stage"] != "carreira":
		return
	var sim = Game.last_sim
	var lu: Dictionary = Game.S.get("last_user", {})
	if sim == null or lu.is_empty():
		return
	var r := rate(sim)
	_store_last(sim, r, str(lu.get("comp", "")), str(lu.get("label", "")))
	var pr: Dictionary = P()
	var p := me()
	var ss: Dictionary = pr["season"]
	var F := cfg_sec("fama")
	if r >= 0.0:
		ss["g"] += 1
		ss["sum"] += r
		ss["best"] = maxf(float(ss["best"]), r)
		ss["min"] += int(pr["last"]["min"])
		ss["gol"] += int(pr["last"]["gol"])
		ss["ass"] += int(pr["last"]["ass"])
		if r >= 8.0:
			ss["mvp"] += 1
		pr["ratings"].append(r)
		if pr["ratings"].size() > 12:
			pr["ratings"].pop_front()
		pr["coach"] = clampf(float(pr["coach"]) + (r - 6.3) * cfg("tecnico", "por_ponto_de_nota", 4.0), 0.0, 100.0)
		var df := 0.0
		if r >= float(F.get("nota_boa", 7.5)):
			df += float(F.get("ganho_nota_boa", 1.5))
		elif r <= float(F.get("nota_ruim", 5.8)):
			df += float(F.get("perda_nota_ruim", -1.0))
		df += int(pr["last"]["gol"]) * float(F.get("gol", 0.6))
		# fama vale mais em clube grande
		df *= 0.7 + float(Game.my_club()["str"]) / 100.0
		_fame(df)
		pr["xp"] = float(pr["xp"]) + maxf(r - 6.0, 0.0) * cfg("treino", "xp_por_nota", 3.0)
		_injury_roll()
	else:
		pr["coach"] = clampf(float(pr["coach"]) + 0.5, 0.0, 100.0)
	# torcida acompanha o resultado
	var sd: int = sim.focus_side
	var res: int = signi(sim.score[sd] - sim.score[1 - sd])
	pr["fans"] = clampf(float(pr["fans"]) + res * 2.0 + (maxf(r, 6.0) - 6.5) * 2.0 * (1.0 if r >= 0.0 else 0.0), 0.0, 100.0)
	if int(pr["banned"]) > 0:
		pr["banned"] = int(pr["banned"]) - 1
	if int(p.get("susp", 0)) <= 1:
		pr["injury"] = ""
	_train()
	_pay(7)
	_sponsor_roll()
	_social_after_match(r, sim)
	pr["posted"] = false
	pr["replied"] = false
	var nrounds: int = Game.S["fixtures"].size()
	if lu.get("kind", "") == "league":
		var rd: int = Game.S["round"]
		if rd == int(round(nrounds * cfg("janela", "rodada_meio", 0.5))):
			_window("meio")
		for k in cfg_sec("selecao").get("rodadas", []):
			if rd == int(k):
				_national_call()
	if int(pr["last"]["gol"]) >= 3:
		Game.add_news("HAT-TRICK!", "%s marcou %d gols e levou a bola para casa." % [p["name"], pr["last"]["gol"]])
	pick_lineup()
	Game.save()


static func _fame(d: float) -> void:
	var pr: Dictionary = P()
	pr["fame"] = clampf(float(pr["fame"]) + d, 0.0, 100.0)
	var target: int = int(120 + pow(float(pr["fame"]), 1.6) * cfg("fama", "seguidores_por_fama", 9000) / 10.0)
	pr["followers"] = maxi(int(pr["followers"]), int(lerpf(float(pr["followers"]), float(target), 0.35)))


# ------------------------------------------------------------ treino, lesões, dinheiro
static func set_training(kind: String) -> void:
	P()["train"] = kind


static func xp_needed() -> float:
	return cfg("treino", "xp_custo_base", 20) + (float(me()["ovr"]) - 50.0) * cfg("treino", "xp_custo_por_ovr", 1.2)


static func _train() -> void:
	var pr: Dictionary = P()
	var p := me()
	var tk: Dictionary = cfg_sec("treino").get(str(pr["train"]), {"xp": 7, "lesao": 1.0, "energia": 0})
	var gain: float = float(tk.get("xp", 7))
	if int(p["age"]) >= int(cfg("treino", "idade_crescimento_lento", 30)):
		gain *= 0.4
	pr["xp"] = float(pr["xp"]) + gain
	p["energy"] = clampf(float(p["energy"]) + float(tk.get("energia", 0)), 20.0, 100.0)
	while float(pr["xp"]) >= xp_needed() and int(p["ovr"]) < int(p["pot"]):
		pr["xp"] = float(pr["xp"]) - xp_needed()
		p["ovr"] = int(p["ovr"]) + 1
		var keep_wage: float = float(p["wage"])
		Game._price(p)            # atualiza o valor de mercado...
		p["wage"] = keep_wage     # ...mas o salário é o do contrato
		Game.add_news("Evolução!", "%s subiu para %d de força." % [p["name"], p["ovr"]])
	if int(p["ovr"]) >= int(p["pot"]):
		pr["xp"] = minf(float(pr["xp"]), xp_needed())


static func _injury_roll() -> void:
	var p := me()
	var tk: Dictionary = cfg_sec("treino").get(str(P()["train"]), {})
	var ch: float = cfg("lesao", "chance_por_jogo", 0.025) * float(tk.get("lesao", 1.0)) * (1.5 if float(p["energy"]) < 50.0 else 1.0)
	if Game.rng.randf() >= ch:
		return
	var n := Game.rng.randi_range(int(cfg("lesao", "jogos_min", 1)), int(cfg("lesao", "jogos_max", 6)))
	var names := ["Estiramento na coxa", "Entorse no tornozelo", "Lesão muscular", "Pancada no joelho", "Desgaste físico"]
	P()["injury"] = names[mini(n - 1, names.size() - 1)] if n <= names.size() else _pick(names)
	p["susp"] = maxi(int(p.get("susp", 0)), n + 1)
	Game.add_news("Lesão", "%s sofreu %s e desfalca o time por %d jogo(s)." % [p["name"], str(P()["injury"]).to_lower(), n])


## Salário e patrocínios de `days` dias (em milhões; salário em mil por semana).
static func _pay(days: int) -> void:
	var pr: Dictionary = P()
	var weeks: float = days / 7.0
	var sal: float = float(me()["wage"]) / 1000.0 * weeks
	var com: float = float(agent().get("comissao", 0.0))
	var spons := 0.0
	for s in pr["sponsors"]:
		spons += float(s["semanal"]) * weeks
	pr["money"] = float(pr["money"]) + (sal + spons) * (1.0 - com)


static func weekly_income() -> Dictionary:
	var spons := 0.0
	for s in P()["sponsors"]:
		spons += float(s["semanal"])
	var sal: float = float(me()["wage"]) / 1000.0
	var com: float = float(agent().get("comissao", 0.0))
	return {"salario": sal, "patrocinio": spons, "comissao": (sal + spons) * com, "liquido": (sal + spons) * (1.0 - com)}


static func _sponsor_roll() -> void:
	var pr: Dictionary = P()
	var have: Array = []
	for s in pr["sponsors"]:
		have.append(s["marca"])
	for sp in life().get("patrocinadores", []):
		if sp["marca"] in have or float(pr["fame"]) < float(sp["fama_minima"]):
			continue
		var ch: float = 0.06 + 0.06 * agent_level()
		if Game.rng.randf() < ch:
			pr["sponsors"].append({"marca": sp["marca"], "semanal": float(sp["semanal"])})
			Game.add_news("Novo patrocínio", "%s fechou com %s: %s por semana." % [me()["name"], sp["marca"], Game.money(float(sp["semanal"]))])
			_post_portal("%s fecha patrocínio com %s" % [me()["name"], sp["marca"]])
		return


static func buy(id: String) -> String:
	var pr: Dictionary = P()
	for it in life().get("compras", []):
		if it["id"] != id:
			continue
		if id in pr["owned"]:
			return "Você já tem isso."
		if float(pr["money"]) < float(it["preco"]):
			return "Dinheiro insuficiente."
		pr["money"] = float(pr["money"]) - float(it["preco"])
		pr["owned"].append(id)
		_fame(float(it["fama"]))
		pr["fans"] = clampf(float(pr["fans"]) + float(it["torcida"]), 0.0, 100.0)
		_post_mine("Realizei mais um sonho: %s!" % str(it["nome"]).to_lower())
		Game.save()
		return "Comprado: %s" % it["nome"]
	return ""


# ------------------------------------------------------------ rede social
static func _new_post(user: String, text: String, kind: String, likes: int) -> Dictionary:
	var pr: Dictionary = P()
	var post := {"id": int(pr["next_post"]), "user": user, "text": text, "kind": kind, "likes": likes, "reply": "", "reply_kind": "", "day": Game.S["day"]}
	pr["next_post"] = int(pr["next_post"]) + 1
	pr["feed"].push_front(post)
	while pr["feed"].size() > 40:
		pr["feed"].pop_back()
	return post


static func _user() -> String:
	var u: String = _pick(social().get("usuarios", ["torcedor"]))
	var cs: String = str(Game.club(Game.S["club"])["short"]).to_lower()
	return "@" + u.replace("{c}", cs) + (str(Game.rng.randi_range(1, 99)) if Game.rng.randf() < 0.4 else "")


static func _likes(base: float) -> int:
	return int(base * (20.0 + float(P()["followers"]) * Game.rng.randf_range(0.002, 0.02)))


static func _post_portal(text: String) -> void:
	_new_post("@" + str(_pick(social().get("portais", ["PortalDaBola"]))), text, "manchete", _likes(3.0))


static func _post_mine(text: String) -> void:
	_new_post("@" + str(me()["name"]).to_lower().replace("", ""), text, "meu", _likes(2.0))


## Comentários da torcida depois do jogo (nota alta = elogios, nota baixa = xingamentos).
static func _social_after_match(r: float, sim) -> void:
	var S: Dictionary = social()
	var sd: int = sim.focus_side
	var lost: bool = sim.score[sd] < sim.score[1 - sd]
	var won: bool = sim.score[sd] > sim.score[1 - sd]
	if r < 0.0:
		# nem entrou: uma cobrança só (ou zoeira se perdeu)
		var t0: String = _pick(S.get("zoeira_rival", ["..."])) if lost else "Cadê o {n}? Nem entrou em campo..."
		_new_post(_user(), _fmt(t0), "zoeira" if lost else "neutro", _likes(1.0))
		return
	var used: Array = []
	var n := Game.rng.randi_range(2, 4)
	for k in n:
		var kind := "neutro"
		if r >= 7.3:
			kind = "elogio" if Game.rng.randf() < 0.85 else "xingamento"
		elif r < 5.9:
			kind = "xingamento" if Game.rng.randf() < 0.8 else "neutro"
		else:
			kind = ["elogio", "neutro", "xingamento"][Game.rng.randi_range(0, 2)]
		if lost and kind == "neutro" and Game.rng.randf() < 0.4:
			kind = "zoeira"
		var pool: Array = S.get("zoeira_rival" if kind == "zoeira" else kind, ["..."])
		var txt: String = _pick(pool)
		if txt in used:
			continue
		used.append(txt)
		_new_post(_user(), _fmt(txt), kind, _likes(1.0 if kind != "xingamento" else 1.6))
	if r >= 8.0 or (won and r >= 7.5):
		_post_portal(_fmt(_pick(S.get("manchete_boa", ["{n} brilha"]))))


static func can_reply(post: Dictionary) -> bool:
	return str(post["reply"]) == "" and post["kind"] in ["xingamento", "neutro", "zoeira", "elogio"]


## Responder um comentário. Devolve o resumo do que aconteceu.
static func reply(post_id: int, style: String) -> String:
	var pr: Dictionary = P()
	var post: Dictionary = {}
	for x in pr["feed"]:
		if int(x["id"]) == post_id:
			post = x
	if post.is_empty() or not can_reply(post):
		return ""
	var R: Dictionary = cfg_sec("redes").get("respostas", {}).get(style, {})
	var texts: Array = social().get("respostas", {}).get(style, ["..."])
	post["reply"] = "Ignorado" if style == "ignorar" else str(_pick(texts))
	post["reply_kind"] = style
	if style == "ignorar":
		Game.save()
		return "Você ignorou."
	var mult: float = 1.6 if post["kind"] == "elogio" and style != "humilde" else 1.0   # responder elogio com grosseria pega pior
	var fame_d: float = float(R.get("fama", 0.0))
	if fame_d > 0.0 and bool(pr.get("replied", false)):
		fame_d = 0.0   # só a primeira resposta boa de cada jogo rende fama (evita farmar)
	if fame_d > 0.0:
		pr["replied"] = true
	_fame(fame_d * (1.0 if fame_d > 0.0 else mult))
	pr["fans"] = clampf(float(pr["fans"]) + float(R.get("torcida", 0.0)) * mult, 0.0, 100.0)
	pr["coach"] = clampf(float(pr["coach"]) + float(R.get("tecnico", 0.0)), 0.0, 100.0)
	pr["followers"] = int(pr["followers"]) + int(float(pr["followers"]) * float(R.get("seguidores", 0.0)) + Game.rng.randi_range(0, 30))
	post["likes"] = int(post["likes"]) + _likes(1.0 + float(R.get("seguidores", 0.0)) * 40.0)
	var out: Array = []
	if Game.rng.randf() < float(R.get("multa", 0.0)) * mult:
		var fine: float = float(me()["wage"]) / 1000.0 * cfg("redes", "multa_salarios_semanas", 2)
		pr["money"] = float(pr["money"]) - fine
		pr["polemics"] = int(pr["polemics"]) + 1
		Game.add_news("Multa do clube", "A diretoria multou %s em %s pela resposta nas redes." % [me()["name"], Game.money(fine)])
		_post_portal(_fmt(_pick(social().get("manchete_polemica", ["{n} causa polêmica"]))))
		out.append("Multa de %s" % Game.money(fine))
		if int(pr["polemics"]) >= int(cfg("redes", "polemicas_para_afastamento", 3)):
			pr["polemics"] = 0
			pr["banned"] = int(cfg("redes", "jogos_afastado", 2))
			pick_lineup()
			Game.add_news("Afastado!", "Depois de mais uma polêmica, %s foi afastado por %d jogos." % [me()["name"], pr["banned"]])
			out.append("AFASTADO por %d jogos" % pr["banned"])
	if not pr["sponsors"].is_empty() and Game.rng.randf() < float(R.get("patrocinio", 0.0)) * mult:
		var lost: Dictionary = pr["sponsors"].pop_at(Game.rng.randi_range(0, pr["sponsors"].size() - 1))
		Game.add_news("Patrocínio cancelado", "%s rompeu o contrato com %s após a confusão." % [lost["marca"], me()["name"]])
		out.append("%s cancelou o patrocínio" % lost["marca"])
	Game.save()
	if out.is_empty():
		return {"humilde": "A torcida gostou da humildade.", "provocar": "Viralizou! Mais seguidores.", "xingar": "Viralizou... e pegou mal."}.get(style, "")
	return " • ".join(out)


static func own_post(id: String) -> String:
	var pr: Dictionary = P()
	if bool(pr["posted"]):
		return "Você já postou desde o último jogo."
	for it in social().get("posts_proprios", []):
		if it["id"] != id:
			continue
		pr["posted"] = true
		_post_mine(str(it["texto"]))
		_fame(float(it["fama"]))
		pr["fans"] = clampf(float(pr["fans"]) + float(it["torcida"]), 0.0, 100.0)
		pr["coach"] = clampf(float(pr["coach"]) + float(it["tecnico"]), 0.0, 100.0)
		pr["followers"] = int(pr["followers"]) + int(float(pr["followers"]) * float(it["seguidores"]))
		var msg := "Postado!"
		if id == "sair":
			var n := _window("pedido")
			msg = "Seu pedido repercutiu: %d proposta(s) chegaram." % n
			_post_portal("%s pede para sair do %s" % [me()["name"], Game.club_name(Game.S["club"])])
		elif id == "indireta":
			_post_portal("Clima pesado? %s manda indireta para o técnico" % me()["name"])
		elif id == "festa" and Game.rng.randf() < 0.35:
			pr["polemics"] = int(pr["polemics"]) + 1
			_post_portal("%s é flagrado em balada na véspera de jogo" % me()["name"])
			msg = "A foto vazou na imprensa..."
		Game.save()
		return msg
	return ""


# ------------------------------------------------------------ empresário, propostas e contratos
static func hire(id: String) -> String:
	for a in life().get("empresarios", []):
		if a["id"] == id:
			if float(P()["fame"]) < float(a["fama_minima"]):
				return "%s só trabalha com quem tem fama %d+." % [a["nome"], int(a["fama_minima"])]
			P()["agent"] = id
			Game.add_news("Novo empresário", "%s agora cuida da carreira de %s." % [a["nome"], me()["name"]])
			Game.save()
			return "%s contratado!" % a["nome"]
	return ""


static func fire_agent() -> void:
	P()["agent"] = ""
	Game.save()


## Proposta de um clube (li, ci) para o seu jogador.
static func make_offer(li: int, ci: int, renewal: bool) -> Dictionary:
	var o := _club_info(li, ci)
	var p := me()
	var ovr: int = int(p["ovr"])
	var st: int = int(o["str"])
	var gap: int = ovr - (st - 6)
	var role := "titular"
	if gap < -12:
		role = "base"
	elif gap < -6:
		role = "reserva"
	elif gap < 0:
		role = "rotacao"
	var wage: float = pow(maxf(float(ovr) - 48.0, 2.0), 2.0) * 0.07 * (0.55 + float(st) / 110.0)
	wage *= (1.0 + float(agent().get("aumento_salario", 0.0))) * (1.0 + float(P()["fame"]) / 220.0)
	wage *= Game.rng.randf_range(0.9, 1.15)
	var luvas := 0.0
	if float(P()["fame"]) > 8.0 or ovr >= 62:
		luvas = wage * 52.0 / 1000.0 * Game.rng.randf_range(0.1, 0.45)
	o["role"] = role
	o["wage"] = snappedf(maxf(wage, 1.0), 0.1)
	o["years"] = Game.rng.randi_range(2, 5) if not renewal else Game.rng.randi_range(2, 4)
	o["luvas"] = snappedf(luvas, 0.01)
	o["clause"] = snappedf(maxf(float(p["value"]), 0.2) * Game.rng.randf_range(2.0, 4.0), 0.1)
	o["renewal"] = renewal
	o["id"] = Game.rng.randi()
	return o


## Janela de transferências: o empresário traz propostas (sem empresário, chegam poucas e de perto).
static func _window(why: String) -> int:
	var pr: Dictionary = P()
	var lvl := agent_level()
	var n: int = int(cfg("janela", "propostas_sem_empresario", 1)) + lvl * int(cfg("janela", "propostas_por_nivel_empresario", 1))
	if why == "pedido":
		n += 1
	var p := me()
	var my_country: String = World.LEAGUES[int(Game.S["league"])]["country"]
	var lo: int = int(p["ovr"]) - 10
	var hi: int = int(p["ovr"]) + 4 + int(float(pr["fame"]) / 12.0) + lvl * 2
	var pool: Array = []
	for li in World.LEAGUES.size():
		var lg: Dictionary = World.LEAGUES[li]
		var abroad: bool = lg["country"] != my_country
		if not signs_from(li):
			continue
		if abroad and lvl < 2 and not (lvl == 1 and float(lg["prize"]) < 1.0):
			continue
		if abroad and lvl < 3 and float(lg["prize"]) >= 1.6 and float(pr["fame"]) < 30.0:
			continue
		for ci in lg["clubs"].size():
			var st: int = int(lg["clubs"][ci][4])
			if st < lo or st > hi:
				continue
			if li == int(Game.S["league"]) and ci == Game.S["club"]:
				continue
			pool.append([li, ci])
	Game.rng_shuffle(pool)
	var made := 0
	for it in pool.slice(0, n):
		if pr["offers"].size() >= 6:
			break
		var o := make_offer(int(it[0]), int(it[1]), false)
		pr["offers"].append(o)
		made += 1
		Game.add_news("Proposta do %s" % o["name"], "%s (%s) quer %s: %s, salário %s/sem por %d anos." % [o["name"], o["league"], me()["name"],
			role_name(o["role"]), _k(o["wage"]), o["years"]])
	if made > 0:
		_post_portal("%s na mira de %d clube(s)" % [me()["name"], made])
	return made


static func _k(wage_k: float) -> String:
	return "$ %.1f mil" % wage_k


## Pedir mais dinheiro. Empresário melhor = mais chance.
static func negotiate(idx: int) -> String:
	var pr: Dictionary = P()
	if idx < 0 or idx >= pr["offers"].size():
		return ""
	var o: Dictionary = pr["offers"][idx]
	var key := str(o["id"])
	var tries: int = int(pr["negotiated"].get(key, 0))
	var ch: float = 0.4 + agent_level() * 0.15 - tries * 0.25
	pr["negotiated"][key] = tries + 1
	if Game.rng.randf() < ch:
		o["wage"] = snappedf(float(o["wage"]) * Game.rng.randf_range(1.1, 1.22), 0.1)
		o["luvas"] = snappedf(float(o["luvas"]) * 1.25 + 0.01, 0.01)
		Game.save()
		return "O clube aceitou melhorar: %s/sem." % _k(o["wage"])
	var must_choose: bool = pr["stage"] in ["propostas", "livre"] and pr["offers"].size() <= 1
	if not must_choose and Game.rng.randf() < 0.45 + tries * 0.2:
		pr["offers"].remove_at(idx)
		Game.save()
		return "O %s se irritou e retirou a proposta." % o["name"]
	Game.save()
	return "O %s manteve a proposta." % o["name"]


static func reject(idx: int) -> void:
	if idx >= 0 and idx < P()["offers"].size():
		P()["offers"].remove_at(idx)
		Game.save()


## Aceitar proposta. Mesma liga = muda na hora; outra liga = no fim da temporada (ou já, se for a primeira).
static func accept(idx: int) -> String:
	var pr: Dictionary = P()
	if idx < 0 or idx >= pr["offers"].size():
		return ""
	var o: Dictionary = pr["offers"][idx]
	pr["offers"] = []
	var com: float = float(agent().get("comissao", 0.0))
	var pay_luvas := func() -> void:
		pr["money"] = float(pr["money"]) + float(o["luvas"]) * (1.0 - com)
	if o.get("renewal", false):
		pay_luvas.call()
		var p := me()
		p["wage"] = o["wage"]
		p["contract"] = o["years"]
		pr["clause"] = o["clause"]
		Game.add_news("Renovado!", "%s renovou com o %s até %d." % [p["name"], o["name"], int(Game.S["year"]) + int(o["years"])])
		Game.save()
		return "Contrato renovado!"
	if pr["stage"] in ["propostas", "livre"]:
		pay_luvas.call()
		move_to(o, pr["stage"] == "livre")
		return "Bem-vindo ao %s!" % o["name"]
	if int(o["li"]) == int(Game.S["league"]) and not Game.S["season_over"]:
		pay_luvas.call()
		_transfer_same_league(o)
		return "Transferência fechada: você já é do %s." % o["name"]
	pr["pending_move"] = o
	Game.add_news("Acerto fechado", "%s vai para o %s no fim da temporada." % [me()["name"], o["name"]])
	Game.save()
	return "Acerto fechado! Você se apresenta ao %s no fim da temporada." % o["name"]


static func _sign_terms(p: Dictionary, o: Dictionary) -> void:
	p["wage"] = float(o["wage"])
	p["contract"] = int(o["years"])
	p["joined"] = Game.S["season"]
	p["cmin"] = 0
	p["cgol"] = 0
	p["cass"] = 0
	p["titles"] = []
	P()["clause"] = o["clause"]
	P()["coach"] = {"titular": 60.0, "rotacao": 50.0, "reserva": 42.0, "base": 35.0}.get(o["role"], 50.0)


static func _transfer_same_league(o: Dictionary) -> void:
	var p := me()
	var old: int = Game.S["club"]
	var cid: int = int(o["ci"])
	p["club"] = cid
	_sign_terms(p, o)
	Game._log_transfer(p, old, cid, float(p["value"]))
	Game.S["club"] = cid
	Game.auto_lineup(old)
	pick_lineup()
	Game.add_news("Novo clube", "%s foi apresentado no %s." % [p["name"], o["name"]])
	_post_mine("Novo capítulo! Feliz demais de vestir essa camisa")
	_post_portal("%s acerta com o %s" % [p["name"], o["name"]])
	Game.save()


## Muda de liga: monta o mundo da nova liga (mesmo ano ou o próximo) e leva o jogador junto.
static func move_to(o: Dictionary, next_year: bool) -> void:
	if next_year and not P()["pending_move"].is_empty() and P()["pending_move"].get("id", 0) == o.get("id", -1):
		P()["money"] = float(P()["money"]) + float(o["luvas"]) * (1.0 - float(agent().get("comissao", 0.0)))
	var pro: Dictionary = P().duplicate(true)
	var mep: Dictionary = me().duplicate(true)
	if next_year:
		# virada de temporada também ao trocar de liga: um ano mais velho, números zerados
		mep["age"] = int(mep["age"]) + 1
		if int(mep["age"]) > 31:
			mep["ovr"] = maxi(int(mep["ovr"]) - Game.rng.randi_range(0, 2), 40)
		for k in ["g", "min", "gol", "ass"]:
			mep[k] = 0
		pro["season"] = _blank_season()
		pro["season_caps"] = 0
	var year: int = int(Game.S["year"]) + (1 if next_year else 0)
	var season: int = int(Game.S["season"]) + (1 if next_year else 0)
	var slot: int = Game.slot
	var li: int = int(o["li"])
	var ci: int = int(o["ci"])
	Game.new_career(slot, _stub_coach(), ci, li, year)
	var S: Dictionary = Game.S
	S["mode"] = "pro"
	S["season"] = season
	S["news"] = []
	S["unread"] = 0
	# abre espaço no elenco: sai o mais fraco da mesma posição
	var same: Array = Game.squad(ci).filter(func(q): return q["pos"] == mep["pos"])
	same.sort_custom(func(a, b): return a["ovr"] < b["ovr"])
	if same.size() > 1:
		same[0]["club"] = Game.FREE
	mep["id"] = S["next_id"]
	S["next_id"] = int(S["next_id"]) + 1
	mep["club"] = ci
	mep["susp"] = 0 if str(pro.get("injury", "")) == "" else int(mep.get("susp", 0))
	S["players"][mep["id"]] = mep
	pro["me"] = mep["id"]
	pro["stage"] = "carreira"
	pro["offers"] = []
	pro["pending_move"] = {}
	pro["season_closed"] = false
	pro["trial_teams"] = []
	S["pro"] = pro
	_sign_terms(mep, o)
	Game._price(mep)
	mep["wage"] = float(o["wage"])
	pick_lineup()
	Game.add_news("Bem-vindo ao %s" % o["name"], "%s assinou por %d anos (%s). Salário de %s por semana." % [mep["name"], o["years"],
		role_name(o["role"]), _k(o["wage"])])
	_post_mine("Contrato assinado com o %s! Obrigado, Deus e família" % o["name"])
	_post_portal("%s é o novo reforço do %s" % [mep["name"], o["name"]])
	Game.save()


# ------------------------------------------------------------ seleção
static func _national_call() -> void:
	var pr: Dictionary = P()
	var p := me()
	var S := cfg_sec("selecao")
	var ok: bool = int(p["ovr"]) >= int(S.get("ovr_garantido", 80)) or \
		(int(p["ovr"]) >= int(S.get("ovr_minimo", 74)) and form(5) >= float(S.get("nota_media_minima", 6.8)))
	if not ok or str(pr["injury"]) != "":
		return
	var w: float = {"AC": 0.45, "PD": 0.3, "PE": 0.3, "MEI": 0.22, "VOL": 0.08, "LD": 0.06, "LE": 0.06, "ZAG": 0.07}.get(p["pos"], 0.1)
	var g := 0
	for k in 2:
		if Game.rng.randf() < w:
			g += 1
	pr["caps"] = int(pr["caps"]) + 2
	pr["season_caps"] = int(pr.get("season_caps", 0)) + 2
	pr["ngoals"] = int(pr["ngoals"]) + g
	_fame(cfg("fama", "convocacao", 3.0))
	Game.add_news("Convocado!", "%s foi chamado para a seleção do(a) %s. Fez %d gol(s) nos dois amistosos." % [p["name"], p["nat"], g])
	_post_portal("%s é convocado para a seleção" % p["name"])
	_post_mine("Sonho realizado! Vestir a camisa do meu país" if p["nat"] == "Brasil" else "Orgulho de defender meu país!")


# ------------------------------------------------------------ fim de temporada
## Fecha a temporada uma vez: prêmios, títulos, histórico, contrato. Devolve o resumo.
static func close_season() -> Dictionary:
	var pr: Dictionary = P()
	if bool(pr["season_closed"]):
		return pr.get("season_report", {})
	pr["season_closed"] = true
	var p := me()
	var ss: Dictionary = pr["season"]
	var avg := avg_rating()
	var sm: Dictionary = Game.season_summary()
	var awards: Array = []
	var titles: Array = []
	var year: int = Game.S["year"]
	if int(sm["champion"]) == Game.S["club"]:
		titles.append(Game.LEAGUE)
	for t in Game.S["trophies"]:
		if int(t["year"]) == year and t["name"] != Game.LEAGUE and not (t["name"] in titles):
			titles.append(t["name"])
	for t in titles:
		pr["titles"].append({"name": t, "year": year, "club": Game.club_name(Game.S["club"])})
		_fame(cfg("fama", "titulo", 6.0))
	var top = sm["top"]
	if top != null and int(top["id"]) == int(p["id"]):
		awards.append("Artilheiro do %s" % Game.LEAGUE)
	if int(ss["g"]) >= 15 and avg >= 7.4:
		awards.append("Seleção do campeonato")
	if int(p["age"]) <= 21 and int(ss["g"]) >= 12 and avg >= 6.9:
		awards.append("Revelação do ano")
	# Bola de Ouro
	var bola := ""
	if float(pr["fame"]) >= 70.0 and avg >= 7.6 and int(ss["gol"]) + int(ss["ass"]) >= 25:
		awards.append("Bola de Ouro")
		bola = str(p["name"])
	else:
		var best = null
		for q in Game.S["players"].values():
			if q.get("me", false) or int(q["club"]) < 0:
				continue
			if best == null or int(q["ovr"]) * 2 + int(q["gol"]) > int(best["ovr"]) * 2 + int(best["gol"]):
				best = q
		if best != null:
			bola = "%s (%s)" % [best["name"], Game.club_name(int(best["club"]))]
	# Copa do Mundo (anos pares de 4 em 4, se você está na seleção)
	var wc := ""
	if year % 4 == 2 and int(pr.get("season_caps", 0)) > 0:
		var ch: float = 0.14 if p["nat"] in BIG_NATIONS else 0.04
		var stage: Array = ["fase de grupos", "oitavas", "quartas", "semifinal", "final"]
		var reached := 0
		while reached < 4 and Game.rng.randf() < (0.55 if p["nat"] in BIG_NATIONS else 0.35) + 0.08 * reached:
			reached += 1
		if reached == 4 and Game.rng.randf() < ch / 0.14 * 0.5:
			wc = "CAMPEÃO DA COPA DO MUNDO!"
			titles.append("Copa do Mundo")
			pr["titles"].append({"name": "Copa do Mundo", "year": year, "club": "Seleção do(a) %s" % p["nat"]})
			_fame(15.0)
		else:
			wc = "Copa do Mundo: eliminado na %s" % stage[reached]
	for a in awards:
		pr["awards"].append({"name": a, "year": year})
		_fame(cfg("fama", "premio", 8.0) * (2.0 if a == "Bola de Ouro" else 0.5))
	# a fama esfria um pouco a cada ano (precisa continuar jogando bem)
	pr["fame"] = float(pr["fame"]) * (1.0 - cfg("fama", "queda_anual", 0.12))
	pr["history"].append({"year": year, "club": Game.club_name(Game.S["club"]), "league": Game.LEAGUE, "g": ss["g"], "gol": ss["gol"],
		"ass": ss["ass"], "avg": snappedf(avg, 0.01), "ovr": p["ovr"]})
	# contrato
	p["contract"] = int(p["contract"]) - 1
	var contract_msg := ""
	if pr["pending_move"].is_empty():
		if int(p["contract"]) <= 0:
			contract_msg = "Seu contrato acabou. Você está livre no mercado."
			pr["stage"] = "livre"
			pr["offers"] = []
			_window("pedido")
			if pr["offers"].is_empty():
				pr["offers"].append(make_offer(int(Game.S["league"]), mini(Game.S["club"], Game.n_league() - 1), false))
		elif int(p["contract"]) == 1 and float(pr["coach"]) >= 35.0:
			var ro := make_offer(int(Game.S["league"]), Game.S["club"], true)
			pr["offers"].append(ro)
			contract_msg = "O clube ofereceu renovação (veja Empresário > Propostas)."
	else:
		contract_msg = "Você se apresenta ao %s na próxima temporada." % pr["pending_move"]["name"]
	_window("fim")
	var rep := {"year": year, "g": ss["g"], "gol": ss["gol"], "ass": ss["ass"], "avg": avg, "mvp": ss["mvp"], "awards": awards,
		"titles": titles, "bola": bola, "wc": wc, "contract": contract_msg, "pos": sm["pos"], "champion": Game.club_name(int(sm["champion"]))}
	pr["season_report"] = rep
	Game.save()
	return rep


## Começa a próxima temporada (no mesmo clube ou no novo).
static func next_season() -> void:
	var pr: Dictionary = P()
	var mv: Dictionary = pr["pending_move"]
	pr["season"] = _blank_season()
	pr["season_caps"] = 0
	pr["season_closed"] = false
	if not mv.is_empty():
		move_to(mv, true)
	else:
		Game.new_season()
		pr["coach"] = clampf(float(pr["coach"]), 30.0, 100.0)
		pick_lineup()
	P()["offers"] = P()["offers"].filter(func(o): return not o.get("renewal", false) or int(me()["contract"]) <= 1)
	Game.save()


static func can_retire() -> bool:
	return int(me()["age"]) >= 33


static func retire() -> void:
	P()["retired"] = true
	P()["stage"] = "aposentado"
	Game.add_news("Fim de carreira", "%s pendurou as chuteiras." % me()["name"])
	Game.save()


## Garante o seu jogador entre os titulares do time (peneira).
static func _force_into_xi(cid: int) -> void:
	var c: Dictionary = Game.club(cid)
	var xi: Array = c["xi"]
	var p := me()
	if p["id"] in xi:
		return
	var slots: Array = Game.FORMATIONS[c["formation"]]
	var best := 0
	var bf := -1.0
	for i in slots.size():
		var f := Game.fit(p["pos"], slots[i][0])
		if slots[i][0] != "GOL" and f > bf:
			bf = f
			best = i
	xi[best] = p["id"]
