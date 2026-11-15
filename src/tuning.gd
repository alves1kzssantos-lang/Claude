class_name Tuning
## Lê os números da partida de assets/data/match_tuning.json.
## Uso: Tuning.f("passe", "velocidade_rasteiro_max")
## Se a chave não existir no arquivo, devolve o valor de reserva informado.

const PATH := "res://assets/data/match_tuning.json"

static var _data: Dictionary = {}
static var _loaded: bool = false


## Recarrega o arquivo (útil em testes ou depois de editar o JSON).
static func reload() -> void:
	_loaded = true
	_data = {}
	if not FileAccess.file_exists(PATH):
		push_warning("Tuning: %s não encontrado, usando valores de reserva" % PATH)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
	else:
		push_warning("Tuning: JSON inválido em %s" % PATH)


## Devolve um número da seção pedida.
static func f(section: String, key: String, fallback: float = 0.0) -> float:
	if not _loaded:
		reload()
	var sec = _data.get(section, {})
	if typeof(sec) == TYPE_DICTIONARY and sec.has(key):
		return float(sec[key])
	push_warning("Tuning: falta %s.%s, usando %s" % [section, key, fallback])
	return fallback
