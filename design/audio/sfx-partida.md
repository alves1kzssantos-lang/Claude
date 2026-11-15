# Craque Manager — Especificação de Efeitos Sonoros (partida, abertura, menus, título)

> **Status:** RASCUNHO para revisão do `audio-director`.
> **Autor:** sound-designer · **Data:** 2026-11-14
> **Escopo:** somente efeitos sonoros (SFX) e ambiência de torcida. Música, hino e
> fanfarra ficam com o `audio-director` (ver §9).
> **Motor:** Godot 4.5, renderer Compatibility, alvo Mobile + PC, entrada por toque.

---

## 0. Pendências e conflitos (ler antes)

| # | Item | Situação | Quem decide |
|---|---|---|---|
| P1 | **Não existe paleta sonora nem convenção de nomes de áudio** do audio-director no repositório. Os nomes e o "caráter" de cada som abaixo são **propostas**. | Precisa de aprovação | audio-director |
| P2 | **Não há evento de intervalo no código.** `MatchSim.step()` vai do minuto 1 ao 90 sem emitir nada no 45. O apito do intervalo precisa de um gancho novo (ex.: `minute == 45` em `match_view._process`). | Gancho a criar | programador (godot-gdscript-specialist) |
| P3 | **Impedimento da simulação só existe como texto.** Em `match_sim.gd:158` é um evento `type: "chance"` com o texto "Impedimento marcado…". Para tocar `apito_impedimento` sem comparar texto, o evento precisa de um campo (ex.: `"offside": true`). No lance em campo já existe `kind == "offside"`. | Gancho a criar | programador |
| P4 | **Falta sem cartão no meio-campo não gera evento** (`_midfield_foul` devolve lista vazia quando não há cartão). Hoje só faltas com cartão podem apitar na partida ao vivo. Decidir se isso basta ou se a falta comum deve emitir evento. | Decisão de design | game-designer / usuário |
| P5 | `src/trophy_celebration.gd` **ainda não existe**; os ganchos do título (§3.6) são uma proposta para quem está escrevendo esse arquivo. | Aguardando código | programador |
| P6 | O arquivo da **rede social do modo jogador** não foi localizado nesta leitura; o gancho de `ui_notificacao_social` está como "a confirmar". | A confirmar | programador |
| P7 | Música/fanfarra do título e trilha da abertura **não estão nesta especificação** (fora do domínio do sound-designer). | Encaminhar | audio-director |

---

## 1. Princípios (proposta para o audio-director validar)

1. **Ler bem no alto-falante do celular.** O alto-falante do celular corta quase tudo abaixo de ~250 Hz. Todo som importante (chute, apito, rede, toque de UI) precisa ter energia entre **1 e 5 kHz**. O grave fica como "bônus" para quem joga de fone.
2. **Transmissão de TV, não estádio realista.** A torcida é uma cama constante e o apito corta por cima. A referência de clareza é o World Soccer Champs: sons curtos, secos, sem cauda longa de reverb.
3. **Sem cauda de reverb longa nos SFX de jogo:** no máximo **300 ms** nos sons de bola e apito. Assim o som não embola em 6× de velocidade.
4. **Nada de cantos reais de clubes** (direito autoral e marca). A torcida é genérica, sem palavras que dê para entender.
5. **Variação acima de quantidade:** poucos arquivos com variação de pitch/volume no Godot (`AudioStreamRandomizer`) e não dezenas de arquivos.

---

## 2. Barramentos (buses) e mixagem

### 2.1 Layout dos buses (`default_bus_layout.tres`)

```
Master (0 dB, limiter no fim)
├── SFX      (-3 dB)   bola, goleiro, trave, rede, apito
├── Torcida  (-8 dB)   ambiência em loop + reações da torcida
└── UI       (-6 dB)   botões, abas, notificação, abertura, título
```

- **Master:** `AudioEffectLimiter` (ou `AudioEffectHardLimiter`, conferir em `docs/engine-reference/`) com teto de **-1 dBFS**, para o gol (rede + explosão da torcida + apito) não distorcer no celular.
- **Torcida:** `AudioEffectLowPassFilter` com corte de **20 kHz** em repouso. O corte cai para **1,2 kHz** quando a partida está pausada (§2.4).
- **Volumes por bus:** o jogador ajusta direto no bus. Uma tela de opções de som está fora deste escopo.

### 2.2 Volume relativo (referência)

Os valores são o `volume_db` do player/evento **antes** do bus. Referência: o chute forte normalizado com pico de -1 dBFS e o arquivo tocado em 0 dB.

| Faixa | Eventos | volume_db do evento |
|---|---|---|
| Mais alto | torcida_gol_explosao, apito_final, rede_gol | 0 |
| Alto | chute, trave, apito_inicio, apito_intervalo | -2 a -4 |
| Médio | defesa_goleiro, apito_falta, apito_impedimento, cabeceio | -5 a -7 |
| Baixo | passe_rasteiro, passe_alto, torcida_lamento | -9 a -12 |
| Cama | torcida_ambiente_loop | -6 (o bus -8 já baixa) |
| UI | ui_toque_botao, ui_troca_aba | -10 a -12 |

### 2.3 Ducking (abaixar a torcida)

O ducking é aplicado **no volume do player do loop de ambiência** e não no bus Torcida. Se fosse no bus, a explosão do gol, que também está no bus Torcida, seria abaixada junto.

| Gatilho | Alvo | Quanto | Ataque | Segura | Volta |
|---|---|---|---|---|---|
| **Gol** (rede_gol + explosão) | torcida_ambiente_loop | **-14 dB** | 80 ms | enquanto a explosão toca (≈ 3,5 s em 1×/2×; 2,0 s em 6×) | 1,5 s |
| Apito (qualquer) | torcida_ambiente_loop | -4 dB | 30 ms | duração do apito | 400 ms |
| Abertura do campeonato (`CompIntro`) | torcida_ambiente_loop (se já estiver tocando) | -10 dB | 150 ms | 2,9 s (`CompIntro.DUR`) | 800 ms |
| Celebração do título | Torcida inteira | -6 dB | 200 ms | duração da fanfarra | 1 s |

**Como fazer o ducking no gol (em ordem):**
1. Tween do `volume_db` do loop até -14 dB em 80 ms.
2. No mesmo quadro: `rede_gol` (bus SFX) e `torcida_gol_explosao` (bus Torcida).
3. Quando a explosão terminar (sinal `finished` do player ou timer), Tween de volta ao volume base em 1,5 s.
4. Se sair outro gol durante o ducking, **reinicia** o ciclo (mata o Tween anterior com `kill()`).

Por que fazer o ducking à mão: o sidechain do `AudioEffectCompressor` funciona, mas é difícil de ajustar e de testar. Um Tween é determinístico e fácil de calibrar.

### 2.4 Estados globais da partida

| Estado (código) | Comportamento do áudio |
|---|---|
| `field.paused_view = true` / menu de pausa | Loop da torcida: low-pass 1,2 kHz e -6 dB em 250 ms. SFX de bola param (o campo congela). UI continua normal. |
| Volta da pausa | Desfaz em 250 ms. |
| `_to_end()` ("Ir ao fim" / "Simular") | Para todos os SFX de bola e as reações da torcida. Toca `apito_final`. O loop faz fade-out em 2 s. |
| Lance em tela cheia (`LanceView`) | A torcida continua. Os SFX de bola agora vêm do `LanceView`, porque o `FieldView` fica invisível. |
| Velocidade 6× | Mesmos sons, com cooldowns (§4) e explosão de gol mais curta. Pitch **não** muda com a velocidade. |
| Saída da tela (`_exit_tree`) | Fade-out de tudo nos buses SFX/Torcida em 300 ms. |

---

## 3. Lista de eventos e especificação de cada som

Legenda:
- **Prio:** 1 = nunca é cortado; 5 = primeiro a ser roubado quando a pool enche.
- **Máx. simult.:** quantas instâncias do mesmo evento podem tocar juntas.
- **Var.:** número de arquivos `.ogg` diferentes. **Pitch / Vol rand.:** randomização do `AudioStreamRandomizer`.
- Todos os arquivos são **mono**, salvo indicação. Taxa de 44,1 kHz.

### 3.1 Bola e jogadores (bus SFX)

| Evento | Arquivo(s) | Dispara em | Duração | volume_db | Var. | Pitch / Vol rand. | Prio | Máx. simult. | Cooldown |
|---|---|---|---|---|---|---|---|---|---|
| Chute | `chute_01..04.ogg` | `LanceView._do_shot()` quando `header == false`; `FieldView.show_chance()` | 0,15–0,30 s | -2 | 4 | ±6% / ±1,5 dB | 2 | 2 | 0,10 s |
| Cabeceio | `cabeceio_01..02.ogg` | `LanceView._do_shot()` quando `header == true` | 0,10–0,20 s | -6 | 2 | ±5% / ±1 dB | 3 | 1 | 0,10 s |
| Passe rasteiro | `passe_rasteiro_01..04.ogg` | `LanceView._do_pass(lofted=false)`; `FieldView` no `bp.kick_ground()` do passe | 0,08–0,15 s | -10 | 4 | ±8% / ±2 dB | 4 | 2 | 0,12 s |
| Passe alto / cruzamento | `passe_alto_01..03.ogg` | `LanceView._do_pass(lofted=true)`; `FieldView` no `bp.kick_lofted()` | 0,20–0,35 s | -8 | 3 | ±6% / ±1,5 dB | 4 | 1 | 0,15 s |
| Defesa do goleiro | `defesa_goleiro_01..03.ogg` | `LanceView._update_shot()` → `_finish("save", …)` | 0,25–0,40 s | -5 | 3 | ±5% / ±1 dB | 2 | 1 | — |
| Trave / travessão | `trave_01..02.ogg` | `_update_shot()`: `"trave"` e `"travessao"` | 0,6–0,9 s (ressonância metálica) | -3 | 2 | trave ±4%; **travessão: pitch fixo -8%** e ±4% | 2 | 1 | — |
| Chute travado | reaproveita `defesa_goleiro_*` com pitch -15% | `_finish("blocked", …)` | 0,2 s | -8 | (reuso) | ±5% | 3 | 1 | — |
| Rede (gol) | `rede_gol_01..02.ogg` | `LanceView._finish("goal", …)`; `match_view._show_event()` com `type == "goal"` | 0,5–0,8 s | 0 | 2 | ±3% / ±0,5 dB | **1** | 1 | — |

**Caráter de cada som (proposta, sujeita a P1):**
- **chute:** "tum" seco de chuteira em bola de couro. Transiente forte entre 2 e 4 kHz e corpo em ~150 Hz. Sem eco.
- **cabeceio:** "pof" abafado, mais grave e mais curto que o chute.
- **passe_rasteiro:** toque leve, quase um "tic". Precisa ficar **atrás** da torcida: ele toca a cada 0,7–1,6 s no `FieldView` e cansa se for alto.
- **passe_alto:** toque com um pouco mais de peito. Pode ter um leve "swoosh" de ar no fim.
- **defesa_goleiro:** tapa de luva na bola com um pouco de corpo caindo na grama. Uma variação pode ser só o tapa (espalmada).
- **trave:** "plim/tóim" metálico de trave de alumínio, com ressonância curta. É a **única** exceção ao limite de cauda de 300 ms: até 900 ms, porque a ressonância é o que diz ao jogador que foi na trave.
- **rede_gol:** bola balançando a rede, "fssh" com corpo. Toca junto com a explosão da torcida e precisa ser ouvida no começo dela.

### 3.2 Apito do árbitro (bus SFX)

Um único conjunto de gravação de apito garante o mesmo timbre. Cada padrão é um arquivo próprio, porque o ritmo do apito é a informação.

| Evento | Arquivo(s) | Dispara em | Padrão | Duração | volume_db | Var. | Pitch rand. | Prio | Máx. simult. |
|---|---|---|---|---|---|---|---|---|---|
| Início da partida | `apito_inicio.ogg` | `match_view._kickoff()` (após o `CompIntro` emitir `done`) | 1 longo | 0,9–1,1 s | -3 | 1 | ±2% | 1 | 1 (todos os apitos juntos) |
| Saída depois do gol | reaproveita `apito_inicio` com -3 dB | `field.kickoff()` chamado em `_show_event` (gol) | 1 longo | 0,9 s | -6 | (reuso) | ±2% | 2 | 1 |
| Falta | `apito_falta_01..03.ogg` | `LanceView._foul()` (FALTA / PÊNALTI / falta direta); `match_view._show_event()` com `type == "card"` | 1 curto e forte | 0,25–0,4 s | -5 | 3 | ±3% | 2 | 1 |
| Pênalti | `apito_penalti.ogg` | `LanceView._foul()` quando `restart == "penalti"` (no lugar do apito de falta) | 1 curto muito forte e estridente | 0,5 s | -3 | 1 | — | 1 | 1 |
| Cartão | apito de falta + `cartao_mostrado.ogg` 0,35 s depois | `type == "card"`; no lance, `card_flash != ""` | stinger curto de UI ("tchak" + brilho), **vermelho com pitch -12% e +2 dB** | 0,4 s | -8 | 1 | — | 2 | 1 |
| Impedimento | `apito_impedimento.ogg` | `LanceView._finish("offside", …)`; na simulação depende de **P3** | 2 curtos | 0,6 s | -5 | 1 | ±2% | 2 | 1 |
| Intervalo | `apito_intervalo.ogg` | **Gancho a criar (P2)**: minuto 45 | 2 longos | 1,8 s | -3 | 1 | — | 1 | 1 |
| Fim de jogo | `apito_final.ogg` | `match_view._end_live()` e `match_view._to_end()` | 2 curtos + 1 longo | 2,2 s | 0 | 1 | — | 1 | 1 |
| Vantagem | **sem apito** | `restart == "vantagem"` | — | — | — | — | — | — | — |

**Regra:** só um apito toca por vez. Se chegar um novo, o anterior é cortado com fade de 30 ms. Exceção: o `apito_final` nunca é cortado.

### 3.3 Torcida (bus Torcida)

| Evento | Arquivo(s) | Dispara em | Duração | volume_db | Var. | Rand. | Prio | Máx. simult. | Observações |
|---|---|---|---|---|---|---|---|---|---|
| Ambiência (cama) | `torcida_ambiente_loop.ogg` (**estéreo**) | começa em `_kickoff()`, para em `_end_live()` / `_to_end()` | loop de 30 s | -6 | 1 | — | 1 | 1 | Loop sem emenda audível (fazer crossfade na edição). Murmúrio de estádio com palmas e gritos distantes sem palavras. Precisa de **marcação de loop no import** (`loop = true`). |
| Tensão (bola no ataque) | `torcida_tensao_01..02.ogg` | `FieldView`: holder a menos de 22 m do gol adversário (mesmo teste da linha 258); `LanceView`: entrada em `state == "decide"` perto da área | 2–3 s, crescendo | -10 | 2 | ±3% / ±1 dB | 4 | 1 | Cooldown de **8 s**. Faz fade-out de 300 ms se o lance terminar antes. |
| Lamento "uuuh" | `torcida_lamento_01..03.ogg` (estéreo) | `_finish("save" / "out" / "blocked")`; `"trave"`/`"travessao"` com **+3 dB**; `show_chance()` | 1,5–2,2 s | -7 | 3 | ±4% / ±1,5 dB | 3 | 1 | Cooldown de 3 s. Não toca em `"lost"` nem em `"offside"`. |
| Explosão do gol | `torcida_gol_explosao_01..02.ogg` (estéreo) | junto com `rede_gol` | 4–5 s (corta com fade conforme a velocidade, ver §2.3) | 0 | 2 | ±2% | **1** | 1 | O gol do **adversário** usa a mesma explosão com **-9 dB** e low-pass de 3 kHz (torcida "visitante"), para o gol do seu time ser mais marcante. Usar `e["side"] == my_side`. |
| Vaia (cartão vermelho contra o mandante, opcional) | `torcida_vaia_01.ogg` | `type == "card"` e `red == true` | 2 s | -9 | 1 | ±3% | 4 | 1 | **Opcional.** Só se o audio-director aprovar. |

### 3.4 Abertura do campeonato — `CompIntro` (bus UI)

Ela sincroniza com a linha do tempo de `comp_intro.gd` (`DUR = 2,9 s`).

| Evento | Arquivo | Momento (t em s) | Duração | volume_db | Var. | Prio |
|---|---|---|---|---|---|---|
| Swoosh da logo (anel expandindo) | `intro_logo_swoosh.ogg` (estéreo) | t = 0,0 | 0,7 s | -6 | 1 | 2 |
| Impacto da logo (fim do elástico) | `intro_logo_impacto.ogg` (estéreo) | t ≈ 0,5 (pico do `_elastic`) | 0,8 s (cauda até 1 s permitida por ser stinger) | -4 | 1 | 2 |
| Brilho passando | `intro_brilho.ogg` | t = 0,9 | 0,5 s | -12 | 1 | 4 |
| Escudos entrando | `intro_escudos_swoosh.ogg` (estéreo, L→R / R→L) | t = 1,15 | 0,45 s | -8 | 1 | 3 |
| "VS" | `intro_vs_impacto.ogg` | t = 1,4 | 0,4 s | -6 | 1 | 3 |
| Toque para pular | — | `_gui_input` adianta `t` para 2,6 s | — | — | — | — |

**Pular a abertura:** os sons que ainda não tocaram são **cancelados** e os que estão tocando fazem fade-out de 150 ms. O `apito_inicio` só toca depois de `done`.

### 3.5 Menus e rede social (bus UI)

| Evento | Arquivo(s) | Dispara em | Duração | volume_db | Var. | Rand. | Prio | Máx. simult. | Cooldown |
|---|---|---|---|---|---|---|---|---|---|
| Toque em botão | `ui_toque_botao_01..02.ogg` | `UI.button()` / `UI.row_button()` no `pressed` (um ponto central em `ui.gd` cobre o jogo todo) | 0,04–0,08 s | -10 | 2 | ±4% / ±1 dB | 3 | 2 | 0,05 s |
| Botão principal (INICIAR PARTIDA, Continuar dourado) | `ui_confirmar.ogg` | botões de estilo `"blue"` grandes / `"gold"` | 0,15 s | -8 | 1 | ±2% | 3 | 1 | 0,05 s |
| Troca de aba | `ui_troca_aba.ogg` | troca de aba nos menus (componente de abas) | 0,08–0,12 s | -12 | 1 | ±3% | 4 | 1 | 0,08 s |
| Toast / erro ("Escolha primeiro quem sai.") | `ui_negado.ogg` | `m.toast()` usado como aviso | 0,15 s | -12 | 1 | — | 4 | 1 | 0,3 s |
| Notificação da rede social | `ui_notificacao_social.ogg` | chegada de post/menção no modo jogador (**gancho a confirmar, P6**) | 0,3–0,5 s | -8 | 1 | — | 2 | 1 | 1,0 s (várias notificações juntas = um som) |

**Caráter:** cliques curtos, "plásticos" e brilhantes, com energia de 2 a 6 kHz e sem grave. A notificação tem duas notas ascendentes, curtas e positivas, que **não** se confundem com o apito.

### 3.6 Título — `trophy_celebration.gd` (bus UI + Torcida)

Proposta de ganchos para quem está criando o arquivo (P5). A fanfarra/música é do audio-director (P7). Os itens abaixo são só as camadas de efeito.

| Evento | Arquivo | Momento sugerido | Duração | Bus | volume_db | Var. | Prio |
|---|---|---|---|---|---|---|---|
| Troféu surgindo (brilho metálico subindo) | `titulo_trofeu_brilho.ogg` (estéreo) | início da animação do troféu | 1,2 s | UI | -6 | 1 | 1 |
| Troféu erguido (impacto) | `titulo_trofeu_impacto.ogg` (estéreo) | quadro em que o troféu chega ao alto | 1,0 s | UI | -3 | 1 | 1 |
| Confete / fogos | `titulo_confete_01..02.ogg` (estéreo) | junto com as partículas | 2–3 s | UI | -10 | 2 | 3 |
| Torcida campeã | reaproveita `torcida_gol_explosao_*` em loop curto, ou `titulo_torcida_campea.ogg` (estéreo, 8 s) | durante toda a celebração | 8 s | Torcida | -6 | 1 | 2 |

---

## 4. Concorrência, prioridade e cooldown

### 4.1 Limites por bus (tamanho da pool)

| Bus | Players na pool | Por quê |
|---|---|---|
| SFX | **8** | Pior caso: passe + chute + defesa + rede + apito + sobra para roubo |
| Torcida | **4** | 1 loop fixo + tensão + lamento/explosão + sobra |
| UI | **4** | Toques rápidos + notificação + camadas da abertura/título |

Total: **16 vozes**, um valor folgado para celular.

### 4.2 Roubo de voz (voice stealing)

Quando a pool do bus está cheia:
1. Procura um player livre.
2. Se não houver, rouba o player tocando o som de **menor prioridade** (número maior). No empate, rouba o mais antigo.
3. Se o novo som tiver prioridade **menor** do que todos os que estão tocando, **descarta o novo**.
4. A prioridade **1 nunca é roubada** (rede, explosão do gol, apito final/início, loop da torcida).

### 4.3 Cooldown e limite por evento

- O **cooldown** é o tempo mínimo entre dois disparos do **mesmo evento** (tabelas do §3). Disparos dentro do cooldown são ignorados (não ficam na fila).
- O **máx. simult.** conta as instâncias do mesmo evento tocando ao mesmo tempo. Quando passa do limite, rouba a instância mais antiga do próprio evento.
- Em **6×**, o passe rasteiro ganha cooldown de 0,25 s. Os demais ficam iguais.

---

## 5. Plano de implementação em Godot 4.5

> Isto é um plano para o programador (`godot-gdscript-specialist`). O sound-designer não escreve código.
> **Antes de usar qualquer API, conferir em `docs/engine-reference/`** (regra de `src/CLAUDE.md`):
> principalmente `AudioStreamRandomizer`, `AudioStreamPlayer.max_polyphony`, o import de OGG com loop e
> `AudioEffectHardLimiter`.

### 5.1 Estrutura sugerida

```
assets/audio/
├── sfx/        chute_*, cabeceio_*, passe_*, defesa_goleiro_*, trave_*, rede_gol_*, apito_*, cartao_mostrado
├── torcida/    torcida_ambiente_loop, torcida_tensao_*, torcida_lamento_*, torcida_gol_explosao_*, (torcida_vaia_01)
├── ui/         ui_*, intro_*, titulo_*
└── eventos/    um .tres de AudioStreamRandomizer por evento (ex.: chute.tres agrupa chute_01..04)
assets/data/audio_events.json   tabela de eventos (volume, prioridade, cooldown, máx. simult., bus)
```

- Os números do §3/§4 ficam no **`assets/data/audio_events.json`**, nada fixo no código (padrão do projeto: valores data-driven, como já é feito em `match_tuning.json`).
- Cada evento tem nome lógico (`"chute"`, `"apito_falta"`…) e o código de jogo chama só `Audio.play("chute")`.

### 5.2 Autoload `Audio` (pool de AudioStreamPlayer)

1. **Autoload** `Audio` (um Node), ao lado dos singletons que já existem (`Game`, `Tuning`, `DataPack`).
2. No `_ready()`, cria **3 pools** de `AudioStreamPlayer` (não `AudioStreamPlayer2D`: a câmera é de TV e não há espacialização). Tamanhos do §4.1, cada player com `bus = "SFX"`, `"Torcida"` ou `"UI"`.
3. O loop da torcida fica num **player dedicado** fora da pool, para o ducking por Tween (§2.3).
4. `play(evento)` faz isto:
   checa o cooldown → checa o máx. simult. → escolhe player (§4.2) → aplica `volume_db` do JSON → `play()`.
   A variação de pitch/volume já vem do `AudioStreamRandomizer` (`random_pitch`, `random_volume_offset_db`, `playback_mode = RANDOM_NO_REPEATS`).
5. `duck_torcida(db, ataque, segura, volta)`, `pausar_partida(bool)` e `parar_partida()` cobrem o §2.3/§2.4.
6. **Testável:** a lógica de cooldown, prioridade e roubo fica numa classe pura (`RefCounted`) que recebe o tempo atual como parâmetro. Assim dá para testar em `tests/unit/audio/` sem tocar áudio de verdade (padrão do projeto: injeção de dependência e testes determinísticos).

### 5.3 Pré-carregamento

- **Todos os SFX curtos** (bola, apito, UI, intro) ficam com `preload()` nos `.tres` de evento, carregados ao abrir o jogo. Eles são pequenos (§6) e não pode haver travada no primeiro chute.
- `torcida_ambiente_loop` e `torcida_gol_explosao_*` são carregados com `ResourceLoader.load_threaded_request()` quando a **Central da partida** abre (`match_view._ready`), e liberados ao sair.
- Os sons do título são carregados com `load_threaded_request()` quando o código do título começar, porque raramente tocam.
- Os OGG são decodificados durante a reprodução (Vorbis, custo leve de CPU). Para 16 vozes isso é tranquilo em celular de entrada. Se o perfil mostrar pico de CPU nos passes em 6×, a alternativa é converter só `passe_*` e `ui_toque_*` para WAV IMA-ADPCM. **Isso sai do pedido ".ogg" e precisa de aprovação.**

### 5.4 Configurações de import

- Os `.ogg` de efeito ficam com `loop = false`. O `torcida_ambiente_loop.ogg` fica com `loop = true` e `loop_offset = 0`.
- **Normalização na edição, antes de exportar:** pico de -1 dBFS em todos. A diferença de volume vem do `volume_db` no JSON e não do arquivo. Assim o ajuste de mixagem não exige re-exportar áudio.
- Silêncio no início do arquivo: **< 5 ms** (chute e toque de UI precisam de resposta imediata ao dedo).

### 5.5 Mapa de ganchos (onde chamar)

| Arquivo | Função / condição | Chamada |
|---|---|---|
| `src/match_view.gd` | `_kickoff()` | `Audio.play("apito_inicio")` + iniciar o loop da torcida |
| | `_process()` ao chegar no minuto 45 (**P2**) | `Audio.play("apito_intervalo")` |
| | `_show_event()`: `type == "goal"` | ducking + `rede_gol` + `torcida_gol_explosao` (side do usuário ou não) + `apito_inicio` (saída, -3 dB) 1,5 s depois |
| | `_show_event()`: `type == "card"` | `apito_falta` → `cartao_mostrado` (vermelho se `red`) |
| | `_show_event()`: impedimento (**P3**) | `apito_impedimento` |
| | `_end_live()`, `_to_end()` | `apito_final` + `Audio.parar_partida()` |
| | `_on_pause()` | `Audio.pausar_partida(paused)` |
| | `_start()` | (a abertura dispara seus próprios sons) |
| | `_exit_tree()` | fade-out geral |
| `src/lance_view.gd` | `_do_pass(i, lofted)` | `passe_alto` ou `passe_rasteiro` |
| | `_do_shot()` | `cabeceio` se `header`, senão `chute` |
| | `_foul()` | `apito_penalti` / `apito_falta` (sem som em `"vantagem"`); `cartao_mostrado` se `card != ""` |
| | `_finish(kind, …)` | `goal` → rede + explosão; `save` → defesa + lamento; `blocked` → defesa travada + lamento; `offside` → apito_impedimento; `out` → lamento. A **trave** deve tocar no ponto do `match` de `_update_shot` (`"trave"`/`"travessao"`), antes do `_finish` |
| | entrada em `state == "decide"` perto da área | `torcida_tensao` |
| | `skip()` | toca só o som do resultado final (sem chute) |
| `src/field_view.gd` | passe em `_process()` (`kick_ground` / `kick_lofted`) | `passe_rasteiro` / `passe_alto` |
| | `show_chance()` | `chute` + `torcida_lamento` |
| | holder a menos de 22 m do gol | `torcida_tensao` (cooldown 8 s) |
| | `celebrate()` | (o som do gol já sai do `match_view`; não duplicar) |
| `src/comp_intro.gd` | `_ready()` + marcas de tempo em `_process()` | sons do §3.4; cancelar ao pular |
| `src/ui.gd` (helpers de botão) | `pressed` de `button` / `row_button` | `ui_toque_botao` / `ui_confirmar` |
| componente de abas | troca de aba | `ui_troca_aba` |
| rede social (**P6**) | nova notificação | `ui_notificacao_social` |
| `src/trophy_celebration.gd` (**P5**) | marcos da animação | sons do §3.6 |

**Cuidado com duplicação:** `LanceView` e `FieldView` compartilham código (`FieldView extends LanceView`). Se o som for colocado dentro de `_do_pass`/`_do_shot`, conferir que o `FieldView` não chama esses métodos por outro caminho e acaba tocando o som duas vezes.

---

## 6. Orçamento de tamanho (celular)

Formato de exportação: **Ogg Vorbis**. SFX mono em qualidade ~q3 (≈ 64 kbps, ≈ 8 KB/s). Torcida/stingers estéreo em ~q3 (≈ 112 kbps, ≈ 14 KB/s).

| Grupo | Arquivos | Duração total aprox. | Tamanho aprox. |
|---|---|---|---|
| Bola, goleiro, trave, rede (mono) | 20 | ~7 s | ~60 KB |
| Apitos + cartão (mono) | 9 | ~8 s | ~65 KB |
| UI (mono) | 6 | ~1,5 s | ~15 KB |
| Torcida: loop 30 s (estéreo) | 1 | 30 s | ~420 KB |
| Torcida: tensão, lamento, explosão, vaia (estéreo) | 8 | ~22 s | ~310 KB |
| Abertura (estéreo/mono) | 5 | ~3 s | ~40 KB |
| Título (estéreo) | 5 | ~15 s | ~210 KB |
| **Total** | **~54** | | **≈ 1,1 MB** |

- **Meta: ≤ 1,5 MB** para todo o áudio desta especificação. **Teto: 2 MB.**
- Se precisar cortar, o primeiro corte é o loop da torcida (de 30 s para 20 s, -140 KB), depois o título.
- **Memória:** os curtos pré-carregados ocupam < 200 KB. Os de torcida são carregados só na partida.

---

## 7. Onde baixar sons parecidos (licença CC0)

> **Regra:** confirmar a licença **de cada arquivo** no momento do download. Em sites como o Freesound
> cada som tem sua própria licença. Registrar a fonte de cada arquivo numa planilha de créditos
> (`assets/audio/CREDITOS.md`, a criar depois) mesmo sendo CC0: isso protege o projeto se alguém questionar.

| Fonte | Licença | Bom para | Dica de busca |
|---|---|---|---|
| **Freesound** — freesound.org | Varia por arquivo. **Usar o filtro de licença "Creative Commons 0"** | torcida, apito, chute, trave, rede | "stadium crowd", "football crowd ambience", "crowd groan", "crowd cheer goal", "referee whistle", "soccer ball kick", "ball hit post", "goal net", "goalkeeper save" |
| **Kenney** — kenney.nl/assets (pacotes "UI Audio", "Interface Sounds", "Impact Sounds") | CC0 (pacote inteiro) | toques de UI, notificação, impactos da abertura/título | — |
| **OpenGameArt** — opengameart.org | Varia. **Filtrar por CC0** | UI, swooshes, fanfarras curtas (fanfarra = audio-director) | "whoosh", "ui click", "sports" |
| **Sonniss GDC Game Audio Bundle** — sonniss.com/gameaudiogdc | **Não é CC0** (licença própria, uso comercial liberado, sem crédito obrigatório). Ver os termos | gravações profissionais de estádio e esportes | — |
| Pixabay Sounds | **Não é CC0** (licença Pixabay). Só usar após o audio-director aprovar | — | — |
| BBC Sound Effects | **Evitar.** Licença não comercial | — | — |

**Cuidados:**
- **Torcida:** baixar gravações sem cantos de clubes que dê para reconhecer, sem nome de time e sem palavrão que se entenda (ver §1.4).
- **Apito:** usar **uma única gravação** de apito e editar os padrões (curto, duplo, longo, final) a partir dela. Isso mantém o timbre igual.
- **Trave:** "metal pipe hit" / "goal post" no Freesound. Evitar sons de cano de ferro grave demais, porque a trave real é de alumínio, mais aguda.

---

## 8. Critérios de aceite (para QA)

1. Em 1×, um gol do usuário: a torcida de fundo abaixa, a rede e a explosão são ouvidas com clareza no **alto-falante do celular**, e a torcida volta suave em ~1,5 s.
2. Em 6× com o campo ao vivo, os passes nunca soam como "metralhadora" (cooldown) e o áudio não trava.
3. Pausa: a torcida fica abafada e os sons de bola param. Ao continuar, tudo volta.
4. "Ir ao fim" toca só o apito final, sem nenhum som de bola restante.
5. Pular a abertura não deixa nenhum som da abertura tocando por cima do apito inicial.
6. Nenhum som clipa no Master (pico ≤ -1 dBFS medido no gol com cartão e apito juntos).
7. O tamanho total da pasta `assets/audio/` é ≤ 1,5 MB (teto de 2 MB).
8. A planilha de créditos lista a fonte e a licença de cada arquivo.

---

## 9. Fora do escopo deste documento

- Música de menu, trilha da abertura, hino/fanfarra do título → **audio-director**.
- Narração/locutor ("GOOOL!" falado) → decisão de direção sonora (audio-director). Exigiria voz gravada ou licenciada.
- Tela de opções de volume e vibração (haptics) → UX / programador.
- Implementação do código → `godot-gdscript-specialist`.
