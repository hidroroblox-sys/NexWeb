--!strict
--[[
	MapBuilder: constrói o mapa inteiro por código (a partir do MapLayout).
	  [ ÁREA INICIAL c/ celeiros ] -> [ ZONA SEGURA ] -> [ CORREDOR com buracos e zonas ] -> [ FIM ]
	Os celeiros são construídos pelo BarnService.
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
	Grass = Color3.fromRGB(110, 200, 75),
	Wood = Color3.fromRGB(150, 100, 55),
	WoodDark = Color3.fromRGB(110, 70, 40),
	SafeZone = Color3.fromRGB(120, 225, 120),
	White = Color3.fromRGB(255, 255, 255),
	Leaves = Color3.fromRGB(60, 160, 60),
	Trunk = Color3.fromRGB(110, 75, 45),
	Nest = Color3.fromRGB(125, 85, 45),
	NestInner = Color3.fromRGB(205, 165, 95),
}

local RAINBOW = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(255, 170, 60),
	Color3.fromRGB(255, 235, 80),
	Color3.fromRGB(110, 230, 110),
	Color3.fromRGB(80, 170, 255),
	Color3.fromRGB(180, 110, 255),
}

local function block(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function invisibleWall(parent: Instance, size: Vector3, cframe: CFrame)
	local wall = block(parent, "InvisibleWall", size, cframe, COLORS.White)
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

-- Cerca de madeira entre dois pontos (no chão)
local function fence(parent: Instance, from: Vector3, to: Vector3)
	local direction = to - from
	local length = direction.Magnitude
	if length < 1 then
		return
	end
	local center = (from + to) / 2
	local look = CFrame.lookAt(center, to)
	for _, height in { 1.6, 3.2 } do
		block(parent, "Rail", Vector3.new(0.4, 0.5, length), look + Vector3.new(0, height, 0), COLORS.Wood, Enum.Material.Wood)
	end
	local posts = math.max(1, math.floor(length / 10))
	for i = 0, posts do
		local point = from + direction * (i / posts)
		block(parent, "Post", Vector3.new(0.8, 4.2, 0.8), CFrame.new(point + Vector3.new(0, 2.1, 0)), COLORS.WoodDark, Enum.Material.Wood)
	end
end

local function tree(parent: Instance, position: Vector3, scale: number)
	block(parent, "Trunk", Vector3.new(2, 10, 2) * scale, CFrame.new(position + Vector3.new(0, 5 * scale, 0)), COLORS.Trunk, Enum.Material.Wood)
	local leaves = block(parent, "Leaves", Vector3.new(10, 10, 10) * scale, CFrame.new(position + Vector3.new(0, 12 * scale, 0)), COLORS.Leaves, Enum.Material.Grass)
	leaves.Shape = Enum.PartType.Ball
end

-- Ninho de "galhos" onde os ovos aparecem
local function nest(parent: Instance, position: Vector3)
	local model = Instance.new("Model")
	model.Name = "Ninho"
	local inner = block(model, "Palha", Vector3.new(0.5, 4, 4), CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.rad(90)), COLORS.NestInner, Enum.Material.Fabric)
	inner.Shape = Enum.PartType.Cylinder
	inner.CanCollide = false
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * 1.9, 0.45, math.sin(angle) * 1.9)
		local stick = block(model, "Galho", Vector3.new(0.5, 0.55, 2.3), CFrame.lookAt(position + offset, position + offset + Vector3.new(-math.sin(angle), 0, math.cos(angle))) * CFrame.Angles(0, 0, math.rad(i * 25)), COLORS.Nest, Enum.Material.Wood)
		stick.CanCollide = false
	end
	model.Parent = parent
end

-- Arco com placa (nome da zona) atravessando o corredor
local function zoneArch(parent: Instance, z: number, title: string, subtitle: string, color: Color3)
	local halfWidth = MapLayout.HalfWidth
	local y = MapLayout.FloorY
	for _, side in { -1, 1 } do
		block(parent, "Pilar", Vector3.new(3, 38, 3), CFrame.new(side * (halfWidth - 1.5), y + 19, z), color:Lerp(Color3.new(0, 0, 0), 0.3))
	end
	local sign = block(parent, "Placa", Vector3.new(MapLayout.CorridorWidth - 6, 9, 1.5), CFrame.new(0, y + 33, z), color)
	sign.Material = Enum.Material.SmoothPlastic
	local text = title .. "\n" .. subtitle
	Billboards.SurfaceText(sign, Enum.NormalId.Front, text, Color3.new(1, 1, 1), nil, 12)
	Billboards.SurfaceText(sign, Enum.NormalId.Back, text, Color3.new(1, 1, 1), nil, 12)
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

	block(base, "Grama", Vector3.new(halfWidth * 2, 4, depth), CFrame.new(0, y - 2, frontZ - depth / 2), COLORS.Grass, Enum.Material.Grass)

	-- Cercas (com abertura para o corredor)
	local corridorEdge = MapLayout.HalfWidth + Map.WallThickness
	local corners = {
		Vector3.new(-halfWidth, y, frontZ),
		Vector3.new(-halfWidth, y, frontZ - depth),
		Vector3.new(halfWidth, y, frontZ - depth),
		Vector3.new(halfWidth, y, frontZ),
	}
	fence(base, Vector3.new(-corridorEdge, y, frontZ), corners[1])
	fence(base, corners[1], corners[2])
	fence(base, corners[2], corners[3])
	fence(base, corners[3], corners[4])
	fence(base, corners[4], Vector3.new(corridorEdge, y, frontZ))

	-- Paredes invisíveis para ninguém sair do mapa
	local h = 60
	invisibleWall(base, Vector3.new(2, h, depth), CFrame.new(-halfWidth - 1, y + h / 2, frontZ - depth / 2))
	invisibleWall(base, Vector3.new(2, h, depth), CFrame.new(halfWidth + 1, y + h / 2, frontZ - depth / 2))
	invisibleWall(base, Vector3.new(halfWidth * 2, h, 2), CFrame.new(0, y + h / 2, frontZ - depth - 1))
	local sideLength = halfWidth - corridorEdge
	for _, side in { -1, 1 } do
		invisibleWall(base, Vector3.new(sideLength, h, 2), CFrame.new(side * (corridorEdge + sideLength / 2), y + h / 2, frontZ + 1))
	end

	-- Árvores e fardos de feno para decorar
	local treeSpots = {
		Vector3.new(-195, y, -15),
		Vector3.new(195, y, -15),
		Vector3.new(-195, y, -185),
		Vector3.new(195, y, -185),
		Vector3.new(-60, y, -195),
		Vector3.new(60, y, -195),
		Vector3.new(-50, y, -20),
		Vector3.new(50, y, -20),
	}
	for index, position in treeSpots do
		tree(base, position, if index % 2 == 0 then 1.1 else 0.9)
	end
	for _, position in { Vector3.new(-30, y, -40), Vector3.new(30, y, -40) } do
		block(base, "Feno", Vector3.new(5, 3, 4), CFrame.new(position + Vector3.new(0, 1.5, 0)), Color3.fromRGB(230, 195, 90), Enum.Material.Fabric)
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

	local floor = block(safe, "ChaoZonaSegura", Vector3.new(MapLayout.CorridorWidth, thickness, length), CFrame.new(0, y - thickness / 2, startZ + length / 2), COLORS.SafeZone)
	Billboards.SurfaceText(floor, Enum.NormalId.Top, "ZONA SEGURA", Color3.new(1, 1, 1), nil, 7)

	-- Paredes laterais da zona segura
	local wallHeight = Map.WallHeight + thickness
	for _, side in { -1, 1 } do
		block(safe, "Parede", Vector3.new(Map.WallThickness, wallHeight, length), CFrame.new(side * (MapLayout.HalfWidth + Map.WallThickness / 2), y - thickness + wallHeight / 2, startZ + length / 2), Color3.fromRGB(150, 110, 70), Enum.Material.WoodPlanks)
	end

	zoneArch(safe, startZ + 1, "FUJA DO TSUNAMI!", "Zona segura: aqui a onda não pega", Color3.fromRGB(60, 190, 80))
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
			block(parent, "Parede", Vector3.new(Map.WallThickness, wallHeight, toZ - fromZ), CFrame.new(wallX(side), bottom + wallHeight / 2, (fromZ + toZ) / 2), color, Enum.Material.Slate)
		end
		-- pedaço de parede em cima da porta
		local lintelBottom = y + Map.VipAlcoveHeight
		local lintelHeight = bottom + wallHeight - lintelBottom
		block(parent, "ParedeTopo", Vector3.new(Map.WallThickness, lintelHeight, Map.VipAlcoveWidth), CFrame.new(wallX(side), lintelBottom + lintelHeight / 2, centerZ), color, Enum.Material.Slate)
		-- pedaço de parede abaixo do chão (fecha a lateral)
		block(parent, "ParedeBase", Vector3.new(Map.WallThickness, thickness, Map.VipAlcoveWidth), CFrame.new(wallX(side), bottom + thickness / 2, centerZ), color, Enum.Material.Slate)
		cursor = centerZ + half
	end
	if zone.EndZ - cursor > 0.05 then
		block(parent, "Parede", Vector3.new(Map.WallThickness, wallHeight, zone.EndZ - cursor), CFrame.new(wallX(side), bottom + wallHeight / 2, (cursor + zone.EndZ) / 2), color, Enum.Material.Slate)
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

	block(model, "Chao", Vector3.new(outer - inner, 2, w), CFrame.new(s * (inner + outer) / 2, y - 1, z), Color3.fromRGB(70, 60, 90), Enum.Material.SmoothPlastic)
	block(model, "Fundo", Vector3.new(1, h + 1, w + 2), CFrame.new(s * (outer + 0.5), y + (h + 1) / 2, z), gold, Enum.Material.SmoothPlastic)
	for _, dz in { -1, 1 } do
		block(model, "Lado", Vector3.new(outer - inner + 1, h + 1, 1), CFrame.new(s * ((inner + outer) / 2 + 0.5), y + (h + 1) / 2, z + dz * (w / 2 + 0.5)), gold, Enum.Material.SmoothPlastic)
	end
	block(model, "Teto", Vector3.new(outer - inner + 1, 1, w + 2), CFrame.new(s * ((inner + outer) / 2 + 0.5), y + h + 0.5, z), gold, Enum.Material.SmoothPlastic)

	local door = block(model, "PortaVIP", Vector3.new(0.5, h, w), CFrame.new(s * (inner + 0.25), y + h / 2, z), Color3.fromRGB(170, 220, 255), Enum.Material.Glass)
	door.Transparency = 0.55
	CollectionService:AddTag(door, "VipDoor")
	Billboards.SurfaceText(door, if s > 0 then Enum.NormalId.Left else Enum.NormalId.Right, "👑 VIP", gold, nil, 10)

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
	local base = block(parent, "PedestalCelestial", Vector3.new(1.2, 12, 12), CFrame.new(position + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 200, 235), Enum.Material.Neon)
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
	local pink = Color3.fromRGB(255, 220, 250)

	-- parede do fim com uma porta no meio
	local sideWidth = (width + Map.WallThickness * 2 - door) / 2
	for _, side in { -1, 1 } do
		block(parent, "ParedeFim", Vector3.new(sideWidth, wallHeight, Map.WallThickness), CFrame.new(side * (door / 2 + sideWidth / 2), y - thickness + wallHeight / 2, endZ + Map.WallThickness / 2), pink, Enum.Material.SmoothPlastic)
	end
	local lintelHeight = wallHeight - thickness - 18
	local lintel = block(parent, "ParedeFimTopo", Vector3.new(door, lintelHeight, Map.WallThickness), CFrame.new(0, y + 18 + lintelHeight / 2, endZ + Map.WallThickness / 2), pink, Enum.Material.SmoothPlastic)
	Billboards.SurfaceText(lintel, Enum.NormalId.Front, "TORRE DO TSUNAMI", Color3.fromRGB(255, 120, 220), nil, 8)

	-- sala da torre
	local roomStart = endZ + Map.WallThickness
	local roomLength = 50
	block(parent, "ChaoTorre", Vector3.new(width, thickness, roomLength), CFrame.new(0, y - thickness / 2, roomStart + roomLength / 2), Color3.fromRGB(255, 235, 250), Enum.Material.Marble)
	for _, side in { -1, 1 } do
		block(parent, "ParedeTorre", Vector3.new(Map.WallThickness, wallHeight, roomLength), CFrame.new(wallX(side), y - thickness + wallHeight / 2, roomStart + roomLength / 2), pink, Enum.Material.SmoothPlastic)
	end
	block(parent, "FundoTorre", Vector3.new(width + Map.WallThickness * 2, wallHeight, Map.WallThickness), CFrame.new(0, y - thickness + wallHeight / 2, roomStart + roomLength + Map.WallThickness / 2), pink, Enum.Material.SmoothPlastic)

	-- a torre em si (decorativa)
	local center = Vector3.new(0, y, roomStart + roomLength / 2 + 6)
	local tower = block(parent, "Torre", Vector3.new(70, 14, 14), CFrame.new(center + Vector3.new(0, 35, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 190, 235), Enum.Material.SmoothPlastic)
	tower.Shape = Enum.PartType.Cylinder
	for ring = 1, 4 do
		local band = block(parent, "Faixa", Vector3.new(2, 15, 15), CFrame.new(center + Vector3.new(0, ring * 15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 240, 160), Enum.Material.Neon)
		band.Shape = Enum.PartType.Cylinder
	end
	local top = block(parent, "TopoTorre", Vector3.new(1, 22, 22), CFrame.new(center + Vector3.new(0, 70.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 215, 80), Enum.Material.Neon)
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
				if areaConfig.Rainbow then
					-- listras de arco-íris de 12 studs
					local stripes = math.max(1, math.floor(length / 12))
					local stripeLength = length / stripes
					for i = 0, stripes - 1 do
						local z0 = fromZ + i * stripeLength
						local color = RAINBOW[(math.floor(z0 / 12) % #RAINBOW) + 1]
						block(zoneFolder, "Chao", Vector3.new(width, thickness, stripeLength), CFrame.new(0, y - thickness / 2, z0 + stripeLength / 2), color, areaConfig.FloorMaterial)
					end
				else
					block(zoneFolder, "Chao", Vector3.new(width, thickness, length), CFrame.new(0, y - thickness / 2, fromZ + length / 2), areaConfig.FloorColor, areaConfig.FloorMaterial)
				end
			end
		end

		for _, side in { -1, 1 } do
			buildSideWall(zoneFolder, zone, side)
		end

		local rarity = zone.Rarity
		local color = if rarity then rarity.Color else Color3.fromRGB(60, 190, 80)
		local subtitle = if areaConfig.RecommendedSpeed ~= ""
			then "Velocidade recomendada: " .. areaConfig.RecommendedSpeed
			else "Corra e pegue ovos!"
		zoneArch(zoneFolder, zone.StartZ + 1, areaConfig.Name, subtitle, color)
	end

	-- Trincheiras: fundo + rampa (rampa no lado da base, para sair indo para casa)
	local holesFolder = folder(corridor, "Trincheiras")
	local depth = Map.HoleDepth
	local rampLength = Map.HoleRampLength
	for _, hole in MapLayout.Holes do
		local zone = MapLayout.Zones[hole.ZoneIndex]
		local floorColor = zone.Area.FloorColor
		local bottomColor = floorColor:Lerp(Color3.new(0, 0, 0), 0.45)
		local holeLength = hole.EndZ - hole.StartZ
		local bottomThickness = thickness - depth
		block(holesFolder, "FundoTrincheira", Vector3.new(width, bottomThickness, holeLength), CFrame.new(0, y - depth - bottomThickness / 2, hole.StartZ + holeLength / 2), bottomColor, Enum.Material.Slate)

		-- Rampa: de (StartZ, chão) até (StartZ + rampLength, fundo)
		local angle = math.atan2(depth, rampLength)
		local slabLength = math.sqrt(depth * depth + rampLength * rampLength)
		local slabThickness = 1.5
		local topMiddle = Vector3.new(0, y - depth / 2, hole.StartZ + rampLength / 2)
		local rotation = CFrame.Angles(angle, 0, 0)
		local normal = rotation.UpVector
		local center = topMiddle - normal * (slabThickness / 2)
		block(holesFolder, "Rampa", Vector3.new(width, slabThickness, slabLength), CFrame.new(center) * rotation, floorColor:Lerp(Color3.new(0, 0, 0), 0.2), zone.Area.FloorMaterial)
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

-- Anel ciano da loja de upgrades (entre os celeiros e a zona segura)
local function buildUpgradeRing(root: Instance)
	local position = Map.UpgradeRingPosition
	local radius = Map.UpgradeRingRadius
	local cyan = Color3.fromRGB(40, 230, 255)
	local ring = block(root, "AnelUpgrades", Vector3.new(0.3, radius * 2, radius * 2), CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), cyan, Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.CanCollide = false
	local inner = block(root, "AnelMiolo", Vector3.new(0.35, radius * 2 - 2.4, radius * 2 - 2.4), CFrame.new(position + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(20, 120, 150), Enum.Material.SmoothPlastic)
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
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	Lighting.Ambient = Color3.fromRGB(110, 110, 120)
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.2
		atmosphere.Haze = 1
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
