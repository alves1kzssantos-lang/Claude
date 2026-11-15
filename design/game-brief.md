# Craque Manager — Game Brief

> Documento de visão. Escrito pelo Creative Director em 2026-11-14 a partir de
> `LEIAME.md`, `design/gdd/carreira-jogador.md`, `design/gdd/partida-e-arbitro.md`
> e das capturas em `production/qa/evidence/`. Toda decisão de design, arte, áudio
> e texto deve poder ser rastreada até um pilar abaixo.

---

## 1. Fantasia central

**"Do campinho ao Maracanã, com a bola no seu pé e a torcida na sua cabeça."**

O jogador vive o futebol brasileiro por dentro: como técnico, monta o time e
decide o lance crucial; como atleta, sai de uma peneira, aguenta xingamento na
rede social e vira craque (ou polêmico). A promessa emocional não é "gerenciar
números", é **ser o protagonista da resenha de segunda-feira**: o gol no fim do
clássico, a resposta atravessada ao torcedor, a convocação, a Bola de Ouro.

Em uma frase de venda: *é como o Top Tier Manager, **e também** cada chance de
gol você joga com o dedo — e, se quiser, você é o próprio craque, com a fama e
as tretas que vêm junto.*

## 2. Pilares de design

Máximo quatro. Cada um tem um teste de decisão e vale para todas as áreas.

### Pilar 1 — "O lance decide"
O momento-pico do jogo é a chance de gol jogada por toque. Tudo o que acontece
fora dela (tática, mercado, treino, rede social) existe para dar peso a esse
momento, e o lance precisa devolver esse peso.
- **Teste:** entre uma feature de gestão nova e deixar o lance mais tenso,
  legível ou recompensador, escolhemos o lance.
- **Arte/Áudio:** o lance tem a melhor animação, o melhor som e a melhor
  câmera do jogo. Menus podem ser sóbrios; o gol nunca pode ser mudo.
- **Texto:** a narração e as manchetes citam o lance ("Alves Jr decide aos 89'").

### Pilar 2 — "Futebol com sotaque brasileiro"
Estaduais, Copa do Brasil, Copa do Nordeste, Libertadores, peneira, várzea,
zoeira, "pagou uma vez é seu". O mundo é global (58 ligas), mas o ponto de
vista é brasileiro.
- **Teste:** entre um termo/situação genérica e uma que um torcedor brasileiro
  reconhece na hora, escolhemos a brasileira (ex.: "peneira" e não "trial";
  "clássico" com peso próprio).
- **Arte/Áudio:** cores de camisa e escudos fiéis; som de arquibancada
  brasileira (batuque, coro, vaia), não estádio europeu genérico.
- **Texto:** português coloquial, com humor; xingamento de torcida é caricato,
  nunca preconceituoso.

### Pilar 3 — "Toda escolha tem consequência visível"
Responder torcedor, treinar intenso, escalar o garoto, aceitar proposta de
outra liga: cada decisão precisa mostrar efeito na tela em pouco tempo
(seguidores, fama, confiança do técnico, multa, manchete).
- **Teste:** se uma escolha não muda nada que o jogador consiga ver em até
  1–2 partidas, ela é cortada ou ganha feedback.
- **Arte/UI:** números que mudam aparecem com seta/cor (+/−), nunca em silêncio.
- **Sistemas:** tudo em JSON de ajuste (`pro_career.json`, `match_tuning.json`),
  para balancear consequências sem mexer em código.

### Pilar 4 — "Uma partida cabe no ponto de ônibus"
Jogo mobile, tela deitada, um dedo. Uma partida com lances deve caber em
3–5 minutos, e o jogador sempre pode pular, simular ou desligar lances.
- **Teste:** entre profundidade que exige mais toques/telas e fluidez de
  sessão curta, escolhemos a sessão curta (profundidade vai para "opcional").
- **UI:** ações principais com um toque a partir da central ("Jogar",
  "Simular", "Próxima partida"); sem menus de 4 níveis.
- **Técnico:** carregamento e simulação de rodada rápidos (meta atual:
  rodada < 120 ms, lance < 2 ms/quadro).

### Tensões intencionais entre pilares
- Pilar 1 x Pilar 4: lances demais cansam. Resposta: **menos lances, mais
  importantes** (ver melhoria nº 2).
- Pilar 2 x mundo global: ligas estrangeiras existem, mas o tom, a interface e
  as copas brasileiras são o centro.
- Pilar 3 x Pilar 4: consequência precisa ser legível em segundos, não em
  relatórios longos.

## 3. Estética-alvo (MDA), em ordem
1. **Fantasy** — ser o técnico/craque do seu clube.
2. **Challenge** — acertar o passe certo, vencer o goleiro, subir de divisão.
3. **Narrative** (emergente) — a história da carreira contada por resultados,
   manchetes e rede social.
4. **Sensation** — o gol tem que ser gostoso de ver e ouvir.
5. **Expression** — visual do atleta, chuteira, respostas na rede, estilo de time.

Fora do foco: Fellowship (sem multiplayer por ora), Submission pura (o jogo
pode ser relaxante, mas a meta é tensão nos lances).

## 4. Público

- **Primário:** brasileiros de 14–30 anos, Android de entrada/médio, que jogam
  World Soccer Champs, Top Tier Manager, Score! Hero, Dream League e assistem
  futebol brasileiro. Sessões curtas, várias por dia.
- **Secundário:** fãs de "football manager leve" que querem 58 ligas e copas
  sem a complexidade do FM.
- **Necessidades (SDT):** Autonomia (escolher clube, responder torcida),
  Competência (lance por toque com habilidade real), Relação (identidade com o
  clube do coração e com a "torcida" da rede social).

## 5. Tom visual e sonoro

### Visual (estado atual, pelas capturas)
- Interface escura (azul-marinho na central do técnico, verde-escuro nas
  carreiras/criação), destaques em **dourado**, cartões arredondados, tipografia
  grande e legível. Coerente e limpa — manter.
- Bonecos cabeçudos desenhados por código, sorridentes, com tom de pele,
  cabelo, barba e chuteira configuráveis. Charme de "figurinha" — é a assinatura
  visual do jogo.
- Campo de cima com gramado verde-acinzentado e adversários esmaecidos durante
  a decisão.

### Direção
- **Palavra-chave: "domingo de clássico".** Cor, calor, festa.
- O campo hoje está apagado (verde dessaturado). O lance deve ser a tela mais
  viva do jogo: gramado com faixas de corte, sombra mais forte, cor de camisa
  saturada, brilho na bola e no gol.
- Menus continuam sóbrios (escuro + dourado) para o campo "estourar" por contraste.
- Comemoração de gol com o boneco cabeçudo (pulo, dancinha, pose) — é onde o
  estilo cartunesco rende mais.

### Som (não há evidência de áudio nos documentos — prioridade)
- Ambiente: murmúrio de torcida contínuo que **sobe** quando a bola se aproxima
  da área; batuque/charanga nos clubes brasileiros.
- Pico: explosão de torcida + apito curto no gol; "uuuh" na bola na trave;
  vaia no cartão.
- Interface: cliques secos e curtos; som de "moeda" em dinheiro/patrocínio;
  notificação de celular na rede social.
- Narração: começar com **frases curtas em texto** na tela ("GOOOL!",
  "Na trave!"); voz gravada é opcional e só se couber.

## 6. O que nos torna únicos frente a WSC e TTM

| | World Soccer Champs | Top Tier Manager | **Craque Manager** |
|---|---|---|---|
| Foco | Jogar partidas | Gerenciar clube | **Gerenciar e decidir o lance** |
| Controle | Partida inteira em toque | Simulação, sem controle em campo | **Só as chances de gol, por toque** |
| Carreira de jogador | Não | Não | **Sim: peneira, empresário, rede social, seleção** |
| Mundo | Ligas e copas | Muitas ligas | **58 ligas + 13 copas, estaduais e copas regionais do Brasil** |
| Identidade | Global | Global | **Brasileira, com zoeira e fama** |

**Diferencial principal:** o "meio-termo" — mais decisão que um manager, menos
cansaço que um jogo de futebol completo. O segundo diferencial é a **carreira de
jogador com consequências sociais** (xingar dá seguidor e tira patrocínio), que
nenhum dos dois tem.

Eixos do mapa de posicionamento: (1) controle em campo — nenhum → total;
(2) profundidade de gestão — leve → pesada; (3) identidade local — genérica →
brasileira. O Craque Manager fica no meio do eixo 1, médio no eixo 2 e no
extremo do eixo 3 — espaço hoje vazio.

## 7. O que o jogo NÃO é (anti-pilares)

1. **Não é um simulador de futebol completo.** Não vamos controlar os 90
   minutos nem todos os jogadores; quem quer isso tem eFootball/WSC.
2. **Não é Football Manager.** Sem planilhas, sem 40 atributos, sem
   instruções individuais por jogador. Se precisar de tutorial longo, cortamos.
3. **Não é pay-to-win nem "gacha".** Nada de comprar força com dinheiro real
   ou loot box de jogador. Moeda do jogo se ganha jogando.
4. **Não é online/competitivo.** Sem PvP, sem servidor, sem conta. Funciona
   offline no celular.
5. **Não é realismo gráfico.** Bonecos cabeçudos e visual desenhado por código
   são escolha, não limitação. Não perseguimos 3D/fotorrealismo.
6. **Não é ofensivo.** A rede social tem xingamento caricato de torcida; nunca
   racismo, homofobia ou ataque a pessoa real.

## 8. As 10 próximas melhorias (diversão e retenção), em prioridade

Critério: proximidade dos pilares + impacto na sensação de jogar / voltar ao
jogo ÷ custo estimado. Os números de custo são relativos (P/M/G) e devem ser
validados pelo produtor e pelo programador líder.

1. **O momento do gol (juice) — Pilar 1, custo M.**
   Som de torcida que sobe perto da área, explosão no gol, "uuuh" na trave,
   vibração do celular, leve zoom/tremida de câmera, texto grande "GOOOL!",
   comemoração do boneco e replay de 2–3 s. Hoje o pico do jogo tem pouca
   recompensa sensorial; é a melhoria de maior retorno por esforço.
   *Teste:* em playtest, o jogador reage em voz alta ao gol e não aperta
   "Lances: NÃO" na primeira sessão.

2. **Menos lances, mais importantes (contexto e pressão) — Pilares 1 e 4, custo M.**
   Limitar os lances jogados a ~3–5 por partida e escolher os de maior peso
   (placar apertado, últimos minutos, clássico, mata-mata). Mostrar na abertura
   do lance: minuto, placar e uma frase ("Último minuto. Empate te elimina.").
   *Teste:* duração média de partida com lances ≤ 5 min; taxa de "Pular" cai.

3. **Objetivos em camadas — Pilar 3, custo M.**
   Curto (meta do jogo: "marque 1 gol", "não leve cartão"), médio (meta da
   diretoria/técnico na temporada) e longo (sonho de carreira: "jogar na
   Europa", "Bola de Ouro", "levar o time da Série D à A"). Cada meta cumprida
   dá recompensa visível. É o motor de "só mais uma rodada".
   *Teste:* sessões por dia e rodadas por sessão sobem em relação à versão atual.

4. **Disputa de pênaltis e bolas paradas jogáveis — Pilares 1 e 2, custo P/M.**
   As 13 copas são mata-mata de jogo único com pênaltis: hoje é o momento mais
   dramático do futebol e precisa ser jogado (bater deslizando, defender
   escolhendo o canto). Reaproveita física de chute e goleiro existentes.
   Depois: escanteio jogável.
   *Teste:* o jogador escolhe "Jogar" (não "Simular") em jogo de copa com
   mais frequência que em jogo de liga.

5. **Rede social que reage ao que aconteceu — Pilares 2 e 3, custo M.**
   Comentários e manchetes ligados a eventos reais da partida e da carreira
   (gol no clássico, pênalti perdido, expulsão, ex-clube, convocação), torcedor
   rival que persegue, e "viralizar" após lance decisivo. Hoje os comentários
   são por tipo genérico; amarrá-los ao evento transforma estatística em história.
   *Teste:* jogadores abrem a aba Rede social após a maioria das partidas.

6. **Clássicos e rivalidades — Pilar 2, custo P.**
   Tabela de rivais por clube (Fla-Flu, Gre-Nal, Choque-Rei…), abertura especial,
   torcida mais alta, pressão maior na rede social e bônus de fama/confiança ao
   vencer. Baixo custo (dados + texto), alto valor emocional.

7. **Sala de troféus e linha do tempo da carreira — Pilar 3, custo P/M.**
   Tela de memórias: títulos, prêmios, gols marcantes, clubes por onde passou,
   gráfico de força/fama por temporada. Dá orgulho e motivo para manter o save
   vivo por várias temporadas.

8. **Primeira sessão guiada — Pilar 4, custo P.**
   Peneira como tutorial real: um passo por vez (passe rasteiro → passe alto
   → chute), com metas simples e sucesso garantido no primeiro lance. Para o
   técnico, primeiro jogo com dica de escalação. Reduz abandono no primeiro dia.

9. **Campo e bonecos mais vivos — Pilares 1 e 2, custo M.**
   Gramado com faixas e cor mais saturada, sombras, animação de corrida/chute
   mais expressiva, torcida na borda do campo, rede do gol que balança.
   Hoje o campo é a tela mais apagada do jogo; deveria ser a mais bonita.

10. **Eventos de vida e escolhas narrativas curtas — Pilar 3, custo M.**
    Cartas de decisão entre partidas (proposta de festa antes do jogo, convite
    para programa de TV, briga no vestiário, oferta de clube rival) com
    consequência em fama, confiança, energia ou dinheiro. Dá variedade entre
    jogos sem aumentar o tempo de partida.

### Fora da lista (de propósito)
- Multiplayer/online, loja com dinheiro real, mais ligas: não aumentam a
  diversão do núcleo agora e conflitam com anti-pilares ou com o Pilar 1.

## 9. Riscos a observar
- **Direitos de nomes e escudos:** o `datapack.zip` vai dentro do APK com
  escudos e elencos reais. Publicar na Play Store assim pode gerar remoção.
  Avaliar com cuidado antes do lançamento (ex.: datapack opcional importado
  pelo usuário, como já é possível pela tela Datapack).
- **Excesso de lances:** se cada partida tiver lances demais, o jogador desliga
  e o Pilar 1 morre. Monitorar a taxa de "Lances: NÃO".
- **Tom da rede social:** manter o xingamento caricato e revisar
  `pro_social.json` para nada ofensivo a grupos ou pessoas reais.

## 10. Como saberemos que a visão está funcionando
- O jogador descreve o jogo como "manager onde você decide o lance".
- Na primeira sessão, a maioria joga os lances em vez de simular.
- Jogadores mantêm o mesmo save por 2+ temporadas.
- As histórias contadas pelos jogadores citam momentos ("fiz o gol no
  Gre-Nal", "xinguei o torcedor e perdi o patrocínio"), não números.
