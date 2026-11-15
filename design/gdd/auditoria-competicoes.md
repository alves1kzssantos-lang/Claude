# Auditoria das competições: Craque Manager, temporada 2026

Data: 14/11/2026. Só leitura: nenhum arquivo do jogo foi alterado.
Arquivos lidos: `src/world_data.gd` (LEAGUES, CUPS), `src/datapack.gd` (CLUB_IDS), `src/cups.gd` (build_season, ensure_draw), `/tmp/dpk/clubs.csv`.

## Como ler

- **Formato:** "trocar X por Y (id N)". O id é a linha `id,nome` em `/tmp/dpk/clubs.csv`.
- **Duas listas para corrigir:** `world_data.gd` (nome, sigla, cores, força) e `datapack.gd` → `CLUB_IDS` (o id do escudo). Muitos dos times "nada a ver" que o usuário viu vêm do **CLUB_IDS errado**: o nome está certo no jogo, mas o escudo e o nome mostrados são de outro clube.
- **Confiança:**
  - **[C]** = confirmado pelo título da fonte, ou é um fato do próprio código ou do datapack.
  - **[P]** = provável, vem do meu conhecimento (que vai até jun/2026). A busca só mostrou títulos e links, não o texto das matérias.
  - **[V]** = verificar antes de mudar.
- **Temporada:** a carreira começa em 07/01/2026. Por isso o jogo usa o Brasil/Sul-América de **2026** e a Europa de **2025/26**, a temporada que está rolando em janeiro de 2026. A Europa confere com 2025/26. Atualizar a Europa para 2026/27 é **decisão do usuário** (ver o fim do documento).

---

## 0. Problemas de regra (código), causa mais provável dos "times nada a ver"

1. **[C] Copa com menos times que o `size` perde times sem jogar.** `ensure_draw` emparelha `alive[i], alive[i+1]`. Com número ímpar, o último clube some sem jogar. Os nomes das fases também saem errados ("Oitavas" com 5 jogos). Isso acontece na **Copa do Nordeste** (ver 3.2).
   Correção: completar a copa até o `size` ou reduzir o `size`. Também vale avisar com `push_warning` quando `teams.size()` não for potência de 2.
2. **[C] Em ligas que não são a do jogador, a copa pega os N primeiros da *ordem do array*, não os classificados de verdade.** Para o clube do jogador, na 1ª temporada, conta a *força*. Por isso entram, por exemplo, River na Libertadores, Milan e Leipzig na Champions, e Porto e Feyenoord no lugar de Sporting e Ajax.
   Correção (dados): adicionar em cada copa um campo `"seed_2026": [nomes]` com os classificados reais, usado na 1ª temporada. Nas seguintes, usar o ranking da liga do jogador e, nas outras ligas, um sorteio ponderado pela força. Hoje os mesmos clubes se repetem todo ano.
3. **[C] O filtro `"only"` compara o nome *bruto* do world_data dos clubes convidados** (`_in_only(only, info[0], info[0])`). "Sport" ≠ "Sport Recife", então o Sport só entra na Copa do Nordeste se o jogador for da Série B.
   Correção: aceitar os dois nomes na lista `only` ou comparar também com `DataPack.club_name`.
4. **[C] Siglas repetidas no mesmo país:** São Bernardo `SAO` = São Paulo `SAO`. Trocar a do São Bernardo por `SBE`.

---

## 1. Brasil

### 1.1 Brasileirão Série A 2026: composição correta [C]
A lista confere: caíram Ceará, Fortaleza, Juventude e Sport. Subiram Coritiba, Athletico-PR, Chapecoense e Remo. Os IDs do CLUB_IDS estão certos.
Fontes: [Goal: quem subiu](https://www.goal.com/br/listas/times-serie-b-2025-que-subiram-jogar-serie-a-brasileirao-2026/blt8285932d581500a0), [Diário do Nordeste: Ceará e Fortaleza rebaixados](https://diariodonordeste.verdesmares.com.br/jogada/ceara-e-fortaleza-sao-rebaixados-para-serie-b-apos-derrotas-em-ultimo-jogo-do-brasileirao-de-2025-1.3716427)

Força fora da realidade [P]:
- Mirassol: 72 → **76** (4º colocado de 2025, na Libertadores 2026).
- Internacional: 76 → **74** (brigou contra a queda em 2025; [InfoMoney](https://www.infomoney.com.br/?p=3131594)).

### 1.2 Série B 2026: composição bate com a minha referência [P], com um ponto a verificar [V]
- **[V]** O título da CBF diz "[Título do Maringá encerra última Série C com 20 clubes](https://www.cbf.com.br/futebol-brasileiro/noticias/campeonato-brasileiro-serie-c/a/titulo-do-maringa-encerra-ultima-serie-c-com-20-clubes)". Se o Maringá foi campeão da Série C 2025, ele **subiu para a Série B 2026** e um dos quatro (Ponte Preta, Londrina, São Bernardo, Náutico) não subiu.
  Conferir na [lista da Série B 2026 (TNH1)](https://www.tnh1.com.br/noticia/nid/serie-b-2026-tem-seus-20-participantes-definidos/). Se for o caso: trocar o clube errado por **Maringá (CLUB_IDS 9187)** na Série B e tirar o Maringá da Série C.
- Sigla: São Bernardo `SAO` → `SBE`.

### 1.3 Série C 2026: faltam clubes [C] / [P]
Subiram da Série D 2025: **Barra-SC** (campeão) e **Santa Cruz** (vice) [C]. Também **Maranhão** e **Inter de Limeira** [P]. Só o Inter de Limeira está no jogo.
Fontes: [Band: Barra campeão sobre o Santa Cruz](https://www.band.com.br/esportes/barra-campeao-serie-d-2025-santa-cruz-202510042011), [Agência Brasil](https://agenciabrasil.ebc.com.br/esportes/noticia/2025-10/barra-segura-empate-com-santa-cruz-e-conquista-titulo-da-serie-d), [Diário de Pernambuco: adversários do Santa Cruz na Série C](https://www.diariodepernambuco.com.br/esportes-dp/santa-cruz/2025/11/11701258-veja-adversarios-do-santa-cruz-na-serie-c-do-brasileiro.html), [Band: os 20 da Série C 2026](https://www.band.com.br/esportes/brasileirao-serie-c-de-2026-tem-os-20-clubes-definidos-veja-a-lista-202511241122), [Itatiaia](https://www.itatiaia.com.br/esportes/futebol/futebol-nacional/brasileirao-serie-c/veja-todos-os-clubes-que-disputarao-a-serie-c-do-campeonato-brasileiro-em-2026/), [Bahia Notícias: rebaixados da Série C 2025](https://www.bahianoticias.com.br/esportes/noticia/80063-serie-c-define-classificados-rebaixados-e-grupos-do-quadrangular-veja-como-ficou)

- Acrescentar **Santa Cruz (id 429)** [C], **Barra (id 9179)** [C] e **Maranhão (id 7587)** [P].
- Para manter 20 clubes, sair os rebaixados da Série C 2025 que ainda estão na lista. A minha referência [P] aponta **CSA (5381)** e **Tombense (5387)**. O terceiro fica entre **Ypiranga (5389)** e **Itabaiana (6974)** [V]. O Retrô também caiu e já não está no jogo.
- Se o Maringá subiu (ver 1.2), ele sai da Série C e entra o clube que desceu no lugar dele.
- Ordem do array: Amazonas (64) e Ferroviária (63) estão no fim. Como as copas pegam pela ordem do array, ordenar a lista por força.

### 1.4 Estaduais: escudos de clubes de outro país [C]
- Paulista: trocar `"Guaraní"` por **"Guarani"** e o CLUB_IDS `campeonatopaulista|guarani` de 2142 (Guaraní do **Paraguai**) por **418**.
- Paulista: CLUB_IDS `campeonatopaulista|santos` de 6155 (um "Santos" do bloco do **Peru**) por **431**.
- Carioca: CLUB_IDS `campeonatocarioca|boavista` de 2333 (Boavista de **Portugal**) por **7013 (Boavista-RJ)**.

---

## 2. Liga Argentina [C] / [P]
Em 2026 a Liga Profesional tem **30 clubes**, com Apertura e Clausura ([Canal26: os 30 do Apertura 2026](https://www.canal26.com/deportes/2025/12/01/de-donde-son-los-30-equipos-que-jugaran-el-torneo-apertura-2026-el-impresionante-record-de-cordoba/), [ESPN: grupos 2026](https://espndeportes.espn.com/futbol/argentina/nota/_/id/16067782/los-grupos-para-la-liga-profesional-2026-torneo-apertura-y-clausura), [La Nación](https://www.lanacion.com.ar/deportes/futbol/liga-profesional-2026-cuando-empieza-el-futbol-argentino-y-como-se-juegan-el-apertura-y-clausura-nid05012026)). O jogo tem 20.

**Erros:**
- **[P] Rebaixados em 2025:** Godoy Cruz e San Martín (SJ). Trocar **Godoy Cruz por Platense (id 113)**, campeão do Apertura 2025 e na Libertadores 2026.
- **[C] Tigre repetido** na Liga Argentina e na Primera Nacional, com o mesmo id 116. Tirar da Primera Nacional.
- **[P] Na Primera Nacional, mas jogam a 1ª divisão:** Atlético Tucumán (117), Gimnasia (M) (5115) e Estudiantes (RC) (6128).
  - Na Primera Nacional, trocar por **Godoy Cruz (131)**, **San Martín (SJ) (139)**, **San Martín (T) (140)** e mais um clube do Ascenso para repor o Tigre.
  - CLUB_IDS `primeranacional|colon` = 9061 [V]. O Colón original do datapack é **124**.

**Decisão do usuário:**
- **(a) Manter 20:** além de Godoy Cruz → Platense, trocar os dois mais fracos (Unión, Gimnasia LP) por **Independiente Rivadavia (133)**, campeão da Copa Argentina 2025 [P], e **Argentinos/Instituto** conforme preferir.
- **(b) Ir para 30, recomendado se o calendário aguentar:** acrescentar Platense 113, Instituto 134, Indep. Rivadavia 133, Aldosivi 102, Atlético Tucumán 117, Barracas Central 6123, C. Córdoba SdE 5135, Deportivo Riestra 5534, Gimnasia (M) 5115, Estudiantes (RC) 6128 e Sarmiento (Junín). O Sarmiento de Junín não foi achado no trecho lido; não confundir com "Sarmiento (R)" 6352 nem "Sarmiento (LB)" 7688 [V].

---

## 3. Copas brasileiras

### 3.1 Copa do Brasil
- `take [20,8,4]` soma 32: ok.
- Da Série C entram os 4 primeiros do array (Paysandu, Guarani, Figueirense, Brusque). Isso é aceitável depois de ordenar a Série C por força.

### 3.2 Copa do Nordeste: chave quebrada [C]
Contagem com o filtro atual:
- Série A: Bahia e Vitória.
- Série B: Fortaleza, Ceará, CRB e Náutico. O Sport cai fora pelo nome.
- Série C: Botafogo-PB, Confiança, ABC, CSA e Itabaiana.

São **11 clubes para `size` 16**: a chave fica ímpar e um time some sem jogar (regra 0.1).
- Na lista `only`, trocar "Sport Recife" por **"Sport" e "Sport Recife"** (os dois).
- Com a Série C atualizada, entram **Santa Cruz (429)** e **Maranhão (7587)**, que já são aceitos pelo nome. Ainda assim fica em cerca de 13 a 14 clubes.
- Decisão: **(a) `size` 8**, só os mais fortes. Ou **(b)** manter 16 e criar um "pool" de convidados nordestinos fora da Série C, todos com id no datapack: Ferroviário 6329, Treze 6330, América-RN 6713, Sampaio Corrêa 4294, Juazeirense 5548, Altos 6705, ASA 6271, Sergipe 7032, Atlético-CE 7021. O "only" já cita vários deles, mas nenhum existe em liga alguma. Recomendo **(b)**.
- [Fonte: classificados da Série C 2026 e rebaixados (Diário do Nordeste)](https://diariodonordeste.verdesmares.com.br/opiniao/colunistas/vladimir-marques/quatro-clubes-conquistam-acesso-para-a-serie-c-de-2026-veja-quem-subiu-1.3688470)

### 3.3 Copa Verde
Com o filtro saem 8 clubes (Remo, Goiás, Atlético-GO, Vila Nova, Cuiabá, Paysandu, Anápolis, Amazonas) para `size` 8: ok.
- [V] Se o Anápolis cair ou for trocado na Série C, a chave fica com 7. Então incluir no pool Brasiliense 6653, Manaus 6658, Aparecidense 6969, Luverdense 4293 e União Rondonópolis 6975, todos com id no datapack.

---

## 4. Libertadores 2026
Fontes: [Netflu: definidos todos os classificados](https://www.netflu.com.br/definidos-todos-os-classificados-para-libertadores-de-2026/), [Band](https://www.band.com.br/esportes/futebol/noticias/times-classificados-libertadores-2026-202512212158), [Diário do Nordeste](https://diariodonordeste.verdesmares.com.br/opiniao/colunistas/vladimir-marques/tudo-definido-veja-todos-os-classificados-para-a-libertadores-2026-1.3721409), [Itatiaia](https://www.itatiaia.com.br/esportes/futebol/futebol-internacional/copa-libertadores/brasileiros-de-olho-veja-todos-os-clubes-classificados-a-copa-libertadores-de-2026/).

**Hoje:** pela ordem do array entram Flamengo, Palmeiras, Cruzeiro, **Corinthians** e **Botafogo**, e da Argentina **River**, Boca, **Racing** e Estudiantes.

**Erros:**
- **[P]** Fica de fora o **Mirassol (6976)**, que se classificou direto. O **River não se classificou** para 2026 (foi para a Sul-Americana).
- **[C] Escudos errados de times de outros países:**
  - Paraguai: `divisionprofesional|nacional` 2350 (Nacional da **Madeira**) → **2144 (Club Nacional)**.
  - Equador: `serieaequador|libertad` 2143 (Libertad do **Paraguai**) → procurar o Libertad FC equatoriano [V].
  - Equador: `serieaequador|universitario` 2201 (Universitario do **Peru**) → procurar o Técnico Universitario [V].
  - Peru: `liga1|universitario` 6229 (fica no bloco do Panamá) → **2201** [P].
- **[C] Faltam Uruguai, Bolívia e Venezuela.** O datapack tem Peñarol 3332, Nacional 3336, Bolívar 338, Always Ready 6142, Caracas 3365 e outros. Sugestão: criar uma liga do Uruguai.

**Propostas:**
- **Novo `take` (16 vagas, perfil típico das oitavas)**, na ordem de region [BRA, ARG, CHI, COL, EQU, PAR, PER]: **[6, 4, 1, 1, 2, 1, 1]**.
- **`seed_2026` (fase de grupos real, só clubes que estão no jogo):**
  - Brasil: Flamengo 410, Palmeiras 422, Cruzeiro 407, **Mirassol 6976**, **Fluminense 411**, Corinthians 428 (campeão da Copa do Brasil).
  - Argentina: **Estudiantes 127, Boca 106, Rosario Central 115, Lanús 110** (campeão da Sul-Americana). Platense 113, Argentinos 99 e Indep. Rivadavia 133 também se classificaram [P].
  - Equador: CA Independiente 4204 e LDU 775. Chile: Coquimbo Unido 512 (campeão de 2025) [P]. Colômbia, Paraguai e Peru: o campeão nacional de 2025 [V]. Peru [P]: Universitario.

---

## 5. Europa (2025/26)

### 5.1 Ligas: a composição está certa nas oito [C]
Premier League (Leeds, Burnley e Sunderland subiram), LaLiga (Levante, Elche e Oviedo), Serie A (Sassuolo, Pisa e Cremonese), Bundesliga (Köln e HSV), Ligue 1 (Lorient, Paris FC e Metz), Liga Portugal (Alverca e Tondela), Eredivisie (Excelsior, Telstar e Volendam). Nenhum clube na divisão errada.

Força fora da realidade em 2025/26 [P]:
- Wolverhampton: 76 → **73** (lanterna).
- Sunderland: 74 → **76**.
- West Ham: 78 → **75**.
- Como: 75 → **79**.
- Fiorentina: 79 → **75** (zona de rebaixamento no 1º turno).
- Villarreal: 80 → **82**.
- Girona: 78 → **75**.

### 5.2 Champions League 2025/26
Fase de liga real, só os clubes que estão no jogo:
- Inglaterra: Arsenal, Liverpool, Man City, Chelsea, **Newcastle**, Tottenham.
- Espanha: Real, Barça, Atlético, Athletic, Villarreal.
- Itália: Inter, Napoli, **Atalanta**, Juventus.
- Alemanha: Bayern, Leverkusen, Dortmund, **Eintracht Frankfurt**.
- França: PSG, Marseille, Monaco.
- Portugal: Benfica, **Sporting**.
- Holanda: PSV, **Ajax**.
- Bélgica: Club Brugge, Union SG.
- Turquia: Galatasaray.
- Grécia: **Olympiacos**.
- Dinamarca: **Copenhagen**.

Também estiveram na fase de liga, mas não existem no jogo: Slavia Praha, Bodø/Glimt, Qarabağ, Kairat e Pafos.

**Hoje, pela ordem do array, entram:** Man Utd (por empate de força), **Milan, Roma**, **Leipzig**, **Porto, Braga**, **Feyenoord** e **Fenerbahçe**. Nenhum deles jogou a fase de liga [P].

**Propostas:**
- **Novo region/take (32):** Premier 6, LaLiga 5, Serie A 4, Bundesliga 4, Ligue 1 3, Liga Portugal 2, Eredivisie 2, Jupiler 2, Süper Lig 2, **Super League Greece 1**, **Superliga 1**.
- **`seed_2026`:** a lista acima, com Fenerbahçe como 32º (caiu no play-off). IDs: Newcastle 928, Tottenham 977, Atalanta 1581, Juventus 1597, Frankfurt 1224, Sporting 2364, Ajax 1964, Olympiacos 1345, Copenhagen 724.
- Até existir o `seed`, dá para **reordenar os arrays** (Atalanta antes de Milan, Frankfurt antes de Leipzig, Sporting antes de Porto, Ajax antes de Feyenoord).

### 5.3 FA Cup
`take [16,8,4,2,2]` soma 32: ok. Só registro que entram sempre os mesmos clubes, por causa da regra 0.2.

---

## 6. Américas e Ásia

### 6.1 MLS 2026 (30 clubes; o jogo tem 28) [C]
- Acrescentar **New York RB (3318)** e **SJ Earthquakes (3325)**.
- Trocar o CLUB_IDS `majorleaguesoccer|vancouver` de 8053 (o mesmo id do **Vancouver FC da CPL**) por **503 (Vancouver WC)**. O nome no world_data passa a ser "Vancouver WC".
- Canadian Championship: a lista `only` usa "Forge FC", "Cavalry FC", "Pacific FC" e "Vancouver Whitecaps", mas as ligas usam "Forge", "Cavalry", "Pacific" e "Vancouver". Por isso esses clubes ficam de fora. Trocar pelos nomes das ligas. York United passou a se chamar **Inter Toronto (490)** [P].
- Força [P]:
  - LA Galaxy: 76 → **70** (temporada 2025 ruim).
  - Vancouver: 70 → **75** (finalista da MLS Cup 2025).
  - San Diego: 67 → **73** (1º do Oeste em 2025).
  - Inter Miami: 76 → **77** (campeão).

### 6.2 Liga MX (18 clubes; o jogo tem 16) [C]
- Trocar o CLUB_IDS `ligamxapertura|tigres` de 5391 (o "Tigres" que também está na Primera B da **Colômbia**) por **1873 (Tigres UANL)**.
- Acrescentar **Atlético San Luis (1879)**. Hoje ele está por engano na **Primera B do Chile** (ver 6.4).
- Acrescentar **Mazatlán** [P]. Não achei o id no trecho lido [V]. Em 2026/27 a vaga passa para o **Atlante (1862)** [V].
- Força: Toluca 74 → **78** (bicampeão em 2025).

### 6.3 Saudi Pro League 2025/26 [C]
Os 18 conferem. Força dentro do razoável.

### 6.4 Outros erros de datapack e repetições achados no caminho [C]
- **Chile 1ª:** CLUB_IDS `chileanprimeradivision|union` de 143 (Unión **Santa Fe, Argentina**) por **534 (Unión Española)**.
- **Chile Primera B:**
  - `rangers` de 86 (Rànger's, **Andorra**) por **509 (Rangers de Talca)**.
  - `atleticosanluis` de 1879 (**México**) por **528 (San Luis Quillota)**, renomeando para "San Luis Quillota".
  - `santacruz` de 429 (Santa Cruz **PE, Brasil**) por **6452 (Dep. Santa Cruz)**.
- **Colômbia 1ª:**
  - `primeraa|independiente` de 109 (Independiente **da Argentina**) por **585 (Indep. Medellín)**.
  - `primeraa|alianza` de 793 (Alianza de **El Salvador**) por **4192 (Alianza Valledupar)**. Tirar da Primera B o "Alianza Valledupar", que fica repetido.
- **Colômbia Primera B:**
  - "Inter Bogotá" está repetido na 1ª e na B (id 576). Tirar da B.
  - "Tigres" 5391 está na B e na Liga MX (resolvido em 6.2).
- **Angola:** `girabola|huila` 4128 é o Huila **colombiano** (o mesmo id da Primera B). Procurar o Desportivo da Huíla [V].
- **Turquia:** "Rizespor" está na Süper Lig e na TFF 1. Lig com o mesmo id 3216. Tirar da TFF 1. Lig.
- **China:** "Yunnan Yukun" está na CSL e na League One (id 545). Tirar de uma das duas.
- **Coreia:** "Suwon" está na K1 e na K2 com o mesmo id 3870. Um é o Suwon FC e o outro o Suwon Samsung [V].
- **MLS × CPL:** "Vancouver" com o id 8053 nas duas (resolvido em 6.1).

---

## 7. Prioridades

| Prioridade | Correção | Impacto |
|---|---|---|
| 1 | CLUB_IDS com clube de outro país: Liga MX Tigres, MLS Vancouver, Colômbia Independiente e Alianza, Chile Unión, Rangers, San Luis e Santa Cruz, Paraguai Nacional, Paulista Guaraní e Santos, Carioca Boavista | É exatamente o "time nada a ver" na tela |
| 2 | Libertadores/Champions: `seed_2026` + novo `take` | River, Milan, Leipzig, Porto e Feyenoord deixam de entrar |
| 3 | Copa do Nordeste: chave ímpar + nome do Sport | Time some da copa sem jogar |
| 4 | Série C: entram Santa Cruz e Barra (+ Maranhão); conferir o Maringá na Série B | Composição real de 2026 |
| 5 | Argentina: Godoy Cruz → Platense; tirar Tigre, Atlético Tucumán, Gimnasia (M) e Estudiantes (RC) da Primera Nacional | Divisão errada e repetição |
| 6 | MLS +2, Liga MX +2, ajustes de força | Fidelidade |

## Decisões em aberto (usuário)
1. Argentina com 20 ou 30 clubes.
2. Copa do Nordeste com `size` 8 ou com pool de convidados (recomendado).
3. Europa fica em 2025/26 (coerente com o início em jan/2026) ou passa para 2026/27.
4. Criar uma liga do Uruguai (Peñarol 3332, Nacional 3336) para a Libertadores.
