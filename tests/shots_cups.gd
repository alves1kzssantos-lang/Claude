extends Node
## Capturas das telas de copa para production/qa/evidence/.

var m


func _snap(name: String) -> void:
	for i in 8:
		await get_tree().process_frame
	await get_tree().create_timer(1.6).timeout   # espera as animações de entrada
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://production/qa/evidence/%s.png" % name)


func _show(screen: String, arg) -> void:
	m.stack.clear()
	m.cur = [screen, arg]
	m.refresh()


func _cup_index(name: String) -> int:
	var cups: Array = Game.S.get("cups", [])
	for i in cups.size():
		if str(cups[i]["name"]) == name:
			return i
	return -1


## Última etapa de uma fase (ex.: semifinal - segunda partida).
func _last_stage_of_round(ci: int, r: int) -> int:
	var c: Dictionary = Game.S["cups"][ci]
	var sts: Array = Cups.stages(c)
	var best := -1
	for i in sts.size():
		if int(sts[i]["round"]) == r:
			best = i
	return best


func _ready():
	m = load("res://main.tscn").instantiate()
	add_child(m)
	await get_tree().process_frame
	if not DataPack.loaded(): DataPack.import_zip("res://datapack.zip")
	var coach = {"name": "Alves", "age": 35, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}
	Game.rng.seed = 77
	Game.new_career(7, coach, 0, 0)
	var guard := 0
	while guard < 60:
		guard += 1
		var mt := Game.next_user_match()
		if mt.is_empty(): break
		if mt["kind"] == "cup":
			m.reset("hub"); await _snap("copa_proxima_partida")
			Game.play_next(null)
			m.go("postmatch", Game.S["last_user"]); await _snap("copa_fim_de_jogo")
			m.replace("cup_results", {"cup": Game.S["last_user"]["cup"], "stage": -1, "next": true})
			await _snap("copa_resultados_fase")
			m.go("cup", {"cup": Game.S["last_user"]["cup"], "next": false}); await _snap("copa_chaveamento")
			break
		Game.play_next(null)
	m.hub_tab = 0
	m.reset("calendar"); await _snap("copa_calendario")
	while not Game.S["season_over"] and guard < 300:
		guard += 1
		if guard % 10 == 0:
			print("shots: evento ", guard, " dia ", Game.S["day"])
		Game.play_next(null)
	print("shots: temporada encerrada após ", guard)
	# Copa do Brasil: final
	var cb := _cup_index("Copa do Brasil")
	if cb >= 0:
		_show("cup_results", {"cup": cb, "stage": -1, "next": false}); await _snap("copa_brasil_final")
	# Libertadores: semifinal (segunda partida) e final
	var lib := _cup_index("Copa Libertadores")
	if lib >= 0:
		var c: Dictionary = Game.S["cups"][lib]
		var semi := _last_stage_of_round(lib, c["rounds"].size() - 2)
		_show("cup_results", {"cup": lib, "stage": semi, "next": false}); await _snap("copa_libertadores_semi_volta")
		_show("cup_results", {"cup": lib, "stage": -1, "next": false}); await _snap("copa_libertadores_resultado_final")
		_show("cup", {"cup": lib, "next": false}); await _snap("copa_libertadores_final")
	m.reset("season_end"); await _snap("copa_fim_temporada")
	Game.delete_save(7)
	get_tree().quit()
