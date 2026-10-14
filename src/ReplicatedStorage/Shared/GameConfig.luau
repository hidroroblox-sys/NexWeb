--!strict
--[[
	GameConfig
	==========
	TODOS os números do jogo ficam aqui. Para balancear, mude só este arquivo.

	  • Tempos em SEGUNDOS (60 = 1 minuto, 3600 = 1 hora)
	  • Distâncias em STUDS
	  • Cores em Color3.fromRGB(vermelho, verde, azul)

	Trocar o placeholder pelo seu modelo 3D:
	  coloque o modelo em ReplicatedStorage > Assets > Eggs (ou Animals)
	  com o MESMO nome do campo "Model" abaixo. O código usa o seu modelo
	  automaticamente; se não achar, cria o placeholder.
]]

local GameConfig = {}

-- =====================================================================
-- TIPOS (ajudam o editor a achar erros — pode ignorar)
-- =====================================================================

export type ZoneConfig = {
	Biome: string, -- nome do bioma (só informativo)
	Length: number, -- comprimento da zona
	HoleSpacing: number, -- chão entre um buraco e o próximo (quanto maior, mais difícil)
	MaxEggs: number, -- máximo de ovos ao mesmo tempo nesta zona
	SpawnInterval: number, -- a cada quantos segundos nasce um ovo novo (se houver espaço)
	NestCount: number, -- quantos ninhos existem na zona
	FloorColor: Color3,
	FloorMaterial: Enum.Material,
	WallColor: Color3,
	RecommendedSpeed: string, -- texto mostrado na placa da zona
	Rainbow: boolean?, -- chão com listras de arco-íris
}

export type Rarity = {
	Id: string,
	Name: string,
	Order: number, -- 1 = mais comum ... 10 = mais raro
	Color: Color3, -- cor do texto da raridade
	HatchTime: number, -- segundos para o ovo chocar
	Zone: ZoneConfig,
}

export type AnimalChance = { Animal: string, Chance: number }

export type Egg = {
	Id: string,
	Name: string,
	Rarity: string,
	Color: Color3, -- cor do placeholder
	SpotColor: Color3, -- cor das pintinhas do placeholder
	Rainbow: boolean?, -- pintinhas coloridas
	Model: string, -- nome do modelo em ReplicatedStorage.Assets.Eggs
	SpawnWeight: number, -- peso, caso exista mais de um ovo da mesma raridade
	Animals: { AnimalChance }, -- chances somam 100
}

export type Animal = {
	Id: string,
	Name: string,
	Rarity: string,
	Income: number, -- dinheiro por segundo
	Color: Color3, -- cor do placeholder
	Icon: string, -- emoji usado na interface (troque por imagem depois)
	Model: string, -- nome do modelo em ReplicatedStorage.Assets.Animals
}

export type WaveType = {
	Id: string,
	Name: string,
	Speed: number, -- studs por segundo
	Weight: number, -- chance relativa de sortear este tipo
	Color: Color3, -- cor do aviso na tela
}

-- =====================================================================
-- JOGADORES
-- =====================================================================

GameConfig.Players = {
	MaxPlayers = 8, -- também configure "Max Players" = 8 nas configurações do jogo
	RespawnTime = 3, -- segundos até renascer no celeiro
}

-- =====================================================================
-- RARIDADES + ZONAS DO CORREDOR (na ordem: perto da base -> fim do corredor)
-- Tempos de chocar: 1 min, 5 min, 15 min, 30 min, 1 h, 2h30, 6 h, 12 h
-- (Celestial e Divino usam 12 h também — mude se quiser)
-- =====================================================================

GameConfig.Rarities = {
	{
		Id = "Comum",
		Name = "Comum",
		Order = 1,
		Color = Color3.fromRGB(215, 215, 215),
		HatchTime = 60, -- 1 min
		Zone = {
			Biome = "Grama",
			Length = 160,
			HoleSpacing = 40,
			MaxEggs = 8,
			SpawnInterval = 4,
			NestCount = 14,
			FloorColor = Color3.fromRGB(106, 190, 72),
			FloorMaterial = Enum.Material.Grass,
			WallColor = Color3.fromRGB(150, 110, 70),
			RecommendedSpeed = "0 - 10",
		},
	},
	{
		Id = "Incomum",
		Name = "Incomum",
		Order = 2,
		Color = Color3.fromRGB(90, 225, 90),
		HatchTime = 5 * 60, -- 5 min
		Zone = {
			Biome = "Grama escura",
			Length = 200,
			HoleSpacing = 50,
			MaxEggs = 7,
			SpawnInterval = 6,
			NestCount = 14,
			FloorColor = Color3.fromRGB(52, 120, 45),
			FloorMaterial = Enum.Material.Grass,
			WallColor = Color3.fromRGB(110, 80, 50),
			RecommendedSpeed = "10 - 20",
		},
	},
	{
		Id = "Raro",
		Name = "Raro",
		Order = 3,
		Color = Color3.fromRGB(70, 160, 255),
		HatchTime = 15 * 60, -- 15 min
		Zone = {
			Biome = "Deserto",
			Length = 240,
			HoleSpacing = 60,
			MaxEggs = 6,
			SpawnInterval = 8,
			NestCount = 12,
			FloorColor = Color3.fromRGB(232, 205, 140),
			FloorMaterial = Enum.Material.Sand,
			WallColor = Color3.fromRGB(200, 160, 100),
			RecommendedSpeed = "20 - 30",
		},
	},
	{
		Id = "Epico",
		Name = "Épico",
		Order = 4,
		Color = Color3.fromRGB(185, 95, 255),
		HatchTime = 30 * 60, -- 30 min
		Zone = {
			Biome = "Pedra",
			Length = 280,
			HoleSpacing = 75,
			MaxEggs = 5,
			SpawnInterval = 12,
			NestCount = 12,
			FloorColor = Color3.fromRGB(130, 130, 138),
			FloorMaterial = Enum.Material.Slate,
			WallColor = Color3.fromRGB(90, 90, 98),
			RecommendedSpeed = "30 - 50",
		},
	},
	{
		Id = "Lendario",
		Name = "Lendário",
		Order = 5,
		Color = Color3.fromRGB(255, 195, 35),
		HatchTime = 60 * 60, -- 1 h
		Zone = {
			Biome = "Gelo e neve",
			Length = 320,
			HoleSpacing = 90,
			MaxEggs = 4,
			SpawnInterval = 16,
			NestCount = 10,
			FloorColor = Color3.fromRGB(230, 242, 255),
			FloorMaterial = Enum.Material.Snow,
			WallColor = Color3.fromRGB(160, 205, 235),
			RecommendedSpeed = "50 - 80",
		},
	},
	{
		Id = "Mitico",
		Name = "Mítico",
		Order = 6,
		Color = Color3.fromRGB(255, 75, 100),
		HatchTime = 150 * 60, -- 2h30
		Zone = {
			Biome = "Oceano",
			Length = 360,
			HoleSpacing = 105,
			MaxEggs = 4,
			SpawnInterval = 20,
			NestCount = 10,
			FloorColor = Color3.fromRGB(70, 165, 215),
			FloorMaterial = Enum.Material.SmoothPlastic,
			WallColor = Color3.fromRGB(30, 95, 150),
			RecommendedSpeed = "80 - 110",
		},
	},
	{
		Id = "Cosmico",
		Name = "Cósmico",
		Order = 7,
		Color = Color3.fromRGB(255, 90, 230),
		HatchTime = 6 * 3600, -- 6 h
		Zone = {
			Biome = "Espaço",
			Length = 400,
			HoleSpacing = 120,
			MaxEggs = 3,
			SpawnInterval = 25,
			NestCount = 10,
			FloorColor = Color3.fromRGB(60, 32, 110),
			FloorMaterial = Enum.Material.Slate,
			WallColor = Color3.fromRGB(30, 15, 60),
			RecommendedSpeed = "110 - 140",
		},
	},
	{
		Id = "Secreto",
		Name = "Secreto",
		Order = 8,
		Color = Color3.fromRGB(35, 35, 35),
		HatchTime = 12 * 3600, -- 12 h
		Zone = {
			Biome = "Vulcão",
			Length = 440,
			HoleSpacing = 140,
			MaxEggs = 3,
			SpawnInterval = 30,
			NestCount = 10,
			FloorColor = Color3.fromRGB(200, 70, 30),
			FloorMaterial = Enum.Material.CrackedLava,
			WallColor = Color3.fromRGB(45, 30, 28),
			RecommendedSpeed = "140 - 180",
		},
	},
	{
		Id = "Celestial",
		Name = "Celestial",
		Order = 9,
		Color = Color3.fromRGB(255, 240, 140),
		HatchTime = 12 * 3600, -- 12 h
		Zone = {
			Biome = "Nuvens douradas",
			Length = 480,
			HoleSpacing = 160,
			MaxEggs = 2,
			SpawnInterval = 40,
			NestCount = 8,
			FloorColor = Color3.fromRGB(255, 236, 175),
			FloorMaterial = Enum.Material.SmoothPlastic,
			WallColor = Color3.fromRGB(245, 245, 255),
			RecommendedSpeed = "180 - 200",
		},
	},
	{
		Id = "Divino",
		Name = "Divino",
		Order = 10,
		Color = Color3.fromRGB(120, 255, 240),
		HatchTime = 12 * 3600, -- 12 h
		Zone = {
			Biome = "Arco-íris",
			Length = 520,
			HoleSpacing = 180,
			MaxEggs = 2,
			SpawnInterval = 50,
			NestCount = 8,
			FloorColor = Color3.fromRGB(255, 255, 255),
			FloorMaterial = Enum.Material.SmoothPlastic,
			WallColor = Color3.fromRGB(255, 220, 250),
			RecommendedSpeed = "200+",
			Rainbow = true,
		},
	},
} :: { Rarity }

-- =====================================================================
-- OVOS (um por raridade; dá para adicionar mais com o mesmo Rarity)
-- =====================================================================

GameConfig.Eggs = {
	{
		Id = "OvoCaipira",
		Name = "Ovo Caipira",
		Rarity = "Comum",
		Color = Color3.fromRGB(250, 238, 215),
		SpotColor = Color3.fromRGB(205, 170, 120),
		Model = "OvoCaipira",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "Pintinho", Chance = 60 },
			{ Animal = "Galinha", Chance = 30 },
			{ Animal = "Pato", Chance = 10 },
		},
	},
	{
		Id = "OvoFazenda",
		Name = "Ovo da Fazenda",
		Rarity = "Incomum",
		Color = Color3.fromRGB(150, 215, 120),
		SpotColor = Color3.fromRGB(80, 150, 60),
		Model = "OvoFazenda",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "Coelho", Chance = 60 },
			{ Animal = "Porco", Chance = 30 },
			{ Animal = "Ovelha", Chance = 10 },
		},
	},
	{
		Id = "OvoDeserto",
		Name = "Ovo do Deserto",
		Rarity = "Raro",
		Color = Color3.fromRGB(235, 185, 95),
		SpotColor = Color3.fromRGB(160, 100, 40),
		Model = "OvoDeserto",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "Suricato", Chance = 60 },
			{ Animal = "Escorpiao", Chance = 30 },
			{ Animal = "Camelo", Chance = 10 },
		},
	},
	{
		Id = "OvoPedra",
		Name = "Ovo de Pedra",
		Rarity = "Epico",
		Color = Color3.fromRGB(150, 150, 165),
		SpotColor = Color3.fromRGB(185, 95, 255),
		Model = "OvoPedra",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "Cabra", Chance = 60 },
			{ Animal = "Aguia", Chance = 30 },
			{ Animal = "Lobo", Chance = 10 },
		},
	},
	{
		Id = "OvoGelo",
		Name = "Ovo de Gelo",
		Rarity = "Lendario",
		Color = Color3.fromRGB(175, 230, 255),
		SpotColor = Color3.fromRGB(255, 255, 255),
		Model = "OvoGelo",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "Pinguim", Chance = 60 },
			{ Animal = "RaposaArtica", Chance = 30 },
			{ Animal = "UrsoPolar", Chance = 10 },
		},
	},
	{
		Id = "OvoOceano",
		Name = "Ovo do Oceano",
		Rarity = "Mitico",
		Color = Color3.fromRGB(40, 140, 220),
		SpotColor = Color3.fromRGB(120, 230, 255),
		Model = "OvoOceano",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "Peixe", Chance = 60 },
			{ Animal = "Golfinho", Chance = 30 },
			{ Animal = "Orca", Chance = 10 },
		},
	},
	{
		Id = "OvoCosmico",
		Name = "Ovo Cósmico",
		Rarity = "Cosmico",
		Color = Color3.fromRGB(110, 55, 210),
		SpotColor = Color3.fromRGB(255, 240, 120),
		Model = "OvoCosmico",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "PolvoGalactico", Chance = 60 },
			{ Animal = "GatoAstronauta", Chance = 30 },
			{ Animal = "BaleiaEstelar", Chance = 10 },
		},
	},
	{
		Id = "OvoLava",
		Name = "Ovo de Lava",
		Rarity = "Secreto",
		Color = Color3.fromRGB(40, 30, 30),
		SpotColor = Color3.fromRGB(255, 110, 20),
		Model = "OvoLava",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "SalamandraLava", Chance = 60 },
			{ Animal = "DragaoLava", Chance = 30 },
			{ Animal = "Fenix", Chance = 10 },
		},
	},
	{
		Id = "OvoNuvens",
		Name = "Ovo das Nuvens",
		Rarity = "Celestial",
		Color = Color3.fromRGB(255, 225, 120),
		SpotColor = Color3.fromRGB(255, 255, 255),
		Model = "OvoNuvens",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "Pegaso", Chance = 60 },
			{ Animal = "CisneDourado", Chance = 30 },
			{ Animal = "LeaoAlado", Chance = 10 },
		},
	},
	{
		Id = "OvoDivino",
		Name = "Ovo Divino",
		Rarity = "Divino",
		Color = Color3.fromRGB(255, 255, 255),
		SpotColor = Color3.fromRGB(255, 120, 200),
		Rainbow = true,
		Model = "OvoDivino",
		SpawnWeight = 1,
		Animals = {
			{ Animal = "Unicornio", Chance = 60 },
			{ Animal = "DragaoDivino", Chance = 30 },
			{ Animal = "PavaoDivino", Chance = 10 },
		},
	},
} :: { Egg }

-- =====================================================================
-- ANIMAIS (Income = dinheiro por segundo)
-- =====================================================================

GameConfig.Animals = {
	-- Comum
	{ Id = "Pintinho", Name = "Pintinho", Rarity = "Comum", Income = 1, Color = Color3.fromRGB(255, 225, 70), Icon = "🐥", Model = "Pintinho" },
	{ Id = "Galinha", Name = "Galinha", Rarity = "Comum", Income = 2, Color = Color3.fromRGB(250, 250, 245), Icon = "🐔", Model = "Galinha" },
	{ Id = "Pato", Name = "Pato", Rarity = "Comum", Income = 4, Color = Color3.fromRGB(255, 240, 160), Icon = "🦆", Model = "Pato" },
	-- Incomum
	{ Id = "Coelho", Name = "Coelho", Rarity = "Incomum", Income = 6, Color = Color3.fromRGB(235, 225, 215), Icon = "🐰", Model = "Coelho" },
	{ Id = "Porco", Name = "Porco", Rarity = "Incomum", Income = 9, Color = Color3.fromRGB(255, 170, 185), Icon = "🐷", Model = "Porco" },
	{ Id = "Ovelha", Name = "Ovelha", Rarity = "Incomum", Income = 14, Color = Color3.fromRGB(245, 245, 245), Icon = "🐑", Model = "Ovelha" },
	-- Raro
	{ Id = "Suricato", Name = "Suricato", Rarity = "Raro", Income = 22, Color = Color3.fromRGB(205, 160, 105), Icon = "🦦", Model = "Suricato" },
	{ Id = "Escorpiao", Name = "Escorpião", Rarity = "Raro", Income = 30, Color = Color3.fromRGB(150, 70, 40), Icon = "🦂", Model = "Escorpiao" },
	{ Id = "Camelo", Name = "Camelo", Rarity = "Raro", Income = 45, Color = Color3.fromRGB(215, 170, 100), Icon = "🐫", Model = "Camelo" },
	-- Épico
	{ Id = "Cabra", Name = "Cabra-Montesa", Rarity = "Epico", Income = 90, Color = Color3.fromRGB(200, 195, 185), Icon = "🐐", Model = "Cabra" },
	{ Id = "Aguia", Name = "Águia", Rarity = "Epico", Income = 130, Color = Color3.fromRGB(110, 75, 45), Icon = "🦅", Model = "Aguia" },
	{ Id = "Lobo", Name = "Lobo", Rarity = "Epico", Income = 200, Color = Color3.fromRGB(120, 125, 140), Icon = "🐺", Model = "Lobo" },
	-- Lendário
	{ Id = "Pinguim", Name = "Pinguim", Rarity = "Lendario", Income = 450, Color = Color3.fromRGB(40, 45, 60), Icon = "🐧", Model = "Pinguim" },
	{ Id = "RaposaArtica", Name = "Raposa-do-Ártico", Rarity = "Lendario", Income = 650, Color = Color3.fromRGB(240, 248, 255), Icon = "🦊", Model = "RaposaArtica" },
	{ Id = "UrsoPolar", Name = "Urso-Polar", Rarity = "Lendario", Income = 1000, Color = Color3.fromRGB(250, 250, 250), Icon = "🐻", Model = "UrsoPolar" },
	-- Mítico
	{ Id = "Peixe", Name = "Peixe", Rarity = "Mitico", Income = 2200, Color = Color3.fromRGB(255, 150, 40), Icon = "🐟", Model = "Peixe" },
	{ Id = "Golfinho", Name = "Golfinho", Rarity = "Mitico", Income = 3200, Color = Color3.fromRGB(110, 170, 220), Icon = "🐬", Model = "Golfinho" },
	{ Id = "Orca", Name = "Orca", Rarity = "Mitico", Income = 5000, Color = Color3.fromRGB(25, 25, 35), Icon = "🐋", Model = "Orca" },
	-- Cósmico
	{ Id = "PolvoGalactico", Name = "Polvo Galáctico", Rarity = "Cosmico", Income = 11000, Color = Color3.fromRGB(160, 70, 255), Icon = "🐙", Model = "PolvoGalactico" },
	{ Id = "GatoAstronauta", Name = "Gato Astronauta", Rarity = "Cosmico", Income = 16000, Color = Color3.fromRGB(230, 230, 240), Icon = "🐱", Model = "GatoAstronauta" },
	{ Id = "BaleiaEstelar", Name = "Baleia Estelar", Rarity = "Cosmico", Income = 25000, Color = Color3.fromRGB(40, 60, 160), Icon = "🐳", Model = "BaleiaEstelar" },
	-- Secreto
	{ Id = "SalamandraLava", Name = "Salamandra de Lava", Rarity = "Secreto", Income = 60000, Color = Color3.fromRGB(255, 90, 20), Icon = "🦎", Model = "SalamandraLava" },
	{ Id = "DragaoLava", Name = "Dragão de Lava", Rarity = "Secreto", Income = 90000, Color = Color3.fromRGB(150, 25, 15), Icon = "🐉", Model = "DragaoLava" },
	{ Id = "Fenix", Name = "Fênix", Rarity = "Secreto", Income = 140000, Color = Color3.fromRGB(255, 60, 20), Icon = "🐦", Model = "Fenix" },
	-- Celestial
	{ Id = "Pegaso", Name = "Pégaso", Rarity = "Celestial", Income = 300000, Color = Color3.fromRGB(255, 255, 255), Icon = "🐴", Model = "Pegaso" },
	{ Id = "CisneDourado", Name = "Cisne Dourado", Rarity = "Celestial", Income = 450000, Color = Color3.fromRGB(255, 210, 80), Icon = "🦢", Model = "CisneDourado" },
	{ Id = "LeaoAlado", Name = "Leão Alado", Rarity = "Celestial", Income = 700000, Color = Color3.fromRGB(240, 180, 60), Icon = "🦁", Model = "LeaoAlado" },
	-- Divino
	{ Id = "Unicornio", Name = "Unicórnio Arco-íris", Rarity = "Divino", Income = 1500000, Color = Color3.fromRGB(255, 200, 245), Icon = "🦄", Model = "Unicornio" },
	{ Id = "DragaoDivino", Name = "Dragão Divino", Rarity = "Divino", Income = 2300000, Color = Color3.fromRGB(120, 255, 220), Icon = "🐲", Model = "DragaoDivino" },
	{ Id = "PavaoDivino", Name = "Pavão Divino", Rarity = "Divino", Income = 3500000, Color = Color3.fromRGB(60, 200, 255), Icon = "🦚", Model = "PavaoDivino" },
} :: { Animal }

-- =====================================================================
-- MAPA
-- =====================================================================

GameConfig.Map = {
	Seed = 2024, -- muda a posição dos ninhos
	FloorY = 0, -- altura do chão
	FloorThickness = 14, -- precisa ser maior que HoleDepth
	CorridorWidth = 64,
	WallHeight = 60,
	WallThickness = 4,
	SafeZoneStartZ = 0, -- onde começa a ZONA SEGURA (o corredor vai para +Z)
	SafeZoneLength = 30,

	-- Buracos (fossos para se esconder)
	HoleLength = 24, -- tamanho do buraco no sentido do corredor
	HoleDepth = 10,
	HoleRampLength = 13, -- rampa para sair (fica no lado da base)
	FirstHoleOffset = 20, -- distância do 1º buraco depois da zona segura

	-- Área inicial com os celeiros (em meio-círculo, de frente para o corredor)
	BaseAreaHalfWidth = 215,
	BaseAreaDepth = 205,
	BarnArcRadius = 143,
	BarnArcAngle = 160, -- graus
	BarnSize = Vector3.new(40, 14, 52),

	-- Slots dentro do celeiro (2 colunas)
	SlotColumnX = 13, -- distância do centro do celeiro até a coluna de ninhos
	PadColumnX = 6, -- distância do centro até a coluna de coletores
	FirstRowZ = -17, -- fileira mais perto da porta
	RowSpacing = 7.5,
	PenSize = Vector3.new(9, 0.4, 6.5),
	PadSize = Vector3.new(3.5, 0.4, 3.5),

	ClearTerrain = true, -- apaga o Terrain ao iniciar (ele taparia os buracos)
}

-- =====================================================================
-- TSUNAMI
-- =====================================================================

GameConfig.Waves = {
	FirstWaveDelay = 30, -- segundos até a 1ª onda depois que o servidor abre
	MinInterval = 45, -- intervalo aleatório entre ondas (início a início)
	MaxInterval = 90,
	WarningTime = 10, -- "TSUNAMI EM 10s!"
	Height = 45,
	Thickness = 40, -- espessura da parede de água
	HideDepth = 3, -- o jogador precisa estar pelo menos isso abaixo do chão
	Types = {
		{ Id = "SuperLenta", Name = "Super Lenta", Speed = 30, Weight = 15, Color = Color3.fromRGB(90, 200, 255) },
		{ Id = "Lenta", Name = "Lenta", Speed = 45, Weight = 30, Color = Color3.fromRGB(50, 130, 255) },
		{ Id = "Media", Name = "Média", Speed = 65, Weight = 30, Color = Color3.fromRGB(255, 200, 40) },
		{ Id = "Rapida", Name = "Rápida", Speed = 90, Weight = 18, Color = Color3.fromRGB(255, 120, 30) },
		{ Id = "Relampago", Name = "Relâmpago", Speed = 130, Weight = 7, Color = Color3.fromRGB(255, 40, 40) },
	} :: { WaveType },
}

-- =====================================================================
-- ECONOMIA
-- =====================================================================

GameConfig.Speed = {
	BaseWalkSpeed = 16, -- velocidade no nível 0
	WalkSpeedPerLevel = 1, -- +WalkSpeed por nível comprado
	MaxLevel = 300,
	BasePrice = 15, -- preço do 1º nível
	PriceGrowth = 1.1, -- preço = BasePrice * PriceGrowth ^ nível
}

GameConfig.Carry = {
	Start = 1, -- ovos que dá para carregar no começo
	Max = 7,
	Prices = { 500, 5000, 50000, 500000, 5000000, 50000000 }, -- preço para ir de 1->2, 2->3, ...
}

GameConfig.Barn = {
	StartSlots = 6,
	MaxSlots = 12,
	SlotPrices = { 1000, 10000, 100000, 1000000, 10000000, 100000000 }, -- 7º slot, 8º, ...
	FullMessageCooldown = 4,
}

GameConfig.Sell = {
	IncomeSeconds = 60, -- animal vendido vale "60 segundos" da renda dele
	ConfirmFromRarityOrder = 5, -- pede confirmação a partir de Lendário
}

GameConfig.Rebirth = { -- (Fase 2) já usado no cálculo de renda
	BaseRequiredLevel = 40,
	ExtraLevelPerRebirth = 10,
	FirstMultiplier = 1.5,
	MultiplierPerRebirth = 0.5,
}

GameConfig.Pickup = {
	HoldDuration = 0.5, -- segurar para pegar o ovo
	PromptDistance = 10,
	MaxDistance = 16, -- validação no servidor
	Cooldown = 0.25,
}

-- =====================================================================
-- DADOS / SEGURANÇA
-- =====================================================================

GameConfig.Data = {
	StoreName = "FujaDoTsunamiOvos_v1",
	AutoSaveInterval = 120,
	MaxRetries = 5,
	RetryBaseDelay = 1,
}

GameConfig.AntiCheat = {
	Enabled = true,
	CheckInterval = 0.5,
	SpeedTolerance = 1.8, -- aceita até 80% acima da velocidade permitida (lag)
	ExtraStuds = 14,
	MaxViolations = 4, -- violações seguidas antes de puxar o jogador de volta
}

-- =====================================================================
-- SONS (deixe "" para não tocar; troque por "rbxassetid://123")
-- =====================================================================

GameConfig.Sounds = {
	Click = "rbxasset://sounds/electronicpingshort.wav",
	Siren = "", -- coloque o id de uma sirene aqui
	Warning = "rbxasset://sounds/electronicpingshort.wav",
	WaveHit = "rbxasset://sounds/impact_water.mp3",
	Hatch = "rbxasset://sounds/electronicpingshort.wav",
	Collect = "rbxasset://sounds/electronicpingshort.wav",
	Pickup = "rbxasset://sounds/electronicpingshort.wav",
	Error = "rbxasset://sounds/electronicpingshort.wav",
}

-- =====================================================================
-- INTERFACE
-- =====================================================================

GameConfig.UI = {
	AbbreviateFrom = 10000, -- abaixo disso mostra "$7,110"; acima "$12.3K"
}

-- =====================================================================
-- TABELAS DE BUSCA (geradas automaticamente — não precisa mexer)
-- =====================================================================

GameConfig.RarityById = {} :: { [string]: Rarity }
GameConfig.EggsById = {} :: { [string]: Egg }
GameConfig.EggsByRarity = {} :: { [string]: { Egg } }
GameConfig.AnimalsById = {} :: { [string]: Animal }
GameConfig.AnimalsByRarity = {} :: { [string]: { Animal } }
GameConfig.WaveTypesById = {} :: { [string]: WaveType }

for _, rarity in GameConfig.Rarities do
	GameConfig.RarityById[rarity.Id] = rarity
	GameConfig.EggsByRarity[rarity.Id] = {}
	GameConfig.AnimalsByRarity[rarity.Id] = {}
end

for _, egg in GameConfig.Eggs do
	assert(GameConfig.RarityById[egg.Rarity], "Ovo com raridade desconhecida: " .. egg.Id)
	GameConfig.EggsById[egg.Id] = egg
	table.insert(GameConfig.EggsByRarity[egg.Rarity], egg)
end

for _, animal in GameConfig.Animals do
	assert(GameConfig.RarityById[animal.Rarity], "Animal com raridade desconhecida: " .. animal.Id)
	GameConfig.AnimalsById[animal.Id] = animal
	table.insert(GameConfig.AnimalsByRarity[animal.Rarity], animal)
end

for _, egg in GameConfig.Eggs do
	for _, entry in egg.Animals do
		assert(GameConfig.AnimalsById[entry.Animal], "Ovo " .. egg.Id .. " aponta para animal inexistente: " .. entry.Animal)
	end
end

for _, waveType in GameConfig.Waves.Types do
	GameConfig.WaveTypesById[waveType.Id] = waveType
end

return GameConfig
