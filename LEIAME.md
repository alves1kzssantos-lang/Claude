CRAQUE MANAGER — projeto Godot 4 (testado no Godot 4.5.1)

COMO ABRIR
1. Extraia o .zip numa pasta.
2. Abra o Godot 4 > Importar > escolha o arquivo project.godot.
3. Aperte Play (tela deitada, 1280x720, se ajusta a qualquer celular).

COMO JOGAR OS LANCES
Na partida, toda chance de gol abre o campo visto de cima.
- No SEU ataque o jogo pausa e fica cinza:
    toque num companheiro ............ passe RASTEIRO
    segure o dedo num companheiro .... passe ALTO (na área vira cruzamento e cabeceio)
    toque dentro do gol .............. chute colocado (toque no fundo da rede = chute alto)
    deslize o dedo até o gol ......... chute: direção = mira, tamanho = força
  A linha tracejada é a linha de impedimento: passe para quem está atrás dela.
  Força demais faz a bola subir e passar por cima do travessão.
- Árbitro: bote pode ser falta. Na área = PÊNALTI, perto da área = FALTA com
  barreira, às vezes ele dá VANTAGEM. Amarelo, segundo amarelo = vermelho,
  expulso desfalca o time e fica fora do próximo jogo.
- No ataque do adversário você assiste (botão "Pular").
- Botão "Lances: SIM/NÃO" liga e desliga durante o jogo.
- Todos os números ficam em assets/data/match_tuning.json
  (explicados em design/gdd/partida-e-arbitro.md).

MODO CARREIRA DE JOGADOR (novo)
Na tela de carreiras escolha "Carreira de jogador": crie o atleta (nome,
posição, idade, número, país, pé, visual e chuteira), jogue a PENEIRA com
olheiros e escolha uma das propostas. Nos lances a seta dourada é você: a bola
só obedece quando está no seu pé. Abas: Jogos (treino, próxima partida),
Carreira (atributos, histórico, títulos), Rede social (responder torcedores,
postar), Empresário (contrato, propostas, agentes) e Vida (dinheiro,
patrocínios, compras). Regras: design/gdd/carreira-jogador.md.

LIGAS E COPAS
- 58 ligas jogáveis, todas com clubes e escudos do datapack: divisões de
  Brasil, Inglaterra (até a National League), Espanha, Itália, Alemanha
  (até a 3. Liga), França, Portugal, Holanda, Bélgica, Turquia, Argentina,
  Chile, Colômbia, Equador, Paraguai, Peru, México, EUA, Canadá, Arábia,
  Emirados, Irã, Marrocos, Angola, Indonésia, China, Coreia, Grécia,
  Dinamarca, Suécia e os estaduais (Paulista, Carioca, Mineiro, Gaúcho,
  Paranaense, Catarinense).
- Copas em mata-mata de jogo único, pênaltis no empate: Copa do Brasil,
  Copa do Nordeste, Copa Verde, FA Cup, Carabao Cup, KNVB Cup, Copa MX,
  Copa Chile, Hazfi Cup, Piala Indonesia, Canadian Championship,
  Copa Libertadores e Champions League.
- Antes de cada jogo aparece a abertura com a logo do campeonato. Clubes de outras ligas entram como convidados com escudo
  e elenco. Quem joga cada copa é definido em src/world_data.gd (CUPS).
- Tela da copa: aba Competições > nome da copa (chaveamento com placares e
  pênaltis). O calendário e a "Próxima partida" já mostram os jogos de copa.
- Elencos reais dos clubes grandes: assets/data/rosters_real.json
  (nome, posição, idade, força). Os outros clubes usam nomes do datapack.

TELAS DE CONFERÊNCIA
production/qa/evidence/ guarda as capturas (copa_*.png, campo_*.png, lance_*.png).
Para gerar de novo: tests/shots_cups.tscn e tests/preview_pro.tscn (vídeo).
Conferir todas as ligas: tests/all_leagues.tscn.

TESTES
godot --headless --path . res://tests/run_tests.tscn

DATAPACK (já vem dentro do jogo)
O arquivo datapack.zip fica na pasta do projeto. Na primeira vez que alguém
abre o jogo, ele importa sozinho (tela "Preparando clubes...", até 1 minuto).
Depois disso fica salvo no aparelho. Para trocar de pacote, substitua o
datapack.zip ou use Datapack > Escolher arquivo / Remover.
Na exportação (Projeto > Exportar > Recursos), em "Filtros para exportar
arquivos que não são recursos", coloque:  *.zip, *.json
Sem isso o pacote e o arquivo de ajuste da partida não vão para o APK.

VISUAL DA PARTIDA
Câmera, tamanho dos bonecos e cor do gramado ficam no topo de src/lance_view.gd
(CAMERA_WIDTH_M, BODY_H, PITCH). Camisas listradas: lista STRIPED em
src/world_data.gd.

ONDE MEXER
src/datapack.gd     importador de datapack e tabela de IDs dos clubes
src/world_data.gd   LIGAS, CLUBES (nome, sigla, cores, força) e nomes gerados
src/game.gd         regras: formações, dinheiro, temporada, mercado
src/match_sim.gd    simulação da partida (chances, gols, substituições, faltas e cartões)
src/ball_physics.gd     física da bola (altura, quique, atrito, travessão)
src/referee.gd          regras do árbitro (falta, pênalti, impedimento, vantagem)
src/tuning.gd           lê assets/data/match_tuning.json
src/lance_view.gd   lances em campo: física da bola, passe, chute, goleiro
src/match_view.gd   central da partida ao vivo
src/ui.gd           cores e estilo dos botões/painéis
src/screens_*.gd    telas (início, central do clube, elenco/mercado)
src/crest.gd        escudo gerado por código
src/coach_avatar.gd desenho do técnico

Os saves ficam em user://carreira_0.sav até carreira_3.sav.
