# Acessibilidade — Craque Manager (accessibility-specialist, 14/11/2026)
Alvo: WCAG 2.1 AA + Android 48 dp. 1 unidade do jogo ≈ 0,59 dp num celular 6,5" deitado.

## Top 5
1. **Uniformes parecidos e daltonismo (bloqueante):** `_close()` compara RGB. Em 17.328 confrontos, ~650 ficam quase iguais para protanopia e ~380 para deuteranopia (ex.: Brusque×Ituano, Palmeiras×Bragantino, Betis×Barcelona). Goleiro amarelo e8c61c colide com 39 clubes amarelos. Correção: ΔE (CIELAB) ≥ 25 em visão normal e simulada; reserva branco→preto→laranja pela maior diferença; goleiro escolhido entre e8c61c, 9be22e, 2b2b2b, b0b0b8; contorno escuro sob os defensores.
2. **Alvos de toque:** botão padrão 46 u (≈27 dp). Subir para 80 u (≈48 dp), 12 u entre alvos; "Pular" 180×80.
3. **Texto pequeno:** corpo ≥ 24 u, secundário ≥ 20 u, nada abaixo de 18 u; opção "Tamanho do texto" 100/125/150%.
4. **Contraste:** botão verde 2,50:1 → 237a47; azul 3,64:1 → 2463b8; vermelho 4,32:1 → ad3450; cinza da decisão → Color(0.30,0.30,0.32,0.72); marcador verde → branco com contorno; "Energia" sobre placa escura; anel de pressão com ícone/texto além da cor.
5. **Gestos:** passe alto exige segurar 0,35 s sem alternativa → opção de botão "ALTO" e tempo 0,35/0,6/1,0 s; limiar de arraste configurável; aviso quando um gesto é ignorado; força do chute escolhível no toque.

## Já está bom
Sem limite de tempo na decisão do lance; velocidades; pausa; lances podem ser desligados.

## Outros
Faixa de resultado ≥ 2,5 s; rótulos de velocidade fiéis; dica do lance em 3 chips curtos; trocar clip_text por quebra de linha; menu de Acessibilidade agrupando tudo.
