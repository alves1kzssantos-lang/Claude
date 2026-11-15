class_name PitchView
extends Control
# Campo de jogo.
#  - modo "lineup": campo em pé, com as notas dos 11 (toque para escolher)
#  - modo "match": campo deitado, com os dois times e a bola

signal slot_pressed(index: int)

var mode: String = "lineup"
var cid: int = 0          # clube (modo lineup)
var selected: int = -1
var sim = null            # MatchSim (modo match)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _slot_pos(i: int, slots: Array) -> Vector2:
	var s: Array = slots[i]
	return Vector2(size.x * float(s[1]), size.y * (1.0 - float(s[2])) * 0.94 + size.y * 0.02)


func _gui_input(e: InputEvent) -> void:
	if mode != "lineup":
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var slots: Array = Game.FORMATIONS[Game.club(cid)["formation"]]
		var best := -1
		var bd := 1e9
		for i in slots.size():
			var d: float = _slot_pos(i, slots).distance_to(e.position)
			if d < bd:
				bd = d
				best = i
		if best >= 0 and bd < maxf(size.x, size.y) * 0.13:
			slot_pressed.emit(best)
		accept_event()


func _draw_field(vertical: bool) -> void:
	var g1 := Color("2f8f52")
	var g2 := Color("2a8249")
	var line := Color(1, 1, 1, 0.55)
	draw_rect(Rect2(Vector2.ZERO, size), g1)
	var n := 8
	for i in n:
		if i % 2 == 0:
			if vertical:
				draw_rect(Rect2(0, size.y * i / n, size.x, size.y / n), g2)
			else:
				draw_rect(Rect2(size.x * i / n, 0, size.x / n, size.y), g2)
	var m := 6.0
	draw_rect(Rect2(m, m, size.x - m * 2, size.y - m * 2), line, false, 2.0)
	if vertical:
		draw_line(Vector2(m, size.y / 2), Vector2(size.x - m, size.y / 2), line, 2.0)
		draw_arc(size / 2, size.x * 0.12, 0, TAU, 40, line, 2.0)
		var bw := size.x * 0.44
		var bh := size.y * 0.13
		draw_rect(Rect2((size.x - bw) / 2, m, bw, bh), line, false, 2.0)
		draw_rect(Rect2((size.x - bw) / 2, size.y - m - bh, bw, bh), line, false, 2.0)
	else:
		draw_line(Vector2(size.x / 2, m), Vector2(size.x / 2, size.y - m), line, 2.0)
		draw_arc(size / 2, size.y * 0.16, 0, TAU, 40, line, 2.0)
		var bw2 := size.x * 0.12
		var bh2 := size.y * 0.5
		draw_rect(Rect2(m, (size.y - bh2) / 2, bw2, bh2), line, false, 2.0)
		draw_rect(Rect2(size.x - m - bw2, (size.y - bh2) / 2, bw2, bh2), line, false, 2.0)


func _draw() -> void:
	if Game.S.is_empty():
		return
	var f := UI.bold()
	if mode == "lineup":
		_draw_field(true)
		var c: Dictionary = Game.club(cid)
		var slots: Array = Game.FORMATIONS[c["formation"]]
		var bw: float = clampf(size.x * 0.085, 30.0, 46.0)
		for i in mini(slots.size(), c["xi"].size()):
			var p: Dictionary = Game.player(c["xi"][i])
			var pos := _slot_pos(i, slots)
			var rect := Rect2(pos.x - bw / 2, pos.y - bw / 2, bw, bw)
			var okpos: bool = p["pos"] == slots[i][0]
			draw_rect(rect, Color("14203a"))
			draw_rect(rect, UI.GOLD if i == selected else (Color(1, 1, 1, 0.8) if okpos else Color("ff8b6b")), false, 3.0 if i == selected else 1.5)
			draw_string(f, Vector2(rect.position.x, pos.y + bw * 0.19), str(p["ovr"]), HORIZONTAL_ALIGNMENT_CENTER, bw, int(bw * 0.5), Color.WHITE)
			draw_string(f, Vector2(pos.x - 60, rect.position.y - 5), slots[i][0], HORIZONTAL_ALIGNMENT_CENTER, 120, 12, UI.pos_color(slots[i][0]))
			var nm: String = p["name"]
			if nm.length() > 14:
				nm = nm.substr(0, 13) + "."
			draw_string(f, Vector2(pos.x - 70, rect.end.y + 15), nm, HORIZONTAL_ALIGNMENT_CENTER, 140, 13, Color.WHITE)
			# barra de energia
			var en: float = float(p["energy"]) / 100.0
			draw_rect(Rect2(rect.position.x, rect.end.y - 4, bw * en, 4), UI.GREEN if en > 0.6 else UI.RED)
	elif sim != null:
		_draw_field(false)
		var cols := [Color("5aa2f2"), Color("f0685e")]
		for side in 2:
			var c2: Dictionary = Game.club(sim.cid(side))
			var slots2: Array = Game.FORMATIONS[c2["formation"]]
			for i in slots2.size():
				var s: Array = slots2[i]
				var along: float = float(s[2]) * 0.46 + 0.03
				var x: float = along if side == 0 else 1.0 - along
				var y: float = float(s[1]) if side == 0 else 1.0 - float(s[1])
				# o time com a bola avança um pouco
				x += (sim.ball.x - 0.5) * 0.18
				var pt := Vector2(size.x * clampf(x, 0.03, 0.97), size.y * (0.1 + y * 0.8))
				draw_circle(pt, 8.0, Color("0e1a30"))
				draw_circle(pt, 6.0, cols[side])
		var b := Vector2(size.x * sim.ball.x, size.y * sim.ball.y)
		draw_circle(b, 6.0, Color("101010"))
		draw_circle(b, 4.5, Color.WHITE)
