--!strict
--[[
	MapBuilder: constrói o mapa inteiro por código (a partir do MapLayout), no visual do vídeo:
	  • tudo de Plastic com STUDS (a textura clássica do Roblox)
	  • área inicial de grama verde-limão com guarda-sóis e coqueiros; bases em cercados
	  • corredor AZUL bem largo, paredes laranja altas com o nome de cada área pintado
	  • trincheiras de areia de parede a parede, com barris vermelho/branco na beira
	  • parede rosa no fim e a Torre do Tsunami atrás dela
	  [ ÁREA INICIAL c/ cercados ] -> [ ZONA SEGURA ] -> [ CORREDOR com trincheiras ] -> [ FIM ]
	Os cercados são construídos pelo BarnService.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Billboards = require(script.Parent.Billboards)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)

local MapBuilder = {}

local Map = GameConfig.Map

local COLORS = {
	White = Color3.fromRGB(255, 255, 255),
	Wall = Color3.fromRGB(220, 115, 85),
	WallTop = Color3.fromRGB(240, 150, 110),
	Leaves = Color3.fromRGB(40, 175, 60),
	Trunk = Color3.fromRGB(150, 105, 60),
	Nest = Color3.fromRGB(125, 85, 45),
	NestInner = Color3.fromRGB(205, 165, 95),
	BarrelRed = Color3.fromRGB(230, 30, 40),
	VipGreen = Color3.fromRGB(150, 255, 40),
	Umbrellas = {
		Color3.fromRGB(255, 70, 80),
		Color3.fromRGB(170, 110, 255),
		Color3.fromRGB(60, 150, 255),
		Color3.fromRGB(255, 200, 40),
	},
}

local STUD_FACES = {
	"TopSurface",
	"FrontSurface",
	"BackSurface",
	"LeftSurface",
	"RightSurface",
}

-- Peça ancorada. Com studs = true (padrão) usa Plastic com a textura de studs
-- em todas as faces, igual aos mapas do vídeo.
local function block(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, studs: boolean?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.Plastic
	local useStuds = Map.Studs and studs ~= false and part.Material == Enum.Material.Plastic
	for _, face in STUD_FACES do
		(part :: any)[face] = if useStuds then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	end
	part.BottomSurface = if useStuds then Enum.SurfaceType.Inlet else Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Peça lisa (detalhes pequenos: barris, folhas, placas)
local function smooth(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	return block(parent, name, size, cframe, color, material or Enum.Material.SmoothPlastic, false)
end

local function invisibleWall(parent: Instance, size: Vector3, cframe: CFrame)
	local wall = smooth(parent, "InvisibleWall", size, cframe, COLORS.White)
	wall.Transparency = 1
	wall.CastShadow = false
	wall.CanQuery = false
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Texto "pintado" numa parede/chão: peça invisível colada na superfície
local function paint(parent: Instance, size: Vector3, cframe: CFrame, face: Enum.NormalId, text: string, color: Color3, pixelsPerStud: number): TextLabel
	local canvas = smooth(parent, "Pintura", size, cframe, COLORS.White)
	canvas.Transparency = 1
	canvas.CanCollide = false
	canvas.CanQuery = false
	canvas.CanTouch = false
	canvas.CastShadow = false
	return Billboards.SurfaceText(canvas, face, text, color, nil, pixelsPerStud)
end

-- Coqueiro: tronco inclinado em gomos + folhas caídas
local function palm(parent: Instance, position: Vector3, scale: number, lean: number)
	local model = Instance.new("Model")
	model.Name = "Coqueiro"
	local top = position
	for i = 1, 5 do
		local tilt = CFrame.Angles(0, lean, math.rad(4 * i))
		local segment = smooth(model, "Tronco", Vector3.new(2.2, 4, 2.2) * scale, CFrame.new(top) * tilt * CFrame.new(0, 2 * scale, 0), COLORS.Trunk:Lerp(Color3.new(0, 0, 0), (i % 2) * 0.12), Enum.Material.Wood)
		top = (segment.CFrame * CFrame.new(0, 2 * scale, 0)).Position
	end
	for i = 1, 7 do
		local angle = i / 7 * math.pi * 2
		smooth(model, "Folha", Vector3.new(2.6, 0.4, 11) * scale, CFrame.new(top) * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.new(0, 0, -5 * scale), COLORS.Leaves)
	end
	for i = 1, 3 do
		local coconut = smooth(model, "Coco", Vector3.new(1.4, 1.4, 1.4) * scale, CFrame.new(top + Vector3.new(math.cos(i * 2.1), -1, math.sin(i * 2.1)) * scale), Color3.fromRGB(90, 60, 30))
		coconut.Shape = Enum.PartType.Ball
	end
	model.Parent = parent
end

-- Guarda-sol de praia: poste + lona em dois discos coloridos
local function umbrella(parent: Instance, position: Vector3, color: Color3)
	local model = Instance.new("Model")
	model.Name = "GuardaSol"
	smooth(model, "Poste", Vector3.new(0.5, 9, 0.5), CFrame.new(position + Vector3.new(0, 4.5, 0)), COLORS.White)
	local canopy = smooth(model, "Lona", Vector3.new(0.6, 11, 11), CFrame.new(position + Vector3.new(0, 8.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), color)
	canopy.Shape = Enum.PartType.Cylinder
	local stripe = smooth(model, "Faixa", Vector3.new(0.7, 6, 6), CFrame.new(position + Vector3.new(0, 8.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), COLORS.White)
	stripe.Shape = Enum.PartType.Cylinder
	local tip = smooth(model, "Ponta", Vector3.new(1, 1, 1), CFrame.new(position + Vector3.new(0, 9.4, 0)), color)
	tip.Shape = Enum.PartType.Ball
	model.Parent = parent
end

-- Barril vermelho e branco deitado na beira da trincheira
local function barrel(parent: Instance, position: Vector3)
	local body = smooth(parent, "Barril", Vector3.new(3.6, 2.6, 2.6), CFrame.new(position + Vector3.new(0, 1.3, 0)), COLORS.BarrelRed)
	body.Shape = Enum.PartType.Cylinder
	body.CanCollide = false
	local band = smooth(parent, "BarrilFaixa", Vector3.new(1.2, 2.7, 2.7), CFrame.new(position + Vector3.new(0, 1.3, 0)), COLORS.White)
	band.Shape = Enum.PartType.Cylinder
	band.CanCollide = false
end

-- Ninho de "galhos" onde os ovos aparecem
local function nest(parent: Instance, position: Vector3)
	local model = Instance.new("Model")
	model.Name = "Ninho"
	local inner = smooth(model, "Palha", Vector3.new(0.5, 4, 4), CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), COLORS.NestInner, Enum.Material.Fabric)
	inner.Shape = Enum.PartType.Cylinder
	inner.CanCollide = false
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * 1.9, 0.45, math.sin(angle) * 1.9)
		local stick = smooth(model, "Galho", Vector3.new(0.5, 0.55, 2.3), CFrame.lookAt(position + offset, position + offset + Vector3.new(-math.sin(angle), 0, math.cos(angle))) * CFrame.Angles(0, 0, math.rad(i * 25)), COLORS.Nest, Enum.Material.Wood)
		stick.CanCollide = false
	end
	model.Parent = parent
end

-- ---------------------------------------------------------------------
-- Área inicial
-- ---------------------------------------------------------------------

local function buildBaseArea(root: Instance)
	local base = folder(root, "AreaInicial")
	local halfWidth = Map.BaseAreaHalfWidth
	local depth = Map.BaseAreaDepth
	local y = MapLayout.FloorY
	local frontZ = MapLayout.SafeZoneStartZ
	local thickness = Map.FloorThickness
	local sandBorder = 22

	-- Grama verde-limão com studs e uma borda de areia (praia) nas laterais e no fundo
	block(base, "Grama", Vector3.new(halfWidth * 2 - sandBorder * 2, thickness, depth - sandBorder), CFrame.new(0, y - thickness / 2, frontZ - (depth - sandBorder) / 2), Map.BaseGrassColor)
	for _, side in { -1, 1 } do
		block(base, "Areia", Vector3.new(sandBorder, thickness, depth), CFrame.new(side * (halfWidth - sandBorder / 2), y - thickness / 2, frontZ - depth / 2), Map.SandColor)
	end
	block(base, "AreiaFundo", Vector3.new(halfWidth * 2 - sandBorder * 2, thickness, sandBorder), CFrame.new(0, y - thickness / 2, frontZ - depth + sandBorder / 2), Map.SandColor)

	-- Muros laranja em volta (com a abertura do corredor na frente)
	local wallHeight = 34
	local t = Map.WallThickness
	local corridorEdge = MapLayout.HalfWidth + t
	for _, side in { -1, 1 } do
		block(base, "Muro", Vector3.new(t, wallHeight, depth + t), CFrame.new(side * (halfWidth + t / 2), y + wallHeight / 2, frontZ - depth / 2 - t / 2), COLORS.Wall)
		local frontLength = halfWidth - corridorEdge + t
		block(base, "MuroFrente", Vector3.new(frontLength, wallHeight, t), CFrame.new(side * (corridorEdge + frontLength / 2), y + wallHeight / 2, frontZ + t / 2), COLORS.Wall)
	end
	block(base, "MuroFundo", Vector3.new(halfWidth * 2 + t * 2, wallHeight, t), CFrame.new(0, y + wallHeight / 2, frontZ - depth - t / 2), COLORS.Wall)

	-- Paredes invisíveis acima dos muros para ninguém sair do mapa
	local h = 80
	local top = y + wallHeight
	invisibleWall(base, Vector3.new(2, h, depth), CFrame.new(-halfWidth - 1, top + h / 2, frontZ - depth / 2))
	invisibleWall(base, Vector3.new(2, h, depth), CFrame.new(halfWidth + 1, top + h / 2, frontZ - depth / 2))
	invisibleWall(base, Vector3.new(halfWidth * 2, h, 2), CFrame.new(0, top + h / 2, frontZ - depth - 1))

	-- Praia: guarda-sóis e coqueiros na areia
	local decor = folder(base, "Decoracao")
	local spots = 7
	for i = 0, spots - 1 do
		local z = frontZ - 20 - i * (depth - 40) / (spots - 1)
		for _, side in { -1, 1 } do
			local x = side * (halfWidth - sandBorder / 2)
			if i % 2 == 0 then
				palm(decor, Vector3.new(x, y, z), 1, side * math.rad(90) + math.rad(i * 37))
			else
				umbrella(decor, Vector3.new(x, y, z), COLORS.Umbrellas[(i + (side + 1) / 2) % #COLORS.Umbrellas + 1])
			end
		end
	end
	for i = -3, 3 do
		local x = i * 55
		if i % 2 == 0 then
			palm(decor, Vector3.new(x, y, frontZ - depth + sandBorder / 2), 1.1, math.rad(i * 50))
		else
			umbrella(decor, Vector3.new(x, y, frontZ - depth + sandBorder / 2), COLORS.Umbrellas[(i + 4) % #COLORS.Umbrellas + 1])
		end
	end
end

-- ---------------------------------------------------------------------
-- Zona segura
-- ---------------------------------------------------------------------

local function buildSafeZone(root: Instance)
	local safe = folder(root, "ZonaSegura")
	local y = MapLayout.FloorY
	local startZ = MapLayout.SafeZoneStartZ
	local endZ = MapLayout.CorridorStartZ
	local length = endZ - startZ
	local thickness = Map.FloorThickness

	block(safe, "ChaoZonaSegura", Vector3.new(MapLayout.CorridorWidth, thickness, length), CFrame.new(0, y - thickness / 2, startZ + length / 2), Map.SandColor)
	paint(safe, Vector3.new(MapLayout.CorridorWidth * 0.6, 0.1, length * 0.7), CFrame.new(0, y + 0.06, startZ + length / 2), Enum.NormalId.Top, "ZONA SEGURA", Color3.fromRGB(110, 255, 80), 6)

	-- Paredes laterais da zona segura
	local wallHeight = Map.WallHeight + thickness
	for _, side in { -1, 1 } do
		block(safe, "Parede", Vector3.new(Map.WallThickness, wallHeight, length), CFrame.new(side * (MapLayout.HalfWidth + Map.WallThickness / 2), y - thickness + wallHeight / 2, startZ + length / 2), COLORS.Wall)
	end
end

-- ---------------------------------------------------------------------
-- Corredor: chão por área (sem as trincheiras), paredes com nichos VIP,
-- placas, ninhos, pedestal celestial e a Torre do Tsunami no fim
-- ---------------------------------------------------------------------

local function wallX(side: number): number
	return side * (MapLayout.HalfWidth + Map.WallThickness / 2)
end

-- Parede de um lado da área, com buracos onde ficam os nichos VIP
local function buildSideWall(parent: Instance, zone: MapLayout.Zone, side: number)
	local y = MapLayout.FloorY
	local thickness = Map.FloorThickness
	local wallHeight = Map.WallHeight + thickness
	local bottom = y - thickness
	local color = zone.Area.WallColor
	local openings: { number } = {}
	for _, alcove in MapLayout.Alcoves do
		if alcove.ZoneIndex == zone.Index and alcove.Side == side then
			table.insert(openings, alcove.CenterZ)
		end
	end
	table.sort(openings)

	local cursor = zone.StartZ
	local half = Map.VipAlcoveWidth / 2
	for _, centerZ in openings do
		local fromZ, toZ = cursor, centerZ - half
		if toZ - fromZ > 0.05 then
			block(parent, "Parede", Vector3.new(Map.WallThickness, wallHeight, toZ - fromZ), CFrame.new(wallX(side), bottom + wallHeight / 2, (fromZ + toZ) / 2), color)
		end
		-- pedaço de parede em cima da porta
		local lintelBottom = y + Map.VipAlcoveHeight
		local lintelHeight = bottom + wallHeight - lintelBottom
		block(parent, "ParedeTopo", Vector3.new(Map.WallThickness, lintelHeight, Map.VipAlcoveWidth), CFrame.new(wallX(side), lintelBottom + lintelHeight / 2, centerZ), color)
		-- pedaço de parede abaixo do chão (fecha a lateral)
		block(parent, "ParedeBase", Vector3.new(Map.WallThickness, thickness, Map.VipAlcoveWidth), CFrame.new(wallX(side), bottom + thickness / 2, centerZ), color)
		cursor = centerZ + half
	end
	if zone.EndZ - cursor > 0.05 then
		block(parent, "Parede", Vector3.new(Map.WallThickness, wallHeight, zone.EndZ - cursor), CFrame.new(wallX(side), bottom + wallHeight / 2, (cursor + zone.EndZ) / 2), color)
	end

	-- Faixa no alto da parede com a cor da raridade da área
	local rarity = zone.Rarity
	local band = if rarity then rarity.Color else COLORS.WallTop
	block(parent, "FaixaArea", Vector3.new(Map.WallThickness + 0.6, 4, zone.EndZ - zone.StartZ), CFrame.new(wallX(side), y + Map.WallHeight - 2, (zone.StartZ + zone.EndZ) / 2), band)
end

-- Nome da área pintado nas duas paredes, na cor da raridade (como no vídeo)
local function paintAreaName(parent: Instance, zone: MapLayout.Zone)
	local areaConfig = zone.Area
	local rarity = zone.Rarity
	local color = if rarity then rarity.Color else Color3.fromRGB(110, 255, 80)
	local text = string.upper(areaConfig.Name)
	if areaConfig.RecommendedSpeed ~= "" then
		text ..= "\nVelocidade " .. areaConfig.RecommendedSpeed
	end
	-- logo depois da 1ª trincheira da área, bem no alto (acima do "VIP" dos nichos)
	local z = zone.StartZ + 40
	for _, hole in MapLayout.Holes do
		if hole.ZoneIndex == zone.Index then
			z = hole.EndZ + 40
			break
		end
	end
	for _, side in { -1, 1 } do
		local x = side * (MapLayout.HalfWidth - 0.1)
		local face = if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left
		paint(parent, Vector3.new(0.1, 26, 64), CFrame.new(x, MapLayout.FloorY + 48, z), face, text, color, 5)
	end
end

-- Nicho VIP: salinha na parede com porta de vidro (só VIP atravessa)
local function buildAlcove(parent: Instance, alcove: MapLayout.Alcove)
	local y = MapLayout.FloorY
	local s = alcove.Side
	local w, d, h = Map.VipAlcoveWidth, Map.VipAlcoveDepth, Map.VipAlcoveHeight
	local inner = MapLayout.HalfWidth
	local outer = inner + Map.WallThickness + d
	local z = alcove.CenterZ
	local model = Instance.new("Model")
	model.Name = "NichoVIP"
	local gold = Color3.fromRGB(255, 205, 60)

	block(model, "Chao", Vector3.new(outer - inner, 2, w), CFrame.new(s * (inner + outer) / 2, y - 1, z), Color3.fromRGB(70, 60, 90))
	block(model, "Fundo", Vector3.new(1, h + 1, w + 2), CFrame.new(s * (outer + 0.5), y + (h + 1) / 2, z), gold)
	for _, dz in { -1, 1 } do
		block(model, "Lado", Vector3.new(outer - inner + 1, h + 1, 1), CFrame.new(s * ((inner + outer) / 2 + 0.5), y + (h + 1) / 2, z + dz * (w / 2 + 0.5)), gold)
	end
	block(model, "Teto", Vector3.new(outer - inner + 1, 1, w + 2), CFrame.new(s * ((inner + outer) / 2 + 0.5), y + h + 0.5, z), gold)

	local door = smooth(model, "PortaVIP", Vector3.new(0.5, h, w), CFrame.new(s * (inner + 0.25), y + h / 2, z), Color3.fromRGB(170, 220, 255), Enum.Material.Glass)
	door.Transparency = 0.55
	CollectionService:AddTag(door, "VipDoor")
	local face = if s > 0 then Enum.NormalId.Left else Enum.NormalId.Right
	Billboards.SurfaceText(door, face, "👑", gold, nil, 10)

	-- "VIP" verde-limão grandão na parede, em cima da porta
	paint(model, Vector3.new(0.1, 9, w + 10), CFrame.new(s * (inner - 0.1), y + h + 6, z), face, "VIP", COLORS.VipGreen, 8)

	local light = Instance.new("PointLight")
	light.Color = gold
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = door
	model.Parent = parent
end

-- Pedestal no fim do corredor onde o Ovo Celestial aparece
local function buildCelestialPedestal(parent: Instance)
	local position = MapLayout.CelestialPosition
	local base = smooth(parent, "PedestalCelestial", Vector3.new(1.2, 12, 12), CFrame.new(position + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 200, 235), Enum.Material.Neon)
	base.Shape = Enum.PartType.Cylinder
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Contagem"
	billboard.Size = UDim2.fromScale(24, 5)
	billboard.StudsOffset = Vector3.new(0, 12, 0)
	billboard.MaxDistance = 600
	billboard.LightInfluence = 0
	billboard.Parent = base
	local label = Instance.new("TextLabel")
	label.Name = "Texto"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 160, 220)
	label.Text = "OVO CELESTIAL"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(28, 22, 40)
	stroke.Parent = label
	label.Parent = billboard
	CollectionService:AddTag(label, "CelestialSign")
end

-- Torre do Tsunami: depois da parede do fim, fora do alcance das ondas
local function buildTower(parent: Instance)
	local y = MapLayout.FloorY
	local thickness = Map.FloorThickness
	local wallHeight = Map.WallHeight + thickness
	local width = MapLayout.CorridorWidth
	local endZ = MapLayout.CorridorEndZ
	local door = 16
	local pink = Map.EndWallColor
	local roomPink = Color3.fromRGB(255, 220, 250)

	-- parede do fim com uma porta no meio
	local sideWidth = (width + Map.WallThickness * 2 - door) / 2
	for _, side in { -1, 1 } do
		block(parent, "ParedeFim", Vector3.new(sideWidth, wallHeight, Map.WallThickness), CFrame.new(side * (door / 2 + sideWidth / 2), y - thickness + wallHeight / 2, endZ + Map.WallThickness / 2), pink)
	end
	local lintelHeight = wallHeight - thickness - 18
	block(parent, "ParedeFimTopo", Vector3.new(door, lintelHeight, Map.WallThickness), CFrame.new(0, y + 18 + lintelHeight / 2, endZ + Map.WallThickness / 2), pink)
	paint(parent, Vector3.new(90, 16, 0.1), CFrame.new(0, y + 34, endZ - 0.1), Enum.NormalId.Front, "TORRE DO TSUNAMI", COLORS.White, 5)

	-- sala da torre
	local roomStart = endZ + Map.WallThickness
	local roomLength = 50
	block(parent, "ChaoTorre", Vector3.new(width, thickness, roomLength), CFrame.new(0, y - thickness / 2, roomStart + roomLength / 2), roomPink)
	for _, side in { -1, 1 } do
		block(parent, "ParedeTorre", Vector3.new(Map.WallThickness, wallHeight, roomLength), CFrame.new(wallX(side), y - thickness + wallHeight / 2, roomStart + roomLength / 2), pink)
	end
	block(parent, "FundoTorre", Vector3.new(width + Map.WallThickness * 2, wallHeight, Map.WallThickness), CFrame.new(0, y - thickness + wallHeight / 2, roomStart + roomLength + Map.WallThickness / 2), pink)

	-- a torre em si (decorativa)
	local center = Vector3.new(0, y, roomStart + roomLength / 2 + 6)
	local tower = smooth(parent, "Torre", Vector3.new(70, 14, 14), CFrame.new(center + Vector3.new(0, 35, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 190, 235))
	tower.Shape = Enum.PartType.Cylinder
	for ring = 1, 4 do
		local band = smooth(parent, "Faixa", Vector3.new(2, 15, 15), CFrame.new(center + Vector3.new(0, ring * 15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 240, 160), Enum.Material.Neon)
		band.Shape = Enum.PartType.Cylinder
	end
	local top = smooth(parent, "TopoTorre", Vector3.new(1, 22, 22), CFrame.new(center + Vector3.new(0, 70.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 215, 80), Enum.Material.Neon)
	top.Shape = Enum.PartType.Cylinder
end

local function buildCorridor(root: Instance)
	local corridor = folder(root, "Corredor")
	local y = MapLayout.FloorY
	local thickness = Map.FloorThickness
	local width = MapLayout.CorridorWidth

	for _, zone in MapLayout.Zones do
		local areaConfig = zone.Area
		local zoneFolder = folder(corridor, string.format("%02d_%s", zone.Index, areaConfig.Id))

		-- Pedaços de chão entre as trincheiras
		local segments: { { number } } = {}
		local cursor = zone.StartZ
		for _, hole in MapLayout.Holes do
			if hole.ZoneIndex == zone.Index then
				table.insert(segments, { cursor, hole.StartZ })
				cursor = hole.EndZ
			end
		end
		table.insert(segments, { cursor, zone.EndZ })

		for _, segment in segments do
			local fromZ, toZ = segment[1], segment[2]
			local length = toZ - fromZ
			if length > 0.05 then
				block(zoneFolder, "Chao", Vector3.new(width, thickness, length), CFrame.new(0, y - thickness / 2, fromZ + length / 2), areaConfig.FloorColor, areaConfig.FloorMaterial)
			end
		end

		for _, side in { -1, 1 } do
			buildSideWall(zoneFolder, zone, side)
		end
		paintAreaName(zoneFolder, zone)
	end

	-- Trincheiras de areia: fundo + rampa (no lado da base, para sair indo para casa)
	-- e barris vermelho/branco nas duas beiradas
	local holesFolder = folder(corridor, "Trincheiras")
	local depth = Map.HoleDepth
	local rampLength = Map.HoleRampLength
	local sand = Map.TrenchColor
	for _, hole in MapLayout.Holes do
		local zone = MapLayout.Zones[hole.ZoneIndex]
		local holeLength = hole.EndZ - hole.StartZ
		local bottomThickness = thickness - depth
		block(holesFolder, "FundoTrincheira", Vector3.new(width, bottomThickness, holeLength), CFrame.new(0, y - depth - bottomThickness / 2, hole.StartZ + holeLength / 2), sand)

		-- Rampa: de (StartZ, chão) até (StartZ + rampLength, fundo)
		local angle = math.atan2(depth, rampLength)
		local slabLength = math.sqrt(depth * depth + rampLength * rampLength)
		local slabThickness = 1.5
		local topMiddle = Vector3.new(0, y - depth / 2, hole.StartZ + rampLength / 2)
		local rotation = CFrame.Angles(angle, 0, 0)
		local normal = rotation.UpVector
		local center = topMiddle - normal * (slabThickness / 2)
		block(holesFolder, "Rampa", Vector3.new(width, slabThickness, slabLength), CFrame.new(center) * rotation, sand:Lerp(Color3.new(0, 0, 0), 0.08), zone.Area.FloorMaterial)

		local count = math.floor(width / Map.BarrelSpacing)
		for i = 0, count - 1 do
			local x = -width / 2 + Map.BarrelSpacing * (i + 0.5)
			barrel(holesFolder, Vector3.new(x, y, hole.StartZ - 2))
			barrel(holesFolder, Vector3.new(x + Map.BarrelSpacing / 2, y, hole.EndZ + 2))
		end
	end

	local vipFolder = folder(corridor, "NichosVIP")
	for _, alcove in MapLayout.Alcoves do
		buildAlcove(vipFolder, alcove)
	end

	buildCelestialPedestal(corridor)
	buildTower(folder(corridor, "TorreDoTsunami"))

	-- Ninhos
	local nestsFolder = folder(corridor, "Ninhos")
	for _, list in MapLayout.Nests do
		for _, position in list do
			nest(nestsFolder, position)
		end
	end
end

-- Anel ciano da loja de upgrades (entre os cercados e a zona segura)
local function buildUpgradeRing(root: Instance)
	local position = Map.UpgradeRingPosition
	local radius = Map.UpgradeRingRadius
	local cyan = Color3.fromRGB(40, 230, 255)
	local ring = smooth(root, "AnelUpgrades", Vector3.new(0.3, radius * 2, radius * 2), CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), cyan, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.CanCollide = false
	local inner = smooth(root, "AnelMiolo", Vector3.new(0.35, radius * 2 - 2.4, radius * 2 - 2.4), CFrame.new(position + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(20, 120, 150))
	inner.Shape = Enum.PartType.Cylinder
	inner.CanCollide = false
	inner.Transparency = 0.3

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(cyan)
	sparkles.LightEmission = 0.8
	sparkles.Rate = 12
	sparkles.Lifetime = NumberRange.new(1, 2)
	sparkles.Speed = NumberRange.new(3, 6)
	sparkles.EmissionDirection = Enum.NormalId.Right -- o cilindro está deitado: "direita" aponta para cima
	sparkles.Parent = ring

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(18, 4)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.MaxDistance = 250
	billboard.LightInfluence = 0
	billboard.Parent = ring
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextColor3 = cyan
	label.Text = "⬆ UPGRADES"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(28, 22, 40)
	stroke.Parent = label
	label.Parent = billboard
end

local function setupLighting()
	Lighting.ClockTime = 13
	Lighting.Brightness = 3
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 180)
	Lighting.Ambient = Color3.fromRGB(120, 120, 130)
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.15
		atmosphere.Haze = 0.6
		atmosphere.Color = Color3.fromRGB(200, 225, 255)
		atmosphere.Parent = Lighting
	end
end

function MapBuilder.Build(): Folder
	-- Remove peças do template padrão que taparia os buracos
	for _, name in { "Baseplate", "SpawnLocation" } do
		local existing = Workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
	if Map.ClearTerrain then
		Workspace.Terrain:Clear()
	end

	local old = Workspace:FindFirstChild("Mapa")
	if old then
		old:Destroy()
	end

	local root = Instance.new("Folder")
	root.Name = "Mapa"
	buildBaseArea(root)
	buildSafeZone(root)
	buildCorridor(root)
	buildUpgradeRing(root)
	root.Parent = Workspace

	setupLighting()
	return root
end

return MapBuilder
