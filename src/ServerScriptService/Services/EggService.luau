--!strict
--[[
	EggService: ovos nascendo nos ninhos do corredor.
	  • cada zona só nasce ovo da sua raridade
	  • cada zona tem um máximo de ovos e repõe a cada X segundos (GameConfig)
	  • o animal é sorteado quando o ovo nasce (as chances ficam no GameConfig)
	  • "Pegar Ovo" = ProximityPrompt (segurar ~0,5 s), validado no servidor
]]

local CollectionService = game:GetService("CollectionService")
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

type WorldEgg = {
	Model: Model,
	ZoneIndex: number,
	NestIndex: number,
	EggId: string,
	AnimalId: string,
	Taken: boolean,
}

type ZoneState = {
	Active: number,
	FreeNests: { number },
	Timer: number,
}

local EggService = {}

local rng = Random.new()
local zoneStates: { ZoneState } = {}
local eggsFolder: Folder

local function pickEgg(rarityId: string): GameConfig.Egg?
	local options = GameConfig.EggsByRarity[rarityId]
	if not options or #options == 0 then
		return nil
	end
	local total = 0
	for _, egg in options do
		total += egg.SpawnWeight
	end
	local roll = rng:NextNumber(0, total)
	for _, egg in options do
		roll -= egg.SpawnWeight
		if roll <= 0 then
			return egg
		end
	end
	return options[#options]
end

local function rollAnimal(egg: GameConfig.Egg): string
	local total = 0
	for _, entry in egg.Animals do
		total += entry.Chance
	end
	local roll = rng:NextNumber(0, total)
	for _, entry in egg.Animals do
		roll -= entry.Chance
		if roll <= 0 then
			return entry.Animal
		end
	end
	return egg.Animals[#egg.Animals].Animal
end

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
			string.format("Você só consegue carregar %d ovo(s)! Leve até o seu celeiro 🏠", CarryService.Capacity(player)),
			"warning"
		)
		return
	end

	record.Taken = true
	CarryService.Add(player, { EggId = record.EggId, AnimalId = record.AnimalId })

	local egg = GameConfig.EggsById[record.EggId]
	local rarity = GameConfig.RarityById[egg.Rarity]
	NotifyService.Effect(player, "Pickup", { Position = record.Model:GetPivot().Position, Color = rarity.Color })
	NotifyService.Notify(player, string.format("Você pegou um %s (%s)!", egg.Name, rarity.Name), "rarity", rarity.Color)

	local profile = DataService.Get(player)
	if profile then
		profile.Data.Stats.EggsCollected += 1
	end

	record.Model:Destroy()
	local state = zoneStates[record.ZoneIndex]
	state.Active -= 1
	table.insert(state.FreeNests, record.NestIndex)
end

local function spawnEgg(zoneIndex: number)
	local state = zoneStates[zoneIndex]
	if #state.FreeNests == 0 then
		return
	end
	local zone = MapLayout.Zones[zoneIndex]
	local egg = pickEgg(zone.Rarity.Id)
	if not egg then
		return
	end
	local nestIndex = table.remove(state.FreeNests, rng:NextInteger(1, #state.FreeNests)) :: number
	local nestPosition = MapLayout.Nests[zoneIndex][nestIndex]
	local animalId = rollAnimal(egg)

	local model = ModelFactory.CreateEgg(egg.Id, 1)
	ModelFactory.PlaceOnGround(model, CFrame.new(nestPosition) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), 0.3)
	model:SetAttribute("EggId", egg.Id)
	model:SetAttribute("AnimalId", animalId)
	CollectionService:AddTag(model, "WorldEgg")

	local root = model.PrimaryPart
	if not root then
		model:Destroy()
		table.insert(state.FreeNests, nestIndex)
		return
	end
	Billboards.WorldEgg(egg.Id, animalId).Parent = root

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pegar Ovo"
	prompt.ObjectText = egg.Name
	prompt.HoldDuration = GameConfig.Pickup.HoldDuration
	prompt.MaxActivationDistance = GameConfig.Pickup.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = root

	local record: WorldEgg = {
		Model = model,
		ZoneIndex = zoneIndex,
		NestIndex = nestIndex,
		EggId = egg.Id,
		AnimalId = animalId,
		Taken = false,
	}
	prompt.Triggered:Connect(function(player)
		onPickup(player, record)
	end)

	model.Parent = eggsFolder
	state.Active += 1
end

function EggService.Init()
	eggsFolder = Instance.new("Folder")
	eggsFolder.Name = "Ovos"
	eggsFolder.Parent = Workspace

	for zoneIndex, zone in MapLayout.Zones do
		local free: { number } = {}
		for nestIndex in MapLayout.Nests[zoneIndex] do
			table.insert(free, nestIndex)
		end
		zoneStates[zoneIndex] = { Active = 0, FreeNests = free, Timer = 0 }
		-- Começa com a zona cheia
		for _ = 1, zone.Rarity.Zone.MaxEggs do
			spawnEgg(zoneIndex)
		end
	end

	task.spawn(function()
		while true do
			local dt = task.wait(1)
			for zoneIndex, zone in MapLayout.Zones do
				local state = zoneStates[zoneIndex]
				local config = zone.Rarity.Zone
				if state.Active < config.MaxEggs then
					state.Timer += dt
					if state.Timer >= config.SpawnInterval then
						state.Timer = 0
						spawnEgg(zoneIndex)
					end
				else
					state.Timer = 0
				end
			end
		end
	end)
end

return EggService
