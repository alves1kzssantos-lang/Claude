extends Node
# ============================================================
# Game (autoload) — todos os dados e regras do jogo ficam aqui.
# As telas só leem "Game.S" e chamam as funções deste arquivo.
# ============================================================

const SAVE_PATH := "user://carreira_%d.sav"
const FREE := -1    # jogador sem clube
const YOUTH := -2   # jogador na base do seu clube

# posição, x (0..1 na largura), y (0 = seu gol, 1 = gol adversário)
const FORMATIONS := {
	"4-3-3": [["GOL", 0.5, 0.07], ["LE", 0.12, 0.30], ["ZAG", 0.37, 0.25], ["ZAG", 0.63, 0.25], ["LD", 0.88, 0.30],
		["VOL", 0.5, 0.47], ["MEI", 0.26, 0.58], ["MEI", 0.74, 0.58], ["PE", 0.15, 0.83], ["AC", 0.5, 0.88], ["PD", 0.85, 0.83]],
	"4-4-2": [["GOL", 0.5, 0.07], ["LE", 0.12, 0.30], ["ZAG", 0.37, 0.25], ["ZAG", 0.63, 0.25], ["LD", 0.88, 0.30],
		["PE", 0.13, 0.60], ["VOL", 0.38, 0.52], ["MEI", 0.62, 0.52], ["PD", 0.87, 0.60], ["AC", 0.36, 0.86], ["AC", 0.64, 0.86]],
	"4-2-3-1": [["GOL", 0.5, 0.07], ["LE", 0.12, 0.30], ["ZAG", 0.37, 0.25], ["ZAG", 0.63, 0.25], ["LD", 0.88, 0.30],
		["VOL", 0.36, 0.46], ["VOL", 0.64, 0.46], ["PE", 0.15, 0.70], ["MEI", 0.5, 0.68], ["PD", 0.85, 0.70], ["AC", 0.5, 0.89]],
	"3-5-2": [["GOL", 0.5, 0.07], ["ZAG", 0.25, 0.25], ["ZAG", 0.5, 0.23], ["ZAG", 0.75, 0.25],
		["LE", 0.10, 0.55], ["VOL", 0.5, 0.45], ["MEI", 0.32, 0.62], ["MEI", 0.68, 0.62], ["LD", 0.90, 0.55], ["AC", 0.36, 0.86], ["AC", 0.64, 0.86]],
}
const FORMATION_NAMES := ["4-3-3", "4-4-2", "4-2-3-1", "3-5-2"]

const POS_ORDER := ["GOL", "ZAG", "LD", "LE", "VOL", "MEI", "PD", "PE", "AC"]
const SQUAD_TEMPLATE := ["GOL", "ZAG", "ZAG", "LD", "LE", "VOL", "MEI", "MEI", "PD", "PE", "AC",
	"GOL", "ZAG", "ZAG", "LD", "LE", "VOL", "VOL", "MEI", "MEI", "PD", "PE", "AC", "AC"]

const COACH_NATS := ["Brasil", "Argentina", "Portugal", "Uruguai", "Espanha", "Itália", "Colômbia"]
const MONTHS := ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]

var S: Dictionary = {}       # estado da carreira atual
var LEAGUE: String = "Brasileirão Série A"   # nome da liga da carreira atual
var slot: int = -1
var rng := RandomNumberGenerator.new()
var _real: Dictionary = {}    ## cache de assets/data/rosters_real.json
var last_sim = null           ## última partida do seu clube (modo jogador calcula a nota com ela)


func _ready() -> void:
	rng.randomize()


# ------------------------------------------------------------ datas
func day_of(y: int, m: int, d: int) -> int:
	var t: int = Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": d, "hour": 12, "minute": 0, "second": 0})
	return int(floor(t / 86400.0))


func date_of(day: int) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(day * 86400 + 43200)


func fmt_date(day: int) -> String:
	var d := date_of(day)
	return "%02d/%02d/%d" % [d["day"], d["month"], d["year"]]


func fmt_short(day: int) -> String:
	var d := date_of(day)
	return "%02d/%02d" % [d["day"], d["month"]]


func month_year(day: int) -> String:
	var d := date_of(day)
	return "%s %d" % [MONTHS[int(d["month"]) - 1], d["year"]]


# ------------------------------------------------------------ save
func has_save(i: int) -> bool:
	return FileAccess.file_exists(SAVE_PATH % i)


## Lê um save; se o principal estiver corrompido (app fechado no meio da gravação), usa o backup.
func _read_save(i: int) -> Dictionary:
	for path in [SAVE_PATH % i, (SAVE_PATH % i) + ".bak"]:
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var d = f.get_var()
		f.close()
		if typeof(d) == TYPE_DICTIONARY and d.has("clubs"):
			return d
	return {}


func peek_save(i: int) -> Dictionary:
	var d: Dictionary = _read_save(i)
	if d.is_empty():
		return {}
	var c: Dictionary = d["clubs"][d["club"]]
	var info := {"club": d["club"], "name": c["name"], "short": c["short"], "c1": c["c1"], "c2": c["c2"], "season": d["season"], "year": d["year"],
		"league": World.LEAGUES[int(d.get("league", 0))]["name"], "li": int(d.get("league", 0)), "mode": str(d.get("mode", "tecnico"))}
	if info["mode"] == "pro" and d.has("pro"):
		var me: Dictionary = d["players"].get(d["pro"]["me"], {})
		info["player"] = str(me.get("name", "Jogador"))
		info["pos"] = str(me.get("pos", ""))
		info["ovr"] = int(me.get("ovr", 0))
		info["stage"] = str(d["pro"].get("stage", ""))
	return info


func save() -> void:
	if slot < 0 or S.is_empty():
		return
	# gravação segura: escreve num temporário e só depois troca (o anterior vira .bak)
	var path: String = SAVE_PATH % slot
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_var(S)
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, path + ".bak")
	DirAccess.rename_absolute(tmp, path)


func load_career(i: int) -> bool:
	var d: Dictionary = _read_save(i)
	if d.is_empty():
		return false
	S = d
	slot = i
	if not S.has("league"):
		S["league"] = 0
	LEAGUE = DataPack.comp_name(int(S["league"]), league()["name"])
	return true


func delete_save(i: int) -> void:
	var dir := DirAccess.open("user://")
	if dir:
		dir.remove("carreira_%d.sav" % i)
		dir.remove("carreira_%d.sav.bak" % i)
		dir.remove("carreira_%d.sav.tmp" % i)


# ------------------------------------------------------------ nova carreira
func new_career(i: int, coach: Dictionary, club_id: int, league_idx: int = 0, year: int = 2026) -> void:
	slot = i
	var infos: Array = World.LEAGUES[league_idx]["clubs"]
	LEAGUE = DataPack.comp_name(league_idx, World.LEAGUES[league_idx]["name"])
	S = {
		"ver": 2, "league": league_idx, "coach": coach, "club": club_id, "season": 1, "year": year,
		"day": day_of(year, 1, 7), "money": 0.0, "support": 60,
		"clubs": [], "players": {}, "next_id": 1, "fixtures": [], "round": 0, "last_round": -1,
		"season_over": false, "news": [], "unread": 0, "offers": [], "transfers": [],
		"trophies": [], "history": [],
		"fin": {"salarios": 0.0, "patrocinio": 0.0, "bilheteria": 0.0, "compras": 0.0, "vendas": 0.0, "premios": 0.0},
	}
	for c in infos.size():
		var info: Array = infos[c]
		var cname: String = DataPack.club_name(league_idx, c, info[0])
		S["clubs"].append({"id": c, "name": cname, "short": info[1], "c1": info[2], "c2": info[3], "str": info[4],
			"li": league_idx, "ci": c, "guest": false,
			"formation": "4-3-3", "xi": [], "titles": 0,
			"pts": 0, "j": 0, "v": 0, "e": 0, "d": 0, "gp": 0, "gc": 0})
		# elenco do datapack (elencos.csv), se existir para este clube
		var ros: Array = DataPack.roster([info[0], cname])
		if ros.size() < 11:
			ros = real_roster(info[0], str(World.LEAGUES[league_idx]["name"]))
		var have := {}
		if ros.size() >= 11:
			for r in ros:
				if squad(c).size() >= 30:
					break
				var rp := make_player(r[1], r[3], c, r[2])
				rp["name"] = r[0]
				if str(r[4]) != "":
					rp["nat"] = r[4]
				rp["pot"] = maxi(rp["pot"], rp["ovr"])
				_seed_history(rp)
				have[r[1]] = int(have.get(r[1], 0)) + 1
		var need := {}
		for k in SQUAD_TEMPLATE.size():
			var tp: String = SQUAD_TEMPLATE[k]
			need[tp] = int(need.get(tp, 0)) + 1
			if int(have.get(tp, 0)) >= int(need[tp]):
				continue   # já veio do datapack
			var base: float = float(info[4]) + rng.randfn(0.5, 3.0)
			if k >= 11 or not have.is_empty():
				base -= 5.0
			var p := make_player(tp, int(round(base)), c)
			_seed_history(p)
	# jogadores livres no mercado
	for k in 26:
		var age := rng.randi_range(29, 37)
		if k % 4 == 0:
			age = rng.randi_range(19, 23)
		make_player(POS_ORDER[rng.randi_range(0, 8)], rng.randi_range(64, 82) if age > 25 else rng.randi_range(58, 68), FREE, age)
	S["n_league"] = infos.size()
	S["money"] = (float(infos[club_id][4]) - 58.0) * 2.0
	_youth_intake(6)
	make_fixtures()
	for c in infos.size():
		auto_lineup(c)
	Cups.build_season([])
	for k in 8:
		_ai_transfer()
	add_news("Bem-vindo ao %s" % my_club()["name"], "A diretoria apresentou você como novo técnico. O elenco está chegando ao centro de treinamento.")
	S["unread"] = 1
	save()


## Número de clubes do campeonato (os convidados das copas ficam depois deles em S["clubs"]).
func n_league() -> int:
	return int(S.get("n_league", S["clubs"].size()))


## Clube de outra liga que entra numa copa. Cria na primeira vez (com elenco).
func guest_club(li: int, ci: int) -> int:
	var key := "%d:%d" % [li, ci]
	if not S.has("guests"):
		S["guests"] = {}
	if S["guests"].has(key):
		return int(S["guests"][key])
	var info: Array = World.LEAGUES[li]["clubs"][ci]
	var cid: int = S["clubs"].size()
	S["clubs"].append({"id": cid, "name": DataPack.club_name(li, ci, info[0]), "short": info[1], "c1": info[2], "c2": info[3],
		"str": info[4], "li": li, "ci": ci, "guest": true, "formation": "4-3-3", "xi": [], "titles": 0,
		"pts": 0, "j": 0, "v": 0, "e": 0, "d": 0, "gp": 0, "gc": 0})
	var ros: Array = real_roster(info[0], str(World.LEAGUES[li]["name"]))
	var have := {}
	if ros.size() >= 11:
		for r in ros:
			var rp := make_player(r[1], r[3], cid, r[2])
			rp["name"] = r[0]
			have[r[1]] = int(have.get(r[1], 0)) + 1
	var need := {}
	for k in SQUAD_TEMPLATE.size():
		var tp: String = SQUAD_TEMPLATE[k]
		need[tp] = int(need.get(tp, 0)) + 1
		if int(have.get(tp, 0)) >= int(need[tp]):
			continue
		var base: float = float(info[4]) + rng.randfn(0.5, 3.0) - (5.0 if k >= 11 or not have.is_empty() else 0.0)
		make_player(tp, int(round(base)), cid)
	auto_lineup(cid)
	S["guests"][key] = cid
	return cid


## Escudo do clube (do datapack), ou null.
func club_logo(cid: int) -> Texture2D:
	if cid < 0 or cid >= S["clubs"].size():
		return null
	var c: Dictionary = S["clubs"][cid]
	if int(c.get("ci", cid)) < 0:
		return null   # times da peneira não têm escudo do datapack
	return DataPack.logo(int(c.get("li", S.get("league", 0))), int(c.get("ci", cid)))


func rng_shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


## Próximo evento do calendário: rodada do campeonato ou fase de copa (a que vier primeiro).
func next_event() -> Dictionary:
	var league_day := 1 << 30
	if S["round"] < S["fixtures"].size():
		league_day = int(S["fixtures"][S["round"]]["day"])
	var cup := Cups.next_due()
	if not cup.is_empty() and int(cup["day"]) < league_day:
		return {"kind": "cup", "cup": cup["cup"], "round": cup["round"], "leg": cup.get("leg", 1), "stage": cup.get("stage", cup["round"]),
			"day": cup["day"]}
	if league_day == 1 << 30:
		return {}
	return {"kind": "league", "round": S["round"], "day": league_day}


## Joga sozinho as fases de copa em que o clube do jogador não está.
func advance_to_user() -> void:
	var guard := 0
	while guard < 50:
		guard += 1
		var ev := next_event()
		if ev.is_empty() or ev["kind"] != "cup":
			return
		if not Cups.my_tie(ev["cup"]).is_empty():
			return
		Cups.play_round(ev["cup"], null)
	save()


## Próxima partida do jogador: {"kind", "h", "a", "comp", "label", "day", "cup"} ou {}.
## Copa: "h"/"a" = mandante/visitante DESTE jogo (na volta, o "a" do confronto manda em casa),
## "leg" = 1 ou 2, "agg" = [gols de h, gols de a] no agregado antes do jogo (visão deste jogo).
func next_user_match() -> Dictionary:
	if Pro.is_pro() and Pro.P()["stage"] == "peneira":
		return Pro.trial_match()
	if S["season_over"]:
		return {}
	advance_to_user()
	var ev := next_event()
	if ev.is_empty():
		return {}
	if ev["kind"] == "cup":
		var t := Cups.my_tie(ev["cup"])
		var c: Dictionary = S["cups"][ev["cup"]]
		var leg: int = ev["leg"]
		var ag := Cups.aggregate(t, leg - 1)
		var flip := leg == 2
		return {"kind": "cup", "h": t["a"] if flip else t["h"], "a": t["h"] if flip else t["a"], "comp": c["name"],
			"label": Cups.stage_label(c, int(ev["stage"])), "day": ev["day"], "cup": ev["cup"], "round": ev["round"],
			"leg": leg, "agg": [ag[1], ag[0]] if flip else ag}
	var mm := my_match(S["round"])
	return {"kind": "league", "h": mm["h"], "a": mm["a"], "comp": LEAGUE, "label": "Rodada %d" % (S["round"] + 1), "day": ev["day"]}


## Joga o próximo evento do jogador (liga ou copa). user_sim = partida jogada na tela ou null.
func play_next(user_sim) -> void:
	if Pro.is_pro() and Pro.P()["stage"] == "peneira":
		Pro.finish_trial(user_sim)
		return
	last_sim = user_sim
	advance_to_user()
	var ev := next_event()
	if ev.is_empty():
		return
	if ev["kind"] == "league":
		play_round(user_sim)
		if Pro.is_pro():
			Pro.after_match()
		return
	var t := Cups.my_tie(ev["cup"])
	var c: Dictionary = S["cups"][ev["cup"]]
	Cups.play_round(ev["cup"], user_sim)
	# "h"/"a"/"hg"/"ag"/"pens" = deste jogo (mandante do jogo); "agg" = agregado depois do jogo, visão do "h" do confronto.
	var leg: int = ev["leg"]
	var flip := leg == 2
	var L := Cups.tie_legs(t)
	var g: Array = L[leg - 1] if L.size() >= leg else [t["hg"], t["ag"]]
	var pens: Array = t["pens"]
	S["last_user"] = {"kind": "cup", "cup": ev["cup"], "round": ev["round"], "leg": leg, "comp": c["name"],
		"label": Cups.stage_label(c, int(ev["stage"])), "day": ev["day"],
		"h": t["a"] if flip else t["h"], "a": t["h"] if flip else t["a"],
		"hg": g[1] if flip else g[0], "ag": g[0] if flip else g[1], "agg": [t["hg"], t["ag"]],
		"pens": [pens[1], pens[0]] if (flip and not pens.is_empty()) else pens.duplicate(),
		"tie_h": t["h"], "tie_a": t["a"], "sc": t["sc"], "st": t["st"]}
	S["day"] = int(ev["day"]) + 1
	for p in S["players"].values():
		p["energy"] = minf(float(p["energy"]) + 8.0, 100.0)
	if Pro.is_pro():
		Pro.after_match()
	save()


func league() -> Dictionary:
	return World.LEAGUES[int(S.get("league", 0))]


func my_club() -> Dictionary:
	return S["clubs"][S["club"]]


func club(cid: int) -> Dictionary:
	return S["clubs"][cid]


func club_name(cid: int) -> String:
	if cid == FREE:
		return "Sem clube"
	if cid == YOUTH:
		return "Base"
	return S["clubs"][cid]["name"]


# ------------------------------------------------------------ jogadores
## Elenco real do clube (assets/data/rosters_real.json), no formato
## [nome, posição, idade, nota, país]. Vazio se o clube não tiver elenco real.
## Elenco real de um clube. Aceita a chave "Liga|Clube" para clubes de mesmo nome em ligas diferentes.
func real_roster(club_name: String, league_name: String = "") -> Array:
	if _real.is_empty():
		var path := "res://assets/data/rosters_real.json"
		if FileAccess.file_exists(path):
			var d = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(d) == TYPE_DICTIONARY:
				_real = d
		# elencos por liga feitos a partir do datapack (assets/data/rosters/*.json) completam/substituem
		var dir := DirAccess.open("res://assets/data/rosters")
		if dir != null:
			for fn in dir.get_files():
				if not fn.ends_with(".json"):
					continue
				var dd = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/rosters/" + fn))
				if typeof(dd) == TYPE_DICTIONARY:
					for k in dd.keys():
						_real[k] = dd[k]
		if _real.is_empty():
			_real = {"_": []}
	var out: Array = []
	var key: String = league_name + "|" + club_name
	for r in _real.get(key, _real.get(club_name, [])):
		out.append([r[0], r[1], int(r[2]), int(r[3]), ""])
	return out


func _name() -> Array:
	var lg: Dictionary = league()
	var pool: String = lg["pool"]
	var nat: String = lg["nat"]
	if rng.randf() < 0.25:
		var f: Array = World.FOREIGN[rng.randi_range(0, World.FOREIGN.size() - 1)]
		pool = f[0]
		nat = f[1]
	# com datapack: nomes de jogadores de verdade, sorteados da lista do pacote
	var pack_names := DataPack.players()
	if pack_names.size() > 1000:
		return [pack_names[rng.randi_range(0, pack_names.size() - 1)], nat]
	var firsts: Array = World.NAMES[pool][0]
	var lasts: Array = World.NAMES[pool][1]
	return [firsts[rng.randi_range(0, firsts.size() - 1)] + " " + lasts[rng.randi_range(0, lasts.size() - 1)], nat]


# Atributos mostrados nos lances (saem da nota geral + posição)
func attrs(p: Dictionary) -> Dictionary:
	var o: int = p["ovr"]
	var id: int = p["id"]
	var pos: String = p["pos"]
	var off := {"GOL": [-15, -10, -30, -5], "ZAG": [-4, -8, -20, 6], "LD": [3, 0, -12, 3], "LE": [3, 0, -12, 3],
		"VOL": [-1, 3, -8, 5], "MEI": [0, 6, 0, -10], "PD": [5, 1, 3, -25], "PE": [5, 1, 3, -25], "AC": [3, -3, 6, -30]}
	var d: Array = off[pos]
	return {
		"vel": clampi(o + int(d[0]) + (id * 7) % 9 - 4, 20, 99),
		"pas": clampi(o + int(d[1]) + (id * 13) % 9 - 4, 20, 99),
		"chu": clampi(o + int(d[2]) + (id * 17) % 9 - 4, 20, 99),
		"des": clampi(o + int(d[3]) + (id * 23) % 9 - 4, 20, 99),
	}


func make_player(pos: String, ovr: int, cid: int, age: int = -1) -> Dictionary:
	if age < 0:
		age = clampi(int(round(rng.randfn(26.5, 4.2))), 18, 36)
	ovr = clampi(ovr, 40, 94)
	var pot := ovr
	if age < 27:
		pot = clampi(ovr + int(round((27 - age) * rng.randf_range(0.5, 1.6))), ovr, 95)
	var nm := _name()
	var p := {
		"id": S["next_id"], "name": nm[0], "nat": nm[1], "pos": pos, "age": age, "ovr": ovr, "pot": pot,
		"club": cid, "energy": 100.0, "wage": 0.0, "value": 0.0, "ask": rng.randf_range(1.1, 1.45),
		"contract": rng.randi_range(1, 4), "joined": S["season"], "listed": false,
		"g": 0, "min": 0, "gol": 0, "ass": 0,          # temporada
		"cmin": 0, "cgol": 0, "cass": 0, "titles": [],  # pelo clube atual
	}
	S["next_id"] += 1
	_price(p)
	S["players"][p["id"]] = p
	return p


func _price(p: Dictionary) -> void:
	var o: float = maxf(float(p["ovr"]) - 50.0, 1.0) / 10.0
	var af := 1.3
	var age: int = p["age"]
	if age >= 35:
		af = 0.2
	elif age >= 32:
		af = 0.45
	elif age >= 29:
		af = 0.8
	elif age >= 24:
		af = 1.1
	if p["pot"] - p["ovr"] >= 8:
		af *= 1.25
	p["value"] = snappedf(maxf(pow(o, 3.2) * 0.35 * af, 0.05), 0.01)
	p["wage"] = snappedf(maxf(pow(maxf(float(p["ovr"]) - 55.0, 1.0), 2.0) * 0.07, 1.5), 0.1)  # em mil por semana


func _seed_history(p: Dictionary) -> void:
	# dá um passado no clube para quem já estava no elenco
	var yrs: int = mini(rng.randi_range(0, 5), int(p["age"]) - 18)
	if yrs <= 0:
		return
	p["joined"] = S["season"] - yrs
	p["cmin"] = yrs * rng.randi_range(900, 2800)
	var gf := {"AC": 0.5, "PD": 0.28, "PE": 0.28, "MEI": 0.16, "VOL": 0.06, "LD": 0.04, "LE": 0.04, "ZAG": 0.04, "GOL": 0.0}
	var af := {"AC": 0.18, "PD": 0.25, "PE": 0.25, "MEI": 0.28, "VOL": 0.1, "LD": 0.14, "LE": 0.14, "ZAG": 0.03, "GOL": 0.0}
	var games: float = float(p["cmin"]) / 90.0
	p["cgol"] = int(games * float(gf[p["pos"]]) * rng.randf_range(0.6, 1.2))
	p["cass"] = int(games * float(af[p["pos"]]) * rng.randf_range(0.6, 1.2))


func player(pid: int) -> Dictionary:
	return S["players"][pid]


func squad(cid: int) -> Array:
	var out: Array = []
	for p in S["players"].values():
		if p["club"] == cid:
			out.append(p)
	out.sort_custom(func(a, b):
		var ia := POS_ORDER.find(a["pos"])
		var ib := POS_ORDER.find(b["pos"])
		if ia != ib:
			return ia < ib
		if a["ovr"] != b["ovr"]:
			return a["ovr"] > b["ovr"]
		return a["id"] < b["id"])
	return out


func fit(ppos: String, spos: String) -> float:
	if ppos == spos:
		return 1.0
	if ppos == "GOL" or spos == "GOL":
		return 0.45
	var near := {"ZAG": ["VOL", "LD", "LE"], "LD": ["LE", "ZAG", "PD"], "LE": ["LD", "ZAG", "PE"], "VOL": ["MEI", "ZAG"],
		"MEI": ["VOL", "PD", "PE"], "PD": ["PE", "MEI", "AC"], "PE": ["PD", "MEI", "AC"], "AC": ["PD", "PE"]}
	if spos in near[ppos]:
		return 0.93
	return 0.82


func eff(p: Dictionary, spos: String) -> float:
	return float(p["ovr"]) * fit(p["pos"], spos) * (0.85 + 0.15 * float(p["energy"]) / 100.0)


func auto_lineup(cid: int) -> void:
	var c: Dictionary = S["clubs"][cid]
	var slots: Array = FORMATIONS[c["formation"]]
	var avail := squad(cid).filter(func(p): return int(p.get("susp", 0)) == 0)
	var xi: Array = []
	for s in slots:
		var best = null
		var bv := -1.0
		for p in avail:
			if p["id"] in xi:
				continue
			var v := eff(p, s[0])
			if v > bv:
				bv = v
				best = p
		if best != null:
			xi.append(best["id"])
	c["xi"] = xi


func validate_xi(cid: int) -> void:
	var c: Dictionary = S["clubs"][cid]
	var xi: Array = c["xi"]
	if xi.size() != 11:
		auto_lineup(cid)
		return
	var slots: Array = FORMATIONS[c["formation"]]
	var seen: Array = []
	for i in 11:
		var pid = xi[i]
		var ok: bool = S["players"].has(pid) and S["players"][pid]["club"] == cid and not (pid in seen) \
			and int(S["players"][pid].get("susp", 0)) == 0
		if not ok:
			var best = null
			var bv := -1.0
			for p in squad(cid):
				if p["id"] in xi or p["id"] in seen or int(p.get("susp", 0)) > 0:
					continue
				var v := eff(p, slots[i][0])
				if v > bv:
					bv = v
					best = p
			if best == null:
				auto_lineup(cid)
				return
			xi[i] = best["id"]
		seen.append(xi[i])


func bench(cid: int) -> Array:
	var xi: Array = S["clubs"][cid]["xi"]
	var out: Array = []
	for p in squad(cid):
		if not (p["id"] in xi) and int(p.get("susp", 0)) == 0:
			out.append(p)
	return out


## Jogadores suspensos (cartão vermelho) do clube.
func suspended(cid: int) -> Array:
	return squad(cid).filter(func(p): return int(p.get("susp", 0)) > 0)


func ratings(cid: int) -> Dictionary:
	var c: Dictionary = S["clubs"][cid]
	var slots: Array = FORMATIONS[c["formation"]]
	var sum := {"def": 0.0, "mei": 0.0, "atq": 0.0}
	var cnt := {"def": 0, "mei": 0, "atq": 0}
	var tot := 0.0
	for i in mini(11, c["xi"].size()):
		var sp: String = slots[i][0]
		var v := eff(S["players"][c["xi"][i]], sp)
		var k := "atq"
		if sp in ["GOL", "ZAG", "LD", "LE"]:
			k = "def"
		elif sp in ["VOL", "MEI"]:
			k = "mei"
		sum[k] += v
		cnt[k] += 1
		tot += v
	return {"def": int(round(sum["def"] / maxi(cnt["def"], 1))), "mei": int(round(sum["mei"] / maxi(cnt["mei"], 1))),
		"atq": int(round(sum["atq"] / maxi(cnt["atq"], 1))), "ger": int(round(tot / 11.0))}


func energy_avg(cid: int) -> int:
	var t := 0.0
	var xi: Array = S["clubs"][cid]["xi"]
	for pid in xi:
		t += float(S["players"][pid]["energy"])
	return int(round(t / maxi(xi.size(), 1)))


func status(p: Dictionary) -> String:
	var yrs: int = S["season"] - int(p["joined"])
	var feats: int = int(p["cgol"]) + int(p["cass"]) + p["titles"].size() * 15
	if yrs >= 5 and feats >= 60:
		return "ÍDOLO"
	if (yrs >= 2 and feats >= 25) or (yrs >= 1 and p["titles"].size() > 0):
		return "GRANDE JOGADOR"
	if yrs >= 1:
		return "JOGADOR DO ELENCO"
	return "RECÉM-CHEGADO"


# ------------------------------------------------------------ calendário
func make_fixtures() -> void:
	var n: int = n_league()
	var ids: Array = range(n)
	for i in range(n - 1, 0, -1):   # embaralha
		var j := rng.randi_range(0, i)
		var tmp = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp
	var first: Array = []
	for r in n - 1:
		var ms: Array = []
		for i in int(n / 2.0):
			var a: int = ids[i]
			var b: int = ids[n - 1 - i]
			var flip: bool = (r % 2 == 1) if i == 0 else (i % 2 == 1)
			if flip:
				ms.append([b, a])
			else:
				ms.append([a, b])
		first.append(ms)
		var last = ids.pop_back()
		ids.insert(1, last)
	var day := day_of(S["year"], 1, 20)
	while int(date_of(day)["weekday"]) != 0:
		day += 1
	var gaps := [7, 4, 3, 7]
	var fixtures: Array = []
	for r in (n - 1) * 2:
		var src: Array = first[r % (n - 1)]
		var ms: Array = []
		for pair in src:
			var h: int = pair[0]
			var a: int = pair[1]
			if r >= n - 1:
				h = pair[1]
				a = pair[0]
			ms.append({"h": h, "a": a, "hg": -1, "ag": -1, "sc": [], "st": []})
		fixtures.append({"day": day, "m": ms})
		day += gaps[r % gaps.size()]
	S["fixtures"] = fixtures
	S["round"] = 0
	S["last_round"] = -1


func my_match(r: int) -> Dictionary:
	if r < 0 or r >= S["fixtures"].size():
		return {}
	for m in S["fixtures"][r]["m"]:
		if m["h"] == S["club"] or m["a"] == S["club"]:
			return m
	return {}


func sorted_table() -> Array:
	var ids: Array = range(n_league())
	ids.sort_custom(func(x, y):
		var a: Dictionary = S["clubs"][x]
		var b: Dictionary = S["clubs"][y]
		if a["pts"] != b["pts"]:
			return a["pts"] > b["pts"]
		if a["v"] != b["v"]:
			return a["v"] > b["v"]
		var sa: int = a["gp"] - a["gc"]
		var sb: int = b["gp"] - b["gc"]
		if sa != sb:
			return sa > sb
		if a["gp"] != b["gp"]:
			return a["gp"] > b["gp"]
		return x < y)
	return ids


func position_of(cid: int) -> int:
	return sorted_table().find(cid) + 1


# ------------------------------------------------------------ rodada
func play_round(user_sim) -> void:
	# user_sim: MatchSim do seu jogo (ou null para simular tudo)
	var rd: Dictionary = S["fixtures"][S["round"]]
	S["day"] = rd["day"]
	for m in rd["m"]:
		if m["hg"] >= 0:
			continue
		var sim
		if user_sim != null and m["h"] == user_sim.h and m["a"] == user_sim.a:
			sim = user_sim
		else:
			sim = MatchSim.new(m["h"], m["a"])
		while not sim.finished:
			sim.step()
		_apply_result(m, sim)
	# suspensões andam uma rodada
	for p in S["players"].values():
		if int(p.get("susp", 0)) > 0:
			p["susp"] = int(p["susp"]) - 1
	S["last_round"] = S["round"]
	var mm: Dictionary = my_match(S["round"])
	S["last_user"] = {"kind": "league", "round": S["round"], "comp": LEAGUE, "label": "Rodada %d" % (S["round"] + 1), "day": rd["day"],
		"h": mm["h"], "a": mm["a"], "hg": mm["hg"], "ag": mm["ag"], "sc": mm["sc"], "st": mm["st"], "pens": []}
	S["round"] += 1
	var gap := 7
	if S["round"] < S["fixtures"].size():
		gap = int(S["fixtures"][S["round"]]["day"]) - int(rd["day"])
	_between_rounds(gap, my_match(S["last_round"])["h"] == S["club"])
	S["day"] = int(rd["day"]) + 1
	if S["round"] >= S["fixtures"].size():
		S["season_over"] = true
		add_news("Fim de temporada", "O campeonato terminou. Veja o resumo e prepare o próximo ano.")
	save()


func _apply_result(m: Dictionary, sim) -> void:
	m["hg"] = sim.score[0]
	m["ag"] = sim.score[1]
	m["sc"] = sim.scorers
	# estatísticas: ataques, chutes, posse, faltas, amarelos, vermelhos, impedimentos
	m["st"] = [sim.att, sim.shots, sim.poss, sim.fouls, sim.yellows, sim.reds, sim.offsides]
	apply_players(sim)
	var ch: Dictionary = S["clubs"][m["h"]]
	var ca: Dictionary = S["clubs"][m["a"]]
	ch["j"] += 1
	ca["j"] += 1
	ch["gp"] += m["hg"]
	ch["gc"] += m["ag"]
	ca["gp"] += m["ag"]
	ca["gc"] += m["hg"]
	if m["hg"] > m["ag"]:
		ch["v"] += 1
		ch["pts"] += 3
		ca["d"] += 1
	elif m["hg"] < m["ag"]:
		ca["v"] += 1
		ca["pts"] += 3
		ch["d"] += 1
	else:
		ch["e"] += 1
		ca["e"] += 1
		ch["pts"] += 1
		ca["pts"] += 1


## Atualiza jogadores depois de qualquer partida (liga ou copa): minutos, gols,
## assistências, energia, suspensões, torcida. Devolve a escalação original.
func apply_players(sim) -> void:
	# expulsos ficam fora do próximo jogo (o contador cai no fim da rodada)
	for pid in sim.sent_off:
		if S["players"].has(pid):
			S["players"][pid]["susp"] = int(Tuning.f("arbitro", "jogos_suspensao_vermelho", 1.0)) + 1
			if S["players"][pid]["club"] == S["club"]:
				add_news("Expulsão", "%s foi expulso e cumpre suspensão no próximo jogo." % S["players"][pid]["name"])
	for pid in sim.mins.keys():
		if not S["players"].has(pid):
			continue
		var p: Dictionary = S["players"][pid]
		var mn: int = sim.mins[pid]
		p["g"] += 1
		p["min"] += mn
		p["cmin"] += mn
		p["energy"] = maxf(float(p["energy"]) - (7.0 + 9.0 * mn / 90.0), 20.0)
	for s in sim.scorers:
		if S["players"].has(s["pid"]):
			S["players"][s["pid"]]["gol"] += 1
			S["players"][s["pid"]]["cgol"] += 1
		if s["apid"] > 0 and S["players"].has(s["apid"]):
			S["players"][s["apid"]]["ass"] += 1
			S["players"][s["apid"]]["cass"] += 1
	# devolve a escalação original (as trocas valem só para o jogo)
	S["clubs"][sim.h]["xi"] = sim.orig_xi[0]
	S["clubs"][sim.a]["xi"] = sim.orig_xi[1]
	# torcida
	if sim.h == S["club"] or sim.a == S["club"]:
		var mine: int = sim.score[0] if sim.h == S["club"] else sim.score[1]
		var other: int = sim.score[1] if sim.h == S["club"] else sim.score[0]
		if mine > other:
			S["support"] = mini(S["support"] + 2, 100)
		elif mine < other:
			S["support"] = maxi(S["support"] - 2, 0)


func _between_rounds(gap: int, was_home: bool) -> void:
	var me: Dictionary = my_club()
	# finanças (em milhões)
	var wages := 0.0
	for p in squad(S["club"]):
		wages += float(p["wage"])
	wages = wages / 1000.0 * gap / 7.0
	var sq: float = pow(maxf(float(me["str"]) - 55.0, 3.0), 2.0)
	var sponsor: float = 0.00105 * sq * gap / 7.0
	var tickets := 0.0
	if was_home:
		tickets = 0.0014 * sq * (0.5 + float(S["support"]) / 100.0)
	S["money"] += sponsor + tickets - wages
	S["fin"]["salarios"] += wages
	S["fin"]["patrocinio"] += sponsor
	S["fin"]["bilheteria"] += tickets
	# descanso
	for p in S["players"].values():
		p["energy"] = minf(float(p["energy"]) + gap * 4.0, 100.0)
	# times da máquina reescalam
	for c in S["clubs"].size():
		if c != S["club"]:
			auto_lineup(c)
	if Pro.is_pro():
		Pro.pick_lineup()   # no modo jogador quem escala é o técnico
	else:
		validate_xi(S["club"])
	# propostas pelos seus jogadores (só no modo técnico)
	for p in ([] if Pro.is_pro() else squad(S["club"])):
		var chance := 0.45 if p["listed"] else 0.012
		if rng.randf() < chance:
			_make_offer(p)
	# mercado dos outros clubes
	for k in rng.randi_range(0, 2):
		_ai_transfer()
	# base
	for p in squad(YOUTH):
		if rng.randf() < 0.3 and p["ovr"] < p["pot"]:
			p["ovr"] += 1
			_price(p)
	if S["round"] == int(S["fixtures"].size() / 2.0):
		_youth_intake(4)
		add_news("Novos jovens na base", "A captação trouxe novos garotos. Veja a Base do clube.")
	if S["money"] < 0.0 and not Pro.is_pro():
		add_news("Caixa no vermelho", "O clube está gastando mais do que arrecada. Venda jogadores ou reduza salários.")


func _make_offer(p: Dictionary) -> void:
	var cid := rng.randi_range(0, n_league() - 1)
	if cid == S["club"]:
		return
	var val: float = snappedf(float(p["value"]) * rng.randf_range(0.8, 1.2), 0.01)
	for o in S["offers"]:
		if o["pid"] == p["id"]:
			S["offers"].erase(o)
			break
	S["offers"].append({"pid": p["id"], "club": cid, "value": val})
	add_news("Proposta por %s" % p["name"], "%s ofereceu %s." % [club_name(cid), money(val)])


func _ai_transfer() -> void:
	var n: int = n_league()
	var seller := rng.randi_range(0, n - 1)
	var buyer := rng.randi_range(0, n - 1)
	if seller == buyer or seller == S["club"] or buyer == S["club"]:
		return
	var sq := squad(seller)
	if sq.is_empty():
		return
	var p: Dictionary = sq[rng.randi_range(0, sq.size() - 1)]
	if p.get("me", false):
		return   # o jogador da carreira só muda de clube pelas propostas dele
	var fee: float = snappedf(float(p["value"]) * rng.randf_range(0.9, 1.3), 0.01)
	_log_transfer(p, seller, buyer, fee)
	p["club"] = buyer
	p["joined"] = S["season"]
	p["cmin"] = 0
	p["cgol"] = 0
	p["cass"] = 0
	p["titles"] = []
	make_player(p["pos"], int(S["clubs"][seller]["str"]) - rng.randi_range(2, 6), seller, rng.randi_range(18, 23))
	_trim(buyer)
	auto_lineup(seller)
	auto_lineup(buyer)
	# mantém a lista de livres num tamanho razoável
	var free := squad(FREE)
	if free.size() > 40:
		free.sort_custom(func(a, b): return a["ovr"] < b["ovr"])
		S["players"].erase(free[0]["id"])


func _trim(cid: int) -> void:
	# clube da máquina com elenco inchado libera os mais fracos
	var sq := squad(cid)
	sq.sort_custom(func(x, y): return x["ovr"] < y["ovr"])
	var i := 0
	while sq.size() - i > 26 and i < sq.size():
		if not sq[i].get("me", false):
			sq[i]["club"] = FREE
		i += 1


func _log_transfer(p: Dictionary, from: int, to: int, fee: float) -> void:
	S["transfers"].push_front({"name": p["name"], "pos": p["pos"], "nat": p["nat"], "from": from, "to": to, "value": fee, "day": S["day"]})
	if S["transfers"].size() > 60:
		S["transfers"].pop_back()


func _youth_intake(count: int) -> void:
	var st: int = my_club()["str"]
	for k in count:
		if squad(YOUTH).size() >= 10:
			return
		var p := make_player(POS_ORDER[rng.randi_range(0, 8)], rng.randi_range(st - 32, st - 16), YOUTH, rng.randi_range(16, 18))
		p["pot"] = clampi(int(p["ovr"]) + rng.randi_range(8, 30), 55, 92)
		_price(p)


func add_news(title: String, text: String) -> void:
	S["news"].push_front({"day": S["day"], "t": title, "x": text})
	S["unread"] += 1
	if S["news"].size() > 40:
		S["news"].pop_back()


func money(v: float) -> String:
	return "$ %.2f mi" % v


# ------------------------------------------------------------ mercado
func ask_fee(p: Dictionary) -> float:
	if p["club"] < 0:
		return 0.0
	return snappedf(float(p["value"]) * float(p["ask"]), 0.01)


func ask_wage(p: Dictionary) -> float:
	return snappedf(float(p["wage"]) * (1.0 if p["club"] == FREE else 1.1), 0.1)


func sign_player(pid: int, fee: float, wage: float, years: int) -> String:
	# devolve "" se deu certo, ou o motivo da recusa
	var p: Dictionary = S["players"][pid]
	if squad(S["club"]).size() >= 30:
		return "Elenco cheio (máximo 30). Venda alguém antes."
	if fee > S["money"] + 0.001:
		return "Você não tem caixa para essa proposta."
	if p["club"] >= 0 and fee < ask_fee(p) - 0.001:
		return "%s recusou: quer um valor maior." % club_name(p["club"])
	if wage < ask_wage(p) * 0.97:
		return "%s recusou: pede um salário maior." % p["name"]
	var from: int = p["club"]
	S["money"] -= fee
	S["fin"]["compras"] += fee
	_log_transfer(p, from, S["club"], fee)
	p["club"] = S["club"]
	p["wage"] = wage
	p["contract"] = years
	p["joined"] = S["season"]
	p["listed"] = false
	p["cmin"] = 0
	p["cgol"] = 0
	p["cass"] = 0
	p["titles"] = []
	if from >= 0:
		if squad(from).size() < 22:
			make_player(p["pos"], int(S["clubs"][from]["str"]) - rng.randi_range(2, 6), from, rng.randi_range(18, 23))
		auto_lineup(from)
	add_news("Reforço confirmado", "%s (%s, GER %d) assinou por %d ano(s)." % [p["name"], p["pos"], p["ovr"], years])
	save()
	return ""


func accept_offer(idx: int) -> String:
	var o: Dictionary = S["offers"][idx]
	var p: Dictionary = S["players"][o["pid"]]
	if squad(S["club"]).size() <= 16:
		return "Elenco muito curto para vender (mínimo 16)."
	if status(p) == "ÍDOLO":
		S["support"] = maxi(S["support"] - 25, 0)
	S["money"] += float(o["value"])
	S["fin"]["vendas"] += float(o["value"])
	_log_transfer(p, S["club"], o["club"], o["value"])
	p["club"] = o["club"]
	p["joined"] = S["season"]
	p["listed"] = false
	p["cmin"] = 0
	p["cgol"] = 0
	p["cass"] = 0
	p["titles"] = []
	S["offers"].remove_at(idx)
	validate_xi(S["club"])
	_trim(o["club"])
	auto_lineup(o["club"])
	add_news("Venda concluída", "%s foi vendido ao %s por %s." % [p["name"], club_name(o["club"]), money(o["value"])])
	save()
	return ""


func reject_offer(idx: int) -> void:
	S["offers"].remove_at(idx)


func promote_youth(pid: int) -> String:
	if squad(S["club"]).size() >= 30:
		return "Elenco cheio (máximo 30)."
	var p: Dictionary = S["players"][pid]
	p["club"] = S["club"]
	p["joined"] = S["season"]
	p["contract"] = 3
	add_news("Jovem promovido", "%s subiu para o profissional." % p["name"])
	save()
	return ""


# ------------------------------------------------------------ fim de temporada
func season_summary() -> Dictionary:
	var tb := sorted_table()
	var pos := tb.find(S["club"]) + 1
	var best = null
	for p in S["players"].values():
		if best == null or p["gol"] > best["gol"]:
			best = p
	return {"pos": pos, "champion": tb[0], "prize": snappedf((tb.size() + 1 - pos) * 0.6 * float(league()["prize"]), 0.01), "top": best, "table": tb}


func new_season() -> void:
	var sm := season_summary()
	var champ: int = sm["champion"]
	S["clubs"][champ]["titles"] += 1
	S["money"] += float(sm["prize"])
	S["history"].append({"year": S["year"], "pos": sm["pos"], "champion": S["clubs"][champ]["name"]})
	if champ == S["club"]:
		S["trophies"].append({"name": LEAGUE, "year": S["year"]})
		S["support"] = mini(S["support"] + 15, 100)
		S["coach"]["rep"] = minf(float(S["coach"]["rep"]) + 1.0, 10.0)
	for p in squad(champ):
		p["titles"].append(LEAGUE)
	# envelhecimento e evolução
	var gone: Array = []
	for p in S["players"].values():
		p["age"] += 1
		var age: int = p["age"]
		if p.get("me", false):
			# o seu jogador evolui pelo treino (src/pro_career.gd); depois dos 31 o corpo cobra
			if age > 31:
				p["ovr"] = maxi(int(p["ovr"]) - rng.randi_range(0, 2), 40)
			for k in ["g", "min", "gol", "ass"]:
				p[k] = 0
			p["energy"] = 100.0
			continue
		if age <= 23:
			p["ovr"] = mini(int(p["ovr"]) + rng.randi_range(1, 4), int(p["pot"]))
		elif age <= 29:
			if p["ovr"] < p["pot"]:
				p["ovr"] += rng.randi_range(0, 2)
		elif age <= 32:
			p["ovr"] -= rng.randi_range(0, 1)
		else:
			p["ovr"] -= rng.randi_range(1, 3)
		p["pot"] = maxi(p["pot"], p["ovr"])
		p["g"] = 0
		p["min"] = 0
		p["gol"] = 0
		p["ass"] = 0
		p["energy"] = 100.0
		if p["club"] != S["club"] and p["club"] != YOUTH:
			_price(p)
		else:
			var w: float = p["wage"]
			_price(p)
			p["wage"] = w
			p["contract"] = maxi(int(p["contract"]) - 1, 1)
		if age >= 38 or (p["club"] == FREE and age >= 36) or (p["club"] == YOUTH and age >= 21):
			gone.append(p)
	for p in gone:
		var cid: int = p["club"]
		if cid == S["club"]:
			add_news("Aposentadoria", "%s pendurou as chuteiras." % p["name"])
		S["players"].erase(p["id"])
		if cid >= 0 and squad(cid).size() < 22:
			make_player(p["pos"], int(S["clubs"][cid]["str"]) - rng.randi_range(1, 6), cid, rng.randi_range(18, 22))
	S["offers"] = []
	for c in S["clubs"]:
		for k in ["pts", "j", "v", "e", "d", "gp", "gc"]:
			c[k] = 0
	S["season"] += 1
	S["year"] += 1
	S["day"] = day_of(S["year"], 1, 7)
	S["season_over"] = false
	S["fin"] = {"salarios": 0.0, "patrocinio": 0.0, "bilheteria": 0.0, "compras": 0.0, "vendas": 0.0, "premios": float(sm["prize"])}
	for k in 6:
		make_player(POS_ORDER[rng.randi_range(0, 8)], rng.randi_range(64, 80), FREE, rng.randi_range(28, 34))
	_youth_intake(4)
	var last_rank: Array = sm["table"]
	make_fixtures()
	Cups.build_season(last_rank)
	for c in S["clubs"].size():
		if c == S["club"]:
			validate_xi(c)
		else:
			auto_lineup(c)
	add_news("Temporada %d" % S["season"], "Premiação recebida: %s. Um novo campeonato começa." % money(sm["prize"]))
	save()
