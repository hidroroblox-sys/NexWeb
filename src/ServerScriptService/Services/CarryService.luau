--!strict
--[[
	CarryService: ovos que o jogador está carregando (ainda não estão no cercado).
	  • ficam visíveis nas costas do personagem (todo mundo vê)
	  • se o jogador morrer, PERDE todos os ovos carregados
	  • NÃO são salvos no DataStore (só o que está no cercado é salvo)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local ModelFactory = require(script.Parent.ModelFactory)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

export type CarriedEgg = {
	EggId: string,
	AnimalId: string, -- o animal já vem sorteado desde que o ovo nasceu
	Mutation: string?,
	Lucky: boolean?, -- é um Ninho Surpresa (abre no cercado)
}

local CarryService = {}

local carried: { [Player]: { CarriedEgg } } = {}
local visuals: { [Player]: { Model } } = {}

local function updateAttribute(player: Player)
	local list = carried[player]
	player:SetAttribute("Carrying", if list then #list else 0)
end

local function clearVisuals(player: Player)
	local list = visuals[player]
	if list then
		for _, model in list do
			model:Destroy()
		end
	end
	visuals[player] = {}
end

-- Recria os ovos nas costas (2 colunas, empilhados)
local function refreshVisuals(player: Player)
	clearVisuals(player)
	local character = player.Character
	local list = carried[player]
	if not character or not list then
		return
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso or not torso:IsA("BasePart") then
		return
	end
	local models = visuals[player]
	for index, item in list do
		local model: Model
		if item.Lucky then
			model = ModelFactory.CreateLuckyNest(GameConfig.EggsById[item.EggId].Rarity, 0.42)
		else
			model = ModelFactory.CreateEgg(item.EggId, 0.45)
			ModelFactory.ApplyMutation(model, item.Mutation)
		end
		ModelFactory.MakeWeldable(model)
		local root = model.PrimaryPart
		if root then
			local column = if index % 2 == 1 then -0.55 else 0.55
			local row = math.floor((index - 1) / 2)
			-- +Z local do torso = costas
			model:PivotTo(torso.CFrame * CFrame.new(column, -0.2 + row * 1.45, 1.05))
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = root
			weld.Parent = root
			model.Name = "OvoCarregado"
			model.Parent = character
			table.insert(models, model)
		else
			model:Destroy()
		end
	end
end

function CarryService.Count(player: Player): number
	local list = carried[player]
	return if list then #list else 0
end

function CarryService.Capacity(player: Player): number
	local profile = DataService.Get(player)
	return if profile then profile.Data.CarryCapacity else GameConfig.Carry.Start
end

function CarryService.CanCarry(player: Player): boolean
	return CarryService.Count(player) < CarryService.Capacity(player)
end

function CarryService.Add(player: Player, item: CarriedEgg): boolean
	if not CarryService.CanCarry(player) then
		return false
	end
	local list = carried[player]
	if not list then
		list = {}
		carried[player] = list
	end
	table.insert(list, item)
	updateAttribute(player)
	refreshVisuals(player)
	return true
end

-- Tira o primeiro ovo da mão (para colocar no cercado)
function CarryService.TakeOne(player: Player): CarriedEgg?
	local list = carried[player]
	if not list or #list == 0 then
		return nil
	end
	local item = table.remove(list, 1)
	updateAttribute(player)
	refreshVisuals(player)
	return item
end

-- Tira tudo da mão (para derrubar no chão quando morre ou leva tacada)
function CarryService.TakeAll(player: Player): { CarriedEgg }
	local list = carried[player] or {}
	carried[player] = {}
	updateAttribute(player)
	clearVisuals(player)
	return list
end

-- Perde tudo (saída do jogo)
function CarryService.Clear(player: Player)
	carried[player] = {}
	updateAttribute(player)
	clearVisuals(player)
end


function CarryService.Setup(player: Player)
	carried[player] = {}
	visuals[player] = {}
	updateAttribute(player)
end

function CarryService.Remove(player: Player)
	clearVisuals(player)
	carried[player] = nil
	visuals[player] = nil
end

return CarryService
