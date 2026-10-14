--!strict
--[[
	Wallet: dinheiro do jogador. Só o servidor mexe aqui.
	Também mantém os atributos do jogador (que o HUD lê) e o leaderstats.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Format = require(ReplicatedStorage.Shared.Format)

local Wallet = {}

-- Atualiza atributos + placar (leaderstats)
function Wallet.Refresh(player: Player)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local data = profile.Data
	player:SetAttribute("Money", data.Money)
	player:SetAttribute("SpeedLevel", data.SpeedLevel)
	player:SetAttribute("CarryCapacity", data.CarryCapacity)
	player:SetAttribute("BarnSlots", data.BarnSlots)
	player:SetAttribute("Rebirths", data.Rebirths)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild("Dinheiro") :: StringValue?
		if money then
			money.Value = Format.Money(data.Money)
		end
		local speed = leaderstats:FindFirstChild("Velocidade") :: IntValue?
		if speed then
			speed.Value = data.SpeedLevel
		end
	end
end

function Wallet.Setup(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local money = Instance.new("StringValue")
	money.Name = "Dinheiro"
	money.Parent = leaderstats

	local speed = Instance.new("IntValue")
	speed.Name = "Velocidade"
	speed.Parent = leaderstats

	leaderstats.Parent = player
	Wallet.Refresh(player)
end

function Wallet.Get(player: Player): number
	local profile = DataService.Get(player)
	return if profile then profile.Data.Money else 0
end

function Wallet.Add(player: Player, amount: number)
	local profile = DataService.Get(player)
	if not profile or amount ~= amount or amount <= 0 or amount == math.huge then
		return
	end
	profile.Data.Money += amount
	Wallet.Refresh(player)
end

-- Tenta gastar. Retorna false se não tiver dinheiro suficiente.
function Wallet.TrySpend(player: Player, amount: number): boolean
	local profile = DataService.Get(player)
	if not profile or amount ~= amount or amount < 0 or amount == math.huge then
		return false
	end
	if profile.Data.Money < amount then
		return false
	end
	profile.Data.Money -= amount
	Wallet.Refresh(player)
	return true
end

return Wallet
