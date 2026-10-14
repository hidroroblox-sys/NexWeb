--!strict
--[[
	Formulas: todas as contas da economia em um lugar só.
	O servidor usa para cobrar; o cliente usa só para MOSTRAR os preços.
]]

local GameConfig = require(script.Parent.GameConfig)

local Formulas = {}

-- WalkSpeed real do personagem para um nível de velocidade
function Formulas.WalkSpeed(level: number): number
	return GameConfig.Speed.BaseWalkSpeed + level * GameConfig.Speed.WalkSpeedPerLevel
end

-- Preço para comprar "amount" níveis a partir de "level".
-- Retorna (preço, quantos níveis realmente serão comprados).
function Formulas.SpeedPurchase(level: number, amount: number): (number, number)
	local config = GameConfig.Speed
	local levels = math.min(amount, config.MaxLevel - level)
	if levels <= 0 then
		return math.huge, 0
	end
	local growth = config.PriceGrowth
	-- soma de uma progressão geométrica: base * g^nível * (g^n - 1) / (g - 1)
	local price = config.BasePrice * growth ^ level * (growth ^ levels - 1) / (growth - 1)
	return math.floor(price), levels
end

-- Preço para carregar +1 ovo (nil = já está no máximo)
function Formulas.CarryPrice(capacity: number): number?
	if capacity >= GameConfig.Carry.Max then
		return nil
	end
	return GameConfig.Carry.Prices[capacity - GameConfig.Carry.Start + 1]
end

-- Preço do próximo slot do celeiro (nil = já está no máximo)
function Formulas.SlotPrice(slots: number): number?
	if slots >= GameConfig.Barn.MaxSlots then
		return nil
	end
	return GameConfig.Barn.SlotPrices[slots - GameConfig.Barn.StartSlots + 1]
end

-- Multiplicador de dinheiro pelos rebirths (0 = 1x, 1 = 1.5x, 2 = 2x...)
function Formulas.IncomeMultiplier(rebirths: number): number
	if rebirths <= 0 then
		return 1
	end
	local config = GameConfig.Rebirth
	return config.FirstMultiplier + config.MultiplierPerRebirth * (rebirths - 1)
end

-- Renda por segundo de um animal já com o multiplicador
function Formulas.AnimalIncome(animalId: string, rebirths: number): number
	local animal = GameConfig.AnimalsById[animalId]
	if not animal then
		return 0
	end
	return animal.Income * Formulas.IncomeMultiplier(rebirths)
end

-- Quanto o jogador recebe ao vender o animal
function Formulas.SellPrice(animalId: string): number
	local animal = GameConfig.AnimalsById[animalId]
	if not animal then
		return 0
	end
	return math.floor(animal.Income * GameConfig.Sell.IncomeSeconds)
end

return Formulas
