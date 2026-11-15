# Revisão de código — modo carreira de jogador e copas

Data: 2026-11-14 • Engine: Godot 4.5.1 • Somente leitura (nenhum arquivo de `src/` foi alterado).
Arquivos lidos por inteiro: `src/pro_career.gd`, `src/screens_pro.gd`, `src/match_sim.gd`, `src/comp_intro.gd`.
Em `src/game.gd` li `load_career`, `new_career`, `next_user_match`, `play_next`, `play_round`, `apply_players`, `_between_rounds`, `season_summary`, `new_season`. Li também `Cups.play_round` e `Cups._crown`, e trechos de `match_view.gd` e `main.gd`.

Nada foi executado. Cada achado vem da leitura do código, não de uma partida rodada. Onde o código que não li pode mudar o resultado, está marcado "verificar".

Legenda: **CRÍTICO** = trava a partida ou perde progresso • **ALTO** = estado errado ou exploit • **MÉDIO** = comportamento errado ou desempenho • **BAIXO** = polimento.

---

## Resumo (mais graves)

| # | Gravidade | Onde | Problema |
|---|---|---|---|
| 1 | CRÍTICO | `pro_career.gd:830-833`, `screens_pro.gd:304-309` | "Negociar" pode remover a única proposta na escolha de clube ou com contrato vencido. A tela fica sem proposta e sem botão para sair. |
| 2 | ALTO | `pro_career.gd:861-863`, `902-941`, `1062-1063` | Trocar de liga (agente livre ou transferência acertada) não envelhece o jogador. Na rota "livre" a temporada também não zera. |
| 3 | ALTO | `pro_career.gd:504` | Cada subida de força sobrescreve o salário negociado, via `Game._price`. |
| 4 | ALTO | `pro_career.gd:822, 971, 1033, 1058`, `screens_pro.gd:601, 674-676` | Saves antigos quebram por chave ausente. Não existe migração do bloco `pro`. |
| 5 | ALTO | `pro_career.gd:845-870` | É possível farmar luvas. Cada `accept` paga as luvas e sobrescreve `pending_move`. |
| 6 | MÉDIO | `pro_career.gd:455`, `519` | Lesão tira 1 jogo a mais do que o anunciado. |
| 7 | MÉDIO | `screens_pro.gd:396` | O hub chama `next_user_match()` a cada refresh. Isso tem efeito colateral: simula copa e salva. |
| 8 | MÉDIO | `pro_career.gd:156, 910` | `new_career` completo na thread principal, no celular, a cada troca de liga. |

---

## CRÍTICO

### 1. Negociar pode remover a última proposta e deixar o jogo sem saída
- **Arquivos:** `src/pro_career.gd:830-833`, `src/screens_pro.gd:300-309` e `333`.
- **Cenário:**
  - Na peneira, ninguém atinge a nota. `finish_trial` gera uma única proposta de base (`pro_career.gd:266-271`).
  - O jogador toca em "Negociar". Com `ch = 0.4 + nível*0.15`, falha com probabilidade de 60% ou mais. Depois, em 45% dos casos, o código executa `pr["offers"].remove_at(idx)`.
  - `stage` continua `"propostas"` (ou `"livre"`) com a lista vazia.
  - `offers()` mostra "Nenhuma proposta na mesa" e faz `return`. Como `first` é verdadeiro, `m.head(..., not first)` esconde o botão de voltar.
  - `main.gd:200` manda `home()` de volta para `pro_offers`. O save fica preso nessa tela.
  - O mesmo vale para o estado `livre` com contrato vencido. O botão "Recusar" já protege contra esse caso (`screens_pro.gd:333`). O `negotiate` não protege.
- **Gravidade:** CRÍTICO. É um soft-lock permanente e vai para o save.
- **Correção:**
```gdscript
# pro_career.gd, em negotiate()
var forced: bool = pr["stage"] in ["propostas", "livre"]
if Game.rng.randf() < 0.45 + tries * 0.2 and not (forced and pr["offers"].size() <= 1):
    pr["offers"].remove_at(idx)
    ...
```
Para cobrir saves já travados, regenere a proposta em `screens_pro.gd:offers()`:
```gdscript
if pr["offers"].is_empty():
    if first:
        pr["offers"].append(Pro.fallback_offer())   # make_offer na liga atual, role "base"
        m.refresh(); return
    ...
```

---

## ALTO

### 2. Mudar de liga não envelhece o jogador e, na rota "livre", não zera a temporada
- **Arquivos:** `pro_career.gd:861-863` (accept), `902-941` (move_to), `1062-1063` (next_season).
- **Cenário A (transferência acertada):**
  - `next_season()` chama `move_to(mv, true)` em vez de `Game.new_season()`. `new_season` é quem faz `p["age"] += 1`, o declínio de força depois dos 31, `energy = 100` e o zerar de `g/min/gol/ass` (`game.gd:1022-1032`).
  - O jogador que troca de liga fica um ano mais novo que o relógio. `can_retire` (33) atrasa.
  - Os `gol`/`ass`/`g` copiados em `mep` (`pro_career.gd:904`) acompanham o jogador para o novo mundo. Em `Game.season_summary` (`game.gd:1002`) o artilheiro é o maior `p["gol"]`. Os gols do ano anterior entram na corrida pela artilharia do ano novo.
- **Cenário B (contrato vencido, estágio "livre"):**
  - `accept` → `move_to(o, true)` direto. `next_season()` nunca roda. `pr["season"]` (g, gol, sum, mvp) e `pr["season_caps"]` não são zerados.
  - A média e os jogos da temporada nova somam por cima dos da anterior. Os prêmios "Seleção do campeonato" e "Revelação do ano", que exigem `g >= 15` e `g >= 12`, saem facilitados.
  - `history` registra números acumulados. `season_caps > 0` reaproveitado dispara a Copa do Mundo sem convocação nova.
- **Gravidade:** ALTO. Quebra a progressão e os prêmios em toda troca de liga.
- **Correção:** dentro de `move_to`, depois de `mep["club"] = ci`:
```gdscript
if next_year:
    mep["age"] = int(mep["age"]) + 1
    if int(mep["age"]) > 31:
        mep["ovr"] = maxi(int(mep["ovr"]) - Game.rng.randi_range(0, 2), 40)
    for k in ["g", "min", "gol", "ass"]:
        mep[k] = 0
    mep["energy"] = 100.0
    pro["season"] = _blank_season()
    pro["season_caps"] = 0
```
O `Game.new_season` não pode ser chamado nos dois mundos, então a regra de envelhecimento fica duplicada. Extraia uma função `Game.age_me(p)` e use nos dois lugares.

### 3. A subida de força apaga o salário negociado
- **Arquivo:** `pro_career.gd:501-505`.
- **Cenário:** `_train()` chama `Game._price(p)` a cada nível. `_price` recalcula `p["value"]` **e** `p["wage"]` (`game.gd:444`: `max(pow(ovr-55,2)*0.07, 1.5)`). O salário do contrato é substituído pelo da fórmula do mundo, que é bem menor que uma proposta com `aumento_salario` e fama. O `move_to` (`:933-935`) já guarda o salário antes e restaura depois. O `_train` não faz isso. `_pay` e `weekly_income` leem `me()["wage"]`, então a renda semanal despenca depois do primeiro treino.
- **Gravidade:** ALTO.
- **Correção:**
```gdscript
var w: float = p["wage"]
Game._price(p)
p["wage"] = w
```

### 4. Saves antigos: chaves lidas por indexação direta, sem migração
- **Arquivos:** `game.gd:102-115` (`load_career` só migra `league`), `pro_career.gd:822` (`negotiated`), `:971` e `:1061` (`season_closed`), `:1033` e `:1058` (`pending_move`), `:306` e `:454` (`banned`), `:461` (`posted`), `:97` (`season`), `:951` (`injury`), `:662-679` (`polemics`), `screens_pro.gd:601` e `:674-676`.
- **Cenário:**
  - Um save criado antes de uma dessas chaves existir entra no hub normalmente.
  - Na primeira negociação, o `Invalid access to property 'negotiated'` derruba o jogo. O mesmo ocorre no fim da temporada com `season_closed` e `pending_move`.
  - Há outro caso em `screens_pro.gd:674-676`. Se `season_closed` é verdadeiro mas `season_report` não existe, `close_season` devolve `{}` e `rep["year"]` quebra.
- **Gravidade:** ALTO. Afeta todo save anterior ao código atual.
- **Correção:** uma função de migração, chamada de `Game.load_career` depois de `S = d`:
```gdscript
# pro_career.gd
static func migrate(pr: Dictionary) -> void:
    var def := {"negotiated": {}, "season_closed": false, "pending_move": {}, "banned": 0, "posted": false,
        "polemics": 0, "retired": false, "season_caps": 0, "caps": 0, "ngoals": 0, "injury": "", "clause": 0.0,
        "sponsors": [], "owned": [], "awards": [], "titles": [], "history": [], "feed": [], "offers": [],
        "next_post": 1, "last": {}, "train": "normal", "xp": 0.0, "ratings": [], "agent": "", "money": 0.0,
        "season": _blank_season()}
    for k in def:
        if not pr.has(k):
            pr[k] = def[k]
# game.gd, load_career
if S.get("mode", "") == "pro" and S.has("pro"):
    Pro.migrate(S["pro"])
```
No `season()` de `screens_pro.gd`, antes de usar `rep`:
```gdscript
if rep.is_empty():
    pr["season_closed"] = false
    rep = Pro.close_season()
```

### 5. Farm de luvas e `pending_move` sobrescrito
- **Arquivo:** `pro_career.gd:845-870`. Relacionados: `:706` (post "sair"), `:769-808` (`_window`).
- **Cenário:**
  - `accept()` paga `luvas` na hora (`:852`) e, para outra liga, só grava `pending_move`. O jogador não se compromete com nada.
  - O post "sair" (`own_post`) gera propostas novas depois de cada jogo, porque `posted` volta a `false` em `after_match`. Cada nova proposta aceita paga luvas de novo e substitui a anterior em `pending_move`.
  - Exemplo: 10 jogos, 10 acordos e 10 pagamentos de luvas, sem nunca sair do clube.
  - Em `close_season` a janela "fim" (`:1047`) também põe propostas na mesa. A tela de fim de temporada deixa aceitar outra por cima do acerto já feito.
- **Gravidade:** ALTO. Quebra a economia.
- **Correção:** só pague as luvas na hora em que o jogador se muda de fato (`move_to` ou `_transfer_same_league`), e bloqueie nova aceitação com acerto pendente:
```gdscript
if not pr["pending_move"].is_empty() and not o.get("renewal", false):
    return "Você já acertou com o %s." % pr["pending_move"]["name"]
...
pr["pending_move"] = o        # sem pagar luvas aqui
# em move_to e _transfer_same_league: pr["money"] += o["luvas"] * (1.0 - comissão)
```

---

## MÉDIO

### 6. Lesão de N jogos tira N+1
- **Arquivos:** `pro_career.gd:519` (`susp = n + 1`), `:455`, `game.gd:695-702` e `:706`.
- **Cenário:** o `+1` pressupõe um decremento depois do jogo, como no cartão vermelho. Mas `_injury_roll` roda em `after_match`, depois do decremento do `play_round` (que acontece antes de `_between_rounds`). A lesão de `n` jogos fica `n+1` na hora de escalar. `status_line` mostra `susp - 1`, então o texto engana. Nas copas não há decremento nenhum (`play_next`), então o contador só anda nas rodadas de liga.
- **Gravidade:** MÉDIO.
- **Correção:** use `p["susp"] = max(susp, n)` quando a lesão nascer de `after_match`, e mostre `susp` sem o `-1`. Ou decremente também depois de jogos de copa.

### 7. O hub tem efeito colateral e é pesado a cada refresh
- **Arquivo:** `screens_pro.gd:396` (`Game.next_user_match()`), `:405`, `:450`.
- **Cenário:**
  - Cada toque em aba, em botão de treino ou em "refresh" reconstrói a tela e chama `next_user_match()`. Ele chama `advance_to_user()` (`game.gd:277-283`), que **simula e salva** rodadas de copa em que o clube não está.
  - Mudar o treino pode, portanto, mudar o estado do mundo.
  - Também roda `Game.ratings(opp)` e `Game.position_of` (que ordena a tabela) a cada reconstrução.
  - `mt` pode vir `{}` se `ev.is_empty()`. Hoje `season_over` cobre isso. Qualquer outra rota até `_tab_games` que não passe por `season_over` cai em `mt["h"]`.
- **Gravidade:** MÉDIO. O custo é pequeno no PC e perceptível no celular.
- **Correção:** chame `next_user_match()` uma vez ao entrar no hub e guarde o resultado (`_next_cache`), invalidando-o em `play_next`. Trate o retorno vazio:
```gdscript
var mt: Dictionary = Game.next_user_match()
if mt.is_empty():
    nc[1].add_child(UI.label("Sem jogos agendados", 18, UI.MUTED))
    lv.add_child(nc[0]); return
```

### 8. Construção do mundo inteiro na thread principal, e saves repetidos
- **Arquivos:** `pro_career.gd:156` (`start`), `:910` (`move_to`), `:473`, `game.gd:711`, `:334`.
- **Cenário:**
  - `Game.new_career` cria 20+ clubes com 30 jogadores, lê elencos do datapack, faz 8 `_ai_transfer` e salva.
  - `move_to` repete tudo a cada troca de liga. `start` também faz isso, mais 32 jogadores de peneira. No celular o toque de "Aceitar" congela por vários segundos.
  - A cada partida o `store_var(S)` do mundo inteiro roda duas ou três vezes: `play_round` (`game.gd:711`), `after_match` (`pro_career.gd:473`) e a copa (`game.gd:334`).
- **Gravidade:** MÉDIO (desempenho no celular).
- **Correção:**
  - Mostre um aviso e dê um frame antes de construir: `m.toast("Montando o novo clube..."); await Engine.get_main_loop().process_frame` no botão. A função precisa ser `async` ou o trabalho vai num `call_deferred`.
  - Salve uma vez só, no fim do `after_match`. Em modo pro, `play_round` e a copa não precisam salvar.
  - Em `move_to`, evite `Game.save()` interno de `new_career`, usando um parâmetro `save := true`.

### 9. Premiação de artilheiro e Bola de Ouro olham todos os jogadores do mundo
- **Arquivos:** `pro_career.gd:989-991`, `game.gd:1000-1005`.
- **Cenário:**
  - `p["gol"]` soma gols de liga e de copa, e inclui jogadores convidados de outras ligas que entram nas copas.
  - "Artilheiro do campeonato" pode ser concedido ou negado por gols de copa.
  - Se ninguém marcou (por exemplo, depois de `move_to`), `best` é o primeiro jogador do dicionário. No mundo novo o seu jogador é o último inserido, então o caso é raro. Mas `top["gol"] == 0` ainda pode premiar.
- **Gravidade:** MÉDIO.
- **Correção:**
```gdscript
if top != null and int(top["id"]) == int(p["id"]) and int(top["gol"]) > 0:
```
E o ideal é filtrar `season_summary` para `club < n_league()`.

### 10. `_pay(7)` e `_sponsor_roll()` rodam por jogo, inclusive de copa
- **Arquivo:** `pro_career.gd:458-459`.
- **Cenário:** semana de dois jogos (liga e copa) paga duas semanas de salário e de patrocínio. Fama e patrocínios saem mais rápido do que o previsto. Isso é um problema de balanceamento.
- **Gravidade:** MÉDIO.
- **Correção:** use os dias reais entre eventos.
```gdscript
var days: int = clampi(int(Game.S["day"]) - int(P().get("last_pay_day", Game.S["day"])), 1, 14)
P()["last_pay_day"] = Game.S["day"]
_pay(days)
```

### 11. Uruguai não tem liga
- **Arquivos:** `pro_career.gd:15`, `:130-136`, `:201-233`, `screens_pro.gd:152`.
- **Cenário:**
  - `NATS` contém "Uruguai", mas `World.LEAGUES` não tem liga uruguaia.
  - `home_league` devolve `maxi(-1, 0) = 0` (Série A do Brasil). A tela de criação diz "A peneira acontece no país do jogador (Brasil)".
  - `pool_home` fica vazio, então `_scouts` só tem os 2 olheiros de fora. Não trava, mas a peneira fica pobre e sem escada de força.
- **Gravidade:** MÉDIO (a regra falha em silêncio).
- **Correção:** remova "Uruguai" da lista, ou use um mapa de país vizinho:
```gdscript
const HOME_ALIAS := {"Uruguai": "Argentina"}
...
var country: String = HOME_ALIAS.get(nat, nat)
```
Faça o mesmo em `_scouts`. Depois confira todos os 10 países de `NATS`.

### 12. Estado impossível: livre no mercado, sem como se aposentar
- **Arquivos:** `main.gd:200` e `screens_pro.gd:511` (`can_retire` só aparece em `_tab_career`).
- **Cenário:** jogador de 34 anos com contrato vencido (`stage = "livre"`). `home()` só leva a `pro_offers`. O botão de aposentadoria fica no hub, que não se alcança. Ele é obrigado a assinar com alguém.
- **Gravidade:** MÉDIO.
- **Correção:** na tela de propostas do estágio `livre`, mostre também o botão "Pendurar as chuteiras" (`Pro.can_retire()` e `Pro.retire()`).

---

## BAIXO

13. **`replace("", "")` não faz nada** — `pro_career.gd:605` e `screens_pro.gd:559`. Era para tirar espaços do @. Hoje o nome sai "@novo craque". Correção: `.replace(" ", "")`.
14. **Ofertas repetidas do mesmo clube** — `_window` (`:780-805`) não confere `pr["offers"]`. Duas janelas seguidas (meio e pedido) podem listar o mesmo clube duas vezes. Correção: pule `ci` já presente em `pr["offers"]`.
15. **Convocação nunca dispara em ligas curtas** — `assets/data/pro_career.json`: `selecao.rodadas = [8,16,24,32]`, mas ligas de 16 clubes têm 30 rodadas. A 4ª convocação nunca acontece. Use frações de `nrounds`.
16. **Lógica que não faz nada** — `pr["clause"]` (multa rescisória) só aparece na tela. `pr["retired"]` é gravado e não é lido. `pr["fans"]` e `pr["coach"]` baixos não têm consequência (o técnico só afeta escalação e renovação). Decida se são cosméticos ou ligue em alguma regra.
17. **`after_match` sai sem salvar nem escalar se `sim == null`** (`:413-416`). Também não protege `sim.focus_side == -1`. Se por algum caminho o sim não passou por `setup_sim`, `rate()` e `_store_last` indexam `score[1 - (-1)]` e quebram. Correção: `if sim == null or lu.is_empty() or sim.focus_pid != int(P()["me"]): return`.
18. **Dinheiro negativo sem limite** — `reply()` desconta multa de `pr["money"]` sem piso (`:670`).
19. **Peneira sem nota** — `finish_trial` faz `P()["ratings"].append(r)` mesmo se `r == -1.0` (`:274`). O `form()` passaria a incluir −1. Hoje o jogador é forçado ao XI, então é improvável.
20. **`CompIntro`**:
    - `var ease` (`comp_intro.gd:50`) sombreia a função global `ease()` (aviso do compilador).
    - `_draw` mede `get_string_size` de textos fixos em todo frame (`:112-127`). Guarde as larguras em `_ready`.
    - `h`/`a` começam em −1. Se o chamador esquecer de definir, `Crest.make(-1)` aponta o último clube (`S["clubs"][-1]`). Valide em `_ready`.
    - `match_view.gd:209-212` liga `done` a `_kickoff` sem proteção. Se o usuário sair da tela durante os 2,9 s, `_kickoff` roda numa tela obsoleta (verificar). Use `CONNECT_ONE_SHOT` e um teste `if not is_instance_valid(...)`.
    - `queue_redraw()` todo frame é aceitável por 2,9 s. O resto da animação é leve.
21. **Estilo**: `Pro._k` é chamado de fora (`screens_pro.gd:325`) mesmo com prefixo `_`. Renomeie para `fmt_wage`. Faltam doc comments em `Pro.P/me/rate/agent` e nas funções de `screens_pro.gd`.

---

## Verificado e sem problema

- Divisão por zero:
  - `avg_rating` (`g > 0`), `xp_needed` (mínimo positivo), `step` em `_scouts` (`maxf(...,1)`) e `ratio` em `step()` (`maxf(...,1)`) estão protegidos.
  - `form()` só roda com lista não vazia, nos chamadores atuais.
- Índices:
  - `slots[k]`/`xi[i]` em `pick_lineup` respeitam `xi.size()`.
  - `_force_into_xi` precisa de `xi` com 11 itens. `auto_lineup` sempre entrega isso nas peneiras.
- Cópias e referências de `Dictionary` no `move_to`: `duplicate(true)` está correto. As alterações de `pr` antes do duplicate entram na cópia.
- Fluxo `pending_move` + renovação: a renovação só é criada com `pending_move` vazio (`:1033`). `accept` limpa as propostas, então os dois não coexistem. O problema real é o item 5.
- `MatchSim`:
  - `_focus_sub` respeita o limite de 5 trocas, expulsos e `out`. O evento `"sub"` é tratado em `match_view.gd:361`.
  - `setup_sim` roda no `_init`, antes de `refresh()`. `orig_xi` já foi copiado, então `apply_players` restaura o XI depois da troca.
- Vazamento de nós: `ProAvatar` desliga `_process`. `LanceView` não tem `_ready`, então nada deixa de ser chamado. O `CompIntro` se libera com `queue_free`. Não achei nó sem dono em `screens_pro.gd` (a árvore é refeita por `UI.clear`/`m.refresh`).
- `_sponsor_roll`: o `return` está dentro do `if` do sorteio, então todo patrocinador elegível é testado. O código está certo.

## Sugestão de testes (gdUnit4, `tests/unit/pro_career/`)
1. `negotiate` nunca deixa `offers` vazio com `stage in [propostas, livre]` (item 1).
2. `move_to(o, true)` incrementa `age` e zera `g/gol/ass/min` e `season` (item 2).
3. `_train` mantém `wage` depois de subir de força (item 3).
4. `Pro.migrate` em um dicionário `pro` mínimo preenche todas as chaves lidas por indexação direta (item 4).
5. Aceitar duas propostas seguidas não soma luvas duas vezes (item 5).
