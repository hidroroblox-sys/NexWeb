--!strict
--[[
	MapBuilder: constrói o mapa inteiro por código (a partir do MapLayout).
	  [ ÁREA INICIAL c/ celeiros ] -> [ ZONA SEGURA ] -> [ CORREDOR com buracos e zonas ] -> [ FIM ]
	Os celeiros são construídos pelo BarnService.
]]

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
	for _, position in { Vector3.new(-25, y, -45), Vector3.new(25, y, -45), Vector3.new(0, y, -60) } do
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
-- Corredor: chão por zona (sem os buracos), paredes, placas, ninhos
-- ---------------------------------------------------------------------

local function buildCorridor(root: Instance)
	local corridor = folder(root, "Corredor")
	local y = MapLayout.FloorY
	local thickness = Map.FloorThickness
	local width = MapLayout.CorridorWidth
	local wallHeight = Map.WallHeight + thickness

	for _, zone in MapLayout.Zones do
		local zoneConfig = zone.Rarity.Zone
		local zoneFolder = folder(corridor, string.format("%02d_%s", zone.Index, zone.Rarity.Id))

		-- Pedaços de chão entre os buracos
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
				if zoneConfig.Rainbow then
					-- listras de arco-íris de 12 studs
					local stripes = math.max(1, math.floor(length / 12))
					local stripeLength = length / stripes
					for i = 0, stripes - 1 do
						local z0 = fromZ + i * stripeLength
						local color = RAINBOW[(math.floor(z0 / 12) % #RAINBOW) + 1]
						block(zoneFolder, "Chao", Vector3.new(width, thickness, stripeLength), CFrame.new(0, y - thickness / 2, z0 + stripeLength / 2), color, zoneConfig.FloorMaterial)
					end
				else
					block(zoneFolder, "Chao", Vector3.new(width, thickness, length), CFrame.new(0, y - thickness / 2, fromZ + length / 2), zoneConfig.FloorColor, zoneConfig.FloorMaterial)
				end
			end
		end

		-- Paredes altas dos dois lados
		local zoneLength = zone.EndZ - zone.StartZ
		for _, side in { -1, 1 } do
			block(zoneFolder, "Parede", Vector3.new(Map.WallThickness, wallHeight, zoneLength), CFrame.new(side * (MapLayout.HalfWidth + Map.WallThickness / 2), y - thickness + wallHeight / 2, zone.StartZ + zoneLength / 2), zoneConfig.WallColor, Enum.Material.Slate)
		end

		zoneArch(zoneFolder, zone.StartZ + 1, "Zona " .. zone.Rarity.Name, "Velocidade recomendada: " .. zoneConfig.RecommendedSpeed, zone.Rarity.Color)
	end

	-- Buracos: fundo + rampa (rampa no lado da base, para sair indo para casa)
	local holesFolder = folder(corridor, "Buracos")
	local depth = Map.HoleDepth
	local rampLength = Map.HoleRampLength
	for _, hole in MapLayout.Holes do
		local zone = MapLayout.Zones[hole.ZoneIndex]
		local floorColor = zone.Rarity.Zone.FloorColor
		local bottomColor = floorColor:Lerp(Color3.new(0, 0, 0), 0.45)
		local holeLength = hole.EndZ - hole.StartZ
		local bottomThickness = thickness - depth
		block(holesFolder, "FundoBuraco", Vector3.new(width, bottomThickness, holeLength), CFrame.new(0, y - depth - bottomThickness / 2, hole.StartZ + holeLength / 2), bottomColor, Enum.Material.Slate)

		-- Rampa: de (StartZ, chão) até (StartZ + rampLength, fundo)
		local angle = math.atan2(depth, rampLength)
		local slabLength = math.sqrt(depth * depth + rampLength * rampLength)
		local slabThickness = 1.5
		local topMiddle = Vector3.new(0, y - depth / 2, hole.StartZ + rampLength / 2)
		local rotation = CFrame.Angles(angle, 0, 0)
		local normal = rotation.UpVector
		local center = topMiddle - normal * (slabThickness / 2)
		block(holesFolder, "Rampa", Vector3.new(width, slabThickness, slabLength), CFrame.new(center) * rotation, floorColor:Lerp(Color3.new(0, 0, 0), 0.2), zone.Rarity.Zone.FloorMaterial)
	end

	-- Parede do fim + placa
	local endZ = MapLayout.CorridorEndZ
	local endWall = block(corridor, "ParedeFim", Vector3.new(width + Map.WallThickness * 2, wallHeight, Map.WallThickness), CFrame.new(0, y - thickness + wallHeight / 2, endZ + Map.WallThickness / 2), Color3.fromRGB(255, 220, 250), Enum.Material.SmoothPlastic)
	Billboards.SurfaceText(endWall, Enum.NormalId.Front, "FIM", Color3.fromRGB(255, 120, 220), nil, 5)

	-- Ninhos
	local nestsFolder = folder(corridor, "Ninhos")
	for _, list in MapLayout.Nests do
		for _, position in list do
			nest(nestsFolder, position)
		end
	end
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
	root.Parent = Workspace

	setupLighting()
	return root
end

return MapBuilder
