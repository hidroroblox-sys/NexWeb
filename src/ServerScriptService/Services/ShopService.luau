--!strict
--[[
	ShopService: compras e vendas (sempre validadas no servidor).
	  BuyUpgrade("Speed", 1 | 10)   -> +1 / +10 níveis de velocidade
	  BuyUpgrade("Carry", 1)        -> carregar +1 ovo (até 7)
	  BuyUpgrade("Slots", 1)        -> +1 slot no celeiro
	  SellAnimal(slot)              -> vende o animal daquele slot
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BarnService = require(script.Parent.BarnService)
local DataService = require(script.Parent.DataService)
local MovementService = require(script.Parent.MovementService)
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
		if amount ~= 1 and amount ~= 10 then
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
		return true, string.format("Velocidade %d! 👟", data.SpeedLevel)
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
		return true, string.format("Agora você carrega %d ovos! 🥚", data.CarryCapacity)
	elseif upgradeId == "Slots" then
		local price = Formulas.SlotPrice(data.BarnSlots)
		if not price then
			return false, "Seu celeiro já está no tamanho máximo!"
		end
		if not Wallet.TrySpend(player, price) then
			return false, notEnough(price, data.Money)
		end
		data.BarnSlots += 1
		Wallet.Refresh(player)
		BarnService.Refresh(player)
		SyncService.Push(player)
		return true, string.format("Celeiro com %d slots! 🏠", data.BarnSlots)
	end

	return false, "Pedido inválido."
end

local function sellAnimal(player: Player, slotIndex: any): (boolean, string)
	if not RateLimit.Check(player, "SellAnimal", 0.25) then
		return false, "Calma! Tente de novo."
	end
	if
		typeof(slotIndex) ~= "number"
		or slotIndex ~= math.floor(slotIndex)
		or slotIndex < 1
		or slotIndex > GameConfig.Barn.MaxSlots
	then
		return false, "Pedido inválido."
	end
	return BarnService.SellSlot(player, slotIndex)
end

function ShopService.Init()
	Net.BuyUpgrade.OnServerInvoke = buyUpgrade
	Net.SellAnimal.OnServerInvoke = sellAnimal
end

return ShopService
