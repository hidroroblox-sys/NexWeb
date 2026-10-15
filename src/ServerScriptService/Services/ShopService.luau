--!strict
--[[
	ShopService: compras, vendas e rebirth (sempre validados no servidor).
	  BuyUpgrade("Speed", 1 | 5 | 10) -> pacotes de velocidade (como no original)
	  BuyUpgrade("Carry", 1)          -> carregar +1 ovo (até 7)
	  BuyUpgrade("Slots", 1)          -> +1 slot (o mesmo da placa do cercado)
	  LevelUp(slot, 1 | 10)           -> sobe o nível do animal (renda x1,25 por nível)
	  SellAnimal(slot)                -> vende o animal daquele slot
	  Rebirth()                       -> zera a Velocidade e aumenta o multiplicador de dinheiro
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BarnService = require(script.Parent.BarnService)
local DataService = require(script.Parent.DataService)
local MovementService = require(script.Parent.MovementService)
local NotifyService = require(script.Parent.NotifyService)
local RateLimit = require(script.Parent.RateLimit)
local SyncService = require(script.Parent.SyncService)
local Wallet = require(script.Parent.Wallet)
local Format = require(ReplicatedStorage.Shared.Format)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)

local ShopService = {}

local function notEnough(price: number, money: number): string
	return "Dinheiro insuficiente! Faltam " .. Format.Money(math.max(0, price - money))
end

local function isSlotIndex(value: any): boolean
	return typeof(value) == "number"
		and value == math.floor(value)
		and value >= 1
		and value <= GameConfig.Barn.MaxSlots
end

local function buyUpgrade(player: Player, upgradeId: any, amount: any): (boolean, string)
	if not RateLimit.Check(player, "BuyUpgrade", 0.15) then
		return false, "Calma! Tente de novo."
	end
	if typeof(upgradeId) ~= "string" then
		return false, "Pedido inválido."
	end
	local profile = DataService.Get(player)
	if not profile then
		return false, "Seus dados ainda estão carregando..."
	end
	local data = profile.Data

	if upgradeId == "Speed" then
		if typeof(amount) ~= "number" or not Formulas.IsSpeedPack(amount) then
			return false, "Pedido inválido."
		end
		local price, levels = Formulas.SpeedPurchase(data.SpeedLevel, amount)
		if levels <= 0 then
			return false, "Você já está na velocidade máxima!"
		end
		if not Wallet.TrySpend(player, price) then
			return false, notEnough(price, data.Money)
		end
		data.SpeedLevel += levels
		MovementService.Apply(player)
		Wallet.Refresh(player)
		SyncService.Push(player)
		return true, string.format("Velocidade %d! 👟", Formulas.WalkSpeed(data.SpeedLevel))
	elseif upgradeId == "Carry" then
		local price = Formulas.CarryPrice(data.CarryCapacity)
		if not price then
			return false, "Você já carrega o máximo de ovos!"
		end
		if not Wallet.TrySpend(player, price) then
			return false, notEnough(price, data.Money)
		end
		data.CarryCapacity += 1
		Wallet.Refresh(player)
		SyncService.Push(player)
		return true, string.format("Agora você carrega %d ovos! 💪", data.CarryCapacity)
	elseif upgradeId == "Slots" then
		return BarnService.BuySlot(player)
	end

	return false, "Pedido inválido."
end

local function sellAnimal(player: Player, slotIndex: any): (boolean, string)
	if not RateLimit.Check(player, "SellAnimal", 0.25) then
		return false, "Calma! Tente de novo."
	end
	if not isSlotIndex(slotIndex) then
		return false, "Pedido inválido."
	end
	return BarnService.SellSlot(player, slotIndex)
end

local function levelUp(player: Player, slotIndex: any, amount: any): (boolean, string)
	if not isSlotIndex(slotIndex) or (amount ~= 1 and amount ~= 10) then
		return false, "Pedido inválido."
	end
	return BarnService.LevelUp(player, slotIndex, amount)
end

local function rebirth(player: Player): (boolean, string)
	if not RateLimit.Check(player, "Rebirth", 1) then
		return false, "Calma! Tente de novo."
	end
	local profile = DataService.Get(player)
	if not profile then
		return false, "Seus dados ainda estão carregando..."
	end
	local data = profile.Data
	local target = data.Rebirths + 1
	if target > GameConfig.Rebirth.MaxRebirths then
		return false, "Você já fez todos os rebirths!"
	end
	-- usa só a velocidade comprada (o Turbo não conta)
	local speed = Formulas.WalkSpeed(data.SpeedLevel)
	local required = Formulas.RebirthSpeed(target)
	if speed < required then
		return false, string.format("Você precisa de Velocidade %d (tem %d).", required, speed)
	end

	data.Rebirths = target
	data.SpeedLevel = 0
	MovementService.Apply(player)
	Wallet.Refresh(player)
	BarnService.Refresh(player)
	SyncService.Push(player)

	local multiplier = Formulas.IncomeMultiplier(target)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			NotifyService.Notify(other, string.format("%s fez o REBIRTH %d! 🔁", player.DisplayName, target), "info")
		end
	end
	return true, string.format("REBIRTH %d! Agora você ganha %sx dinheiro! 🔁", target, tostring(multiplier))
end

function ShopService.Init()
	Net.BuyUpgrade.OnServerInvoke = buyUpgrade
	Net.SellAnimal.OnServerInvoke = sellAnimal
	Net.LevelUp.OnServerInvoke = levelUp
	Net.Rebirth.OnServerInvoke = rebirth
end

return ShopService
