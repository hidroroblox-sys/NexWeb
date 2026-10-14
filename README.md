# 🌊🥚 Fuja do Tsunami por Ovos (Roblox)

Uma versão do **Escape Tsunami For Brainrots** com **ovos** no lugar dos brainrots. As mecânicas e
os números seguem o original, com base na pesquisa em `reports/`. Tudo o que você vê (modelos,
nomes, sons e interface) é feito do zero, nada é copiado do jogo original.

Você corre pelo corredor, pega ovos e se esconde nas trincheiras quando a onda vem. Depois leva os
ovos para o seu celeiro, eles chocam, e os animais dão dinheiro por segundo. Com esse dinheiro você
compra Velocidade e faz Rebirth.

---

## O que já está igual ao original

| Sistema | Como ficou |
|---|---|
| **Mapa** | Corredor reto murado: Início (sem ovos) → Comum → Incomum → Raro → Épico → Lendário → Mítico → Cósmico I e II → Secreto I, II e III → Celestial → **Torre do Tsunami** (segura) |
| **Trincheiras** | Entre as áreas (e mais uma no meio das áreas longas), com rampa para sair |
| **Nichos VIP** | Portas de vidro nas duas paredes de cada área; só quem tem VIP entra e fica seguro |
| **Ondas** | Super Lenta 85 😁, Lenta 120 🙂, Média 140 😐, Rápida 180 😠, Relâmpago 220 😈. Cores: azul-claro, azul, verde-claro, vermelho e roxo brilhante. As maiores são mais altas, o nome e o emoji flutuam sobre a onda, e as ondas podem vir juntas |
| **Aviso** | Contador "PRÓXIMA ONDA" sempre no topo, bipes nos últimos 5 s e sirene quando a onda nasce |
| **Morte** | Ao tocar na onda você morre, os ovos caem onde você morreu (qualquer um pode pegar por 60 s) e você renasce no celeiro |
| **Velocidade** | Começa em 16. Pacotes **+1, +5 e +10** no **anel ciano** do lobby. O preço sobe 17% por nível e o +10 sai pela metade |
| **Carregar** | De 1 a 7 ovos. Preços: $500K, $25M, $1B, $750B… |
| **Celeiro** | **10 slots** iniciais. A **placa verde** na frente compra +1 slot, e a cada 10 slots surge um **andar novo** (até 30, com elevadores) |
| **Coleta** | Um coletor verde por slot: é só pisar nele. A renda continua **offline** (até 8 h) |
| **Nível do animal** | Botão "Subir Nível" (tecla F) em cada animal: a renda é ×1,25 por nível |
| **Rebirth** | Botão roxo. Precisa de Velocidade **40, 50, 60…**; o dinheiro vai de **1,5x a 11x** (R20) e depois a 13,25x (R29). Zera só a Velocidade |
| **Raridades** | 10 raridades, de Comum a Divino, com as cores do original e 77 animais nas mesmas escalas de renda ($2/s até $330M/s) |
| **Mutações** | Esmeralda 1,5x, Dourado 1,5x, Rubi 2x, Elétrico 3x e Diamante 4,25x, com cor, brilho e partículas |
| **Ninho Surpresa** | É o "Lucky Block" com ovos: abre no celeiro com mais chance de mutação e às vezes de raridade maior |
| **Ovo Celestial** | Aparece **1 por vez a cada 15 min** no fim do corredor, com contagem para todos; às vezes vem um Ovo Divino |
| **Taco** | Todo mundo ganha um. A tacada no corredor faz a pessoa **derrubar os ovos** e cair por 2,5 s; no celeiro não funciona |
| **HUD** | Esquerda: **Loja**, **Rebirth** (roxo) e **Índice**. Direita: **Chocando** e **Celeiro** (os botões que você pediu). Topo: contador da onda, área atual e Celestial. Embaixo: Velocidade e dinheiro |

Os **tempos de chocar** são os que você pediu: 1 min, 5 min, 15 min, 30 min, 1 h, 2h30, 6 h e 12 h
(Secreto, Celestial e Divino = 12 h).

---

## 1. Abrir no Roblox Studio

**Jeito mais fácil:** abra o arquivo `FujaDoTsunamiPorOvos.rbxl` (eu mando pelo chat) com
**Arquivo → Abrir do arquivo** e depois use **Arquivo → Publicar no Roblox como…** na sua experiência.

**Com Rojo** (para as atualizações entrarem sozinhas no Studio):
1. Baixe este projeto: branch `claude/funny-cori-8pzgfd` → **Code** → **Download ZIP**.
2. Abra a pasta no **VS Code** e instale a extensão **Rojo** (autor evaera).
3. Aperte Ctrl+Shift+P, escolha **Rojo: Open menu**, clique em **Install Roblox Studio plugin** e depois em **default.project.json**.
4. No Studio: **Plugins → Rojo → Connect**.

Pelo terminal, o mesmo processo: `rokit install`, `rojo plugin install` e `rojo serve`.

> No modo de edição o mundo aparece vazio, e isso é normal: o mapa é montado quando o jogo começa.

**Atualizações direto no seu jogo (sem baixar arquivo):** o script `scripts/publish-to-roblox.sh`
monta o jogo e envia para a sua experiência pela Open Cloud do Roblox. Ele precisa de três variáveis
de ambiente: `ROBLOX_API_KEY` (chave com permissão "universe-places: write"), `ROBLOX_UNIVERSE_ID` e
`ROBLOX_PLACE_ID`. Por padrão ele salva uma versão, que aparece quando você abre o lugar no Studio.
Com `Published`, publica para os jogadores.

**Configurações:** para salvar o progresso, ligue **Configurações do jogo → Segurança → Permitir acesso
do Studio aos serviços de API**. Também coloque **Max Players = 8**.

**Gamepasses:** crie os passes no Creator Hub e coloque os IDs em `GameConfig.GamePasses`. No Studio,
com `TestGamePassesInStudio = true`, todos os jogadores ganham VIP e Turbo para testar; por isso a
Velocidade começa em 36. Mude para `false` se quiser testar sem os passes.

---

## 2. Como testar

No menu **Teste**, escolha **Clientes e servidores**, coloque **2 jogadores** e clique em **Iniciar**.

| # | O que fazer | O que deve acontecer |
|---|---|---|
| 1 | Entrar | Você nasce no seu celeiro e o nome aparece na placa. Do lado de fora, a placa verde mostra "+1 SLOT $1M" |
| 2 | Olhar o topo | Aparecem "🌊 PRÓXIMA ONDA: 0:20" e a pílula "🌟 Celestial 5:00" |
| 3 | Pisar no **anel ciano** entre os celeiros | Abre o painel UPGRADES com Velocidade +1/+5/+10 e Carregar; ao sair do anel ele fecha |
| 4 | Ir ao corredor e pegar um ovo (segurar E) | O ovo vai para as costas. Alguns vêm com mutação (texto colorido e brilho) ou como Ninho Surpresa (caixa com "?") |
| 5 | Esperar a onda | Bipes nos últimos 5 s e depois a sirene. Do fundo vem a onda colorida, com o nome e o emoji em cima |
| 6 | Ficar fora da trincheira | Você morre, o ovo cai no chão (dá para pegar de novo) e você renasce no celeiro |
| 7 | Pular numa trincheira | A onda passa por cima e você sobrevive |
| 8 | Entrar no nicho VIP (porta de vidro na parede) | Com VIP você atravessa a porta e fica seguro; sem VIP a porta bloqueia |
| 9 | Voltar ao celeiro com o ovo | O ovo vai sozinho para um ninho e mostra "Choca em 0:59". O Ninho Surpresa abre na hora |
| 10 | Ovo chocou | O animal aparece com placa (nome, raridade, $/s e "Nv. 1"). O coletor verde enche; pise nele para pegar |
| 11 | Chegar perto do animal e apertar **F** | "Subir Nível" mostra o preço; a renda sobe ×1,25 |
| 12 | Comprar slots na placa até o 11º | Aparece o **2º andar**. Use os elevadores (discos azuis no fundo) |
| 13 | Com Velocidade 40, abrir **Rebirth** | Mostra 1x ➜ 1,5x; ao renascer, a Velocidade volta para 16 e o resto fica |
| 14 | Equipar o **Taco** (tecla 1) e acertar o outro jogador no corredor | Ele cai e derruba os ovos que estava carregando |
| 15 | Esperar 5 min (ou baixar `Celestial.FirstDelay`) | Aviso para todos: "Um OVO CELESTIAL apareceu no fim do corredor!" |

**Para testar mais rápido:** no `GameConfig.luau`, diminua `HatchTime`, `Celestial.FirstDelay`,
`Waves.FirstWaveDelay` e `Speed.BasePrice`.

---

## 3. Onde mudar as coisas

Os números do jogo ficam todos em **`src/ReplicatedStorage/Shared/GameConfig.luau`**: áreas, ondas,
animais, mutações, preços, rebirth, gamepasses e sons.

**Para trocar pelos seus modelos 3D:** coloque o `Model` em **ReplicatedStorage → Assets → Eggs**
(ou **Animals**), com o mesmo nome do campo `Model` no GameConfig (ex.: `OvoGelo`, `Orca`).

**Sons:** a sirene está vazia. Coloque um `rbxassetid://` em `GameConfig.Sounds.Siren`.

---

## 4. Organização do código

```
src/ServerScriptService/
  Main.server.luau      entrada/saída, renascer, ovos caem ao morrer
  Services/
    MapBuilder          corredor, trincheiras, nichos VIP, torre, anel de upgrades
    BarnService         celeiros com andares, placa de slot, chocar, coletores, nível, renda offline
    EggService          ovos por área, mutações, Ninho Surpresa, Ovo Celestial, ovos derrubados
    TsunamiService      ondas (morte checada a cada frame) + esconderijos
    ShopService         velocidade, carregar, slots, nível, vender, rebirth (tudo validado)
    BatService          taco que derruba os ovos
    GamePassService     VIP / Turbo
    DataService         DataStore com retry, autosave e BindToClose
    Movement, Wallet, Sync, Notify, RateLimit, ModelFactory, Billboards, CarryService
src/ReplicatedStorage/Shared/   GameConfig, MapLayout, Formulas, Format, Net, Types, Signal
src/StarterPlayer/StarterPlayerScripts/ClientModules/
  UI/        Theme, UIKit, HUD, Toasts, ConfirmDialog
  UI/Panels/ Upgrades (ShopPanel), Store (Loja), Rebirth, Índice, Chocando, Celeiro
  World/     WaveRenderer (ondas coloridas), WorldFx (portas VIP, anel, efeitos, tacada)
```

**Segurança contra trapaça:** o servidor decide tudo: dinheiro, velocidade, pegar ovo (distância e
intervalo), morte, tacada, compras e rebirth. Todo pedido do cliente é conferido e tem limite de
frequência.

---

## 5. O que ainda não tem (próximas fases)

- **Eventos:** rotação a cada hora (moeda, roleta, mutação de evento, ninho de evento) e o modo "Ondas Malucas".
- **Wave Machine:** fichas de onda para Monstro, Caos, Zen, Pausar e Limpar.
- **Trocas** entre jogadores e a Praça de Trocas.
- **Recompensa do Índice** ao completar uma raridade e as raridades Infinito, Paradoxo e Eterno.
- **Comandos de admin** para eventos ao vivo.
- **Seus modelos** de ovos e animais.
