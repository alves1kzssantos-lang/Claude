# Craque Manager — Checklist de regressão manual (celular)

**Tipo:** Integração + UI (teste manual documentado) • **Gate:** BLOCKING antes de cada versão
**Onde rodar:** APK instalado num celular Android real, tela deitada.
**Referências:** `LEIAME.md`, `design/gdd/partida-e-arbitro.md`, `design/gdd/carreira-jogador.md`,
capturas em `production/qa/evidence/` (comparar a tela com a captura citada).

## Como usar

- Marque `[x]` quando o resultado bater **exatamente** com o "Esperado". Qualquer diferença = falha:
  anote o ID do caso e abra um bug em `production/qa/bugs/`.
- Faça os casos na ordem: vários usam a carreira criada em casos anteriores.
- "Trava" = tela parada por mais de 5 s, botão que não responde ou app fechando sozinho. Em
  qualquer caso, trava é falha.
- Antes de começar, preencha:

| Campo | Valor |
|---|---|
| Versão / build do APK | |
| Celular e versão do Android | |
| Data | |
| Testador | |

---

## 1. Primeira abertura e datapack

- [ ] **R01 — Instalação limpa importa o datapack**
  Passos: desinstale o app (apaga os saves) • instale o APK novo • abra.
  Esperado: aparece "Preparando clubes, escudos e estádios…" e em até 1 minuto abre "Minhas carreiras" com o botão **Datapack: ativo** (azul) e as 4 carreiras vazias (ver `jogador_01_carreiras.png`).

- [ ] **R02 — Segunda abertura não importa de novo**
  Passos: feche o app pelo multitarefa • abra de novo.
  Esperado: vai direto para "Minhas carreiras", sem a tela "Preparando clubes…".

- [ ] **R03 — Escudos e nomes vieram do datapack**
  Passos: comece uma carreira de técnico (R06) e abra a lista de clubes do Brasileirão.
  Esperado: clubes com nome real e escudo de imagem (não o escudo genérico gerado por código).

- [ ] **R04 — Tela do datapack**
  Passos: toque em **Datapack: ativo**.
  Esperado: abre a tela com **Escolher arquivo…** e **Remover datapack**; o botão Voltar retorna para "Minhas carreiras".

- [ ] **R05 — APK contém o pacote e o ajuste da partida**
  Passos: em instalação limpa (R01), jogue um lance qualquer.
  Esperado: importação acontece (prova que o `datapack.zip` foi no APK) e o lance funciona normal (prova que `match_tuning.json` foi no APK). Se aparecer "Datapack: nenhum" na primeira abertura, o filtro de exportação `*.zip, *.json` está faltando.

## 2. Criar carreira

- [ ] **R06 — Carreira de técnico**
  Passos: em "Carreira 1", toque **Carreira de técnico** • escolha liga e clube • confirme.
  Esperado: abre a central do clube; voltando ao início, o card mostra escudo, nome do clube, "TÉCNICO • liga • Temporada 1 • 2026".

- [ ] **R07 — Carreira de jogador: criar atleta**
  Passos: em "Carreira 2", toque **Carreira de jogador** • preencha nome, posição, idade, número, país, pé, visual e chuteira • confirme.
  Esperado: todos os campos aceitam o toque; idade só permite 16 a 19 anos; o boneco do visual muda conforme as escolhas (ver `jogador_02_criar.png`, `jogador_03_visual.png`).

- [ ] **R08 — Nome vazio ou muito longo**
  Passos: tente confirmar o atleta com nome vazio; depois com um nome de 40 letras.
  Esperado: não cria atleta sem nome; nome longo não estoura o layout nem trava.

## 3. Peneira e propostas

- [ ] **R09 — Abertura da peneira**
  Passos: após criar o atleta, entre na peneira.
  Esperado: abertura do jogo festivo Peneira Azul × Peneira Branca e depois o campo (ver `jogador_05_peneira_abertura.png`, `jogador_07_peneira_campo.png`).

- [ ] **R10 — Só a bola no seu pé obedece**
  Passos: num lance da peneira, toque na tela quando a bola estiver com um companheiro; depois quando estiver com você (seta dourada).
  Esperado: com o companheiro, o toque não faz nada e ele decide sozinho; com você, o toque executa passe/chute.

- [ ] **R11 — Nota da peneira**
  Passos: termine a peneira.
  Esperado: tela de fim com SUA NOTA, minutos, gols, assistências, lances, chutes, perdas, comentários da rede social e botão **Ver propostas** (ver `jogador_14_peneira_nota.png`). Os números batem com o que aconteceu no jogo.

- [ ] **R12 — Propostas com nota boa**
  Passos: jogue a peneira tentando nota alta (gols) • toque **Ver propostas**.
  Esperado: tela "Escolha seu clube" com 1 ou mais clubes, cada um com papel, salário, anos, luvas e multa rescisória.

- [ ] **R13 — Propostas com nota ruim**
  Passos: nova carreira de jogador • na peneira erre de propósito (chute por cima, perca a bola) • ver propostas.
  Esperado: aparece pelo menos uma proposta (time de base do clube mais fraco). Nunca fica sem nenhuma.

- [ ] **R14 — Negociar e recusar na peneira**
  Passos: em uma proposta toque **Negociar**; depois, se houver mais de uma, **Recusar** outra.
  Esperado: Negociar mostra um aviso com o resultado e o valor muda ou a proposta é mantida; Recusar remove só aquela. Com uma proposta só, o botão Recusar não aparece.

- [ ] **R15 — Aceitar proposta**
  Passos: toque **Aceitar**.
  Esperado: aviso de contrato assinado; abre o hub com as abas 01 JOGOS a 05 VIDA; cabeçalho mostra nome, número, clube novo, posição, força, idade; rede social tem post "novo reforço" (ver `jogador_18_rede_social.png`).

## 4. Partida com lances (fazer com a carreira de técnico e repetir R16/R17 na de jogador)

- [ ] **R16 — Abertura e campo**
  Passos: na central, toque para jogar a próxima partida.
  Esperado: aparece a abertura com a logo do campeonato e depois o jogo ao vivo com placar, minuto e escudos (ver `campo_01_ao_vivo.png`).

- [ ] **R17 — Lance de ataque pausa e fica cinza**
  Passos: espere uma chance de gol do seu time.
  Esperado: abre o campo visto de cima, o jogo pausa e fica cinza esperando seu toque; aparece a linha tracejada de impedimento (ver `lance_01_decisao.png`).

- [ ] **R18 — Passe rasteiro**
  Passos: toque rápido em um companheiro atrás da linha tracejada.
  Esperado: a bola rola no chão até ele e vai perdendo velocidade; ele recebe ou um zagueiro corta.

- [ ] **R19 — Passe alto**
  Passos: segure o dedo sobre um companheiro fora da área.
  Esperado: a bola sobe, passa por cima da zaga e cai perto dele.

- [ ] **R20 — Cruzamento e cabeceio**
  Passos: segure o dedo sobre um companheiro dentro da área.
  Esperado: a bola vem alta (cruzamento) e o recebedor cabeceia para o gol (gol, defesa, por cima ou fora).

- [ ] **R21 — Impedimento**
  Passos: passe para um companheiro que está à frente da linha tracejada.
  Esperado: o árbitro marca impedimento e o lance termina sem gol.

- [ ] **R22 — Chute tocando dentro do gol**
  Passos: com a bola no pé, toque dentro do gol (parte baixa); em outro lance, toque no fundo da rede.
  Esperado: chute colocado na direção do toque; tocando no fundo da rede a bola vai alta. Resultado aparece (gol, defesa, trave, fora) (ver `lance_04_chute.png`, `lance_05_resultado.png`).

- [ ] **R23 — Chute deslizando o dedo**
  Passos: deslize o dedo curto até o gol; em outro lance, deslize bem longo.
  Esperado: direção segue a mira; deslize curto = chute fraco; deslize longo = chute forte, que pode subir e passar por cima do travessão.

- [ ] **R24 — Goleiro reage**
  Passos: chute colocado no canto e depois no meio.
  Esperado: o goleiro se joga para o lado da bola; às vezes defende, às vezes espalma; nunca fica parado com a bola passando no meio dele sem reação.

- [ ] **R25 — Falta perto da área (barreira)**
  Passos: jogue lances até sofrer um bote perto da área (ou repita jogos).
  Esperado: árbitro marca falta, aparece a barreira e você cobra tocando/deslizando no gol.

- [ ] **R26 — Pênalti**
  Passos: jogue até sofrer falta dentro da área.
  Esperado: árbitro marca PÊNALTI; cobrança com o goleiro na linha; o placar só muda se for gol.

- [ ] **R27 — Lei da vantagem**
  Passos: em vários botes com a bola seguindo, observe.
  Esperado: às vezes aparece VANTAGEM e o lance continua sem parar.

- [ ] **R28 — Cartões e expulsão**
  Passos: jogue (ou simule) partidas até aparecer cartão.
  Esperado: amarelo aparece no comentário; segundo amarelo do mesmo jogador vira vermelho; expulso sai do lance e o time fica com um a menos.

- [ ] **R29 — Suspensão no jogo seguinte**
  Passos: após uma expulsão no seu time, vá para a próxima partida e veja a escalação.
  Esperado: o expulso não pode ser escalado nesse jogo; volta no jogo depois.

- [ ] **R30 — Ataque do adversário e "Pular"**
  Passos: espere um lance do adversário • toque **Pular**.
  Esperado: você só assiste (toques não mexem na bola); Pular encerra o lance e o resultado entra no placar normalmente (ver `lance_12_maquina_chute.png`).

- [ ] **R31 — Lances SIM/NÃO**
  Passos: toque **Lances: SIM** para virar NÃO • deixe o jogo correr • volte para SIM.
  Esperado: com NÃO as chances são resolvidas sem abrir o campo; com SIM o campo volta a abrir.

## 5. Pausa, substituições, velocidade e simular

- [ ] **R32 — Pausa**
  Passos: durante o jogo toque no botão de pausa.
  Esperado: abre "PARTIDA PAUSADA • minuto" com placar, Continuar, Substituições (x/5), Velocidade, Lances e Ir ao fim; o relógio não anda (ver `campo_05_pausa.png`).

- [ ] **R33 — Continuar**
  Passos: na pausa toque **Continuar**.
  Esperado: o jogo segue do mesmo minuto e placar.

- [ ] **R34 — Substituição**
  Passos: abra **Substituições** • troque um titular por um reserva • volte.
  Esperado: comentário "Substituição: sai X, entra Y"; contador vai para 1/5; o jogador que saiu não aparece mais para entrar.

- [ ] **R35 — Limite de 5 substituições**
  Passos: faça 5 trocas e tente a 6ª.
  Esperado: o jogo não deixa fazer a 6ª; contador fica em 5/5.

- [ ] **R36 — Velocidade 1×, 2× e 6×**
  Passos: toque no botão de velocidade várias vezes.
  Esperado: alterna 1× → 2× → 6× → 1×; o relógio do jogo acelera de acordo, sem pular gols do placar.

- [ ] **R37 — Ir ao fim / Simular dentro do jogo**
  Passos: no meio do jogo toque **Ir ao fim** (ou **Simular**).
  Esperado: o jogo termina na hora com placar final válido e vai para o pós-jogo; nenhum lance abre depois disso.

- [ ] **R38 — Simular a rodada pela central**
  Passos: na central toque **Simular** em vez de jogar.
  Esperado: a partida é resolvida sem abrir o jogo; o resultado aparece na tabela e no calendário; a data avança.

- [ ] **R39 — Pós-jogo e nota (jogador)**
  Passos: na carreira de jogador, jogue uma partida da liga até o fim.
  Esperado: tela de nota com estatísticas e comentários da rede (ver `jogador_24_liga_nota.png`); se você jogou menos de 30 min, nota perto de 6,0; nota sempre entre 4,5 e 8,5 em jogo normal.

## 6. Copas

- [ ] **R40 — Sorteio / chaveamento**
  Passos: aba Competições > nome da copa (ex.: Copa do Brasil).
  Esperado: chaveamento com fases, datas e confrontos; nenhum clube repetido na mesma fase; Voltar retorna (ver `copa_chaveamento.png`).

- [ ] **R41 — Copa no calendário e na próxima partida**
  Passos: veja o calendário e o card "Próxima partida".
  Esperado: jogos de copa aparecem com a logo e o nome da fase (ver `copa_calendario.png`, `copa_proxima_partida.png`).

- [ ] **R42 — Pênaltis no jogo único**
  Passos: numa copa de jogo único (ex.: FA Cup, Copa Verde), simule/jogue até um empate.
  Esperado: decisão por pênaltis; no chaveamento o placar mostra pênaltis entre parênteses, ex.: "2 (6) × 2 (7)", e o vencedor fica em destaque.

- [ ] **R43 — Ida e volta**
  Passos: numa copa com ida e volta (Copa do Brasil, Libertadores, Champions — ver `CUPS` em `src/world_data.gd`), jogue os dois jogos de um confronto.
  Esperado: rótulos "Jogo de ida" e "Jogo de volta"; na volta o mando inverte; quem avança é decidido pelo agregado dos dois jogos.

- [ ] **R44 — Agregado empatado vai para pênaltis**
  Passos: num confronto de ida e volta, termine com agregado empatado (ex.: 1×0 e 0×1).
  Esperado: pênaltis no fim do jogo de volta (não há gol fora); o vencedor avança no chaveamento.

- [ ] **R45 — Final em jogo único (Libertadores/Champions)**
  Passos: chegue (ou simule) à final da Libertadores ou Champions.
  Esperado: a final é um jogo só, rotulada "Final", com pênaltis se empatar (ver `copa_libertadores_final.png`).

- [ ] **R46 — Eliminação**
  Passos: perca um confronto de copa.
  Esperado: seu clube some das próximas fases; a copa segue sendo resolvida sozinha; nenhum jogo de copa seu aparece mais no calendário.

## 7. Fim de temporada e troféu

- [ ] **R47 — Fim de temporada (técnico)**
  Passos: jogue/simule até a última rodada.
  Esperado: tela de fim de temporada com classificação final, campeão, prêmios; botão para a próxima temporada (ver `copa_fim_temporada.png`).

- [ ] **R48 — Nova temporada**
  Passos: avance para a temporada seguinte.
  Esperado: cabeçalho mostra Temporada 2 e o ano seguinte; tabela zerada; novo chaveamento de copas; jogadores um ano mais velhos.

- [ ] **R49 — Troféu de liga ou copa nacional (ouro)**
  Passos: ganhe um campeonato ou copa nacional.
  Esperado: animação com taça dourada, confete e "Parabéns! O <clube> vence a <campeonato>" (ver `trofeu_inicio.png`, `trofeu_meio.png`, `trofeu_fim.png`); ao terminar, volta para a tela do jogo.

- [ ] **R50 — Troféu continental (prata)**
  Passos: ganhe Libertadores ou Champions.
  Esperado: mesma animação, com taça prateada (ver `trofeu_prata.png`).

- [ ] **R51 — Fim de temporada (jogador)**
  Passos: na carreira de jogador, chegue ao fim da temporada.
  Esperado: resumo da temporada; títulos aparecem na aba Carreira; abre a janela de transferências.

## 8. Rede social (carreira de jogador)

- [ ] **R52 — Comentários após o jogo**
  Passos: jogue uma partida • aba 03 REDE SOCIAL.
  Esperado: comentários novos no feed (elogio, neutro, xingamento, zoeira ou manchete), cada um com Humilde, Provocar, Xingar de volta, Ignorar.

- [ ] **R53 — Responder humilde / provocar / ignorar**
  Passos: responda um comentário com cada opção.
  Esperado: aparece um aviso com a consequência; os botões daquele comentário somem (não dá para responder duas vezes); seguidores/fama/torcida mudam no perfil.

- [ ] **R54 — Xingar de volta**
  Passos: responda com **Xingar de volta**.
  Esperado: seguidores sobem; fama, torcida ou confiança caem; aparece "Polêmicas recentes: N (com 3 você é afastado)".

- [ ] **R55 — Multa**
  Passos: xingue de volta várias vezes até aparecer multa.
  Esperado: aviso "Multa de $ X", notícia "Multa do clube" e o dinheiro na aba VIDA cai no valor da multa.

- [ ] **R56 — Perda de patrocínio**
  Passos: com pelo menos 1 patrocinador, xingue de volta até perdê-lo.
  Esperado: aviso "<marca> cancelou o patrocínio"; a marca some de PATROCINADORES na aba VIDA.

- [ ] **R57 — Afastamento**
  Passos: chegue a 3 polêmicas.
  Esperado: aviso "AFASTADO por N jogos" e notícia "Afastado!"; nos próximos N jogos o jogador não é escalado; depois volta a ser.

- [ ] **R58 — Postar**
  Passos: toque em cada post (Foto do treino, Agradecer a torcida, Foto na balada, Indireta para o técnico, Pedir para sair do clube, Provocar o próximo rival).
  Esperado: o post aparece no feed com seu @; cada um mostra um aviso de consequência; nada trava.

## 9. Empresário, propostas e negociação (jogador)

- [ ] **R59 — Contratar empresário**
  Passos: aba 04 EMPRESÁRIO • toque **Contratar** no nível 1 (Zé da Várzea).
  Esperado: vira seu empresário; contrato atual continua mostrando salário, duração, multa e valor de mercado (ver `jogador_20_empresario.png`).

- [ ] **R60 — Empresário exige fama**
  Passos: com fama 0, tente contratar o nível 2 ou 3.
  Esperado: recusa com aviso de fama mínima (15 e 40); nada muda.

- [ ] **R61 — Comissão aparece na VIDA**
  Passos: com empresário, avance uma semana • aba 05 VIDA.
  Esperado: "Comissão do empresário" mostra a porcentagem descontada e o "Líquido por semana" = salário + patrocínios − comissão.

- [ ] **R62 — Propostas na janela**
  Passos: jogue até o meio ou fim da temporada • toque **Propostas na mesa (N)**.
  Esperado: lista com clubes, salário, anos, luvas e multa; sem propostas aparece "Nenhuma proposta na mesa" com a dica.

- [ ] **R63 — Negociar**
  Passos: toque **Negociar** numa proposta.
  Esperado: aviso com o resultado (melhora, mantém ou clube desiste); a tela atualiza com os valores novos.

- [ ] **R64 — Transferência na mesma liga**
  Passos: aceite proposta de clube da sua liga.
  Esperado: muda de clube na hora; cabeçalho mostra o clube novo.

- [ ] **R65 — Transferência para outra liga**
  Passos: aceite proposta de clube de outra liga.
  Esperado: continua no clube atual até o fim da temporada; na virada vai para a nova liga com tabela, calendário e escudos dela.

- [ ] **R66 — Contrato acabando / renovação**
  Passos: chegue ao último ano de contrato.
  Esperado: pode aparecer proposta "RENOVAÇÃO • clube"; se o contrato acabar sem acordo, tela "Livre no mercado" para escolher clube.

## 10. Compras (aba VIDA)

- [ ] **R67 — Sem dinheiro**
  Passos: com $ 0,00 mi toque **Comprar** em Moto.
  Esperado: aviso "Dinheiro insuficiente."; dinheiro não muda (ver `jogador_21_vida.png`).

- [ ] **R68 — Comprar com dinheiro**
  Passos: acumule salário até ter dinheiro • compre um item barato.
  Esperado: aviso "Comprado: <item>"; dinheiro cai no preço exato; fama/torcida mudam; post "Realizei mais um sonho" no feed.

- [ ] **R69 — Comprar o mesmo item de novo**
  Passos: toque **Comprar** no mesmo item.
  Esperado: aviso "Você já tem isso."; dinheiro não muda.

## 11. Botão voltar do Android

- [ ] **R70 — Voltar em tela interna**
  Passos: abra uma tela com botão **Voltar** no topo (ex.: chaveamento da copa, datapack, propostas) • aperte o voltar do Android.
  Esperado: faz o mesmo que o botão Voltar da tela: volta uma tela.

- [ ] **R71 — Voltar várias vezes seguidas**
  Passos: entre 3 telas para dentro • aperte voltar do Android 3 vezes.
  Esperado: volta uma tela por vez, na ordem certa, até a tela inicial do fluxo.

- [ ] **R72 — Voltar onde não há Voltar**
  Passos: aperte voltar do Android em "Minhas carreiras", no hub e durante a partida/lance.
  Esperado: nada acontece: o app não fecha, a partida não sai nem perde o placar, nada trava.

## 12. Salvar, carregar e trocar de slot

- [ ] **R73 — Salva ao fechar o app**
  Passos: jogue uma rodada • compre algo / responda na rede • feche o app pelo multitarefa • abra • **Carregar**.
  Esperado: tudo volta como estava: data, rodada, placares, dinheiro, compras, respostas.

- [ ] **R74 — Fechar no meio da partida**
  Passos: no minuto 60 de uma partida, feche o app • abra • carregue.
  Esperado: a carreira abre sem erro na central antes daquela partida (ou com ela resolvida); nunca save corrompido ou tela em branco.

- [ ] **R75 — Card do slot mostra o resumo**
  Passos: volte para "Minhas carreiras".
  Esperado: cada slot usado mostra escudo, clube, TÉCNICO ou jogador, liga, temporada e ano corretos.

- [ ] **R76 — Trocar de slot**
  Passos: carregue Carreira 1 (técnico) • volte ao início • carregue Carreira 2 (jogador) • volte e carregue a 1 de novo.
  Esperado: cada carreira abre com os próprios dados; nada de uma aparece na outra (dinheiro, clube, data).

- [ ] **R77 — Quatro carreiras ao mesmo tempo**
  Passos: crie carreiras nos slots 3 e 4 • reabra o app.
  Esperado: os 4 slots aparecem preenchidos e cada um carrega o seu.

- [ ] **R78 — Excluir slot**
  Passos: toque **Excluir** em um slot • confirme.
  Esperado: só aquele slot volta para "Espaço disponível para uma nova história"; os outros continuam iguais.

- [ ] **R79 — Criar por cima de slot excluído**
  Passos: no slot excluído, crie uma carreira nova.
  Esperado: começa do zero (Temporada 1), sem dados da carreira antiga.

- [ ] **R80 — Save da versão anterior**
  Passos: com a versão anterior do app, crie e jogue uma carreira • instale a versão nova **por cima** (sem desinstalar) • carregue.
  Esperado: a carreira antiga abre e continua jogável (jogar 1 rodada); datapack continua ativo sem reimportar.

---

## Resultado

| Seção | Casos | Passou | Falhou | Bugs abertos |
|---|---|---|---|---|
| 1. Primeira abertura e datapack | R01–R05 | | | |
| 2. Criar carreira | R06–R08 | | | |
| 3. Peneira e propostas | R09–R15 | | | |
| 4. Partida com lances | R16–R31 | | | |
| 5. Pausa, substituições, velocidade, simular | R32–R39 | | | |
| 6. Copas | R40–R46 | | | |
| 7. Fim de temporada e troféu | R47–R51 | | | |
| 8. Rede social | R52–R58 | | | |
| 9. Empresário, propostas, negociação | R59–R66 | | | |
| 10. Compras | R67–R69 | | | |
| 11. Botão voltar do Android | R70–R72 | | | |
| 12. Salvar, carregar e trocar de slot | R73–R80 | | | |
| **Total** | **80** | | | |

A versão só sai com todos os casos marcados ou com cada falha registrada em bug e aceita pelo qa-lead.
