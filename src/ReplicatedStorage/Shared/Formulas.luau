--!strict
--[[
	Formulas: todas as contas da economia em um lugar só.
	O servidor usa para cobrar; o cliente usa só para MOSTRAR os preços.
]]

local GameConfig = require(script.Parent.GameConfig)

local Formulas = {}

-- ---------------------------------------------------------------------
-- Velocidade
-- ---------------------------------------------------------------------

-- Velocidade real (WalkSpeed) para um nível comprado. É o número do HUD.
function Formulas.WalkSpeed(level: number, boosted: boolean?): number
	local speed = GameConfig.Speed.BaseWalkSpeed + level * GameConfig.Speed.WalkSpeedPerLevel
	if boosted then
		speed += GameConfig.SpeedBoostAmount
	end
	return speed
end

local function packDiscount(amount: number): number
	for _, pack in GameConfig.Speed.Packs do
		if pack.Amount == amount then
			return pack.Discount
		end
	end
	return 1
end

function Formulas.IsSpeedPack(amount: number): boolean
	for _, pack in GameConfig.Speed.Packs do
		if pack.Amount == amount then
			return true
		end
	end
	return false
end

-- Preço para comprar "amount" níveis a partir de "level" (com o desconto do pacote).
-- Retorna (preço, quantos níveis realmente serão comprados).
function Formulas.SpeedPurchase(level: number, amount: number): (number, number)
	local config = GameConfig.Speed
	local levels = math.min(amount, config.MaxLevel - level)
	if levels <= 0 then
		return math.huge, 0
	end
	local growth = config.PriceGrowth
	-- soma de uma progressão geométrica: base * g^nível * (g^n - 1) / (g - 1)
	local sum = config.BasePrice * growth ^ level * (growth ^ levels - 1) / (growth - 1)
	local discount = if levels == amount then packDiscount(amount) else 1
	return math.floor(sum * discount), levels
end

-- ---------------------------------------------------------------------
-- Carregar / slots
-- ---------------------------------------------------------------------

function Formulas.CarryPrice(capacity: number): number?
	if capacity >= GameConfig.Carry.Max then
		return nil
	end
	return GameConfig.Carry.Prices[capacity - GameConfig.Carry.Start + 1]
end

function Formulas.SlotPrice(slots: number): number?
	if slots >= GameConfig.Barn.MaxSlots then
		return nil
	end
	return GameConfig.Barn.SlotPrices[slots - GameConfig.Barn.StartSlots + 1]
end

function Formulas.FloorOfSlot(slotIndex: number): number
	return math.ceil(slotIndex / GameConfig.Barn.SlotsPerFloor)
end

-- ---------------------------------------------------------------------
-- Rebirth
-- ---------------------------------------------------------------------

-- Multiplicador de dinheiro: 0 = 1x, 1 = 1,5x ... 20 = 11x, depois +0,25x
function Formulas.IncomeMultiplier(rebirths: number): number
	local config = GameConfig.Rebirth
	if rebirths <= 0 then
		return 1
	end
	if rebirths <= config.LateFrom then
		return 1 + config.MultiplierPerRebirth * rebirths
	end
	return 1 + config.MultiplierPerRebirth * config.LateFrom + config.LateMultiplierPerRebirth * (rebirths - config.LateFrom)
end

-- Velocidade exigida para fazer o rebirth número "target" (1, 2, 3...)
function Formulas.RebirthSpeed(target: number): number
	local config = GameConfig.Rebirth
	return config.SpeedBase + config.SpeedPerRebirth * target
end

-- ---------------------------------------------------------------------
-- Animais: mutação, nível e renda
-- ---------------------------------------------------------------------

function Formulas.MutationMultiplier(mutationId: string?): number
	if not mutationId then
		return 1
	end
	local mutation = GameConfig.MutationsById[mutationId]
	return if mutation then mutation.Multiplier else 1
end

function Formulas.LevelMultiplier(level: number): number
	return GameConfig.Level.IncomeMultiplier ^ (math.max(level, 1) - 1)
end

-- Renda por segundo de um animal com tudo: nível, mutação e rebirth
function Formulas.AnimalIncome(animalId: string, rebirths: number, level: number?, mutationId: string?): number
	local animal = GameConfig.AnimalsById[animalId]
	if not animal then
		return 0
	end
	return animal.Income
		* Formulas.LevelMultiplier(level or 1)
		* Formulas.MutationMultiplier(mutationId)
		* Formulas.IncomeMultiplier(rebirths)
end

-- Preço para subir "amount" níveis a partir de "level"
function Formulas.LevelUpCost(animalId: string, level: number, amount: number): (number, number)
	local animal = GameConfig.AnimalsById[animalId]
	local config = GameConfig.Level
	local levels = math.min(amount, config.MaxLevel - level)
	if not animal or levels <= 0 then
		return math.huge, 0
	end
	local base = math.min(animal.Income, config.BaseCostCap)
	local growth = config.CostGrowth
	local sum = base * growth ^ (level - 1) * (growth ^ levels - 1) / (growth - 1)
	return math.floor(sum), levels
end

-- Quanto o jogador recebe ao vender o animal
function Formulas.SellPrice(animalId: string, mutationId: string?): number
	local animal = GameConfig.AnimalsById[animalId]
	if not animal then
		return 0
	end
	return math.floor(animal.Income * GameConfig.Sell.IncomeSeconds * Formulas.MutationMultiplier(mutationId))
end

return Formulas
