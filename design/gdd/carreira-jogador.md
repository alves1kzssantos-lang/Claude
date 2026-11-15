# Modo carreira de jogador

## Overview
O jogador cria um atleta (16–19 anos), joga uma peneira com olheiros e assina com um dos
clubes que fizerem proposta. Depois vive a carreira: escalação pelo técnico, nota por jogo,
treino, lesões, fama, rede social, empresário, contratos, seleção, prêmios e vida fora de campo.
Código: `src/pro_career.gd` (regras) e `src/screens_pro.gd` (telas).

## Player Fantasy
Sair da várzea e virar craque — e sentir o peso da fama: a torcida xinga, você pode responder,
e cada resposta tem consequência.

## Detailed Rules
- **Peneira**: jogo festivo (dois times de garotos). Nos lances, só a bola no seu pé obedece
  ao toque; companheiros decidem sozinhos e costumam devolver para você.
- **Propostas da peneira**: cada olheiro exige nota mínima = `nota_minima_base + (força do clube − forca_referencia) × nota_por_ponto_de_forca`. Sem nenhuma, o clube mais fraco oferece time de base.
- **Escalação**: o técnico escala os melhores; seu jogador ganha bônus de confiança e de fase.
  No banco, pode entrar no 2º tempo (`entra_do_banco_chance`).
- **Nota**: base + (sua força − força do time) + gols, assistências, chutes, perdas, resultado,
  cartões; quem joga menos de 30 min puxa para 6,0.
- **Treino**: leve / normal / intenso (XP e risco de lesão). XP vira +1 de força até o potencial.
- **Rede social**: comentários após cada jogo (elogio, neutro, xingamento, zoeira, manchetes).
  Respostas: humilde, provocar, xingar, ignorar. Xingar dá seguidores, mas tira fama/torcida/
  confiança e pode gerar multa, perda de patrocínio e afastamento após 3 polêmicas.
- **Empresário**: 3 níveis (comissão, alcance das propostas, aumento de salário, fama mínima).
- **Janelas**: meio e fim da temporada. Mesma liga = transferência imediata; outra liga =
  ao fim da temporada (o mundo da nova liga é montado e o jogador vai junto).
- **Contrato**: acaba → jogador livre e precisa escolher clube; no último ano o clube pode renovar.
- **Seleção**: convocação nas rodadas de `selecao.rodadas` (força e fase). Copa do Mundo em anos de Copa.
- **Prêmios**: artilheiro, seleção do campeonato, revelação, Bola de Ouro.
- **Vida**: salário, patrocínios (marcas fictícias), compras que mexem em fama e torcida.

## Formulas
Todas em `assets/data/pro_career.json` (nota, fama, treino, lesão, técnico, seleção, redes).

## Edge Cases
- O jogador nunca é vendido/dispensado pela máquina (`me: true` protegido em `_ai_transfer` e `_trim`).
- Estaduais não contratam (`Pro.signs_from`).
- Lesão usa o mesmo contador de suspensão (fica fora da escalação).

## Dependencies
MatchSim (foco no jogador, substituição automática), LanceView (`me_pid`), Game (mundo, temporada), Cups.

## Tuning Knobs
`assets/data/pro_career.json`, `pro_social.json` (textos), `pro_life.json` (compras, empresários, patrocínios).

## Acceptance Criteria
`tests/integration/pro/test_pro_career.gd`: peneira → propostas → assinatura → temporada inteira
(jogador escalado, notas entre 4,5 e 8,5, salário recebido, respostas na rede) → fim de temporada → próxima.
