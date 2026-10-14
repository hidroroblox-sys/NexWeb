--!strict
--[[
	GamePassService: quem tem cada gamepass (VIP, Turbo...).
	  • os IDs ficam em GameConfig.GamePasses (0 = desativado)
	  • no Studio, com TestGamePassesInStudio = true, todo mundo "tem" os passes (para testar)
	  • o atributo "Pass_<Key>" no jogador avisa o cliente (ex.: portas VIP)
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Signal = require(ReplicatedStorage.Shared.Signal)

local GamePassService = {}

local owned: { [Player]: { [string]: boolean } } = {}

-- Dispara quando um jogador ganha um passe (compra durante o jogo)
GamePassService.Changed = Signal.new() :: Signal.Signal<Player, string>

local function set(player: Player, key: string, value: boolean)
	local list = owned[player]
	if not list then
		list = {}
		owned[player] = list
	end
	list[key] = value
	player:SetAttribute("Pass_" .. key, value)
end

function GamePassService.Owns(player: Player, key: string): boolean
	local list = owned[player]
	return list ~= nil and list[key] == true
end

function GamePassService.Setup(player: Player)
	local testing = RunService:IsStudio() and GameConfig.TestGamePassesInStudio
	for _, pass in GameConfig.GamePasses do
		local has = testing
		if not has and pass.Id ~= 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
			end)
			has = ok and result == true
		end
		set(player, pass.Key, has)
	end
end

function GamePassService.Init()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, pass in GameConfig.GamePasses do
			if pass.Id ~= 0 and pass.Id == passId then
				set(player, pass.Key, true)
				GamePassService.Changed:Fire(player, pass.Key)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
end

return GamePassService
