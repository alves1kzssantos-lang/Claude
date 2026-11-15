extends Node
## Ferramenta: joga uma temporada em cada liga (com copas) e lista problemas.
func _ready():
	if not DataPack.loaded(): DataPack.import_zip("res://datapack.zip")
	var coach = {"name": "T", "age": 35, "nat": "Brasil", "skin": 1, "hair": 0, "haircolor": 0, "beard": 0, "suit": 0, "rep": 5.0}
	var t0 = Time.get_ticks_msec()
	for li in World.LEAGUES.size():
		Game.new_career(9, coach, 0, li)
		var g := 0
		while not Game.S.season_over and g < 200:
			g += 1
			Game.play_next(null)
		var nologo = 0
		for c in Game.n_league():
			if Game.club_logo(c) == null: nologo += 1
		var cups := []
		for c in Game.S.cups:
			cups.append("%s(%d)%s" % [c.name, c.rounds[0].size() * 2 if not c.rounds.is_empty() else 0, "" if c.champion >= 0 else " SEM CAMPEÃO"])
		print(li, " ", Game.LEAGUE, " | ", Game.n_league(), " clubes | sem escudo ", nologo, " | logo liga ", DataPack.comp_logo_by_id(DataPack.comp_id(li)) != null, " | ", ", ".join(cups))
	print("tempo ", Time.get_ticks_msec() - t0)
	Game.delete_save(9)
	get_tree().quit()
