extends Control
## Demo/captura da TrophyCelebration: salva PNGs em production/qa/evidence/.

const OUT := "res://production/qa/evidence/"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	var c := TrophyCelebration.play(self, "Copa Continental", "Craque FC", null, "ouro")
	await _shot(0.75, "trofeu_inicio")
	await _shot(1.25, "trofeu_meio")
	await _shot(1.4, "trofeu_fim")
	await c.done
	var c2 := TrophyCelebration.play(self, "Copa Sul-Continental", "Atlético Litoral", _make_logo(), "prata")
	await _shot(3.2, "trofeu_prata")
	await c2.done
	get_tree().quit()


func _shot(wait: float, file: String) -> void:
	await get_tree().create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + file + ".png"))
	print("salvo: ", file)


func _make_logo() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length()
			if d < 30.0:
				img.set_pixel(x, y, Color("1f4fa8") if d > 22.0 else Color("e8392b"))
	return ImageTexture.create_from_image(img)
