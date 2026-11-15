class_name Crest
extends Control
# Escudo gerado por código (cores + sigla do clube).

var cid: int = -1
var raw: Array = []   # [sigla, cor1, cor2] quando não há carreira carregada
var li: int = -1      # liga e clube (para achar o escudo do datapack)
var ci: int = -1


static func make(club_id: int, size: float = 48.0) -> Crest:
	var c := Crest.new()
	c.cid = club_id
	c.custom_minimum_size = Vector2(size, size)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func make_raw(short: String, c1: String, c2: String, size: float = 48.0, league_idx: int = -1, club_idx: int = -1) -> Crest:
	var c := make(-1, size)
	c.raw = [short, c1, c2]
	c.li = league_idx
	c.ci = club_idx
	return c


func _draw() -> void:
	var r: float = minf(size.x, size.y) / 2.0
	var ctr := size / 2.0
	# escudo do datapack, se houver
	var tex: Texture2D = null
	if raw.size() == 3:
		tex = DataPack.logo(li, ci)
	elif cid >= 0 and not Game.S.is_empty():
		tex = Game.club_logo(cid)
	if tex != null:
		draw_texture_rect(tex, Rect2(ctr - Vector2(r, r), Vector2(r, r) * 2.0), false)
		return
	var c1 := Color("44506a")
	var c2 := Color("8a94a8")
	var txt := "—"
	if raw.size() == 3:
		txt = raw[0]
		c1 = Color(str(raw[1]))
		c2 = Color(str(raw[2]))
	elif cid >= 0 and not Game.S.is_empty() and cid < Game.S["clubs"].size():
		var cl: Dictionary = Game.S["clubs"][cid]
		c1 = Color(str(cl["c1"]))
		c2 = Color(str(cl["c2"]))
		txt = cl["short"]
	draw_circle(ctr, r, Color("f4f6fa"))
	draw_circle(ctr, r * 0.9, c1)
	# faixa central com a segunda cor
	draw_rect(Rect2(ctr.x - r * 0.86, ctr.y - r * 0.26, r * 1.72, r * 0.52), c2)
	draw_arc(ctr, r * 0.9, 0, TAU, 40, Color("f4f6fa"), maxf(r * 0.08, 1.0), true)
	var fs := int(r * 0.52)
	if fs >= 7:
		var f := UI.bold()
		var tc := Color("101010") if c2.get_luminance() > 0.5 else Color("ffffff")
		draw_string(f, Vector2(ctr.x - r, ctr.y + fs * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, tc)
