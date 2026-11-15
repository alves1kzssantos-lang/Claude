# Sprint WSC — 14/11/2026 (sprint de 1 dia, entrega hoje)

> Projeto: Craque Manager (Godot 4.5, GDScript, Compatibility, mobile deitado 1280x720)
> Produtor: producer · Pedido do usuário: 14/11/2026 · Prazo: hoje, zip entregue ao usuário.

## Objetivo

Deixar a partida e as copas com cara de **World Soccer Champs**: lance com visão
mais aberta (campo de cima, gol no topo), visual elegante com bordas
arredondadas, times e campeonatos corretos, copas com **ida e volta** onde a
competição real é assim, telas de copa no estilo WSC e **animação de levantar o
troféu** ao ser campeão. Tudo testado, com capturas, vídeo de prévia e zip.

## Regras do sprint (valem para todos)

1. **Um arquivo, um dono.** Só o dono listado edita o arquivo. Quem precisa de
   mudança em arquivo de outro pede ao dono (via coordenador). Revisores
   (S6, S9, S10) **não editam código**: devolvem achados ao dono.
2. **Números em dados.** Valores novos de câmera, tempo de animação, prêmios
   etc. vão para `assets/data/*.json` / `src/tuning.gd`, não fixos no código.
3. **Prova visual.** Toda história que muda algo visível só fecha com captura
   PNG retida em `production/qa/evidence/` (PNG, não JPG).
4. **Não mexer fora do pedido.** Nada de mudanças além do que o usuário pediu
   (ex.: não refazer o menu inicial, não mudar regras do árbitro).
5. Buffer: ~20% do dia reservado para correções da integração (bloco final).

## Mapa de arquivos (anti-conflito)

| Arquivo | Dono | Observação |
|---|---|---|
| `src/cups.gd` | S1 gameplay-programmer | API de ida e volta (`round_legs`, `tie_legs`, `aggregate`, `stage_results`) |
| `src/world_data.gd` | S1 gameplay-programmer | Único escritor; aplica as correções da auditoria S5 |
| `src/game.gd` | S1 gameplay-programmer | Calendário/temporada com jogos de ida e volta; evento "campeão" |
| `tests/integration/cups/test_cups_season.gd` | S1 gameplay-programmer | |
| `src/lance_view.gd`, `src/field_view.gd`, `src/pitch_view.gd`, `src/match_view.gd` | S2 godot-specialist | Câmera do lance (gol em cima) + otimização de desenho |
| `src/ball_physics.gd` | S2 godot-specialist | Só se a câmera exigir; regra da física não muda |
| `assets/data/match_tuning.json` | S2 godot-specialist | Chaves novas de câmera/zoom |
| `tests/integration/match/test_field_view.gd`, `tests/unit/physics/test_ball_physics.gd` | S2 godot-specialist | |
| `src/trophy_lift.gd` (novo) + cena/recursos novos do troféu | S3 technical-artist | Só arquivos novos |
| `src/comp_intro.gd`, `src/screens_hub.gd`, `src/screens_team.gd`, `src/ui.gd`, `src/crest.gd`, `src/main.gd` | S4 ui-programmer | Telas de copa WSC, estilo arredondado global, chamada do troféu |
| `tests/shots_cups.gd`/`.tscn`, `tests/shots_match.gd`/`.tscn` | S4 ui-programmer | Roteiros de captura |
| `design/gdd/competicoes.md` (novo), `assets/data/rosters_real.json` | S5 game-designer | Lista de correções para S1 aplicar em `world_data.gd` |
| (nenhum) | S6 art-director | Parecer visual devolvido ao coordenador |
| `assets/data/pro_career.json`, `assets/data/pro_life.json`, seção Economia de `design/gdd/carreira-jogador.md` | S7 economy-designer | `src/pro_career.gd` **não** muda hoje sem pedido ao coordenador |
| `assets/data/pro_social.json` | S8 writer | |
| (nenhum) | S9 godot-gdscript-specialist | Revisão; achados vão ao dono do arquivo |
| (nenhum) | S10 ux-designer | Revisão de fluxo; achados vão a S4 |
| `production/qa/plano-testes-wsc-2026-11-14.md` (novo), `tests/run_tests.gd`/`.tscn`, `tests/all_leagues.gd`, `tests/movie.gd`/`.tscn`, `tests/preview_pro.gd` | S11 qa-lead | Arnês de testes, vídeo de prévia |
| `design/audio/sons-wsc.md` (novo) | S12 sound-designer | Só especificação, sem áudio no jogo hoje |

**Pontos quentes de conflito:** `src/game.gd` (S1) e `src/main.gd` (S4) — o
evento "campeão" nasce em `game.gd` e a navegação para a tela/animação fica em
`main.gd`/`screens_hub.gd`. `src/ui.gd` (estilos) é do S4: S2 e S3 usam as
cores/estilos de lá, não criam cópias.

## Histórias

| ID | História | Dono | Prioridade | Estimativa | Depende de | Caminho crítico |
|---|---|---|---|---|---|---|
| S1 | Copas com ida e volta (onde a real é assim), agregado, pênaltis só no fim do 2º jogo, calendário e "Próxima partida" corretos | gameplay-programmer | P0 | 0,5 dia | S5 (lista de quais fases são ida e volta) | **Sim** |
| S2 | Câmera do lance WSC: campo visto de cima, gol do ataque no topo, visão mais aberta; otimização (menos redesenho por quadro) | godot-specialist | P0 | 0,5 dia | — | Não |
| S3 | Animação de levantar o troféu (cena reutilizável, cor/nome da copa por parâmetro, botão pular) | technical-artist | P0 | 0,5 dia | — | **Sim** |
| S4 | Telas de copa estilo WSC (chaveamento com ida/volta e agregado, fase atual, abertura com logo) + bordas arredondadas/visual elegante + chamada do troféu ao ser campeão | ui-programmer | P0 | 0,5–1 dia | S1 (API), S3 (API do troféu), S10 (achados) | **Sim** |
| S5 | Auditoria de times e campeonatos (participantes, formato, nº de fases, ida e volta, nomes/escudos) | game-designer | P0 | 0,25 dia | — | **Sim** (alimenta S1) |
| S6 | Revisão visual (partida, telas de copa, troféu) contra referência WSC | art-director | P1 | 0,25 dia | S2, S3, S4 com capturas | Não |
| S7 | Economia da carreira de jogador (salários, prêmios, compras, patrocínios coerentes) | economy-designer | P1 | 0,25 dia | — | Não |
| S8 | Textos da rede social (variedade, português correto, gatilhos de título/copa) | writer | P1 | 0,25 dia | — | Não |
| S9 | Revisão de código (erros, avisos, desempenho, tipagem) das mudanças S1–S4 | godot-gdscript-specialist | P1 | 0,25 dia | S1–S4 entregues | Não |
| S10 | Revisão de fluxos (de "Próxima partida" à copa, ao título, ao troféu e volta ao hub; toques no celular) | ux-designer | P1 | 0,25 dia | Rascunho de S4 | Não |
| S11 | Plano de testes + execução final (testes, capturas, vídeo de prévia) | qa-lead | P0 | 0,25 dia plano + 0,25 dia execução | Todas as P0 | **Sim** (fim) |
| S12 | Especificação de sons (apito, torcida, gol, troféu, toques de UI) | sound-designer | P2 | 0,25 dia | — | Não |

### Contratos entre histórias

- **S1 → S4 (API de ida e volta):** `Cups.round_legs(cup, r)`, `Cups.tie_legs(t)`,
  `Cups.aggregate(t, n)`, `Cups.stage_results(ci, stage)`, `Cups.my_tie(ci)`,
  mais um jeito de saber se o usuário foi campeão (sinal/flag em `game.gd`).
  S1 avisa o coordenador quando a assinatura estiver congelada; S4 não lê
  campos internos do dicionário fora dessa API.
- **S3 → S4 (API do troféu):** uma chamada única, por exemplo
  `TrophyLift.play(parent, cup_info, team_info, on_done)`, que roda sozinha,
  tem botão "Pular" e devolve o controle em `on_done`. S3 publica a assinatura
  antes de terminar o polimento para S4 integrar em paralelo.
- **S5 → S1:** lista de correções em `design/gdd/competicoes.md` (copa,
  fase, jogo único ou ida e volta, participantes). S1 aplica em `world_data.gd`.
- **S2 ↔ S4:** S2 usa estilos de `src/ui.gd`; se precisar de estilo novo, pede a S4.

## Critérios de pronto

**Gerais (toda história com código):**
- Projeto abre e roda sem erros nem avisos novos no console do Godot 4.5.1.
- `tests/run_tests.tscn` passa inteiro (headless).
- Capturas PNG retidas em `production/qa/evidence/` para cada tela tocada.
- Nenhum arquivo de outro dono editado.

**Por história:**
- **S1:** fases de ida e volta jogam 2 partidas (mando invertido); agregado
  decide; empate no agregado → pênaltis só ao fim do 2º jogo; final em jogo
  único quando a competição real é assim; calendário mostra os dois jogos;
  `test_cups_season.gd` cobre jogo único, ida e volta e pênaltis no agregado.
- **S2:** no lance o gol atacado fica em cima e o campo cabe com folga (visão
  aberta); toques/deslizes continuam acertando jogador e gol; sem queda
  perceptível de quadros no celular (medir FPS no desktop como referência e
  comparar antes/depois); `test_field_view.gd` passa.
- **S3:** animação completa (entrada, levantar, festa) em poucos segundos,
  configurável em dados; funciona para qualquer copa/liga; botão "Pular";
  captura de pelo menos 2 quadros-chave.
- **S4:** tela da copa mostra fases, confrontos com ida/volta e agregado,
  pênaltis, destaque do time do usuário; cantos arredondados e estilo único
  em todas as telas tocadas; ao ser campeão a animação do troféu abre e volta
  ao hub; capturas de chaveamento, confronto de ida e volta, final e troféu.
- **S5:** documento com cada copa/campeonato auditado (OK / corrigir) e
  correções aplicadas por S1; `tests/all_leagues.gd` roda sem erro.
- **S6/S9/S10:** parecer entregue; todo item "bloqueante" corrigido pelo dono
  ou explicitamente adiado pelo usuário.
- **S7:** valores em JSON, coerentes (nada que deixe o jogador rico em 1
  temporada nem quebrado sem saída); `test_pro_career.gd` passa.
- **S8:** textos sem erro de português, sem repetição óbvia; JSON válido.
- **S11:** plano escrito; execução final registrada (ver ordem abaixo).
- **S12:** documento de especificação de sons (sem implementação hoje).

## Riscos

| Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|
| 12 frentes em 1 dia — escopo grande demais para "pronto hoje" | Alta | Alto | Prioridades P0/P1/P2: se o tempo apertar, P2 (sons) e P1 sem achados bloqueantes ficam para depois; o zip sai com as P0 |
| Conflito de edição em `game.gd`/`main.gd`/`ui.gd` | Média | Alto | Mapa de donos acima; mudanças cruzadas só por pedido |
| API de ida e volta mudar depois que S4 integrou | Média | Alto | S1 congela assinatura cedo e avisa; S4 usa só a API |
| Ida e volta quebrar save/calendário de temporada já existente | Média | Alto | Teste de temporada completa em `test_cups_season.gd`; rodar `all_leagues` |
| Câmera nova desalinhar a área de toque (passe/chute errado) | Média | Alto | Conversão tela↔campo testada em `test_field_view.gd`; captura com pausa |
| "Otimização" sem medida vira só opinião | Média | Médio | Medir FPS/tempo de quadro antes e depois na mesma cena |
| Auditoria de times atrasar e travar S1 | Média | Médio | S5 entrega primeiro só a lista de formatos das copas (o que S1 precisa); nomes/escudos depois |
| Animação do troféu pesada no celular (renderer Compatibility) | Baixa | Médio | Desenho 2D/Tween simples, sem shader pesado; testar no Compatibility |
| Usuário não consegue rodar headless o vídeo de prévia | Baixa | Baixo | Vídeo gerado aqui com `--write-movie` e incluído na entrega |

## Ordem de integração e verificação final

1. **S5 (formatos das copas)** → entregar a S1.
2. **S1** congela API de ida e volta; **S3** publica API do troféu. **S2**, **S7**,
   **S8**, **S12** correm em paralelo, sem dependência.
3. **S4** integra telas de copa + estilo arredondado + chamada do troféu;
   **S10** revisa o fluxo no rascunho.
4. **S9** revisa código de S1–S4; **S6** revisa capturas. Donos corrigem
   achados bloqueantes.
5. **S11 — verificação final**, nesta ordem (Godot em
   `/home/claude/tools/Godot_v4.5.1-stable_linux.x86_64`):
   1. Abrir o projeto headless uma vez (importação) e checar erros/avisos.
   2. `tests/run_tests.tscn` — todos os testes unitários e de integração
      (física, árbitro, partida, campo, copas, carreira).
   3. `tests/all_leagues.tscn` — todas as ligas e copas simulam sem erro.
   4. `tests/shots_match.tscn` e `tests/shots_cups.tscn` — capturas PNG em
      `production/qa/evidence/` (lance com gol em cima, chaveamento ida e volta,
      final, troféu, telas com bordas arredondadas).
   5. `tests/movie.tscn` com `--write-movie` — vídeo de prévia (partida →
      copa → título → troféu).
   6. Conferir as capturas a olho (não basta o script rodar).
   7. Atualizar `LEIAME.md` (ida e volta, troféu) — pedir a quem for dono; hoje
      fica com S4.
   8. Gerar o zip do projeto (sem `.godot/`, sem `production/session-logs`) e
      entregar ao usuário junto com o vídeo de prévia e as capturas.
6. Checkpoint em `production/session-state/active.md`.

## Notas

- Sem histórico de sprints anteriores: estimativas não calibradas pela
  velocidade do time; confiança média.
- Ida e volta já tem início em `src/cups.gd` (`round_legs`, `tie_legs`,
  `aggregate`) — S1 parte dali.
