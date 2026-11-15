# Craque Manager — Revisão de UX dos fluxos (celular, paisagem 1280×720)

> Data: 2026-11-14 • Autor: ux-designer • Status: proposta para decisão do Alves
> Escopo: primeira abertura → criar carreira → peneira → assinar → jogar → rede social → fim de temporada (modo jogador) e modo técnico com copas.
> Base: leitura do código (`src/screens_start.gd`, `src/screens_pro.gd`, `src/screens_hub.gd`, `src/match_view.gd`, `src/lance_view.gd`, `src/main.gd`, `src/ui.gd`, `project.godot`).
> **Limitação:** as capturas em `production/qa/evidence/` não puderam ser abertas nesta revisão (sem ferramenta para listar a pasta). Tudo abaixo vem do código; os itens marcados **[verificar na tela]** precisam ser conferidos nas capturas ou no aparelho.
> Nenhum código foi alterado. Cada solução é uma especificação para o ui-programmer.

---

## 0. Referência de medida (importante para tudo o que vem depois)

O jogo usa `stretch/mode = canvas_items` com `aspect = expand` e base de 720 px de altura. No celular deitado, **a altura é o que fica fixo**: em um aparelho comum (~6,5", ~68 mm de altura útil deitado), **1 px do jogo ≈ 0,095 mm**.

| Altura no código | Tamanho real aproximado | Situação |
|---|---|---|
| 30 px (botão "Central" do cabeçalho) | ~2,9 mm | muito pequeno |
| 36–42 px (responder post, Comprar, Demitir, Treino, Tabela/Calendário, Fechar) | 3,4–4,0 mm | muito pequeno |
| 46 px (padrão de `UI.button`) | ~4,4 mm | pequeno |
| 48 px (mínimo pedido na tarefa) | ~4,6 mm | ainda pequeno no aparelho |
| 64 px | ~6 mm | aceitável para linhas de lista, com espaço entre elas |
| 80–88 px | 7,6–8,4 mm | ≈ 48 dp do Android, o que o polegar acerta sem olhar |

**Conclusão:** "48 px" no espaço 1280×720 **não** equivale a 48 dp do Android. Proposta de tamanhos (tokens) para `UI`:

- `TOQUE_PRINCIPAL = 80` (Jogar, Entrar em campo, Aceitar, Continuar, Iniciar partida)
- `TOQUE_SECUNDARIO = 64` (abas, botões de cartão, filtros, Voltar)
- `TOQUE_LINHA = 64` (linhas de lista clicáveis: clubes, substituições, posts)
- `TOQUE_MINIMO_ABSOLUTO = 56`, **com pelo menos 12 px de espaço** até o vizinho. Nada abaixo disso.
- Fonte: `TEXTO_MIN = 16` para qualquer coisa que o jogador precise ler; `LEGENDA = 14` só para informação terciária; nada de 11–13 px em informação de decisão.

Custo disso: cabe menos coisa por tela. A solução é tirar densidade (menos linhas por tela, rolagem, uma coisa por cartão), não encolher o toque.

---

## 1. Contagem de toques até jogar

| Fluxo | Caminho | Toques | Avaliação |
|---|---|---|---|
| Jogador, 1ª vez | Carreira de jogador → Ir para a peneira → ENTRAR EM CAMPO → INICIAR PARTIDA → (abertura) → lance | **4** | Bom. Dá para ir a 3 (ver P1-6). |
| Técnico, 1ª vez | Carreira de técnico → Escolher clube → (setas de liga ‹ ›, N toques) → clube → Começar carreira → Jogar → INICIAR PARTIDA | **6 + N** | Ok; o N das setas de liga cresce com o datapack. |
| Jogador, jogo seguinte | (aba Jogos) Jogar → INICIAR PARTIDA | 2 | Bom. |
| Técnico, jogo seguinte | Jogar → INICIAR PARTIDA | 2 | Bom. |
| Abrir o jogo com carreira salva | Carregar | 1 | Bom. |

O número de toques não é o problema. Os problemas são **toques arriscados** (P0-3), **saídas que faltam** (P0-1) e **o lance sem ensino** (P0-2).

---

## 2. Problemas priorizados

Prioridade: **P0** = trava, faz perder progresso ou faz largar o jogo; **P1** = confunde ou irrita sempre; **P2** = polimento.

### P0-1 — Modo jogador não tem saída para o menu de carreiras
**Onde:** `screens_pro.gd` → `hub()` / `_tab_*`. O "Salvar e sair" só existe no modo técnico (`screens_hub.gd` → `_tab_manager`). O hub do jogador chama `head(..., false)` (sem Voltar) e a pilha fica vazia depois de `m.home()`. O botão voltar do Android (`main.gd` → `_notification`) só age se o Voltar estiver visível. `quit_on_go_back=false`.
**Efeito:** quem começa uma carreira de jogador só sai fechando o app. Não dá para trocar de carreira nem voltar ao menu. Na peneira e na tela de propostas também não há saída.
**Solução:**
1. Botão **"Menu"** fixo no cabeçalho em todo hub (técnico e jogador), no lugar do Voltar quando a pilha está vazia: 64 px de altura, ícone + texto.
2. Ao tocar, abre um modal com: **Continuar** (dourado, 80 px), **Salvar e voltar às carreiras**, **Configurações** (futuro).
3. Voltar do Android com a pilha vazia → abre esse mesmo modal (não fecha o app direto).
4. Salvamento automático depois de todo jogo/simulação, para que sair nunca custe progresso **[verificar se já salva]**.

### P0-2 — O lance (a mecânica principal) não tem tutorial
**Onde:** `lance_view.gd` → `_draw()`, estado `decide`. A única ajuda é uma linha de 16 px: *"Toque = passe rasteiro • Segure = passe alto • Toque no gol ou deslize até ele = CHUTE"*. Ela aparece por cima de um véu cinza, todo lance, igual para iniciante e veterano. A explicação da "seta dourada" fica só num texto da tela da peneira, que ninguém lê.
**Problemas específicos:**
- Três gestos numa frase só; "segurar" não tem retorno visual (o limite é 0,35 s em `toque_longo_segundos`). O jogador não sabe se segurou o bastante.
- Tocar e deslizar se separam por 40 px de arraste, e a diferença é invisível: um toque que "escorrega" vira chute sem querer.
- No modo jogador, quando a bola está com um companheiro, os toques são **ignorados em silêncio** (`_gui_input`: `return`). Parece que o jogo travou.
- A peneira, que decide a carreira, é justamente o **primeiro** lance da vida do jogador.

**Solução — "Aquecimento" guiado antes da peneira (3 passos, ~40 s, pode pular):**
1. **Passe rasteiro:** só 1 companheiro destacado com anel pulsando + mãozinha animada tocando nele. Texto grande (22 px): "Toque no companheiro para passar".
2. **Passe alto:** ao encostar o dedo, aparece um **anel de carga** em volta do companheiro, que fecha em 0,35 s e muda de cor quando o passe vira alto. Texto: "Segure até o anel fechar = passe alto".
3. **Chute:** a boca do gol pisca; a mãozinha desliza da bola até o gol. Mostrar a **seta de mira já desde 20 px** (hoje já existe; manter) com um **medidor de força** no tamanho do arraste.
- Depois do aquecimento, a dica de uma linha só aparece **nos 5 primeiros lances**. Depois vira um ícone "?" de 64 px que reabre a ajuda.
- Dica contextual, uma por vez, no lugar da frase com tudo: perto do gol → "Deslize até o gol para chutar"; com zagueiro colado (o anel já fica vermelho) → "Passe agora!".
- Bola com companheiro no modo jogador: faixa "Bola com o nº 8 — espere a sua vez" + seta apontando para você.
- Pênalti e falta já têm textos próprios: manter, só aumentar a fonte para 20 px.

### P0-3 — Ações irreversíveis sem confirmação (ou com confirmação fraca)
| Ação | Onde | Risco |
|---|---|---|
| **Simular** a peneira | `trial()`, ao lado de ENTRAR EM CAMPO | Um toque decide o início da carreira sem jogar |
| **Aceitar** proposta | `offers()` → `_accept` | Contrato de anos, sem resumo nem volta |
| **Recusar** proposta | `offers()` | A proposta some |
| **Xingar de volta** | `_post_row()`, botão de 36 px colado em "Ignorar" | Multa, patrocínio, afastamento (com 3 polêmicas) |
| **Demitir empresário** | `_tab_agent()`, 36 px | Perde nível e propostas |
| **Comprar** | `_tab_life()`, 36 px | Gasta dinheiro |
| **Remover datapack** | `datapack()` | Apaga nomes/escudos das próximas carreiras |
| **Excluir carreira** / **Pendurar as chuteiras** | "dois toques no mesmo botão" | Dois toques rápidos no mesmo lugar (toque duplo sem querer) confirmam. O botão também não volta ao normal sozinho |
| **Simular** no hub / **Ir ao fim** | botões com o mesmo peso de Jogar | Perde a partida jogável |

**Solução — padrão único de confirmação, em 3 níveis:**
- **Nível A (destrutivo permanente: excluir carreira, aposentar, remover datapack):** modal com o título do que se perde ("Excluir Carreira 2 — Zé Craque, Temporada 3?"), botão de cancelar **à esquerda e dourado**, destrutivo vermelho **à direita**, e o destrutivo só ativo depois de 1 s. Tirar o padrão de dois toques no mesmo botão.
- **Nível B (decisão de carreira: aceitar/recusar proposta, demitir empresário):** folha de resumo antes ("Você vai assinar com X por 3 anos, salário Y, multa Z. O empresário fica com N%") + Confirmar / Voltar.
- **Nível C (consequência social/dinheiro: xingar, provocar, comprar):** mostrar a consequência **no botão ou embaixo dele**, sem modal: "Xingar de volta (+engajamento, risco de multa • polêmicas 2/3)". Quando chegar a 2/3, passa para Nível B.
- **Simular na peneira:** tirar da tela da peneira, ou deixar só como link pequeno "Pular a peneira (não recomendado)" com confirmação Nível B. **Decisão do Alves** (ver seção 4).
- **Jogar × Simular:** Jogar dourado e com 2× a largura; Simular escuro e menor, nunca colados (mínimo 24 px de espaço).

### P1-4 — Alvos de toque abaixo do mínimo em todo o jogo
Ver a tabela da seção 0. Lista do que precisa subir primeiro (em ordem de uso):
1. Abas inferiores do hub (46 → 64) e "Voltar" do cabeçalho (44 → 64).
2. Botão **"Central"** do cabeçalho (30 → 64, ou virar um ícone de sino 64×64 com número).
3. Respostas a posts (36 → 64; 2 por linha em vez de 4).
4. Linhas de substituição (`_sub_row`, 40 → 64) e **Fechar** do modal (40 → 64, no canto, longe da lista).
5. Treino Leve/Normal/Intenso, Tabela/Calendário/Copas/Notícias (42 → 64).
6. Comprar, Contratar, Demitir (36–40 → 64).
7. Setas do calendário e das ligas (40–44 → 64×64).
8. "Pular ›" do lance adversário (área de toque 180×56): ok na largura, subir para 64 de altura **[verificar o botão de pausa do `FieldView`]**.
9. Botão de **pausa** na partida ao vivo: mínimo 72×72, no canto superior direito **[verificar na tela]**.

### P1-5 — Resultado importante aparece num aviso (toast) que some em 2,4 s
**Onde:** `main.gd` → `toast()`. Resultado de negociação (`Pro.negotiate`), de aceitar proposta, de responder post, de contratar empresário e de compra aparecem só ali. O texto **não quebra linha** (o painel cresce para os dois lados; texto longo sai da tela), dois toasts seguidos se sobrepõem e somem enquanto o jogador ainda lê.
**Solução:**
- Toast só para confirmação curta ("Melhor time escalado."). Largura máxima de 900 px, quebra de linha, duração = 2 s + 0,05 s por caractere, um de cada vez (fila).
- **Negociação:** o resultado aparece **dentro do cartão da proposta** ("Clube aceitou: salário 12 mil → 14 mil") e os números mudam com destaque.
- **Assinar contrato:** tela própria de celebração ("Você é do X!" + escudo + camisa) antes do hub. É um momento marcante da carreira e hoje passa num aviso.
- **Respostas na rede:** o efeito aparece no próprio post ("↳ você: …  +3,2 mil seguidores • polêmica +1").

### P1-6 — Fluxo do jogador: passos que confundem ou sobram
1. **Tela pré-jogo no modo jogador** (`match_view` estado `pre`): o modo jogador não deixa escalar, então a tela mostra só as escalações e repete "Simular". **O que ela faz pelo jogador:** mostra contra quem e se você é titular. Esse papel já é cumprido pelo cartão "Próxima partida" do hub e pela peneira. **Proposta:** no modo jogador, "Jogar" vai direto para a abertura animada (−1 toque). Se o Alves quiser manter, levar "você: TITULAR/NO BANCO" para o centro, grande.
2. **Propostas escondidas:** no meio da temporada as propostas ficam dentro da aba **04 EMPRESÁRIO**, sem aviso. Pôr **número/selo nas abas** (Empresário • 2, Rede social • novo) e um aviso no cartão "Próxima partida": "2 propostas na mesa ›".
3. **Peneira:** a exigência "nota 6,3+" aparece antes de o jogador saber o que é a nota. Pôr uma legenda: "Nota de 0 a 10 pela sua atuação. 6 = regular, 7 = boa, 8 = craque". Mostrar a **nota ao vivo** num canto durante a partida no modo jogador **[verificar se já existe]**. Na peneira, a nota é o objetivo da partida inteira.
4. **Fim da peneira → propostas:** o botão "Ver propostas" é bom. Na tela de propostas da 1ª vez, explicar em uma linha: "Papel = quanto você vai jogar. Titular joga mais e evolui mais rápido".
5. **Criar jogador:** "Nacionalidade ›" só avança, item por item. Se `Pro.NATS` for longa, são dezenas de toques para voltar uma. Trocar por **lista em grade com bandeiras** (modal), ou no mínimo setas ‹ › dos dois lados. O mesmo vale para posição e cabelo.

### P1-7 — Botão voltar do Android e pausa
- Na partida ao vivo o Voltar está escondido; o voltar do Android **não faz nada**. Quem joga no celular espera que ele **pause**. Ligar o voltar do Android a `_on_pause()` durante o estado `live` e a "fechar modal" quando houver modal aberto.
- No pré-jogo, o Voltar sai da partida. Ok, desde que nada tenha sido gasto.
- Com a pilha vazia (hubs, peneira, propostas iniciais): abrir o modal do P0-1.

### P1-8 — Copa (modo técnico): chaveamento ilegível e sem foco no seu jogo
**Onde:** `screens_hub.gd` → `cup()`. Colunas de 300 px lado a lado dentro de `UI.scroll()`, que **desativa a rolagem horizontal**. Uma copa com 5–6 fases (5 × 312 = 1560 px) passa da largura e fica cortada ou empurra o layout **[verificar em copa_*.png]**. A 1ª fase pode ter dezenas de confrontos em escudos de 22 px e texto de 15 px. Não rola sozinho até o seu confronto.
**Solução:**
- Ver **uma fase por vez**, com abas de fase no topo (64 px): "16 avos • Oitavas • Quartas • Semi • Final". Abrir já na fase atual.
- Seu confronto **fixo no topo** da fase, em cartão grande (escudos 56 px, nomes 20 px). Depois os outros em lista de 64 px.
- Aba extra **"Seu caminho"**: só os seus jogos na copa, do primeiro à final (padrão de app de futebol, fácil de ler no celular).
- Pênaltis: escrever "(4 × 3 nos pênaltis)" por extenso no seu confronto, no lugar do número solto entre parênteses.
- Status claro no cartão da copa no hub: "VOCÊ ESTÁ VIVO • próxima: Quartas, 12/05", sem o "•" no meio de uma frase longa.

### P1-9 — Texto pequeno demais para o celular
Muito texto de decisão está em 11–14 px: força/caixa dos clubes (12), subtítulos de cartão (13–14), legenda das escalações na partida (11–12), energia no minimapa (11), posse (12), regras da rede social (12), detalhes do empresário (13). O contraste está bom (o MUTED `9fbfb0` sobre o PANEL `123528` passa de 4,5:1); o problema é o **tamanho**.
**Solução:** aplicar `TEXTO_MIN = 16` / `LEGENDA = 14` (seção 0). O que não couber em 14 px sai da tela e vai para um detalhe ao tocar ("toque no clube para ver os números").

### P2-10 — Primeira abertura
- Importar o datapack mostra uma tela parada por até 1 minuto, sem barra de progresso. Parece que travou. Pôr barra ou contador ("Clubes 120/480…") e uma bola girando.
- Tela de carreiras: os 4 espaços vazios repetem os dois botões 4 vezes. Na primeira vez (nenhum save), mostrar uma tela de **boas-vindas com dois cartões grandes**: "Seja o técnico" / "Seja o craque", com uma frase e uma imagem cada. A grade de 4 espaços fica para depois.
- "Datapack: nenhum" no topo chama atenção na primeira vez, e o jogador novo não precisa dele. Levar para Configurações.

### P2-11 — Cor como única informação
- Tipo de post (xingamento/elogio/zoeira/manchete) só pela cor do nome → pôr etiqueta/ícone ("XINGOU", "ELOGIO").
- Zona de rebaixamento na tabela só pelo número em vermelho → faixa lateral + legenda "Z4".
- Lista de escalação na partida: o cartão amarelo/vermelho é um retângulo de 9×13 px → aumentar e pôr letra (A/V).

### P2-12 — Hub do técnico
- "Salvar e sair" fica escondido na aba 05 MANAGER → resolvido pelo modal "Menu" (P0-1).
- O cartão "Calendário" do hub é um botão de 170 px de altura cheio de texto: ok, mas pôr "Ver calendário ›" explícito no rodapé do cartão (affordance).
- Escolha de clube: com o datapack, muitas ligas → trocar setas ‹ › por uma lista de ligas com bandeira (modal) + busca.

---

## 3. Riscos para o ui-programmer conferir (não são de UX, mas afetam o fluxo)

- `screens_pro.gd` → `season()` chama `Pro.close_season()` **dentro da função que desenha a tela**. Qualquer `refresh()` ou ida a "Ver propostas" e volta desenha de novo e pode **fechar a temporada duas vezes** (prêmios/estatísticas em dobro). Conferir se `close_season` é idempotente.
- "Começar a próxima temporada" com propostas ainda sem resposta: o que acontece com elas? Se somem, avisar antes ("Você tem 2 propostas sem resposta. Elas vão expirar").
- Toast sem quebra de linha pode passar da tela com mensagem longa (P1-5).

---

## 4. Decisões que dependem do Alves

1. **Simular na peneira**
   - Tirar da tela: a peneira sempre é jogada. *(Recomendado)*
   - Link discreto com confirmação: deixa pular, mas com aviso.
   - Manter como está: mais rápido, mais risco de errar.
2. **Tela pré-jogo no modo jogador**
   - Pular direto para a abertura: −1 toque, combina com o WSC. *(Recomendado)*
   - Manter, com titular/banco em destaque.
3. **Tamanho dos botões**
   - Tokens 80/64/56 com menos coisa por tela: acerto do polegar no celular. *(Recomendado)*
   - Mínimo de 56 em tudo: menos mudança de layout, toque ainda apertado.
4. **Aquecimento do lance**
   - Obrigatório na 1ª carreira de jogador, pode pular: ensina antes da peneira. *(Recomendado)*
   - Só dicas dentro do jogo: menos atrito, mais chance de errar a peneira.

---

## 5. Checklist de acessibilidade (situação atual)

| Item | Situação |
|---|---|
| Só teclado | não se aplica ao alvo (Android); os botões têm `FOCUS_NONE`, então teclado/controle não navegam |
| Só controle | não suportado (anotar se um dia sair em TV/PC) |
| Texto no tamanho mínimo | **falha** (P1-9) |
| Sem depender só de cor | **parcial** (P2-11) |
| Sem flash sem aviso | ok (o GOOOL é um painel, não pisca) **[verificar a comemoração]** |
| Legendas | não há diálogo falado; narração em texto ok |
| Interface escala nas resoluções | ok na altura (expand); conferir 4:3 de tablet, onde a largura fica perto de 960 px e os layouts de 1280 px ficam apertados |
