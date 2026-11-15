class_name TrophyCelebration
extends Control
## Animação de título: mãos levantando um troféu com confete e "Parabéns!".
## Tudo desenhado por código em _draw (estilo flat). Use TrophyCelebration.play(...).
## Toque/clique pula para o fim. Emite `done` e se libera ao terminar.

## Emitido uma única vez quando a animação termina (logo antes do queue_free).
signal done

const DURATION := 4.5
const FADE_OUT_START := 3.9
const CONFETTI_COUNT := 120

const BG_COLOR := Color("2b7a87")
const BG_GLOW := Color("3b95a1")
const SKIN := Color("f8d6ad")
const SKIN_SHADE := Color("e9bb8c")
const OUTLINE := Color("10262b")

const GOLD_BASE := Color("f2b632")
const GOLD_LIGHT := Color("ffd96a")
const GOLD_DARK := Color("c98a17")
const SILVER_BASE := Color("c3c9cf")
const SILVER_LIGHT := Color("eef1f4")
const SILVER_DARK := Color("8d969f")
const PEDESTAL := Color("2e3236")
const PEDESTAL_LIGHT := Color("464b50")
const PEDESTAL_DARK := Color("1d2023")

const CONFETTI_COLORS: Array[Color] = [
	Color("3ccf3c"), Color("f5d31b"), Color("e8392b"), Color("ff8a1f"),
	Color("9be23c"), Color("ffffff"), Color("4fc3f7"), Color("ff5fa2"),
]

var comp_name: String = ""
var club_name: String = ""
var logo: Texture2D = null
var style: String = "ouro"

var _t: float = 0.0
var _finished: bool = false

# Confete em arrays empacotados (nada é alocado por quadro).
var _cx := PackedFloat32Array()
var _cy := PackedFloat32Array()
var _crot := PackedFloat32Array()
var _cvrot := PackedFloat32Array()
var _cvy := PackedFloat32Array()
var _cflip := PackedFloat32Array()
var _cvflip := PackedFloat32Array()
var _csway := PackedFloat32Array()
var _csize := PackedFloat32Array()
var _ccol := PackedInt32Array()
var _rng := RandomNumberGenerator.new()

# Formas pré-calculadas (coordenadas locais do troféu, origem = base do pedestal).
var _confetti_shape := PackedVector2Array()
var _spark_shape := PackedVector2Array()
var _star_shape := PackedVector2Array()
var _bowl := PackedVector2Array()
var _bowl_shade := PackedVector2Array()
var _bowl_hi := PackedVector2Array()
var _rim := PackedVector2Array()
var _rim_in := PackedVector2Array()
var _rim_front := PackedVector2Array()
var _flute := PackedVector2Array()
var _flute_shade := PackedVector2Array()
var _flute_hi := PackedVector2Array()
var _arm_l := PackedVector2Array()
var _arm_shade_l := PackedVector2Array()
var _palm_l := PackedVector2Array()
var _arm_r := PackedVector2Array()
var _arm_shade_r := PackedVector2Array()
var _palm_r := PackedVector2Array()
var _sparks: Array[Vector3] = []  # x, y, fase

var _title := "Parabéns!"
var _subtitle := ""
var _title_size: int = 64
var _sub_size: int = 32


## Cria a celebração em tela cheia dentro de `parent` e já começa a animar.
## `style`: "ouro" (taça dourada com alças) ou "prata" (taça prateada com bola e estrelas).
static func play(parent: Control, comp_name: String, club_name: String, logo: Texture2D = null, style: String = "ouro") -> TrophyCelebration:
	var c := TrophyCelebration.new()
	c.comp_name = comp_name
	c.club_name = club_name
	c.logo = logo
	c.style = style
	parent.add_child(c)
	return c


## Sugere o estilo do troféu pelo tipo da competição ("liga", "continental", ...).
static func style_for(kind: String) -> String:
	var k := kind.to_lower()
	if k.contains("contin") or k.contains("sul") or k.contains("liberta"):
		return "prata"
	return "ouro"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	_subtitle = "O %s vence a %s" % [club_name, comp_name]
	_rng.seed = 7
	_build_shapes()
	_init_confetti()
	_fit_text()
	resized.connect(_fit_text)


func _is_silver() -> bool:
	var s := style.to_lower()
	return s == "prata" or s == "silver"


# ---------------------------------------------------------------- formas

func _build_shapes() -> void:
	# Confete: tira levemente curva.
	for i in 7:
		var a := lerpf(-0.6, 0.6, float(i) / 6.0)
		_confetti_shape.append(Vector2(sin(a) * 1.6, -cos(a) * 0.9 + 0.9))
	for i in 7:
		var a := lerpf(0.6, -0.6, float(i) / 6.0)
		_confetti_shape.append(Vector2(sin(a) * 1.6, -cos(a) * 0.9 + 0.9 + 0.8))
	# Brilho de 4 pontas (raio 1).
	for i in 8:
		var a := float(i) * PI / 4.0
		var r := 1.0 if i % 2 == 0 else 0.16
		_spark_shape.append(Vector2(sin(a), -cos(a)) * r)
	# Estrela de 5 pontas (raio 1).
	for i in 10:
		var a := float(i) * PI / 5.0
		var r := 1.0 if i % 2 == 0 else 0.45
		_star_shape.append(Vector2(sin(a), -cos(a)) * r)

	if _is_silver():
		_build_silver()
	else:
		_build_gold()
	_build_hands()


func _build_gold() -> void:
	# Taça: perfil de -195 (base) até -355 (borda).
	var n := 14
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / float(n)
		var hw := 16.0 + 82.0 * pow(sin(t * PI * 0.5), 0.7)
		var y := lerpf(-195.0, -355.0, t)
		right.append(Vector2(hw, y))
		left.append(Vector2(-hw, y))
	for p in right:
		_bowl.append(p)
	for i in range(left.size() - 1, -1, -1):
		_bowl.append(left[i])
	# Sombra do lado direito.
	for p in right:
		_bowl_shade.append(p)
	for i in range(right.size() - 1, -1, -1):
		_bowl_shade.append(Vector2(right[i].x * 0.45, right[i].y))
	# Faixa de brilho no lado esquerdo.
	for i in range(2, n):
		_bowl_hi.append(Vector2(left[i].x * 0.72, left[i].y))
	for i in range(n - 1, 1, -1):
		_bowl_hi.append(Vector2(left[i].x * 0.52, left[i].y))
	_rim = _ellipse(Vector2(0, -355), 98.0, 15.0, 28)
	_rim_in = _ellipse(Vector2(0, -353), 84.0, 10.0, 28)
	_sparks = [Vector3(-60, -300, 0.0), Vector3(70, -345, 1.9), Vector3(-15, -160, 3.4),
		Vector3(55, -95, 4.6), Vector3(-130, -330, 2.7)]


func _build_silver() -> void:
	# Flauta prateada: base estreita, abre em cálice, de -110 até -300.
	var n := 16
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / float(n)
		var hw := 0.0
		if t < 0.25:
			hw = lerpf(34.0, 14.0, t / 0.25)
		else:
			var u := (t - 0.25) / 0.75
			hw = 14.0 + 62.0 * u * u
		var y := lerpf(-112.0, -292.0, t)
		right.append(Vector2(hw, y))
		left.append(Vector2(-hw, y))
	for p in right:
		_flute.append(p)
	for i in range(left.size() - 1, -1, -1):
		_flute.append(left[i])
	for p in right:
		_flute_shade.append(p)
	for i in range(right.size() - 1, -1, -1):
		_flute_shade.append(Vector2(right[i].x * 0.4, right[i].y))
	for i in range(3, n):
		_flute_hi.append(Vector2(left[i].x * 0.75, left[i].y))
	for i in range(n - 1, 2, -1):
		_flute_hi.append(Vector2(left[i].x * 0.5, left[i].y))
	_rim = _ellipse(Vector2(0, -292), 80.0, 12.0, 28)
	_rim_in = _ellipse(Vector2(0, -291), 68.0, 8.0, 28)
	for i in 15:
		_rim_front.append(_rim[i])
	_sparks = [Vector3(-45, -390, 0.0), Vector3(60, -330, 1.7), Vector3(-30, -200, 3.1),
		Vector3(50, -95, 4.4), Vector3(95, -400, 2.4)]


func _build_hands() -> void:
	# Braço e mão esquerdos (o direito é espelhado). Origem = base do pedestal.
	_arm_l = PackedVector2Array([
		Vector2(-92, 26), Vector2(-48, 30), Vector2(-40, 700), Vector2(-112, 700)])
	_arm_shade_l = PackedVector2Array([
		Vector2(-60, 30), Vector2(-48, 30), Vector2(-40, 700), Vector2(-58, 700)])
	_palm_l = PackedVector2Array([
		Vector2(-40, 2), Vector2(-40, 30), Vector2(-60, 40), Vector2(-92, 40),
		Vector2(-112, 30), Vector2(-124, 14), Vector2(-128, -6), Vector2(-124, -26),
		Vector2(-116, -30), Vector2(-110, -22), Vector2(-108, -4), Vector2(-100, 2)])
	for p in _arm_l:
		_arm_r.append(Vector2(-p.x, p.y))
	for p in _arm_shade_l:
		_arm_shade_r.append(Vector2(-p.x, p.y))
	for p in _palm_l:
		_palm_r.append(Vector2(-p.x, p.y))


func _ellipse(c: Vector2, rx: float, ry: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / float(seg)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# ---------------------------------------------------------------- confete

func _init_confetti() -> void:
	_cx.resize(CONFETTI_COUNT)
	_cy.resize(CONFETTI_COUNT)
	_crot.resize(CONFETTI_COUNT)
	_cvrot.resize(CONFETTI_COUNT)
	_cvy.resize(CONFETTI_COUNT)
	_cflip.resize(CONFETTI_COUNT)
	_cvflip.resize(CONFETTI_COUNT)
	_csway.resize(CONFETTI_COUNT)
	_csize.resize(CONFETTI_COUNT)
	_ccol.resize(CONFETTI_COUNT)
	var w := maxf(size.x, 1280.0)
	var h := maxf(size.y, 720.0)
	for i in CONFETTI_COUNT:
		_spawn(i, w)
		# Começa espalhado acima da tela para "chover" de forma escalonada.
		_cy[i] = -_rng.randf_range(10.0, h * 1.1)


func _spawn(i: int, w: float) -> void:
	_cx[i] = _rng.randf_range(0.0, w)
	_cy[i] = -_rng.randf_range(10.0, 60.0)
	_crot[i] = _rng.randf_range(0.0, TAU)
	_cvrot[i] = _rng.randf_range(-4.0, 4.0)
	_cvy[i] = _rng.randf_range(110.0, 220.0)
	_cflip[i] = _rng.randf_range(0.0, TAU)
	_cvflip[i] = _rng.randf_range(3.0, 8.0)
	_csway[i] = _rng.randf_range(0.0, TAU)
	_csize[i] = _rng.randf_range(8.0, 13.0)
	_ccol[i] = _rng.randi_range(0, CONFETTI_COLORS.size() - 1)


func _update_confetti(delta: float) -> void:
	var s := _scale()
	for i in CONFETTI_COUNT:
		_cy[i] += _cvy[i] * s * delta
		_csway[i] += delta * 1.6
		_cx[i] += sin(_csway[i]) * 30.0 * s * delta
		_crot[i] += _cvrot[i] * delta
		_cflip[i] += _cvflip[i] * delta
		if _cy[i] > size.y + 20.0:
			_spawn(i, size.x)


# ---------------------------------------------------------------- tempo

func _process(delta: float) -> void:
	if _finished:
		return
	_t += delta
	_update_confetti(delta)
	modulate.a = 1.0 - _ease_in_out(clampf((_t - FADE_OUT_START) / (DURATION - FADE_OUT_START), 0.0, 1.0))
	queue_redraw()
	if _t >= DURATION:
		_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	done.emit()
	queue_free()


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if pressed:
		accept_event()
		if _t < FADE_OUT_START:
			_t = FADE_OUT_START


## Pula diretamente para o fade final (mesmo efeito do toque).
func skip() -> void:
	if _t < FADE_OUT_START:
		_t = FADE_OUT_START


func _scale() -> float:
	return maxf(minf(size.x / 1280.0, size.y / 720.0), 0.2)


func _fit_text() -> void:
	var s := _scale()
	var font := UI.bold()
	_title_size = int(round(66.0 * s))
	_sub_size = int(round(34.0 * s))
	var maxw := size.x * 0.92
	while _sub_size > 12 and font.get_string_size(_subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, _sub_size).x > maxw:
		_sub_size -= 1


static func _ease_out(x: float) -> float:
	return 1.0 - pow(1.0 - x, 3.0)


static func _ease_in_out(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


static func _elastic(x: float) -> float:
	if x <= 0.0:
		return 0.0
	if x >= 1.0:
		return 1.0
	return pow(2.0, -10.0 * x) * sin((x * 10.0 - 0.75) * TAU / 3.0) + 1.0


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var s := _scale()
	var w := size.x
	var h := size.y

	# Fundo com fade-in e um brilho suave atrás do troféu.
	var bg_a := _ease_in_out(clampf(_t / 0.4, 0.0, 1.0))
	draw_rect(Rect2(Vector2.ZERO, size), Color(BG_COLOR, bg_a))
	var glow_c := Vector2(w * 0.5, h * 0.36)
	var pulse := 1.0 + 0.04 * sin(_t * 2.5)
	for i in 4:
		var r := (330.0 - float(i) * 70.0) * s * pulse
		draw_circle(glow_c, r, Color(BG_GLOW, 0.11 * bg_a))

	# Confete atrás do troféu (metade) — a outra metade vai na frente.
	_draw_confetti(0, s)

	# Troféu + mãos: sobem de baixo com ease-out e leve balanço.
	var k := s * 0.98
	var rise := _ease_out(clampf((_t - 0.15) / 1.2, 0.0, 1.0))
	var rest_y := h * 0.66
	var start_y := h + 420.0 * k
	var settle := clampf((_t - 1.35), 0.0, 10.0)
	var sway := 0.0
	var bob := 0.0
	if rise >= 1.0:
		sway = 0.06 * sin(settle * 7.0) * exp(-settle * 2.2) + 0.012 * sin(_t * 2.2)
		bob = -6.0 * k * absf(sin(settle * 7.0)) * exp(-settle * 2.6) + 3.0 * k * sin(_t * 2.8)
	else:
		sway = 0.05 * sin(rise * PI * 2.0) * (1.0 - rise)
	var origin := Vector2(w * 0.5, lerpf(start_y, rest_y, rise) + bob)
	var xf := Transform2D(sway, Vector2(k, k), 0.0, origin)

	_cur_xf = xf
	draw_set_transform_matrix(xf)
	_draw_arms()
	if _is_silver():
		_draw_silver()
	else:
		_draw_gold()
	_draw_pedestal()
	_draw_palms()
	_draw_sparks(xf)
	draw_set_transform_matrix(Transform2D.IDENTITY)

	_draw_confetti(1, s)
	_draw_texts(s)


func _draw_confetti(half: int, s: float) -> void:
	var start_t := 0.25
	if _t < start_t:
		return
	for i in range(half, CONFETTI_COUNT, 2):
		var sz := _csize[i] * s
		var flip := cos(_cflip[i])
		var sc := Vector2(sz, sz * maxf(absf(flip), 0.15))
		draw_set_transform(Vector2(_cx[i], _cy[i]), _crot[i], sc)
		var col := CONFETTI_COLORS[_ccol[i]]
		if flip < 0.0:
			col = col.darkened(0.25)
		draw_colored_polygon(_confetti_shape, col)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_arms() -> void:
	draw_colored_polygon(_arm_l, SKIN)
	draw_colored_polygon(_arm_shade_l, SKIN_SHADE)
	draw_colored_polygon(_arm_r, SKIN)
	draw_colored_polygon(_arm_shade_r, SKIN_SHADE)


func _draw_palms() -> void:
	draw_colored_polygon(_palm_l, SKIN)
	draw_colored_polygon(_palm_r, SKIN)
	# Dobras dos dedos.
	for sgn in [-1.0, 1.0]:
		var sx: float = sgn
		draw_line(Vector2(sx * 112, 22), Vector2(sx * 120, 6), SKIN_SHADE, 3.0, true)
		draw_line(Vector2(sx * 100, 30), Vector2(sx * 110, 14), SKIN_SHADE, 3.0, true)
		draw_line(Vector2(sx * 60, 38), Vector2(sx * 92, 38), SKIN_SHADE, 3.0, true)


func _draw_pedestal() -> void:
	# Bloco principal.
	draw_rect(Rect2(-92, -112, 184, 96), PEDESTAL)
	draw_rect(Rect2(52, -112, 40, 96), PEDESTAL_LIGHT)
	draw_rect(Rect2(-92, -112, 24, 96), PEDESTAL_DARK)
	draw_rect(Rect2(-92, -118, 184, 8), PEDESTAL_LIGHT)
	# Base mais larga.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-112, -16), Vector2(112, -16), Vector2(120, 0), Vector2(-120, 0)]), PEDESTAL_DARK)
	draw_line(Vector2(-96, -7), Vector2(96, -7), PEDESTAL_LIGHT, 2.0)
	# Placa com a logo do campeonato.
	var c := Vector2(0, -64)
	var metal := SILVER_BASE if _is_silver() else GOLD_BASE
	draw_circle(c, 37.0, metal)
	draw_circle(c, 32.0, Color("f4f6f8"))
	if logo != null:
		var ts := logo.get_size()
		var box := 50.0
		var f := box / maxf(ts.x, ts.y)
		var ds := ts * f
		draw_texture_rect(logo, Rect2(c - ds * 0.5, ds), false)
	else:
		_star_at(c, 20.0, metal)


func _star_at(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform_matrix(_cur_xf * Transform2D(0.0, Vector2(r, r), 0.0, c))
	draw_colored_polygon(_star_shape, col)
	draw_set_transform_matrix(_cur_xf)


func _draw_gold() -> void:
	# Plinto e haste.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-62, -118), Vector2(62, -118), Vector2(44, -136), Vector2(-44, -136)]), GOLD_DARK)
	draw_rect(Rect2(-13, -185, 26, 52), GOLD_BASE)
	draw_rect(Rect2(3, -185, 10, 52), GOLD_DARK)
	_ellipse_fill(Vector2(0, -160), 24.0, 10.0, GOLD_LIGHT)
	_ellipse_fill(Vector2(0, -186), 30.0, 9.0, GOLD_BASE)
	# Alças (atrás da taça).
	for sgn in [-1.0, 1.0]:
		var sx: float = sgn
		var ac := Vector2(sx * 86.0, -300.0)
		var a0 := -PI * 0.55 if sx > 0.0 else PI * 0.45
		draw_arc(ac, 42.0, a0, a0 + PI * 1.1, 24, GOLD_DARK, 15.0, true)
		draw_arc(ac, 42.0, a0, a0 + PI * 1.1, 24, GOLD_BASE, 9.0, true)
	# Taça.
	draw_colored_polygon(_bowl, GOLD_BASE)
	draw_colored_polygon(_bowl_shade, GOLD_DARK)
	draw_colored_polygon(_bowl_hi, GOLD_LIGHT)
	draw_colored_polygon(_rim, GOLD_LIGHT)
	draw_colored_polygon(_rim_in, GOLD_DARK)
	# Faixa e estrela no corpo.
	draw_line(Vector2(-86, -318), Vector2(86, -318), GOLD_LIGHT, 4.0, true)
	draw_circle(Vector2(0, -265), 24.0, GOLD_DARK)
	draw_circle(Vector2(0, -265), 20.0, GOLD_LIGHT)
	_star_at(Vector2(0, -265), 15.0, GOLD_DARK)


func _draw_silver() -> void:
	# Plinto.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-58, -118), Vector2(58, -118), Vector2(40, -132), Vector2(-40, -132)]), SILVER_DARK)
	# Cálice prateado.
	draw_colored_polygon(_flute, SILVER_BASE)
	draw_colored_polygon(_flute_shade, SILVER_DARK)
	draw_colored_polygon(_flute_hi, SILVER_LIGHT)
	# Anel dourado e estrelas.
	_ellipse_fill(Vector2(0, -168), 19.0, 6.0, GOLD_BASE)
	for i in 3:
		var sx := (float(i) - 1.0) * 30.0
		var sy := -238.0 + absf(float(i) - 1.0) * 6.0
		_star_at(Vector2(sx, sy), 10.0, SILVER_LIGHT)
	# Bola estilizada repousando no cálice.
	var bc := Vector2(0, -350)
	var br := 64.0
	draw_circle(bc, br, SILVER_LIGHT)
	draw_circle(bc + Vector2(10, 8), br * 0.9, Color("dfe4e8"))
	draw_circle(bc, br, SILVER_DARK, false, 3.0, true)
	# Gomos: pentágono central + raios.
	var pent := PackedVector2Array()
	for i in 5:
		var a := -PI * 0.5 + float(i) * TAU / 5.0
		pent.append(bc + Vector2(cos(a), sin(a)) * 21.0)
	draw_colored_polygon(pent, Color("5d666f"))
	for i in 5:
		var a := -PI * 0.5 + float(i) * TAU / 5.0
		var p0 := bc + Vector2(cos(a), sin(a)) * 21.0
		var p1 := bc + Vector2(cos(a), sin(a)) * (br - 2.0)
		draw_line(p0, p1, SILVER_DARK, 3.0, true)
		var pc := bc + Vector2(cos(a), sin(a)) * (br - 9.0)
		draw_circle(pc, 8.0, Color("5d666f"))
	draw_circle(bc, br, SILVER_DARK, false, 3.0, true)
	# Reflexo da bola.
	draw_arc(bc, br - 10.0, PI * 1.08, PI * 1.42, 12, Color(1, 1, 1, 0.9), 6.0, true)
	# Borda do cálice na frente da bola.
	draw_colored_polygon(_rim, GOLD_LIGHT)
	draw_polyline(_rim_front, GOLD_DARK, 4.0, true)


func _ellipse_fill(c: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_set_transform_matrix(_cur_xf * Transform2D(0.0, Vector2(rx, ry), 0.0, c))
	draw_circle(Vector2.ZERO, 1.0, col)
	draw_set_transform_matrix(_cur_xf)


var _cur_xf := Transform2D.IDENTITY


func _draw_sparks(xf: Transform2D) -> void:
	if _t < 1.0:
		return
	for sp in _sparks:
		var a := sin(_t * 4.2 + sp.z)
		if a <= 0.0:
			continue
		var r := 24.0 * a
		draw_set_transform_matrix(xf * Transform2D(_t * 0.6, Vector2(r, r), 0.0, Vector2(sp.x, sp.y)))
		draw_colored_polygon(_spark_shape, Color(1, 1, 1, minf(a * 1.4, 1.0)))


func _draw_texts(s: float) -> void:
	var font := UI.bold()
	var w := size.x
	var h := size.y
	# "Parabéns!" com escala elástica.
	var tp := clampf((_t - 1.25) / 0.9, 0.0, 1.0)
	if tp > 0.0:
		var sc := _elastic(tp)
		var cy := h * 0.81
		draw_set_transform(Vector2(w * 0.5, cy), 0.0, Vector2(sc, sc))
		var base := Vector2(-w * 0.5, float(_title_size) * 0.35)
		var ol := int(round(10.0 * s))
		draw_string_outline(font, base, _title, HORIZONTAL_ALIGNMENT_CENTER, w, _title_size, ol, OUTLINE)
		draw_string(font, base, _title, HORIZONTAL_ALIGNMENT_CENTER, w, _title_size, Color.WHITE)
	# Subtítulo: sobe um pouco e aparece.
	var sp := _ease_out(clampf((_t - 1.75) / 0.5, 0.0, 1.0))
	if sp > 0.0:
		var y := h * 0.91 + (1.0 - sp) * 24.0 * s
		draw_set_transform(Vector2(0, y), 0.0, Vector2.ONE)
		var base2 := Vector2(0, float(_sub_size) * 0.35)
		var ol2 := int(round(7.0 * s))
		draw_string_outline(font, base2, _subtitle, HORIZONTAL_ALIGNMENT_CENTER, w, _sub_size, ol2, Color(OUTLINE, sp))
		draw_string(font, base2, _subtitle, HORIZONTAL_ALIGNMENT_CENTER, w, _sub_size, Color(1, 1, 1, sp))
	draw_set_transform_matrix(Transform2D.IDENTITY)
