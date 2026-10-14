--!strict
--[[
	MapLayout: calcula a GEOMETRIA do mapa a partir do GameConfig.
	Não cria nenhuma peça — só números. O servidor usa para construir o mapa,
	gerar ninhos e checar o tsunami; o cliente usa para desenhar a onda.

	Eixos:
	  • O corredor vai no sentido +Z (Z = 0 é o começo da zona segura).
	  • As bases (celeiros) ficam em Z negativo, em meio-círculo.
]]

local GameConfig = require(script.Parent.GameConfig)

export type Zone = {
	Index: number,
	Rarity: GameConfig.Rarity,
	StartZ: number,
	EndZ: number,
}

export type Hole = {
	StartZ: number,
	EndZ: number,
	ZoneIndex: number,
}

export type BarnLayout = {
	Index: number,
	CFrame: CFrame, -- centro do chão do celeiro; LookVector aponta para a porta (para o corredor)
}

local Map = GameConfig.Map

local MapLayout = {}

MapLayout.FloorY = Map.FloorY
MapLayout.CorridorWidth = Map.CorridorWidth
MapLayout.HalfWidth = Map.CorridorWidth / 2
MapLayout.SafeZoneStartZ = Map.SafeZoneStartZ
MapLayout.CorridorStartZ = Map.SafeZoneStartZ + Map.SafeZoneLength -- fim da zona segura

-- ---------------------------------------------------------------------
-- Zonas
-- ---------------------------------------------------------------------

local zones: { Zone } = {}
do
	local z = MapLayout.CorridorStartZ
	for index, rarity in GameConfig.Rarities do
		local zone: Zone = {
			Index = index,
			Rarity = rarity,
			StartZ = z,
			EndZ = z + rarity.Zone.Length,
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
-- Buracos: espaçamento cresce a cada zona; nunca atravessam a divisa
-- ---------------------------------------------------------------------

local holes: { Hole } = {}
do
	local length = Map.HoleLength
	local z = MapLayout.CorridorStartZ + Map.FirstHoleOffset
	local zone = MapLayout.GetZoneAtZ(z)
	while zone do
		if z + length > zone.EndZ - 2 then
			-- não cabe nesta zona: pula para o começo da próxima
			local nextZone = zones[zone.Index + 1]
			if not nextZone then
				break
			end
			zone = nextZone
			z = nextZone.StartZ + 6
		else
			table.insert(holes, { StartZ = z, EndZ = z + length, ZoneIndex = zone.Index })
			z += length + zone.Rarity.Zone.HoleSpacing
			zone = MapLayout.GetZoneAtZ(z)
		end
	end
end

MapLayout.Holes = holes

-- Está dentro (no sentido Z) de algum buraco? "margin" encolhe a área.
function MapLayout.IsInHole(z: number, margin: number?): boolean
	local m = margin or 0
	for _, hole in holes do
		if z >= hole.StartZ + m and z <= hole.EndZ - m then
			return true
		end
	end
	return false
end

-- Perto de algum buraco? (usado para não colocar ninho na beirada)
function MapLayout.IsNearHole(z: number, distance: number): boolean
	for _, hole in holes do
		if z >= hole.StartZ - distance and z <= hole.EndZ + distance then
			return true
		end
	end
	return false
end

-- Área sem tsunami: toda a área inicial + zona segura
function MapLayout.IsSafeZ(z: number): boolean
	return z < MapLayout.CorridorStartZ
end

-- ---------------------------------------------------------------------
-- Ninhos (posições fixas, sorteadas com semente para ser sempre igual)
-- ---------------------------------------------------------------------

local nests: { { Vector3 } } = {}
do
	local rng = Random.new(Map.Seed)
	local edge = MapLayout.HalfWidth - 6
	for _, zone in zones do
		local list: { Vector3 } = {}
		local tries = 0
		while #list < zone.Rarity.Zone.NestCount and tries < 600 do
			tries += 1
			local z = rng:NextNumber(zone.StartZ + 6, zone.EndZ - 6)
			local x = rng:NextNumber(-edge, edge)
			if not MapLayout.IsNearHole(z, 5) then
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

-- ---------------------------------------------------------------------
-- Celeiros em meio-círculo virados para a entrada do corredor
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

-- Posição LOCAL (dentro do celeiro) do ninho e do coletor de um slot.
-- Slot 1 = esquerda da porta, 2 = direita da porta, 3 = esquerda 2ª fileira...
function MapLayout.GetSlotOffsets(slotIndex: number): (Vector3, Vector3)
	local row = math.ceil(slotIndex / 2) - 1
	local side = if slotIndex % 2 == 1 then -1 else 1
	local z = Map.FirstRowZ + row * Map.RowSpacing
	-- LookVector do celeiro = -Z local, então a porta fica em Z negativo
	local pen = Vector3.new(side * Map.SlotColumnX, 0, z)
	local pad = Vector3.new(side * Map.PadColumnX, 0, z)
	return pen, pad
end

-- Ponto dentro do celeiro? (posição em coordenadas locais do celeiro)
function MapLayout.IsInsideBarn(localPosition: Vector3): boolean
	local size = Map.BarnSize
	return math.abs(localPosition.X) <= size.X / 2
		and localPosition.Z >= -size.Z / 2 - 3
		and localPosition.Z <= size.Z / 2
		and localPosition.Y < size.Y + 6
end

return MapLayout
