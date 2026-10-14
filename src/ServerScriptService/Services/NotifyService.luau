--!strict
-- NotifyService: manda pop-ups e efeitos para os clientes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)

local NotifyService = {}

-- kind: "info" | "success" | "warning" | "danger" | "rarity"
function NotifyService.Notify(player: Player, text: string, kind: string?, color: Color3?)
	local payload: Types.NotifyPayload = {
		Text = text,
		Kind = kind or "info",
		Color = color,
	}
	Net.Notify:FireClient(player, payload)
end

-- Efeito só para um jogador
function NotifyService.Effect(player: Player, name: string, data: { [string]: any }?)
	Net.Effect:FireClient(player, name, data or {})
end

-- Efeito para todos (ex.: ovo chocando — quem estiver perto vê)
function NotifyService.EffectAll(name: string, data: { [string]: any }?)
	Net.Effect:FireAllClients(name, data or {})
end

return NotifyService
