# Partida em campo e árbitro

## Overview
Cada chance de gol vira um lance jogado em campo (src/lance_view.gd), com física
da bola (src/ball_physics.gd) e regras do árbitro (src/referee.gd). Os minutos
sem lance são simulados em src/match_sim.gd, que também apita faltas, cartões,
impedimentos e pênaltis. Expulso cumpre suspensão no jogo seguinte (src/game.gd).

## Detailed Rules
- **Passe rasteiro** (toque no companheiro): rola no chão e perde velocidade pelo atrito.
  Erro de mira cresce com passe ruim e com marcador perto.
- **Passe alto** (segurar o dedo): sobe e cai no alvo; passa por cima da zaga.
  Dentro da área vira cruzamento e o recebedor cabeceia.
- **Corte**: cada defensor tem uma tentativa por passe, depois de reagir;
  chance depende de desarme contra passe e da velocidade da bola.
- **Chute**: toque no gol = chute colocado (fundo da rede = alto); deslizar = força.
  Muita força sobe a bola (pode passar por cima). Trave, travessão, por cima e fora.
- **Goleiro**: reage depois de um tempo e se joga para onde a bola cruza a linha;
  alcança até alcance_lateral para o lado e alcance_alto para cima.
- **Zaga**: linha única que acompanha a bola (é a linha de impedimento); um defensor
  dá o bote, o vizinho faz a cobertura, volantes fecham a linha de passe.
- **Árbitro**: bote pode virar falta; falta na área = pênalti; perto da área = falta
  direta com barreira; com a bola seguindo, às vezes lei da vantagem. Segundo
  amarelo = vermelho. Expulso sai do lance e o time perde força.
- **Impedimento**: julgado no momento do passe, contra o penúltimo defensor ou a bola.

## Tuning Knobs — assets/data/match_tuning.json
Medidas em metros, segundos e probabilidades de 0 a 1.

| Seção | Chave | O que faz |
|---|---|---|
| bola | gravidade, atrito_grama, arrasto_ar, quique | queda, rolagem, freio no ar, altura do quique |
| passe | velocidade_rasteiro_min/max | velocidade do passe rasteiro (m/s) |
| passe | altura_passe_alto, altura_cruzamento | altura máxima da bola (m) |
| passe | erro_base_graus, erro_por_ponto_faltando, erro_pressao_graus, distancia_pressao | erro de mira do passe |
| passe | alcance_corte_pe, alcance_corte_cabeca, altura_max_corte_pe/cabeca, reacao_corte, chance_corte_base | corte da zaga |
| passe | chance_dominio_alto, toque_longo_segundos | domínio de bola alta; tempo de segurar para passe alto |
| chute | velocidade_min/max, subida_por_forca, erro_* , velocidade_cabeceio, chance_travar, arraste_para_forca_maxima_px | chute e cabeceio |
| goleiro | reacao_base, reacao_por_ponto_faltando, velocidade_base, velocidade_por_ponto, alcance_lateral, alcance_alto, chance_espalmar_canto_alto | goleiro |
| zaga | profundidade_linha, linha_minima, linha_maxima, compactacao, deslocar_para_bola, distancia_cobertura | organização da defesa |
| arbitro | chance_falta_no_bote, chance_amarelo_na_falta, chance_vermelho_direto, chance_vantagem, vitoria_bote_base, cuidado_com_amarelo | botes, faltas e cartões |
| arbitro | faltas_por_minuto_por_time, chance_impedimento_ataque_simulado, chance_penalti_ataque_simulado, chance_gol_penalti_simulado | jogo simulado |
| arbitro | perda_forca_expulsao, jogos_suspensao_vermelho, distancia_falta_direta | expulsão e falta direta |

## Acceptance Criteria (tests/run_tests.tscn)
- Passe alto cai a menos de 1,6 m do alvo; passe rasteiro para sozinho.
- Temporada simulada: 2,0–3,4 gols, 18–32 faltas, 2,5–6 amarelos e 0,05–0,45 vermelho por jogo.
- 300 lances jogados sozinhos: nenhum trava; gols, defesas, cortes e impedimentos acontecem.
- Rodada simulada em menos de 120 ms; lógica do lance em menos de 2 ms por quadro.
