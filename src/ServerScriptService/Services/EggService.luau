--!strict
--[[
	EggService: ovos nascendo no corredor.
	  • cada área só nasce ovo da sua raridade (máximo + reposição no GameConfig)
	  • o animal e a MUTAÇÃO são sorteados quando o ovo nasce
	  • às vezes nasce um NINHO SURPRESA (abre no cercado com mais sorte)
	  • Ovo Celestial: só 1 por vez, no pedestal do fim, a cada 15 min (com contagem)
	  • ovos derrubados (morte ou tacada) ficam no chão por um tempo; qualquer um pega
	  • "Pegar Ovo" = ProximityPrompt (segurar ~0,5 s), validado no servidor
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Billboards = require(script.Parent.Billboards)
local CarryService = require(script.Parent.CarryService)
local DataService = require(script.Parent.DataService)
local ModelFactory = require(script.Parent.ModelFactory)
local NotifyService = require(script.Parent.NotifyService)
local RateLimit = require(script.Parent.RateLimit)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)

type Item = CarryService.CarriedEgg

type WorldEgg = {
	Model: Model,
	Item: Item,
	ZoneIndex: number?, -- nil = ovo derrubado ou celestial
	NestIndex: number?,
	Celestial: boolean,
	Taken: boolean,
}

type ZoneState = {
	Active: number,
	FreeNests: { number },
	Timer: number,
}

local EggService = {}

local rng = Random.new()
local zoneStates: { [number]: ZoneState } = {}
local eggsFolder: Folder
local gameState: Instance
local celestialRecord: WorldEgg? = nil

-- ---------------------------------------------------------------------
-- Sorteios
-- ---------------------------------------------------------------------

local function rollAnimal(rarityId: string): string
	local list = GameConfig.AnimalsByRarity[rarityId]
	local weights = GameConfig.AnimalWeights
	local total = 0
	for index in list do
		total += weights[math.min(index, #weights)]
	end
	local roll = rng:NextNumber(0, total)
	for index, entry in list do
		roll -= weights[math.min(index, #weights)]
		if roll <= 0 then
			return entry.Id
		end
	end
	return list[1].Id
end

local function rollMutation(luck: number): string?
	local roll = rng:NextNumber(0, 100)
	-- da mais rara para a mais comum
	for index = #GameConfig.Mutations, 1, -1 do
		local mutation = GameConfig.Mutations[index]
		local chance = mutation.Chance * luck
		if roll < chance then
			return mutation.Id
		end
		roll -= chance
	end
	return nil
end

local function nextRarity(rarityId: string): string
	local rarity = GameConfig.RarityById[rarityId]
	local nextOne = GameConfig.Rarities[rarity.Order + 1]
	return if nextOne then nextOne.Id else rarityId
end

-- Cria o conteúdo de um ovo (ou ninho surpresa) de uma raridade
function EggService.RollItem(rarityId: string, allowLucky: boolean): Item
	if allowLucky and rng:NextNumber(0, 100) < GameConfig.LuckyNest.Chance then
		local finalRarity = rarityId
		if rng:NextNumber(0, 100) < GameConfig.LuckyNest.UpgradeChance then
			finalRarity = nextRarity(rarityId)
		end
		local egg = GameConfig.EggByRarity[finalRarity]
		return {
			EggId = egg.Id,
			AnimalId = rollAnimal(finalRarity),
			Mutation = rollMutation(GameConfig.LuckyNest.MutationLuck),
			Lucky = true,
		}
	end
	local egg = GameConfig.EggByRarity[rarityId]
	return { EggId = egg.Id, AnimalId = rollAnimal(rarityId), Mutation = rollMutation(1), Lucky = false }
end

-- ---------------------------------------------------------------------
-- Ovos no mundo
-- ---------------------------------------------------------------------

local function getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local scheduleCelestial: (delay: number) -> ()

local function onPickup(player: Player, record: WorldEgg)
	if record.Taken then
		return
	end
	if not RateLimit.Check(player, "PickupEgg", GameConfig.Pickup.Cooldown) then
		return
	end
	local root = getRoot(player)
	if not root then
		return
	end
	-- Validação de distância (não confia no cliente)
	if (root.Position - record.Model:GetPivot().Position).Magnitude > GameConfig.Pickup.MaxDistance then
		return
	end
	if not CarryService.CanCarry(player) then
		NotifyService.Notify(
			player,
			string.format("Você só consegue carregar %d ovo(s)! Leve até o seu cercado 🏠", CarryService.Capacity(player)),
			"warning"
		)
		return
	end

	record.Taken = true
	local item = record.Item
	CarryService.Add(player, item)

	local egg = GameConfig.EggsById[item.EggId]
	local rarity = GameConfig.RarityById[egg.Rarity]
	NotifyService.Effect(player, "Pickup", { Position = record.Model:GetPivot().Position, Color = rarity.Color })
	local title = if item.Lucky then "um Ninho Surpresa" else "um " .. egg.Name
	NotifyService.Notify(player, string.format("Você pegou %s (%s)!", title, rarity.Name), "rarity", rarity.Color)

	local profile = DataService.Get(player)
	if profile then
		profile.Data.Stats.EggsCollected += 1
	end

	record.Model:Destroy()
	local zoneIndex, nestIndex = record.ZoneIndex, record.NestIndex
	if zoneIndex and nestIndex then
		local state = zoneStates[zoneIndex]
		state.Active -= 1
		table.insert(state.FreeNests, nestIndex)
	end
	if record.Celestial then
		celestialRecord = nil
		gameState:SetAttribute("CelestialActive", false)
		for _, other in Players:GetPlayers() do
			NotifyService.Notify(other, player.DisplayName .. " pegou o Ovo " .. rarity.Name .. "! 🌟", "rarity", rarity.Color)
		end
		scheduleCelestial(GameConfig.Celestial.Interval)
	end
end

-- Coloca um ovo no mundo com placa e "Pegar Ovo"
local function placeWorldEgg(item: Item, ground: CFrame, record: WorldEgg)
	local egg = GameConfig.EggsById[item.EggId]
	local model: Model
	if item.Lucky then
		model = ModelFactory.CreateLuckyNest(egg.Rarity, 1)
	else
		model = ModelFactory.CreateEgg(egg.Id, 1)
		ModelFactory.ApplyMutation(model, item.Mutation)
	end
	ModelFactory.PlaceOnGround(model, ground * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), 0.3)
	model:SetAttribute("EggId", egg.Id)
	CollectionService:AddTag(model, "WorldEgg")

	local root = model.PrimaryPart
	if root then
		Billboards.WorldEgg(egg.Id, item.AnimalId, item.Mutation, item.Lucky).Parent = root
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pegar Ovo"
		prompt.ObjectText = if item.Lucky then "Ninho Surpresa" else egg.Name
		prompt.HoldDuration = GameConfig.Pickup.HoldDuration
		prompt.MaxActivationDistance = GameConfig.Pickup.PromptDistance
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = root
		prompt.Triggered:Connect(function(player)
			onPickup(player, record)
		end)
	end
	record.Model = model
	model.Parent = eggsFolder
end

local function spawnInZone(zoneIndex: number)
	local state = zoneStates[zoneIndex]
	local zone = MapLayout.Zones[zoneIndex]
	if #state.FreeNests == 0 or not zone.Rarity then
		return
	end
	local nestIndex = table.remove(state.FreeNests, rng:NextInteger(1, #state.FreeNests)) :: number
	local position = MapLayout.Nests[zoneIndex][nestIndex]
	local item = EggService.RollItem(zone.Rarity.Id, true)
	local record: WorldEgg = {
		Model = Instance.new("Model"),
		Item = item,
		ZoneIndex = zoneIndex,
		NestIndex = nestIndex,
		Celestial = false,
		Taken = false,
	}
	placeWorldEgg(item, CFrame.new(position), record)
	state.Active += 1
end

-- Ovos derrubados ficam no chão um tempo; qualquer jogador pode pegar
function EggService.DropItems(items: { Item }, position: Vector3)
	for index, item in items do
		local angle = index * (math.pi * 2 / math.max(#items, 1))
		local spot = position + Vector3.new(math.cos(angle) * 3, 0, math.sin(angle) * 3)
		local groundY = if MapLayout.IsInHole(spot.Z) and spot.Y < MapLayout.FloorY - 2
			then MapLayout.FloorY - GameConfig.Map.HoleDepth
			elseif spot.Y > MapLayout.FloorY + 8 then spot.Y - 3 -- em cima de um deck do cercado
			else MapLayout.FloorY
		local record: WorldEgg = {
			Model = Instance.new("Model"),
			Item = item,
			ZoneIndex = nil,
			NestIndex = nil,
			Celestial = false,
			Taken = false,
		}
		placeWorldEgg(item, CFrame.new(spot.X, groundY, spot.Z), record)
		task.delay(GameConfig.Pickup.DroppedLifetime, function()
			if not record.Taken then
				record.Taken = true
				record.Model:Destroy()
			end
		end)
	end
end

-- ---------------------------------------------------------------------
-- Ovo Celestial (1 por vez, no timer)
-- ---------------------------------------------------------------------

local function spawnCelestial()
	if celestialRecord then
		return
	end
	local rarityId = if rng:NextNumber(0, 100) < GameConfig.Celestial.DivineChance then "Divino" else "Celestial"
	local item = EggService.RollItem(rarityId, false)
	local record: WorldEgg = {
		Model = Instance.new("Model"),
		Item = item,
		ZoneIndex = nil,
		NestIndex = nil,
		Celestial = true,
		Taken = false,
	}
	placeWorldEgg(item, CFrame.new(MapLayout.CelestialPosition + Vector3.new(0, 1.2, 0)), record)
	celestialRecord = record
	gameState:SetAttribute("CelestialActive", true)
	local rarity = GameConfig.RarityById[rarityId]
	for _, player in Players:GetPlayers() do
		NotifyService.Notify(player, "🌟 Um OVO " .. string.upper(rarity.Id) .. " apareceu no fim do corredor!", "rarity", rarity.Color)
	end
end

local celestialToken = 0
scheduleCelestial = function(delay: number)
	celestialToken += 1
	local token = celestialToken
	gameState:SetAttribute("CelestialAt", Workspace:GetServerTimeNow() + delay)
	task.delay(delay, function()
		if token == celestialToken then
			spawnCelestial()
		end
	end)
end

-- ---------------------------------------------------------------------

function EggService.Init()
	eggsFolder = Instance.new("Folder")
	eggsFolder.Name = "Ovos"
	eggsFolder.Parent = Workspace

	local existing = ReplicatedStorage:FindFirstChild("GameState")
	if not existing then
		existing = Instance.new("Folder")
		existing.Name = "GameState"
		existing.Parent = ReplicatedStorage
	end
	gameState = existing :: Instance
	gameState:SetAttribute("CelestialActive", false)

	for zoneIndex, zone in MapLayout.Zones do
		local free: { number } = {}
		for nestIndex in MapLayout.Nests[zoneIndex] do
			table.insert(free, nestIndex)
		end
		zoneStates[zoneIndex] = { Active = 0, FreeNests = free, Timer = 0 }
		-- Começa com a área cheia
		for _ = 1, zone.Area.MaxEggs do
			spawnInZone(zoneIndex)
		end
	end

	scheduleCelestial(GameConfig.Celestial.FirstDelay)

	task.spawn(function()
		while true do
			local dt = task.wait(1)
			for zoneIndex, zone in MapLayout.Zones do
				local state = zoneStates[zoneIndex]
				local config = zone.Area
				if config.MaxEggs > 0 and state.Active < config.MaxEggs then
					state.Timer += dt
					if state.Timer >= config.SpawnInterval then
						state.Timer = 0
						spawnInZone(zoneIndex)
					end
				else
					state.Timer = 0
				end
			end
		end
	end)
end

return EggService
