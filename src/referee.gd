class_name Referee
extends RefCounted
## Regras do árbitro, separadas da tela para poder testar.
## Plano do lance: o time atacante vai para o gol em y = 0.
## Números em assets/data/match_tuning.json (seção "arbitro").

const BOX_HALF_W := 20.16   ## meia largura da grande área
const BOX_DEPTH := 16.5     ## profundidade da grande área
const PEN_SPOT := 11.0      ## marca do pênalti
const HALFWAY := 52.5       ## linha do meio-campo

var rng: RandomNumberGenerator


func _init(random: RandomNumberGenerator) -> void:
	rng = random


## O ponto está dentro da grande área do gol atacado?
static func in_box(p: Vector2) -> bool:
	return absf(p.x) <= BOX_HALF_W and p.y <= BOX_DEPTH and p.y >= -0.5


## Linha de impedimento: o penúltimo defensor (o goleiro conta) mais perto do gol,
## ou a bola, se ela estiver mais à frente. Nunca passa do meio-campo.
## defenders_y: lista com o y de todos os defensores, goleiro incluído.
static func offside_line(defenders_y: Array, ball_y: float) -> float:
	var ys := defenders_y.duplicate()
	ys.sort()
	var second_last: float = ys[1] if ys.size() >= 2 else 0.0
	return minf(minf(second_last, ball_y), HALFWAY)


## O recebedor está impedido no momento do passe?
## (à frente da linha de impedimento, no campo do adversário)
static func is_offside(receiver: Vector2, ball: Vector2, defenders_y: Array) -> bool:
	if receiver.y >= HALFWAY:
		return false
	return receiver.y < offside_line(defenders_y, ball.y) - 0.25


## Resultado de um bote.
## Devolve {"tipo": "limpo"|"falta"|"errou", "cartao": ""|"amarelo"|"vermelho"}
## def_des = desarme do defensor; att_skill = média de velocidade/passe do atacante.
func judge_tackle(def_des: float, att_skill: float) -> Dictionary:
	var win := clampf(Tuning.f("arbitro", "vitoria_bote_base", 0.2) + (def_des - att_skill) / 160.0, 0.08, 0.5)
	var foul_p := Tuning.f("arbitro", "chance_falta_no_bote", 0.28)
	var r := rng.randf()
	if r < foul_p:
		return {"tipo": "falta", "cartao": card_for_foul()}
	if r < foul_p + win * (1.0 - foul_p):
		return {"tipo": "limpo", "cartao": ""}
	return {"tipo": "errou", "cartao": ""}


## Cartão para uma falta (pode não ter cartão).
func card_for_foul() -> String:
	var r := rng.randf()
	if r < Tuning.f("arbitro", "chance_vermelho_direto", 0.025):
		return "vermelho"
	if r < Tuning.f("arbitro", "chance_amarelo_na_falta", 0.22):
		return "amarelo"
	return ""


## Decide o que fazer com uma falta: "penalti", "falta_direta", "vantagem" ou "falta".
## foul_pos = onde a falta aconteceu; attack_keeps_ball = o atacante seguiu com a bola.
func restart_for_foul(foul_pos: Vector2, attack_keeps_ball: bool) -> String:
	if in_box(foul_pos):
		return "penalti"
	if attack_keeps_ball and rng.randf() < Tuning.f("arbitro", "chance_vantagem", 0.35):
		return "vantagem"
	if foul_pos.y <= Tuning.f("arbitro", "distancia_falta_direta", 30.0):
		return "falta_direta"
	return "falta"
