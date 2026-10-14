--!strict
--[[
	DataService
	-----------
	Carrega e salva o progresso do jogador no DataStore.
	  • pcall + várias tentativas (retry) com espera crescente
	  • salvamento automático, ao sair e ao fechar o servidor (BindToClose)
	  • dados carregados passam por uma "limpeza" (sanitize) para nunca quebrar o jogo
	  • no Studio sem acesso à API: o jogo funciona, mas NÃO salva (aviso no Output)
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

export type SlotData = {
	EggId: string,
	AnimalId: string,
	HatchAt: number, -- os.time() em que vai chocar (continua contando offline)
	HatchDuration: number,
	Hatched: boolean,
	Stored: number, -- dinheiro acumulado no coletor deste slot
}

export type Stats = {
	EggsCollected: number,
	EggsHatched: number,
	Deaths: number,
}

export type PlayerData = {
	Version: number,
	Money: number,
	SpeedLevel: number,
	Rebirths: number,
	CarryCapacity: number,
	BarnSlots: number,
	Slots: { [string]: SlotData }, -- chave = número do slot em texto ("1", "2"...)
	Index: { [string]: boolean }, -- animais já chocados
	Stats: Stats,
}

export type Profile = {
	Data: PlayerData,
	CanSave: boolean,
	Saving: boolean,
}

local DATA_VERSION = 1
local CONFIG = GameConfig.Data

local DataService = {}

local profiles: { [Player]: Profile } = {}
local pendingReleases = 0
local store: DataStore? = nil

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(CONFIG.StoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore indisponível:", result)
	end
end

local function defaultData(): PlayerData
	return {
		Version = DATA_VERSION,
		Money = 0,
		SpeedLevel = 0,
		Rebirths = 0,
		CarryCapacity = GameConfig.Carry.Start,
		BarnSlots = GameConfig.Barn.StartSlots,
		Slots = {},
		Index = {},
		Stats = { EggsCollected = 0, EggsHatched = 0, Deaths = 0 },
	}
end

-- Número válido (não NaN, não infinito) ou o padrão
local function number(value: any, default: number): number
	if typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
		return value
	end
	return default
end

-- Garante que os dados carregados têm o formato certo
local function sanitize(raw: any): PlayerData
	local data = defaultData()
	if typeof(raw) ~= "table" then
		return data
	end

	data.Money = math.max(0, number(raw.Money, 0))
	data.SpeedLevel = math.clamp(math.floor(number(raw.SpeedLevel, 0)), 0, GameConfig.Speed.MaxLevel)
	data.Rebirths = math.max(0, math.floor(number(raw.Rebirths, 0)))
	data.CarryCapacity = math.clamp(
		math.floor(number(raw.CarryCapacity, GameConfig.Carry.Start)),
		GameConfig.Carry.Start,
		GameConfig.Carry.Max
	)
	data.BarnSlots = math.clamp(
		math.floor(number(raw.BarnSlots, GameConfig.Barn.StartSlots)),
		GameConfig.Barn.StartSlots,
		GameConfig.Barn.MaxSlots
	)

	if typeof(raw.Slots) == "table" then
		for key, slot in raw.Slots do
			local index = tonumber(key)
			if
				index
				and index == math.floor(index)
				and index >= 1
				and index <= data.BarnSlots
				and typeof(slot) == "table"
				and typeof(slot.EggId) == "string"
				and typeof(slot.AnimalId) == "string"
				and GameConfig.EggsById[slot.EggId]
				and GameConfig.AnimalsById[slot.AnimalId]
			then
				data.Slots[tostring(index)] = {
					EggId = slot.EggId,
					AnimalId = slot.AnimalId,
					HatchAt = number(slot.HatchAt, 0),
					HatchDuration = math.max(1, number(slot.HatchDuration, 60)),
					Hatched = slot.Hatched == true,
					Stored = math.max(0, number(slot.Stored, 0)),
				}
			end
		end
	end

	if typeof(raw.Index) == "table" then
		for animalId, discovered in raw.Index do
			if typeof(animalId) == "string" and discovered == true and GameConfig.AnimalsById[animalId] then
				data.Index[animalId] = true
			end
		end
	end

	if typeof(raw.Stats) == "table" then
		data.Stats.EggsCollected = math.max(0, number(raw.Stats.EggsCollected, 0))
		data.Stats.EggsHatched = math.max(0, number(raw.Stats.EggsHatched, 0))
		data.Stats.Deaths = math.max(0, number(raw.Stats.Deaths, 0))
	end

	return data
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

-- Carrega os dados (pode demorar alguns segundos). Retorna nil se o jogador saiu
-- ou foi expulso por erro de carregamento.
function DataService.Load(player: Player): Profile?
	local raw: any = nil
	local loaded = false

	local dataStore = store
	if dataStore then
		for attempt = 1, CONFIG.MaxRetries do
			local ok, result = pcall(function()
				return dataStore:GetAsync(keyFor(player))
			end)
			if ok then
				raw = result
				loaded = true
				break
			end
			warn(string.format("[DataService] Falha ao carregar %s (tentativa %d): %s", player.Name, attempt, tostring(result)))
			if player.Parent == nil then
				return nil
			end
			task.wait(CONFIG.RetryBaseDelay * 2 ^ (attempt - 1))
		end
	end

	if player.Parent == nil then
		return nil
	end

	if not loaded then
		if RunService:IsStudio() then
			warn(
				"[DataService] Studio sem DataStore: usando dados novos SEM SALVAR. "
					.. "Para salvar no Studio: Game Settings > Security > Enable Studio Access to API Services."
			)
		else
			player:Kick("Não conseguimos carregar seus dados. Entre de novo em alguns instantes!")
			return nil
		end
	end

	local profile: Profile = {
		Data = sanitize(raw),
		CanSave = loaded,
		Saving = false,
	}
	profiles[player] = profile
	return profile
end

function DataService.Get(player: Player): Profile?
	return profiles[player]
end

-- Salva (com retry). Espera se outro salvamento do mesmo jogador estiver rodando.
local function save(player: Player, profile: Profile): boolean
	local dataStore = store
	if not profile.CanSave or not dataStore then
		return false
	end
	while profile.Saving do
		task.wait(0.1)
	end
	profile.Saving = true
	local success = false
	for attempt = 1, CONFIG.MaxRetries do
		local ok, err = pcall(function()
			dataStore:UpdateAsync(keyFor(player), function(_old: any)
				return profile.Data
			end)
		end)
		if ok then
			success = true
			break
		end
		warn(string.format("[DataService] Falha ao salvar %s (tentativa %d): %s", player.Name, attempt, tostring(err)))
		task.wait(CONFIG.RetryBaseDelay * 2 ^ (attempt - 1))
	end
	profile.Saving = false
	return success
end

function DataService.Save(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	return save(player, profile)
end

-- Chamado quando o jogador sai: salva e libera
function DataService.Release(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	pendingReleases += 1
	save(player, profile)
	profiles[player] = nil
	pendingReleases -= 1
end

function DataService.Init()
	-- Salvamento automático
	task.spawn(function()
		while true do
			task.wait(CONFIG.AutoSaveInterval)
			for player, profile in profiles do
				task.spawn(save, player, profile)
			end
		end
	end)

	-- Servidor fechando: salva todo mundo e espera terminar (máx. ~25 s)
	game:BindToClose(function()
		for player in profiles do
			task.spawn(DataService.Release, player)
		end
		local deadline = os.clock() + 25
		while (pendingReleases > 0 or next(profiles) ~= nil) and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
