# Equilíbrio da partida simulada — real × jogo

Escopo: `src/match_sim.gd` (jogo simulado, minuto a minuto), `src/referee.gd` e as chaves de
`assets/data/match_tuning.json`. Data: 2026-11-14.

## Como os números foram obtidos (leia antes)

- **Números do jogo: calculados, não rodados.** Esta sessão não tinha shell (sem Godot, sem
  script em /tmp) nem busca na web. As médias abaixo saem das fórmulas exatas de
  `MatchSim.step()`, com valor esperado e distribuição de Poisson para os placares. A margem
  é de ±5% nas médias e ±3 pontos percentuais nos resultados (o jogo sorteia por minuto,
  o que dá um pouco mais de empates que a Poisson).
  **Antes de aplicar, confirme com a suíte** (`test_match_balance.gd`) ou com um script de medição.
- **Números reais: de memória, aproximados, sem conferência na web nesta sessão.** São médias
  de várias temporadas recentes (Premier League 2022/23–2024/25, Brasileirão 2022–2025).
  Confira em FBref, Footystats ou ogol antes de fechar.
- Hipótese: nota do setor ≈ força do clube (`str` em `world_data.gd`), com energia parecida
  nos dois times. Com elencos do datapack, as notas reais podem fugir disso.

## Fórmulas usadas (como estão no código)

Por minuto: posse do mandante `P_m = 1,03·mei_m / (1,03·mei_m + mei_v)`. Quem tem a bola
cria um ataque com probabilidade `A = 0,30`. Em cada ataque simulado, nesta ordem:

```
impedimento        p_imp
pênalti            (1 − p_imp) · p_pen                      → gol com p_gp
chute              (1 − p_imp)(1 − p_pen) · clamp(0,36·R, 0,1, 0,7)
gol no chute       pg = clamp(0,26 · R^1,6, 0,08, 0,6)
R = atq_ataque / def_defesa  (× 1,04 se for o mandante)
gols esperados do lado = 90 · posse · A · [(1−p_imp)(1−p_pen)·chute·pg + (1−p_imp)·p_pen·p_gp]
```

| Símbolo | Tipo | Faixa | Descrição |
|---|---|---|---|
| mei_m, mei_v | int | 40–94 | nota de meio-campo do mandante / visitante |
| A | float | 0,30 (fixo no código) | chance de um minuto virar ataque |
| R | float | ~0,7–1,4 na prática | atq de quem ataca / def de quem defende |
| p_imp | float | 0–1 (JSON 0,06) | `chance_impedimento_ataque_simulado` |
| p_pen | float | 0–1 (JSON 0,022) | `chance_penalti_ataque_simulado` |
| p_gp | float | 0–1 (JSON 0,76) | `chance_gol_penalti_simulado` |
| pg | float | 0,08–0,60 (clamp) | chance de um chute virar gol |
| gols | float | ~0,4–3,0 por lado | gols esperados do lado no jogo |

Saída limitada: o chute fica entre 0,1 e 0,7 e o `pg` entre 0,08 e 0,6, então nenhum lado passa de
~90·1·0,3·0,7·0,6 ≈ 11 gols nem fica abaixo de ~0,2 gol. Não há valor inválido.

**Exemplo (times iguais, nota 75):** mandante R = 1,04 → chute 0,374, pg 0,277, posse 50,7%
→ 13,7 ataques → 4,7 chutes → 1,31 gol de jogada + 0,22 de pênalti = **1,52**.
Visitante: R = 1 → chute 0,36, pg 0,26 → **1,35**. Total **2,87 gols**.

Cartões: `card_for_foul()` é cumulativo. Vermelho = `chance_vermelho_direto`; amarelo =
`chance_amarelo_na_falta − chance_vermelho_direto` (hoje 0,184). O segundo amarelo depende do
peso de sorteio por posição (concentração ≈ 0,108) e de `cuidado_com_amarelo`.

## Tabela real × jogo (média por partida, valores atuais do JSON)

| Estatística | Brasileirão (real, aprox.) | Premier League (real, aprox.) | Jogo hoje (calculado) | Avaliação |
|---|---|---|---|---|
| Gols | 2,3–2,5 | 2,8–3,3 (média longa ~2,8) | **2,87** | alto para o Brasileirão; ok para a PL |
| Gols mandante / visitante | ~1,45 / ~1,00 | ~1,6 / ~1,3 | **1,52 / 1,35** | mando fraco demais (razão 1,12; real 1,25–1,45) |
| Chutes no alvo | ~8 | ~8,5–9 | **9,6** (`shots`) | ok se `shots` = no alvo |
| Finalizações totais | ~23 | ~25 | não existe | o jogo não conta chute para fora |
| Posse do mandante (média) | ~51–52% | ~51–52% | 50,7% | ok |
| Posse forte × fraco | 60–65% | 62–70% | **54,7%** (81 × 69) | achatada |
| Faltas | 25–27 | 20–22 | **~24** | no meio; um pouco baixo para o Brasileirão |
| Amarelos | 5,0–5,5 | 3,5–4,2 | **~4,0** | baixo para o Brasileirão; ok para a PL |
| Vermelhos | 0,25–0,30 | 0,12–0,18 | **~0,27** | ok para o Brasileirão |
| Impedimentos | 3,5–4 | 3,5–4 | **1,6** | metade do real |
| Pênaltis marcados | 0,35–0,40 | 0,28–0,32 | **0,56** | +40–80% |
| Conversão de pênalti | ~0,76 | ~0,78 | 0,76 | ok |
| % gols de pênalti | ~11% | ~9% | **~15%** | alto |
| Vitória mandante / empate / visitante | ~49 / 27 / 24% | ~45 / 24 / 31% | **~41 / 25 / 34%** | mando bem abaixo do Brasileirão |

### Zebra por diferença de força (mandante favorito × visitante)

| Confronto | Real (odds típicas do Brasileirão) | Jogo hoje (calculado) |
|---|---|---|
| Iguais (75 × 75) | 46 / 28 / 26 | 41 / 25 / 34 |
| Diferença de 4 (77 em casa × 73) | ~52 / 26 / 22 | 51 / 23 / **26** |
| Diferença de 12 (81 em casa × 69) | ~68 / 20 / 12 | 70 / 17 / **12** |
| Diferença de 12 com o fraco em casa (69 × 81) | zebra (vitória do 69) ~23%, favorito ~50% | zebra **~17%**, favorito ~60% |

Leitura: o peso da força está bom (a fórmula `R^1,6` acerta o favorito forte em casa). O que está
fora é o **mando de campo**: sozinho ele vale pouco (×1,04 e ×1,03), por isso o time fraco
quase não arranca resultado em casa, e jogos equilibrados viram demais para o visitante.

## Ajustes sugeridos — cada chave do match_tuning.json

Meta escolhida: **Brasileirão** (liga padrão, `league_idx 0`). Com os ajustes, a previsão é
2,57 gols, 25,6 faltas, ~4,8 amarelos, ~0,27 vermelho, 3,2 impedimentos e 0,35 pênalti por jogo.
Tudo continua dentro das faixas do teste atual.

### arbitro (jogo simulado — é aqui que estão os ganhos)

| Chave | Atual → Sugerido | Motivo |
|---|---|---|
| chance_penalti_ataque_simulado | 0,022 → **0,014** | 0,56 → 0,35 pênalti/jogo; gols de pênalti 15% → ~10%; tira ~0,15 gol/jogo. Também baixa o pênalti no lance jogado (×4 = 8,8% → 5,6%). |
| chance_impedimento_ataque_simulado | 0,06 → **0,12** | 1,6 → 3,2 impedimentos/jogo (real 3,5–4). Como o impedimento vem antes do chute, corta ~6% dos chutes e gols, o que ajuda a baixar os gols para o nível do Brasileirão. No lance jogado, 12% → 24% de chance de "offside" no roteiro: acompanhar no teste de lances. |
| faltas_por_minuto_por_time | 0,13 → **0,14** | 24 → 25,6 faltas/jogo (Brasileirão 25–27). |
| chance_amarelo_na_falta | 0,19 → **0,21** | amarelo por falta 0,184 → 0,205; ~4,0 → ~4,8 amarelos/jogo (Brasileirão 5,0–5,5). |
| chance_vermelho_direto | 0,006 → **0,005** | com mais faltas e mais amarelos, segura os vermelhos em ~0,27 (direto ~0,13 + segundo amarelo ~0,14). |
| cuidado_com_amarelo | 0,75 → **0,80** | com mais amarelos sobem os segundos amarelos; 0,80 mantém a proporção real de ~metade das expulsões por segundo amarelo. |
| perda_forca_expulsao | 0,09 → **0,12** | hoje, com 10, o time faz ×0,78 dos gols e sofre ×1,28. O real fica perto de ×0,70 / ×1,40, e 0,12 dá ×0,72 / ×1,39. O piso de 0,6 está no código. |
| chance_gol_penalti_simulado | 0,76 → 0,76 (manter) | igual ao real (0,75–0,78). |
| jogos_suspensao_vermelho | 1 → 1 (manter) | regra padrão (vermelho = 1 jogo automático). |
| chance_falta_no_bote | 0,20 → 0,20 (manter) | só vale no lance jogado; sem medição nesta sessão. |
| chance_vantagem | 0,35 → 0,35 (manter) | plausível; só no lance jogado. |
| distancia_falta_direta | 30,0 → 30,0 (manter) | ~zona de falta perigosa real (até ~30 m do gol). |
| vitoria_bote_base | 0,20 → 0,20 (manter) | só no lance jogado; sem medição. |

### bola, passe, chute, goleiro, zaga (só o lance jogado em campo)

Essas chaves não entram no jogo simulado, então não mudam nenhuma média da tabela. Elas só
mexem na taxa de gol do lance que o jogador joga, coberta pelo teste de 600 lances. **Sugestão:
manter todas até medir.** Conferência física, sem mudança de valor:

| Chave | Atual | Observação |
|---|---|---|
| bola.gravidade | 9,8 | correto |
| bola.raio | 0,11 | correto (bola tamanho 5) |
| bola.quique | 0,45 | real na grama ~0,5–0,6; aceitável (grama alta) |
| bola.atrito_grama, arrasto_ar | 0,9 / 0,12 | sem referência de unidade no doc; medir passe rasteiro parando ~25–35 m |
| passe.velocidade_rasteiro_min/max | 13 / 24 m/s | plausível (passe real 10–25 m/s) |
| chute.velocidade_min/max | 16 / 31 m/s | plausível (chute forte real 28–35 m/s) |
| goleiro.alcance_lateral | 1,15 m | parece curto para um goleiro que se joga (~2,5–3 m do corpo). Se o deslocamento (velocidade × tempo) já cobre o resto, ok. Medir a % de defesas antes de mudar. |
| goleiro.alcance_alto | 2,55 m | ok (travessão 2,44 m) |
| demais (erro_*, corte_*, zaga.*) | — | manter; precisam de medição no lance |

## Ajustes que o JSON não alcança (números fixos no código)

O maior desvio (mando de campo fraco, posse achatada) depende de constantes escritas direto em
`match_sim.gd`. Isso fere a regra "valores de jogo vêm de config". Sugestão para quem cuida do código,
como chaves novas em `arbitro` ou numa seção `simulacao`:

| Constante no código | Valor | Chave nova sugerida | Sugerido | Efeito |
|---|---|---|---|---|
| `ratio *= 1.04` (mandante) | 1,04 | vantagem_mandante_ataque | **1,12** | razão de gols casa/fora 1,12 → ~1,35; vitória do mandante ~41% → ~47% |
| `mei * 1.03` (posse do mandante) | 1,03 | vantagem_mandante_posse | 1,03 (manter) | posse média do mandante já está certa |
| `mh / (mh + ma)` (posse) | expoente 1 | expoente_posse | **3,0** | 81 × 69: posse 54,7% → ~62% (real 60–65%) |
| `0.30` (ataque por minuto) | 0,30 | chance_ataque_por_minuto | 0,30 | expor só para ajuste por liga |
| `0.36 * ratio` (chute) | 0,36 | chance_chute_base | 0,36 | idem |
| `0.26 * pow(ratio, 1.6)` | 0,26 / 1,6 | chance_gol_chute_base / expoente_forca | **0,25** / 1,6 | com mandante a 1,12 o total sobe ~0,1; 0,25 compensa |
| `maxf(..., 0.6)` (piso da expulsão) | 0,6 | piso_forca_expulsao | 0,6 | ok |

Outros dois pontos para registrar:
- **`shots` mistura no alvo e fora.** O contador entra como "chutes ao gol", mas 3 dos 4 textos de
  chute perdido são para fora ("por cima", "raspa a trave", "cabeceia para fora"). Hoje o número
  (9,6) bate com chutes **no alvo**. O texto ou o rótulo da tela precisa escolher um dos dois.
- **Os padrões do código não batem com o JSON.** Em `referee.gd`, `Tuning.f` usa 0,28 / 0,025 / 0,22
  para falta no bote / vermelho / amarelo, e o JSON tem 0,20 / 0,006 / 0,19. Se o JSON
  não carregar, a partida passa a ter ~0,6 vermelho por jogo. Os padrões do código deveriam ser iguais aos do JSON.

### Premier League (se um dia houver ajuste por liga)

A PL tem mais gols (~2,8–3,0) e menos faltas e cartões (~21 faltas, ~3,8 amarelos, ~0,15 vermelho).
Com um multiplicador por liga: faltas ×0,85, amarelo ×0,85, vermelho ×0,55, gol no chute ×1,10.
Isso não existe hoje. É assunto do game-designer e de quem cuida do código.

## Verificação pendente

1. Rodar `test_match_balance.gd` com os valores sugeridos e anotar gols, faltas, amarelos,
   vermelhos e impedimentos medidos ao lado da previsão acima.
2. Script de medição (2.000+ jogos) para vitória do mandante e zebra por faixa de diferença
   (0–2, 3–6, 7+): o teste atual não mede nenhum dos dois.
3. Conferir os números reais em fonte pública antes de fechar as metas.
