# Relatório de Desempenho — Craque Manager (parcial)

**Data:** 2026-11-14 · **Autor:** performance-analyst · **Status:** PARCIAL. A importação do datapack e os escudos já foram medidos. Partida, rodada, temporada e telas estão pendentes (ver seção 5).

## 1. Ambiente e método

| Item | Valor |
|---|---|
| Motor | Godot 4.5.1-stable (oficial), GL Compatibility |
| Máquina de medição | Intel Xeon 2,3 GHz, 2 vCPU, 8 GB RAM, Linux, `--headless` |
| Código medido | Cópia de `src/` feita em 2026-11-14 às 15:54 para `/tmp/perf/proj` (user:// isolado em `craque_perf`, para não mexer nos saves nem no datapack do projeto). `field_view.gd` md5 `e114973e…`, `lance_view.gd` md5 `f451d7a6…`, `screens_cup.gd` md5 `e9a373bb…` (já com a correção do `_cups_call`) |
| Script | `/tmp/perf/proj/perf/perf_all.gd` (modos `import`, `sim`, `screens`, `match`), `/tmp/perf/proj/perf/zip_test.gd` |
| Datapack | `res://datapack.zip`: 20,7 MB, 5204 arquivos, todos com Deflate. São 4122 escudos de clube (120×120 webp), 152 logos de competição e cerca de 900 placas |
| Celular médio | Estimativa de **4–6x mais lento** que esta máquina em CPU e E/S. É um fator assumido e não foi medido em aparelho. Na E/S em flash do Android, o fator real pode ser maior |

Os números de memória são `OS.get_static_memory_usage()` (memória do motor). A leitura do RSS por `/proc/self/status` falhou no script (deu 0) e **não foi medida**. No modo headless o renderizador é o dummy, então o custo de envio de textura para a GPU não aparece aqui.

## 2. Medições

| Medição | Servidor | Celular estimado (4–6x) | Observação |
|---|---|---|---|
| **Importação completa do datapack** (`DataPack.import_zip`) | **70,3 s** | **4,7–7,0 min** | A tela de importação diz "pode levar até 1 minuto" |
| Abrir o zip + `get_files()` | 27 ms | 0,1–0,16 s | Barato |
| **Só ler os 4122 escudos do zip** (`zip.read_file`) | **38,9 s** | **2,6–3,9 min** | 14,9 MB lidos |
| `_copy_images` dos escudos (ler + gravar) | 39,4 s | 2,6–3,9 min | Gravar no disco custa só cerca de 0,5 s. Quase todo o tempo vai na leitura do zip |
| Restante da importação (logos de competição, placas, CSVs, `pack.dat`) | ~31 s (por diferença) | 2,1–3,1 min | São os arquivos que ficam no fim do zip (ver causa) |
| `players.csv` (69.223 nomes) | 136 ms | 0,5–0,8 s | |
| `read_file` de um escudo **no início** do zip | 0,5 ms | 2–3 ms | |
| `read_file` de um escudo **no fim** do zip | **20–32 ms** | 80–190 ms | O custo cresce com a posição do arquivo |
| Pico de memória do motor durante a importação | 71,6 MB (base 29,5 MB) | igual | +42 MB transitórios |
| `DataPack.ensure()`: carga fria do `pack.dat` (5272 clubes, 275 KB) | 109 ms | 0,45–0,65 s | Acontece em **toda abertura do app** (`main._first_run_import` → `loaded()`) |
| `DataPack.pack_id()` por chamada | 51 µs | 0,2–0,3 ms | Chama `norm()` (19 `replace` + laço por caractere) duas vezes |
| Decodificar 1 escudo webp (frio) | 0,71 ms | 2,8–4,3 ms | 991 escudos das ligas medidos |
| Decodificar todos os 991 escudos das ligas | 0,70 s | 2,8–4,2 s | |
| `DataPack.logo()` com cache quente | 39 µs | 0,16–0,24 ms | Quase todo o custo é o `pack_id`/`norm` |
| Memória dos 991 escudos em cache (`_tex`) | +49,6 MB | igual, mais VRAM | Cerca de 50 KB por escudo (120×120 RGBA8 = 57,6 KB). O cache nunca é liberado |

## 3. Causa provável dos 39 s de leitura dos escudos

O custo de `ZIPReader.read_file()` **cresce linearmente com a posição do arquivo dentro do zip**: 0,5 ms no 6º arquivo, 20–32 ms nos últimos. Isso indica que cada `read_file` procura o arquivo varrendo o diretório central do zip desde o começo, com busca linear no estilo `unzLocateFile` do minizip. Ler N arquivos um a um custa então O(N²). Com 5204 entradas, a leitura média fica em cerca de 9,5 ms por escudo, e 4122 × 9,5 ms ≈ 39 s.

Dois pontos reforçam essa leitura:
- O tempo de `_copy_images` (39,4 s) é praticamente igual ao de só ler (38,9 s). Descompactar e gravar não é o problema.
- Os ~31 s restantes vêm das logos de competição e das placas. Elas ficam **depois** dos escudos no zip, então cada leitura é a mais cara. São apenas cerca de 1050 arquivos, mas a uns 30 ms cada.

Pelo `res://` a leitura é ~1,5x mais cara no fim do zip do que pelo caminho absoluto (32 ms contra 21 ms). No Android o `res://` fica dentro do APK, que também é um zip. A tendência ali é **piorar**, não melhorar. Ponto em aberto: confirmar no código-fonte do Godot 4.5.1 (`modules/zip/zip_reader.cpp`) se a busca é mesmo linear. A curva medida já sustenta a conclusão.

## 4. Gargalos medidos (prioridade) e recomendações

| # | Gargalo | Impacto no celular | Recomendação | Ganho estimado | Custo | Dono |
|---|---|---|---|---|---|---|
| 1 | **Importação do datapack: 70 s, com leitura O(N²) do zip** | 4,7–7 min na primeira abertura, travando a tela (tudo roda no thread principal) | (a) **Montar o zip como pacote de recursos** (`ProjectSettings.load_resource_pack`). O índice é montado uma vez, então ler cada arquivo vira O(1) e não é preciso extrair nada. (b) Se a extração for mantida, juntar os escudos em **um único arquivo binário** (blob + tabela de offsets, ou atlas), lido uma vez só. (c) No mínimo, rodar a importação num `Thread`/`WorkerThreadPool`, com barra de progresso, e corrigir o texto "até 1 minuto" | (a)/(b): de 70 s para **poucos segundos** (estimativa, a confirmar). (c): não reduz o tempo, mas tira o travamento | (a) médio, (b) médio, (c) baixo | engine-programmer (`src/datapack.gd`) |
| 2 | **Cache de escudos sem limite** (`DataPack._tex`) | +50 MB por ~1000 escudos, e cresce ao navegar por ligas e copas. Risco de matar o app em aparelhos de 2–3 GB | LRU com limite (ex.: 150 texturas). Ou reduzir os escudos para 64×64 / compressão ETC2 quando o tamanho de exibição for ≤ 58 px (o maior `Crest.make` é 120 px só no campeão e na abertura) | −70% a −90% de memória de escudos | baixo | engine-programmer |
| 3 | **`pack_id()`/`norm()` a cada chamada** (51 µs) | 0,2–0,3 ms por escudo desenhado, por `club_name` e por `stadium`. Uma tela com ~130 escudos (chaveamento de 64) paga ~25–40 ms só nisso ao montar | Memoizar `pack_id(li, ci)` num `Dictionary`, ou pré-calcular os nomes normalizados uma vez. No `Crest`, guardar a textura em `_ready` em vez de buscar em cada `_draw` | Chamada quente de 39 µs para ~1 µs (−95%) | baixo | engine-programmer (`datapack.gd`, `crest.gd`) |
| 4 | **Decodificar escudos no thread principal** (0,71 ms cada) | 2,8–4,3 ms por escudo frio. Uma tabela de 24 clubes custa ~70–100 ms e um chaveamento de 64 clubes ~0,2–0,3 s de travada ao abrir pela primeira vez | Pré-carregar os escudos da liga da carreira em segundo plano (`WorkerThreadPool`) ao carregar a carreira, ou mantê-los já como `CompressedTexture2D` importadas no PCK | Some a travada da primeira abertura das telas | baixo-médio | engine-programmer |
| 5 | **Carga fria do `pack.dat` em toda abertura** (109 ms) | 0,45–0,65 s a mais no boot | Carregar sob demanda num thread, ou dividir em `clubs.dat` (pequeno) e `rosters.dat` (só ao criar carreira). Também dá para pré-calcular `_byname` na importação em vez de chamar `norm()` 5272 vezes a cada boot | −50% a −80% desse tempo | baixo | engine-programmer |

## 5. Pendente (ainda não medido)

Estas medições estão no script, mas **não foram executadas** antes deste relatório:

- Tempo por quadro do `FieldView` (22 bonecos): `_process`, `_draw`, draw calls e primitivas, em headless e com xvfb (`--rendering-driver opengl3`).
- Tempo por quadro do `LanceView`: `setup`, `_process` e `_draw`.
- `Game.play_round` por rodada, na maior liga (MLS: 28 clubes, li=19) e nas de 24 clubes (EFL Championship, li=10).
- Temporada inteira (`play_next` até `season_over`, com copas) e `new_season`.
- Montagem da tabela e do chaveamento (frio/quente, número de nós, primeiro quadro).

**Hipóteses da leitura do código, a confirmar com medição** (não são resultados):
- `Game.squad(cid)` percorre **todos** os jogadores e ordena a cada chamada. É chamado dentro de laços: `auto_lineup` de todos os clubes a cada rodada em `_between_rounds`, e `new_career` chama `squad(c)` a cada jogador do elenco (O(clubes × elenco × jogadores)). Candidato forte a gargalo da rodada e da criação de carreira.
- `Game.save()` grava o estado inteiro (`store_var(S)`) a cada rodada e a cada fase de copa. Um save observado (`carreira_8.sav`) tem 1,06 MB, e no celular isso pode custar dezenas de ms por rodada.
- O `_draw` dos `Crest` só roda ao montar ou redimensionar (o Godot guarda os comandos do canvas em cache), então rolar a tabela não deve repetir esse custo. Falta confirmar.

## 6. Regressões

Nenhuma comparação possível: este é o primeiro relatório e não há perfil anterior.
