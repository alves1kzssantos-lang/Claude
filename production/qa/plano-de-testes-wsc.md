# Plano de testes — rodada "estilo WSC" (Craque Manager)

**Data:** 2026-11-14 · **Autor:** qa-lead · **Motor:** Godot 4.5.1 (Compatibility) · **Alvos:** Mobile (toque) e PC
**Escopo:** (1) copas em ida e volta, (2) câmera do lance invertida + otimização, (3) telas de resultado de copa estilo WSC,
(4) animação de título, (5) modo carreira de jogador (regressão).

Comandos usados neste plano (`G=/home/claude/tools/Godot_v4.5.1-stable_linux.x86_64`, sempre a partir de `/home/claude/claude`):

| Nome | Comando | O que prova |
|---|---|---|
| SUÍTE | `$G --headless --path . res://tests/run_tests.tscn` | testes unit + integration; sai 0 se tudo passa |
| LIGAS | `$G --headless --path . res://tests/all_leagues.tscn` | uma temporada em cada uma das 58 ligas, com copas |
| CAP-COPA | `$G --path . res://tests/shots_cups.tscn` | capturas `copa_*.png` |
| CAP-PARTIDA | `$G --path . res://tests/shots_match.tscn` | capturas `wsc_*.png` |
| CAP-JOGADOR | `$G --path . res://tests/preview_pro.tscn` | capturas `jogador_*.png` |

> Capturas precisam de janela/renderizador (não rodam em `--headless`). Em servidor sem tela, usar `xvfb-run` com `--rendering-driver opengl3`.

---

## 0. Linha de base (antes de aceitar as mudanças)

Registrada em 2026-11-14 ~15:52–15:58, com os outros agentes editando ao mesmo tempo.

| Execução | Resultado | Observação |
|---|---|---|
| SUÍTE, 1ª tentativa (~15:51) | **78 ok / 3 falharam** (código 1) | As 3 falhas eram "empate na copa vai para os pênaltis". O agente de copas regravou `test_cups_season.gd` e `game.gd` às 15:51 **durante** a execução; esse texto de teste nem existe mais no arquivo. Edição em andamento, não é defeito. |
| SUÍTE, 2ª tentativa (~15:54, após 100 s) | **120 ok / 0 falharam** (código 0) | Os testes passaram de 82 para 120 porque o agente de copas incluiu as verificações de ida e volta. `screens_cup.gd`, `trophy_celebration.gd`, `main.gd`, `screens_hub.gd`, `screens_pro.gd` e o teste de copas foram alterados de novo entre 15:53:06 e 15:53:34, ou seja, no meio desta execução. **Rodar de novo quando os 4 agentes terminarem.** |
| LIGAS | **58/58 ligas terminaram, 0 copas "SEM CAMPEÃO"**, código 0, 222 s (221 932 ms) | 30 ligas têm copa, 28 não têm. 13 ligas sem logo da liga. 17 clubes sem escudo no total (o pior é China League One, com 4). |

Números de desempenho da linha de base (máquina de CI, não é celular):
`campo ao vivo leve` 84 µs/quadro · `lógica do lance leve` 33 µs/quadro · `rodada simulada rápida` 69,4 ms/rodada · média de gols 3,03/jogo.

**Pontos fracos já vistos na linha de base:**
- `all_leagues.gd` tem um limite de 200 iterações (`g < 200`) mas **não avisa** se a temporada parou por esse limite. Uma copa que nunca termina pode passar despercebida, já que só aparece "SEM CAMPEÃO" quando o campeão é −1. Sugestão para o dono da ferramenta: imprimir `TRAVOU` quando `season_over` for falso ao sair do laço.
- O número entre parênteses (ex.: `Copa do Brasil(32)`) é o total de times da 1ª fase, não o número de jogos.
- `tests/integration/match/bench_draw.gd` diz para rodar `res://tests/bench_draw.tscn`, mas essa cena não existe em `tests/`. Também não está na SUÍTE. Hoje não há medida automática do custo de **desenho** do lance.
- O save (`Game.save()` → `store_var(S)`) **não tem número de versão**. A compatibilidade com saves antigos depende de verificações tipo `has()` espalhadas pelo código (ex.: `Cups.stages()` e `Cups.tie_legs()`).

---

## 1. Copas em ida e volta (`src/cups.gd`)

**Tipo de história:** Logic + Integration · **Evidência obrigatória:** teste automático (BLOQUEIA) + capturas das telas de copa.

### Critérios de aceite
- CA1.1 Copas com `legs = 2` (Copa do Brasil, Libertadores, Champions) têm 2 etapas por fase. As de jogo único (FA Cup, Carabao, Nordeste, Verde, etc.) têm 1.
- CA1.2 Com `final_single = true`, a final é jogo único (Libertadores, Champions). A final da Copa do Brasil é ida e volta.
- CA1.3 Quem avança é decidido pelo agregado (sem gol fora). Só tem pênaltis quando o agregado empata no **último** jogo do confronto. Nunca tem pênaltis no jogo de ida.
- CA1.4 O mando inverte na volta: quem é `h` joga a ida em casa e `a` joga a volta em casa.
- CA1.5 Todas as copas de todas as 58 ligas têm campeão antes da última rodada da liga. Nenhuma copa divide data com outra.
- CA1.6 Um save antigo (sem `stages` nem `legs`) carrega, segue em jogo único até o fim da temporada e passa a sortear em ida e volta na temporada seguinte.
- CA1.7 Os nomes das etapas aparecem certos: "… - Primeira Partida" / "… - Segunda Partida" e "Jogo de ida" / "Jogo de volta".

### Casos automáticos
| ID | Caso | Onde | Estado |
|---|---|---|---|
| A1.1 | Número de etapas por fase igual a `legs`/`final_single` | `test_cups_season.gd::_check_legs` | existe, passa |
| A1.2 | Agregado decide; pênaltis só com agregado empatado | `test_cups_season.gd` | existe, passa |
| A1.3 | Última etapa aponta o campeão | `test_cups_season.gd` | existe, passa |
| A1.4 | Copas não dividem datas e acabam antes da última rodada | `test_cups_season.gd` | existe, passa (Brasil e Inglaterra) |
| A1.5 | Todas as 58 ligas: temporada termina e toda copa tem campeão | LIGAS | existe; **falta** detectar o limite de 200 iterações (ver §0) |
| A1.6 | **Save antigo:** carregar um dicionário de copa sem `stages`/`legs` com uma fase pela metade, jogar até o fim e ver campeão + `round_legs == 1` | `tests/integration/cups/` (novo) | **FALTA, bloqueia o aceite** |
| A1.7 | Mando invertido na volta (`legs[1]` com o `a` em casa) | `test_cups_season.gd` (novo `check`) | **FALTA** |
| A1.8 | Agregado empatado em 0–0 e 0–0, e em 1–1 e 1–1: tem pênaltis e o vencedor é quem ganhou os pênaltis | unit `tests/unit/cups/` (novo, entrada determinística) | **FALTA** |
| A1.9 | Salvar e carregar entre a ida e a volta: o agregado se mantém | integration (novo) | **FALTA** |
| A1.10 | Clube do usuário eliminado na ida/volta: o calendário não mostra mais jogos dessa copa | integration (novo) | **FALTA** |

### Casos manuais (celular)
| ID | Passos | Esperado |
|---|---|---|
| M1.1 | Carreira de técnico no Brasileirão A → jogar até a 1ª partida da Copa do Brasil | Rótulo "Jogo de ida", placar do jogo, sem pênaltis mesmo com empate |
| M1.2 | Jogar a volta empatando o agregado | Disputa de pênaltis, e a tela mostra o agregado e os pênaltis |
| M1.3 | Salvar depois da ida, fechar o app (tirar da memória), abrir e carregar | Volta marcada, agregado da ida certo |
| M1.4 | Carregar um save feito **antes** desta rodada (guardar uma cópia de `user://carreira_*.sav` antes de instalar o build novo) | Carrega sem erro, a copa em andamento termina e a próxima temporada sorteia ida e volta |
| M1.5 | Final da Libertadores e da Champions | Jogo único |

### Riscos de regressão
- **Copa que não termina:** se `days` e `stages` ficarem com tamanhos diferentes (ex.: um save antigo com `stages` criado pela metade), `c["next"]` nunca chega ao fim e o campeão fica −1. Coberto por A1.5 e A1.6.
- **Datas:** dobrar as etapas aperta o calendário. Em ligas curtas (8–12 clubes: Premier League do Canadá, Superliga, K League 1, estaduais) há risco de a copa passar da última rodada. Cobrir com A1.4 estendido a todas as ligas pela ferramenta LIGAS.
- **Telas que leem `hg`/`ag`** como placar do jogo, quando agora são o agregado: placar errado no pós-jogo, no feed da rede social (modo jogador) e no histórico.
- **Carreira de jogador:** os jogos de copa contam nos jogos e nas notas do jogador, e dobrar as etapas muda essa contagem (ver §5).

---

## 2. Câmera do lance invertida + otimização (`src/lance_view.gd`, `src/field_view.gd`)

**Tipo de história:** Visual/Feel + Logic (a parte de converter coordenadas) · **Evidência:** capturas guardadas + aprovação do lead (BLOQUEIA), testes de lance continuam passando.

### Critérios de aceite
- CA2.1 No lance, o gol que o usuário ataca fica **em cima** da tela. O ataque sobe.
- CA2.2 O toque cai onde o dedo está: `_s2w(_w2s(p)) == p` (erro < 0,01 m) com a câmera nova, em qualquer `cam_y`.
- CA2.3 A câmera não mostra fora do campo além da margem e acompanha a bola com "mais campo à frente", agora para cima.
- CA2.4 **Pênalti:** batedor, goleiro, marca da cal e gol enquadrados desde o primeiro quadro (sem pulo de câmera). A mira do toque é coerente com a nova orientação. "GOOOL DE PÊNALTI!" / defesa aparecem certos.
- CA2.5 Falta direta, barreira, escanteio/cruzamento, impedimento e a comemoração funcionam na orientação nova.
- CA2.6 No campo ao vivo (`field_view`), o lado de ataque continua o mesmo do lance, sem trocar de lado entre o campo ao vivo e o lance.
- CA2.7 Desempenho: `lógica do lance leve` ≤ 33 µs/quadro (linha de base) e `campo ao vivo leve` ≤ 84 µs/quadro. No celular fraco, ≥ 30 fps estáveis no lance e no campo ao vivo (ver M2.5).

### Casos automáticos
| ID | Caso | Onde | Estado |
|---|---|---|---|
| A2.1 | `nenhum lance trava`, distribuição de resultados (gols 79/600 na linha de base, defesas, impedimento) | `test_match_balance.gd` | existe; a faixa aceitável não pode mudar com a câmera |
| A2.2 | `lógica do lance leve` e `campo ao vivo leve` | `test_match_balance.gd`, `test_field_view.gd` | existe; comparar com a linha de base |
| A2.3 | Ida e volta tela↔mundo (`_w2s`/`_s2w`) com vários `cam_y` e tamanhos de tela (720×1280, 1080×2400, 1280×720) | unit novo `tests/unit/lance/` | **FALTA, bloqueia o aceite** (é Logic) |
| A2.4 | Pênalti scriptado (`script_kind = "penalty"`) termina com `result.pen == true` e kind goal/save conforme `sim.penalty_scored` | integration novo | **FALTA** |
| A2.5 | Custo de `_draw` do lance (corrigir a cena de `bench_draw.gd` e registrar µs/quadro antes e depois) | `bench_draw` | **FALTA a cena**; é a única prova de "otimizou" |

### Casos manuais (celular)
| ID | Passos | Esperado |
|---|---|---|
| M2.1 | Jogar 3 partidas e pegar lances de ataque | Gol em cima, toque responde no ponto tocado, passe/chute para o lugar certo |
| M2.2 | Forçar pênalti a favor (jogar até sair um, ou usar a cena de captura) | Enquadramento estável, mira coerente, resultado certo |
| M2.3 | Pênalti **contra** (lance da máquina) e disputa de pênaltis de copa | Orientação consistente, nada de câmera de cabeça para baixo |
| M2.4 | Falta direta com barreira, perto da área | Barreira entre a bola e o gol, na orientação nova |
| M2.5 | **Celular fraco** (Android de entrada, 2–3 GB de RAM, GPU Mali-G52 ou parecida): campo ao vivo 3 min + 5 lances, com o monitor de fps ligado | ≥ 30 fps, sem travadas visíveis > 100 ms, sem esquentar a ponto de cair o desempenho em 10 min |
| M2.6 | Girar ou redimensionar a tela (PC: 1280×720 e janela retrato) | Câmera se ajusta, nada cortado |

### Riscos de regressão
- **Pênalti com câmera nova:** o código de pênalti tem vários `if setpiece == "penalti"` (linhas ~723, 744, 773, 817) com posições e alvos que podem estar na orientação antiga (sinal de `y`/`dirv`). É o maior risco desta mudança.
- Placas de publicidade (`_draw_adboards(goal_y, dirv)`), comemoração e o árbitro (`rt` limitado a y entre 3 e 60) dependem da direção.
- Otimizar `_draw` pode quebrar a ordem de desenho (jogador atrás da trave, bola por cima/por baixo). Só a captura pega isso.
- `test_field_view` "posse na tela bate com a simulação" já está larga (37% na tela contra 49% na simulação). Se a otimização mexer no campo ao vivo, essa diferença pode piorar sem o teste falhar.

---

## 3. Telas de resultado de copa estilo WSC (`src/screens_cup.gd`)

**Tipo de história:** UI · **Evidência:** captura guardada de **cada** tela tocada (BLOQUEIA, inclusive em `qa.level: minimal`).

### Critérios de aceite
- CA3.1 Tela `cup_results`: cabeçalho com a logo do campeonato, aba COMPETIÇÃO, fundo temático (listras = Copa do Brasil, chuva = Libertadores, estrelas = Champions, gramado = demais), faixas de resultado (vencedor em texto escuro, perdedor apagado) e ticker.
- CA3.2 Em ida e volta, a faixa mostra o placar do jogo, o agregado e, se houver, os pênaltis. O nome da etapa mostra Primeira/Segunda Partida.
- CA3.3 Tela `cup` (chaveamento) mostra as fases e quem avançou, com o campeão destacado no fim.
- CA3.4 Copa sem logo, clube sem escudo (17 clubes na linha de base) e nomes longos (ex.: "Brighton & Hove", "Liga Expansión MX Apertura") não quebram o layout: sem texto saindo da faixa e sem escudo vazio sem substituto.
- CA3.5 A tela funciona com toque: rolagem nas listas grandes (32 times) e botão de avançar com área ≥ 48 dp.
- CA3.6 O fundo animado não derruba o fps no celular fraco (≥ 30 fps).

### Casos automáticos
| ID | Caso | Onde | Estado |
|---|---|---|---|
| A3.1 | Montar `cup_results` e `cup` para todas as copas de todas as ligas, sem erro de script | integration novo (montar as telas sem renderizar, como o laço de LIGAS) | **FALTA**, recomendado |
| A3.2 | `theme_for(nome)` devolve o fundo esperado para as 3 copas temáticas e o gramado para as outras | unit novo | **FALTA**, barato |
| A3.3 | Capturas geradas sem erro | CAP-COPA | existe |

### Casos manuais (celular)
| ID | Passos | Esperado |
|---|---|---|
| M3.1 | Ver os resultados da fase depois de um jogo de copa (ida, volta e final) | CA3.1 e CA3.2 |
| M3.2 | Abrir o chaveamento pelo hub/calendário | CA3.3, rolagem suave |
| M3.3 | Liga sem logo (ex.: Bundesliga, MLS, EFL) com copa (FA Cup, Canadian Championship) | Substituto visual em vez de espaço vazio |
| M3.4 | Tela pequena (≤ 5,5") e tela grande retrato | Nada cortado, texto legível |

### Riscos de regressão
- `screens_hub.gd`, `screens_pro.gd` e `main.gd` foram alterados para chamar `CupScreens`. Uma rota quebrada (`m.go("cup_results", …)` com parâmetro errado) só aparece em uso. Cobrir com A3.1.
- Telas antigas de copa (`copa_chaveamento`, `copa_fim_de_jogo`) podem ter ficado duplicadas ou sem acesso.

---

## 4. Animação de título (`src/trophy_celebration.gd`)

**Tipo de história:** Visual/Feel · **Evidência:** capturas guardadas + aprovação do lead (BLOQUEIA).

### Critérios de aceite
- CA4.1 Ao ganhar a liga ou a copa (técnico) e ao ganhar título pelo clube (jogador), toca a animação: mãos levantando o troféu, confete, "Parabéns!" e duração de cerca de 4,5 s com fade a partir de 3,9 s.
- CA4.2 Um toque pula para o fim. `done` é emitido **uma única vez** e o nó se libera (`queue_free`).
- CA4.3 Vários títulos na mesma temporada (`celebrate_queue`) tocam em sequência, um por vez, cada um com a logo e o estilo de troféu certos (ouro/prata), e não travam a tela de fim de temporada.
- CA4.4 Depois da animação, o fluxo continua (fim de temporada / hub) sem precisar de toque extra e sem overlay preso por cima bloqueando o toque.
- CA4.5 Os 120 confetes não derrubam o fps no celular fraco (≥ 30 fps).

### Casos automáticos
| ID | Caso | Onde | Estado |
|---|---|---|---|
| A4.1 | Instanciar, avançar o `_process` por 5 s simulados e ver que `done` foi emitido 1 vez e o nó saiu da árvore | integration novo | **FALTA**, recomendado |
| A4.2 | Pular com toque no 1º quadro: `done` 1 vez, sem erro | idem | **FALTA** |
| A4.3 | Fila de 3 títulos: 3 `done`, na ordem certa | idem | **FALTA** |

### Casos manuais (celular)
| ID | Passos | Esperado |
|---|---|---|
| M4.1 | Ganhar uma copa (técnico, time forte no Brasileirão A) | CA4.1 e CA4.4 |
| M4.2 | Tocar várias vezes seguidas durante a animação | Pula uma vez, não pula a tela seguinte por engano |
| M4.3 | Liga + copa na mesma temporada | Duas animações em sequência (CA4.3) |
| M4.4 | Modo jogador: clube do jogador campeão | Animação com o nome do clube |
| M4.5 | Minimizar o app durante a animação e voltar | Retoma ou termina, nunca trava |

### Riscos de regressão
- Toque "vazando" para a tela de baixo (o overlay pega o toque mas o botão do hub também recebe).
- `done` emitido duas vezes (toque + fim do tempo) fazendo o fluxo avançar duas telas.

---

## 5. Modo carreira de jogador (regressão)

**Tipo de história:** Integration (regressão) · **Evidência:** `test_pro_career.gd` passando + capturas `jogador_*`.

### Critérios de aceite (o que já funciona e não pode quebrar)
- CA5.1 Fluxo: peneira (jogo festivo, titular) → propostas (≥ 1) → assinar → empresário → temporada → histórico → nova temporada com +1 ano. Igual à linha de base (18 checks passando).
- CA5.2 A máquina nunca vende nem dispensa o jogador. Notas realistas (média de 6,38 na linha de base, faixa aceita pelo teste).
- CA5.3 Jogos de copa em ida e volta contam nos jogos e nas notas do jogador e aparecem no feed da rede social com o placar **do jogo** (não o agregado).
- CA5.4 A câmera nova no lance do jogador (peneira e liga) segue CA2.1–CA2.4.
- CA5.5 Título do clube toca a animação (CA4.3) pela rota de `screens_pro.gd`.
- CA5.6 Save do modo jogador feito antes desta rodada carrega (`peek_save` mostra nome, posição, ovr e estágio).

### Casos automáticos
| ID | Caso | Onde | Estado |
|---|---|---|---|
| A5.1 | Fluxo completo de uma temporada | `test_pro_career.gd` | existe, passa (18/18) |
| A5.2 | Jogador em clube de liga com copa ida e volta: jogos de copa contados e sem pênaltis na ida | `test_pro_career.gd` (novo `check`) | **FALTA** |
| A5.3 | Save antigo de jogador carrega (`peek_save` + `load_career`) | integration novo | **FALTA**, junto com A1.6 |

### Casos manuais (celular)
| ID | Passos | Esperado |
|---|---|---|
| M5.1 | Nova carreira de jogador, peneira até a nota | Igual às capturas `jogador_04`–`jogador_14`, com o lance na orientação nova |
| M5.2 | Jogar 5 jogos da liga e 1 de copa | Feed, notas e salário corretos |
| M5.3 | Responder torcedores e ver a vida/empresário | Sem regressão visual |

### Riscos de regressão
- O feed pós-jogo e o histórico podem ler `hg`/`ag` (que agora é o agregado) como placar.
- Mais jogos de copa → mais minutos, o que pode tirar as notas e o salário da faixa do teste.

---

## 6. Riscos transversais (resumo)

| Risco | Severidade se acontecer | Cobertura |
|---|---|---|
| Save antigo não carrega / copa antiga não termina | S1 (perda de progresso) | A1.6, A5.3, M1.4 — **faltam os testes automáticos** |
| Copa sem campeão / temporada que não acaba em alguma liga | S1 (trava o progresso) | A1.5 (LIGAS), com o aviso de limite de iterações a incluir |
| Pênalti com câmera nova errado (mira ou enquadramento) | S2 | A2.4, M2.2, M2.3 |
| Toque desalinhado no lance | S2 | A2.3, M2.1 |
| fps < 30 em celular fraco (lance, fundo animado, confete) | S2 | M2.5, CA3.6, CA4.5; A2.5 para medir |
| Overlay de título prendendo o toque | S2 | A4.1–A4.3, M4.2, M4.5 |
| Layout quebrado com nome longo ou sem escudo | S4 | M3.3, M3.4 + capturas |

---

## 7. Capturas obrigatórias em `production/qa/evidence/` (PNG)

Todas **guardadas** (o arquivo precisa estar no disco quando a história fechar). As novas são geradas pelas cenas de captura. As que já existem precisam ser **regeradas** depois das mudanças, porque as atuais são de antes desta rodada.

### Copas ida e volta + telas WSC (CAP-COPA)
| Arquivo | Conteúdo | Situação |
|---|---|---|
| `copa_resultados_fase.png` | Resultados de uma etapa (cup_results) | nova, a gerar |
| `copa_brasil_ida.png` | Copa do Brasil, "Primeira Partida", fundo listras | **nova, a criar na cena** |
| `copa_brasil_final.png` | Final da Copa do Brasil (Segunda Partida, agregado) | nova, a gerar |
| `copa_libertadores_semi_volta.png` | Semi da Libertadores, volta, fundo chuva | nova, a gerar |
| `copa_libertadores_resultado_final.png` | Final jogo único da Libertadores | nova, a gerar |
| `copa_champions_resultados.png` | Champions, fundo estrelas | **nova, a criar na cena** |
| `copa_penaltis_agregado.png` | Faixa com agregado empatado + pênaltis | **nova, a criar na cena** |
| `copa_sem_logo.png` | Copa/clube sem logo ou escudo (ex.: FA Cup na EFL) | **nova, a criar na cena** |
| `copa_chaveamento.png`, `copa_libertadores_final.png`, `copa_calendario.png`, `copa_proxima_partida.png`, `copa_fim_de_jogo.png`, `copa_fim_temporada.png` | Telas existentes | **regerar** |

### Lance com câmera nova (CAP-PARTIDA)
| Arquivo | Conteúdo | Situação |
|---|---|---|
| `wsc_03_campo.png`, `wsc_04_lance_decisao.png`, `wsc_05_gol_lance.png` | Campo ao vivo e lance com o gol em cima | **regerar** |
| `lance_penalti_cobranca.png` | Pênalti a favor, antes do chute | **nova** |
| `lance_penalti_resultado.png` | Gol ou defesa de pênalti | **nova** |
| `lance_penalti_contra.png` | Pênalti da máquina | **nova** |
| `lance_falta_barreira.png` | Falta direta com barreira | **nova** |
| `lance_01`…`lance_14`, `campo_01`…`campo_05` | Sequência existente | **regerar** (orientação antiga) |

### Animação de título
| Arquivo | Conteúdo | Situação |
|---|---|---|
| `titulo_01_inicio.png` | ~0,5 s: mãos e troféu entrando | **nova** |
| `titulo_02_auge.png` | ~2 s: troféu no alto + confete + "Parabéns!" | **nova** |
| `titulo_03_prata.png` | Estilo prata (outra competição) | **nova** |
| `titulo_04_fila.png` | 2º título da fila (liga + copa) | **nova** |
| `titulo_05_jogador.png` | Título no modo jogador | **nova** |

### Carreira de jogador (CAP-JOGADOR)
| Arquivo | Conteúdo | Situação |
|---|---|---|
| `jogador_01`…`jogador_25` | Fluxo completo | **regerar** (lance novo e feed com copa) |
| `jogador_26_copa_ida_volta.png` | Jogador num jogo de copa (rótulo ida/volta) | **nova** |

### Celular (manual)
Prints tirados no aparelho com o monitor de fps visível, salvos em PNG:
`celular_lance_fps.png`, `celular_campo_fps.png`, `celular_copa_resultados.png`, `celular_titulo.png`.
Anotar o modelo do aparelho e o build no nome ou no relatório.

---

## 8. Ordem de execução e critério de saída da rodada

1. Os 4 agentes terminam → rodar SUÍTE e LIGAS de novo, sem edição em andamento. Esperado: SUÍTE com código 0, sem número de testes passando menor que 120, e LIGAS com 58/58 e 0 "SEM CAMPEÃO".
2. Criar os testes marcados **FALTA, bloqueia o aceite** (A1.6, A2.3). É trabalho para o programador dono de cada parte, não para o QA.
3. Gerar e regerar todas as capturas do §7 e revisar uma por uma contra os critérios.
4. Rodada manual no celular (M1–M5), com M2.5 no aparelho fraco.
5. Abrir bug com `/bug-report` para cada falha (S1/S2 bloqueiam a rodada).

**Rodada aprovada quando:** SUÍTE 0 falhas · LIGAS 58/58 com campeão e sem limite de iterações estourado · A1.6 e A2.3 existem e passam · capturas do §7 no disco e aprovadas pelo lead · ≥ 30 fps no celular fraco · nenhum bug S1/S2 aberto.
