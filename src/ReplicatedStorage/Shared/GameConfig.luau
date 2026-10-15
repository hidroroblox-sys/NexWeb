--!strict
--[[
	GameConfig
	==========
	TODOS os números do jogo ficam aqui. Para balancear, mude só este arquivo.

	Os valores seguem o "Escape Tsunami For Brainrots" (pesquisa em reports/):
	ondas 85/120/140/180/220, Speed ×1,17 por nível com pacotes +1/+5/+10,
	carry 1→7, base com 10 slots e um andar novo a cada 10, rebirth por Speed
	(40, 50, 60...) com 1,5x a 11x, mutações, ninhos surpresa e Celestial a cada 15 min.

	  • Tempos em SEGUNDOS (60 = 1 minuto, 3600 = 1 hora)
	  • Distâncias em STUDS
	  • Cores em Color3.fromRGB(vermelho, verde, azul)

	Trocar o placeholder pelo seu modelo 3D:
	  coloque o modelo em ReplicatedStorage > Assets > Eggs (ou Animals)
	  com o MESMO nome do campo "Model" abaixo.
]]

local GameConfig = {}

-- =====================================================================
-- TIPOS (ajudam o editor a achar erros — pode ignorar)
-- =====================================================================

export type Rarity = {
	Id: string,
	Name: string,
	Order: number, -- 1 = mais comum
	Color: Color3, -- cor do texto da raridade
	HatchTime: number, -- segundos para o ovo chocar
}

export type Area = {
	Id: string,
	Name: string,
	Rarity: string?, -- raridade dos ovos que nascem aqui (nil = não nasce nada)
	Length: number, -- comprimento da área no corredor
	MaxEggs: number, -- máximo de ovos ao mesmo tempo
	SpawnInterval: number, -- a cada quantos segundos nasce um ovo (se houver espaço)
	NestCount: number, -- quantos ninhos existem na área
	FloorColor: Color3,
	FloorMaterial: Enum.Material,
	WallColor: Color3,
	RecommendedSpeed: string, -- texto da placa
	TimedSpawn: boolean?, -- só nasce 1 ovo por vez, no timer (Celestial)
	TrenchSpacing: number, -- distância entre trincheiras nesta área (cresce no fundo)
}

export type Egg = {
	Id: string,
	Name: string,
	Rarity: string,
	Color: Color3, -- cor do placeholder
	SpotColor: Color3, -- cor das pintinhas do placeholder
	Rainbow: boolean?,
	Model: string, -- nome do modelo em ReplicatedStorage.Assets.Eggs
}

export type Animal = {
	Id: string,
	Name: string,
	Rarity: string,
	Income: number, -- dinheiro por segundo (nível 1, sem mutação)
	Color: Color3,
	Icon: string, -- emoji da interface
	Model: string, -- nome do modelo em ReplicatedStorage.Assets.Animals
}

export type Mutation = {
	Id: string,
	Name: string,
	Multiplier: number,
	Chance: number, -- % de chance por ovo que nasce
	Color: Color3,
	Material: Enum.Material?,
}

export type WaveType = {
	Id: string,
	Name: string,
	Emoji: string, -- aparece flutuando em cima da onda
	Speed: number, -- studs por segundo (mesma escala da Velocidade do jogador)
	Weight: number, -- chance relativa de sortear
	Color: Color3, -- cor da água e do aviso
	Height: number, -- altura da parede de água
	Glow: boolean?,
}

export type GamePass = {
	Key: string,
	Id: number, -- coloque o ID do gamepass do seu jogo (0 = desativado)
	Name: string,
	Description: string,
	Price: number, -- só para mostrar na loja (Robux)
	Icon: string,
}

-- =====================================================================
-- JOGADORES
-- =====================================================================

GameConfig.Players = {
	MaxPlayers = 8, -- também configure "Max Players" = 8 nas configurações do jogo
	RespawnTime = 3,
}

-- =====================================================================
-- RARIDADES (cores do original) — tempos de chocar pedidos por você
-- =====================================================================

GameConfig.Rarities = {
	{ Id = "Comum", Name = "Comum", Order = 1, Color = Color3.fromRGB(205, 205, 205), HatchTime = 60 },
	{ Id = "Incomum", Name = "Incomum", Order = 2, Color = Color3.fromRGB(120, 235, 100), HatchTime = 5 * 60 },
	{ Id = "Raro", Name = "Raro", Order = 3, Color = Color3.fromRGB(60, 145, 255), HatchTime = 15 * 60 },
	{ Id = "Epico", Name = "Épico", Order = 4, Color = Color3.fromRGB(175, 85, 255), HatchTime = 30 * 60 },
	{ Id = "Lendario", Name = "Lendário", Order = 5, Color = Color3.fromRGB(255, 215, 40), HatchTime = 3600 },
	{ Id = "Mitico", Name = "Mítico", Order = 6, Color = Color3.fromRGB(255, 60, 60), HatchTime = 150 * 60 },
	{ Id = "Cosmico", Name = "Cósmico", Order = 7, Color = Color3.fromRGB(255, 70, 225), HatchTime = 6 * 3600 },
	{ Id = "Secreto", Name = "Secreto", Order = 8, Color = Color3.fromRGB(25, 25, 25), HatchTime = 12 * 3600 },
	{ Id = "Celestial", Name = "Celestial", Order = 9, Color = Color3.fromRGB(255, 140, 205), HatchTime = 12 * 3600 },
	{ Id = "Divino", Name = "Divino", Order = 10, Color = Color3.fromRGB(255, 245, 150), HatchTime = 12 * 3600 },
} :: { Rarity }

-- =====================================================================
-- ÁREAS DO CORREDOR (da base para o fim). Trincheiras no começo de cada área e a cada TrenchSpacing.
-- Como no original: Início (sem ovos), Comum ... Cósmico (2), Secreto (3),
-- Celestial (1 ovo por vez a cada 15 min). No fim: a Torre do Tsunami.
-- =====================================================================

local function area(
	id: string,
	name: string,
	rarity: string?,
	length: number,
	maxEggs: number,
	interval: number,
	nests: number,
	floor: Color3,
	material: Enum.Material,
	wall: Color3,
	speed: string,
	trenchSpacing: number
): Area
	return {
		TrenchSpacing = trenchSpacing,
		Id = id,
		Name = name,
		Rarity = rarity,
		Length = length,
		MaxEggs = maxEggs,
		SpawnInterval = interval,
		NestCount = nests,
		FloorColor = floor,
		FloorMaterial = material,
		WallColor = wall,
		RecommendedSpeed = speed,
	}
end

local rgb = Color3.fromRGB
local M = Enum.Material

-- Visual igual ao do vídeo: chão AZUL com studs em todo o corredor, trincheiras de areia,
-- paredes laranja altas. A cor de cada área aparece na placa pintada na parede.
-- O Início (logo depois da base) é de areia, como a praia do vídeo.
local BLUE = rgb(0, 162, 250)
local SAND = rgb(248, 228, 140)
local WALL = rgb(220, 115, 85)
local P = M.Plastic

GameConfig.Areas = {
	area("Inicio", "Início", nil, 120, 0, 0, 0, SAND, P, WALL, "", 120),
	area("Comum", "Área Comum", "Comum", 300, 16, 3, 30, BLUE, P, WALL, "0 - 20", 100),
	area("Incomum", "Área Incomum", "Incomum", 360, 14, 4, 28, BLUE, P, WALL, "20 - 40", 115),
	area("Raro", "Área Rara", "Raro", 440, 12, 5, 26, BLUE, P, WALL, "40 - 65", 130),
	area("Epico", "Área Épica", "Epico", 520, 10, 7, 22, BLUE, P, WALL, "65 - 85", 145),
	area("Lendario", "Área Lendária", "Lendario", 600, 10, 9, 22, BLUE, P, WALL, "85 - 110", 160),
	area("Mitico", "Área Mítica", "Mitico", 640, 8, 11, 20, BLUE, P, WALL, "110 - 130", 175),
	area("Cosmico1", "Área Cósmica", "Cosmico", 560, 6, 14, 16, BLUE, P, WALL, "130 - 150", 190),
	area("Cosmico2", "Área Cósmica II", "Cosmico", 560, 6, 14, 16, BLUE, P, WALL, "130 - 150", 200),
	area("Secreto1", "Área Secreta", "Secreto", 600, 4, 20, 14, BLUE, P, WALL, "150+", 215),
	area("Secreto2", "Área Secreta II", "Secreto", 600, 4, 20, 14, BLUE, P, WALL, "150+", 230),
	area("Secreto3", "Área Secreta III", "Secreto", 600, 4, 20, 14, BLUE, P, WALL, "160+", 245),
	area("Celestial", "Área Celestial", "Celestial", 720, 0, 0, 0, BLUE, P, WALL, "180+", 260),
} :: { Area }
GameConfig.Areas[#GameConfig.Areas].TimedSpawn = true

-- =====================================================================
-- OVOS (um por raridade)
-- =====================================================================

GameConfig.Eggs = {
	{ Id = "OvoCaipira", Name = "Ovo Caipira", Rarity = "Comum", Color = rgb(250, 238, 215), SpotColor = rgb(205, 170, 120), Model = "OvoCaipira" },
	{ Id = "OvoFazenda", Name = "Ovo da Fazenda", Rarity = "Incomum", Color = rgb(150, 215, 120), SpotColor = rgb(80, 150, 60), Model = "OvoFazenda" },
	{ Id = "OvoDeserto", Name = "Ovo do Deserto", Rarity = "Raro", Color = rgb(235, 185, 95), SpotColor = rgb(60, 120, 230), Model = "OvoDeserto" },
	{ Id = "OvoPedra", Name = "Ovo de Pedra", Rarity = "Epico", Color = rgb(150, 150, 165), SpotColor = rgb(185, 95, 255), Model = "OvoPedra" },
	{ Id = "OvoGelo", Name = "Ovo de Gelo", Rarity = "Lendario", Color = rgb(175, 230, 255), SpotColor = rgb(255, 220, 60), Model = "OvoGelo" },
	{ Id = "OvoOceano", Name = "Ovo do Oceano", Rarity = "Mitico", Color = rgb(40, 140, 220), SpotColor = rgb(255, 80, 80), Model = "OvoOceano" },
	{ Id = "OvoCosmico", Name = "Ovo Cósmico", Rarity = "Cosmico", Color = rgb(110, 55, 210), SpotColor = rgb(255, 120, 230), Model = "OvoCosmico" },
	{ Id = "OvoLava", Name = "Ovo de Lava", Rarity = "Secreto", Color = rgb(40, 30, 30), SpotColor = rgb(255, 110, 20), Model = "OvoLava" },
	{ Id = "OvoNuvens", Name = "Ovo das Nuvens", Rarity = "Celestial", Color = rgb(255, 225, 240), SpotColor = rgb(255, 140, 205), Model = "OvoNuvens" },
	{ Id = "OvoDivino", Name = "Ovo Divino", Rarity = "Divino", Color = rgb(255, 250, 200), SpotColor = rgb(255, 120, 200), Rainbow = true, Model = "OvoDivino" },
} :: { Egg }

-- =====================================================================
-- ANIMAIS — escadas de renda iguais às do original (mais fraco -> mais forte)
-- A chance de cada animal dentro do ovo vem de AnimalWeights (o 1º é o mais comum).
-- =====================================================================

local function animal(id: string, name: string, rarity: string, income: number, icon: string, color: Color3): Animal
	return { Id = id, Name = name, Rarity = rarity, Income = income, Icon = icon, Color = color, Model = id }
end

GameConfig.Animals = {
	-- Comum: 2, 4, 6, 7, 9, 11, 13, 15
	animal("Pintinho", "Pintinho", "Comum", 2, "🐥", rgb(255, 225, 70)),
	animal("Galinha", "Galinha", "Comum", 4, "🐔", rgb(250, 250, 245)),
	animal("Pato", "Pato", "Comum", 6, "🦆", rgb(255, 240, 160)),
	animal("Peru", "Peru", "Comum", 7, "🦃", rgb(150, 90, 60)),
	animal("Codorna", "Codorna", "Comum", 9, "🐦", rgb(170, 130, 90)),
	animal("Galo", "Galo", "Comum", 11, "🐓", rgb(230, 70, 40)),
	animal("Hamster", "Hamster", "Comum", 13, "🐹", rgb(240, 190, 130)),
	animal("Ratinho", "Ratinho", "Comum", 15, "🐭", rgb(200, 200, 210)),
	-- Incomum: 20, 30, 35, 40, 50, 60, 70, 90, 120
	animal("Coelho", "Coelho", "Incomum", 20, "🐰", rgb(235, 225, 215)),
	animal("Porco", "Porco", "Incomum", 30, "🐷", rgb(255, 170, 185)),
	animal("Ovelha", "Ovelha", "Incomum", 35, "🐑", rgb(245, 245, 245)),
	animal("Cachorro", "Cachorro", "Incomum", 40, "🐶", rgb(200, 150, 90)),
	animal("Gato", "Gato", "Incomum", 50, "🐱", rgb(255, 180, 90)),
	animal("Vaca", "Vaca", "Incomum", 60, "🐮", rgb(250, 250, 250)),
	animal("Cavalo", "Cavalo", "Incomum", 70, "🐴", rgb(140, 90, 55)),
	animal("Lhama", "Lhama", "Incomum", 90, "🦙", rgb(240, 225, 200)),
	animal("Touro", "Touro", "Incomum", 120, "🐂", rgb(110, 70, 45)),
	-- Raro: 100 ... 275
	animal("Formiga", "Formiga Gigante", "Raro", 100, "🐜", rgb(120, 40, 30)),
	animal("Suricato", "Suricato", "Raro", 120, "🦦", rgb(205, 160, 105)),
	animal("Escorpiao", "Escorpião", "Raro", 135, "🦂", rgb(150, 70, 40)),
	animal("Lagartixa", "Lagartixa", "Raro", 150, "🦎", rgb(120, 200, 80)),
	animal("Cobra", "Cobra", "Raro", 175, "🐍", rgb(80, 160, 60)),
	animal("Camelo", "Camelo", "Raro", 200, "🐫", rgb(215, 170, 100)),
	animal("Dromedario", "Dromedário", "Raro", 240, "🐪", rgb(200, 150, 90)),
	animal("Leao", "Leão", "Raro", 275, "🦁", rgb(230, 170, 60)),
	-- Épico: 290 ... 1.400
	animal("Cabra", "Cabra-Montesa", "Epico", 290, "🐐", rgb(200, 195, 185)),
	animal("Coruja", "Coruja", "Epico", 475, "🦉", rgb(150, 110, 70)),
	animal("Aguia", "Águia", "Epico", 625, "🦅", rgb(110, 75, 45)),
	animal("Lobo", "Lobo", "Epico", 775, "🐺", rgb(120, 125, 140)),
	animal("Urso", "Urso", "Epico", 925, "🐻", rgb(120, 80, 50)),
	animal("Gorila", "Gorila", "Epico", 1100, "🦍", rgb(60, 60, 65)),
	animal("Rinoceronte", "Rinoceronte", "Epico", 1270, "🦏", rgb(150, 150, 155)),
	animal("Elefante", "Elefante", "Epico", 1400, "🐘", rgb(160, 160, 175)),
	-- Lendário: 1.500 ... 5.000
	animal("Pinguim", "Pinguim", "Lendario", 1500, "🐧", rgb(40, 45, 60)),
	animal("RaposaArtica", "Raposa-do-Ártico", "Lendario", 1900, "🦊", rgb(240, 248, 255)),
	animal("CorujaNeves", "Coruja-das-Neves", "Lendario", 2290, "🦉", rgb(250, 250, 255)),
	animal("LebreArtica", "Lebre-Ártica", "Lendario", 2600, "🐇", rgb(235, 240, 250)),
	animal("LoboArtico", "Lobo-Ártico", "Lendario", 3200, "🐺", rgb(220, 230, 240)),
	animal("Rena", "Rena", "Lendario", 3500, "🦌", rgb(150, 100, 60)),
	animal("UrsoPolar", "Urso-Polar", "Lendario", 4000, "🐻", rgb(250, 250, 250)),
	animal("Yeti", "Yeti", "Lendario", 5000, "⛄", rgb(200, 230, 255)),
	-- Mítico: 6.000 ... 25.500
	animal("Peixe", "Peixe", "Mitico", 6000, "🐟", rgb(255, 150, 40)),
	animal("PeixePalhaco", "Peixe-Palhaço", "Mitico", 8000, "🐠", rgb(255, 120, 30)),
	animal("Baiacu", "Baiacu", "Mitico", 10000, "🐡", rgb(230, 200, 120)),
	animal("Caranguejo", "Caranguejo", "Mitico", 11000, "🦀", rgb(230, 60, 40)),
	animal("Lula", "Lula", "Mitico", 13000, "🦑", rgb(255, 130, 150)),
	animal("Tubarao", "Tubarão", "Mitico", 15000, "🦈", rgb(110, 130, 160)),
	animal("Golfinho", "Golfinho", "Mitico", 19000, "🐬", rgb(110, 170, 220)),
	animal("Orca", "Orca", "Mitico", 25500, "🐋", rgb(25, 25, 35)),
	-- Cósmico: 22.000 ... 240.000
	animal("Alien", "Alien Verde", "Cosmico", 22000, "👽", rgb(120, 230, 120)),
	animal("Robo", "Robô Espacial", "Cosmico", 48000, "🤖", rgb(180, 190, 210)),
	animal("PolvoGalactico", "Polvo Galáctico", "Cosmico", 60000, "🐙", rgb(160, 70, 255)),
	animal("GatoAstronauta", "Gato Astronauta", "Cosmico", 90000, "🚀", rgb(230, 230, 240)),
	animal("CoelhoLunar", "Coelho Lunar", "Cosmico", 110000, "🌙", rgb(255, 245, 190)),
	animal("EstrelaViva", "Estrela Viva", "Cosmico", 130000, "⭐", rgb(255, 220, 60)),
	animal("BaleiaEstelar", "Baleia Estelar", "Cosmico", 170000, "🐳", rgb(40, 60, 160)),
	animal("Cometa", "Cometa", "Cosmico", 240000, "🌠", rgb(120, 200, 255)),
	-- Secreto: 200.000 ... 7,5M
	animal("MorcegoVulcanico", "Morcego Vulcânico", "Secreto", 200000, "🦇", rgb(60, 30, 30)),
	animal("SalamandraLava", "Salamandra de Lava", "Secreto", 350000, "🦎", rgb(255, 90, 20)),
	animal("EscorpiaoFogo", "Escorpião de Fogo", "Secreto", 500000, "🦂", rgb(255, 60, 20)),
	animal("CobraMagma", "Cobra de Magma", "Secreto", 700000, "🐍", rgb(200, 40, 10)),
	animal("GolemLava", "Golem de Lava", "Secreto", 1000000, "🗿", rgb(90, 50, 40)),
	animal("Fenix", "Fênix", "Secreto", 2500000, "🔥", rgb(255, 120, 20)),
	animal("DragaoLava", "Dragão de Lava", "Secreto", 6000000, "🐉", rgb(150, 25, 15)),
	animal("ReiVulcao", "Rei do Vulcão", "Secreto", 7500000, "👑", rgb(255, 200, 40)),
	-- Celestial: 7,5M ... 18M
	animal("Pegaso", "Pégaso", "Celestial", 7500000, "🐴", rgb(255, 255, 255)),
	animal("CisneDourado", "Cisne Dourado", "Celestial", 8500000, "🦢", rgb(255, 210, 80)),
	animal("LeaoAlado", "Leão Alado", "Celestial", 9500000, "🦁", rgb(240, 180, 60)),
	animal("Grifo", "Grifo", "Celestial", 12250000, "🦅", rgb(230, 200, 140)),
	animal("PavaoDourado", "Pavão Dourado", "Celestial", 14000000, "🦚", rgb(255, 200, 60)),
	animal("DragaoCelestial", "Dragão Celestial", "Celestial", 18000000, "🐲", rgb(255, 180, 230)),
	-- Divino: 30M ... 330M
	animal("Unicornio", "Unicórnio Arco-íris", "Divino", 30000000, "🦄", rgb(255, 200, 245)),
	animal("FenixArcoIris", "Fênix Arco-íris", "Divino", 45000000, "🌈", rgb(255, 120, 200)),
	animal("BaleiaArcoIris", "Baleia Arco-íris", "Divino", 88800000, "🐳", rgb(120, 220, 255)),
	animal("DragaoDivino", "Dragão Divino", "Divino", 115000000, "🐉", rgb(120, 255, 220)),
	animal("PavaoDivino", "Pavão Divino", "Divino", 140000000, "🦚", rgb(60, 200, 255)),
	animal("GalinhaOvosOuro", "Galinha dos Ovos de Ouro", "Divino", 330000000, "🐔", rgb(255, 215, 0)),
} :: { Animal }

-- Peso de cada animal dentro do ovo, do mais fraco para o mais forte
GameConfig.AnimalWeights = { 30, 22, 16, 12, 8, 6, 3, 2, 1 }

-- =====================================================================
-- MUTAÇÕES (sorteadas quando o ovo nasce; o animal herda)
-- =====================================================================

GameConfig.Mutations = {
	{ Id = "Esmeralda", Name = "Esmeralda", Multiplier = 1.5, Chance = 4, Color = rgb(40, 220, 110), Material = M.Glass },
	{ Id = "Dourado", Name = "Dourado", Multiplier = 1.5, Chance = 4, Color = rgb(255, 200, 40), Material = M.Foil },
	{ Id = "Rubi", Name = "Rubi", Multiplier = 2, Chance = 2.5, Color = rgb(220, 30, 50), Material = M.Glass },
	{ Id = "Eletrico", Name = "Elétrico", Multiplier = 3, Chance = 1.2, Color = rgb(90, 200, 255), Material = M.Neon },
	{ Id = "Diamante", Name = "Diamante", Multiplier = 4.25, Chance = 0.5, Color = rgb(150, 230, 255), Material = M.Glass },
} :: { Mutation }

-- =====================================================================
-- NINHO SURPRESA (o "Lucky Block" da versão com ovos)
-- =====================================================================

GameConfig.LuckyNest = {
	Chance = 4, -- % de um ovo que nasce virar Ninho Surpresa
	MutationLuck = 3, -- multiplica as chances de mutação
	UpgradeChance = 10, -- % de vir um ovo da raridade seguinte
	Color = rgb(255, 205, 60),
}

-- =====================================================================
-- OVO CELESTIAL (1 por vez, no fim do corredor)
-- =====================================================================

GameConfig.Celestial = {
	Interval = 15 * 60, -- de quanto em quanto tempo aparece
	FirstDelay = 5 * 60, -- primeiro depois que o servidor abre
	DivineChance = 5, -- % de vir um Ovo Divino no lugar
}

-- =====================================================================
-- MAPA
-- =====================================================================

GameConfig.Map = {
	Seed = 2024,
	FloorY = 0,
	FloorThickness = 12, -- precisa ser maior que HoleDepth
	CorridorWidth = 200, -- corredor bem largo, como no vídeo
	WallHeight = 80,
	WallThickness = 6,
	SafeZoneStartZ = 0, -- onde começa a ZONA SEGURA (o corredor vai para +Z)
	SafeZoneLength = 40,

	-- Cores e textura (studs clássicos do Roblox, como no vídeo)
	Studs = true,
	TrenchColor = rgb(248, 228, 140), -- fundo de areia das trincheiras
	BaseGrassColor = rgb(0, 225, 40), -- grama verde-limão da área inicial
	SandColor = rgb(248, 228, 140),
	EndWallColor = rgb(255, 80, 200),

	-- Trincheiras: no começo de cada área e depois a cada TrenchSpacing da área
	HoleLength = 18,
	HoleDepth = 8,
	HoleRampLength = 9,
	BarrelSpacing = 25, -- barris vermelho/branco na beira das trincheiras

	-- Nichos VIP de vidro nas paredes (um de cada lado por área)
	VipAlcoveWidth = 14,
	VipAlcoveDepth = 10,
	VipAlcoveHeight = 12,

	-- Área inicial com as bases (cercados em meio-círculo virados para o corredor)
	BaseAreaHalfWidth = 230,
	BaseAreaDepth = 215,
	BarnArcRadius = 150,
	BarnArcAngle = 160,
	BarnSize = Vector3.new(36, 4, 46), -- cercado: largura, altura da cerca, fundo
	FloorHeight = 14, -- altura de cada andar extra (deck de vidro)
	UpgradeRingPosition = Vector3.new(0, 0, -60), -- anel ciano da loja de upgrades
	UpgradeRingRadius = 8,

	-- Slots dentro do cercado (2 colunas x 5 fileiras por andar)
	SlotColumnX = 12.5,
	PadColumnX = 5.5,
	FirstRowZ = -15,
	RowSpacing = 7.2,
	PenSize = Vector3.new(8.5, 0.4, 6.2),
	PadSize = Vector3.new(3.4, 0.4, 3.4),

	ClearTerrain = true,
}

-- =====================================================================
-- TSUNAMI (velocidades e cores do original)
-- =====================================================================

GameConfig.Waves = {
	FirstWaveDelay = 20,
	MinInterval = 30, -- intervalo aleatório entre ondas (elas podem se sobrepor)
	MaxInterval = 60,
	WarningTime = 5, -- últimos segundos com aviso grande + bipes
	Thickness = 40,
	HideDepth = 3, -- o jogador precisa estar pelo menos isso abaixo do chão
	Types = {
		{ Id = "SuperLenta", Name = "Super Lenta", Emoji = "😁", Speed = 85, Weight = 30, Color = rgb(140, 215, 255), Height = 42 },
		{ Id = "Lenta", Name = "Lenta", Emoji = "🙂", Speed = 120, Weight = 25, Color = rgb(45, 115, 255), Height = 50 },
		{ Id = "Media", Name = "Média", Emoji = "😐", Speed = 140, Weight = 20, Color = rgb(110, 230, 110), Height = 58 },
		{ Id = "Rapida", Name = "Rápida", Emoji = "😠", Speed = 180, Weight = 15, Color = rgb(255, 55, 55), Height = 68 },
		{ Id = "Relampago", Name = "Relâmpago", Emoji = "😈", Speed = 220, Weight = 10, Color = rgb(165, 60, 255), Height = 80, Glow = true },
	} :: { WaveType },
}

-- =====================================================================
-- ECONOMIA
-- =====================================================================

GameConfig.Speed = {
	BaseWalkSpeed = 16, -- Velocidade inicial (mostrada no HUD)
	WalkSpeedPerLevel = 1,
	MaxLevel = 1000,
	BasePrice = 590, -- preço do 1º +1 (chegar a 50 custa ~ $722K, como no original)
	PriceGrowth = 1.17, -- cada nível custa 17% a mais
	Packs = { -- desconto dos pacotes (o +10 sai pela metade, como no original)
		{ Amount = 1, Discount = 1 },
		{ Amount = 5, Discount = 0.74 },
		{ Amount = 10, Discount = 0.49 },
	},
}

GameConfig.Carry = {
	Start = 1,
	Max = 7,
	Prices = { 500e3, 25e6, 1e9, 750e9, 50e12, 5e15 }, -- 1->2, 2->3, ...
}

GameConfig.Barn = {
	StartSlots = 10,
	MaxSlots = 30,
	SlotsPerFloor = 10, -- um andar novo a cada 10 slots
	-- preço do 11º slot, 12º, ... 30º
	SlotPrices = {
		1e6, 10e6, 25e6, 50e6, 100e6, 200e6, 350e6, 600e6, 1e9, 2.5e9,
		5e9, 10e9, 20e9, 35e9, 60e9, 100e9, 200e9, 350e9, 500e9, 750e9,
	},
	FullMessageCooldown = 4,
}

GameConfig.Level = {
	IncomeMultiplier = 1.25, -- cada nível multiplica a renda por 1,25
	CostGrowth = 1.3, -- cada nível custa 30% a mais
	BaseCostCap = 25000, -- custo do nível 2 = renda base (no máximo 25.000)
	MaxLevel = 200,
}

GameConfig.Sell = {
	IncomeSeconds = 60, -- vender dá 60 segundos da renda base do animal (com mutação)
	ConfirmFromRarityOrder = 5,
}

GameConfig.Rebirth = {
	MaxRebirths = 29,
	SpeedBase = 30, -- Velocidade exigida = 30 + 10 x nível (40, 50, 60...)
	SpeedPerRebirth = 10,
	MultiplierPerRebirth = 0.5, -- 1,5x, 2x, ... 11x no Rebirth 20
	LateFrom = 20, -- depois do 20, cada rebirth dá só +0,25x (13,25x no 29)
	LateMultiplierPerRebirth = 0.25,
}

GameConfig.Pickup = {
	HoldDuration = 0.5,
	PromptDistance = 10,
	MaxDistance = 16,
	Cooldown = 0.25,
	DroppedLifetime = 60, -- ovos derrubados ficam no chão por 60 s (qualquer um pega)
}

GameConfig.Bat = {
	Cooldown = 1,
	Range = 8,
	RagdollTime = 2.5, -- quem leva a tacada cai e derruba os ovos
	Knockback = 45,
}

-- =====================================================================
-- GAMEPASSES (coloque os IDs do SEU jogo; 0 = desativado)
-- =====================================================================

GameConfig.GamePasses = {
	{ Key = "VIP", Id = 0, Name = "VIP", Description = "Abre as portas de vidro dos nichos nas paredes: esconderijos seguros contra o tsunami!", Price = 149, Icon = "👑" },
	{ Key = "SpeedBoost", Id = 0, Name = "Turbo", Description = "+20 de Velocidade para sempre.", Price = 129, Icon = "⚡" },
} :: { GamePass }

GameConfig.TestGamePassesInStudio = true -- no Studio, todo mundo ganha os passes para testar
GameConfig.SpeedBoostAmount = 20

-- =====================================================================
-- DADOS / SEGURANÇA
-- =====================================================================

GameConfig.Data = {
	StoreName = "FujaDoTsunamiOvos_v2",
	AutoSaveInterval = 120,
	MaxRetries = 5,
	RetryBaseDelay = 1,
	OfflineIncomeHours = 8, -- renda offline (como no original); 0 = desligado
}

GameConfig.AntiCheat = {
	Enabled = true,
	CheckInterval = 0.5,
	SpeedTolerance = 1.8,
	ExtraStuds = 14,
	MaxViolations = 4,
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
	Bat = "rbxasset://sounds/swordslash.wav",
}

GameConfig.UI = {
	AbbreviateFrom = 10000, -- abaixo disso mostra "$7,110"; acima "$12.3K"
}

-- =====================================================================
-- TABELAS DE BUSCA (geradas automaticamente — não precisa mexer)
-- =====================================================================

GameConfig.RarityById = {} :: { [string]: Rarity }
GameConfig.EggsById = {} :: { [string]: Egg }
GameConfig.EggByRarity = {} :: { [string]: Egg }
GameConfig.AnimalsById = {} :: { [string]: Animal }
GameConfig.AnimalsByRarity = {} :: { [string]: { Animal } }
GameConfig.MutationsById = {} :: { [string]: Mutation }
GameConfig.WaveTypesById = {} :: { [string]: WaveType }
GameConfig.GamePassesByKey = {} :: { [string]: GamePass }

for _, rarity in GameConfig.Rarities do
	GameConfig.RarityById[rarity.Id] = rarity
	GameConfig.AnimalsByRarity[rarity.Id] = {}
end

for _, egg in GameConfig.Eggs do
	assert(GameConfig.RarityById[egg.Rarity], "Ovo com raridade desconhecida: " .. egg.Id)
	GameConfig.EggsById[egg.Id] = egg
	GameConfig.EggByRarity[egg.Rarity] = egg
end

for _, entry in GameConfig.Animals do
	assert(GameConfig.RarityById[entry.Rarity], "Animal com raridade desconhecida: " .. entry.Id)
	assert(GameConfig.AnimalsById[entry.Id] == nil, "Animal repetido: " .. entry.Id)
	GameConfig.AnimalsById[entry.Id] = entry
	table.insert(GameConfig.AnimalsByRarity[entry.Rarity], entry)
end

for _, list in GameConfig.AnimalsByRarity do
	table.sort(list, function(a, b)
		return a.Income < b.Income
	end)
end

for _, rarity in GameConfig.Rarities do
	assert(GameConfig.EggByRarity[rarity.Id], "Raridade sem ovo: " .. rarity.Id)
	assert(#GameConfig.AnimalsByRarity[rarity.Id] > 0, "Raridade sem animais: " .. rarity.Id)
end

for _, areaConfig in GameConfig.Areas do
	if areaConfig.Rarity then
		assert(GameConfig.RarityById[areaConfig.Rarity], "Área com raridade desconhecida: " .. areaConfig.Id)
	end
end

for _, mutation in GameConfig.Mutations do
	GameConfig.MutationsById[mutation.Id] = mutation
end

for _, waveType in GameConfig.Waves.Types do
	GameConfig.WaveTypesById[waveType.Id] = waveType
end

for _, pass in GameConfig.GamePasses do
	GameConfig.GamePassesByKey[pass.Key] = pass
end

return GameConfig
