# Checklist de lançamento na Google Play — Craque Manager

Gerado em: 14/11/2026 · Responsável: release-manager · Status: **rascunho para o dono revisar**
Plataforma: Android (Google Play) · Motor: Godot 4.5.1 (renderer Compatibility, tela deitada 1280x720)
Versão alvo: **a definir pelo dono** (proposta na seção 7) · Data alvo: **a definir pelo dono**

> **Esta lista não é parecer jurídico.** A seção 2 aponta riscos de direitos e um
> caminho mais seguro, mas a decisão final sobre nomes, escudos e marcas deve passar
> por um advogado de propriedade intelectual antes da publicação.

---

## 0. Veredito rápido: **NÃO PRONTO (NOT READY)**

Os 5 bloqueios principais (detalhados nas seções seguintes):

1. **Nomes reais estão no próprio código do jogo, não só no datapack.** `src/world_data.gd`
   traz centenas de clubes reais (Flamengo, Palmeiras, Real Madrid, Arsenal...) e nomes de
   competições com marca (Champions League, Libertadores, Copa do Brasil, FA Cup,
   Carabao Cup). `assets/data/rosters_real.json` traz **520 jogadores reais de 37 clubes**
   com nome, idade e nota. Tirar o datapack não resolve sozinho.
2. **O datapack de terceiros vai dentro do APK.** `datapack.zip` (20 MB, 5.204 arquivos:
   escudos, logos de competições, estádios, `players.csv` e **924 placas de publicidade
   com marcas reais**, por exemplo `adboards/generic/toyota.webp`) é importado
   automaticamente de `res://datapack.zip`. O autor declarado é um grupo de fãs
   (`settings.csv`) e não há licença de redistribuição.
3. **Build Android ainda não existe e o target API provavelmente está abaixo do exigido.**
   Não há `export_presets.cfg`. O Godot 4.5.1 gera `targetSdk 35` por padrão (conferido no
   `config.gradle` da tag `4.5.1-stable`). A exigência da Play para apps novos desde
   31/08/2026 é provavelmente **API 36 (Android 16)**, mas **não consegui confirmar na
   fonte oficial** (ver 3.2).
4. **Conta de desenvolvedor e teste fechado obrigatório.** Conta pessoal nova precisa de
   verificação de identidade e de **teste fechado com pelo menos 12 testadores por 14 dias
   seguidos** antes de pedir acesso à produção. Isso define o prazo mínimo do lançamento.
5. **"Conteúdo do app" e ficha da loja não existem.** Falta política de privacidade (URL
   pública), formulário de Segurança dos dados, questionário de classificação (IARC),
   público-alvo, ícone PNG 512x512, gráfico de destaque 1024x500 e capturas **sem escudos,
   nomes ou marcas reais**. As 60 capturas em `production/qa/evidence/` mostram o datapack
   e não podem ir para a loja.

Também bloqueia: a pasta do projeto **não é um repositório git**. Sem git não há tag de
versão nem build reproduzível a partir de um commit marcado (seção 7).

---

## 1. Escopo e premissas

| Item | Valor | Origem |
|---|---|---|
| Plataforma | Android / Google Play | pedido do dono |
| `platform.targets` | Mobile, PC | `project.yaml` |
| `platform.cert_tier` | **não definido** | `project.yaml` |
| `project.stage` | não definido | `project.yaml` |
| Monetização (grátis, pago, anúncios, compras no app) | **não definido**: perguntar ao dono | — |
| Data de lançamento | **não definida**: sem data não monto calendário | — |

**Certificação: NOT ASSESSED, cert tier não definido.** A Play Store não tem trilha de
certificação de console. As exigências dela estão nos blocos "Android/Mobile" e "Loja"
abaixo. A versão PC (também em `platform.targets`) está fora deste documento.

---

## 2. Riscos de direitos (nomes reais, escudos, marcas)

### 2.1 O que existe hoje no projeto

| O quê | Onde | Tipo de direito envolvido | Risco |
|---|---|---|---|
| Nomes de clubes reais (centenas) | `src/world_data.gd` (dentro do APK) | Marca registrada dos clubes (nome e sigla) | Alto |
| Nomes de competições (Champions League, Libertadores, Copa do Brasil, FA Cup, Carabao Cup, Copa MX...) | `src/world_data.gd`, abertura de jogo | Marca da UEFA, CONMEBOL, CBF, FA, EFL; "Carabao" é marca de patrocinador | Alto |
| 520 jogadores reais com nome, idade e nota | `assets/data/rosters_real.json` (dentro do APK) | Direito ao nome e à imagem do atleta | Alto |
| Escudos dos clubes e logos de competições | `datapack.zip` → `club_logos/`, `competition_logos/` | Marca e direito autoral do desenho | Muito alto |
| 924 placas com marcas comerciais reais | `datapack.zip` → `adboards/` | Marca de terceiros (anunciantes) | Muito alto |
| Nomes de estádios, base de jogadores | `datapack.zip` → `stadiums.csv`, `players.csv` | Marca / nome de pessoas | Alto |
| O próprio datapack (obra de terceiros) | `datapack.zip`, autor "Champholics" | Direito autoral do pacote; sem licença | Alto |

Base legal no Brasil (para conversar com o advogado, não é parecer):
- Marcas: Lei 9.279/96 (LPI). Usar marca alheia em produto comercial sem autorização é infração.
- Nome e imagem de pessoas: Código Civil, arts. 18 e 20 (uso do nome alheio em propaganda
  comercial sem autorização). Atletas: Lei 9.615/98 (Lei Pelé), direito de imagem.
- Já houve no Brasil ações de jogadores contra jogos de futebol pelo uso do nome sem autorização.

### 2.2 O que a Google Play faz nesses casos

- A política de **Propriedade Intelectual** e a de **Falsificação de identidade** da Play
  proíbem usar marcas, logos e nomes de terceiros sem autorização.
- Basta o dono da marca mandar uma notificação para o app ser **removido**. Remoções e
  violações repetidas podem **encerrar a conta de desenvolvedor inteira**, junto com
  qualquer outro app que o dono publicar nela.
- A análise pode recusar o app logo no primeiro envio se a ficha ou as capturas mostrarem
  escudos ou nomes reais.

### 2.3 Opções de lançamento

| Opção | O que é | Prós | Contras |
|---|---|---|---|
| **A. Mundo fictício + importação pelo usuário** (recomendada) | A versão da loja vem com clubes, jogadores, competições e placas genéricos. Quem quiser importa por conta própria um pacote de dados pelo seletor de arquivos do Android. | Modelo parecido com os "option files" do PES e os arquivos de nomes reais que a comunidade faz para o Football Manager. O app publicado não contém material de terceiros. Já existe base: `src/crest.gd` gera escudo por código e `world_data.gd` já gera nomes. | Ainda sobra risco se o app parecer feito para carregar um pacote específico, ou se a loja insinuar isso. Precisa de trabalho de programação (2.4). |
| B. Licenciar | Contratar licenças com clubes, ligas e sindicato de atletas | Risco legal mínimo | Inviável no custo e no prazo de um projeto indie |
| C. Só mundo fictício, sem importador | Igual à A, mas sem a função de importar | Risco mais baixo de todos | O jogo perde parte do atrativo para quem gosta de nomes reais |
| D. Lançar como está | — | Nenhum | **Não recomendado**: remoção quase certa e risco de perder a conta |

**Por que recomendo a A:** é o único caminho que mantém o atrativo do jogo e tira do app
publicado todo material de terceiros. A escolha é do dono (e do produtor). A forma de
fazer cada item é decisão do programador responsável.

### 2.4 Regras para a opção A ficar segura (requisitos para o build da loja)

Itens para o produtor e o programador. Este documento não altera código.

- [ ] `datapack.zip` **fora do build da loja**: tirar `*.zip` do filtro de exportação
      (o LEIAME manda incluir) e não ler mais `res://datapack.zip` (`src/datapack.gd`, `SOURCES`).
- [ ] `assets/data/rosters_real.json` fora do build, ou trocado por elencos fictícios.
- [ ] `src/world_data.gd`: nomes, siglas e competições fictícios. Evitar nomes "parecidos"
      que, junto com as mesmas cores e sigla, confundam com o clube real
      (ex.: não usar "FLA" + vermelho e preto + "Rubro-Negro do Rio").
- [ ] Nenhum escudo, logo de competição ou placa real no APK/AAB.
- [ ] Placas genéricas (marcas inventadas ou "Craque Manager") no lugar das reais.
- [ ] Textos do jogo sem instruções do tipo "copie o datapack para a pasta do projeto"
      (`src/screens_start.gd`, linha ~317) e sem "importar de novo o pacote do jogo".
- [ ] O importador aceita só formato documentado e genérico ("pacote de dados
      personalizado"), **sem link, sem nome do grupo de fãs, sem indicar onde baixar**.
- [ ] O importador usa o seletor nativo do Android (`use_native_dialog = true` já está em
      `_pick_file()`), então **não precisa** pedir permissão de armazenamento.
      **Não** pedir `MANAGE_EXTERNAL_STORAGE`: a Play restringe essa permissão.
- [ ] Ficha da loja, capturas, vídeo e ícone **só com o conteúdo fictício**. Não citar
      "Brasileirão", "Libertadores", nomes de clubes ou "nomes reais" na descrição.
- [ ] Termos de uso dizendo que o usuário é responsável pelo conteúdo que importa.
- [ ] Nome "Craque Manager": pesquisar no INPI (busca de marcas) e na própria Play se já
      existe app ou marca igual.
- [ ] Consulta com advogado de PI antes da produção, levando esta seção.

---

## 3. Requisitos técnicos da Play Store (2026)

### 3.1 Formato e tamanho
- [ ] **Android App Bundle (.aab)**, obrigatório para apps novos (APK sozinho não é aceito).
      No Godot: preset Android → `Gradle Build` ligado → formato de exportação **AAB**.
- [ ] Download comprimido do módulo base até 200 MB. Sem o datapack o jogo deve ficar bem
      abaixo disso: medir no Play Console (Explorador de pacotes de apps).
- [ ] **Páginas de memória de 16 KB**: exigido para apps com target Android 15 ou mais. O
      Godot 4.5.1 usa NDK r28, que alinha em 16 KB por padrão. Conferir no Explorador
      de pacotes, que avisa se houver biblioteca incompatível.
- [ ] Arquiteturas: `arm64-v8a` obrigatória. `armeabi-v7a` é opcional (celulares antigos).

### 3.2 Target API level
- **Confirmado:** o Godot 4.5.1 exporta com `targetSdk 35`, `compileSdk 35`, `minSdk 24`
  (`platform/android/java/app/config.gradle`, tag `4.5.1-stable`). O branch `master` do
  Godot já usa 36.
- **Não confirmado nesta sessão:** a regra em vigor na Play. O acesso a developer.android.com
  e support.google.com foi bloqueado pela rede deste ambiente, e não havia ferramenta de busca.
  Pelo padrão anual da Google (API 35 exigida a partir de 31/08/2025), a exigência para apps
  novos e atualizações desde 31/08/2026 deve ser **API 36**.
- [ ] **Conferir** em developer.android.com/google/play/requirements/target-sdk (abre no celular).
- [ ] Se for 36: no preset Android, com Gradle Build, definir **Target SDK = 36** e instalar o
      Android SDK 36 na máquina ou no CI que gera o build. A outra saída é atualizar para uma
      versão estável do Godot que já use 36 por padrão (isso é decisão técnica: technical-director).
- [ ] Testar o jogo depois de subir o target (comportamento de tela cheia, voltar, pausar).

### 3.3 Assinatura
- [ ] Criar a **chave de upload** (keystore `.jks`) e guardá-la em dois lugares seguros
      (ex.: pendrive e nuvem particular), junto com as senhas.
- [ ] Usar a **Assinatura de apps do Google Play** (obrigatória com AAB). A Google guarda a
      chave final. Se a chave de upload se perder, dá para pedir a troca no Play Console.
- [ ] Nunca colocar o keystore nem as senhas dentro da pasta do projeto ou num repositório.
- [ ] Configurar o keystore de **release** no preset (Godot: Editor > Configurações do Editor >
      Exportar > Android, ou no próprio preset).

### 3.4 Permissões
- [ ] O jogo é offline e não precisa de nenhuma permissão. No preset, deixar **todas
      desmarcadas** (inclusive `INTERNET`, que só faz falta para depuração remota).
- [ ] Conferir no Play Console a lista de permissões declaradas do AAB enviado.

---

## 4. Conta de desenvolvedor

- [ ] Criar a conta no Play Console (taxa única de US$ 25). Conta **pessoal** ou de
      **organização** (organização exige CNPJ e número D-U-N-S). Decisão do dono.
- [ ] Verificação de identidade (documento) e de telefone/e-mail. Usar um e-mail próprio para
      o jogo, porque o contato do desenvolvedor aparece na ficha.
- [ ] **Conta pessoal criada depois de 13/11/2023:** teste fechado com **no mínimo 12
      testadores ativos por 14 dias seguidos** antes de pedir acesso à produção, e depois
      responder o questionário sobre o teste.
- [ ] Juntar 12+ testadores (contas Google) antes de começar o teste. É o item que mais atrasa.
- [ ] Se for vender o jogo ou ter compras no app: perfil de pagamentos e dados fiscais.

---

## 5. Conteúdo do app (Play Console > Política > Conteúdo do app)

- [ ] **Política de privacidade**: URL pública e acessível sem login. Dá para publicar numa
      página simples no próprio domínio do dono. Conteúdo: o jogo não coleta, não envia e não
      compartilha dados. Os saves (`user://carreira_*.sav`) e o pacote importado ficam só no
      aparelho. Informar um contato.
- [ ] **Segurança dos dados**: declarar "não coleta nem compartilha dados". Só vale enquanto não
      houver anúncios, analytics nem relatório de falhas. Se algum SDK entrar, o formulário
      tem que ser refeito.
- [ ] **Classificação de conteúdo (IARC)**: questionário no próprio Play Console, sem custo. Gera
      ClassInd, PEGI, ESRB etc. automaticamente. Responder com sinceridade: a carreira tem
      dinheiro fictício e "rede social" simulada, mas não tem aposta, compras com dinheiro real
      nem chat com pessoas de verdade.
- [ ] **Público-alvo**: **decisão do dono.** Se marcar menores de 13, o app entra na Política
      para Famílias (regras bem mais rígidas). Recomendo começar com 13+.
- [ ] **Anúncios**: "não contém anúncios", se for verdade.
- [ ] Acesso ao app: sem login, então nada a informar.
- [ ] Demais declarações (notícias, saúde, finanças, governo, VPN): "não".

---

## 6. Ficha da loja

| Item | Exigência da Play | Status |
|---|---|---|
| Nome do app | até 30 caracteres | [ ] |
| Descrição curta | até 80 caracteres | [ ] |
| Descrição completa | até 4.000 caracteres, sem nomes reais (2.4) | [ ] |
| Ícone | **PNG 512x512**, 32 bits, até 1 MB (o projeto só tem `icon.svg`) | [ ] |
| Ícone adaptativo do Android | primeiro plano e fundo 432x432 no preset | [ ] |
| Gráfico de destaque | 1024x500, PNG | [ ] |
| Capturas de tela (celular) | de 2 a 8, PNG, lados entre 320 e 3.840 px, lado maior até 2x o menor. Recomendo 4 a 8 capturas deitadas 1920x1080 | [ ] |
| Capturas de tablet (7" e 10") | opcionais, ajudam a aparecer em tablets | [ ] |
| Vídeo | opcional, link do YouTube | [ ] |
| Categoria | Jogos > Esportes | [ ] |
| Contato | e-mail obrigatório | [ ] |
| Preço e países | decisão do dono. Grátis não pode virar pago depois | [ ] |

- [ ] Capturas **novas**, feitas no build fictício. As de `production/qa/evidence/` mostram
      escudos e nomes reais.
- [ ] Os textos da ficha são de marketing: o community-manager escreve. Este documento só
      lista os requisitos.

---

## 7. Versão e numeração

Proposta. A decisão é do dono.

- **versionName** (o que o jogador vê): `MAJOR.MINOR.PATCH`.
  - `0.9.x` nos testes interno e fechado.
  - `1.0.0` no primeiro lançamento em produção.
  - Correções depois: `1.0.1`, `1.0.2`... Conteúdo novo: `1.1.0`.
- **versionCode** (número inteiro que a Play exige): é o `BUILD` da versão interna
  `MAJOR.MINOR.PATCH.BUILD` e sobe 1 a cada build enviado (1, 2, 3...). **Nunca diminui
  e nunca se repete**: a Play recusa um AAB com versionCode já usado, mesmo que o envio
  tenha sido apagado.
- No Godot: preset Android → `Version > Code` e `Version > Name`.
- [ ] **Colocar o projeto no git** (a pasta não é um repositório hoje) e criar uma tag em cada
      build enviado, por exemplo `v0.9.0.1`. Tag aplicada não se move nem se reaproveita: se o
      mesmo número aparecer com mudanças diferentes, quem já tem a tag fica com ele e o outro
      build vira o próximo PATCH.
- [ ] Guardar o AAB de cada versão enviada.

---

## 8. Passo a passo (o que dá para fazer pelo celular)

**Legenda:** CELULAR = dá pelo celular · PC = precisa de PC ou de build na nuvem

| # | Passo | Onde |
|---|---|---|
| 1 | Decidir a opção de lançamento (2.3), a monetização, o público-alvo e a versão | CELULAR |
| 2 | Falar com um advogado de PI, levando a seção 2 | CELULAR |
| 3 | Programador gera o build fictício (2.4). Trabalho de código, não é deste documento | PC |
| 4 | Criar a conta no Play Console: play.google.com/console no Chrome do celular, com "Site para computador" ligado. Pagar a taxa e verificar a identidade | CELULAR |
| 5 | Publicar a página da política de privacidade | CELULAR (no construtor de sites que o dono já usa) |
| 6 | Gerar o keystore e o **AAB assinado**. O Godot 4.5.1 precisa do editor de PC com Android SDK e JDK. Saída para quem só tem celular: build automático na nuvem (ex.: GitHub Actions com imagem do Godot), disparado e baixado pelo celular. O devops-engineer configura | PC (ou nuvem disparada pelo CELULAR) |
| 7 | Criar o app no Console: nome, idioma padrão pt-BR, "Jogo", grátis/pago | CELULAR |
| 8 | Preencher "Conteúdo do app" (seção 5) | CELULAR |
| 9 | Montar a ficha: textos, ícone, gráfico, capturas PNG tiradas no celular rodando o build de teste | CELULAR |
| 10 | **Teste interno**: enviar o AAB (Testar e lançar > Teste interno), instalar pelo link no próprio celular e testar | CELULAR |
| 11 | **Teste fechado** com 12+ testadores por **14 dias seguidos**. Corrigir o que aparecer, subindo o versionCode a cada envio | CELULAR |
| 12 | Pedir acesso à produção (Painel > questionário do teste fechado) | CELULAR |
| 13 | Produção: lançamento gradual (ex.: 20% → 50% → 100%) e acompanhamento de falhas/ANR em "Android vitals" nas primeiras 72 h | CELULAR |

**Prazo mínimo depois que o build fictício estiver pronto:** cerca de 14 dias de teste
fechado + análise do Google (costuma levar alguns dias e pode passar de uma semana em conta
nova) + uma rodada de correção se o app for recusado. Planejar pelo menos 4 semanas. Com uma
data definida, eu monto o calendário de trás para frente.

---

## 9. Checklist geral do lançamento

### Saúde do código
- Varridos: 24 arquivos `.gd` em `src/`. TODO: 0 · FIXME: 0 · HACK: 0.
- Resultados de testes: **NOT ASSESSED**, nenhuma saída de testes ou log de CI encontrado.
  Existe a suíte `godot --headless --path . res://tests/run_tests.tscn`, que precisa rodar
  e passar no build da loja.

### Build
- [ ] Preset Android criado (`export_presets.cfg` ainda não existe)
- [ ] Build AAB de release limpo e assinado
- [ ] Filtro de exportação **sem** `*.zip` e sem `rosters_real.json`. Manter `match_tuning.json`
      e os outros JSONs de que o jogo precisa
- [ ] Target SDK conforme a regra confirmada em 3.2
- [ ] versionCode e versionName corretos (seção 7)
- [ ] Build reproduzível a partir de uma tag git

### Qualidade
- Bugs abertos: **NOT ASSESSED**, não existe `production/qa/bugs/`. Registrar com `/bug-report`.
- [ ] Zero bugs S1 (Críticos) abertos
- [ ] QA aprova o jogo **sem datapack** (mundo fictício) e **com pacote importado**
- [ ] Testado em pelo menos um celular fraco (2–3 GB de RAM) e um médio: FPS, tempo da
      tela "Preparando clubes...", memória
- [ ] Sessão longa (temporada inteira) sem travar nem vazar memória
- [ ] Saves continuam funcionando depois de atualizar o app

### Android / Mobile
- [ ] Toques e gestos testados em telas de tamanhos diferentes (18:9, 20:9, tablet)
- [ ] Recortes de câmera e barras do sistema não cobrem botões
- [ ] Ir para o fundo, voltar e fechar pelo sistema sem perder progresso
- [ ] Botão "voltar" do Android com comportamento definido (`quit_on_go_back=false` hoje)
- [ ] Nenhuma permissão declarada (3.4)
- [ ] Importador abre o seletor nativo e lida com arquivo inválido ou corrompido sem fechar o jogo
- [ ] Bateria e aquecimento aceitáveis numa partida completa
- [ ] Compras no app: não se aplica, salvo decisão do dono

### Loja e distribuição
- [ ] Seções 5 e 6 completas
- [ ] Classificação IARC recebida
- [ ] Política de privacidade e termos de uso no ar
- [ ] Créditos e licenças de terceiros: fontes, o próprio Godot (licença MIT, exige aviso)
- [ ] Preço e países configurados

### Pronto para lançar
- [ ] Android vitals acompanhado (o jogo não tem SDK de falhas próprio; o Play Console mostra falhas e ANR)
- [ ] Plano de reversão: pausar o lançamento gradual e enviar um hotfix (PATCH + versionCode novo)
- [ ] Anúncio e textos da comunidade prontos (community-manager)
- [ ] Respostas prontas para "cadê os nomes reais?" sem indicar onde baixar pacote (2.4)

### Go / No-Go: **NOT READY**

**Motivo:** bloqueios 1 a 5 da seção 0, mais a falta de git. Itens não avaliados: certificação
(cert tier não definido), bugs (sem registros) e resultados de testes (sem saída).

**Aprovações necessárias:** QA Lead · Technical Director · Producer · Creative Director (mundo
fictício) · Dono (opção de lançamento e consulta jurídica)

---

## 10. Perguntas para o dono

1. Qual opção de lançamento (2.3)? Recomendo a A.
2. O jogo vai ser grátis, pago, ou ter anúncios/compras? Isso muda as seções 4, 5 e 6.
3. Público-alvo: 13+ (recomendado) ou incluir crianças?
4. Conta pessoal ou de organização (CNPJ)?
5. Tem data alvo? Com ela eu monto o calendário com folga para uma recusa.
6. Tem acesso a um PC para gerar o AAB, ou prefere o build na nuvem disparado pelo celular?
