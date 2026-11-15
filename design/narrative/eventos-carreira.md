# Eventos de carreira (narrative-director, 14/11/2026) — proposta, ainda não implementado

## Regras
- Roda no fim de `Pro.after_match()`: chance 30% por jogo, 1 evento por vez, intervalo de 2 jogos, até 8 por temporada.
- Sorteio por `peso` entre os eventos cujo gatilho bate; `uma_vez` e `cooldown_temporadas` evitam repetição.
- Escolhas mexem nas variáveis já existentes (fama, torcida, técnico 0–100; dinheiro em mi; salário em mil/sem; polêmicas).
- "Cobrança": a escolha pode ter efeito no jogo seguinte conforme a nota (provocou e jogou bem = bônus; jogou mal = torcida cobra).
- Arquivo de dados proposto: `assets/data/pro_events.json` (versao, config{chance_por_jogo, cooldown_jogos, max_por_temporada}, eventos[ {id, titulo, categoria, peso, uma_vez, cooldown_temporadas, gatilho{fama, idade, forca_clube, fase, tecnico, torcida, contrato_anos, momento, no_exterior, proximo, lesionado, empresario_min, jogos_no_banco_min, temporadas_no_clube_min, flags_com, flags_sem}, texto, escolhas[ {id, texto, chance, efeitos, efeitos_falha, resultado, resultado_falha, cobranca{nota_min, efeitos, senao, texto_ok, texto_senao}} ]} ]).
- Efeitos: fama, torcida, tecnico, seguidores_pct, dinheiro, dinheiro_sal, multa_sal, polemica, propostas, proposta_especial{tipo: exterior_rico|pais_natal|clube_formador|gigante, salario_mult, luvas_mult}, renovacao{salario_mult}, cancelar_renovacao, xp, energia, lesao_jogos, ausente_jogos, nota_proximo, banco_proximo, patrocinio_risco, flag_add/flag_rem, post_portal/post_meu.
- Mecânicas novas necessárias: nota_proximo, banco_proximo, cobranca, proposta_especial, flags, contador de ausência (não usar `banned`).

## Exemplos completos
- **classico_provocacao** (fama ≥ 10, próximo jogo é clássico): responder em campo (+técnico, +torcida, +0,2 na nota) / provocar (60%: +fama, +seguidores, −técnico; falha: multa; cobrança nota ≥ 7: +fama +torcida, senão −torcida) / ignorar.
- **proposta_arabe** (fama ≥ 35, 27–34 anos, meio/fim de temporada, com empresário): aceitar (proposta 3× salário, −torcida) / recusar (+torcida, +fama) / usar para renovar (50%: +25% salário).
- **mae_saudade** (jogando fora do país, uma vez): pedir clube no Brasil / trazer a família (+energia) / visitar (1 jogo ausente, +torcida).
- **lesao_vespera_final**: jogar no sacrifício (60%; falha = 5 jogos lesionado) / ficar fora (+técnico) / começar no banco.
- **balada_vazada** (fama ≥ 15): pedir desculpas (multa leve) / desculpa esfarrapada (50%; falha = multa pesada e manchete) / bancar (seguidores, polêmica, risco de patrocínio, cobrança nota ≥ 7,5).

## Os outros 27 (gatilho → escolhas)
tecnico_novo_desconfia, renovacao_travada, assedio_rival_nacional, jornalista_perseguidor, convocacao_vs_clube, convite_influencer, primeiro_salario, bracadeira_capitao, penalti_perdido, vaia_da_torcida, conselho_do_veterano, dancinha_viral, escolinha_na_quebrada, patrocinio_concorrente, organizada_no_ct, apelido_do_narrador, mundial_sub20, gigante_europeu_sonda, audio_vazado, nascimento_do_filho, tatuagem_do_escudo, desfile_carnaval, clube_formador_chama, encostado_no_banco, despedida_do_idolo, capa_de_videogame, bate_boca_na_falta.

## Decisões sugeridas
- Frequência 30% por jogo; clube "árabe" = liga mais rica de fora do país; clássico = adversário forte e próximo na tabela.
