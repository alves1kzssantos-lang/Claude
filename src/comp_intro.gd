class_name CompIntro
extends Control
## Abertura animada da partida: a logo do campeonato entra com raios de luz,
## depois os escudos dos dois clubes chegam pelos lados. Toque para pular.

signal done

const DUR := 2.9

var title: String = ""
var sub: String = ""
var tex: Texture2D = null      ## logo do datapack (null = emblema desenhado)
var h: int = -1
var a: int = -1
var accent: Color = UI.GOLD
var t: float = 0.0
var _crests: Array = []


## Logo do campeonato da partida (liga ou copa) a partir do datapack.
static func logo_for(mt: Dictionary) -> Texture2D:
	if mt.get("kind", "") == "cup":
		var c: Dictionary = Game.S["cups"][int(mt["cup"])]
		var cid: int = int(World.CUPS[int(c["def"])]["comp"])
		return DataPack.comp_logo_by_id(cid) if cid >= 0 else null
	if mt.get("kind", "") == "trial":
		return null
	return DataPack.comp_logo_by_id(DataPack.comp_id(int(Game.S.get("league", 0))))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for k in 2:
		var cr := Crest.make(h if k == 0 else a, 120)
		cr.modulate.a = 0.0
		add_child(cr)
		_crests.append(cr)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		t = maxf(t, DUR - 0.3)


func _process(delta: float) -> void:
	t += delta
	var c := size / 2.0
	# escudos entram pelos lados depois da logo
	var k := clampf((t - 1.15) / 0.45, 0.0, 1.0)
	var ease := 1.0 - pow(1.0 - k, 3.0)
	for i in _crests.size():
		var cr: Crest = _crests[i]
		var side := -1.0 if i == 0 else 1.0
		var target := c + Vector2(side * size.x * 0.3 - 60.0, size.y * 0.12 - 60.0)
		cr.position = target + Vector2(side * size.x * 0.4 * (1.0 - ease), 0.0)
		cr.modulate.a = ease * _fade()
	queue_redraw()
	if t >= DUR:
		set_process(false)
		done.emit()
		queue_free()


func _fade() -> float:
	return clampf((DUR - t) / 0.35, 0.0, 1.0)


func _elastic(x: float) -> float:
	if x <= 0.0:
		return 0.0
	if x >= 1.0:
		return 1.0
	return pow(2.0, -10.0 * x) * sin((x * 10.0 - 0.75) * TAU / 3.0) + 1.0


func _draw() -> void:
	var f := _fade()
	var c := size / 2.0 + Vector2(0, -size.y * 0.08)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.05, 0.04, 0.94 * minf(t / 0.2, 1.0) * f))
	# raios de luz girando atrás da logo
	var rays := 14
	var rr: float = size.length() * 0.6
	for i in rays:
		var ang := t * 0.5 + TAU * i / rays
		var w := 0.09
		var pts := PackedVector2Array([c, c + Vector2(cos(ang - w), sin(ang - w)) * rr, c + Vector2(cos(ang + w), sin(ang + w)) * rr])
		draw_colored_polygon(pts, Color(accent, 0.06 * f * minf(t / 0.4, 1.0)))
	# anel que se expande
	var ring := clampf(t / 0.7, 0.0, 1.0)
	draw_arc(c, 40.0 + ring * 150.0, 0, TAU, 96, Color(accent, (1.0 - ring) * 0.8 * f), 4.0)
	draw_arc(c, 118.0, 0, TAU, 96, Color(accent, 0.35 * f * ring), 2.0)
	# logo com efeito elástico
	var sc := _elastic(clampf((t - 0.1) / 0.8, 0.0, 1.0))
	var r := 100.0 * sc
	draw_circle(c, r * 1.08, Color(1, 1, 1, 0.08 * f))
	if tex != null:
		var ts := tex.get_size()
		var fit := (r * 2.0) / maxf(ts.x, ts.y)
		draw_set_transform(c, sin(t * 2.0) * 0.03 * (1.0 - minf(t, 1.0)), Vector2(fit, fit))
		draw_texture(tex, -ts / 2.0, Color(1, 1, 1, f))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_emblem(c, r, f)
	# brilho passando
	var sweep := clampf((t - 0.9) / 0.5, 0.0, 1.0)
	if sweep > 0.0 and sweep < 1.0:
		var x := c.x - r + sweep * r * 2.0
		draw_line(Vector2(x - 12, c.y - r), Vector2(x + 12, c.y + r), Color(1, 1, 1, 0.35 * f), 10.0)
	# título
	var ta := clampf((t - 0.6) / 0.4, 0.0, 1.0) * f
	var font := UI.bold()
	var tw := font.get_string_size(title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	draw_string(font, Vector2(c.x - tw / 2.0, c.y + r + 62.0 + (1.0 - ta) * 20.0), title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(1, 1, 1, ta))
	var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2(c.x - sw / 2.0, c.y + r + 92.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(accent, ta))
	# VS entre os escudos
	var va := clampf((t - 1.4) / 0.3, 0.0, 1.0) * f
	if h >= 0 and a >= 0:
		var vw := font.get_string_size("VS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		draw_string(font, Vector2(size.x / 2.0 - vw / 2.0, size.y / 2.0 + size.y * 0.12 + 10.0), "VS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1, va))
		for i in 2:
			var nm := Game.club_name(h if i == 0 else a)
			var nw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var cx := size.x / 2.0 + (-1.0 if i == 0 else 1.0) * size.x * 0.3
			draw_string(font, Vector2(cx - nw / 2.0, size.y / 2.0 + size.y * 0.12 + 92.0), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, va))
	var hint := "toque para pular"
	draw_string(UI.bold(), Vector2(size.x - 190, size.y - 24), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.35 * f))


## Emblema próprio quando o datapack não tem a logo (escudo com estrelas e bola).
func _emblem(c: Vector2, r: float, f: float) -> void:
	if r <= 1.0:
		return
	var pts := PackedVector2Array()
	for i in 6:
		var ang := -PI / 2.0 + TAU * i / 6.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, Color(0.08, 0.16, 0.13, f))
	pts.append(pts[0])
	draw_polyline(pts, Color(accent, f), 5.0)
	draw_circle(c, r * 0.42, Color(0.95, 0.96, 0.98, f))
	for i in 5:
		var ang := -PI / 2.0 + TAU * i / 5.0
		draw_circle(c + Vector2(cos(ang), sin(ang)) * r * 0.27, r * 0.09, Color(0.1, 0.12, 0.16, f))
	draw_circle(c, r * 0.11, Color(0.1, 0.12, 0.16, f))
	for i in 3:
		var sx := c.x + (i - 1) * r * 0.32
		_star(Vector2(sx, c.y - r * 0.66), r * 0.09, Color(accent, f))


func _star(p: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + PI * i / 5.0
		var rr := rad if i % 2 == 0 else rad * 0.45
		pts.append(p + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(pts, col)
