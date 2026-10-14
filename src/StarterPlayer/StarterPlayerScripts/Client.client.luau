--!strict
--[[
	Client: liga a interface e os efeitos do jogador.
	O cliente só MOSTRA e PEDE coisas; o servidor decide tudo.
]]

local modules = script.Parent:WaitForChild("ClientModules")

local PlayerData = require(modules:WaitForChild("PlayerData"))
local HUD = require(modules:WaitForChild("UI"):WaitForChild("HUD"))
local WaveRenderer = require(modules:WaitForChild("World"):WaitForChild("WaveRenderer"))
local WorldFx = require(modules:WaitForChild("World"):WaitForChild("WorldFx"))

-- Primeiro a interface (para ela escutar os dados), depois pede os dados
WaveRenderer.Start()
HUD.Start()
WorldFx.Start()
PlayerData.Start()
