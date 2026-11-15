class_name MatchSim
extends RefCounted
## Simulação de uma partida, minuto a minuto.
## Chame step() 90 vezes (ou até finished ficar true).
## Inclui o árbitro: faltas, cartões, expulsões, impedimentos e pênaltis.
## Números do árbitro: assets/data/match_tuning.json (seção "arbitro").

var h: int
var a: int
var score: Array = [0, 0]
var minute: int = 0
var finished: bool = false
var att: Array = [0, 0]      # jogadas de ataque
var shots: Array = [0, 0]    # chutes ao gol
var poss: Array = [0, 0]     # minutos com a bola
var scorers: Array = []      # {min, side, pid, name, apid, aname}
var r: Array = []            # notas dos dois times
var mins: Dictionary = {}    # minutos jogados por jogador
var subs: Array = [0, 0]
var out: Array = []          # quem já saiu não volta
var orig_xi: Array = []
var ball: Vector2 = Vector2(0.5, 0.5)
var interactive: bool = false   # true = as chances viram lances jogados em campo
var pending: Dictionary = {}
var fouls: Array = [0, 0]          ## faltas cometidas
var yellows: Array = [0, 0]        ## cartões amarelos
var reds: Array = [0, 0]           ## expulsões
var offsides: Array = [0, 0]       ## impedimentos
var cards: Dictionary = {}         ## pid -> amarelos nesta partida
var sent_off: Array = []           ## pids expulsos
var penalty_scored: bool = false   ## resultado sorteado do pênalti da máquina
var penalties: Array = [0, 0]
var last_side: int = 0           ## quem ficou com a bola no último minuto (para o campo ao vivo)
# --- modo carreira de jogador (src/pro_career.gd)
var focus_pid: int = -1          ## seu jogador; -1 = modo técnico
var focus_side: int = -1
var focus_sub_min: int = -1      ## minuto em que o técnico te coloca (se começou no banco)
var me: Dictionary = {"lances": 0, "on": 0, "off": 0, "lost": 0, "offside": 0}

const SCORE_W := {"AC": 8.0, "PD": 5.5, "PE": 5.5, "MEI": 4.0, "VOL": 1.6, "LD": 0.8, "LE": 0.8, "ZAG": 0.9, "GOL": 0.0}
const ASSIST_W := {"AC": 3.0, "PD": 6.0, "PE": 6.0, "MEI": 6.5, "VOL": 3.0, "LD": 3.0, "LE": 3.0, "ZAG": 0.8, "GOL": 0.2}


func _init(home: int, away: int) -> void:
	h = home
	a = away
	Game.validate_xi(h)
	Game.validate_xi(a)
	orig_xi = [Game.club(h)["xi"].duplicate(), Game.club(a)["xi"].duplicate()]
	if Pro.is_pro() and (h == Game.S["club"] or a == Game.S["club"]):
		Pro.setup_sim(self)
	refresh()


func refresh() -> void:
	r = [Game.ratings(h), Game.ratings(a)]
	# cada expulsão deixa o time mais fraco
	var loss := Tuning.f("arbitro", "perda_forca_expulsao", 0.09)
	for side in 2:
		if reds[side] > 0:
			var f := maxf(1.0 - loss * reds[side], 0.6)
			for k in ["def", "mei", "atq", "ger"]:
				r[side][k] = int(round(float(r[side][k]) * f))


## Jogador expulso não participa mais da partida.
func is_out_of_play(pid: int) -> bool:
	return pid in sent_off


func add_foul(side: int) -> void:
	fouls[side] += 1


## Dá um cartão. Devolve true se o jogador foi expulso (vermelho ou segundo amarelo).
func give_card(side: int, pid: int, color: String) -> bool:
	if pid in sent_off:
		return false
	if color == "amarelo":
		cards[pid] = int(cards.get(pid, 0)) + 1
		yellows[side] += 1
		if int(cards[pid]) < 2:
			return false
	sent_off.append(pid)
	reds[side] += 1
	refresh()
	return true


func cid(side: int) -> int:
	return h if side == 0 else a


func possession(side: int) -> int:
	var t: int = poss[0] + poss[1]
	if t == 0:
		return 50
	var ph := int(round(100.0 * poss[0] / t))
	return ph if side == 0 else 100 - ph


func _pick(side: int, weights: Dictionary, skip: int = -1) -> Dictionary:
	var xi: Array = Game.club(cid(side))["xi"]
	var total := 0.0
	var ws: Array = []
	for pid in xi:
		var p: Dictionary = Game.player(pid)
		var w: float = 0.0 if pid == skip or pid in sent_off else float(weights[p["pos"]]) * pow(float(p["ovr"]) / 70.0, 2.0)
		ws.append(w)
		total += w
	var x := Game.rng.randf() * total
	if total <= 0.0:
		return Game.player(xi[0])
	for i in xi.size():
		x -= ws[i]
		if x <= 0.0:
			return Game.player(xi[i])
	return Game.player(xi[xi.size() - 1])


func step() -> Array:
	# devolve os lances do minuto: {type: "goal"/"chance", side, text, ...}
	var ev: Array = []
	if finished:
		return ev
	minute += 1
	if minute == focus_sub_min:
		var sub_txt := _focus_sub()
		if sub_txt != "":
			ev.append({"type": "sub", "side": focus_side, "text": sub_txt, "min": minute})
	for side in 2:
		for pid in Game.club(cid(side))["xi"]:
			if not (pid in sent_off):
				mins[pid] = int(mins.get(pid, 0)) + 1
	# árbitro: faltas no meio-campo (com chance de cartão)
	var fpm := Tuning.f("arbitro", "faltas_por_minuto_por_time", 0.13)
	for fs in 2:
		if Game.rng.randf() < fpm:
			ev.append_array(_midfield_foul(fs))
	var mh: float = float(r[0]["mei"]) * 1.03
	var ma: float = float(r[1]["mei"])
	var side := 0 if Game.rng.randf() < mh / (mh + ma) else 1
	poss[side] += 1
	last_side = side
	ball = Vector2(0.5 + (0.12 if side == 0 else -0.12) + Game.rng.randf_range(-0.1, 0.1), Game.rng.randf_range(0.2, 0.8))
	if Game.rng.randf() < 0.30:
		att[side] += 1
		var o := 1 - side
		var ratio: float = float(r[side]["atq"]) / maxf(float(r[o]["def"]), 1.0)
		if side == 0:
			ratio *= 1.04
		ball = Vector2(0.86 if side == 0 else 0.14, Game.rng.randf_range(0.3, 0.7))
		var cname: String = Game.club(cid(side))["name"]
		# modo jogador: só viram lance em campo as jogadas do seu time em que você participa
		var live: bool = interactive and (focus_pid < 0 or side == focus_side)
		if not live and Game.rng.randf() < Tuning.f("arbitro", "chance_impedimento_ataque_simulado", 0.06):
			offsides[side] += 1
			ev.append({"type": "chance", "side": side, "text": "Impedimento marcado contra o %s." % cname, "min": minute})
		elif not live and Game.rng.randf() < Tuning.f("arbitro", "chance_penalti_ataque_simulado", 0.022):
			ev.append_array(_sim_penalty(side))
		elif Game.rng.randf() < clampf(0.36 * ratio, 0.1, 0.7):
			shots[side] += 1
			var pg: float = clampf(0.26 * pow(ratio, 1.6), 0.08, 0.6)
			if live and focus_pid >= 0 and not focus_involved():
				live = false
			if live:
				if focus_pid >= 0:
					me["lances"] += 1
				pending = {"side": side, "pg": pg}
				ev.append({"type": "lance", "side": side, "text": "", "min": minute})
			else:
				var sc := _pick(side, SCORE_W)
				if Game.rng.randf() < pg:
					var apid := 0
					if Game.rng.randf() < 0.72:
						apid = _pick(side, ASSIST_W, sc["id"])["id"]
					ev.append(_goal(side, sc["id"], apid))
				else:
					var opts := ["%s finaliza e o goleiro defende!", "%s chuta por cima do gol.", "%s bate cruzado, raspa a trave!", "%s cabeceia para fora."]
					ev.append({"type": "chance", "side": side, "text": opts[Game.rng.randi_range(0, opts.size() - 1)] % sc["name"], "min": minute})
		elif Game.rng.randf() < 0.35:
			var opts2 := ["%s chega com perigo, mas a zaga corta.", "Boa troca de passes do %s.", "%s pressiona a saída de bola."]
			ev.append({"type": "chance", "side": side, "text": opts2[Game.rng.randi_range(0, opts2.size() - 1)] % cname, "min": minute})
	if minute >= 90:
		finished = true
	return ev


func _goal(side: int, pid: int, apid: int) -> Dictionary:
	var sc: Dictionary = Game.player(pid)
	var cname: String = Game.club(cid(side))["name"]
	score[side] += 1
	var g := {"min": minute, "side": side, "pid": pid, "name": sc["name"], "apid": 0, "aname": ""}
	var txt := "GOL do %s! %s marca." % [cname, sc["name"]]
	if apid > 0:
		g["apid"] = apid
		g["aname"] = Game.player(apid)["name"]
		txt = "GOL do %s! %s marca com passe de %s." % [cname, sc["name"], g["aname"]]
	scorers.append(g)
	ball = Vector2(0.98 if side == 0 else 0.02, 0.5)
	return {"type": "goal", "side": side, "text": txt, "name": sc["name"], "min": minute}


## Falta de um jogador do time fs no meio-campo.
func _midfield_foul(fs: int) -> Array:
	var out_ev: Array = []
	fouls[fs] += 1
	var ref := Referee.new(Game.rng)
	var color := ref.card_for_foul()
	if color == "":
		return out_ev
	var p := _pick(fs, {"AC": 1.0, "PD": 1.0, "PE": 1.0, "MEI": 1.6, "VOL": 2.4, "LD": 1.8, "LE": 1.8, "ZAG": 2.2, "GOL": 0.05})
	# quem já tem amarelo pega mais leve
	if color == "amarelo" and int(cards.get(p["id"], 0)) > 0 and Game.rng.randf() < Tuning.f("arbitro", "cuidado_com_amarelo", 0.75):
		return out_ev
	var off := give_card(fs, p["id"], color)
	var txt := "Cartão amarelo para %s (%s)." % [p["name"], Game.club(cid(fs))["short"]]
	if off:
		txt = "EXPULSO! %s (%s) recebe o vermelho." % [p["name"], Game.club(cid(fs))["short"]]
	out_ev.append({"type": "card", "side": fs, "text": txt, "min": minute, "red": off})
	return out_ev


## Pênalti no jogo simulado (sem lance em campo).
func _sim_penalty(side: int) -> Array:
	var o := 1 - side
	fouls[o] += 1
	penalties[side] += 1
	var ev: Array = []
	var ref := Referee.new(Game.rng)
	var color := ref.card_for_foul()
	if color != "":
		var d := _pick(o, {"AC": 0.1, "PD": 0.2, "PE": 0.2, "MEI": 0.6, "VOL": 1.5, "LD": 1.5, "LE": 1.5, "ZAG": 3.0, "GOL": 0.6})
		var off := give_card(o, d["id"], color)
		ev.append({"type": "card", "side": o, "text": ("EXPULSO! %s comete o pênalti." if off else "Amarelo para %s no lance do pênalti.") % d["name"], "min": minute, "red": off})
	var taker := _pick(side, SCORE_W)
	shots[side] += 1
	if Game.rng.randf() < Tuning.f("arbitro", "chance_gol_penalti_simulado", 0.76):
		var g := _goal(side, taker["id"], 0)
		g["text"] = "PÊNALTI! " + g["text"]
		ev.append(g)
	else:
		ev.append({"type": "chance", "side": side, "text": "PÊNALTI para o %s... %s perde!" % [Game.club(cid(side))["name"], taker["name"]], "min": minute})
	return ev


## Resultado sorteado para o lance da máquina (mantém o equilíbrio do jogo).
func lance_script() -> String:
	var pen := Tuning.f("arbitro", "chance_penalti_ataque_simulado", 0.022) * 4.0
	if Game.rng.randf() < pen:
		penalty_scored = Game.rng.randf() < Tuning.f("arbitro", "chance_gol_penalti_simulado", 0.76)
		return "penalty"
	if Game.rng.randf() < float(pending.get("pg", 0.25)):
		return "goal"
	if Game.rng.randf() < Tuning.f("arbitro", "chance_impedimento_ataque_simulado", 0.06) * 2.0:
		return "offside"
	var x := Game.rng.randf()
	if x < 0.45:
		return "save"
	if x < 0.7:
		return "out"
	return "lost"


# recebe o resultado do lance jogado em campo
func resolve_lance(res: Dictionary) -> Dictionary:
	var side: int = int(pending.get("side", 0))
	pending = {}
	if res.get("pen", false):
		penalties[side] += 1
	if res.get("kind", "") == "offside":
		offsides[side] += 1
	if res.get("goal", false):
		var g := _goal(side, res["pid"], int(res.get("apid", 0)))
		if res.get("pen", false):
			g["text"] = "PÊNALTI! " + g["text"]
		return g
	if focus_pid >= 0 and int(res.get("pid", 0)) == focus_pid:
		match str(res.get("kind", "")):
			"save":
				me["on"] += 1
			"out", "blocked":
				me["off"] += 1
			"lost":
				me["lost"] += 1
			"offside":
				me["offside"] += 1
	var nm: String = Game.player(res["pid"])["name"]
	var texts := {"save": "%s finaliza e o goleiro defende!", "out": "%s finaliza para fora.", "lost": "%s perde a bola na hora H.",
		"offside": "%s estava impedido.", "blocked": "Chute de %s travado pela zaga."}
	return {"type": "chance", "side": side, "text": str(texts.get(res.get("kind", "out"), "%s perde a chance.")) % nm, "min": minute}


func substitute(side: int, slot: int, in_pid: int) -> String:
	if subs[side] >= 5:
		return "Você já fez as 5 substituições."
	if in_pid in out:
		return "Esse jogador já saiu da partida."
	var xi: Array = Game.club(cid(side))["xi"]
	if xi[slot] in sent_off:
		return "Jogador expulso não pode ser substituído."
	out.append(xi[slot])
	xi[slot] = in_pid
	subs[side] += 1
	refresh()
	return ""


## Seu jogador está em campo agora?
func focus_on_pitch() -> bool:
	return focus_pid >= 0 and focus_pid in Game.club(cid(focus_side))["xi"] and not (focus_pid in sent_off)


## Sorteia se a jogada do seu time passa por você (depende da sua posição).
func focus_involved() -> bool:
	if not focus_on_pitch():
		return false
	var pos: String = Game.player(focus_pid)["pos"]
	return Game.rng.randf() < Pro.cfg("envolvimento_no_lance", pos, 0.5)


## O técnico te coloca no jogo no lugar de alguém da mesma posição (ou do mesmo setor).
func _focus_sub() -> String:
	if focus_on_pitch() or subs[focus_side] >= 5 or focus_pid in out:
		return ""
	var xi: Array = Game.club(cid(focus_side))["xi"]
	var mypos: String = Game.player(focus_pid)["pos"]
	var best := -1
	var bs := -1.0
	for i in xi.size():
		var p: Dictionary = Game.player(xi[i])
		if p["pos"] == "GOL" or xi[i] in sent_off:
			continue
		var sc: float = Game.fit(mypos, p["pos"]) * 100.0 - float(p["ovr"]) * 0.3
		if sc > bs:
			bs = sc
			best = i
	if best < 0:
		return ""
	var leaving: String = Game.player(xi[best])["name"]
	if substitute(focus_side, best, focus_pid) != "":
		return ""
	return "Substituição: entra %s, sai %s." % [Game.player(focus_pid)["name"], leaving]
