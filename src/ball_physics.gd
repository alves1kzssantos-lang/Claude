class_name BallPhysics
extends RefCounted
## Física da bola usada nos lances em campo.
## Plano do campo: x = largura (0 no meio), y = distância até o gol que está
## sendo atacado (gol em y = 0). z = altura em metros.
## Todos os números vêm de assets/data/match_tuning.json (seção "bola").

const GOAL_HALF := 3.66     ## meia largura do gol (regra do futebol)
const CROSSBAR := 2.44      ## altura do travessão (regra do futebol)

var pos: Vector2 = Vector2.ZERO
var z: float = 0.0
var vel: Vector2 = Vector2.ZERO
var vz: float = 0.0
var spin: float = 0.0       ## giro visual da bola (radianos)

var gravity: float
var grass_friction: float
var air_drag: float
var bounce: float


func _init() -> void:
	gravity = Tuning.f("bola", "gravidade", 9.8)
	grass_friction = Tuning.f("bola", "atrito_grama", 0.9)
	air_drag = Tuning.f("bola", "arrasto_ar", 0.12)
	bounce = Tuning.f("bola", "quique", 0.45)


## Coloca a bola parada num ponto (nos pés de alguém, na marca do pênalti...).
func place(p: Vector2) -> void:
	pos = p
	z = 0.0
	vel = Vector2.ZERO
	vz = 0.0


func in_air() -> bool:
	return z > 0.0005 or vz > 0.0005


func speed() -> float:
	return vel.length()


## Passe rasteiro: a bola rola no chão até perto do alvo.
## Devolve o tempo estimado até chegar.
func kick_ground(target: Vector2, spd: float) -> float:
	var d := target - pos
	vel = d.normalized() * spd
	z = 0.0
	vz = 0.0
	return time_to_travel(d.length(), spd)


## Passe alto / cruzamento: a bola sobe e cai perto do alvo.
## apex = altura máxima em metros. Devolve o tempo de voo.
func kick_lofted(target: Vector2, apex: float) -> float:
	var d := target - pos
	vz = sqrt(2.0 * gravity * maxf(apex, 0.3))
	var t := 2.0 * vz / gravity
	# compensa o arrasto do ar para cair no alvo
	vel = d / maxf(t, 0.05) * (1.0 + air_drag * t * 0.5)
	z = 0.0
	return t


## Chute: velocidade no chão + velocidade de subida.
func kick_shot(dir: Vector2, spd: float, lift: float) -> void:
	vel = dir.normalized() * spd
	vz = lift
	z = 0.05


## Distância percorrida até a bola rasteira parar ou atingir a distância pedida.
func time_to_travel(dist: float, spd: float) -> float:
	# com atrito constante a: v(t) = v0 - a t ; s(t) = v0 t - a t²/2
	var a := grass_friction * gravity * 0.35
	var disc := spd * spd - 2.0 * a * dist
	if disc <= 0.0:
		return spd / a   # não chega: tempo até parar
	return (spd - sqrt(disc)) / a


## Avança a simulação. Chame com o delta do quadro.
func step(delta: float) -> void:
	if in_air():
		vz -= gravity * delta
		vel *= maxf(0.0, 1.0 - air_drag * delta)
		pos += vel * delta
		z += vz * delta
		if z <= 0.0:
			z = 0.0
			if absf(vz) > 1.6:
				vz = -vz * bounce
				vel *= 0.82
			else:
				vz = 0.0
	else:
		var s := vel.length()
		if s > 0.0:
			var a := grass_friction * gravity * 0.35
			var ns := maxf(s - a * delta, 0.0)
			vel = vel * (ns / s)
			pos += vel * delta
	spin += vel.length() * delta * 1.6


## Onde e quando a bola cruza a linha do gol (y = 0) mantendo o movimento atual.
## Devolve {} se não for cruzar; senão {x, z, t}.
func goal_line_crossing() -> Dictionary:
	if vel.y >= -0.01:
		return {}
	# simulação curta, sem mexer no estado real
	var p := pos
	var h := z
	var v := vel
	var w := vz
	var t := 0.0
	var dt := 1.0 / 120.0
	while t < 4.0:
		if h > 0.0 or w > 0.0:
			w -= gravity * dt
			v *= maxf(0.0, 1.0 - air_drag * dt)
			h = maxf(h + w * dt, 0.0)
			if h == 0.0:
				w = -w * bounce if absf(w) > 1.6 else 0.0
		else:
			var s := v.length()
			var a := grass_friction * gravity * 0.35
			if s <= 0.01:
				return {}
			v = v * (maxf(s - a * dt, 0.0) / s)
		var np := p + v * dt
		if np.y <= 0.0:
			var k := p.y / maxf(p.y - np.y, 0.0001)
			return {"x": lerpf(p.x, np.x, k), "z": h, "t": t + dt * k}
		p = np
		t += dt
	return {}


## Classifica onde a bola cruzou a linha de fundo.
## "gol", "trave", "travessao", "fora" ou "por_cima".
static func classify_crossing(x: float, h: float) -> String:
	var ax := absf(x)
	if ax < GOAL_HALF - 0.12 and h < CROSSBAR - 0.11:
		return "gol"
	if ax < GOAL_HALF + 0.12 and h < CROSSBAR + 0.12:
		if h >= CROSSBAR - 0.11 and ax < GOAL_HALF - 0.12:
			return "travessao"
		return "trave"
	if ax < GOAL_HALF + 0.12:
		return "por_cima"
	return "fora"
