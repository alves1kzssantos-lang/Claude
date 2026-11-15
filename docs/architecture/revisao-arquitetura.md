# Revisão de Arquitetura — Craque Manager (mobile, crescimento)

- **Data**: 2026-11-14
- **Autor**: technical-director
- **Escopo**: save/load, memória de texturas, inicialização e importação do datapack, acoplamento (`Game` global), compatibilidade de saves, testes.
- **Base**: Godot 4.5.1 (Compatibility), código em `src/` no estado de 2026-11-14 (cópia congelada em `/tmp/cm_measure`, para não atrapalhar os agentes que estão editando).
- **Status**: Proposto — nada aqui foi implementado; as ADRs abaixo aguardam decisão do usuário.

---

## 1. Medições

Ambiente: servidor Linux x86-64, 2 vCPU, headless, `user://` isolado (`XDG_DATA_HOME=/tmp/cm_xdg`).
Script: `/tmp/cm_measure/zz_measure.gd` (baseado em `tests/all_leagues.gd`); dados brutos em `/tmp/cm_scripts/all_leagues.txt`.
**Celular**: os valores "estimados no celular" usam um fator de 3x a 5x mais lento que este servidor (Android intermediário, um núcleo, armazenamento flash). É estimativa, não medição; precisa ser confirmada num aparelho real (ver seção 6).

### 1.1 Save (uma temporada completa, com copas, nas 58 ligas)

| Métrica | Valor medido | Estimado no celular |
|---|---|---|
| Tamanho do `carreira_N.sav` — mediana | 596 KB | igual |
| Tamanho — pior caso (liga com mais convidados de copa: 67 clubes, 1.682 jogadores) | 1,27 MB | igual |
| Bytes por jogador (média) | ~900 B | igual |
| Mesmo save com `var_to_bytes` + ZSTD | ~9% do tamanho (1,27 MB vira 113 KB) | igual |
| `Game.save()` — média / pior caso | 12 ms / 28 ms (75 ms em uma rodada de 3 temporadas) | 40–375 ms |
| `get_var()` (carregar) — pior caso | 45 ms | 135–225 ms |
| Saves por temporada (um por jogo do usuário, mais as telas) | 42–52 | — |
| Crescimento ao longo de 3 temporadas (Série A) | 1.104 → 1.108 KB (estável) | — |

Observações:
- O save fica **estável entre temporadas** porque `news` (40), `transfers` (60) e jogadores aposentados têm limite. O que cresce sem limite: `history`, `trophies`, `p["titles"]`, `pro.history` — pequeno, uma entrada por temporada.
- Hoje **só a liga da carreira é simulada**. Os outros clubes entram como "convidados" de copa (`S["guests"]`). As 58 ligas existem em `World.LEAGUES` (cerca de 510 clubes), mas não ficam no save.
- **Projeção**, se o design passar a simular todas as ligas (como no World Soccer Champs): cerca de 510 clubes × 25 jogadores ≈ 12.800 jogadores ≈ **11–12 MB por save**, com save de cerca de 150–250 ms aqui e **0,5–1,2 s no celular, a cada jogo**, na thread principal.
- 4 slots: `peek_save()` lê o save **inteiro** de cada slot só para mostrar o cartão na tela inicial. Hoje são cerca de 4 × 30 ms; na projeção, cerca de 4 × 1 s.

### 1.2 Datapack (primeira importação e inicialização)

| Métrica | Valor medido | Estimado no celular |
|---|---|---|
| `datapack.zip` | 20,7 MB, 5.204 arquivos (4.122 escudos, 152 logos de competição, 924 placas) | — |
| **`DataPack.import_zip()` completo** | **97 s** | **5–8 min** |
| Ler as 500 **primeiras** entradas do zip | 0,7 s (1,4 ms cada) | — |
| Ler as 500 **últimas** entradas do zip | 16,5 s (33 ms cada) | — |
| Gravar 500 arquivos pequenos | 0,06–0,08 s | — |
| Disco depois de importar (`user://datapack`) | ~29 MB (logos 21 MB, placas 5,6 MB, `players.dat` 1,4 MB, `pack.dat` 270 KB) | + 20,7 MB do zip dentro do APK = **~50 MB** |
| `DataPack.ensure()` a frio (`pack.dat`) | 100–147 ms | 0,3–0,7 s |
| `players.dat` (69.223 nomes) | 19 ms | 60–100 ms |

**Causa dos 97 s:** `ZIPReader.read_file(path)` localiza cada entrada percorrendo o diretório central do zip, então cada leitura custa O(n) e a importação inteira custa **O(n²)**. A gravação em disco é desprezível. Além disso, `import_zip` roda **na thread principal** (`main.gd::_first_run_import`). O Android mostra o aviso "O app não está respondendo" depois de cerca de 5 s sem responder a toque. A tela diz "pode levar até 1 minuto", o que não confere com o medido.

### 1.3 Memória de texturas

| Métrica | Valor |
|---|---|
| Escudo típico | 120×120 (2.855 de 4.122), RGBA8, sem mipmap |
| Todos os escudos decodificados | **216 MB** de RAM/VRAM (decodificar tudo leva 3,0 s, 0,73 ms por escudo) |
| Todas as placas decodificadas | **122 MB** |
| Uso típico numa carreira (cerca de 60 clubes, 1–3 conjuntos de placas) | cerca de 3–4 MB (escudos) + 3–8 MB (placas) |
| Memória estática do Godot depois de uma temporada | 35–40 MB |

`DataPack._tex` e `DataPack._ads` são caches estáticos **sem descarte nenhum**. Cada escudo visto no navegador do datapack (`screens_start.gd`, busca nos 4.122 clubes, 60 por página) fica na memória até o processo fechar. Em celulares de 2–3 GB isso leva a o sistema matar o app (OOM) depois de uso longo do navegador ou de muitas copas com placas de vários países.

---

## 2. Arquitetura atual (resumo)

- **Estado**: um único `Dictionary` sem tipo (`Game.S`) guarda toda a carreira. O schema é implícito: as chaves são strings espalhadas pelo código e os defaults de migração ficam soltos (`S.get(...)`/`S.has(...)` em cerca de 33 lugares).
- **Acoplamento**: cerca de 570 referências a `Game.` em 16 arquivos (`pro_career` 147, `screens_hub` 104, `screens_team` 60, `match_sim` 52, `lance_view` 49, `cups` 40). `Pro`, `Cups` e `DataPack` são `class_name` com **estado estático** que lê e escreve direto em `Game.S`. Telas mutam `Game.S` e chamam `Game.save()` por conta própria (cerca de 30 chamadas em 4 arquivos).
- **Persistência**: `FileAccess.store_var(S)` síncrono, sobrescrevendo o arquivo no lugar (sem `.tmp` nem backup), na thread principal, depois de cada jogo e de várias ações de tela.
- **Versão**: `S["ver"] = 2` é gravado e **nunca lido**. Não existe rotina de migração.
- **Referências por índice**: o save guarda `league` (índice em `World.LEAGUES`), `li`/`ci` (índices de liga e clube) e chaves `"li:ci"` de convidados. `peek_save` faz `World.LEAGUES[int(d["league"])]` sem checar o limite.
- **Testes**: `tests/run_tests.tscn` (executor próprio) cobre física, árbitro, balanço de partida, `field_view`, copas e modo jogador. **Não há** teste de save/load (ida e volta), de migração, de `datapack.import_zip`, nem das regras de `game.gd` (mercado, nova temporada). `tests/all_leagues.tscn` é uma ferramenta de inspeção que imprime problemas mas não falha (sem asserções). Também usa o slot 9 no `user://` real.
- **Detalhe de dados**: duas ligas aparecem com o nome "Premier League" no `comp_name` do datapack (uma com 11 clubes). Vale conferir o `COMP_IDS`.

---

## 3. Riscos priorizados

Severidade = impacto × probabilidade, considerando um jogo mobile que vai crescer.

| # | Risco | Sev. | Evidência | Mitigação recomendada |
|---|---|---|---|---|
| **R1** | **Primeira importação do datapack trava o celular por minutos (O(n²) no zip + thread principal) → aviso "não está respondendo", o usuário fecha o app, a importação fica pela metade** | **Crítica** | 97 s medidos aqui; últimas entradas a 33 ms cada | ADR-A |
| **R2** | **Save corrompido ou carreira perdida**: escrita não atômica a cada jogo; o Android mata apps em segundo plano; `get_var` de um arquivo truncado devolve `null` e o slot "some" | **Crítica** | `game.gd::save()` abre com WRITE (trunca) e grava direto; cerca de 50 gravações por temporada | ADR-B |
| **R3** | **Saves antigos quebram em silêncio a cada atualização**: `ver` nunca é lido, não há migração, e as referências são índices em `World.LEAGUES` (reordenar ou inserir uma liga embaralha carreiras; remover uma derruba `peek_save`) | **Alta** | `"ver": 2` sem leitor; `S["league"]`, `li`, `ci` e `"li:ci"` são índices | ADR-B |
| **R4** | **Save não escala se o mundo passar a simular as 58 ligas**: ~900 B/jogador em `store_var` com chaves string repetidas; projeção de 11–12 MB e 0,5–1,2 s de travada por jogo no celular; `peek_save` lê o save inteiro | **Alta** (condicional ao design) | 1,27 MB com 1.682 jogadores; ZSTD reduz para 9% | ADR-C |
| **R5** | **Memória de texturas sem limite**: caches `_tex`/`_ads` estáticos e sem descarte; 216 MB de escudos e 122 MB de placas se tudo for visto | **Alta** em celular de 2–3 GB | Medido pela decodificação de todos os arquivos | Cache LRU com teto (ex.: 256 escudos ≈ 14 MB, 3 conjuntos de placas); texturas com mipmap ou reduzidas para 64 px nas listas |
| R6 | Acoplamento ao `Game` global + estado estático em `Pro`/`Cups`/`DataPack`: impossível testar regras sem o autoload; telas e agentes em paralelo mexem nas mesmas chaves de `S` | Média (cresce com o time e com os agentes em paralelo) | ~570 referências; schema implícito | Fachadas por domínio (`CareerState` tipado com acessores), injetar `state` nas funções puras de `Cups`/`Pro`/`match_sim`; telas não chamam `save()` e sim `Game.mark_dirty()` |
| R7 | Saves síncronos na thread principal mesmo hoje: 40–375 ms estimados no celular por jogo, somando travadas na transição entre partidas | Média | 12–75 ms medidos | Salvar no fim do frame com "dirty flag" e agrupar; serializar fora da thread principal (ADR-C) |
| R8 | Disco e tamanho do APK duplicados: o zip de 20,7 MB no APK mais ~29 MB extraídos | Média | Medido | Faz parte da ADR-A (escudos já dentro do pacote do jogo, sem extrair) |
| R9 | Falta de testes justamente nas áreas de maior risco (save, migração, datapack, regras de `game.gd`); `all_leagues` sem asserções e usando o `user://` real | Média | Árvore `tests/` | Testes de ida e volta do save, de migração com saves "fósseis" versionados em `tests/fixtures/saves/`, de importação com um zip pequeno; transformar `all_leagues` em teste com asserções e `user://` isolado |
| R10 | Inicialização: `pack.dat` (270 KB) e `World` (const grande) carregados no boot; 0,3–0,7 s estimados no celular | Baixa | 100–147 ms medidos | Ficar de olho; carregar o `pack.dat` sob demanda, depois da primeira tela |

---

## 4. Decisões recomendadas (ADRs curtas)

### ADR-A — Datapack pré-processado no build, importação de usuário em segundo plano

- **Status**: Proposto
- **Contexto**: a importação em tempo de execução custa O(n²) por causa de `ZIPReader.read_file` e roda na thread principal. Foram 97 s aqui; no celular a estimativa é de 5–8 min. Duplica ~50 MB em disco. É a primeira experiência do jogador.
- **Decisão**:
  1. O **datapack que vem com o jogo** deixa de ser importado no aparelho. Uma ferramenta de build (`tools/asset-pipeline/`, script `@tool` ou headless) gera, a partir do `datapack.zip`: `pack.dat`/`players.dat` prontos e os escudos/placas como arquivos dentro de `res://` (importados pelo Godot), ou como atlas por liga. O APK leva só isso; nada é extraído para `user://` na primeira abertura.
  2. A **importação de um datapack do usuário** (opcional) roda em `WorkerThreadPool`, com barra de progresso, e é **retomável**: grava num diretório `datapack.tmp/` e só troca para `datapack/` no fim (`rename`). A leitura do zip fica linear. Opções: dividir o pacote em vários zips menores (ex.: por pasta ou de 200 em 200 arquivos), ou validar uma leitura sequencial que não precise localizar cada entrada pelo nome.
  3. `PACK_VER` continua; o jogo só reimporta se a versão do pacote for maior.
- **Consequências**: (+) primeira abertura instantânea; −20 a 29 MB em disco; elimina o aviso de travamento. (−) passo extra no build; o datapack do jogo fica "congelado" por versão do app.
- **Desempenho**: meta de primeira abertura até a tela inicial em menos de 3 s no celular de referência.
- **Dependências de ADR**: nenhuma. **Compatibilidade com o motor**: Godot 4.5 (`WorkerThreadPool`, `ZIPReader`, importação de `.webp` em `res://`); confirmar em `docs/engine-reference/godot/`. **Requisitos de GDD**: nenhum GDD formal; atende ao requisito de plataforma Mobile do `project.yaml`.
- **Alternativas rejeitadas**: só mover a importação atual para uma thread (continua levando minutos, só não trava); manter e mudar o texto da tela (não resolve).

### ADR-B — Save versionado, atômico e com migração em cadeia

- **Status**: Proposto
- **Contexto**: escrita não atômica a cada jogo; `ver` ignorado; referências por índice em `World.LEAGUES`; os defaults espalhados (`S.get`) viram migração implícita e não testada. O jogo vai receber atualizações com ligas, copas e modos novos.
- **Decisão**:
  1. **Envelope** do arquivo: `{"magic": "CRAQUE", "ver": N, "meta": {...cartão do slot...}, "data": S}`. O `peek_save` lê só `meta` (ou um `carreira_N.meta` separado).
  2. **Escrita atômica**: grava em `carreira_N.sav.tmp`, fecha, confere o tamanho, renomeia o `.sav` atual para `.sav.bak` e o `.tmp` para `.sav`. Se o `.sav` falhar ao carregar, usa o `.bak` e avisa o jogador.
  3. **Migração em cadeia**: `SaveMigrations.migrate(d)` aplica `_v2_to_v3`, `_v3_to_v4` e assim por diante até a versão atual. Cada passo é uma função pura e testada. Os `S.get(...)` de compatibilidade migram para lá aos poucos.
  4. **IDs estáveis no lugar de índices**: o save guarda `league_key` (ex.: `norm(nome)` ou id do datapack) e `club_key` além do índice. No load, os índices são resolvidos pela chave, e o load falha com mensagem clara se a liga não existir mais.
  5. **Regra de time**: qualquer PR que mude a forma de `S` sobe `SAVE_VER` e traz a migração junto, com teste.
- **Consequências**: (+) carreiras sobrevivem a quedas e atualizações; (+) cartão do slot sem ler o save inteiro. (−) disciplina por PR; um pouco mais de código no save/load.
- **Desempenho**: o rename é desprezível; o `.bak` dobra o espaço por slot (~1–2,5 MB hoje).
- **Validação**: testes com saves "fósseis" de cada versão publicada em `tests/fixtures/saves/`, carregando e jogando uma rodada; teste que simula arquivo truncado e confere o uso do `.bak`.
- **Dependências de ADR**: nenhuma (a ADR-C depende desta). **Compatibilidade com o motor**: Godot 4.5 (`FileAccess`, `DirAccess.rename`); o formato binário de Variant pode mudar entre versões do motor, mais um motivo para o envelope versionado. **Requisitos de GDD**: carreira persistente com 4 slots.
- **Alternativas rejeitadas**: `ResourceSaver` com `.tres` (mais lento e frágil quando scripts mudam de nome); JSON puro (4–10x mais lento no `stringify` medido e perde tipos `int`/`float`).

### ADR-C — Formato de save compacto e salvamento fora do caminho crítico

- **Status**: Proposto (prioridade sobe para obrigatória **antes** de qualquer decisão de simular todas as ligas)
- **Contexto**: ~900 B por jogador porque `store_var` repete as chaves string de cada dicionário de jogador. Um save por jogo na thread principal. A projeção com o mundo inteiro simulado dá 11–12 MB e 0,5–1,2 s por jogo.
- **Decisão**:
  1. **Comprimir**: `FileAccess.open_compressed(path, WRITE, COMPRESSION_ZSTD)` + `store_var`, ou `var_to_bytes().compress(ZSTD)`. Medido: tamanho cai para cerca de 9%. É a mudança mais barata e vem junto com o envelope da ADR-B.
  2. **Agrupar**: `Game.mark_dirty()` + um único `save` no fim do frame ou na transição de tela, e sempre em `NOTIFICATION_APPLICATION_PAUSED`/`WM_CLOSE_REQUEST` (Android).
  3. **Thread**: tirar uma cópia (`var_to_bytes(S)` na thread principal, que é rápido) e comprimir/gravar no `WorkerThreadPool`.
  4. **Se e quando** o mundo inteiro for simulado: jogadores em tabela por colunas (arrays empacotados por atributo, ou array de arrays com schema fixo) e só os clubes "ativos" com elenco completo; os demais com elenco resumido gerado de forma determinística por seed.
- **Consequências**: (+) save 10x menor e sem travada visível; (+) espaço para crescer. (−) o arquivo deixa de ser legível com `get_var` simples (precisa do helper); a tabela por colunas só vale o custo se o mundo inteiro for simulado.
- **Desempenho**: meta de save no celular de referência em menos de 16 ms na thread principal (só a cópia) e arquivo menor que 300 KB comprimido no maior caso de hoje.
- **Dependências de ADR**: ADR-B (envelope e versão). **Compatibilidade com o motor**: Godot 4.5 (`FileAccess.open_compressed`, `COMPRESSION_ZSTD`, `WorkerThreadPool`). **Requisitos de GDD**: nenhum GDD formal; condicionado à decisão de design de simular todas as ligas.
- **Alternativas rejeitadas**: SQLite via GDExtension (dependência nativa por plataforma, desnecessária nesta escala).

---

## 5. Outras recomendações (sem ADR)

1. **Cache de texturas com teto (R5)**: LRU em `DataPack._load_tex` (ex.: 256 entradas) e em `_ads` (3 conjuntos); nas listas, usar uma versão de 64 px (no build, junto com a ADR-A).
2. **Desacoplamento gradual (R6)**: começar pelas funções puras (`Cups`, `match_sim`, regras de mercado), que passam a receber `state: Dictionary` por parâmetro em vez de ler `Game.S`. As telas param de chamar `Game.save()`. Não é big-bang: fazer um módulo por sprint, depois que os agentes atuais terminarem.
3. **Testes (R9)**: (a) ida e volta do save, conferindo que `S` é idêntico depois de save + load; (b) migração com fósseis; (c) `import_zip` com um zip de teste de cerca de 20 arquivos; (d) `all_leagues` com asserções (toda copa com campeão, clubes sem escudo abaixo de X), `user://` isolado e no CI com tempo limite; (e) teste de desempenho que falha se `save()` passar de um orçamento no maior caso.
4. **Orçamentos propostos** (celular de referência a definir pelo usuário): primeira abertura em menos de 3 s; save em menos de 16 ms na thread principal; load de carreira em menos de 500 ms; RAM total em menos de 350 MB; save menor que 300 KB comprimido.

## 6. Validação

Saberemos que as decisões estão certas se:
- A primeira abertura num Android intermediário real chegar à tela inicial em menos de 3 s, sem aviso de travamento (medir antes e depois).
- Matar o app no meio de uma rodada nunca fizer um slot sumir (teste manual com 20 repetições, mais o teste automatizado do `.bak`).
- Uma versão nova com uma liga inserida no meio de `World.LEAGUES` carregar os saves fósseis sem trocar a liga de ninguém.
- O monitor de memória ficar estável depois de navegar por todo o datapack.

> Pendente: confirmar os números de celular num aparelho real. A estimativa de 3–5x é uma suposição.
