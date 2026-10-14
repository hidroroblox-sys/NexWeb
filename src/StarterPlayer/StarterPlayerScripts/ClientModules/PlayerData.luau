--!strict
-- PlayerData (cliente): guarda o último "retrato" dos dados enviado pelo servidor.
-- O cliente só LÊ e MOSTRA; quem decide tudo é o servidor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

local PlayerData = {}

local snapshot: Types.Snapshot? = nil

PlayerData.Changed = Signal.new() :: Signal.Signal<Types.Snapshot>

function PlayerData.Get(): Types.Snapshot?
	return snapshot
end

function PlayerData.IsDiscovered(animalId: string): boolean
	return snapshot ~= nil and snapshot.Index[animalId] == true
end

function PlayerData.Start()
	Net.DataSync.OnClientEvent:Connect(function(data: Types.Snapshot)
		snapshot = data
		PlayerData.Changed:Fire(data)
	end)
	Net.RequestSync:FireServer()
end

return PlayerData
