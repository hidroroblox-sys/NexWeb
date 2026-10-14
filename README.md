# 🌊🥚 Fuja do Tsunami por Ovos (Roblox)

Mistura de **Escape Tsunami For Brainrots** (jogabilidade) com **Steal an Egg** (tema/visual):
corra pelo corredor, pegue ovos, esconda-se nos buracos quando a onda vier, leve os ovos para o
seu celeiro, choque, ganhe dinheiro e compre velocidade para ir cada vez mais longe.

> **Status: Fase 1 (MVP) pronta para testar**, mais os extras que você pediu:
> botão **Índice**, botão **Chocando** (ovos chocando com tempo) e botão **Celeiro**
> (seus animais, quanto cada um dá por segundo, e vender).

---

## 1. Instalar e abrir no Roblox Studio (passo a passo)

O código fica em arquivos `.luau` nesta pasta. O **Rojo** copia esses arquivos para dentro do Studio
automaticamente enquanto você trabalha.

### Jeito mais fácil (Windows, com VS Code)

1. Instale o **Roblox Studio** e o **Visual Studio Code** (code.visualstudio.com).
2. Baixe este projeto: no GitHub, abra o branch `claude/funny-cori-8pzgfd` →
   botão verde **Code** → **Download ZIP** → extraia numa pasta (ex.: `Documentos\FujaDoTsunami`).
3. Abra essa pasta no VS Code (**File → Open Folder**).
4. No VS Code, vá em **Extensions** (Ctrl+Shift+X), procure **"Rojo"** (autor *evaera*) e instale.
5. Aperte **Ctrl+Shift+P**, digite **"Rojo: Open menu"** e:
   - clique em **Install Roblox Studio plugin** (instala o plugin no Studio);
   - clique em **default.project.json** → isso roda o `rojo serve` (fica "Serving...").
6. Abra o **Roblox Studio** → **New** → **Baseplate**.
7. No Studio: aba **Plugins** → botão **Rojo** → **Connect**. Pronto: as pastas
   `ServerScriptService`, `ReplicatedStorage` e `StarterPlayer` são preenchidas com o código.
8. **Salve o lugar** (File → Save to Roblox) e, para o progresso salvar enquanto testa:
   **Home → Game Settings → Security → Enable Studio Access to API Services = ON**.
9. Em **Game Settings → Places** (ou no Creator Hub) deixe **Max Players = 8**.

### Jeito pelo terminal (qualquer sistema)

```bash
# 1) instalar o Rokit (gerenciador de ferramentas)
#    Windows (PowerShell):
Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
#    Mac/Linux:
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash

# 2) dentro da pasta do projeto
rokit install          # instala o Rojo na versão certa (rokit.toml)
rojo plugin install    # instala o plugin do Rojo no Studio
rojo serve             # deixe rodando e clique "Connect" no plugin do Studio
```

Quer só um arquivo para abrir? `rojo build -o FujaDoTsunami.rbxl` gera o lugar pronto.

> ⚠️ O mapa é construído **por código quando o jogo começa** (no modo edição o Workspace fica vazio
> — é normal). O `Baseplate` e o `SpawnLocation` padrão são apagados ao dar Play, porque taparia os buracos.

---

## 2. Como testar a Fase 1

**Test → Clients and Servers → 2 jogadores → Start.** Abrem 3 janelas (servidor + 2 jogadores).

| # | O que fazer | O que deve acontecer |
|---|---|---|
| 1 | Entrar no jogo | Você nasce **dentro do seu celeiro** (8 celeiros vermelhos em meio-círculo). A placa em cima mostra seu nome. O outro jogador recebe outro celeiro. |
| 2 | Olhar a tela | Esquerda: **Loja** (verde) e **Índice** (azul). Direita: **Chocando** (laranja) e **Celeiro** (roxo). Embaixo à esquerda: **Velocidade** e **dinheiro**. Em cima: **"Próxima onda em 0:30"**. |
| 3 | Andar até o corredor | Faixa **ZONA SEGURA** e arco "FUJA DO TSUNAMI!". No corredor aparecem arcos de cada zona (Comum, Incomum…) e o chão muda de cor. Em cima aparece "📍 Zona Comum". |
| 4 | Chegar perto de um ovo | Placa com nome, raridade e **"???"** (animal ainda não descoberto). Aparece **"Pegar Ovo"** (segure E ou toque e segure no celular). |
| 5 | Pegar o ovo | O ovo vai para as **costas** (o outro jogador também vê). Pop-up "Você pegou um Ovo Caipira (Comum)!". Contador "🎒 1/1 CHEIO!". Tentar pegar outro → aviso "só consegue carregar 1". |
| 6 | Esperar o aviso | 10 s antes: faixa colorida **"🌊 TSUNAMI EM 10s!"** com o tipo da onda e bipes. |
| 7 | Ficar parado no corredor | A parede de água vem do fundo. Se ela passar por você **fora de buraco** → tela azul, "O tsunami te levou!", **perde o ovo** carregado e renasce no celeiro em 3 s. |
| 8 | Pular dentro de um buraco | A onda passa **por cima** e você **sobrevive**. Saia pela **rampa** (lado da base). |
| 9 | Entrar no seu celeiro com o ovo | O ovo vai sozinho para um ninho: "Ovo colocado no celeiro!". Em cima dele: barra + **"Choca em 0:59"**. Botão **Chocando** mostra "1" e a lista com o tempo. |
| 10 | Esperar 1 min (ovo Comum) | Explosão de brilho, o ovo vira **animal** (balançando). Pop-up "Seu ovo chocou: 🐔 Galinha (Comum)!" e "Novo animal no Índice!" (bolinha vermelha no Índice). |
| 11 | Esperar alguns segundos | O **coletor verde** na frente do ninho mostra o dinheiro acumulando. **Pise nele** → "+$12" e o dinheiro sobe. |
| 12 | Abrir **Loja** | Comprar **+1 / +10 velocidade**: o número de velocidade sobe e você corre mais rápido. Botões ficam cinza sem dinheiro. Bolinha vermelha na Loja quando dá para comprar algo. |
| 13 | Abrir **Índice** | Animais descobertos coloridos; o resto como **"?"**. Os ovos no corredor que viram esse animal passam a mostrar **$/s** em vez de "???". |
| 14 | Abrir **Celeiro** | Lista dos animais com **$/s** e renda total. **Vender** → recebe dinheiro (animais Lendário+ pedem confirmação). |
| 15 | Encher os 6 ninhos e voltar com outro ovo | "Celeiro cheio! Venda um animal ou compre mais slots". |
| 16 | Sair e entrar de novo (com API ativada) | Dinheiro, velocidade, animais e ovos voltam. O tempo de chocar **continuou contando** enquanto você estava fora. |

**Testando rápido:** em `GameConfig.luau` diminua `HatchTime` (ex.: 10) e `FirstWaveDelay`/`MinInterval`.

---

## 3. Onde mudar as coisas

Tudo que é número está em **`src/ReplicatedStorage/Shared/GameConfig.luau`**:
velocidade, preços, tempo de chocar, $/s dos animais, chances de cada animal no ovo,
intervalo/velocidade das ondas, tamanho das zonas, distância entre buracos, ovos por zona…

**Tempos de chocar** (como você pediu): Comum 1 min · Incomum 5 min · Raro 15 min · Épico 30 min ·
Lendário 1 h · Mítico 2h30 · Cósmico 6 h · Secreto 12 h · Celestial 12 h · Divino 12 h.

### Trocar os placeholders pelos seus modelos 3D
1. No Studio, coloque o modelo (um `Model`) em **ReplicatedStorage → Assets → Eggs** (ou **Animals**).
2. O **nome do modelo** tem que ser igual ao campo `Model` no GameConfig (ex.: `OvoGelo`, `Orca`).
3. Pronto — o jogo usa o seu modelo; se não achar, usa a bolinha placeholder.
   (Essas pastas não são apagadas pelo Rojo. Você também pode exportar como `.rbxm` para
   `src/ReplicatedStorage/Assets/Eggs/`.)

### Ícones e sons
- Ícones da interface são emojis por enquanto (`UI/Theme.luau → Theme.Icons`). Para usar imagem,
  coloque `Theme.Images.Shop = "rbxassetid://..."`.
- Sons em `GameConfig.Sounds`. A **sirene** está vazia: coloque um `rbxassetid://` de sirene do
  Creator Store.

---

## 4. Como o código está organizado

```
src/
  ServerScriptService/
    Main.server.luau        liga tudo + entrada/saída/renascimento
    Services/
      DataService           DataStore (pcall, retry, autosave, BindToClose)
      MapBuilder            constrói o mapa por código
      BarnService           celeiros, slots, chocar, coletores, vender
      EggService            ovos nascendo nos ninhos + "Pegar Ovo"
      CarryService          ovos nas costas (perde ao morrer)
      TsunamiService        ondas + morte checada no Heartbeat (sem .Touched)
      ShopService           compras (velocidade, carregar, slots) validadas
      MovementService       WalkSpeed pelo servidor + anti speed-hack
      Wallet, SyncService, NotifyService, RateLimit, ModelFactory, Billboards
  ReplicatedStorage/
    Shared/   GameConfig, MapLayout (geometria), Formulas (economia), Format, Net, Types, Signal
    Remotes/  Notify, Effect, DataSync, RequestSync, BuyUpgrade, SellAnimal
    Assets/   Eggs/, Animals/  (seus modelos)
  StarterPlayer/StarterPlayerScripts/
    Client.client.luau
    ClientModules/
      UI/        Theme (design system), UIKit (componentes), HUD, Toasts, ConfirmDialog
      UI/Panels/ ShopPanel, IndexPanel, HatchingPanel, BarnPanel
      World/     WaveRenderer (desenha a onda), WorldFx (timers, animações, efeitos)
```

**Anti-exploit:** o cliente só pede e mostra. Dinheiro, velocidade, pegar ovo (distância + cooldown),
morte no tsunami, chocar e compras são decididos no servidor. Todo Remote valida tipo e tem limite de
frequência. O servidor também puxa de volta quem andar muito mais rápido que a velocidade comprada.

**Design da interface** (feito com o guia de UI/UX): botões grandes 3D (88 px na base, ≥ 55 px reais
no celular), sempre ícone + texto, contorno escuro em todo texto (contraste), animações curtas,
HUD só nas bordas e escala automática pelo tamanho da tela. Cores e fontes ficam no `Theme.luau`.

---

## 5. Decisões que eu tomei (me avise se quiser diferente)

- **10 raridades e 8 tempos de chocar:** Celestial e Divino também usam 12 h.
- **O animal é sorteado quando o ovo nasce** (assim a placa do ovo mostra o $/s certo quando você já
  conhece o animal). As chances (ex.: Ovo do Oceano 60% Peixe / 30% Golfinho / 10% Orca) estão no GameConfig.
- **Ovos vão sozinhos para os ninhos livres** ao entrar no seu celeiro (mais gostoso no celular).
- **Coletor por slot** (pisar para coletar), igual aos jogos de brainrot.
- **Ondas podem se sobrepor** (intervalo é de início a início, 45–90 s), como no original.
- **Celeiros em meio-círculo**, todos à mesma distância da entrada do corredor (justo para todos).
- **Vender** fica dentro do painel **Celeiro** (a barraca "VENDER" no mapa entra na Fase 2).
  Antecipei também os upgrades **Carregar** e **Slots** na Loja (sem eles o jogo travava com o celeiro cheio).
- **Sem dinheiro offline** (só o chocar continua offline). Dá para adicionar depois.
- **Preço da velocidade:** `15 × 1,1^nível` (1,15 deixava o fim do jogo impossível com os $/s atuais).
- **Botão de pular:** usamos o botão padrão do Roblox no celular (já é grande e confiável).
- Os **vídeos não chegaram** nesta sessão; o visual do HUD seguiu a sua descrição do Roube um Ovo.
  Mande prints/vídeo que eu ajusto os botões para ficar igualzinho.

## 6. Próximo: Fase 2
Seus modelos de ovos/animais · barraca Vender no mapa · Rebirth (já calculado no código) ·
mutações (Dourado ×2, Diamante ×3, Arco-íris ×5) · Tsunami Monstro, ondas duplas, chuva de ovos ·
sons e animações de chocar melhores · recompensa por completar raridade no Índice.
