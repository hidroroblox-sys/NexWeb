--!strict
--[[
	MapLayout: calcula a GEOMETRIA do mapa a partir do GameConfig.
	Não cria nenhuma peça — só números. O servidor usa para construir o mapa,
	gerar ninhos e checar o tsunami; o cliente usa para desenhar a onda.

	Eixos:
	  • O corredor vai no sentido +Z (Z = 0 é o começo da zona segura).
	  • As bases (cercados) ficam em Z negativo, em meio-círculo.
]]

local GameConfig = require(script.Parent.GameConfig)

export type Zone = {
	Index: number,
	Area: GameConfig.Area,
	Rarity: GameConfig.Rarity?,
	StartZ: number,
	EndZ: number,
}

export type Hole = {
	StartZ: number,
	EndZ: number,
	ZoneIndex: number,
}

export type Alcove = {
	ZoneIndex: number,
	Side: number, -- -1 esquerda, 1 direita
	CenterZ: number,
}

export type BarnLayout = {
	Index: number,
	CFrame: CFrame, -- centro do chão do cercado; LookVector aponta para o portão
}

local Map = GameConfig.Map

local MapLayout = {}

MapLayout.FloorY = Map.FloorY
MapLayout.CorridorWidth = Map.CorridorWidth
MapLayout.HalfWidth = Map.CorridorWidth / 2
MapLayout.SafeZoneStartZ = Map.SafeZoneStartZ
MapLayout.CorridorStartZ = Map.SafeZoneStartZ + Map.SafeZoneLength -- fim da zona segura

-- ---------------------------------------------------------------------
-- Áreas
-- ---------------------------------------------------------------------

local zones: { Zone } = {}
do
	local z = MapLayout.CorridorStartZ
	for index, areaConfig in GameConfig.Areas do
		local zone: Zone = {
			Index = index,
			Area = areaConfig,
			Rarity = if areaConfig.Rarity then GameConfig.RarityById[areaConfig.Rarity] else nil,
			StartZ = z,
			EndZ = z + areaConfig.Length,
		}
		table.insert(zones, zone)
		z = zone.EndZ
	end
end

MapLayout.Zones = zones
MapLayout.CorridorEndZ = zones[#zones].EndZ

function MapLayout.GetZoneAtZ(z: number): Zone?
	for _, zone in zones do
		if z >= zone.StartZ and z < zone.EndZ then
			return zone
		end
	end
	return nil
end

-- ---------------------------------------------------------------------
-- Trincheiras (faixas de areia mais baixas, de parede a parede):
-- no começo de cada área (a partir da 2ª) e depois a cada TrenchSpacing.
-- A última da área precisa deixar meio espaçamento livre antes da próxima área.
-- ---------------------------------------------------------------------

local holes: { Hole } = {}
do
	local length = Map.HoleLength
	for index, zone in zones do
		if index >= 2 then
			local spacing = zone.Area.TrenchSpacing
			local startZ = zone.StartZ + 2
			while startZ + length <= zone.EndZ - spacing / 2 or startZ == zone.StartZ + 2 do
				table.insert(holes, { StartZ = startZ, EndZ = startZ + length, ZoneIndex = index })
				startZ += spacing
			end
		end
	end
	table.sort(holes, function(a, b)
		return a.StartZ < b.StartZ
	end)
end

MapLayout.Holes = holes

-- Está dentro (no sentido Z) de alguma trincheira? "margin" encolhe a área.
function MapLayout.IsInHole(z: number, margin: number?): boolean
	local m = margin or 0
	for _, hole in holes do
		if z >= hole.StartZ + m and z <= hole.EndZ - m then
			return true
		end
	end
	return false
end

function MapLayout.IsNearHole(z: number, distance: number): boolean
	for _, hole in holes do
		if z >= hole.StartZ - distance and z <= hole.EndZ + distance then
			return true
		end
	end
	return false
end

-- Área sem tsunami: toda a área inicial + zona segura (e atrás do fim do corredor)
function MapLayout.IsSafeZ(z: number): boolean
	return z < MapLayout.CorridorStartZ or z > MapLayout.CorridorEndZ
end

-- ---------------------------------------------------------------------
-- Nichos VIP (portas de vidro nas paredes, um de cada lado por área),
-- no meio do chão entre a 1ª e a 2ª trincheira da área
-- ---------------------------------------------------------------------

local alcoves: { Alcove } = {}
do
	for index, zone in zones do
		if index >= 2 then
			local zoneHoles: { Hole } = {}
			for _, hole in holes do
				if hole.ZoneIndex == index then
					table.insert(zoneHoles, hole)
				end
			end
			local gapStart = if zoneHoles[1] then zoneHoles[1].EndZ else zone.StartZ
			local gapEnd = if zoneHoles[2] then zoneHoles[2].StartZ else zone.EndZ
			local centerZ = (gapStart + gapEnd) / 2
			for _, side in { -1, 1 } do
				table.insert(alcoves, { ZoneIndex = index, Side = side, CenterZ = centerZ })
			end
		end
	end
end

MapLayout.Alcoves = alcoves

-- Está dentro de um nicho VIP?
function MapLayout.IsInAlcove(position: Vector3): boolean
	if math.abs(position.X) < MapLayout.HalfWidth + 1 then
		return false
	end
	if position.Y > MapLayout.FloorY + Map.VipAlcoveHeight + 2 then
		return false
	end
	local side = if position.X < 0 then -1 else 1
	for _, alcove in alcoves do
		if alcove.Side == side and math.abs(position.Z - alcove.CenterZ) <= Map.VipAlcoveWidth / 2 then
			return true
		end
	end
	return false
end

-- ---------------------------------------------------------------------
-- Ninhos (posições fixas, sorteadas com semente para ser sempre igual)
-- ---------------------------------------------------------------------

local nests: { { Vector3 } } = {}
do
	local rng = Random.new(Map.Seed)
	local edge = MapLayout.HalfWidth - 8
	for _, zone in zones do
		local list: { Vector3 } = {}
		local tries = 0
		while #list < zone.Area.NestCount and tries < 3000 do
			tries += 1
			local z = rng:NextNumber(zone.StartZ + 6, zone.EndZ - 6)
			local x = rng:NextNumber(-edge, edge)
			if not MapLayout.IsNearHole(z, 6) then
				local ok = true
				for _, other in list do
					if (Vector2.new(other.X, other.Z) - Vector2.new(x, z)).Magnitude < 9 then
						ok = false
						break
					end
				end
				if ok then
					table.insert(list, Vector3.new(x, MapLayout.FloorY, z))
				end
			end
		end
		nests[zone.Index] = list
	end
end

MapLayout.Nests = nests

-- Pedestal do ovo celestial: perto do fim do corredor, longe das trincheiras
do
	local last = zones[#zones]
	local z = last.EndZ - 60
	while MapLayout.IsNearHole(z, 10) and z > last.StartZ + 30 do
		z -= 10
	end
	MapLayout.CelestialPosition = Vector3.new(0, MapLayout.FloorY, z)
end

-- ---------------------------------------------------------------------
-- Bases (cercados) em meio-círculo virados para a entrada do corredor
-- ---------------------------------------------------------------------

local barns: { BarnLayout } = {}
do
	local count = GameConfig.Players.MaxPlayers
	local radius = Map.BarnArcRadius
	local span = math.rad(Map.BarnArcAngle)
	local target = Vector3.new(0, MapLayout.FloorY, MapLayout.SafeZoneStartZ)
	for index = 1, count do
		local alpha = if count == 1 then 0.5 else (index - 1) / (count - 1)
		local angle = -span / 2 + span * alpha
		local position = target + Vector3.new(math.sin(angle) * radius, 0, -math.cos(angle) * radius)
		table.insert(barns, {
			Index = index,
			CFrame = CFrame.lookAt(position, target),
		})
	end
end

MapLayout.Barns = barns
MapLayout.FloorCount = math.ceil(GameConfig.Barn.MaxSlots / GameConfig.Barn.SlotsPerFloor)

-- Altura (local) do chão de um andar (1 = térreo)
function MapLayout.FloorHeight(floor: number): number
	return (floor - 1) * Map.FloorHeight
end

-- Posição LOCAL (dentro do cercado) do ninho e do coletor de um slot.
-- Por andar: 2 colunas x 5 fileiras; slot 1 = esquerda da porta, 2 = direita...
function MapLayout.GetSlotOffsets(slotIndex: number): (Vector3, Vector3)
	local perFloor = GameConfig.Barn.SlotsPerFloor
	local floor = math.ceil(slotIndex / perFloor)
	local inFloor = (slotIndex - 1) % perFloor + 1
	local row = math.ceil(inFloor / 2) - 1
	local side = if inFloor % 2 == 1 then -1 else 1
	local y = MapLayout.FloorHeight(floor)
	local z = Map.FirstRowZ + row * Map.RowSpacing
	-- LookVector do cercado = -Z local, então o portão fica em Z negativo
	local pen = Vector3.new(side * Map.SlotColumnX, y, z)
	local pad = Vector3.new(side * Map.PadColumnX, y, z)
	return pen, pad
end

-- Elevadores (no fundo do cercado): sobe do andar f para f+1, desce de f para f-1
function MapLayout.GetElevatorOffsets(floor: number): (Vector3, Vector3)
	local y = MapLayout.FloorHeight(floor)
	local back = Map.BarnSize.Z / 2 - 3.5
	return Vector3.new(-5, y, back), Vector3.new(5, y, back)
end

-- Onde o jogador aparece ao chegar num andar
function MapLayout.GetFloorArrival(floor: number): Vector3
	return Vector3.new(0, MapLayout.FloorHeight(floor) + 3.5, Map.BarnSize.Z / 2 - 13)
end

-- Placa de comprar slot (fora do cercado, ao lado do portão)
MapLayout.SlotSignOffset = Vector3.new(Map.BarnSize.X / 2 + 3, 0, -Map.BarnSize.Z / 2 - 4)

-- Ponto dentro do cercado? (posição em coordenadas locais do cercado, qualquer andar)
function MapLayout.IsInsideBarn(localPosition: Vector3): boolean
	local size = Map.BarnSize
	return math.abs(localPosition.X) <= size.X / 2
		and localPosition.Z >= -size.Z / 2 - 3
		and localPosition.Z <= size.Z / 2
		and localPosition.Y < MapLayout.FloorHeight(MapLayout.FloorCount) + size.Y + 6
end

return MapLayout
