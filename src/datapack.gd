class_name DataPack
# ============================================================
# Sistema de DATAPACK — importa TUDO que o pacote tem:
#   clubs.csv, stadiums.csv, competitions.csv, players.csv (id,nome)
#   club_logos/ID.webp e competition_logos/ID.webp
# e liga os clubes/ligas do jogo ao pacote:
#   1) pela tabela CLUB_IDS abaixo (feita à mão para as 9 ligas)
#   2) pelo NOME, para qualquer clube que você acrescentar no
#      world_data.gd usando o mesmo nome do pacote.
#
# Como usar: copie o pacote para a pasta do projeto com o nome
# "datapack.zip" e toque em Datapack > Importar (tela de carreiras).
#
# Elencos reais (opcional): ponha dentro do zip um "elencos.csv"
# com uma linha por jogador:
#     Clube;Jogador;Posição;Idade;Nota;País
# Posições: GOL ZAG LD LE VOL MEI PD PE AC
# ============================================================

const DIR := "user://datapack/"
const BUNDLED := "res://assets/datapack/"   ## escudos/logos/placas do pacote do jogo já dentro do APK (carregam rápido)
const PACK_VER := 3   ## sobe quando a importação passa a trazer coisas novas (3 = placas de publicidade)
## País da liga -> pasta de placas do datapack (adboards/country-XXX)
const AD_COUNTRY := {"Brasil": "BRA", "Argentina": "ARG", "Inglaterra": "ENG", "Espanha": "ESP", "Itália": "ITA", "Alemanha": "DEU",
	"França": "FRA", "Portugal": "PRT", "Holanda": "NLD", "Bélgica": "BEL", "Turquia": "TUR", "Arábia Saudita": "SAU",
	"Estados Unidos": "USA", "México": "MEX", "Chile": "CHL", "Colômbia": "COL", "Grécia": "GRC", "Dinamarca": "DNK", "Suécia": "SWE",
	"Coreia do Sul": "KOR", "China": "CHN", "Paraguai": "PRY", "Peru": "PER", "Equador": "ECU", "Emirados Árabes": "ARE", "Irã": "IRN",
	"Marrocos": "MAR", "Indonésia": "IDN", "Canadá": "CAN"}
static var _ads: Dictionary = {}
const SOURCES := ["res://datapack.zip", "user://datapack.zip"]

# "liga|clube" (sem acento, minúsculo) -> ID do clube no pacote
const CLUB_IDS := {
	# Brasileirão Série A (temporada 2026)
	"brasileiraoseriea|flamengo": 410, "brasileiraoseriea|palmeiras": 422, "brasileiraoseriea|cruzeiro": 407, "brasileiraoseriea|corinthians": 428,
	"brasileiraoseriea|botafogo": 400, "brasileiraoseriea|atleticomg": 401, "brasileiraoseriea|saopaulo": 435, "brasileiraoseriea|fluminense": 411,
	"brasileiraoseriea|internacional": 416, "brasileiraoseriea|bahia": 408, "brasileiraoseriea|gremio": 414, "brasileiraoseriea|santos": 431,
	"brasileiraoseriea|vascodagama": 436, "brasileiraoseriea|rbbragantino": 402, "brasileiraoseriea|athleticopr": 398, "brasileiraoseriea|mirassol": 6976,
	"brasileiraoseriea|vitoria": 438, "brasileiraoseriea|coritiba": 405, "brasileiraoseriea|chapecoense": 4182, "brasileiraoseriea|remo": 427,
	# Brasileirão Série B (temporada 2026)
	"brasileiraoserieb|fortaleza": 5383, "brasileiraoserieb|sport": 433, "brasileiraoserieb|ceara": 403, "brasileiraoserieb|juventude": 5378,
	"brasileiraoserieb|goias": 413, "brasileiraoserieb|atleticogo": 396, "brasileiraoserieb|criciuma": 406, "brasileiraoserieb|cuiaba": 5382,
	"brasileiraoserieb|americamg": 397, "brasileiraoserieb|avai": 399, "brasileiraoserieb|novorizontino": 6654, "brasileiraoserieb|vilanova": 437,
	"brasileiraoserieb|crb": 3909, "brasileiraoserieb|operariopr": 5549, "brasileiraoserieb|athleticclub": 9180, "brasileiraoserieb|botafogosp": 5385,
	"brasileiraoserieb|pontepreta": 425, "brasileiraoserieb|nautico": 421, "brasileiraoserieb|londrina": 5215, "brasileiraoserieb|saobernardo": 8532,
	# Brasileirão Série C (temporada 2026)
	"brasileiraoseriec|paysandu": 4180, "brasileiraoseriec|guarani": 418, "brasileiraoseriec|figueirense": 409, "brasileiraoseriec|brusque": 6655,
	"brasileiraoseriec|ypiranga": 5389, "brasileiraoseriec|caxiasdosul": 7066, "brasileiraoseriec|floresta": 6861, "brasileiraoseriec|botafogopb": 5379,
	"brasileiraoseriec|confianca": 5380, "brasileiraoseriec|abc": 395, "brasileiraoseriec|voltaredonda": 5388, "brasileiraoseriec|csa": 5381,
	"brasileiraoseriec|itabaiana": 6974, "brasileiraoseriec|ituano": 6704, "brasileiraoseriec|maringa": 9187, "brasileiraoseriec|anapolis": 8907,
	"brasileiraoseriec|tombense": 5387, "brasileiraoseriec|amazonas": 8908, "brasileiraoseriec|ferroviaria": 6971, "brasileiraoseriec|interdelimeira": 7012,
	# Liga Argentina
	"ligaargentina|riverplate": 114, "ligaargentina|bocajuniors": 106, "ligaargentina|racing": 137, "ligaargentina|estudiantes": 127,
	"ligaargentina|velezsarsfield": 144, "ligaargentina|independiente": 109, "ligaargentina|talleres": 141, "ligaargentina|sanlorenzo": 138,
	"ligaargentina|rosariocentral": 115, "ligaargentina|lanus": 110, "ligaargentina|argentinosjuniors": 99, "ligaargentina|huracan": 108,
	"ligaargentina|newellsoldboys": 135, "ligaargentina|godoycruz": 131, "ligaargentina|defensayjusticia": 126, "ligaargentina|belgrano": 105,
	"ligaargentina|banfield": 104, "ligaargentina|gimnasialp": 130, "ligaargentina|union": 143, "ligaargentina|tigre": 116,
	# Premier League
	"premierleague|manchestercity": 919, "premierleague|liverpool": 915, "premierleague|arsenal": 810, "premierleague|chelsea": 845,
	"premierleague|manchesterunited": 920, "premierleague|tottenham": 977, "premierleague|newcastleunited": 928, "premierleague|astonvilla": 811,
	"premierleague|brighton": 830, "premierleague|westhamunited": 984, "premierleague|nottinghamforest": 933, "premierleague|crystalpalace": 856,
	"premierleague|bournemouth": 802, "premierleague|fulham": 877, "premierleague|brentford": 829, "premierleague|everton": 868,
	"premierleague|wolverhampton": 990, "premierleague|leedsunited": 909, "premierleague|burnley": 834, "premierleague|sunderland": 970,
	# La Liga
	"laliga|realmadrid": 2921, "laliga|barcelona": 2880, "laliga|atleticodemadrid": 2835, "laliga|athleticbilbao": 2834,
	"laliga|villarreal": 2967, "laliga|realbetis": 2918, "laliga|realsociedad": 2926, "laliga|sevilla": 2943,
	"laliga|girona": 2885, "laliga|valencia": 2962, "laliga|celtadevigo": 2869, "laliga|osasuna": 2844,
	"laliga|rayovallecano": 2916, "laliga|mallorca": 2911, "laliga|getafe": 2883, "laliga|espanyol": 2909,
	"laliga|alaves": 2876, "laliga|levante": 2889, "laliga|elche": 2879, "laliga|realoviedo": 2925,
	# Serie A Itália
	"serieaitalia|inter": 1596, "serieaitalia|napoli": 1622, "serieaitalia|juventus": 1597, "serieaitalia|milan": 1566,
	"serieaitalia|atalanta": 1581, "serieaitalia|roma": 1578, "serieaitalia|lazio": 1618, "serieaitalia|fiorentina": 1573,
	"serieaitalia|bologna": 1583, "serieaitalia|torino": 1628, "serieaitalia|udinese": 1642, "serieaitalia|genoa": 1594,
	"serieaitalia|como": 1587, "serieaitalia|parma": 1602, "serieaitalia|cagliari": 1585, "serieaitalia|sassuolo": 1640,
	"serieaitalia|lecce": 1637, "serieaitalia|verona": 1595, "serieaitalia|pisa": 1606, "serieaitalia|cremonese": 1634,
	# Bundesliga
	"bundesliga|bayernmunchen": 1215, "bundesliga|bayerleverkusen": 1213, "bundesliga|borussiadortmund": 1217, "bundesliga|rbleipzig": 4106,
	"bundesliga|eintrachtfrankfurt": 1224, "bundesliga|stuttgart": 1282, "bundesliga|freiburg": 1255, "bundesliga|mainz05": 1208,
	"bundesliga|wolfsburg": 1286, "bundesliga|borussiamgladbach": 1219, "bundesliga|werderbremen": 1268, "bundesliga|hoffenheim": 1276,
	"bundesliga|unionberlin": 1207, "bundesliga|augsburg": 1227, "bundesliga|koln": 1203, "bundesliga|hamburg": 1238,
	"bundesliga|stpauli": 1232, "bundesliga|heidenheim": 1269,
	# Ligue 1
	"ligue1|parissaintgermain": 1164, "ligue1|olympiquedemarseille": 1161, "ligue1|monaco": 1122, "ligue1|lille": 1154,
	"ligue1|lyon": 1160, "ligue1|nice": 1158, "ligue1|lens": 1165, "ligue1|rennes": 1175,
	"ligue1|strasbourg": 1166, "ligue1|toulouse": 1147, "ligue1|brest": 1173, "ligue1|nantes": 1143,
	"ligue1|auxerre": 1118, "ligue1|angers": 1126, "ligue1|lehavre": 1151, "ligue1|lorient": 1155,
	"ligue1|metz": 1142, "ligue1|parisfc": 1163,
	# Liga Portugal
	"ligaportugal|benfica": 2362, "ligaportugal|porto": 2343, "ligaportugal|sporting": 2364, "ligaportugal|braga": 2365,
	"ligaportugal|vitoriasc": 2370, "ligaportugal|famalicao": 5034, "ligaportugal|gilvicente": 2345, "ligaportugal|estoril": 2339,
	"ligaportugal|moreirense": 2349, "ligaportugal|casapia": 6001, "ligaportugal|rioave": 2358, "ligaportugal|santaclara": 2363,
	"ligaportugal|arouca": 2326, "ligaportugal|nacional": 2350, "ligaportugal|estrelaamadora": 6748, "ligaportugal|avs": 10132,
	"ligaportugal|tondela": 3702, "ligaportugal|alverca": 2330,
	# EFL Championship
	"eflchampionship|leicestercity": 910, "eflchampionship|ipswichtown": 904, "eflchampionship|southampton": 959, "eflchampionship|sheffieldunited": 954,
	"eflchampionship|westbromwich": 983, "eflchampionship|middlesbrough": 924, "eflchampionship|coventrycity": 853, "eflchampionship|norwichcity": 932,
	"eflchampionship|watford": 981, "eflchampionship|millwall": 925, "eflchampionship|bristolcity": 831, "eflchampionship|hullcity": 901,
	"eflchampionship|stokecity": 969, "eflchampionship|swanseacity": 972, "eflchampionship|derbycounty": 859, "eflchampionship|prestonnorthend": 943,
	"eflchampionship|queensparkrangers": 944, "eflchampionship|blackburnrovers": 820, "eflchampionship|sheffieldwednesday": 955, "eflchampionship|portsmouth": 942,
	"eflchampionship|oxfordunited": 938, "eflchampionship|charltonathletic": 843, "eflchampionship|wrexham": 994, "eflchampionship|birminghamcity": 818,
	# LaLiga 2
	"laliga2|realvalladolid": 2931, "laliga2|laspalmas": 2951, "laliga2|leganes": 2854, "laliga2|sportinggijon": 2928,
	"laliga2|racingsantander": 2914, "laliga2|almeria": 2947, "laliga2|malaga": 2898, "laliga2|realzaragoza": 2933,
	"laliga2|granada": 2887, "laliga2|cadiz": 2874, "laliga2|huesca": 2937, "laliga2|burgos": 2842,
	"laliga2|eibar": 2936, "laliga2|albacete": 2829, "laliga2|castellon": 2868, "laliga2|mirandes": 2859,
	"laliga2|cordoba": 2875, "laliga2|andorra": 2832, "laliga2|culturalleonesa": 2873, "laliga2|ceuta": 2827,
	# Serie B
	"serieb|monza": 3789, "serieb|empoli": 1589, "serieb|venezia": 3783, "serieb|palermo": 1633,
	"serieb|sampdoria": 1631, "serieb|spezia": 1579, "serieb|bari": 1574, "serieb|modena": 1599,
	"serieb|frosinone": 1592, "serieb|cesena": 1560, "serieb|catanzaro": 3660, "serieb|sudtirol": 3779,
	"serieb|reggiana": 1570, "serieb|carrarese": 1601, "serieb|juvestabia": 1617, "serieb|mantova": 1564,
	"serieb|padova": 1588, "serieb|virtusentella": 3643, "serieb|avellino": 3781, "serieb|pescara": 1604,
	# 2. Bundesliga
	"2bundesliga|schalke04": 1231, "2bundesliga|herthabsc": 1242, "2bundesliga|holsteinkiel": 1244, "2bundesliga|bochum": 1284,
	"2bundesliga|fortunadusseldorf": 1236, "2bundesliga|hannover96": 1240, "2bundesliga|kaiserslautern": 1201, "2bundesliga|karlsruher": 1246,
	"2bundesliga|darmstadt98": 1262, "2bundesliga|nurnberg": 1205, "2bundesliga|paderborn": 1256, "2bundesliga|elversberg": 1264,
	"2bundesliga|greutherfurth": 1271, "2bundesliga|magdeburg": 1204, "2bundesliga|eintbraunschweig": 1223, "2bundesliga|arminiabielefeld": 1211,
	"2bundesliga|preuenmunster": 1247, "2bundesliga|dynamodresden": 1222,
	# Ligue 2
	"ligue2|saintetienne": 1124, "ligue2|montpellier": 1156, "ligue2|reims": 1176, "ligue2|guingamp": 1137,
	"ligue2|troyes": 1136, "ligue2|pau": 5276, "ligue2|grenoble": 1148, "ligue2|redstar": 3715,
	"ligue2|amiens": 1125, "ligue2|bastia": 1168, "ligue2|annecy": 6385, "ligue2|rodez": 1167,
	"ligue2|clermont": 1133, "ligue2|lemans": 1152, "ligue2|laval": 1174, "ligue2|dunkerque": 4111,
	"ligue2|boulogne": 1178, "ligue2|nancy": 1123,
	# Eredivisie
	"eredivisie|psv": 1990, "eredivisie|feyenoord": 1978, "eredivisie|ajax": 1964, "eredivisie|azalkmaar": 1963,
	"eredivisie|twente": 1974, "eredivisie|utrecht": 1975, "eredivisie|necnijmegen": 1989, "eredivisie|goaheadeagles": 1980,
	"eredivisie|spartarotterdam": 1998, "eredivisie|heerenveen": 1996, "eredivisie|fortunasittard": 1979, "eredivisie|groningen": 1971,
	"eredivisie|peczwolle": 1977, "eredivisie|heraclesalmelo": 1984, "eredivisie|nacbreda": 1988, "eredivisie|excelsior": 1994,
	"eredivisie|telstar": 2000, "eredivisie|volendam": 1976,
	# Jupiler Pro League
	"jupilerproleague|clubbrugge": 280, "jupilerproleague|unionsaintgilloise": 317, "jupilerproleague|anderlecht": 305, "jupilerproleague|genk": 306,
	"jupilerproleague|kaagent": 277, "jupilerproleague|antwerp": 278, "jupilerproleague|standardliege": 315, "jupilerproleague|mechelen": 295,
	"jupilerproleague|westerlo": 321, "jupilerproleague|charleroi": 313, "jupilerproleague|cerclebrugge": 279, "jupilerproleague|ohleuven": 302,
	"jupilerproleague|sinttruidensem": 288, "jupilerproleague|zultewaregem": 312, "jupilerproleague|raallalouviere": 6024, "jupilerproleague|dender": 281,
	# Süper Lig
	"superlig|galatasaray": 3163, "superlig|fenerbahce": 3160, "superlig|beikta": 3141, "superlig|trabzonspor": 3207,
	"superlig|baakehir": 7058, "superlig|samsunspor": 3202, "superlig|goztepe": 3135, "superlig|eyupspor": 3158,
	"superlig|kasmpaa": 3183, "superlig|rizespor": 3216, "superlig|konyaspor": 3187, "superlig|kayserispor": 3185,
	"superlig|alanyaspor": 3132, "superlig|antalyaspor": 3138, "superlig|gaziantep": 3165, "superlig|kocaelispor": 3186,
	"superlig|genclerbirlii": 3168, "superlig|karagumruk": 3159,
	# Saudi Pro League
	"saudiproleague|alhilal": 2570, "saudiproleague|alnassr": 2573, "saudiproleague|alittihad": 2571, "saudiproleague|alahli": 2568,
	"saudiproleague|alqadsiah": 2574, "saudiproleague|alshabab": 2577, "saudiproleague|alettifaq": 2569, "saudiproleague|altaawoun": 2578,
	"saudiproleague|alkhaleej": 4324, "saudiproleague|alfateh": 2580, "saudiproleague|alfayha": 5483, "saudiproleague|alriyadh": 2576,
	"saudiproleague|alkholood": 9475, "saudiproleague|alokhdood": 6855, "saudiproleague|alhazem": 2567, "saudiproleague|alnajma": 9482,
	"saudiproleague|damac": 6010, "saudiproleague|neom": 7708,
	# Major League Soccer
	"majorleaguesoccer|intermiami": 6146, "majorleaguesoccer|lagalaxy": 3314, "majorleaguesoccer|losangelesfc": 5583, "majorleaguesoccer|columbuscrew": 3307,
	"majorleaguesoccer|cincinnati": 5192, "majorleaguesoccer|philadelphiaunion": 3446, "majorleaguesoccer|seattlesounders": 3326, "majorleaguesoccer|orlandocity": 3298,
	"majorleaguesoccer|newyorkcity": 3300, "majorleaguesoccer|atlantaunited": 3321, "majorleaguesoccer|nashville": 5584, "majorleaguesoccer|charlotte": 3303,
	"majorleaguesoccer|minnesotaunited": 3316, "majorleaguesoccer|realsaltlake": 3322, "majorleaguesoccer|vancouver": 503, "majorleaguesoccer|portlandtimbers": 3320,
	"majorleaguesoccer|houstondynamo": 3312, "majorleaguesoccer|dallas": 3310, "majorleaguesoccer|austin": 3679, "majorleaguesoccer|coloradorapids": 3306,
	"majorleaguesoccer|sandiego": 6539, "majorleaguesoccer|kansascity": 3313, "majorleaguesoccer|stlouiscity": 9731, "majorleaguesoccer|chicagofire": 3304,
	"majorleaguesoccer|nerevolution": 3317, "majorleaguesoccer|cfmontreal": 494, "majorleaguesoccer|torontofc": 3327, "majorleaguesoccer|dcunited": 3309,
	# Liga MX Apertura
	"ligamxapertura|america": 1872, "ligamxapertura|tigres": 1873, "ligamxapertura|monterrey": 1868, "ligamxapertura|cruzazul": 1866,
	"ligamxapertura|toluca": 1877, "ligamxapertura|guadalajara": 1865, "ligamxapertura|pumasunam": 1876, "ligamxapertura|pachuca": 1869,
	"ligamxapertura|leon": 3755, "ligamxapertura|santoslaguna": 1875, "ligamxapertura|atlas": 1863, "ligamxapertura|tijuana": 3466,
	"ligamxapertura|necaxa": 1874, "ligamxapertura|juarez": 6006, "ligamxapertura|puebla": 1878, "ligamxapertura|queretaro": 1867,
	# Chilean Primera División
	"chileanprimeradivision|colocolo": 511, "chileanprimeradivision|universidaddechile": 532, "chileanprimeradivision|coquimbounido": 512, "chileanprimeradivision|palestino": 525,
	"chileanprimeradivision|ohiggins": 524, "chileanprimeradivision|audaxitaliano": 506, "chileanprimeradivision|huachipato": 521, "chileanprimeradivision|everton": 519,
	"chileanprimeradivision|cobresal": 507, "chileanprimeradivision|union": 534, "chileanprimeradivision|nublense": 508, "chileanprimeradivision|deportesiquique": 523,
	"chileanprimeradivision|deporteslimache": 9035, "chileanprimeradivision|deplaserena": 516,
	# Primera A
	"primeraa|atleticonacional": 574, "primeraa|millonarios": 577, "primeraa|junior": 573, "primeraa|americadecali": 570,
	"primeraa|deportestolima": 580, "primeraa|independiente": 585, "primeraa|indepsantafe": 586, "primeraa|oncecaldas": 587,
	"primeraa|deportivocali": 581, "primeraa|atlbucaramanga": 5213, "primeraa|deportivopereira": 583, "primeraa|alianza": 4192,
	"primeraa|aguilasdoradas": 6858, "primeraa|envigado": 584, "primeraa|boyacachico": 575, "primeraa|llaneros": 3925,
	"primeraa|unionmagdalena": 6007, "primeraa|interbogota": 576,
	# Super League Greece
	"superleaguegreece|olympiacos": 1345, "superleaguegreece|paok": 1352, "superleaguegreece|aek": 1295, "superleaguegreece|panathinaikos": 1358,
	"superleaguegreece|aris": 1310, "superleaguegreece|oficreta": 1343, "superleaguegreece|atromitos": 1313, "superleaguegreece|asterastripolis": 6429,
	"superleaguegreece|volos": 6117, "superleaguegreece|levadiakos": 1337, "superleaguegreece|panetolikos": 1360, "superleaguegreece|kifisia": 6791,
	"superleaguegreece|aellarissa": 1293, "superleaguegreece|panserraikos": 1323,
	# Liga Portugal 2
	"ligaportugal2|maritimo": 2348, "ligaportugal2|academicoviseu": 4097, "ligaportugal2|torreense": 6747, "ligaportugal2|chaves": 2337,
	"ligaportugal2|vizela": 2372, "ligaportugal2|leixoes": 2347, "ligaportugal2|penafiel": 2356, "ligaportugal2|feirense": 2344,
	"ligaportugal2|benficab": 4098, "ligaportugal2|fcportob": 4100, "ligaportugal2|pacosdeferreira": 2355, "ligaportugal2|portimonense": 2357,
	"ligaportugal2|udoliveirense": 2367, "ligaportugal2|felgueiras": 6013, "ligaportugal2|sclusitania": 7704, "ligaportugal2|uniaodeleiria": 2368,
	"ligaportugal2|farense": 4096, "ligaportugal2|sportingb": 8860,
	# Superliga
	"superliga|copenhagen": 724, "superliga|midtjylland": 725, "superliga|brndby": 715, "superliga|agfaarhus": 701,
	"superliga|nordsjlland": 726, "superliga|randers": 748, "superliga|viborg": 761, "superliga|silkeborg": 750,
	"superliga|odenseboldklub": 746, "superliga|snderjyske": 756, "superliga|vejle": 760, "superliga|fredericia": 721,
	# Allsvenskan
	"allsvenskan|malmo": 3036, "allsvenskan|hammarby": 2999, "allsvenskan|mjallby": 3037, "allsvenskan|aik": 2972,
	"allsvenskan|djurgrden": 2981, "allsvenskan|goteborg": 3010, "allsvenskan|elfsborg": 3006, "allsvenskan|hacken": 2976,
	"allsvenskan|gais": 2992, "allsvenskan|sirius": 3020, "allsvenskan|norrkoping": 3014, "allsvenskan|brommapojkarna": 3005,
	"allsvenskan|halmstad": 2998, "allsvenskan|degerfors": 2980, "allsvenskan|varnamo": 3017, "allsvenskan|oster": 3065,
	# K League 1
	"kleague1|jeonbukhdmotors": 1731, "kleague1|ulsanhd": 1736, "kleague1|pohangsteelers": 1732, "kleague1|gangwon": 1734,
	"kleague1|seoul": 1726, "kleague1|gimcheonsangmu": 7040, "kleague1|daejeonhanacitizen": 1725, "kleague1|suwon": 3870,
	"kleague1|gwangju": 6317, "kleague1|anyang": 4127, "kleague1|jejusk": 1730, "kleague1|daegu": 1724,
	# Chinese Super League
	"chinesesuperleague|shanghaiport": 6996, "chinesesuperleague|shanghaishenhua": 560, "chinesesuperleague|chengdurongcheng": 544, "chinesesuperleague|beijingguoan": 538,
	"chinesesuperleague|shandongtaishan": 6998, "chinesesuperleague|tianjinjinmen": 7000, "chinesesuperleague|zhejiangpro": 7005, "chinesesuperleague|henanlongmen": 7001,
	"chinesesuperleague|qingdaohainiu": 9426, "chinesesuperleague|yunnanyukun": 545, "chinesesuperleague|dalianyingbo": 7068, "chinesesuperleague|shenzhenpengcity": 6166,
	"chinesesuperleague|wuhanthreetowns": 8583, "chinesesuperleague|qingdaowestcoast": 9427, "chinesesuperleague|meizhouhakka": 5260, "chinesesuperleague|changchunyatai": 541,
	# Division Profesional
	"divisionprofesional|olimpia": 2148, "divisionprofesional|cerroporteno": 2140, "divisionprofesional|libertad": 2143, "divisionprofesional|guarani": 2142,
	"divisionprofesional|nacional": 2144, "divisionprofesional|sportivoluqueno": 2150, "divisionprofesional|sportivotrinidense": 2151, "divisionprofesional|2demayo": 2138,
	"divisionprofesional|sportivoameliano": 8505, "divisionprofesional|generalcaballero": 2137, "divisionprofesional|recoleta": 9733, "divisionprofesional|tacuary": 2152,
	# Liga 1
	"liga1|universitario": 6229, "liga1|alianzalima": 2158, "liga1|sportingcristal": 2194, "liga1|cusco": 6137,
	"liga1|melgar": 2181, "liga1|cienciano": 6154, "liga1|alianzaatletico": 2169, "liga1|sporthuancayo": 2174,
	"liga1|adt": 8601, "liga1|deportivogarcilaso": 7575, "liga1|juanpabloii": 7645, "liga1|atleticograu": 2168,
	"liga1|comerciantesunidos": 4300, "liga1|loschankas": 5223, "liga1|sportboys": 2192, "liga1|utc": 2200,
	"liga1|ayacucho": 6135, "liga1|alianzauniversidad": 6139,
	# EFL League One
	"eflleagueone|stockportcounty": 968, "eflleagueone|boltonwanderers": 824, "eflleagueone|cardiffcity": 841, "eflleagueone|huddersfieldtown": 900,
	"eflleagueone|lutontown": 916, "eflleagueone|plymouthargyle": 940, "eflleagueone|wycombewanderers": 995, "eflleagueone|wiganathletic": 987,
	"eflleagueone|reading": 946, "eflleagueone|barnsley": 813, "eflleagueone|blackpool": 821, "eflleagueone|lincolncity": 914,
	"eflleagueone|stevenage": 967, "eflleagueone|mansfieldtown": 921, "eflleagueone|peterboroughutd": 939, "eflleagueone|leytonorient": 913,
	"eflleagueone|rotherhamunited": 949, "eflleagueone|burtonalbion": 836, "eflleagueone|bradfordcity": 827, "eflleagueone|doncasterrovers": 860,
	"eflleagueone|northampton": 930, "eflleagueone|exetercity": 869, "eflleagueone|wimbledon": 805, "eflleagueone|portvale": 941,
	# EFL League Two
	"eflleaguetwo|chesterfield": 848, "eflleaguetwo|walsall": 980, "eflleaguetwo|nottscounty": 934, "eflleaguetwo|mkdons": 926,
	"eflleaguetwo|swindontown": 973, "eflleaguetwo|gillingham": 880, "eflleaguetwo|bromley": 833, "eflleaguetwo|salfordcity": 5197,
	"eflleaguetwo|grimsby": 883, "eflleaguetwo|colchester": 851, "eflleaguetwo|crewealexandra": 855, "eflleaguetwo|fleetwood": 875,
	"eflleaguetwo|cambridgeutd": 840, "eflleaguetwo|bristolrovers": 832, "eflleaguetwo|shrewsbury": 956, "eflleaguetwo|tranmererovers": 978,
	"eflleaguetwo|accrington": 806, "eflleaguetwo|barrow": 814, "eflleaguetwo|harrogate": 887, "eflleaguetwo|cheltenham": 846,
	"eflleaguetwo|newportcounty": 929, "eflleaguetwo|crawley": 854, "eflleaguetwo|oldhamathletic": 936, "eflleaguetwo|barnet": 812,
	# National League
	"nationalleague|yorkcity": 9273, "nationalleague|forestgreen": 876, "nationalleague|southend": 960, "nationalleague|rochdale": 948,
	"nationalleague|carlisle": 842, "nationalleague|scunthorpeunited": 953, "nationalleague|boston": 825, "nationalleague|hartlepool": 889,
	"nationalleague|suttonunited": 971, "nationalleague|solihull": 958, "nationalleague|eastleigh": 865, "nationalleague|aldershot": 807,
	"nationalleague|altrincham": 809, "nationalleague|yeovil": 996, "nationalleague|woking": 989, "nationalleague|braintree": 828,
	"nationalleague|halifax": 870, "nationalleague|gateshead": 879, "nationalleague|tamworth": 974, "nationalleague|wealdstone": 4333,
	"nationalleague|morecambe": 927, "nationalleague|truro": 975, "nationalleague|brackley": 826, "nationalleague|borehamwood": 3444,
	# 3. Liga
	"3liga|energiecottbus": 1225, "3liga|msvduisburg": 1250, "3liga|1860munchen": 1277, "3liga|hansarostock": 1241,
	"3liga|waldhofmannheim": 1266, "3liga|wehenwiesbaden": 1267, "3liga|viktoriakoln": 6005, "3liga|rotweissessen": 1253,
	"3liga|ingolstadt": 1228, "3liga|saarbrucken": 1206, "3liga|osnabruck": 1285, "3liga|verl": 1258,
	"3liga|alemanniaaachen": 1209, "3liga|ulm": 9887, "3liga|jahnregensburg": 1259, "3liga|erzgebirgeaue": 1226,
	"3liga|hoffenheimii": 50079, "3liga|havelse": 6716, "3liga|schweinfurt": 6587, "3liga|stuttgartii": 1283,
	# Eerste Divisie
	"eerstedivisie|willemii": 2005, "eerstedivisie|almerecity": 1973, "eerstedivisie|rkcwaalwijk": 1992, "eerstedivisie|cambuur": 1995,
	"eerstedivisie|adodenhaag": 1960, "eerstedivisie|degraafschap": 1966, "eerstedivisie|roda": 1993, "eerstedivisie|emmen": 1970,
	"eerstedivisie|vitesse": 2004, "eerstedivisie|dordrecht": 1968, "eerstedivisie|denbosch": 1967, "eerstedivisie|mvvmaastricht": 1987,
	"eerstedivisie|helmondsport": 1983, "eerstedivisie|vvvvenlo": 2003, "eerstedivisie|jongpsv": 4196, "eerstedivisie|jongajax": 4117,
	"eerstedivisie|jongaz": 5471, "eerstedivisie|jongutrecht": 6049, "eerstedivisie|eindhoven": 1969, "eerstedivisie|toposs": 1999,
	# Challenger Pro League
	"challengerproleague|beerschot": 287, "challengerproleague|kortrijk": 294, "challengerproleague|lommel": 299, "challengerproleague|rwdm": 6019,
	"challengerproleague|patroeisden": 6023, "challengerproleague|lierse": 300, "challengerproleague|beveren": 310, "challengerproleague|rfcseraing": 6021,
	"challengerproleague|francsborains": 6742, "challengerproleague|rscafutures": 7612, "challengerproleague|jonggenk": 7613, "challengerproleague|kaseupen": 316,
	"challengerproleague|olympiccharleroi": 301, "challengerproleague|lokeren": 314, "challengerproleague|kaagentii": 50087,
	# TFF 1. Lig
	"tff1lig|rizespor": 3216, "tff1lig|erzurumspor": 3155, "tff1lig|amed": 5610, "tff1lig|esenlererokspor": 9159,
	"tff1lig|bodrumspor": 5613, "tff1lig|pendikspor": 3200, "tff1lig|bandrmaspor": 5601, "tff1lig|igdir": 7625,
	"tff1lig|keciorengucu": 5608, "tff1lig|sivasspor": 3204, "tff1lig|hatayspor": 3172, "tff1lig|adanademirspor": 3129,
	"tff1lig|manisafk": 7073, "tff1lig|sakaryaspor": 3201, "tff1lig|umraniyespor": 5272, "tff1lig|boluspor": 3145,
	"tff1lig|serikbelediyespor": 6087, "tff1lig|saryer": 9149, "tff1lig|vanspor": 6080,
	# Liga Expansión MX
	"ligaexpansionmx|atlante": 1862, "ligaexpansionmx|leonesnegros": 6158, "ligaexpansionmx|celaya": 3756, "ligaexpansionmx|cancunfc": 6840,
	"ligaexpansionmx|tepatitlan": 6839, "ligaexpansionmx|tapatio": 6842, "ligaexpansionmx|mineroszacatecas": 6491, "ligaexpansionmx|venados": 6714,
	"ligaexpansionmx|tlaxcala": 6489, "ligaexpansionmx|dorados": 3758, "ligaexpansionmx|correcaminos": 3766, "ligaexpansionmx|atleticomorelia": 6838,
	"ligaexpansionmx|oaxaca": 4173, "ligaexpansionmx|jaibabrava": 5251, "ligaexpansionmx|irapuato": 3760, "ligaexpansionmx|durango": 6844,
	# Campeonato Primera B
	"campeonatoprimerab|univconcepcion": 533, "campeonatoprimerab|depconcepcion": 9034, "campeonatoprimerab|cobreloa": 510, "campeonatoprimerab|santiagowanderers": 530,
	"campeonatoprimerab|depantofagasta": 505, "campeonatoprimerab|temuco": 518, "campeonatoprimerab|rangers": 509, "campeonatoprimerab|atleticosanluis": 528,
	"campeonatoprimerab|usanfelipe": 536, "campeonatoprimerab|copiapo": 515, "campeonatoprimerab|curicounido": 513, "campeonatoprimerab|magallanes": 517,
	"campeonatoprimerab|santiagomorning": 529, "campeonatoprimerab|sanmarcos": 526, "campeonatoprimerab|deportesrecoleta": 6699, "campeonatoprimerab|santacruz": 6452,
	# Primera B
	"primerab|cucutadeportivo": 9211, "primerab|jaguarescordoba": 5045, "primerab|realcundinamarca": 6652, "primerab|huila": 4128,
	"primerab|patriotas": 3913, "primerab|bogota": 6456, "primerab|realcartagena": 572, "primerab|leones": 5555,
	"primerab|barranquilla": 6454, "primerab|orsomarso": 6458, "primerab|tigres": 5391, "primerab|interpalmira": 5046,
	"primerab|interbogota": 576, "primerab|deportesquindio": 579, "primerab|alianzavalledupar": 4192, "primerab|realsantander": 7080,
	# Serie A Equador
	"serieaequador|caindependiente": 4204, "serieaequador|lduquito": 775, "serieaequador|barcelonasc": 764, "serieaequador|emelec": 770,
	"serieaequador|aucas": 5047, "serieaequador|univcatolica": 4199, "serieaequador|depcuenca": 773, "serieaequador|elnacional": 765,
	"serieaequador|orense": 6129, "serieaequador|delfin": 5211, "serieaequador|universitario": 2201, "serieaequador|macara": 3916,
	"serieaequador|mushucruna": 4302, "serieaequador|libertad": 2143, "serieaequador|manta": 772, "serieaequador|vinotinto": 7576,
	# Primera Nacional
	"primeranacional|atleticotucuman": 117, "primeranacional|gimnasiam": 5115, "primeranacional|estudiantesrc": 6128, "primeranacional|deportivomoron": 5529,
	"primeranacional|atlanta": 132, "primeranacional|chacaritajuniors": 119, "primeranacional|quilmes": 136, "primeranacional|tigre": 116,
	"primeranacional|ferrocarriloeste": 128, "primeranacional|almirantebrown": 120, "primeranacional|gimnasiaj": 129, "primeranacional|allboys": 103,
	"primeranacional|agropecuario": 5528, "primeranacional|temperley": 4415, "primeranacional|defensoresbelgrano": 5617, "primeranacional|santelmo": 8910,
	"primeranacional|deportivomadryn": 6356, "primeranacional|colon": 9061, "primeranacional|racingcordoba": 8922, "primeranacional|chacoforever": 6350,
	# China League One
	"chinaleagueone|liaoningtieren": 552, "chinaleagueone|ctonglianglong": 3875, "chinaleagueone|guangzhoufc": 542, "chinaleagueone|yunnanyukun": 545,
	"chinaleagueone|nantongzhiyun": 6165, "chinaleagueone|shijiazhuanggongfu": 9429, "chinaleagueone|suzhoudongwu": 8582, "chinaleagueone|foshannanshi": 50055,
	"chinaleagueone|guangxipingguo": 9425, "chinaleagueone|qingdaoredlions": 7004, "chinaleagueone|shaanxiunion": 6163, "chinaleagueone|yanbianlongding": 568,
	"chinaleagueone|hubeiistar": 50097,
	# K League 2
	"kleague2|suwon": 3870, "kleague2|incheonunited": 1729, "kleague2|busanipark": 1722, "kleague2|jeonnamdragons": 6319,
	"kleague2|seongnam": 1733, "kleague2|bucheon": 4126, "kleague2|seouleland": 5067, "kleague2|gimpo": 6645,
	"kleague2|chungnamasan": 6320, "kleague2|hwaseong": 6494, "kleague2|ansangreeners": 3874, "kleague2|gyeongnam": 1728,
	"kleague2|cheonancity": 3862, "kleague2|chungbukcheongju": 6845,
	# UAE Pro League
	"uaeproleague|shababalahli": 3283, "uaeproleague|alain": 3284, "uaeproleague|alwahda": 3289, "uaeproleague|aljazira": 3285,
	"uaeproleague|sharjah": 3297, "uaeproleague|alwasl": 3290, "uaeproleague|alnasr": 3286, "uaeproleague|ajman": 3282,
	"uaeproleague|baniyas": 3294, "uaeproleague|ittihadkalba": 3891, "uaeproleague|khorfakkan": 6262, "uaeproleague|albataeh": 8338,
	"uaeproleague|dibbascc": 5106, "uaeproleague|aldhafra": 3291,
	# Persian Gulf Pro League
	"persiangulfproleague|persepolis": 3476, "persiangulfproleague|esteghlal": 3469, "persiangulfproleague|sepahan": 3481, "persiangulfproleague|tractor": 3484,
	"persiangulfproleague|foolad": 3471, "persiangulfproleague|golgohar": 6266, "persiangulfproleague|zobahan": 3485, "persiangulfproleague|mesrafsanjan": 6893,
	"persiangulfproleague|chadormalusc": 7633, "persiangulfproleague|estkhuzestan": 4029, "persiangulfproleague|malavan": 3472, "persiangulfproleague|aluminiumarak": 6894,
	"persiangulfproleague|kheybarkhorramabad": 8577, "persiangulfproleague|shamsazarqazvin": 8576, "persiangulfproleague|havadar": 8568, "persiangulfproleague|parsjonoubi": 5456,
	# Botola Pro
	"botolapro|wydad": 1959, "botolapro|rajacasablanca": 1950, "botolapro|berkane": 3572, "botolapro|farrabat": 1934,
	"botolapro|fusrabat": 1935, "botolapro|maghrebfes": 1943, "botolapro|hassania": 1936, "botolapro|difaaeljadida": 1933,
	"botolapro|safi": 1947, "botolapro|irtanger": 1939, "botolapro|uniontouarga": 8598, "botolapro|kawkabmarrakech": 1941,
	"botolapro|renaissance": 8408, "botolapro|tetouan": 1944, "botolapro|codmeknes": 10151, "botolapro|yacoubelmansour": 7748,
	# Girabola
	"girabola|petrodeluanda": 3525, "girabola|1odeagosto": 3527, "girabola|sagrada": 3530, "girabola|wiliete": 6269,
	"girabola|kabuscorp": 3524, "girabola|interclube": 3526, "girabola|huila": 4128, "girabola|lobito": 3538,
	"girabola|cdsaosalvador": 9516, "girabola|bravos": 3533, "girabola|libolo": 3523, "girabola|luandacity": 50116,
	"girabola|santarita": 5401, "girabola|isaacdebenguela": 9741, "girabola|sportingcabinda": 3853,
	# BRI Super League
	"brisuperleague|persibbandung": 3491, "brisuperleague|persijajakarta": 3495, "brisuperleague|borneo": 3499, "brisuperleague|baliunited": 5178,
	"brisuperleague|dewaunited": 8209, "brisuperleague|persebayasurabaya": 3878, "brisuperleague|psmmakassar": 4431, "brisuperleague|persitatangerang": 8206,
	"brisuperleague|arema": 3486, "brisuperleague|bhayangkara": 6273, "brisuperleague|psimyogyakarta": 8212, "brisuperleague|persissolo": 8221,
	"brisuperleague|psbsbiaknumfor": 8211, "brisuperleague|maduraunited": 3489, "brisuperleague|persikkediri": 4429, "brisuperleague|semenpadang": 3502,
	"brisuperleague|persijapjepara": 8220,
	# USL Championship
	"uslchampionship|louisvillecity": 4972, "uslchampionship|tampabayrowdies": 3328, "uslchampionship|sacramentorep": 4229, "uslchampionship|newmexicounited": 6537,
	"uslchampionship|charlestonbattery": 3302, "uslchampionship|switchbacks": 4971, "uslchampionship|sanantonio": 7648, "uslchampionship|pittsburghriver": 3319,
	"uslchampionship|northcarolina": 3301, "uslchampionship|phoenixrising": 4049, "uslchampionship|orangecounty": 3305, "uslchampionship|detroitcity": 6905,
	"uslchampionship|indyeleven": 4231, "uslchampionship|birminghamlegion": 6167, "uslchampionship|hartfordathletic": 6168, "uslchampionship|miami": 5188,
	"uslchampionship|oaklandroots": 6907, "uslchampionship|lasvegaslights": 5585, "uslchampionship|montereybay": 8670, "uslchampionship|rhodeisland": 7649,
	"uslchampionship|elpasolocomotive": 6536, "uslchampionship|loudoununited": 6169, "uslchampionship|lexington": 9729, "uslchampionship|tulsa": 4970,
	# Canadian Premier League
	"canadianpremierleague|forge": 6192, "canadianpremierleague|cavalry": 6191, "canadianpremierleague|atleticoottawa": 8048, "canadianpremierleague|pacific": 6193,
	"canadianpremierleague|vancouver": 8053, "canadianpremierleague|hfxwanderers": 6196,
	# Campeonato Paulista
	"campeonatopaulista|palmeiras": 422, "campeonatopaulista|corinthians": 428, "campeonatopaulista|saopaulo": 435, "campeonatopaulista|santos": 431,
	"campeonatopaulista|rbbragantino": 402, "campeonatopaulista|mirassol": 6976, "campeonatopaulista|pontepreta": 425, "campeonatopaulista|guarani": 418,
	"campeonatopaulista|novorizontino": 6654, "campeonatopaulista|botafogosp": 5385, "campeonatopaulista|ituano": 6704, "campeonatopaulista|veloclube": 50027,
	"campeonatopaulista|noroeste": 50028, "campeonatopaulista|capivariano": 50217, "campeonatopaulista|portuguesa": 8877, "campeonatopaulista|primavera": 50200,
	# Campeonato Carioca
	"campeonatocarioca|flamengo": 410, "campeonatocarioca|fluminense": 411, "campeonatocarioca|botafogo": 400, "campeonatocarioca|vascodagama": 436,
	"campeonatocarioca|voltaredonda": 5388, "campeonatocarioca|novaiguacu": 8896, "campeonatocarioca|madureira": 7014, "campeonatocarioca|bangu": 6709,
	"campeonatocarioca|boavista": 7013, "campeonatocarioca|portuguesarj": 426, "campeonatocarioca|marica": 50008, "campeonatocarioca|sampaiocorrearj": 7664,
	# Campeonato Mineiro
	"campeonatomineiro|atleticomg": 401, "campeonatomineiro|cruzeiro": 407, "campeonatomineiro|americamg": 397, "campeonatomineiro|athleticclub": 9180,
	"campeonatomineiro|tombense": 5387, "campeonatomineiro|uberlandia": 8538, "campeonatomineiro|pousoalegre": 8891, "campeonatomineiro|betim": 50029,
	"campeonatomineiro|urt": 8886, "campeonatomineiro|itabirito": 7677, "campeonatomineiro|democratagv": 9183, "campeonatomineiro|north": 50218,
	# Campeonato Gaúcho
	"campeonatogaucho|gremio": 414, "campeonatogaucho|internacional": 416, "campeonatogaucho|juventude": 5378, "campeonatogaucho|ypiranga": 5389,
	"campeonatogaucho|caxiasdosul": 7066, "campeonatogaucho|guaranydebage": 9184, "campeonatogaucho|saojosers": 7016, "campeonatogaucho|avenida": 6657,
	"campeonatogaucho|brasildepelotas": 7126, "campeonatogaucho|monsoon": 50031, "campeonatogaucho|saoluiz": 6972, "campeonatogaucho|novohamburgo": 9188,
	# Campeonato Paranaense
	"campeonatoparanaense|athleticopr": 398, "campeonatoparanaense|coritiba": 405, "campeonatoparanaense|operariopr": 5549, "campeonatoparanaense|londrina": 5215,
	"campeonatoparanaense|maringa": 9187, "campeonatoparanaense|cascavel": 7020, "campeonatoparanaense|azuriz": 8906, "campeonatoparanaense|cianorte": 6656,
	"campeonatoparanaense|andraus": 7679, "campeonatoparanaense|saojoseense": 7591, "campeonatoparanaense|fozdoiguacu": 9746,
	# Campeonato Catarinense
	"campeonatocatarinense|chapecoense": 4182, "campeonatocatarinense|criciuma": 406, "campeonatocatarinense|avai": 399, "campeonatocatarinense|figueirense": 409,
	"campeonatocatarinense|brusque": 6655, "campeonatocatarinense|joinville": 3908, "campeonatocatarinense|barra": 9179, "campeonatocatarinense|marciliodias": 8873,
	"campeonatocatarinense|concordia": 9182, "campeonatocatarinense|santacatarina": 50032, "campeonatocatarinense|hercilioluz": 9185,
}
# liga do jogo -> ID da competição no pacote
const COMP_IDS := {"brasileiraoseriea": 1410, "brasileiraoserieb": 1420, "ligaargentina": 830, "premierleague": 2270, "laliga": 6790, "serieaitalia": 3890, "bundesliga": 3150, "ligue1": 2980, "ligaportugal": 5610, "brasileiraoseriec": 1424, "eflchampionship": 2280, "laliga2": 6800, "serieb": 3900, "2bundesliga": 3160, "ligue2": 2990, "eredivisie": 5030, "jupilerproleague": 1190, "superlig": 7270, "saudiproleague": 6120, "majorleaguesoccer": 7500, "ligamxapertura": 10320, "chileanprimeradivision": 1670, "primeraa": 1770, "superleaguegreece": 3280, "ligaportugal2": 5620, "superliga": 2060, "allsvenskan": 6970, "kleague1": 4260, "chinesesuperleague": 1690, "divisionprofesional": 5410, "liga1": 5430, "eflleagueone": 2290, "eflleaguetwo": 2300, "nationalleague": 2310, "3liga": 3170, "eerstedivisie": 5040, "challengerproleague": 1200, "tff1lig": 7280, "ligaexpansionmx": 10410, "campeonatoprimerab": 1680, "primerab": 1775, "serieaequador": 2180, "primeranacional": 840, "chinaleagueone": 1700, "kleague2": 4263, "uaeproleague": 7480, "persiangulfproleague": 9200, "botolapro": 4950, "girabola": 9300, "brisuperleague": 9350, "uslchampionship": 7520, "canadianpremierleague": 1610, "campeonatopaulista": 10700, "campeonatocarioca": 10800, "campeonatomineiro": 91420, "campeonatogaucho": 91440, "campeonatoparanaense": 91450, "campeonatocatarinense": 91470}

static var info: Dictionary = {}
static var _tex: Dictionary = {}
static var _byname: Dictionary = {}
static var _players: PackedStringArray = PackedStringArray()
static var _ready: bool = false


static func norm(s: String) -> String:
	var t := s.to_lower()
	var map := {"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a", "é": "e", "ê": "e", "è": "e", "ë": "e", "í": "i", "ï": "i",
		"ó": "o", "ô": "o", "õ": "o", "ö": "o", "ú": "u", "ü": "u", "ç": "c", "ñ": "n"}
	for k in map.keys():
		t = t.replace(k, map[k])
	var out := ""
	for ch in t:
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
	return out


static func ensure() -> void:
	if _ready:
		return
	_ready = true
	info = {}
	_byname = {}
	var f := FileAccess.open(DIR + "pack.dat", FileAccess.READ)
	if f:
		var d = f.get_var()
		f.close()
		if typeof(d) == TYPE_DICTIONARY and d.has("clubs"):
			info = d
			for id in info["clubs"].keys():
				var k := norm(info["clubs"][id])
				if not _byname.has(k):
					_byname[k] = id


static func loaded() -> bool:
	ensure()
	return not info.is_empty()


## Importação antiga (sem as novidades da versão atual): importar de novo o pacote do jogo.
static func outdated() -> bool:
	ensure()
	return int(info.get("ver", 0)) < PACK_VER


## Placas de publicidade de uma pasta do datapack (ex.: "country-BRA", "competition-LIBERT").
static func adboards(key: String) -> Array:
	if _ads.has(key):
		return _ads[key]
	var out: Array = []
	var dir := DirAccess.open(DIR + "adboards/" + key)
	if dir == null:
		dir = DirAccess.open(BUNDLED + "adboards/" + key)
	if dir != null:
		var names: Array = []
		for fn0 in dir.get_files():
			var fn: String = fn0.trim_suffix(".import").trim_suffix(".remap")   # no APK aparecem os .import
			if fn.ends_with(".webp") and not (fn in names):
				names.append(fn)
		names.sort()
		for fn in names:
			var t := _load_tex(DIR + "adboards/" + key + "/" + fn, "ad_" + key + fn)
			if t != null:
				out.append(t)
	_ads[key] = out
	return out


## Placas para a partida: copa continental tem as dela; senão, as do país da liga.
static func adboards_for(cup_name: String, country: String) -> Array:
	var keys: Array = []
	if cup_name == "Copa Libertadores":
		keys.append("competition-LIBERT")
	if AD_COUNTRY.has(country):
		keys.append("country-" + str(AD_COUNTRY[country]))
	keys.append("generic")
	for k in keys:
		var a := adboards(k)
		if not a.is_empty():
			return a
	return []


static func find_source() -> String:
	for p in SOURCES:
		if FileAccess.file_exists(p):
			return p
	return ""


static func pack_id(li: int, ci: int) -> int:
	ensure()
	if li < 0 or li >= World.LEAGUES.size():
		return -1
	var lg: Dictionary = World.LEAGUES[li]
	if ci < 0 or ci >= lg["clubs"].size():
		return -1
	var cname: String = norm(lg["clubs"][ci][0])
	var key := norm(lg["name"]) + "|" + cname
	if CLUB_IDS.has(key):
		return CLUB_IDS[key]
	return int(_byname.get(cname, -1))


static func linked_count() -> Array:
	# [clubes do jogo ligados ao pacote, total de clubes do jogo]
	ensure()
	var ok := 0
	var total := 0
	for li in World.LEAGUES.size():
		for ci in World.LEAGUES[li]["clubs"].size():
			total += 1
			var id := pack_id(li, ci)
			if id >= 0 and info.has("clubs") and info["clubs"].has(id):
				ok += 1
	return [ok, total]


static func club_name(li: int, ci: int, fallback: String) -> String:
	var id := pack_id(li, ci)
	if info.has("clubs") and info["clubs"].has(id):
		return info["clubs"][id]
	return fallback


static func stadium(li: int, ci: int) -> String:
	var id := pack_id(li, ci)
	if info.has("stadiums") and info["stadiums"].has(id):
		return info["stadiums"][id]
	return ""


static func comp_id(li: int) -> int:
	if li < 0 or li >= World.LEAGUES.size():
		return -1
	return int(COMP_IDS.get(norm(World.LEAGUES[li]["name"]), -1))


static func comp_name(li: int, fallback: String) -> String:
	ensure()
	var id := comp_id(li)
	if info.has("comps") and info["comps"].has(id):
		return info["comps"][id]
	return fallback


static func _load_tex(path: String, key: String) -> Texture2D:
	if _tex.has(key):
		return _tex[key]
	var tex: Texture2D = null
	var bundled := path.replace(DIR, BUNDLED)
	if path.begins_with(DIR) and ResourceLoader.exists(bundled):
		tex = load(bundled) as Texture2D   # já importado pelo Godot: sem decodificar no celular
		_tex[key] = tex
		return tex
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load_webp_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			tex = ImageTexture.create_from_image(img)
	_tex[key] = tex
	return tex


static func logo_by_id(id: int) -> Texture2D:
	ensure()
	if info.is_empty() or id < 0:
		return null
	return _load_tex(DIR + "logos/%d.webp" % id, "c%d" % id)


static func logo(li: int, ci: int) -> Texture2D:
	return logo_by_id(pack_id(li, ci))


static func comp_logo_by_id(id: int) -> Texture2D:
	ensure()
	if info.is_empty() or id < 0:
		return null
	return _load_tex(DIR + "comps/%d.webp" % id, "k%d" % id)


static func players() -> PackedStringArray:
	ensure()
	if _players.is_empty() and FileAccess.file_exists(DIR + "players.dat"):
		var f := FileAccess.open(DIR + "players.dat", FileAccess.READ)
		var d = f.get_var()
		f.close()
		if typeof(d) == TYPE_PACKED_STRING_ARRAY:
			_players = d
	return _players


static func roster(names: Array) -> Array:
	ensure()
	if not info.has("rosters"):
		return []
	for n in names:
		var k := norm(str(n))
		if info["rosters"].has(k):
			return info["rosters"][k]
	return []


static func _table(zip: ZIPReader, path: String) -> Dictionary:
	var out := {}
	var txt := zip.read_file(path).get_string_from_utf8()
	for line in txt.split("\n", false):
		var parts := line.strip_edges().split(",", true, 1)
		if parts.size() == 2 and parts[0].is_valid_int():
			out[int(parts[0])] = parts[1].strip_edges()
	return out


static func _copy_images(zip: ZIPReader, files: PackedStringArray, folder: String, dest: String) -> int:
	DirAccess.make_dir_recursive_absolute(DIR + dest)
	var n := 0
	for f in files:
		if not f.begins_with(folder) or not f.ends_with(".webp"):
			continue
		var bytes := zip.read_file(f)
		if bytes.size() == 0:
			continue
		var out := FileAccess.open(DIR + dest + "/" + f.get_file(), FileAccess.WRITE)
		if out:
			out.store_buffer(bytes)
			out.close()
			n += 1
	return n


## Copia as placas mantendo a pasta de cada país/competição.
static func _copy_adboards(zip: ZIPReader, files: PackedStringArray, folder: String) -> int:
	var n := 0
	for f in files:
		if not f.begins_with(folder) or not f.ends_with(".webp"):
			continue
		var rel := f.substr(folder.length())
		var sub := rel.get_base_dir()
		if sub == "":
			continue
		DirAccess.make_dir_recursive_absolute(DIR + "adboards/" + sub)
		var bytes := zip.read_file(f)
		var out := FileAccess.open(DIR + "adboards/" + sub + "/" + rel.get_file(), FileAccess.WRITE)
		if out and bytes.size() > 0:
			out.store_buffer(bytes)
			out.close()
			n += 1
	return n


# Importa o pacote inteiro. Devolve "" se deu certo ou a mensagem de erro.
static func import_zip(path: String) -> String:
	var zip := ZIPReader.new()
	if zip.open(path) != OK:
		return "Não consegui abrir o arquivo. Ele precisa ser um .zip."
	var files := zip.get_files()
	var prefix := ""
	var found := false
	for f in files:
		if f.ends_with("clubs.csv") and not f.ends_with("unbundled_clubs.csv"):
			prefix = f.substr(0, f.length() - "clubs.csv".length())
			found = true
			break
	if not found:
		zip.close()
		return "Este zip não tem o arquivo clubs.csv. Não parece um datapack."
	var has := {}
	for f in files:
		has[f] = true
	remove()
	DirAccess.make_dir_recursive_absolute(DIR)
	var d := {"clubs": _table(zip, prefix + "clubs.csv"), "stadiums": {}, "comps": {}, "n_players": 0,
		"logos": 0, "comp_logos": 0, "author": "", "rosters": {}}
	if has.has(prefix + "unbundled_clubs.csv"):
		var extra := _table(zip, prefix + "unbundled_clubs.csv")
		for id in extra.keys():
			if not d["clubs"].has(id):
				d["clubs"][id] = extra[id]
	if has.has(prefix + "stadiums.csv"):
		d["stadiums"] = _table(zip, prefix + "stadiums.csv")
	if has.has(prefix + "competitions.csv"):
		d["comps"] = _table(zip, prefix + "competitions.csv")
	if has.has(prefix + "players.csv"):
		var names := PackedStringArray()
		for line in zip.read_file(prefix + "players.csv").get_string_from_utf8().split("\n", false):
			var parts := line.strip_edges().split(",", true, 1)
			if parts.size() == 2:
				names.append(parts[1].strip_edges())
		d["n_players"] = names.size()
		var pf := FileAccess.open(DIR + "players.dat", FileAccess.WRITE)
		if pf:
			pf.store_var(names)
			pf.close()
		_players = names
	if has.has(prefix + "settings.csv"):
		for line in zip.read_file(prefix + "settings.csv").get_string_from_utf8().split("\n", false):
			var kv := line.split(",", true, 1)
			if kv.size() == 2 and kv[0] == "DataPackAuthor":
				d["author"] = kv[1].strip_edges()
	if path == "res://datapack.zip" and DirAccess.dir_exists_absolute(BUNDLED + "logos"):
		# pacote do jogo: as imagens já vêm prontas no APK (importar uma a uma do zip levava ~1 min)
		d["logos"] = 1
		d["comp_logos"] = 1
		d["ads"] = 1
	else:
		d["logos"] = _copy_images(zip, files, prefix + "club_logos/", "logos")
		d["comp_logos"] = _copy_images(zip, files, prefix + "competition_logos/", "comps")
		d["ads"] = _copy_adboards(zip, files, prefix + "adboards/")
	d["ver"] = PACK_VER
	if has.has(prefix + "elencos.csv"):
		for line in zip.read_file(prefix + "elencos.csv").get_string_from_utf8().split("\n", false):
			var sep := ";" if line.contains(";") else ","
			var p := line.strip_edges().split(sep)
			if p.size() < 5 or not p[3].strip_edges().is_valid_int():
				continue
			var pos := p[2].strip_edges().to_upper()
			if not (pos in Game.POS_ORDER):
				pos = "MEI"
			var key := norm(p[0])
			if not d["rosters"].has(key):
				d["rosters"][key] = []
			d["rosters"][key].append([p[1].strip_edges(), pos, clampi(int(p[3]), 15, 45), clampi(int(p[4]), 40, 99),
				p[5].strip_edges().to_upper() if p.size() > 5 and p[5].strip_edges() != "" else ""])
	zip.close()
	var f := FileAccess.open(DIR + "pack.dat", FileAccess.WRITE)
	if f == null:
		return "Não consegui salvar o datapack no aparelho."
	f.store_var(d)
	f.close()
	_ready = false
	ensure()
	return ""


static func remove() -> void:
	for sub in ["logos", "comps"]:
		var dir := DirAccess.open(DIR + sub)
		if dir:
			for f in dir.get_files():
				dir.remove(f)
	var ad := DirAccess.open(DIR + "adboards")
	if ad:
		for sub in ad.get_directories():
			var sd := DirAccess.open(DIR + "adboards/" + sub)
			if sd:
				for f in sd.get_files():
					sd.remove(f)
			ad.remove(sub)
	var root := DirAccess.open(DIR)
	if root:
		for f in ["pack.dat", "players.dat", "logos", "comps", "adboards"]:
			root.remove(f)
	_ads = {}
	_tex = {}
	info = {}
	_byname = {}
	_players = PackedStringArray()
	_tex.clear()
	_ready = true
