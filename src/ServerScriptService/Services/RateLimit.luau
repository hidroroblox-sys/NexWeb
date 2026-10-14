--!strict
-- RateLimit: impede que um cliente (ou exploiter) chame algo rápido demais.

local Players = game:GetService("Players")

local RateLimit = {}

local lastCall: { [Player]: { [string]: number } } = {}

-- Retorna true se pode executar agora (e registra a chamada)
function RateLimit.Check(player: Player, key: string, cooldown: number): boolean
	local now = os.clock()
	local calls = lastCall[player]
	if not calls then
		calls = {}
		lastCall[player] = calls
	end
	local last = calls[key]
	if last and now - last < cooldown then
		return false
	end
	calls[key] = now
	return true
end

Players.PlayerRemoving:Connect(function(player)
	lastCall[player] = nil
end)

return RateLimit
