class_name CoachAvatar
extends Control
# Desenho do técnico (pele, cabelo, barba e roupa escolhidos na criação).

const SKINS := [Color("f6d3b3"), Color("e8b88f"), Color("c98f62"), Color("9a643f"), Color("6b3f26")]
const HAIR_COLORS := [Color("1a1a1e"), Color("5a3a22"), Color("d9b25f"), Color("a9adb5")]
const HAIR_NAMES := ["Curto", "Topete", "Longo ondulado", "Careca"]
const HAIR_COLOR_NAMES := ["Preto", "Castanho", "Loiro", "Grisalho"]
const BEARD_NAMES := ["Sem barba", "Barba", "Bigode"]
const SUITS := [Color("2553a8"), Color("1d2333"), Color("2c7a4d")]
const SUIT_NAMES := ["Terno azul", "Terno escuro", "Agasalho verde"]

var coach: Dictionary = {}


func _draw() -> void:
	if coach.is_empty():
		return
	var w := size.x
	var h := size.y
	var u: float = minf(w / 200.0, h / 240.0)
	var cx := w / 2.0
	var top := h - 240.0 * u
	var skin: Color = SKINS[int(coach.get("skin", 1)) % SKINS.size()]
	var hair: Color = HAIR_COLORS[int(coach.get("haircolor", 0)) % HAIR_COLORS.size()]
	var suit: Color = SUITS[int(coach.get("suit", 0)) % SUITS.size()]
	var hs: int = int(coach.get("hair", 0))
	var beard: int = int(coach.get("beard", 0))
	var head := Vector2(cx, top + 78 * u)
	# cabelo comprido atrás
	if hs == 2:
		draw_rect(Rect2(cx - 50 * u, top + 60 * u, 100 * u, 86 * u), hair)
		draw_circle(Vector2(cx - 40 * u, top + 146 * u), 12 * u, hair)
		draw_circle(Vector2(cx + 40 * u, top + 146 * u), 12 * u, hair)
	# corpo
	draw_rect(Rect2(cx - 86 * u, top + 156 * u, 172 * u, 84 * u), suit)
	draw_circle(Vector2(cx - 62 * u, top + 160 * u), 24 * u, suit)
	draw_circle(Vector2(cx + 62 * u, top + 160 * u), 24 * u, suit)
	draw_rect(Rect2(cx - 62 * u, top + 136 * u, 124 * u, 30 * u), suit)
	# pescoço e camisa
	draw_rect(Rect2(cx - 16 * u, top + 112 * u, 32 * u, 36 * u), skin.darkened(0.12))
	if int(coach.get("suit", 0)) < 2:
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 30 * u, top + 136 * u), Vector2(cx + 30 * u, top + 136 * u), Vector2(cx + 14 * u, top + 240 * u), Vector2(cx - 14 * u, top + 240 * u)]), Color("f1f3f8"))
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 8 * u, top + 146 * u), Vector2(cx + 8 * u, top + 146 * u), Vector2(cx + 10 * u, top + 226 * u), Vector2(cx, top + 240 * u), Vector2(cx - 10 * u, top + 226 * u)]), UI.GOLD)
	else:
		draw_rect(Rect2(cx - 3 * u, top + 140 * u, 6 * u, 100 * u), Color("e9edf5"))
	# cabeça
	draw_circle(Vector2(head.x - 44 * u, head.y + 4 * u), 9 * u, skin)
	draw_circle(Vector2(head.x + 44 * u, head.y + 4 * u), 9 * u, skin)
	draw_circle(head, 44 * u, skin)
	draw_rect(Rect2(head.x - 40 * u, head.y, 80 * u, 30 * u), skin)
	draw_circle(Vector2(head.x, head.y + 22 * u), 36 * u, skin)
	# barba
	if beard == 1:
		draw_circle(Vector2(head.x, head.y + 26 * u), 34 * u, hair)
		draw_circle(Vector2(head.x, head.y + 8 * u), 34 * u, skin)
		draw_rect(Rect2(head.x - 12 * u, head.y + 30 * u, 24 * u, 5 * u), skin.darkened(0.25))
	elif beard == 2:
		draw_rect(Rect2(head.x - 16 * u, head.y + 24 * u, 32 * u, 6 * u), hair)
	if beard != 1:
		draw_rect(Rect2(head.x - 9 * u, head.y + 36 * u, 18 * u, 3 * u), skin.darkened(0.35))
	# cabelo
	if hs != 3:
		draw_circle(Vector2(head.x, head.y - 14 * u), 42 * u, hair)
		draw_rect(Rect2(head.x - 44 * u, head.y - 22 * u, 88 * u, 14 * u), hair)
		draw_circle(Vector2(head.x, head.y + 6 * u), 38 * u, skin)
		draw_rect(Rect2(head.x - 36 * u, head.y - 12 * u, 72 * u, 20 * u), skin)
		if hs == 1:
			draw_circle(Vector2(head.x + 6 * u, head.y - 50 * u), 18 * u, hair)
			draw_circle(Vector2(head.x - 14 * u, head.y - 46 * u), 14 * u, hair)
	# olhos e sobrancelhas
	draw_rect(Rect2(head.x - 24 * u, head.y - 2 * u, 14 * u, 3 * u), Color("1c1c22"))
	draw_rect(Rect2(head.x + 10 * u, head.y - 2 * u, 14 * u, 3 * u), Color("1c1c22"))
	draw_circle(Vector2(head.x - 17 * u, head.y + 9 * u), 3.6 * u, Color("23304a"))
	draw_circle(Vector2(head.x + 17 * u, head.y + 9 * u), 3.6 * u, Color("23304a"))
