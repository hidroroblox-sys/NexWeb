# Escape Tsunami For Brainrots: HUD, UI and Visual Style

> **Method note:** This session could not fetch pages directly. WebFetch and curl were blocked by the sandbox egress proxy (DNS/403 on beebom.com, fandom.com, roblox.com and bloxinformer.com). As a result, **no screenshots or images could be viewed**, and every finding below comes from search-engine extracts of guide and wiki pages. Treat pixel positions, hex colors and fonts as **unverified** unless a source is quoted. A developer should check them against a recent gameplay video or a screenshot before finalizing the design.
>
> **Identity of the game:** The Roblox experience is titled "[🌊] Escape Tsunami For Brainrots!", place ID 131623223084840, by the group "Wave of Brainrots". Its official tagline is "Run fast and grab Brainrots! Don't let Tsunami catch you!" ([Roblox game page](https://www.roblox.com/games/131623223084840/Escape-Tsunami-For-Brainrots); [Rolimons](https://www.rolimons.com/game/131623223084840)). Rolimons gives the creation date as Dec 15, 2025 and about 5.7B visits ([Rolimons](https://www.rolimons.com/game/131623223084840)). A French guide says it launched in January 2026 ([Gamewave.fr](https://gamewave.fr/roblox/roblox-codes-escape-tsunami-for-brainrots/)). **Do not confuse it with** the Fortnite Creative island of the same name (island code 7113-0641-3989, which uses "Password Terminals") or with browser clones on CrazyGames and escapetsunamibrainrots.org (platformers with jump/dash upgrades) ([AllThings.how codes](https://allthings.how/escape-tsunami-for-brainrots-codes/); [FandomWire Fortnite codes](https://fandomwire.com/escape-tsunami-for-brainrots-in-fortnite-codes/)).

## 1. HUD layout: which buttons exist, where they sit, their colors and order

### Takeaway
Guides confirm a **left-side vertical button column** that includes **Store**, **Trade** (next to Store) and **Rebirth**, plus a **Settings cogwheel**. A **Wave Machine** button is reported on the **right side**, and a **wave countdown timer** sits at the **top of the screen**. Reliable sources say there is **no Codes button**. The exact order, icons, colors and badges of the buttons are not documented in any text source I could reach.

### Cited Findings
- **Rebirth button on the left side of the screen:** "click the Rebirth button on the left side of the screen". Clicking it opens a panel ([Sportskeeda rebirth guide](https://www.sportskeeda.com/roblox-news/escape-tsunami-for-brainrots-rebirth-guide); [TechWiser rebirth](https://techwiser.com/escape-tsunami-for-brainrots-rebirth/); [Beebom rebirth guide](https://beebom.com/escape-tsunami-for-brainrots-rebirth-guide/)).
- **Store button on the left side:** "players can open the Store from the left side of the screen and choose their desired deal" ([Sportskeeda Wave Machine guide](https://www.sportskeeda.com/roblox-news/escape-tsunami-for-brainrots-wave-machine-guide); [GameRant Trade Tokens](https://gamerant.com/roblox-escape-tsunami-for-brainrots-how-get-trade-tokens-fast/)).
- **Trade button on the left side, next to Store:** "Press the Trade button on the left side of the screen, next to Store" ([Sportskeeda how to trade](https://www.sportskeeda.com/roblox-news/how-trade-escape-tsunami-for-brainrots)).
- **Settings uses a cogwheel icon.** Trade requests can be set to On, Off or Friends-only in the settings ([Sportskeeda how to trade](https://www.sportskeeda.com/roblox-news/how-trade-escape-tsunami-for-brainrots)).
- **Wave Machine on-screen button on the right side:** one guide says the Wave Machine is "accessible by pressing the namesake button on the right side of the screen". Others describe it only as a physical machine next to the Wheel on the left of the Safe Zone ([Sportskeeda Wave Machine guide](https://www.sportskeeda.com/roblox-news/escape-tsunami-for-brainrots-wave-machine-guide); [TechWiser Wave Tokens](https://techwiser.com/escape-tsunami-for-brainrots-wave-tokens/); [Fandom Wave Machine](https://escape-tsunami-for-brainrots.fandom.com/wiki/Wave_Machine)).
- **Countdown timer at the top:** "a countdown timer will be on the top part of screen, depicting how long it is before the next wave". When it reaches zero, a siren sounds ([LDPlayer safe spots guide](https://www.ldplayer.net/blog/escape-tsunami-for-brainrots-roblox.html) / [MuMuPlayer walkthrough](https://www.mumuplayer.com/blog/roblox-escape-tsunami-brainrot-walkthrough-guide.html); the search extract did not say which of the two contains the quote).
- **No Codes button:** "there is no 'Codes' button or text field anywhere in the game UI" ([AllThings.how, codes: what exists](https://allthings.how/escape-tsunami-for-brainrots-codes-what-exists-and-how-to-get-free-rewards/)). Gamewave.fr and Destructoid also report no code system ([Gamewave.fr](https://gamewave.fr/roblox/roblox-codes-escape-tsunami-for-brainrots/); [Destructoid](https://vip-develop.destructoid.com/?p=1167950)). **Contradicted by** a July 2026 AllThings.how page that describes an on-screen Codes button and "Wave Coins" ([AllThings.how codes](https://allthings.how/escape-tsunami-for-brainrots-codes/)). That page probably mixes in the Fortnite version.
- **No confirmed daily-login, playtime or gift button.** The only consistently reported freebie is an Epic Brainrot for joining the developer's Roblox group ([AllThings.how, codes: what exists](https://allthings.how/escape-tsunami-for-brainrots-codes-what-exists-and-how-to-get-free-rewards/)).
- **Index exists** (it tracks every Brainrot rescued, sorted by rarity), but no source gives the location of its button ([Fandom (alt wiki) Index](https://escapetsunamiforbrainnrot.fandom.com/wiki/Index)).

### Inferences
- A likely layout to reproduce, assembled from the findings above: a **left vertical stack** of square or rounded buttons (Store, Trade, Rebirth, and probably Index and Settings), a **top-center wave countdown**, and a **right-side Wave Machine button**. The order of the left stack is not confirmed. "Trade next to Store" suggests the two are adjacent.
- The game has several Robux shops (Store, Wave Machine, Rebirth skip, wheel spins). Many Roblox simulators mark buttons with red notification dots or "!" badges, but **no source confirms badges in this game**.

### Gaps
- Exact pixel and anchor positions, button sizes, icon art, button colors and gradients for the HUD buttons.
- Whether Index, Settings, Base Skins and Spins are HUD buttons or world interactions.
- Notification badges: no source.
- Whether a top bar shows current wave type or zone name: no source.

## 2. How money, speed, carry, wave timer and zone are displayed

### Takeaway
Money is plain "$" cash with K/M/B/T suffixes in guides (e.g. "$500,000", "$25M", "3.83T"). Speed is an integer stat (e.g. 40, 140, 230) used to gate rebirths and zones. The wave countdown is at the top, followed by a siren. The **on-screen widgets for money, speed and carry count are not described** by any reachable source.

### Cited Findings
- Guides quote carry upgrade prices as "$500,000", "$25 million", "$1 billion" and "$750 billion" ([Beebom carry guide](https://beebom.com/how-to-carry-more-brainrots-in-escape-tsunami-for-brainrots/)). Another guide gives speed costs as "around 210K", "396M" and "3.83T" ([AllThings.how shops / speed guides](https://allthings.how/escape-tsunami-for-brainrots-shops-explained/)). A calculator shows "$721.77K" ([BloxCalculator](https://bloxcalculator.org/escape-tsunami-for-brainrots-speed-upgrade-calculator)). These show the community uses short-scale suffixes (K, M, B, T). The in-game formatting is not confirmed.
- Brainrots earn money per second, with top items traded as "$4T+/s" ([Itemku listing title](https://www.itemku.com/en/product/roblox-brainrots-4ts-escape-tsunami-for-brainrots-shev-shop/4017858)). This suggests a "$X/s" notation.
- Speed is a numeric stat. Rebirth 1 needs Speed 40, and each later level adds +10, up to Rebirth 20 at Speed 230 ([AllThings.how rebirth](https://allthings.how/how-rebirth-works-in-escape-tsunami-for-brainrots-all-20-levels/); [FandomWire rebirth list](https://fandomwire.com/roblox-escape-tsunami-for-brainrots-rebirth-list-all-requirements-rewards/)). TechWiser says the Secret Zone needs a minimum of 140 Speed ([TechWiser speed guide](https://techwiser.com/escape-tsunami-for-brainrots-speed-guide/)).
- There is a separate "carry speed" that affects movement while carrying a brainrot ([Escape Tsunami calculator site](https://escapetsunamiforbrainrotscalculator.com/)). This is a secondary source.
- Carry capacity runs from 1 to 7 brainrots per run ([Beebom carry guide](https://beebom.com/how-to-carry-more-brainrots-in-escape-tsunami-for-brainrots/); [Roonby carry slots](https://roonby.com/2026/02/19/carry-slots-escape-tsunami-for-brainrots-explained-is-it-worth-to-upgrade/)).
- **Wave warning:** a top countdown, then "a distinct siren" that is "the only warning before the wave". Timing after the siren conflicts: 3–5 s, 5–10 s, or (less reliable) 15–20 s ([LDPlayer](https://www.ldplayer.net/blog/escape-tsunami-for-brainrots-roblox.html); [MuMuPlayer](https://www.mumuplayer.com/blog/roblox-escape-tsunami-brainrot-walkthrough-guide.html)).
- Players should check whether the incoming tsunami "is designated as Super Slow or Slow" before setting out. That implies the wave type is visible before or as it arrives ([Filibuster Blog beginner guide](https://thefilibusterblog.com/escape-tsunami-for-brainrots-essential-walkthrough-guide-for-beginners/); [1v9.gg](https://1v9.gg/blog/escape-tsunami-for-brainrots-beginners-guide)).
- **The wave itself carries its name label plus an emoji:** "Each wave has its name displayed on it, along with a specific emoji" ([Designer Daily beginner guide](https://www.designer-daily.com/how-to-play-escape-tsunami-for-brainrots-a-beginners-guide-211326)). The emoji sits **under** the name. A wiki discussion notes that some event waves "lack the emoji under their name" ([Fandom discussion: Waves](https://escape-tsunami-for-brainrots.fandom.com/f/t/Waves)).
- **Zone indicator:** none described. Zones are named by rarity (Common, Uncommon, Rare, Epic, Legendary, Mythical, Cosmic, Secret, Celestial) ([games.gg zones](https://games.gg/roblox/guides/escape-tsunami-for-brainrots-zones-guide/); [Fandom Areas](https://escape-tsunami-for-brainrots.fandom.com/wiki/Areas)).

### Inferences
- Display cash as "$" plus a short-scale suffix (K/M/B/T/Qa…) and income as "$X/s". The guide numbers follow this convention.
- Wave identity is shown **in the world** as a floating name and emoji label on the wave (a billboard), not only in the HUD.

### Gaps
- Where the cash and speed counters sit on screen, and their color, icon and font: no text source.
- Whether there is a carry counter (e.g. "2/4") on the HUD: no source.
- The exact wording of the countdown (e.g. "Next wave in 12s") and its color: no source.
- Whether a zone-name banner appears on entering a zone: no source.

## 3. Menus and panels (Upgrades/Speed shop, Rebirth, Index, Store/Gamepasses, Trade, Wave Machine)

### Takeaway
The **Upgrades shop** is a world-space **cyan ring/circle** that opens a panel with +1/+5/+10 Speed rows and a carry row (arm icon), bought with **green Upgrade buttons**. The **Rebirth** panel shows the Speed requirement and the multiplier, with a **big purple "Rebirth" button** and a Robux "Skip Rebirth Keep Speed!" option. The **Store** sells passes and packs at strike-through sale prices. **Trade** uses '+' slots and green Accept buttons.

### Cited Findings
**Upgrades / Speed shop**
- It is a "glowing Cyan Circle in the lobby area". You walk in to open the shop and buy with in-game cash ([TechWiser speed guide](https://techwiser.com/escape-tsunami-for-brainrots-speed-guide/); [Noleep speed guide](https://noleep.com/en/escape-tsunami-brainrots-speed-guide/)).
- It offers three purchase options: **+1, +5 or +10 Speed**. Each purchase raises the price ([TechWiser speed guide](https://techwiser.com/escape-tsunami-for-brainrots-speed-guide/)). You press the green "Upgrade" button ([AllThings.how shops explained](https://allthings.how/escape-tsunami-for-brainrots-shops-explained/)).
- **Carry upgrade:** "enter the cyan-colored ring to open the shop. Click on the green button beside the arm icon to upgrade your carry." The maximum is 7 ([Beebom carry guide](https://beebom.com/how-to-carry-more-brainrots-in-escape-tsunami-for-brainrots/)).
- The upgrade store also sells jump upgrades (for "floating brainrots") ([GGWTB hidden mechanics](https://ggwtb.com/blog/escape-tsunami-for-brainrots-unlocking-hidden-mechanics-glitches--events--and-secret-obbys)). This is a single, lower-reliability source.

**Rebirth panel**
- The panel displays the required Speed, the Money Multiplier you will gain, and "a big purple 'Rebirth' button". A **"Skip Rebirth Keep Speed!"** option costs 89 Robux ([Sportskeeda rebirth](https://www.sportskeeda.com/roblox-news/escape-tsunami-for-brainrots-rebirth-guide); [Beebom rebirth](https://beebom.com/escape-tsunami-for-brainrots-rebirth-guide/)).
- Values: Rebirth 1 needs Speed 40 and gives 1.5x money. Each level adds +10 Speed and +0.5x, up to Rebirth 20 at Speed 230 for 11x ([AllThings.how rebirth](https://allthings.how/how-rebirth-works-in-escape-tsunami-for-brainrots-all-20-levels/)). The maximum level conflicts: 20 (Sportskeeda/Beebom), 25 (GameRant), 26 (AllThings) or 27. Game8 says going past Rebirth 23 needs a Divine Brainrot placed in your base ([Game8 max rebirth](https://game8.co/games/Roblox/archives/580777); [GameRant](https://gamerant.com/roblox-escape-tsunami-for-brainrots-how-rebirth-fast-all-levels/)).
- Rebirth resets Speed and Carry ([Beebom carry guide](https://beebom.com/how-to-carry-more-brainrots-in-escape-tsunami-for-brainrots/)).

**Index**
- It tracks every Brainrot rescued, sorted by rarity, and keeps **separate index pages per mutation** (Gold and Diamond have their own pages). Blood, Diamond, Emerald, Gold, Radioactive, Admin and Electric mutations are indexed ([Fandom (alt) Index](https://escapetsunamiforbrainnrot.fandom.com/wiki/Index)).
- Completing an Index category unlocks a unique base skin ([Fandom Brainrots](https://escape-tsunami-for-brainrots.fandom.com/wiki/Brainrots)).

**Store / gamepasses / dev products** (prices conflict between sources and dates)
- **VIP:** 85 Robux (wiki), 149 (Rolimons pass page and a guide), or 175 (Rolimons game page) ([Fandom Gamepass](https://escape-tsunami-for-brainrots.fandom.com/wiki/Gamepass); [Rolimons VIP](https://www.rolimons.com/gamepass/1653433269); [AllThings.how VIP](https://allthings.how/vip-gamepass-in-escape-tsunami-for-brainrots-roblox/)).
- **VIP+:** 888 Robux, with perks including "Insta Revive Chance, +5 Bonus Lucky Blocks, Rainbow Magic Carpet" ([Fandom Gamepass](https://escape-tsunami-for-brainrots.fandom.com/wiki/Gamepass)).
- **Server Luck 2x** costs 199 (5 minutes), **Rainbow Shield** 295, and a **Private Server** 67/month ([Fandom Gamepass](https://escape-tsunami-for-brainrots.fandom.com/wiki/Gamepass)).
- **Sale pricing is shown as "X instead of Y":** 5 Spins at 189 instead of 245, the Starter Pack at 19 instead of 79, and the Secret Pack at 199 instead of 349 ([Fandom Gamepass](https://escape-tsunami-for-brainrots.fandom.com/wiki/Gamepass)). This implies a strike-through old price in the Store.
- The Heartbreaker base skin was sold for 499 Robux and has since been removed ([Fandom Gamepass](https://escape-tsunami-for-brainrots.fandom.com/wiki/Gamepass)).
- Third-party resale lists other passes: "Flying Carpet, Blackhole Slap, Laser Gun, Ban Hammer, 2X MONEY, VIP, Server Luck, Admin Panel" ([Carousell](https://www.carousell.ph/video-gaming/in-game-products/brainrot/q-5261/)). **These are unverified as official.**
- **Trade Tokens** (sold in the Store): 100 for 100 R$, 500 (+25 free) for 500 R$, and 2000 (+100 free) for 2000 R$ ([Deltia's trading update](https://deltiasgaming.com/roblox-escape-tsunami-for-brainrots-trading-update-guide/)).
- **Lucky Blocks** can be bought with Robux: standard, Alien, Jackpot, Arcade and Golden Nest variants ([Roblox Fandom](https://roblox.fandom.com/wiki/Wave_of_Brainrots/Escape_Tsunami_For_Brainrots)).

**Trade menu**
- Flow: pick a player on the server, they have about 10 s to accept, add brainrots with **'+' icons**, both press the **green Accept** button, and the trade completes **5 s** after both confirm. Trade Tokens are added in steps of 10 or 100 ([Sportskeeda how to trade](https://www.sportskeeda.com/roblox-news/how-trade-escape-tsunami-for-brainrots); [TechWiser trade tokens](https://techwiser.com/escape-tsunami-for-brainrots-trade-tokens/)).

**Wave Machine** (added in the Jan 2026 "Wave Wednesday" update)
- It is paid with Wave Tokens: 10 for 19 R$, 100 for 187 R$, 1000 for 1499 R$. Effects: Beast Wave (8 tokens), Chaos Waves (50), Ragdoll Waves (75), Pause Waves (99, which freezes wave spawns for 20 s) and Clear Waves (199) ([Sportskeeda Wave Machine](https://www.sportskeeda.com/roblox-news/escape-tsunami-for-brainrots-wave-machine-guide); [Fandom Wave Machine](https://escape-tsunami-for-brainrots.fandom.com/wiki/Wave_Machine); [FFBooyah Jan 2026 update](https://ffbooyah.com/2026/01/31/escape-tsunami-for-brainrots-new-update-explained-wave-machine-map-expansion-new-waves/)).

**Mystery Merchant** (an NPC shop priced in Trade Tokens)
- Rotating stock: Divine units; Celestial, Divine and Infinity Lucky Blocks; Base Skins; VIP passes. Its location is reported inconsistently: left side of the map, near the Wave Machine, or in the lobby ([TechWiser Mystery Merchant](https://techwiser.com/escape-tsunami-for-brainrots-mystery-merchant-guide/); [Deltia's](https://deltiasgaming.com/roblox-escape-tsunami-for-brainrots-trading-update-guide/)).

### Inferences
- **Color coding to reproduce:** cyan for the shop trigger ring, green for purchase, Upgrade and Accept buttons, and purple for Rebirth. These three are the only button colors confirmed in text.
- The Upgrades panel likely uses one row per stat (Speed with +1/+5/+10, Carry with an arm icon), each with a price on a green button.

### Gaps
- Panel background colors, borders, corner radius, close-button style and title fonts.
- The exact price text format on buttons.
- The Index grid layout (card size, how locked or silhouette entries look, rarity tabs).
- The layout of the Store tabs.

## 4. Base/plot visuals: slots, podiums, cash collection and brainrot billboards

### Takeaway
Each player has a multi-floor base where each upgrade adds one slot and every 10 slots adds a new floor. You upgrade it via a **clickable signboard outside the base**. Cash is collected by **walking over green buttons** inside the base, and each placed brainrot has an **upgrade button beside it** (hold to mass-upgrade). No source describes the billboard text above brainrots. Rarity colors are documented on NamuWiki.

### Cited Findings
- "Cash is collected at the green buttons inside your base; walking over them deposits the accumulated cash into your balance" ([AllThings.how money guide](https://allthings.how/escape-tsunami-for-brainrots-money-guide-fastest-ways-to-scale-your-income/)).
- Brainrot upgrade: you use the button beside the placed Brainrot, "your Brainrot will level up, and the required money will be deducted". Holding the button mass-upgrades ([Fandom Survival Guide](https://escape-tsunami-for-brainrots.fandom.com/wiki/Survival_Guide)). Each level multiplies income by 1.25x. The maximum level is 200 (wiki) or 250, and going past 200 needs Rebirth 26 ([AllThings.how level caps](https://allthings.how/every-max-level-cap-in-escape-tsunami-for-brainrots-explained/)).
- Base upgrade: "go near the signboard outside your base. Then, click on the board". Each upgrade adds one slot, and every ten slots adds a new floor. Slot 11 costs 1M and slot 31 costs 1,000 billion ([Beebom base upgrade](https://beebom.com/how-to-upgrade-base-in-escape-tsunami-for-brainrots/)). After base level 20, further upgrades need a higher Rebirth ([Shigjeta base upgrades](https://www.shigjeta.net/escape-tsunami-for-brainrots-base-upgrades-how-slots-floors-and-rebirths-really-fit-together/)).
- **Base Skins** (whole-base cosmetic themes): Default, Gamer, Glitch, Heartbreaker, Money, Valentine, Brainrot Master, Bastion ("steel, concrete"), Corruption ("black panels with red glow"), Crownfire, Solarflare, Wraith, plus Carnival Tower and Ringmaster Tower. They come from the Mystery Merchant, the Ticket Machine or Lucky Blocks. Brainrot Master needs every non-mutated brainrot plus Rebirth 29 ([Fandom Base Skins](https://escape-tsunami-for-brainrots.fandom.com/wiki/Base_Skins); [Fandom Update Log](https://escape-tsunami-for-brainrots.fandom.com/wiki/Update_Log); [TechWiser base skins](https://techwiser.com/escape-tsunami-for-brainrots-base-skins/)).
- **Rarity colors (NamuWiki):** Common gray, Uncommon light green, Rare blue, Epic purple, Legendary yellow, Mythic red, Cosmic magenta, Secret black, Celestial pink, Divine light yellow, Infinity rainbow, Paradox achromatic ([NamuWiki Brainrot page](https://en.namu.wiki/w/Escape%20Tsunami%20For%20Brainrots!/%EB%B8%8C%EB%A0%88%EC%9D%B8%EB%A1%AF)).
- **Lucky Block colors:** Common is a white cube, Uncommon green, Rare light blue, Epic purple, Legendary yellow, Mythical pink, Cosmic cherry pink and Secret red. Celestial and Divine blocks appear only in Wacky Waves in the Celestial Area ([GameRant Lucky Blocks](https://gamerant.com/roblox-escape-tsunami-for-brainrots-all-lucky-block-types-rewards/); [AllThings.how Lucky Blocks](https://allthings.how/every-lucky-block-in-escape-tsunami-for-brainrots-and-how-to-obtain-them/); [Beebom Lucky Blocks](https://beebom.com/escape-tsunami-for-brainrots-lucky-blocks/)). Note the conflict on Mythic: block pink vs NamuWiki rarity red.
- **Rarity tiers:** 12 are listed: Common, Uncommon, Rare, Epic, Legendary, Mythic, Cosmic, Secret, Celestial, Divine, Infinity, Paradox ([Fandom Brainrots](https://escape-tsunami-for-brainrots.fandom.com/wiki/Brainrots)). Another wiki page says 11, and Eldorado adds "Eternal" ([Eldorado](https://www.eldorado.gg/blog/all-brainrots-escape-tsunami-for-brainrots/)).
- **Mutation visuals:** Gold is a "yellow / gold tint on the brainrot". Rainbow "cycles through RGB colors continuously" (single source) ([AllThings.how mutations](https://allthings.how/escape-tsunami-for-brainrots-mutation-multipliers-explained/); [mutations calculator site](https://escapetsunamiforbrainrotscalculator.com/mutations)). Multipliers conflict: Gold 1.25x, 1.5x or 2x; Diamond 1.5x to 4.5x.

### Inferences
- A base can be built as a multi-story structure with 10 pads per floor. Each pad has a brainrot on it, an adjacent upgrade button, and a green step-on collect button. A clickable sign at the entrance handles slot purchases.
- The billboard above each brainrot most likely shows name, rarity (in its rarity color), $/s and level, as in sibling "brainrot" games, but **this is not confirmed for this game**.

### Gaps
- What the billboard above placed or wild brainrots looks like (fields, colors, outline): **no source found**.
- How the collect button shows pending cash (e.g. a "$X" floating label): no source.
- The base's default materials and colors, the podium shape, and how bases are arranged relative to each other: no source.

## 5. World visuals: map layout, zones/biomes, gaps, tsunami wave, lighting, signs and events

### Takeaway
The map is a **linear run from a Safe Zone (lobby with bases, shops, wheel and Wave Machine) outward through rarity-ordered zones** (Common nearest, then Secret and Celestial farthest, near where waves start). **Trenches/gaps between zones** are shelters where you sink below the water. VIP players also get **glass-door alcoves along the right wall**. Waves are **color-coded by type** (light blue, blue, light green, red, purple), grow taller and wider with tier, and carry a floating name and emoji label.

### Cited Findings
**Layout and zones**
- The closer a zone is to spawn, the lower its rarity and the more forgiving the tsunamis. Speed ranges conflict: games.gg gives Common 0–20, Rare 40–65, Mythical 110–130, Secret 150+ and Celestial 150+ ("Endgame"). TechWiser and Rosenberry give Common 0–10 and Uncommon 10–20 ([games.gg zones](https://games.gg/roblox/guides/escape-tsunami-for-brainrots-zones-guide/); [TechWiser zones](https://techwiser.com/escape-tsunami-for-brainrots-all-zones/); [Rosenberry Rooms](https://www.rosenberryrooms.com/all-escape-tsunami-zones-brainrots-guide/)).
- Celestial brainrots spawn "in a zone beyond the Secret area, near where the tsunami waves begin", about every 10–15 minutes ([VirtGold](https://virtgold.com/blog/all-brainrot-categories-in-escape-from-tsunami-for/); [Fandom Brainrots](https://escape-tsunami-for-brainrots.fandom.com/wiki/Brainrots)).
- The zone count conflicts: 9 or 6 zones ([TechWiser wiki](https://techwiser.com/escape-tsunami-for-brainrots-wiki/); [escapetsunamiforbrainrots.com zones](https://escapetsunamiforbrainrots.com/escape-tsunami-for-brainrots-wiki/progression-zones)).
- **Gaps:** "trenches sit between the zones, and a character can sink below the water level there". They are described as "tight spaces in the terrain between each Brainrot zone" used as emergency shelters. Enter 3–5 s before impact ([LDPlayer guide](https://www.ldplayer.net/blog/escape-tsunami-for-brainrots-roblox-guide.html); [1v9.gg](https://1v9.gg/blog/escape-tsunami-for-brainrots-beginners-guide); [Roblox Fandom: "underground gaps"](https://roblox.fandom.com/wiki/Wave_of_Brainrots/Escape_Tsunami_For_Brainrots)).
- **VIP safe spots:** "safe spots along the right wall of every zone, each behind glass doors", also described as "large indents on the side walls" ([LDPlayer safe spots](https://www.ldplayer.net/blog/escape-tsunami-for-brainrots-roblox.html); [U7Buy beginner guide](https://www.u7buy.com/blog/escape-tsunami-for-brainrots-beginner-guide/)). The map has side walls, so it is a corridor or track.
- If a wave hits you, you respawn at the Safe Zone and lose the Brainrots you were carrying. Placed ones stay ([Roblox Fandom](https://roblox.fandom.com/wiki/Wave_of_Brainrots/Escape_Tsunami_For_Brainrots); [Beebom beginner guide](https://beebom.com/escape-tsunami-for-brainrots-walkthrough-beginners-guide/)).

**Safe Zone / lobby props**
- The Wave Machine stands next to the Wheel on the left side of the Safe Zone ([TechWiser Wave Tokens](https://techwiser.com/escape-tsunami-for-brainrots-wave-tokens/)). Wheels include Cash Spin (costs coins), Radioactive, UFO and Arcade Spin, rotating with events. The event spin is "near the Sell Shop on the left side of the map" ([GGWTB](https://ggwtb.com/blog/escape-tsunami-for-brainrots-unlocking-hidden-mechanics-glitches--events--and-secret-obbys); [Earnaldo](https://earnaldo.com/blog/escape-tsunami-for-brainrots-free-robux-guide)). This is lower-reliability; the extract did not say which of the two holds the quote.
- **Trading Plaza:** "head left from your base and press 'E' at the gate to teleport", with player booths inside ([TechWiser trade tokens](https://techwiser.com/escape-tsunami-for-brainrots-trade-tokens/); [GameRant](https://gamerant.com/roblox-escape-tsunami-for-brainrots-how-get-trade-tokens-fast/)). Straight ahead in the plaza, a **portal** leads to the **Tsunami Arena** (2–8 players fight over one brainrot with bats). Arena variants include fishing, mine and jungle ([NamuWiki Biome](https://en.namu.wiki/w/Escape%20Tsunami%20For%20Brainrots!/%EB%B0%94%EC%9D%B4%EC%98%B4); [Fandom Tsunami Arena](https://escape-tsunami-for-brainrots.fandom.com/wiki/Tsunami_Arena)).
- Event structures: a Carnival Shop near the upgrades shop; a Valentine wheel in the Safe Zone (20 Candies or 49 Robux per spin); and a Candygram Station "opposite the Upgrade Shop, but in the Tsunami zone" ([Sportskeeda Carnival](https://www.sportskeeda.com/roblox-news/escape-tsunami-brainrots-carnival-event-guide); [Pro Game Guides Valentine](https://progameguides.com/roblox/escape-tsunami-for-brainrots-valentines-candy-event-guide/); [Sportskeeda Valentine](https://www.sportskeeda.com/roblox-news/escape-tsunami-for-brainrots-valentine-s-update-guide)).
- Arcade event: yellow Trade Tickets are scattered on the floor and exchanged at a slot machine in a "Secret Room" (3 tickets = 1 token) ([TechWiser Mystery Merchant](https://techwiser.com/escape-tsunami-for-brainrots-mystery-merchant-guide/)).
- Weather "biomes": in Mine weather "stones form on the floor", and in Phantom weather there is "a phantom coin on the floor" ([NamuWiki Biome](https://en.namu.wiki/w/Escape%20Tsunami%20For%20Brainrots!/%EB%B0%94%EC%9D%B4%EC%98%B4)). A geyser hazard erupts from the ground after a 7-second warning and slows players ([Fandom (alt) Tsunamis](https://escapetsunamiforbrainnrot.fandom.com/wiki/Tsunamis)).

**Tsunami waves**
- Natural types and speeds: Super Slow 85, Slow 120, Medium 140, Fast 180, Lightning 220. Wacky and Snakey (event) are 70. Beast is "?" and can be triggered for 19 Robux or 8 Wave Tokens ([Fandom Waves](https://escape-tsunami-for-brainrots.fandom.com/wiki/Waves); [Roblox Fandom](https://roblox.fandom.com/wiki/Wave_of_Brainrots/Escape_Tsunami_For_Brainrots)).
- **Colors by type:** Super Slow light blue, Slow blue, Medium light green, Fast red, Lightning purple ([TechWiser tsunami survival](https://techwiser.com/escape-tsunami-for-brainrots-tsunami-survival-guide/)).
- Lightning is "colossal in size", moves at "a blinding speed", and is "accompanied by a purple glow and a terrifying sound". Higher tiers are "taller and wider than the previous one, covering more area of the map" ([Fandom (alt) Tsunamis](https://escapetsunamiforbrainnrot.fandom.com/wiki/Tsunamis)).
- Emoji labels: Super Slow 😁 and Lightning 😈 ([Fandom (alt) Tsunamis](https://escapetsunamiforbrainnrot.fandom.com/wiki/Tsunamis)). Others not found.
- Wave Machine event waves: Chaos, Ragdoll, Pause, Clear. "Wave Wednesday" admin events bring double-speed or non-stop waves every 30 s ([GGWTB Wave Wednesday](https://ggwtb.com/blog/escape-tsunami-for-brainrots-guide-wave-wednesday-update-map-expansion); [Beebom Wave Wednesday time](https://beebom.com/next-escape-tsunami-for-brainrots-wave-wednesday-time/)).

**Timeline of map and visual changes (2026)**
- **Jan 2026:** the "Wave Wednesday" update added the Wave Machine, an expanded map, new safe zones and new waves ([FFBooyah](https://ffbooyah.com/2026/01/31/escape-tsunami-for-brainrots-new-update-explained-wave-machine-map-expansion-new-waves/)).
- **Feb 2026:** Valentine's candy event, with a wheel and the Candygram Station ([Pro Game Guides](https://progameguides.com/roblox/escape-tsunami-for-brainrots-valentines-candy-event-guide/)).
- **Apr 4, 2026:** the Easter update gave the map, Tsunami Arena and portal "a festive look", and added Bunny Waves and the Spring Hatch and Golden Nest Lucky Blocks ([Sportskeeda Easter patch notes](https://www.sportskeeda.com/roblox-news/escape-tsunami-for-brainrots-easter-update-patch-notes)).
- **Jun 20, 2026:** summer update with Paradox Summer Hunts and Infinity tiers ([Earnaldo](https://earnaldo.com/blog/escape-tsunami-for-brainrots-free-robux-guide)). Also a Trading update (Trade Tokens, Mystery Merchant) and Carnival and Arcade events (dates not pinned down) ([Deltia's](https://deltiasgaming.com/roblox-escape-tsunami-for-brainrots-trading-update-guide/)).
- **Sep 2026:** admin-abuse wave events are still reported ([Roonby](https://roonby.com/2026/09/02/escape-tsunami-for-brainrots-waves-tsunami-admin-abuse-time/)).

### Inferences
- **Map blueprint:** a long, walled, straight track. The Safe Zone/lobby (bases, cyan upgrade ring, wheel, Wave Machine, Sell Shop, Trading Plaza gate on the left) sits at one end. Rarity zones run outward, separated by sunken trenches. VIP glass-door alcoves line the right wall. Waves spawn at the far (Celestial) end and sweep toward the lobby.
- Each wave can be built as a large translucent wall whose color is tinted per type and whose height and width scale with tier, with a billboard showing the name and emoji. The Lightning wave adds a purple glow (point light or particles) and a distinct sound.
- Zones can reasonably use each zone's rarity color (gray, then light green, blue, purple, yellow, red, magenta, black, pink) for floors or signs. **This is an inference**: no source states the zone floor colors.

### Gaps
- Actual zone floor colors and materials, and the zone signs and arches: **no source** (a NamuWiki search returned only brainrot rarity colors).
- Wave foam, particles and transparency, the exact hue values, and whether the wave is a mesh or Terrain water: no source.
- Skybox, time of day, lighting and fog: no source.
- The art style of the brainrot models (Italian-brainrot meme characters such as Tung Tung Sahur): not verified for this game's models.

## 6. Mobile-specific UI (jump button, scaling)

### Takeaway
**No reliable game-specific source** describes the mobile layout. Found sources either describe browser clones or contradict each other. The Roblox game most likely uses Roblox's default touch controls.

### Cited Findings
- Control descriptions conflict between a joystick plus run and jump buttons, a "Virtual joystick + jump button", and a claimed "Right joystick — Move … Right button — Jump" ([Deltia's controls guide](https://deltiasgaming.com/roblox-escape-tsunami-for-brainrots-controls-guide/); [AnimalBrainrot](https://animalbrainrot.com/game/escape-tsunami-for-brainrots); [CrazyGames clone](https://www.crazygames.com/game/escape-tsunami-for-brainrots-wfe)). Several of these pages are for browser clones, not the Roblox game.
- Trading Plaza entry uses the "E" interaction prompt ([TechWiser trade tokens](https://techwiser.com/escape-tsunami-for-brainrots-trade-tokens/)). On touch devices this becomes a tappable ProximityPrompt (an inference about Roblox standard behavior).

### Inferences
- On Roblox mobile the default is a thumbstick at bottom-left and a round jump button at bottom-right. Unless the game overrides them, the left HUD button column and the right Wave Machine button must leave the bottom corners clear.

### Gaps
- Mobile scaling of the button column, whether there is a custom sprint or jump button, and any portrait support: no source.

## 7. Fonts, text style and sound

### Takeaway
**No reachable source names the fonts or describes the text outline style.** On sound, sources confirm only a **siren** before each wave and a "terrifying sound" for the Lightning wave.

### Cited Findings
- A siren sounds when the countdown hits zero and is "the only warning before the wave" ([LDPlayer](https://www.ldplayer.net/blog/escape-tsunami-for-brainrots-roblox.html); [MuMuPlayer](https://www.mumuplayer.com/blog/roblox-escape-tsunami-brainrot-walkthrough-guide.html)).
- The Lightning wave has "a purple glow and a terrifying sound" ([Fandom (alt) Tsunamis](https://escapetsunamiforbrainnrot.fandom.com/wiki/Tsunamis)).
- Exact UI strings found: "Rebirth" (purple button), "Skip Rebirth Keep Speed!", "Upgrade" (green), "Accept" (green), and wave names "Super Slow / Slow / Medium / Fast / Lightning / Beast" ([Sportskeeda rebirth](https://www.sportskeeda.com/roblox-news/escape-tsunami-for-brainrots-rebirth-guide); [AllThings.how shops](https://allthings.how/escape-tsunami-for-brainrots-shops-explained/); [Sportskeeda trade](https://www.sportskeeda.com/roblox-news/how-trade-escape-tsunami-for-brainrots); [Fandom Waves](https://escape-tsunami-for-brainrots.fandom.com/wiki/Waves)).
- An App Store listing touts "viral sound effects" ([App Store](https://apps.apple.com/us/app/escape-tsunami-for-brainrots/id6754049060)). **This is likely a separate mobile app, not the Roblox game. Do not rely on it.**

### Inferences
- The genre convention for 2025 brainrot simulators is a heavy rounded cartoon font (e.g. Fredoka One or Luckiest Guy style) in white or colored text with a thick black outline (UIStroke). **This is a genre assumption, not verified for this game.**

### Gaps
- Font family, text stroke thickness and color, and number font: no source.
- Background music and its style: no source.
- Sound effects for collecting, upgrading and buying: no source.
- To close these gaps, view a recent (2026) gameplay video or screenshot. That was not possible in this session.
