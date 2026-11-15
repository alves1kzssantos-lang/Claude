class_name LanceView
extends Control
## Lance em campo, visto de cima, com o time atacante indo para CIMA (como no World Soccer Champs):
## o gol atacado fica no alto da tela, com a rede e as placas de publicidade atrás dele.
## Plano em metros: gol atacado em y = 0, meio-campo em y = 52.5; z = altura.
## Na tela, y do mundo cresce para baixo (y_sign = 1); o FieldView usa o contrário (y_sign = -1).
##
## Como o jogador controla (no ataque do time dele o jogo pausa e fica cinza):
##   toque num companheiro .................. passe RASTEIRO
##   segurar o dedo num companheiro ......... passe ALTO (cruzamento se ele estiver na área)
##   toque dentro do gol .................... chute colocado (toque no fundo da rede = chute alto)
##   deslizar o dedo para cima, até o gol ... chute: direção = mira, tamanho = força
##
## Máquina de estados (transições):
##   intro  -> run
##   run    -> decide | tackle_result (falta, desarme, vantagem)
##   decide -> pass | shot
##   pass   -> run (dominou) | decide (cabeceio na área) | end (corte, domínio ruim, impedimento)
##   shot   -> end (gol, defesa, trave, fora, travado)
##   setpiece (pênalti / falta direta) -> decide (só chute)
##   end    -> done (emite "finished")
## Números: assets/data/match_tuning.json. Regras do juiz: src/referee.gd.

signal finished(result: Dictionary)

const GOAL_HALF := BallPhysics.GOAL_HALF
const CAMERA_WIDTH_M := 56.0   ## quantos metros de largura a câmera mostra (menor = mais perto) — visão aberta estilo WSC
const STRIPE_M := 6.0          ## largura das faixas do gramado
const AD_H := 1.25             ## altura das placas de publicidade (metros de tela)
const PITCH := Color("7f9a17")    ## gramado verde-oliva
const STRIDE := 2.7            ## radianos de passada por metro corrido
const LIFT := 0.85             ## pixels de altura por pixel de chão (altura da bola, traves e bonecos)
const BODY_H := 2.4            ## altura desenhada do jogador em metros (um pouco exagerada para ler no celular)
const SKINS := [Color("f3cfae"), Color("e4b48a"), Color("c98d5c"), Color("a8703f"), Color("85532f"), Color("5e3a22")]
const HAIRS := [Color("1b1b1f"), Color("2e2018"), Color("5a3a22"), Color("8a5a2b"), Color("c9a24a"), Color("6e6e72")]
const AD_GAP := 3.3            ## distância (m) entre a linha de fundo e as placas atrás do gol atacado
const HUD_TOP := 78.0          ## pixels do placar no topo (a câmera não sobe além das placas)
const INK := Color("17171b")
const NEAR_BLACK := Color("202228")
const WHITE_TEETH := Color("fbfbfb")
const KEEPER_SHIRT := Color("e8c61c")
const KEEPER_TRIM := Color("2b2b2b")
const REF_SHORTS := Color("15161a")
const BALL_DARK := Color("1c1c1c")
const BALL_WHITE := Color("f1f1f1")
const BALL_RIM := Color("101010")
const HAIR_GREY := Color("8a7060")
const LINE_COL := Color(1, 1, 1, 0.9)
const NET_COL := Color(1, 1, 1, 0.32)
const SEP_STATES := ["run", "pass", "shot", "end"]
## Linhas do campo do lance (pares de pontos, em metros): laterais, fundo, meio, grande área e pequena área.
const LANCE_LINES := [
	Vector2(-34, 0), Vector2(34, 0), Vector2(-34, 0), Vector2(-34, 70), Vector2(34, 0), Vector2(34, 70),
	Vector2(-34, 52.5), Vector2(34, 52.5),
	Vector2(-20.16, 0), Vector2(-20.16, 16.5), Vector2(20.16, 0), Vector2(20.16, 16.5), Vector2(-20.16, 16.5), Vector2(20.16, 16.5),
	Vector2(-9.16, 0), Vector2(-9.16, 5.5), Vector2(9.16, 0), Vector2(9.16, 5.5), Vector2(-9.16, 5.5), Vector2(9.16, 5.5)]

var sim: MatchSim
var side: int = 0
var user_ctrl: bool = false
var script_kind: String = ""   ## só no ataque da máquina: goal/save/out/lost/offside/penalty
var lost_at: int = 1
var ref: Referee
var bp: BallPhysics

var att: Array = []
var dfn: Array = []
var gk: Dictionary = {}
var kits: Array = []
var carrier: int = 0
var last_passer: int = -1
var presser: int = -1
var state: String = "intro"
var t: float = 0.0
var run_time: float = 0.9
var moments: int = 0
var cam_y: float = 22.0
var pass_to: int = -1
var pass_end: Vector2 = Vector2.ZERO
var pass_lofted: bool = false
var pass_offside: bool = false
var shot_from: Vector2 = Vector2.ZERO
var shot_only: bool = false    ## pênalti, falta direta ou cabeceio: só pode chutar
var header: bool = false
var setpiece: String = ""      ## "", "penalti", "falta_direta"
var wall: Array = []           ## índices dos defensores na barreira
var gk_react: float = 0.2
var gk_speed: float = 4.3
var gk_dive_x: float = 0.0
var gk_checked: bool = false
var gk_tilt: float = 0.0       ## inclinação do goleiro no pulo
var line_y: float = 18.0       ## linha da zaga (também é a linha de impedimento)
var result: Dictionary = {}
var banner: String = ""
var banner_t: float = 0.0
var card_flash: String = ""    ## "amarelo" / "vermelho" desenhado na tela
var pressing: bool = false
var press: Vector2 = Vector2.ZERO
var press_ms: int = 0
var drag_now: Vector2 = Vector2.ZERO
var s: float = 16.8            ## pixels por metro
var referee: Dictionary = {}   ## boneco do árbitro
var me_pid: int = -1           ## modo carreira de jogador: você só joga quando a bola está com ele
var stage_label: String = ""   ## fase/rodada no canto do placar (ex.: "Final", "Rodada 5")
var ads: Array = []            ## placas de publicidade do datapack (texturas)
var ad_t: float = 0.0          ## rolagem das placas de LED
var cel_t: float = 0.0         ## comemoração de gol (segundos)
var cel_ent: Dictionary = {}
var cel_name: String = ""
var y_sign: float = 1.0        ## 1 = y do mundo cresce para baixo na tela (lance); -1 = para cima (FieldView)
static var _boxes: Dictionary = {}

# --- números do arquivo de ajuste usados a cada quadro (lidos uma vez no setup)
var _tz_depth: float = 10.0
var _tz_line_min: float = 6.0
var _tz_line_max: float = 30.0
var _tz_compact: float = 0.62
var _tz_shift: float = 0.35
var _tz_cover: float = 2.4
var _tz_cut_react: float = 0.18

# --- caches de desenho e de lógica (evitam alocar arrays a cada quadro)
var _sep_ents: Array = []                  ## todo mundo que não pode se atravessar
var _sep_pos := PackedVector2Array()
var _sep_sig: int = -1
var _ro_ents: Array = []                   ## ordem de desenho: entidades (null = bola)
var _ro_kind := PackedInt32Array()         ## 0 atacante, 1 defensor, 2 goleiro, 3 árbitro, 4 bola
var _ro_key := PackedFloat32Array()
var _ro_ord := PackedInt32Array()
var _ro_sig: int = -1
var _bp := PackedVector2Array()            ## lote de triângulos já na tela (uma draw call)
var _bc := PackedColorArray()
var _lp := PackedVector2Array()            ## triângulos da peça atual, em coordenadas locais
var _lk: float = 1.0                       ## pixels por unidade local (define quantos lados o círculo tem)
var _batch_open: bool = false
var _goal_s: float = -1.0                  ## escala do gol em cache
var _goal_far: Array = []                  ## [teto, fundo, rede, traves] relativos à trave esquerda
var _goal_near: Array = []
var _lines_buf := PackedVector2Array()
var _dash_buf := PackedVector2Array()
var _dash_w: float = -1.0
static var _tmpl: Dictionary = {}
static var _rr_cache: Dictionary = {}      ## retângulos arredondados prontos (tamanho, canto, lados)
static var _cfill: Dictionary = {}         ## listas de cor prontas (cor + tamanho -> PackedColorArray)          ## modelos de círculo/quartos/pentágono/sorriso (gerados uma vez)


## Monta o lance. side = time que ataca; user_ = é o time do jogador?
func setup(sim_: MatchSim, side_: int, user_: bool) -> void:
	sim = sim_
	side = side_
	user_ctrl = user_
	ref = Referee.new(Game.rng)
	bp = BallPhysics.new()
	if not user_ctrl:
		script_kind = sim.lance_script()
		lost_at = Game.rng.randi_range(1, 2)
	var ac: Dictionary = Game.club(sim.cid(side))
	var dc: Dictionary = Game.club(sim.cid(1 - side))
	var am := Color(str(ac["c1"]))
	var dm := Color(str(dc["c1"]))
	var dt := Color(str(dc["c2"]))
	if _close(am, dm):
		dm = Color(str(dc["c2"]))
		dt = Color(str(dc["c1"]))
		if _close(am, dm):
			dm = Color("f0a419")
	# 3º item = camisa listrada? (lista em world_data.gd, pelo nome original do clube)
	var lg: Array = World.LEAGUES[int(Game.S.get("league", 0))]["clubs"]
	var a_str: bool = striped(ac)
	var d_str: bool = striped(dc) and dm == Color(str(dc["c1"]))
	kits = [[am, Color(str(ac["c2"])), a_str], [dm, dt, d_str]]
	banner = "ATAQUE DO %s" % str(ac["name"]).to_upper()

	# --- atacantes (quem foi expulso não entra)
	var aslots: Array = Game.FORMATIONS[ac["formation"]]
	var anum := _numbers(aslots)
	var mids: Array = []
	var fwd: Array = []
	for i in 11:
		if sim.is_out_of_play(ac["xi"][i]):
			continue
		var ps: String = aslots[i][0]
		if ps in ["MEI", "VOL"]:
			mids.append(i)
		elif ps in ["PD", "PE", "AC"]:
			fwd.append(i)
	if mids.is_empty() and fwd.is_empty():
		for i in 11:
			if not sim.is_out_of_play(ac["xi"][i]) and aslots[i][0] != "GOL":
				mids.append(i)
	var cs: int = mids[Game.rng.randi_range(0, mids.size() - 1)] if not mids.is_empty() else fwd[0]
	var my_i: int = ac["xi"].find(me_pid) if me_pid >= 0 else -1
	if my_i >= 0 and aslots[my_i][0] != "GOL" and not sim.is_out_of_play(me_pid):
		cs = my_i   # o lance começa com o seu jogador
		if not (my_i in mids) and not (my_i in fwd):
			mids.append(my_i)
	var order: Array = [cs]
	for i in fwd:
		if i != cs:
			order.append(i)
	for i in mids:
		if i != cs and order.size() < 6:
			order.append(i)
	for i in order:
		var sl: Array = aslots[i]
		var x: float = (float(sl[1]) - 0.5) * 40.0
		var pos := Vector2(x, 33.0 + Game.rng.randf_range(0.0, 4.0))
		if i == cs:
			pos = Vector2(x * 0.5, 41.0)
		elif sl[0] in ["PD", "PE", "AC"]:
			pos = Vector2(x, 19.0 + (0.9 - float(sl[2])) * 30.0 + Game.rng.randf_range(0.0, 3.0))
		var e := _ent(Game.player(ac["xi"][i]), pos, anum[i])
		e["fwd"] = sl[0] in ["PD", "PE", "AC"]
		att.append(e)
	carrier = 0

	# --- defensores: linha de 4 (ou 3/5), volantes protegendo, goleiro
	var dslots: Array = Game.FORMATIONS[dc["formation"]]
	var dnum := _numbers(dslots)
	for i in 11:
		var pid: int = dc["xi"][i]
		if sim.is_out_of_play(pid):
			continue
		var ps2: String = dslots[i][0]
		var x2: float = -(float(dslots[i][1]) - 0.5) * 50.0
		if ps2 == "GOL":
			gk = _ent(Game.player(pid), Vector2(0, 1.3), dnum[i])
		elif ps2 in ["ZAG", "LD", "LE"]:
			var d := _ent(Game.player(pid), Vector2(x2, 18.0), dnum[i])
			d["role"] = "line"
			dfn.append(d)
		elif ps2 == "VOL":
			var d2 := _ent(Game.player(pid), Vector2(x2, 28.0 + Game.rng.randf_range(0.0, 3.0)), dnum[i])
			d2["role"] = "mid"
			dfn.append(d2)
	if gk.is_empty():
		# goleiro expulso: um zagueiro vai para o gol
		gk = dfn.pop_front() if not dfn.is_empty() else _ent(Game.player(dc["xi"][0]), Vector2(0, 1.3), 1)
		gk["pos"] = Vector2(0, 1.3)
	# face: 1 = de frente para a câmera (para baixo na tela), -1 = de costas.
	# O gol atacado fica em cima: a zaga e o goleiro olham para baixo; o ataque, para cima.
	gk["face"] = 1.0
	for d in dfn:
		d["face"] = 1.0
		d["home"] = d["pos"]
	for e in att:
		e["face"] = -1.0
	_load_tuning()
	bp.place(att[0]["pos"] + Vector2(0, -0.6))
	referee = {"p": {"id": 3}, "pos": bp.pos + Vector2(9, 6), "num": 0, "ph": 0.0, "moving": false, "dir": Vector2(0, -1),
		"face": 1.0, "skin": SKINS[1], "hair": HAIRS[0]}
	if script_kind == "penalty":
		_setup_penalty(att[0]["pos"])


## Lê do arquivo de ajuste os números que a zaga usa a cada quadro.
func _load_tuning() -> void:
	_tz_depth = Tuning.f("zaga", "profundidade_linha", 10.0)
	_tz_line_min = Tuning.f("zaga", "linha_minima", 6.0)
	_tz_line_max = Tuning.f("zaga", "linha_maxima", 30.0)
	_tz_compact = Tuning.f("zaga", "compactacao", 0.62)
	_tz_shift = Tuning.f("zaga", "deslocar_para_bola", 0.35)
	_tz_cover = Tuning.f("zaga", "distancia_cobertura", 2.4)
	_tz_cut_react = Tuning.f("passe", "reacao_corte", 0.18)


## Caixa arredondada (estilo dos menus), com cache dos estilos.
func _rbox(r: Rect2, col: Color, rad: int = 14) -> void:
	var key := "%s|%d" % [col.to_html(), rad]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(rad)
		sb.corner_detail = 8
		sb.anti_aliasing = true
		_boxes[key] = sb
	draw_style_box(sb, r)


## Gramado com faixas largas (como na TV), em toda a área visível.
func _pitch_bands() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PITCH)
	var ya: float = _s2w(Vector2(0, 0)).y
	var yb: float = _s2w(Vector2(0, size.y)).y
	var lo := floori(minf(ya, yb) / STRIPE_M)
	var hi := ceili(maxf(ya, yb) / STRIPE_M)
	var dark := PITCH.darkened(0.085)
	for k in range(lo, hi + 1):
		if k % 2 == 0:
			continue
		var a := _w2s(Vector2(0, k * STRIPE_M))
		var b := _w2s(Vector2(0, (k + 1) * STRIPE_M))
		draw_rect(Rect2(0, minf(a.y, b.y), size.x, absf(b.y - a.y)), dark)


## Placas de publicidade do datapack atrás da linha de fundo (y do gol, dirv = para onde fica o campo,
## gap = metros entre a linha de fundo e as placas). As placas ficam em pé: sobem na tela a partir da base.
func _draw_adboards(goal_y: float, dirv: float, gap: float = 4.6) -> void:
	var base := _w2s(Vector2(-60.0, goal_y - dirv * gap))
	var hpx: float = AD_H * s
	var top_y: float = base.y - hpx
	draw_rect(Rect2(0, top_y - 4.0, size.x, hpx + 8.0), Color("1c2a5a"))
	if ads.is_empty():
		return
	var x: float = -fmod(ad_t * 18.0, 4000.0)
	var i := 0
	var guard := 0
	while x < size.x and guard < 80:
		guard += 1
		var tex: Texture2D = ads[i % ads.size()]
		var ts := tex.get_size()
		var w: float = hpx * ts.x / maxf(ts.y, 1.0)
		if x + w > 0.0:
			draw_texture_rect(tex, Rect2(x, top_y, w, hpx), false)
		x += w
		i += 1
		if x < 0.0 and i > ads.size() * 6:
			break
	draw_rect(Rect2(0, top_y + hpx, size.x, 3.0), Color(0, 0, 0, 0.35))


## Comemoração: o autor do gol grande na tela, "GOOOOOL!!" e o nome (como no WSC).
func _draw_celebration(f: Font) -> void:
	if cel_t <= 0.0 or cel_ent.is_empty():
		return
	var k: float = clampf(cel_t / 0.25, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.03, 0.42 * k))
	var mid := size.x / 2.0
	var e: Dictionary = cel_ent.duplicate()
	e["screen"] = Vector2(mid, size.y * 0.5 - absf(sin(cel_t * 7.0)) * 12.0)
	e["cheer"] = true
	e["moving"] = false
	e["spd"] = 0.0
	e["face"] = 1.0
	e["dir"] = Vector2(0, 1)
	var s0 := s
	s = s * 2.7 * (0.7 + 0.3 * k)
	_draw_player(e, cel_ent.get("kit", kits[0]), false)
	s = s0
	var big := "GOOOOOL!!"
	var y0: float = size.y * 0.5 + 54.0
	draw_string(f, Vector2(2, y0 + 3), big, HORIZONTAL_ALIGNMENT_CENTER, size.x, 46, Color(0, 0, 0, 0.45))
	draw_string(f, Vector2(0, y0), big, HORIZONTAL_ALIGNMENT_CENTER, size.x, 46, Color.WHITE)
	draw_string(f, Vector2(0, y0 + 40), "%s marca!" % cel_name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color(1, 1, 1, 0.92))


func start_celebration(e: Dictionary, kit: Array, name: String) -> void:
	cel_ent = e.duplicate()
	cel_ent["kit"] = kit
	cel_name = name
	cel_t = 0.001


## Camisa listrada? (pelo nome original do clube na sua liga; convidados das copas também)
static func striped(c: Dictionary) -> bool:
	var ci: int = int(c.get("ci", c["id"]))
	if ci < 0:
		return false
	var lg: Array = World.LEAGUES[int(c.get("li", Game.S.get("league", 0)))]["clubs"]
	return ci < lg.size() and lg[ci][0] in World.STRIPED


func _close(a: Color, b: Color) -> bool:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() < 0.4


func _ent(p: Dictionary, pos: Vector2, num: int) -> Dictionary:
	var id: int = p["id"]
	return {"p": p, "pos": pos, "num": num, "a": Game.attrs(p), "ph": float(id % 7), "moving": false, "run": pos,
		"home": pos, "stun": 0.0, "dir": Vector2(0, -1), "face": 1.0, "role": "", "fwd": false,
		"skin": SKINS[int(p.get("look_skin", (id * 3) % SKINS.size()))], "hair": HAIRS[int(p.get("look_hcolor", (id * 5) % HAIRS.size()))]}


func _numbers(slots: Array) -> Array:
	var pool := {"GOL": [1], "LD": [2], "LE": [6], "ZAG": [3, 4, 13], "VOL": [5, 15], "MEI": [8, 10, 20], "PD": [7], "PE": [11], "AC": [9, 19]}
	var used := {}
	var out: Array = []
	for sl in slots:
		var k: int = int(used.get(sl[0], 0))
		var arr: Array = pool[sl[0]]
		out.append(arr[k] if k < arr.size() else 20 + out.size())
		used[sl[0]] = k + 1
	return out


func _spd(e: Dictionary) -> float:
	return 5.0 + float(e["a"]["vel"]) * 0.035


## Move a entidade em direção ao alvo. A passada da animação anda junto
## com a distância percorrida, então o pé não "escorrega" no gramado.
func _move(e: Dictionary, target: Vector2, speed: float, delta: float) -> void:
	var d: Vector2 = target - e["pos"]
	if d.length() < 0.08:
		e["moving"] = false
		e["spd"] = lerpf(float(e.get("spd", 0.0)), 0.0, clampf(delta * 10.0, 0.0, 1.0))
		return
	var stepv: Vector2 = d.limit_length(speed * delta)
	e["pos"] += stepv
	e["ph"] += stepv.length() * STRIDE
	e["spd"] = stepv.length() / maxf(delta, 0.001)
	e["moving"] = true
	e["dir"] = e["dir"].lerp(d.normalized(), clampf(delta * 12.0, 0.0, 1.0)).normalized()


func _defenders_y() -> Array:
	var ys: Array = [gk["pos"].y]
	for d in dfn:
		ys.append(d["pos"].y)
	return ys


func _say(text: String, dur: float = 1.1) -> void:
	banner = text
	banner_t = dur


# ------------------------------------------------------------ organização da zaga
## Afasta jogadores que ficaram encostados (ninguém atravessa ninguém).
## min_d = distância mínima entre dois jogadores, em metros.
## (As posições são copiadas para um array compacto, resolvidas ali e devolvidas só se algo mexeu.)
func _separate(ents: Array, min_d: float = 0.9) -> void:
	var n_e := ents.size()
	_sep_pos.resize(n_e)
	for i in n_e:
		_sep_pos[i] = ents[i]["pos"]
	var moved := false
	for i in n_e:
		for j in range(i + 1, n_e):
			var d: Vector2 = _sep_pos[j] - _sep_pos[i]
			var dist := d.length()
			if dist < min_d:
				var n: Vector2 = d / dist if dist > 0.001 else Vector2(1, 0)
				var push := (min_d - dist) * 0.5
				_sep_pos[i] -= n * push
				_sep_pos[j] += n * push
				moved = true
	if moved:
		for i in n_e:
			ents[i]["pos"] = _sep_pos[i]


## Todos os jogadores em campo (atacantes, zaga e goleiro), num array reaproveitado.
func _everyone() -> Array:
	var sig: int = att.size() * 1000 + dfn.size()
	if sig != _sep_sig:
		_sep_sig = sig
		_sep_ents = att + dfn + [gk]
	return _sep_ents


## Atualiza a linha da zaga: acompanha a bola, sem passar dos limites do arquivo de ajuste.
func _update_line() -> void:
	var target := clampf(bp.pos.y - _tz_depth, _tz_line_min, _tz_line_max)
	line_y = lerpf(line_y, target, 0.08)


## Para onde cada defensor vai neste quadro.
func _defender_target(j: int) -> Vector2:
	var d: Dictionary = dfn[j]
	var compact := _tz_compact
	var shift := _tz_shift
	if j == presser:
		return att[carrier]["pos"] + Vector2(0, -0.8)
	if d["role"] == "line":
		var tx: float = d["home"].x * compact + bp.pos.x * shift
		var ty := line_y
		# cobertura: o vizinho do zagueiro que saiu no bote recua um pouco
		if presser >= 0 and dfn[presser]["role"] == "line" and absf(dfn[presser]["home"].x - d["home"].x) < 16.0:
			ty -= _tz_cover
			tx = lerpf(tx, dfn[presser]["home"].x * compact, 0.3)
		return Vector2(tx, ty)
	# volante: fica na linha de passe entre a bola e o atacante mais perigoso
	var danger := -1
	var dy := 1e9
	for i in att.size():
		if i != carrier and att[i]["pos"].y < dy:
			dy = att[i]["pos"].y
			danger = i
	if danger >= 0:
		var mid: Vector2 = bp.pos.lerp(att[danger]["pos"], 0.45)
		return Vector2(lerpf(mid.x, d["home"].x * compact, 0.3), maxf(mid.y, line_y + 4.0))
	return d["home"]


# ------------------------------------------------------------ fases
func _start_run(dur: float) -> void:
	run_time = dur
	state = "run"
	t = 0.0
	for i in att.size():
		var e: Dictionary = att[i]
		if e["fwd"]:
			# atacante tenta passar da linha da zaga (pode ficar impedido)
			e["run"] = Vector2(clampf(e["pos"].x * 0.85 + Game.rng.randf_range(-3.0, 3.0), -28.0, 28.0),
				maxf(line_y + Game.rng.randf_range(-2.0, 3.0), 5.0))
		else:
			e["run"] = Vector2(clampf(e["pos"].x * 0.85 + Game.rng.randf_range(-3.0, 3.0), -30.0, 30.0),
				maxf(e["pos"].y - Game.rng.randf_range(4.0, 8.0), line_y + 3.0))
	presser = -1
	var bd := 1e9
	for j in dfn.size():
		if dfn[j]["stun"] > 0.0 or j in wall:
			continue
		var dist: float = dfn[j]["pos"].distance_to(att[carrier]["pos"])
		if dist < bd:
			bd = dist
			presser = j


func _move_all(delta: float, chase_ball: bool = false) -> void:
	_update_line()
	for i in att.size():
		var e: Dictionary = att[i]
		if i == carrier and state != "pass":
			if state == "run":
				_move(e, Vector2(e["pos"].x * 0.75, maxf(e["pos"].y - 12.0, 7.0)), _spd(e) * 0.8, delta)
		elif state == "pass" and i == pass_to:
			# vai ao ponto do passe; quando a bola chega perto, ataca a bola
			var go: Vector2 = pass_end
			if not bp.in_air() and (bp.pos.distance_to(e["pos"]) < 5.0 or bp.speed() < 4.0):
				go = bp.pos
			_move(e, go, _spd(e), delta)
		else:
			_move(e, e["run"], _spd(e) * 0.75, delta)
	for j in dfn.size():
		var d: Dictionary = dfn[j]
		if j in wall:
			continue
		if d["stun"] > 0.0:
			d["stun"] -= delta
			d["moving"] = false
			continue
		if chase_ball and not pass_lofted and t > _tz_cut_react:
			# tenta cortar a linha do passe (depois de reagir, e só se estiver perto)
			var seg: Vector2 = pass_end - bp.pos
			var k: float = clampf((d["pos"] - bp.pos).dot(seg) / maxf(seg.length_squared(), 0.01), 0.0, 1.0)
			var on_line: Vector2 = bp.pos + seg * k
			if d["pos"].distance_to(on_line) < 4.0:
				_move(d, on_line, _spd(d) * 0.7, delta)
				continue
		elif chase_ball and pass_lofted and d["pos"].distance_to(pass_end) < 7.0:
			_move(d, pass_end, _spd(d) * 0.95, delta)
			continue
		var sp := 0.9 if j == presser else 0.8
		_move(d, _defender_target(j), _spd(d) * sp, delta)
	if state != "shot":
		_move(gk, Vector2(clampf(bp.pos.x * 0.14, -2.6, 2.6), 1.3), 3.0, delta)


# ------------------------------------------------------------ bote e árbitro
func _end_run() -> void:
	if presser >= 0 and setpiece == "":
		var d: Dictionary = dfn[presser]
		var c: Dictionary = att[carrier]
		if d["pos"].distance_to(c["pos"]) < 1.6 and d["stun"] <= 0.0:
			if user_ctrl and moments == 0:
				d["stun"] = 0.8   # no primeiro toque você sempre tem a chance de decidir
			elif user_ctrl:
				var att_skill: float = (float(c["a"]["vel"]) + float(c["a"]["pas"])) / 2.0
				var res: Dictionary = ref.judge_tackle(float(d["a"]["des"]), att_skill)
				if res["tipo"] == "limpo":
					_finish("lost", "Desarmado por %s!" % d["p"]["name"])
					return
				if res["tipo"] == "falta":
					_foul(d, c, res["cartao"], Game.rng.randf() < 0.5)
					return
				d["stun"] = 1.3
			elif script_kind == "lost" and moments >= lost_at:
				_finish("lost", "Desarme de %s!" % d["p"]["name"])
				return
	state = "decide"
	t = 0.0


## Falta do defensor d no atacante c. keeps = o atacante conseguiu seguir com a bola.
func _foul(d: Dictionary, c: Dictionary, card: String, keeps: bool) -> void:
	var dside := 1 - side
	sim.add_foul(dside)
	var where: Vector2 = c["pos"]
	var restart := ref.restart_for_foul(where, keeps)
	if card != "":
		var sent_off := sim.give_card(dside, d["p"]["id"], card)
		card_flash = "vermelho" if sent_off else card
		if sent_off:
			dfn.erase(d)
			presser = -1
	match restart:
		"penalti":
			_say("PÊNALTI!", 1.4)
			_setup_penalty(where)
		"falta_direta":
			_say("FALTA!", 1.2)
			_setup_free_kick(where)
		"vantagem":
			_say("VANTAGEM!", 1.0)
			d["stun"] = 1.5
			state = "decide"
			t = 0.0
		_:
			_say("FALTA!", 1.0)
			for o in dfn:
				o["stun"] = 0.8
			bp.place(c["pos"] + Vector2(0, -0.6))
			state = "decide"
			t = 0.0


## Cobrança de pênalti: bola na marca, só o batedor e o goleiro na área.
func _setup_penalty(_where: Vector2) -> void:
	setpiece = "penalti"
	shot_only = true
	header = false
	var c: Dictionary = att[carrier]
	c["pos"] = Vector2(0, Referee.PEN_SPOT + 1.2)
	bp.place(Vector2(0, Referee.PEN_SPOT))
	for i in att.size():
		if i != carrier:
			att[i]["pos"] = Vector2(-16.0 + i * 6.0, Referee.BOX_DEPTH + 3.0)
	for j in dfn.size():
		dfn[j]["pos"] = Vector2(-14.0 + j * 5.0, Referee.BOX_DEPTH + 4.5)
		dfn[j]["stun"] = 99.0
	gk["pos"] = Vector2(0, 0.4)
	presser = -1
	state = "decide"
	t = 0.0


## Falta direta: bola parada e barreira a 9,15 m entre a bola e o gol.
func _setup_free_kick(where: Vector2) -> void:
	setpiece = "falta_direta"
	shot_only = true
	header = false
	bp.place(where)
	att[carrier]["pos"] = where + Vector2(0, 1.0)
	var to_goal := (Vector2(0, 0) - where).normalized()
	var spot := where + to_goal * 9.15
	var perp := Vector2(-to_goal.y, to_goal.x)
	wall.clear()
	var n := mini(4, dfn.size())
	for k in n:
		dfn[k]["pos"] = spot + perp * (float(k) - (n - 1) / 2.0) * 0.6
		dfn[k]["moving"] = false
		wall.append(k)
	for j in range(n, dfn.size()):
		dfn[j]["stun"] = 99.0
	gk["pos"] = Vector2(clampf(where.x * 0.2, -1.5, 1.5), 0.6)
	presser = -1
	state = "decide"
	t = 0.0


# ------------------------------------------------------------ decisões da máquina
func _ai_decide() -> void:
	var c: Dictionary = att[carrier]
	if script_kind == "lost" and moments >= lost_at:
		var nm: String = dfn[presser]["p"]["name"] if presser >= 0 and presser < dfn.size() else "zaga"
		_finish("lost", "Desarme de %s!" % nm)
		return
	# modo jogador: o companheiro costuma devolver para você
	if user_ctrl and me_pid >= 0 and not shot_only and moments < 4:
		for i in att.size():
			if i != carrier and int(att[i]["p"]["id"]) == me_pid and Game.rng.randf() < 0.6:
				_do_pass(i, absf(c["pos"].x) > 14.0 and Referee.in_box(att[i]["pos"]))
				return
	if not shot_only and c["pos"].y > 19.0 and moments < 3:
		var opts: Array = []
		for i in att.size():
			if i != carrier and att[i]["pos"].y < c["pos"].y - 3.0:
				opts.append(i)
		if not opts.is_empty():
			var to: int = opts[Game.rng.randi_range(0, opts.size() - 1)]
			var lofted: bool = absf(c["pos"].x) > 14.0 and Referee.in_box(att[to]["pos"])
			_do_pass(to, lofted)
			return
		if script_kind == "offside":
			_do_pass(0 if carrier != 0 else mini(1, att.size() - 1), false)
			return
	var sgn: float = -1.0 if gk["pos"].x > 0.0 else 1.0
	if Game.rng.randf() < 0.3:
		sgn = -sgn
	var tx: float = gk["pos"].x + Game.rng.randf_range(-0.6, 0.6)
	var h := 0.5
	var goal_kind: bool = script_kind == "goal" or (script_kind == "penalty" and sim.penalty_scored)
	if user_ctrl:
		# companheiro do modo jogador: mira num canto, a física decide
		tx = sgn * Game.rng.randf_range(1.2, 3.4)
		h = Game.rng.randf_range(0.3, 1.8)
	if goal_kind:
		tx = sgn * Game.rng.randf_range(2.2, 3.0)
	elif script_kind in ["out", "lost", "offside"]:
		tx = sgn * Game.rng.randf_range(4.4, 6.5)
		if Game.rng.randf() < 0.4:
			tx = sgn * Game.rng.randf_range(0.5, 2.5)
			h = 3.2   # por cima
	_do_shot(tx, h, 0.6)


# ------------------------------------------------------------ passe
## Passe para o atacante i. lofted = passe alto / cruzamento.
func _do_pass(i: int, lofted: bool) -> void:
	var c: Dictionary = att[carrier]
	var r: Dictionary = att[i]
	pass_to = i
	pass_lofted = lofted
	# impedimento é julgado no momento do passe
	pass_offside = Referee.is_offside(r["pos"], bp.pos, _defenders_y())
	if not user_ctrl:
		pass_offside = script_kind == "offside"
	var lead: Vector2 = (r["run"] - r["pos"]).limit_length(3.0 if lofted else 2.0)
	var aim: Vector2 = r["pos"] + lead
	var d: Vector2 = aim - bp.pos
	var dist := d.length()
	if user_ctrl:
		var deg := Tuning.f("passe", "erro_base_graus", 1.5) + (100.0 - float(c["a"]["pas"])) * Tuning.f("passe", "erro_por_ponto_faltando", 0.09)
		var near := 1e9
		for o in dfn:
			near = minf(near, o["pos"].distance_to(c["pos"]))
		var pd := Tuning.f("passe", "distancia_pressao", 3.0)
		if near < pd:
			deg += Tuning.f("passe", "erro_pressao_graus", 4.0) * (1.0 - near / pd)
		if lofted:
			deg *= 1.3
		d = d.rotated(deg_to_rad(Game.rng.randfn(0.0, deg))) * Game.rng.randf_range(0.93, 1.07)
	pass_end = bp.pos + d
	if lofted:
		var apex := Tuning.f("passe", "altura_cruzamento", 3.4) if Referee.in_box(r["pos"]) else Tuning.f("passe", "altura_passe_alto", 4.2)
		bp.kick_lofted(pass_end, apex)
	else:
		var spd := clampf(dist * 0.9 + 8.0, Tuning.f("passe", "velocidade_rasteiro_min", 13.0), Tuning.f("passe", "velocidade_rasteiro_max", 24.0))
		bp.kick_ground(pass_end, spd)
	presser = -1
	c["kick"] = 0.28
	for o in dfn:
		o["tried"] = false
	state = "pass"
	t = 0.0


func _update_pass() -> void:
	var r: Dictionary = att[pass_to]
	# corte de defensor (só no ataque do jogador; o da máquina segue o roteiro)
	if user_ctrl and t > 0.12:
		var passer: Dictionary = att[carrier]
		for d in dfn:
			if d["stun"] > 0.0 or d.get("tried", false):
				continue
			var dist: float = d["pos"].distance_to(bp.pos)
			if bp.z <= Tuning.f("passe", "altura_max_corte_pe", 0.9) and dist < Tuning.f("passe", "alcance_corte_pe", 1.0):
				# uma tentativa por defensor; bola rápida e passe bom são mais difíceis de cortar
				d["tried"] = true
				var pc := Tuning.f("passe", "chance_corte_base", 0.4) + (float(d["a"]["des"]) - float(passer["a"]["pas"])) / 150.0 \
					- bp.speed() / 60.0
				if Game.rng.randf() < clampf(pc, 0.1, 0.7):
					_finish("lost", "Passe cortado por %s!" % d["p"]["name"])
					return
			if bp.z <= Tuning.f("passe", "altura_max_corte_cabeca", 2.3) and bp.z > 1.2 and dist < Tuning.f("passe", "alcance_corte_cabeca", 1.25):
				if Game.rng.randf() < 0.5 + (float(d["a"]["des"]) - float(r["a"]["vel"])) / 200.0:
					_finish("lost", "%s ganha pelo alto!" % d["p"]["name"])
					return
	# chegou no recebedor?
	if r["pos"].distance_to(bp.pos) < 1.3 and bp.z < 2.1:
		if pass_offside:
			_finish("offside", "IMPEDIMENTO!")
			return
		last_passer = carrier
		carrier = pass_to
		moments += 1
		if bp.z > 0.5:
			# bola pelo alto: cabeceio dentro da área, senão precisa dominar
			if Referee.in_box(r["pos"]) and bp.z > 1.0:
				header = true
				shot_only = true
				state = "decide"
				t = 0.0
				return
			var ctrl := Tuning.f("passe", "chance_dominio_alto", 0.82) + (float(r["a"]["pas"]) - 75.0) / 200.0
			if user_ctrl and Game.rng.randf() > ctrl:
				_finish("lost", "%s dominou mal!" % r["p"]["name"])
				return
		bp.place(r["pos"] + Vector2(0, -0.6))
		_start_run(0.75)
		return
	# bola parou ou passou longe
	if not bp.in_air():
		var away: bool = (bp.pos - r["pos"]).dot(bp.vel) > 0.0 and bp.pos.distance_to(r["pos"]) > 4.0
		if bp.speed() < 0.6 or away:
			_finish("lost", "Passe errado!")
			return
	if t > 4.0:
		_finish("lost", "Passe errado!")


# ------------------------------------------------------------ chute
## Chute mirando x na linha do gol, altura h (metros) e força p (0..1).
func _do_shot(tx: float, h: float, p: float) -> void:
	var c: Dictionary = att[carrier]
	shot_from = bp.pos
	var chu := float(c["a"]["chu"])
	var target := Vector2(clampf(tx, -9.0, 9.0), -0.3)
	var d: Vector2 = target - bp.pos
	var spd: float
	var deg: float
	if header:
		spd = Tuning.f("chute", "velocidade_cabeceio", 14.0) + chu * 0.03
		deg = Tuning.f("chute", "erro_cabeceio_graus", 5.0) + (100.0 - chu) * 0.05
		h = minf(h, 1.6)
	else:
		spd = lerpf(Tuning.f("chute", "velocidade_min", 16.0), Tuning.f("chute", "velocidade_max", 31.0), p) * (0.85 + chu / 650.0)
		deg = Tuning.f("chute", "erro_base_graus", 1.2) + (100.0 - chu) * Tuning.f("chute", "erro_por_ponto_faltando", 0.10) \
			+ Tuning.f("chute", "erro_por_forca_graus", 3.0) * p * p
	if setpiece == "penalti":
		deg *= 0.6
	if not user_ctrl:
		deg *= 0.25   # a máquina segue o resultado já sorteado
	d = d.rotated(deg_to_rad(Game.rng.randfn(0.0, deg)))
	var dist := d.length()
	var tt := dist / spd
	var g := bp.gravity
	var start_z := 1.6 if header else 0.05
	var vz := (h - start_z + 0.5 * g * tt * tt) / tt
	if user_ctrl and not header:
		# muita força faz a bola subir demais
		vz += Game.rng.randfn(0.0, 0.3 + p * Tuning.f("chute", "subida_por_forca", 3.4) * (1.25 - chu / 100.0) * 0.5)
	bp.kick_shot(d, spd, vz)
	bp.z = start_z
	c["kick"] = 0.32
	# goleiro
	var gko: float = float(gk["p"]["ovr"])
	gk_react = Tuning.f("goleiro", "reacao_base", 0.12) + (99.0 - gko) * Tuning.f("goleiro", "reacao_por_ponto_faltando", 0.004)
	gk_speed = Tuning.f("goleiro", "velocidade_base", 2.6) + gko * Tuning.f("goleiro", "velocidade_por_ponto", 0.024)
	gk_dive_x = gk["pos"].x
	if setpiece == "penalti":
		# no pênalti o goleiro escolhe um canto antes do chute
		gk_dive_x = [-2.8, 0.0, 2.8][Game.rng.randi_range(0, 2)]
		gk_react = 0.0
		gk_speed = 9.0
	var goal_kind: bool = script_kind == "goal" or (script_kind == "penalty" and sim.penalty_scored)
	if not user_ctrl:
		if goal_kind:
			gk_speed = 1.2
			gk_react = 0.35
			gk_dive_x = -signf(tx) * 2.5
		elif script_kind == "save" or script_kind == "penalty":
			gk_speed = 14.0
			gk_react = 0.04
			gk_dive_x = tx
	for k in wall:
		dfn[k]["stun"] = 0.0
	for o in dfn:
		o["tried"] = false
	gk_checked = false
	state = "shot"
	t = 0.0


func _update_shot(delta: float) -> void:
	var cross := bp.goal_line_crossing()
	# goleiro se joga para onde a bola vai cruzar a linha
	if t > gk_react:
		var target_x: float = gk_dive_x
		if setpiece != "penalti" and not cross.is_empty():
			target_x = cross["x"]
		var tx := clampf(target_x, -4.2, 4.2)
		var gap: float = tx - gk["pos"].x
		gk_tilt = lerpf(gk_tilt, clampf(gap / 1.2, -1.0, 1.0) * 1.15, clampf(delta * 14.0, 0.0, 1.0))
		gk["pos"].x = move_toward(gk["pos"].x, tx, gk_speed * delta)
		gk["ph"] += delta * 11.0
	# barreira e zagueiros podem travar o chute
	if bp.pos.distance_to(shot_from) > 1.5 and bp.pos.y > 2.5:
		for j in dfn.size():
			var d: Dictionary = dfn[j]
			var reach := 0.55 if j in wall else 0.65
			var top := 1.95 if j in wall else 1.7
			if d.get("tried", false):
				continue
			if d["pos"].distance_to(bp.pos) < reach and bp.z < top and (user_ctrl or script_kind == "lost"):
				d["tried"] = true
				if j not in wall and Game.rng.randf() > Tuning.f("chute", "chance_travar", 0.45):
					continue
				bp.vel = Vector2(Game.rng.randf_range(-5.0, 5.0), 6.0)
				bp.vz = 2.0
				_finish("blocked", "Travado por %s!" % d["p"]["name"])
				return
	# goleiro alcança?
	if not gk_checked and bp.pos.y <= gk["pos"].y + 0.25:
		gk_checked = true
		var lat := absf(bp.pos.x - gk["pos"].x)
		var reach_l := Tuning.f("goleiro", "alcance_lateral", 1.15)
		var reach_h := Tuning.f("goleiro", "alcance_alto", 2.55)
		var saved := lat <= reach_l and bp.z <= reach_h
		if saved and bp.z > 1.7 and lat > 0.6:
			saved = Game.rng.randf() < Tuning.f("goleiro", "chance_espalmar_canto_alto", 0.55)
		var goal_kind: bool = script_kind == "goal" or (script_kind == "penalty" and sim.penalty_scored)
		if not user_ctrl and goal_kind:
			saved = false
		if saved:
			bp.vel = Vector2(Game.rng.randf_range(-7.0, 7.0), Game.rng.randf_range(5.0, 9.0))
			bp.vz = 2.5
			_finish("save", "Defesa de %s!" % gk["p"]["name"])
			return
	if bp.pos.y <= 0.0:
		var kind := BallPhysics.classify_crossing(bp.pos.x, bp.z)
		match kind:
			"gol":
				_finish("goal", "GOOOL!" if setpiece != "penalti" else "GOOOL DE PÊNALTI!")
			"trave":
				bp.vel = Vector2(-bp.vel.x * 0.5, 7.0)
				_finish("out", "Na trave!")
			"travessao":
				bp.vel = Vector2(bp.vel.x * 0.3, 6.0)
				bp.vz = -2.0
				_finish("out", "No travessão!")
			"por_cima":
				_finish("out", "Por cima do gol!")
			_:
				_finish("out", "Pra fora!")
		return
	if t > 3.0:
		_finish("out", "Pra fora!")


func _finish(kind: String, text: String) -> void:
	var apid := 0
	if kind == "goal" and last_passer >= 0 and last_passer != carrier and setpiece == "":
		apid = att[last_passer]["p"]["id"]
	result = {"goal": kind == "goal", "kind": kind, "pid": att[carrier]["p"]["id"], "apid": apid, "pen": setpiece == "penalti"}
	banner = text
	banner_t = 99.0
	state = "end"
	t = 0.0


## Pula o lance da máquina e aplica o resultado já sorteado.
func skip() -> void:
	if user_ctrl or state == "end" or state == "done":
		return
	var best := 0
	for i in att.size():
		if att[i]["pos"].y < att[best]["pos"].y:
			best = i
	carrier = best
	var kind := script_kind
	if kind == "penalty":
		kind = "goal" if sim.penalty_scored else "save"
		setpiece = "penalti"
	var texts := {"goal": "GOOOL!", "save": "Defesa de %s!" % gk["p"]["name"], "out": "Pra fora!", "lost": "A zaga cortou!", "offside": "IMPEDIMENTO!"}
	_finish(kind, texts[kind])
	t = 0.9


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	t += delta
	ad_t += delta
	if cel_t > 0.0:
		cel_t += delta
	if banner_t > 0.0 and state != "end":
		banner_t -= delta
		if banner_t <= 0.0:
			banner = ""
			card_flash = ""
	for e in att:
		if float(e.get("kick", 0.0)) > 0.0:
			e["kick"] = float(e["kick"]) - delta
	match state:
		"intro":
			if t > 0.9:
				banner = ""
				_start_run(0.9)
		"run":
			_move_all(delta)
			var ce: Dictionary = att[carrier]
			var touch: float = 0.3 + 0.22 * (0.5 + 0.5 * sin(float(ce["ph"]) * 0.5))   # toquinhos na bola
			bp.place(ce["pos"] + ce["dir"] * touch)
			bp.spin += float(ce.get("spd", 0.0)) * delta * 1.6
			if t > run_time:
				_end_run()
		"decide":
			var mate: bool = user_ctrl and me_pid >= 0 and int(att[carrier]["p"]["id"]) != me_pid
			if (not user_ctrl or mate) and t > (0.9 if setpiece != "" else 0.55):
				_ai_decide()
		"pass":
			bp.step(delta)
			_move_all(delta, user_ctrl)
			_update_pass()
		"shot":
			bp.step(delta)
			_move_all(delta)
			_update_shot(delta)
		"end":
			bp.step(delta)
			if result.get("goal", false):
				bp.pos.y = maxf(bp.pos.y, -2.1)
				bp.pos.x = clampf(bp.pos.x, -GOAL_HALF + 0.2, GOAL_HALF - 0.2)
				if bp.pos.y <= -2.0:
					bp.vel = Vector2.ZERO
			if result.get("goal", false) and cel_t <= 0.0:
				start_celebration(att[carrier], kits[0], str(att[carrier]["p"]["name"]))
			if t > (2.9 if result.get("goal", false) else 1.5):
				state = "done"
				finished.emit(result)
	if state in SEP_STATES:
		_separate(_everyone())
	# árbitro acompanha a jogada de perto, sem atrapalhar
	var rt := Vector2(clampf(bp.pos.x + 9.0, -30.0, 30.0), clampf(bp.pos.y + 7.0, 3.0, 60.0))
	_move(referee, rt, 6.5, delta)
	# câmera: cam_y = y do mundo no topo da tela. A bola fica a 62% da altura, então
	# há mais campo à frente dela (acima, rumo ao gol). No máximo, o topo mostra as placas.
	if size.x > 0.0:
		s = size.x / CAMERA_WIDTH_M   # mesma escala do _draw (o limite da câmera depende dela)
	var vh: float = size.y / s
	var cam_min: float = _cam_min_y()
	var target: float = clampf(bp.pos.y - vh * 0.62, cam_min, maxf(56.0 - vh, cam_min))
	cam_y = lerpf(cam_y, target, clampf(delta * 4.0, 0.0, 1.0))
	queue_redraw()


## Menor cam_y do lance: o alto das placas atrás do gol encosta logo abaixo do placar.
func _cam_min_y() -> float:
	return -(AD_GAP + AD_H) - HUD_TOP / maxf(s, 1.0)


# ------------------------------------------------------------ toque
## Mundo -> tela. O gol atacado (y = 0) fica em cima; cam_y é o y do mundo no topo da tela.
func _w2s(w: Vector2) -> Vector2:
	return Vector2(size.x / 2.0 + w.x * s, (w.y - cam_y) * s)


## Tela -> mundo (inverso de _w2s).
func _s2w(p: Vector2) -> Vector2:
	return Vector2((p.x - size.x / 2.0) / s, cam_y + p.y / s)


## A mesma conversão de _w2s como Transform2D (para converter muitos pontos de uma vez).
func _w2s_xf() -> Transform2D:
	return Transform2D(Vector2(s, 0.0), Vector2(0.0, s), Vector2(size.x / 2.0, -cam_y * s))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and pressing:
		drag_now = e.position
	if not (e is InputEventMouseButton) or e.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if e.pressed:
		if not user_ctrl and Rect2(size.x - 190, 80, 180, 56).has_point(e.position):
			skip()
			return
		pressing = true
		press = e.position
		press_ms = Time.get_ticks_msec()
		drag_now = e.position
		return
	if not pressing:
		return
	pressing = false
	if state != "decide" or not user_ctrl:
		return
	if me_pid >= 0 and int(att[carrier]["p"]["id"]) != me_pid:
		return   # a bola está com um companheiro
	var held: float = (Time.get_ticks_msec() - press_ms) / 1000.0
	var drag: Vector2 = e.position - press
	if drag.length() >= 40.0:
		# deslizar (para cima, rumo ao gol): direção = mira, comprimento = força
		var dir := Vector2(drag.x, drag.y * y_sign).normalized()
		if dir.y < -0.08:
			var p := clampf(drag.length() / Tuning.f("chute", "arraste_para_forca_maxima_px", 260.0), 0.2, 1.0)
			_do_shot(bp.pos.x + dir.x / -dir.y * bp.pos.y, 0.4 + p * 1.2, p)
		return
	if not shot_only:
		var best := -1
		var bd := 58.0
		for i in att.size():
			if i == carrier:
				continue
			var dd: float = (_w2s(att[i]["pos"]) - Vector2(0, 18)).distance_to(e.position)
			if dd < bd:
				bd = dd
				best = i
		if best >= 0:
			_do_pass(best, held >= Tuning.f("passe", "toque_longo_segundos", 0.35))
			return
	var w := _s2w(e.position)
	# o gol fica em pé sobre a linha (y = 0): subir na tela a partir da linha = mais alto no gol
	var up_m: float = -w.y * y_sign
	if absf(w.x) < 5.6 and up_m < BallPhysics.CROSSBAR * LIFT + 0.8 and up_m > -2.0:
		# toque perto do chão = chute rasteiro; perto do travessão = chute alto
		var h := clampf(up_m / LIFT, 0.1, 2.3)
		_do_shot(w.x, h, 0.55)


# ------------------------------------------------------------ desenho
func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
	draw_circle(Vector2.ZERO, rx, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------ desenho em lote
# Bonecos e bola não usam draw_circle/draw_rect soltos (cada círculo virava uma draw call
# com buffer próprio: ~70 por boneco). As formas viram triângulos num lote único e o lote
# vai para a tela numa chamada só (_flush). O formato de cada peça é o mesmo de antes.
#   _q_*        ..... acrescenta uma forma em _lp (coordenadas locais) e a cor em _bc
#   _commit(xf) ..... leva _lp para a tela com a transformação do boneco
#   _flush()    ..... desenha o lote acumulado

## Quantos lados o círculo precisa para parecer redondo com raio r_px na tela.
static func _circle_n(r_px: float) -> int:
	if r_px < 5.0:
		return 16
	if r_px < 10.0:
		return 24
	if r_px < 20.0:
		return 32
	if r_px < 40.0:
		return 48
	return 64


## Círculo unitário em triângulos (n lados), gerado uma vez.
static func _circle_tris(n: int) -> PackedVector2Array:
	var got: PackedVector2Array = _tmpl.get(n, PackedVector2Array())
	if not got.is_empty():
		return got
	var out := PackedVector2Array()
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		out.append(Vector2.ZERO)
		out.append(Vector2(cos(a0), sin(a0)))
		out.append(Vector2(cos(a1), sin(a1)))
	_tmpl[n] = out
	return out


## Um quarto de círculo unitário (q: 0 sup. esq., 1 sup. dir., 2 inf. dir., 3 inf. esq.), n/4 lados.
static func _quarter_tris(n: int, q: int) -> PackedVector2Array:
	var key := 1000 + n * 4 + q
	var got: PackedVector2Array = _tmpl.get(key, PackedVector2Array())
	if not got.is_empty():
		return got
	var out := PackedVector2Array()
	var m := maxi(n / 4, 2)
	var start: float = [PI, PI * 1.5, 0.0, PI * 0.5][q]
	for i in m:
		var a0: float = start + PI * 0.5 * i / m
		var a1: float = start + PI * 0.5 * (i + 1) / m
		out.append(Vector2.ZERO)
		out.append(Vector2(cos(a0), sin(a0)))
		out.append(Vector2(cos(a1), sin(a1)))
	_tmpl[key] = out
	return out


## Polígono convexo (lista de pontos) em leque de triângulos, guardado com um nome.
static func _fan_tmpl(key: String, pts: PackedVector2Array) -> PackedVector2Array:
	var got: PackedVector2Array = _tmpl.get(key, PackedVector2Array())
	if not got.is_empty():
		return got
	var out := PackedVector2Array()
	for i in range(1, pts.size() - 1):
		out.append(pts[0])
		out.append(pts[i])
		out.append(pts[i + 1])
	_tmpl[key] = out
	return out


## Pentágono unitário da bola.
static func _pent_tris() -> PackedVector2Array:
	if _tmpl.has("pent"):
		return _tmpl["pent"]
	var pts := PackedVector2Array()
	for j in 5:
		pts.append(Vector2(cos(TAU * j / 5.0), sin(TAU * j / 5.0)))
	return _fan_tmpl("pent", pts)


## Sorriso de frente (meia elipse 8,5 x 4,6) e de lado (5 x 3,6), centrados na boca.
static func _smile_tris(side: bool) -> PackedVector2Array:
	var key := "smile_s" if side else "smile_f"
	if _tmpl.has(key):
		return _tmpl[key]
	var pts := PackedVector2Array()
	var n := 6 if side else 10
	for i in n + 1:
		var ang := PI * i / n
		pts.append(Vector2(cos(ang) * (5.0 if side else 8.5), sin(ang) * (3.6 if side else 4.6)))
	return _fan_tmpl(key, pts)


## Acrescenta n vezes a cor col no lote (listas prontas guardadas por cor e tamanho).
func _fill(col: Color, n: int) -> void:
	var key := Vector4(col.r, col.g, col.b, col.a * 1000.0 + n)
	var a: PackedColorArray = _cfill.get(key, PackedColorArray())
	if a.is_empty():
		if _cfill.size() > 2048:
			_cfill.clear()   # cores que variam a cada quadro (sombras) não acumulam
		a.resize(n)
		a.fill(col)
		_cfill[key] = a
	_bc.append_array(a)


func _q_tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	_lp.append(a)
	_lp.append(b)
	_lp.append(c)
	_fill(col, 3)


func _q_quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, col: Color) -> void:
	_lp.append(a)
	_lp.append(b)
	_lp.append(c)
	_lp.append(a)
	_lp.append(c)
	_lp.append(d)
	_fill(col, 6)


func _q_rect(r: Rect2, col: Color) -> void:
	_q_quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), col)


## Linha com largura w (o mesmo retângulo que draw_line monta).
func _q_line(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var t := (b - a).orthogonal().normalized() * (w * 0.5)
	_q_quad(a - t, a + t, b + t, b - t, col)


func _q_circle(c: Vector2, r: float, col: Color) -> void:
	var tm := _circle_tris(_circle_n(r * _lk))
	_lp.append_array(Transform2D(0.0, Vector2(r, r), 0.0, c) * tm)
	_fill(col, tm.size())


func _q_ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var tm := _circle_tris(_circle_n(maxf(rx, ry) * _lk))
	_lp.append_array(Transform2D(0.0, Vector2(rx, ry), 0.0, c) * tm)
	_fill(col, tm.size())


## Membro com pontas redondas (linha + dois círculos), como antes.
func _q_limb(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	_q_line(a, b, col, w)
	_q_circle(a, w * 0.5, col)
	_q_circle(b, w * 0.5, col)


## Retângulo de cantos redondos (o canto nunca passa da metade do lado menor).
## A forma (tamanho + canto) é montada uma vez e reaproveitada, só deslocada.
func _q_rr(r: Rect2, rad: float, col: Color) -> void:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var n := _circle_n(rad * _lk)
	var key := Vector4(r.size.x, r.size.y, rad, n)
	var tm: PackedVector2Array = _rr_cache.get(key, PackedVector2Array())
	if tm.is_empty():
		if _rr_cache.size() > 1024:
			_rr_cache.clear()
		tm = _rr_tris(r.size, rad, n)
		_rr_cache[key] = tm
	_lp.append_array(Transform2D(0.0, r.position) * tm)
	_fill(col, tm.size())


## Triângulos de um retângulo arredondado em (0, 0): duas faixas em cruz e quatro quartos de círculo.
static func _rr_tris(sz: Vector2, rad: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for rc in [Rect2(rad, 0.0, sz.x - rad * 2.0, sz.y), Rect2(0.0, rad, sz.x, sz.y - rad * 2.0)]:
		var q: Rect2 = rc
		out.append_array(PackedVector2Array([q.position, Vector2(q.end.x, q.position.y), q.end,
			q.position, q.end, Vector2(q.position.x, q.end.y)]))
	var sc := Vector2(rad, rad)
	out.append_array(Transform2D(0.0, sc, 0.0, Vector2(rad, rad)) * _quarter_tris(n, 0))
	out.append_array(Transform2D(0.0, sc, 0.0, Vector2(sz.x - rad, rad)) * _quarter_tris(n, 1))
	out.append_array(Transform2D(0.0, sc, 0.0, Vector2(sz.x - rad, sz.y - rad)) * _quarter_tris(n, 2))
	out.append_array(Transform2D(0.0, sc, 0.0, Vector2(rad, sz.y - rad)) * _quarter_tris(n, 3))
	return out


## Modelo pronto (triângulos) deslocado para o ponto o.
func _q_tmpl(tm: PackedVector2Array, o: Vector2, col: Color) -> void:
	_lp.append_array(Transform2D(0.0, o) * tm)
	_fill(col, tm.size())


func _commit(xf: Transform2D) -> void:
	_bp.append_array(xf * _lp)
	_lp.clear()


func _commit_screen() -> void:
	_bp.append_array(_lp)
	_lp.clear()


## Desenha o lote acumulado numa única chamada.
func _flush() -> void:
	if not _lp.is_empty():
		_commit_screen()
	if not _bp.is_empty():
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), PackedInt32Array(), _bp, _bc)
	_bp.clear()
	_bc.clear()


## Visual guardado do jogador: [estilo do cabelo, barba, cor da chuteira, número como texto].
func _look(e: Dictionary) -> Array:
	var lk: Array = e.get("_look", [])
	if lk.is_empty():
		var look: int = int(e["p"]["id"])
		lk = [int(e["p"].get("look_hstyle", look % 6)), bool(e["p"].get("look_beard", look % 4 == 1)),
			Color(str(e["p"].get("look_boots", "17171b"))), str(e["num"])]
		e["_look"] = lk
	return lk


## Boneco no estilo da referência: cabeção arredondado, sobrancelha grossa,
## olhos em pílula, sorriso branco, corpo pequeno, meião alto e chuteira preta.
## Camisa e meião na cor 1 do time, calção na cor 2. Goleiro de amarelo com luva preta.
## Unidades do corpo: 100 = altura toda (pés em 0, topo da cabeça em -100).
## Frente/costas: e["face"] (1 = de frente para a câmera) quando parado; correndo, vale a
## direção na tela (quem corre para cima, rumo ao gol do lance, aparece de costas).
func _draw_player(e: Dictionary, kit: Array, keeper: bool = false, ref_kit: bool = false) -> void:
	var p: Vector2 = e["screen"] if e.has("screen") else _w2s(e["pos"])
	var ku: float = BODY_H * LIFT * s / 100.0
	var lk := _look(e)
	_lk = 1.0
	if me_pid >= 0 and not ref_kit and int(e["p"]["id"]) == me_pid:
		# seta dourada em cima do seu jogador
		var tip := p + Vector2(0, -116.0 * ku)
		_q_tri(tip, tip + Vector2(-9, -12) * ku, tip + Vector2(9, -12) * ku, UI.GOLD)
		_q_circle(p, 15.0 * ku, Color(UI.GOLD, 0.35))
	var shirt := NEAR_BLACK
	var trim := NEAR_BLACK
	var striped := false
	if keeper:
		shirt = KEEPER_SHIRT
		trim = KEEPER_TRIM
	elif not ref_kit:
		shirt = kit[0]
		trim = kit[1]
		striped = kit.size() > 2 and kit[2]
	var shorts: Color = trim if not _close(trim, shirt) else shirt.darkened(0.22)
	if ref_kit:
		shorts = REF_SHORTS
	var sock: Color = shirt
	var skin: Color = e["skin"]
	var hair: Color = e["hair"]
	var spd: float = float(e.get("spd", 0.0))
	var amp: float = clampf(spd / 6.5, 0.0, 1.0)
	var ph: float = e["ph"]
	var dir: Vector2 = e["dir"]
	var sd := Vector2(dir.x, dir.y * y_sign)     # direção na tela (y para baixo)
	var view := 1 if float(e["face"]) < 0.0 else 0      # 0 frente, 1 costas, 2 lado
	if e["moving"] or amp > 0.05:
		if absf(sd.x) > 0.75:
			view = 2
		else:
			view = 0 if sd.y > 0.0 else 1
	var flip := -1.0 if sd.x < 0.0 else 1.0
	var kick: float = clampf(float(e.get("kick", 0.0)) / 0.3, 0.0, 1.0)
	var dive: float = gk_tilt if keeper else 0.0
	var fwd := Vector2(flip, 0.0) if view == 2 else Vector2(0.0, 1.0 if view == 0 else -1.0)

	_q_ellipse(p + Vector2(2.0 * ku, 0.0), (17.0 + absf(dive) * 20.0) * ku, 5.0 * ku, Color(0, 0, 0, 0.25))
	_commit_screen()
	var xf := Transform2D(dive, Vector2(ku, ku), 0.0, p + Vector2(0, -absf(dive) * 22.0 * ku))
	_lk = ku
	var bob: float = absf(sin(ph)) * 2.0 * amp

	# --- pernas: coxa (pele), meião alto e chuteira
	var boots: Color = lk[2]
	for li in 2:
		var leg: float = -1.0 if li == 0 else 1.0
		var phase := ph + (0.0 if leg > 0.0 else PI)
		var sw: float = sin(phase) * amp
		if kick > 0.0 and leg > 0.0:
			sw = 1.5 * sin(kick * PI)
		var hip := Vector2(leg * 8.5, -28.0 - bob)
		var foot := Vector2(leg * 8.5, -3.0) + fwd * sw * (11.0 if view == 2 else 3.0)
		foot.y -= maxf(0.0, -cos(phase)) * 4.0 * amp
		var knee := hip.lerp(foot, 0.3)
		_q_limb(hip, foot, 11.5, skin)
		_q_limb(knee, foot, 12.0, sock)
		_q_line(knee, hip.lerp(foot, 0.36), sock.darkened(0.18), 11.2)
		var boot := foot + (fwd * 2.5 if view == 2 else Vector2(0, 0.6))
		_q_rr(Rect2(boot.x - 6.5, boot.y - 2.5, 13.0, 6.5), 3.0, boots)
		_q_line(boot + Vector2(-2.5, 0.6), boot + Vector2(2.5, 0.6), Color(1, 1, 1, 0.35), 0.9)

	# --- calção
	var wid := 1.0 if view != 2 else 0.68
	_q_rr(Rect2(-18.0 * wid, -41.0 - bob, 36.0 * wid, 14.0), 3.5, shorts)
	if view != 2:
		_q_rect(Rect2(-0.7, -33.0 - bob, 1.4, 6.0), shorts.darkened(0.2))

	# --- braços (o de trás primeiro no perfil)
	var swing := 7.0 if view == 2 else 2.5
	var shp_l := Vector2(-22.0 * wid, -57.0 - bob)
	var shp_r := Vector2(22.0 * wid, -57.0 - bob)
	var hand_l := shp_l + Vector2(-4.0 * wid, 18.0) + fwd * (-sin(ph + PI) * amp) * swing
	var hand_r := shp_r + Vector2(4.0 * wid, 18.0) + fwd * (-sin(ph) * amp) * swing
	if (keeper and absf(dive) > 0.35) or e.get("cheer", false):
		hand_l = shp_l + Vector2(-4.0, -20.0)
		hand_r = shp_r + Vector2(4.0, -20.0)
	var left_behind := view != 2 or flip > 0.0
	if left_behind:
		_draw_arm2(shp_l, hand_l, shirt, skin, keeper)
	else:
		_draw_arm2(shp_r, hand_r, shirt, skin, keeper)

	# --- camisa com mangas curtas
	var tw := 22.5 * wid
	_q_rr(Rect2(-tw, -64.0 - bob, tw * 2.0, 25.0), 7.0, shirt)
	if striped:
		for k2 in 3:
			var cx: float = -tw + tw * 2.0 * (k2 + 0.5) / 3.0
			_q_rect(Rect2(cx - tw * 0.16, -63.0 - bob, tw * 0.32, 23.5), trim)
	_q_rect(Rect2(-tw + 2.0, -44.0 - bob, tw * 2.0 - 4.0, 4.6), Color(1, 1, 1, 0.14))    # luz na barra
	_q_rect(Rect2(-tw + 2.0, -64.0 - bob, tw * 2.0 - 4.0, 3.0), Color(0, 0, 0, 0.06))
	if view == 1:
		# número nas costas: o texto não entra no lote, então o lote é desenhado antes
		var ink := Color("151515") if shirt.get_luminance() > 0.55 else Color("f4f4f4")
		_commit(xf)
		_flush()
		draw_set_transform_matrix(xf)
		draw_string(UI.bold(), Vector2(-14.0, -45.0 - bob), lk[3], HORIZONTAL_ALIGNMENT_CENTER, 28.0, 17, ink)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	if left_behind:
		_draw_arm2(shp_r, hand_r, shirt, skin, keeper)
	else:
		_draw_arm2(shp_l, hand_l, shirt, skin, keeper)

	# --- cabeça grande
	var hx: float = (2.5 * flip) if view == 2 else 0.0
	var top := -101.0 - bob
	var hw := 17.5
	var style: int = lk[0]   # jogador criado no modo carreira escolhe o visual
	var beard: bool = lk[1]
	if style == 2:   # cabelo cheio aparece um pouco em volta
		_q_rr(Rect2(hx - hw - 1.5, top - 3.0, hw * 2.0 + 3.0, 16.0), 10.0, hair)
	var skin_d := skin.darkened(0.12)
	# orelhas
	if view != 2:
		_q_circle(Vector2(hx - hw, top + 22.0), 4.6, skin)
		_q_circle(Vector2(hx + hw, top + 22.0), 4.6, skin)
		_q_circle(Vector2(hx - hw, top + 22.0), 2.2, skin_d)
		_q_circle(Vector2(hx + hw, top + 22.0), 2.2, skin_d)
	_q_rr(Rect2(hx - hw, top, hw * 2.0, 40.0), 13.0, skin)
	_q_rect(Rect2(hx + hw * 0.35, top + 8.0, hw * 0.55, 26.0), Color(0, 0, 0, 0.04))
	if view == 1:
		# de costas: cabelo cobrindo a nuca
		if style != 3:
			_q_rr(Rect2(hx - hw, top, hw * 2.0, 24.0 if style != 4 else 18.0), 13.0, hair if style != 4 else hair.lerp(HAIR_GREY, 0.3))
		_q_rect(Rect2(hx - 6.0, top + 39.0, 12.0, 3.0), skin.darkened(0.15))
	elif view == 0:
		_hair_front2(Vector2(hx, top), hw, hair, style)
		if beard:
			# barba rala no queixo
			_q_rr(Rect2(hx - hw + 3.0, top + 30.0, hw * 2.0 - 6.0, 10.0), 5.0, skin.lerp(hair, 0.4))
		# sobrancelhas grossas e arqueadas
		var brow := hair.darkened(0.25)
		_q_limb(Vector2(hx - 12.0, top + 18.5), Vector2(hx - 4.0, top + 16.5), 2.6, brow)
		_q_limb(Vector2(hx + 4.0, top + 16.5), Vector2(hx + 12.0, top + 18.5), 2.6, brow)
		# olhos em pílula
		_q_limb(Vector2(hx - 10.0, top + 23.0), Vector2(hx - 5.0, top + 23.0), 3.0, INK)
		_q_limb(Vector2(hx + 5.0, top + 23.0), Vector2(hx + 10.0, top + 23.0), 3.0, INK)
		# nariz
		_q_tri(Vector2(hx - 2.2, top + 28.5), Vector2(hx + 2.2, top + 28.5), Vector2(hx, top + 30.5), skin.darkened(0.22))
		# sorriso branco
		_q_tmpl(_smile_tris(false), Vector2(hx, top + 32.0), WHITE_TEETH)
		_q_line(Vector2(hx - 8.5, top + 32.0), Vector2(hx + 8.5, top + 32.0), skin.darkened(0.3), 0.8)
	else:
		# de lado
		_q_circle(Vector2(hx - 5.0 * flip, top + 22.0), 4.6, skin)
		_q_circle(Vector2(hx - 5.0 * flip, top + 22.0), 2.2, skin_d)
		if style != 3:
			_q_rr(Rect2(hx - hw, top, hw * 2.0, 8.5), 8.0, hair)
			if flip > 0.0:
				_q_rr(Rect2(hx - hw, top, hw * 0.75, 19.0), 8.0, hair)
			else:
				_q_rr(Rect2(hx + hw * 0.25, top, hw * 0.75, 19.0), 8.0, hair)
		if beard:
			_q_rr(Rect2(hx - hw + 4.0, top + 30.0, hw * 2.0 - 8.0, 10.0), 5.0, skin.lerp(hair, 0.4))
		_q_limb(Vector2(hx + 5.0 * flip, top + 17.0), Vector2(hx + 12.0 * flip, top + 17.5), 2.6, hair.darkened(0.25))
		_q_limb(Vector2(hx + 7.0 * flip, top + 23.0), Vector2(hx + 11.5 * flip, top + 23.0), 3.0, INK)
		_q_circle(Vector2(hx + 16.5 * flip, top + 28.0), 2.2, skin.darkened(0.08))
		_q_tmpl(_smile_tris(true), Vector2(hx + 9.0 * flip, top + 32.0), WHITE_TEETH)
	_commit(xf)
	_lk = 1.0
	if not _batch_open:
		_flush()


func _draw_arm2(shp: Vector2, hand: Vector2, shirt: Color, skin: Color, keeper: bool) -> void:
	_q_limb(shp, hand, 6.4, skin)
	_q_limb(shp, shp.lerp(hand, 0.38), 9.5, shirt)      # manga curta
	if keeper:
		_q_rr(Rect2(hand.x - 4.6, hand.y - 3.0, 9.2, 8.5), 3.5, INK)    # luva preta
		_q_line(hand + Vector2(-2.5, 1.5), hand + Vector2(-1.0, 4.0), Color(1, 1, 1, 0.25), 1.0)
	else:
		_q_circle(hand, 3.6, skin)


## Cabelo de frente. Estilos: 0 curto, 1 topete, 2 cheio, 3 careca, 4 raspado, 5 franja.
## O cabelo é uma "tampa" fina no topo da cabeça, como na referência.
func _hair_front2(o: Vector2, hw: float, hair: Color, style: int) -> void:
	match style:
		0:
			_q_rr(Rect2(o.x - hw, o.y, hw * 2.0, 9.5), 9.0, hair)
			_q_rect(Rect2(o.x - hw, o.y + 5.0, 2.6, 8.0), hair)
			_q_rect(Rect2(o.x + hw - 2.6, o.y + 5.0, 2.6, 8.0), hair)
		1:
			_q_rr(Rect2(o.x - hw, o.y, hw * 2.0, 9.0), 9.0, hair)
			_q_rr(Rect2(o.x - 5.0, o.y - 4.5, 14.0, 8.0), 4.0, hair)
		2:
			_q_rr(Rect2(o.x - hw, o.y - 1.0, hw * 2.0, 11.0), 10.0, hair)
		4:
			_q_rr(Rect2(o.x - hw + 1.0, o.y, hw * 2.0 - 2.0, 6.5), 6.0, hair.lerp(HAIR_GREY, 0.3))
		5:
			_q_rr(Rect2(o.x - hw, o.y, hw * 2.0, 10.0), 9.0, hair)
			_q_tri(Vector2(o.x - hw + 3.0, o.y + 7.0), Vector2(o.x + 7.0, o.y + 7.0), Vector2(o.x - 4.0, o.y + 13.5), hair)


# ------------------------------------------------------------ ordem de profundidade
func _ro_reset() -> void:
	_ro_ents.clear()
	_ro_kind.clear()


func _ro_add(e: Variant, kind: int) -> void:
	_ro_ents.append(e)
	_ro_kind.append(kind)


func _ro_done() -> void:
	var n := _ro_ents.size()
	_ro_key.resize(n)
	_ro_ord.resize(n)
	for i in n:
		_ro_ord[i] = i


## Quem entra no desenho do lance. Só é refeito quando o elenco muda (expulsão).
func _sync_roster() -> void:
	var sig: int = att.size() * 1000 + dfn.size() + (0 if referee.is_empty() else 500)
	if sig == _ro_sig:
		return
	_ro_sig = sig
	_ro_reset()
	for e in att:
		_ro_add(e, 0)
	for e in dfn:
		_ro_add(e, 1)
	_ro_add(gk, 2)
	if not referee.is_empty():
		_ro_add(referee, 3)
	_ro_add(null, 4)
	_ro_done()


## Desenha todo mundo e a bola em ordem de profundidade: quem está mais longe da câmera
## (mais em cima na tela) primeiro. A ordem do quadro anterior é reaproveitada e só
## ajustada (ordenação por inserção, sem criar arrays nem funções novas).
func _draw_people(only_att: bool = false) -> void:
	_sync_roster()
	var n := _ro_ents.size()
	for i in n:
		if _ro_kind[i] == 4:
			_ro_key[i] = bp.pos.y * y_sign + 0.05    # a bola fica na frente de quem está no mesmo ponto
		else:
			_ro_key[i] = _ro_ents[i]["pos"].y * y_sign
	for i in range(1, n):
		var v := _ro_ord[i]
		var kv := _ro_key[v]
		var j := i - 1
		while j >= 0 and _ro_key[_ro_ord[j]] > kv:
			_ro_ord[j + 1] = _ro_ord[j]
			j -= 1
		_ro_ord[j + 1] = v
	_batch_open = true
	for i in n:
		var k := _ro_ord[i]
		var kind := _ro_kind[k]
		if only_att and kind != 0 and kind != 4:
			continue
		match kind:
			4:
				_draw_ball()
			3:
				_draw_player(_ro_ents[k], [], false, true)
			_:
				var e: Dictionary = _ro_ents[k]
				_draw_player(e, kits[mini(kind, 1)], kind == 2 or e.get("keeper", false))
	_batch_open = false
	_flush()


func _line(a: Vector2, b: Vector2) -> void:
	draw_line(_w2s(a), _w2s(b), LINE_COL, maxf(0.12 * s, 2.0))


static var _lance_lines := PackedVector2Array(LANCE_LINES)


func _draw_field() -> void:
	_pitch_bands()
	_draw_adboards(0.0, 1.0, AD_GAP)
	# todas as linhas retas numa chamada só
	_lines_buf = _w2s_xf() * _lance_lines
	draw_multiline(_lines_buf, LINE_COL, maxf(0.12 * s, 2.0))
	draw_arc(_w2s(Vector2(0, 52.5)), 9.15 * s, 0, TAU, 64, Color(1, 1, 1, 0.92), 2.0)
	draw_circle(_w2s(Vector2(0, 52.5)), 4.0, Color(1, 1, 1, 0.85))
	draw_circle(_w2s(Vector2(0, 11)), 3.5, Color(1, 1, 1, 0.85))
	# meia-lua da grande área, do lado do campo (com o gol em cima, ela fica embaixo da área)
	if y_sign > 0.0:
		draw_arc(_w2s(Vector2(0, 11)), 9.15 * s, 0.645, PI - 0.645, 32, Color(1, 1, 1, 0.92), 2.0)
	else:
		draw_arc(_w2s(Vector2(0, 11)), 9.15 * s, -PI + 0.645, -0.645, 32, Color(1, 1, 1, 0.92), 2.0)


## Geometria do gol relativa à base da trave esquerda (gl): gr, bl, br e as alturas.
## Devolve [teto, fundo, rede, traves, chave]; só é refeita se a escala mudar.
func _goal_geo_far(gr: Vector2, bl: Vector2, br: Vector2) -> Array:
	var key := Vector4(gr.x, bl.y, br.x, s)
	if not _goal_far.is_empty() and _goal_far[7] == key:
		return _goal_far
	var L := LIFT * s
	var h := BallPhysics.CROSSBAR
	var gl := Vector2.ZERO
	var up := Vector2(0, -h * L)
	var ub := Vector2(0, -h * 0.55 * L)   # rede de fundo mais baixa: o gol fica "em pé", sem caixa alta atrás
	var roof := PackedVector2Array([bl + ub, br + ub, gr + up, gl + up])
	var back := PackedVector2Array([bl, br, br + ub, bl + ub])
	var side_l := PackedVector2Array([gl, bl, bl + ub, gl + up])
	var side_r := PackedVector2Array([gr, br, br + ub, gr + up])
	# malha da rede (quadriculada fina) em cada face
	var net := PackedVector2Array()
	_mesh(net, bl, br, br + ub, bl + ub, 24, 6)
	_mesh(net, gl + up, gr + up, br + ub, bl + ub, 24, 3)
	_mesh(net, gl, bl, bl + ub, gl + up, 3, 6)
	_mesh(net, gr, br, br + ub, gr + up, 3, 6)
	var posts := PackedVector2Array([gl, gl + up, gr, gr + up, gl + up, gr + up])
	var shadow := PackedVector2Array([gl, gr, gr + Vector2(0.9 * s, 0.35 * s), gl + Vector2(0.9 * s, 0.35 * s)])
	_goal_far = [roof, back, net, posts, side_l, side_r, shadow, key]
	return _goal_far


## Linhas de uma malha num quadrilátero a-b-c-d (nu colunas, nv linhas).
func _mesh(out: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2, nu: int, nv: int) -> void:
	for i in nu + 1:
		var u := float(i) / nu
		out.append(a.lerp(b, u))
		out.append(d.lerp(c, u))
	for j in nv + 1:
		var v := float(j) / nv
		out.append(a.lerp(d, v))
		out.append(b.lerp(c, v))


## Gol do fundo da tela (mais longe da câmera), em pé sobre a linha (gy) com a rede atrás
## (back = para que lado do mundo fica a rede). Desenhado antes dos jogadores: quem está
## no campo sempre fica na frente dele. No lance é o gol atacado, no alto da tela.
func _draw_goal_far(gy: float, back: float) -> void:
	var gl := _w2s(Vector2(-GOAL_HALF, gy))
	var gr := _w2s(Vector2(GOAL_HALF, gy)) - gl
	var bl := _w2s(Vector2(-GOAL_HALF * 0.96, gy + back * 1.1)) - gl
	var br := _w2s(Vector2(GOAL_HALF * 0.96, gy + back * 1.1)) - gl
	if gl.y < -2.0 or gl.y - 4.0 * s > size.y:
		return   # fora da tela (a base das traves acima do topo, ou o gol todo abaixo)
	var geo := _goal_geo_far(gr, bl, br)
	var pw: float = maxf(0.16 * s, 4.0)
	draw_set_transform(gl)
	# sombra das traves no gramado
	draw_colored_polygon(geo[6], Color(0, 0, 0, 0.16))
	# fundo da rede escuro e translúcido (dá profundidade), depois a malha branca
	draw_colored_polygon(geo[1], Color(0.02, 0.06, 0.03, 0.30))
	draw_colored_polygon(geo[0], Color(0.02, 0.06, 0.03, 0.22))
	draw_colored_polygon(geo[4], Color(0.02, 0.06, 0.03, 0.18))
	draw_colored_polygon(geo[5], Color(0.02, 0.06, 0.03, 0.18))
	draw_multiline(geo[2], Color(1, 1, 1, 0.42), 1.0)
	# traves: contorno escuro, branco e brilho
	var p: PackedVector2Array = geo[3]
	draw_multiline(p, Color(0.1, 0.12, 0.12, 0.55), pw + 3.0)
	draw_multiline(p, Color.WHITE, pw)
	for k in [0, 2]:
		draw_line(p[k] + Vector2(-pw * 0.2, 0), p[k + 1] + Vector2(-pw * 0.2, 0), Color(1, 1, 1, 0.9), maxf(pw * 0.3, 1.0))
	for q in [p[1], p[3]]:
		draw_circle(q, pw * 0.55, Color.WHITE)
	draw_set_transform(Vector2.ZERO)


## Geometria do gol perto da câmera (o de baixo da tela no FieldView), relativa a gl.
## [fundo, rede do fundo, teto, rede do teto e laterais, quinas 0.7, quinas 0.6, sombra, traves, chave]
func _goal_geo_near(gr: Vector2, bl: Vector2, br: Vector2) -> Array:
	var key := Vector4(gr.x, bl.y, br.x, s)
	if not _goal_near.is_empty() and _goal_near[8] == key:
		return _goal_near
	var L := LIFT * s
	var h := BallPhysics.CROSSBAR
	var gl := Vector2.ZERO
	var up := Vector2(0, -h * L)
	var up_back := Vector2(0, -h * 0.75 * L)
	var back := PackedVector2Array([bl, br, br + up_back, bl + up_back])
	var back_net := PackedVector2Array()
	for i in 15:
		var x := lerpf(bl.x, br.x, float(i) / 14.0)
		back_net.append(Vector2(x, bl.y))
		back_net.append(Vector2(x, bl.y + up_back.y))
	for j in 6:
		var y := bl.y + up_back.y * float(j) / 5.0
		back_net.append(Vector2(bl.x, y))
		back_net.append(Vector2(br.x, y))
	var roof := PackedVector2Array([gl + up, gr + up, br + up_back, bl + up_back])
	var roof_net := PackedVector2Array()
	for i in 15:
		var k := float(i) / 14.0
		roof_net.append((gl + up).lerp(gr + up, k))
		roof_net.append((bl + up_back).lerp(br + up_back, k))
	var edge7 := PackedVector2Array()
	var edge6 := PackedVector2Array()
	for sp in [[gl, bl], [gr, br]]:
		var a: Vector2 = sp[0]
		var b: Vector2 = sp[1]
		roof_net.append(a)
		roof_net.append(b)
		edge7.append(a + up)
		edge7.append(b + up_back)
		edge6.append(b)
		edge6.append(b + up_back)
		for j in 4:
			var kk := float(j + 1) / 5.0
			roof_net.append(a + up * kk)
			roof_net.append(b + up_back * kk)
	var shadow := PackedVector2Array([gl + Vector2(3, 2), gr + Vector2(3, 2)])
	var posts := PackedVector2Array([gl, gl + up, gr, gr + up, gl + up, gr + up])
	_goal_near = [back, back_net, roof, roof_net, edge7, edge6, shadow, posts, key]
	return _goal_near


## Gol perto da câmera (no FieldView, o de baixo): traves e travessão sobem na mesma
## escala da altura da bola. back = parte de trás (rede no chão), front = armação
## desenhada por cima dos jogadores.
func _draw_goal(front: bool) -> void:
	var gl := _w2s(Vector2(-GOAL_HALF, 0))
	var gr := _w2s(Vector2(GOAL_HALF, 0)) - gl
	var bl := _w2s(Vector2(-GOAL_HALF, -2.0)) - gl
	var br := _w2s(Vector2(GOAL_HALF, -2.0)) - gl
	if gl.y + 3.0 * s < 0.0 or gl.y - 3.0 * s > size.y:
		return   # fora da tela
	var geo := _goal_geo_near(gr, bl, br)
	draw_set_transform(gl)
	if not front:
		# rede: fundo
		draw_colored_polygon(geo[0], Color(1, 1, 1, 0.10))
		draw_multiline(geo[1], NET_COL, 1.0)
	else:
		# teto e laterais da rede, quinas, sombra e traves
		var pw: float = maxf(0.12 * s, 3.0)
		draw_colored_polygon(geo[2], Color(1, 1, 1, 0.12))
		draw_multiline(geo[3], NET_COL, 1.0)
		draw_multiline(geo[4], Color(1, 1, 1, 0.7), 2.0)
		draw_multiline(geo[5], Color(1, 1, 1, 0.6), 2.0)
		draw_multiline(geo[6], Color(0, 0, 0, 0.25), pw)
		draw_multiline(geo[7], Color.WHITE, pw)
	draw_set_transform(Vector2.ZERO)


func _draw_ball() -> void:
	var g := _w2s(bp.pos)
	var r: float = maxf(0.19 * s, 4.0)     # bola um pouco maior que a real para enxergar
	var b := g - Vector2(0, r + bp.z * s * LIFT)
	var sh: float = clampf(1.0 - bp.z * 0.12, 0.4, 1.0)
	_lk = 1.0
	_q_ellipse(g + Vector2(r * 0.3, 0), r * 1.05 * sh, r * 0.42 * sh, Color(0, 0, 0, 0.3 * sh))
	_q_circle(b, r, BALL_WHITE)
	var rot: float = bp.spin
	var pent := _pent_tris()
	_lp.append_array(Transform2D(rot, Vector2(r * 0.36, r * 0.36), 0.0, b) * pent)
	_fill(BALL_DARK, pent.size())
	for i in 5:
		var a3 := rot + TAU * (i + 0.5) / 5.0
		var c := b + Vector2(cos(a3), sin(a3)) * r * 0.84
		_lp.append_array(Transform2D(a3, Vector2(r * 0.27, r * 0.27), 0.0, c) * pent)
		_fill(BALL_DARK, pent.size())
		var a5 := rot + TAU * i / 5.0
		var dv := Vector2(cos(a5), sin(a5))
		_q_line(b + dv * r * 0.36, b + dv * r * 0.9, Color(0, 0, 0, 0.35), 1.0)
	_flush()
	draw_arc(b, r * 1.04, 0, TAU, 32, BALL_RIM, r * 0.2, true)
	draw_arc(b, r * 0.62, -2.4, -1.2, 8, Color(1, 1, 1, 0.55), r * 0.14, true)


func _draw() -> void:
	if sim == null or att.is_empty():
		return
	s = size.x / CAMERA_WIDTH_M
	var f := UI.bold()
	var ph_px: float = BODY_H * LIFT * s       # altura do boneco na tela
	_draw_field()
	_draw_goal_far(0.0, -1.0)   # gol atacado em cima; os jogadores ficam todos na frente dele
	_draw_people()
	var deciding: bool = state == "decide" and user_ctrl
	if deciding:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.45, 0.47, 0.72))
		var c: Dictionary = att[carrier]
		var danger := false
		for d in dfn:
			if d["pos"].distance_to(c["pos"]) < 3.2 and d["stun"] <= 0.0:
				danger = true
		for i in att.size():
			var p := _w2s(att[i]["pos"])
			if i == carrier:
				_ellipse(p, ph_px * 0.42, ph_px * 0.19, Color(0.9, 0.3, 0.25, 0.5) if danger else Color(0.95, 0.75, 0.3, 0.45))
			else:
				_ellipse(p, ph_px * 0.5, ph_px * 0.22, Color(1, 1, 1, 0.28))
		_draw_people(true)
		for i in att.size():
			if i == carrier:
				continue
			var p2 := _w2s(att[i]["pos"])
			draw_string(f, Vector2(p2.x - 40, p2.y - ph_px - 12), _look(att[i])[3], HORIZONTAL_ALIGNMENT_CENTER, 80, 18, Color.WHITE)
			draw_rect(Rect2(p2.x - 10, p2.y - ph_px - 8, 20, 3), Color("3ddc6a"))
		# boca do gol destacada (onde tocar para chutar)
		var g1 := _w2s(Vector2(-GOAL_HALF, 0))
		var g2 := _w2s(Vector2(GOAL_HALF, 0)) + Vector2(0, -BallPhysics.CROSSBAR * LIFT * s)
		if g1.y > -40.0 and g1.y < size.y + 40.0:
			draw_rect(Rect2(Vector2(g1.x, g2.y), Vector2(g2.x - g1.x, g1.y - g2.y)), Color(1.0, 0.85, 0.3, 0.9), false, 4.0)
		# linha de impedimento (tracejada)
		if not shot_only:
			var oy := Referee.offside_line(_defenders_y(), bp.pos.y)
			var la := _w2s(Vector2(-34, oy))
			draw_set_transform(Vector2(0.0, la.y))
			draw_multiline(_dashes(), Color(1, 1, 1, 0.55), 2.0)
			draw_set_transform(Vector2.ZERO)
		if pressing and (drag_now - press).length() > 20.0:
			var b := _w2s(bp.pos)
			draw_line(b, b + (drag_now - press).normalized() * 260.0, Color(1.0, 0.85, 0.3, 0.9), 5.0)

	_draw_scoreboard(f)
	var mid := size.x / 2.0
	if not user_ctrl and state != "end":
		_rbox(Rect2(size.x - 190, 80, 180, 56), Color(0, 0, 0, 0.42), 14)
		draw_string(f, Vector2(size.x - 190, 114), "Pular  ›", HORIZONTAL_ALIGNMENT_CENTER, 180, 18, Color.WHITE)
	_draw_card(f, att[carrier])
	_draw_minimap(f)
	_draw_possession(f, 380.0, size.x - 400.0)
	if deciding:
		_rbox(Rect2(mid - 410, 86, 820, 44), Color(0, 0, 0, 0.5), 22)
		var hint := "Toque = passe rasteiro  •  Segure = passe alto  •  Toque no gol ou deslize para cima = CHUTE"
		if header:
			hint = "CABECEIO! Toque no gol para mirar"
		elif setpiece == "penalti":
			hint = "PÊNALTI: toque no canto do gol (fundo da rede = alto) ou deslize"
		elif setpiece == "falta_direta":
			hint = "FALTA: deslize com força para passar a barreira, ou toque no gol"
		draw_string(f, Vector2(mid - 410, 114), hint, HORIZONTAL_ALIGNMENT_CENTER, 820, 16, Color.WHITE)
	if banner != "" and cel_t <= 0.0:
		var goal: bool = result.get("goal", false)
		var bw := 620.0
		_rbox(Rect2(mid - bw / 2, size.y * 0.36, bw, 84), Color("e6c56a") if goal else Color(0.03, 0.06, 0.05, 0.86), 22)
		draw_string(f, Vector2(mid - bw / 2, size.y * 0.36 + 56), banner, HORIZONTAL_ALIGNMENT_CENTER, bw, 38 if goal else 28, Color("14203a") if goal else Color.WHITE)
	if card_flash != "":
		var cc2 := Color("f2d21f") if card_flash == "amarelo" else Color("d7263d")
		_rbox(Rect2(mid + 230, size.y * 0.36 - 20, 54, 76), cc2, 8)
	_draw_celebration(f)


## Traços da linha de impedimento (14 px a cada 26 px, na altura 0), refeitos só se a largura mudar.
func _dashes() -> PackedVector2Array:
	if _dash_w != size.x:
		_dash_w = size.x
		_dash_buf = PackedVector2Array()
		var xx := 0.0
		while xx < size.x:
			_dash_buf.append(Vector2(xx, 0.0))
			_dash_buf.append(Vector2(xx + 14, 0.0))
			xx += 26.0
	return _dash_buf


## Cartão de quem está com a bola (canto de baixo).
func _draw_card(f: Font, cc: Dictionary) -> void:
	_rbox(Rect2(20, size.y - 108, 330, 80), Color(0, 0, 0, 0.36), 16)
	draw_string(f, Vector2(36, size.y - 80), "%d %s" % [cc["num"], cc["p"]["name"]], HORIZONTAL_ALIGNMENT_LEFT, 300, 18, Color.WHITE)
	draw_string(f, Vector2(36, size.y - 58), "VEL %d  PAS %d  CHU %d  DES %d" % [cc["a"]["vel"], cc["a"]["pas"], cc["a"]["chu"], cc["a"]["des"]], HORIZONTAL_ALIGNMENT_LEFT, 300, 14, Color(1, 1, 1, 0.85))
	var stars: int = clampi(int((float(cc["p"]["ovr"]) - 55.0) / 7.0), 1, 5)
	for i in 5:
		_star(Vector2(42 + i * 17, size.y - 42), 6.5, Color("f0a020") if i < stars else Color(1, 1, 1, 0.18))


## Barra de posse de bola (cores dos times) num painel arredondado.
func _draw_possession(f: Font, x: float, w: float) -> void:
	var hcol := Color(str(Game.club(sim.h)["c1"]))
	var acol := Color(str(Game.club(sim.a)["c1"]))
	if _close(hcol, acol):
		acol = Color(str(Game.club(sim.a)["c2"]))
	var ph2: float = sim.possession(0) / 100.0
	_rbox(Rect2(x, size.y - 62, w, 42), Color(0, 0, 0, 0.32), 16)
	draw_string(f, Vector2(x + 14, size.y - 44), "Posse de bola", HORIZONTAL_ALIGNMENT_LEFT, 200, 12, Color(1, 1, 1, 0.85))
	draw_string(f, Vector2(x + w - 214, size.y - 44), "%d%%  •  %d%%" % [sim.possession(0), sim.possession(1)], HORIZONTAL_ALIGNMENT_RIGHT, 200, 12, Color(1, 1, 1, 0.85))
	var bar := Rect2(x + 14, size.y - 36, w - 28, 9)
	_rbox(bar, acol, 5)
	if ph2 > 0.0:
		_rbox(Rect2(bar.position, Vector2(maxf(bar.size.x * ph2, 10.0), bar.size.y)), hcol, 5)


func _star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + PI * i / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(pts, col)


## Minimapa no canto: campo inteiro, área que a câmera mostra, jogadores e bola.
## Em cima, a energia de quem está com a bola.
func _draw_minimap(f: Font) -> void:
	var m := Rect2(30, 104, 74, 112)
	var en: float = float(att[carrier]["p"].get("energy", 100.0)) / 100.0
	draw_string(f, Vector2(m.position.x, m.position.y - 18), "Energia", HORIZONTAL_ALIGNMENT_LEFT, 80, 11, Color(1, 1, 1, 0.9))
	draw_rect(Rect2(m.position.x, m.position.y - 12, m.size.x, 7), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(m.position.x + 1, m.position.y - 11, (m.size.x - 2) * en, 5), Color("3ddc6a"))
	_rbox(m.grow(5), Color(0, 0, 0, 0.3), 10)
	draw_rect(m, PITCH.darkened(0.12))
	# visível: os dois cantos da tela levados ao minimapa (vale para qualquer orientação)
	var va := _to_map(m, _s2w(Vector2.ZERO), 105.0)
	var vb := _to_map(m, _s2w(size), 105.0)
	var v0 := Vector2(clampf(minf(va.x, vb.x), m.position.x, m.end.x), clampf(minf(va.y, vb.y), m.position.y, m.end.y))
	var v1 := Vector2(clampf(maxf(va.x, vb.x), m.position.x, m.end.x), clampf(maxf(va.y, vb.y), m.position.y, m.end.y))
	draw_rect(Rect2(v0, v1 - v0), Color(1, 1, 1, 0.22))
	draw_rect(m, Color(1, 1, 1, 0.85), false, 1.5)
	draw_line(Vector2(m.position.x, m.position.y + m.size.y / 2), Vector2(m.end.x, m.position.y + m.size.y / 2), Color(1, 1, 1, 0.7), 1.0)
	draw_arc(m.position + m.size / 2, 7.0, 0, TAU, 20, Color(1, 1, 1, 0.7), 1.0)
	draw_rect(Rect2(m.position.x + m.size.x * 0.22, m.end.y - m.size.y * 0.16, m.size.x * 0.56, m.size.y * 0.16), Color(1, 1, 1, 0.7), false, 1.0)
	draw_rect(Rect2(m.position.x + m.size.x * 0.22, m.position.y, m.size.x * 0.56, m.size.y * 0.16), Color(1, 1, 1, 0.7), false, 1.0)
	_lk = 1.0
	for e in att:
		_q_circle(_to_map(m, e["pos"], 105.0), 2.2, kits[0][0])
	for e in dfn:
		_q_circle(_to_map(m, e["pos"], 105.0), 2.2, kits[1][0])
	_q_circle(_to_map(m, gk["pos"], 105.0), 2.2, KEEPER_SHIRT)
	_q_circle(_to_map(m, bp.pos, 105.0), 1.8, Color.WHITE)
	_flush()


## Ponto do campo (metros) no minimapa m, na mesma orientação da tela:
## no lance, o gol atacado (y = 0) fica em cima; no FieldView, embaixo.
func _to_map(m: Rect2, w: Vector2, length: float) -> Vector2:
	var fy: float = w.y / length
	if y_sign < 0.0:
		fy = 1.0 - fy
	return Vector2(m.position.x + (w.x + 34.0) / 68.0 * m.size.x, m.position.y + fy * m.size.y)


## Placar no topo (estilo WSC): bloco claro do mandante, placar escuro, visitante; escudos em círculo branco.
func _draw_scoreboard(f: Font) -> void:
	var hc: Dictionary = Game.club(sim.h)
	var ac: Dictionary = Game.club(sim.a)
	var mid := size.x / 2.0
	var H := 50.0
	draw_rect(Rect2(0, 0, size.x, H), Color("0d1013"))
	draw_rect(Rect2(0, 0, mid - 64, H), Color("f3f4f6"))
	draw_string(f, Vector2(80, 34), str(hc["name"]), HORIZONTAL_ALIGNMENT_RIGHT, mid - 160, 23, Color("15181d"))
	draw_string(f, Vector2(mid + 84, 34), str(ac["name"]), HORIZONTAL_ALIGNMENT_LEFT, mid - 170, 23, Color.WHITE)
	draw_string(f, Vector2(mid - 64, 35), str(sim.score[0]), HORIZONTAL_ALIGNMENT_CENTER, 64, 27, Color.WHITE)
	draw_string(f, Vector2(mid, 35), str(sim.score[1]), HORIZONTAL_ALIGNMENT_CENTER, 64, 27, Color.WHITE)
	draw_line(Vector2(mid, 12), Vector2(mid, H - 12), Color(1, 1, 1, 0.25), 1.0)
	for it in [[hc, 34.0], [ac, size.x - 34.0]]:
		var cx: float = it[1]
		draw_circle(Vector2(cx, H / 2.0), 21.0, Color.WHITE)
		var ltex: Texture2D = Game.club_logo(int(it[0]["id"]))
		if ltex != null:
			draw_texture_rect(ltex, Rect2(cx - 15, H / 2.0 - 15, 30, 30), false)
		else:
			draw_circle(Vector2(cx, H / 2.0), 15.0, Color(str(it[0]["c1"])))
			draw_rect(Rect2(cx - 14, H / 2.0 - 4, 28, 8), Color(str(it[0]["c2"])))
	draw_rect(Rect2(0, H, size.x, 24), Color(0, 0, 0, 0.28))
	draw_string(f, Vector2(24, H + 17), "%s • %d'" % ["Primeiro Tempo" if sim.minute <= 45 else "Segundo Tempo", sim.minute], HORIZONTAL_ALIGNMENT_LEFT, 400, 14, Color.WHITE)
	if stage_label != "":
		draw_string(f, Vector2(size.x - 424, H + 17), stage_label, HORIZONTAL_ALIGNMENT_RIGHT, 400, 14, Color.WHITE)
