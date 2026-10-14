--!strict
-- SyncService: manda para o cliente um "retrato" dos dados (slots, índice, upgrades).
-- Várias mudanças no mesmo frame viram um envio só.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local RateLimit = require(script.Parent.RateLimit)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)

local SyncService = {}

local pending: { [Player]: boolean } = {}

function SyncService.BuildSnapshot(data: DataService.PlayerData): Types.Snapshot
	local slots: { Types.SlotSnapshot } = {}
	for key, slot in data.Slots do
		table.insert(slots, {
			Index = tonumber(key) or 0,
			EggId = slot.EggId,
			AnimalId = slot.AnimalId,
			HatchAt = slot.HatchAt,
			HatchDuration = slot.HatchDuration,
			Hatched = slot.Hatched,
		})
	end
	table.sort(slots, function(a, b)
		return a.Index < b.Index
	end)
	return {
		Slots = slots,
		Index = table.clone(data.Index),
		BarnSlots = data.BarnSlots,
		CarryCapacity = data.CarryCapacity,
		SpeedLevel = data.SpeedLevel,
		Rebirths = data.Rebirths,
	}
end

function SyncService.Push(player: Player)
	if pending[player] then
		return
	end
	pending[player] = true
	task.defer(function()
		pending[player] = nil
		if player.Parent == nil then
			return
		end
		local profile = DataService.Get(player)
		if profile then
			Net.DataSync:FireClient(player, SyncService.BuildSnapshot(profile.Data))
		end
	end)
end

function SyncService.Init()
	-- O cliente pede os dados quando o script dele termina de carregar
	Net.RequestSync.OnServerEvent:Connect(function(player)
		if RateLimit.Check(player, "RequestSync", 1) then
			SyncService.Push(player)
		end
	end)
end

return SyncService
