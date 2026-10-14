--!strict
-- Net: acesso aos RemoteEvents/RemoteFunctions (pasta ReplicatedStorage.Remotes).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local Net = {
	-- Servidor -> Cliente
	Notify = remotes:WaitForChild("Notify") :: RemoteEvent, -- pop-up de mensagem
	Effect = remotes:WaitForChild("Effect") :: RemoteEvent, -- efeitos visuais/sons
	DataSync = remotes:WaitForChild("DataSync") :: RemoteEvent, -- dados do celeiro/índice

	-- Cliente -> Servidor (sempre validados no servidor!)
	RequestSync = remotes:WaitForChild("RequestSync") :: RemoteEvent,
	BuyUpgrade = remotes:WaitForChild("BuyUpgrade") :: RemoteFunction,
	SellAnimal = remotes:WaitForChild("SellAnimal") :: RemoteFunction,
}

return Net
