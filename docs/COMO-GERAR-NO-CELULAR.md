# Como gerar e baixar o Craque Manager pelo celular

Você não precisa de computador. O GitHub monta o jogo para você (leva uns 10 a 20 minutos) e você baixa o resultado no celular.

## 1. Gerar o jogo (rodar o workflow)

1. No celular, abra o navegador (Chrome) e entre em `github.com`. Faça login.
2. Abra o repositório **alves1kzssantos-lang/Claude**.
3. Toque na aba **Actions**. Se não achar a aba, toque em `...` (mais) ou ative **"Site para computador"** no menu do Chrome.
4. Na lista da esquerda (ou no topo), toque em **Build Craque Manager**.
5. Toque em **Run workflow**, deixe a branch **main** e toque no botão verde **Run workflow**.
6. Espere. Atualize a página até aparecer uma bolinha **verde** (deu certo) ou **vermelha** (deu erro).
   - Todo push de código também dispara esse processo sozinho.

O que acontece lá dentro: roda os testes do jogo, gera o APK e gera a versão Web. Se um teste falhar, o processo para e fica vermelho (de propósito).

## 2. Baixar e instalar o APK (Android)

1. Toque na execução que ficou verde.
2. Role até o fim da página, na parte **Artifacts**.
3. Toque em **craque-manager-apk**. Baixa um arquivo `.zip`.
4. Abra o `.zip` pelo app **Arquivos** (ou Downloads) e extraia. Dentro está `craque-manager-debug.apk`.
5. Toque no APK para instalar. Na primeira vez o Android pede para **permitir instalar de fontes desconhecidas** para o app que você usou (Chrome ou Arquivos). Toque em **Configurações**, ative **Permitir desta fonte**, volte e toque em **Instalar**.
6. Se aparecer aviso do Google Play Protect, toque em **Instalar mesmo assim** (o APK é de teste e não vem da loja).
7. Abra **Craque Manager**. O jogo abre na horizontal.

Para atualizar: baixe o APK novo e instale por cima (os saves ficam, desde que seja gerado pelo mesmo workflow; a chave de debug é criada de novo a cada build, então se o Android reclamar de "conflito de assinatura", desinstale o jogo antes e instale de novo, isso apaga o save).

## 3. Jogar a versão Web (navegador do celular)

**Opção A, por link (precisa do GitHub Pages ligado, ver abaixo):**
`https://alves1kzssantos-lang.github.io/Claude/`

Ligar o Pages uma única vez: no repositório, **Settings > Pages > Build and deployment > Source: GitHub Actions**. Depois rode o workflow na branch main. Obs.: o Pages grátis só funciona em repositório **público**.

**Opção B, sem Pages:** baixe o artifact **craque-manager-web** (zip). Ele precisa ser servido por um site para funcionar, então a Opção A é a recomendada.

Dica: use o celular deitado e, no Chrome, toque em `...` > **Adicionar à tela inicial** para abrir como se fosse um app.

## Problemas comuns

| Problema | O que fazer |
|---|---|
| Bolinha vermelha | Toque na execução, depois no passo com **X** vermelho e leia a mensagem. Se for "Rodar a suíte de testes", é um teste do jogo que falhou. |
| Não acho "Artifacts" | Só aparece em execuções terminadas. Role até o final da página. |
| Artifact sumiu | Ficam guardados por 30 dias. Rode o workflow de novo. |
| Datapack não aparece no jogo | `datapack.zip` não está no repositório (está no `.gitignore`), então o jogo gerado vem sem ele. Importe pelo próprio jogo (Datapack > Importar). |
