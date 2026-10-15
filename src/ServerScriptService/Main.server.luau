--!strict
--[[
	Main (servidor): liga todos os sistemas na ordem certa e cuida
	da entrada/saída/renascimento dos jogadores.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script.Parent:WaitForChild("Services")
local BarnService = require(Services.BarnService)
local BatService = require(Services.BatService)
local CarryService = require(Services.CarryService)
local DataService = require(Services.DataService)
local EggService = require(Services.EggService)
local GamePassService = require(Services.GamePassService)
local IncomeTag = require(Services.IncomeTag)
local MapBuilder = require(Services.MapBuilder)
local MovementService = require(Services.MovementService)
local NotifyService = require(Services.NotifyService)
local RateLimit = require(Services.RateLimit)
local ShopService = require(Services.ShopService)
local SyncService = require(Services.SyncService)
local TsunamiService = require(Services.TsunamiService)
local Wallet = require(Services.Wallet)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)

-- O servidor controla quando o personagem nasce (depois de carregar os dados)
Players.CharacterAutoLoads = false

MapBuilder.Build()
DataService.Init()
GamePassService.Init()
SyncService.Init()
BarnService.Init()
EggService.Init()
TsunamiService.Init()
MovementService.Init()
ShopService.Init()

-- Comprou o Turbo durante o jogo: aplica na hora
GamePassService.Changed:Connect(function(player)
	MovementService.Apply(player)
end)

local function spawnCharacter(player: Player)
	if player.Parent ~= nil and DataService.Get(player) then
		local ok, err = pcall(function()
			player:LoadCharacterAsync()
		end)
		if not ok then
			-- Studio antigo sem LoadCharacterAsync: usa o método clássico
			warn("[Main] LoadCharacterAsync falhou (" .. tostring(err) .. "), tentando LoadCharacter")
			pcall(function()
				(player :: any):LoadCharacter()
			end)
		end
	end
end

local function onCharacterAdded(player: Player, character: Model)
	MovementService.Reset(player)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	MovementService.Apply(player)
	BatService.Give(player)
	task.spawn(IncomeTag.Attach, player, character)

	-- Garante que nasce dentro do próprio cercado
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local spawnCFrame = BarnService.GetSpawnCFrame(player)
	if root and spawnCFrame then
		character:PivotTo(spawnCFrame)
	end

	humanoid.Died:Once(function()
		-- Os ovos carregados caem no chão onde você morreu (qualquer um pode pegar)
		local items = CarryService.TakeAll(player)
		local deathRoot = character:FindFirstChild("HumanoidRootPart")
		if #items > 0 and deathRoot and deathRoot:IsA("BasePart") then
			EggService.DropItems(items, deathRoot.Position)
			NotifyService.Notify(player, string.format("Você deixou cair %d ovo(s)! Corra para pegar de volta!", #items), "danger")
		end
		task.delay(GameConfig.Players.RespawnTime, spawnCharacter, player)
	end)
end

-- Botão "Soltar": larga no chão todos os ovos que está carregando
Net.DropCarried.OnServerEvent:Connect(function(player)
	if not RateLimit.Check(player, "DropCarried", 0.5) or CarryService.Count(player) == 0 then
		return
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end
	local items = CarryService.TakeAll(player)
	EggService.DropItems(items, root.Position + root.CFrame.LookVector * 4)
	NotifyService.Notify(player, string.format("Você soltou %d ovo(s).", #items), "info")
end)

local function onPlayerAdded(player: Player)
	if #Players:GetPlayers() > GameConfig.Players.MaxPlayers then
		player:Kick("Servidor cheio! Tente outro servidor.")
		return
	end

	local profile = DataService.Load(player)
	if not profile or player.Parent == nil then
		return
	end

	GamePassService.Setup(player)
	Wallet.Setup(player)
	CarryService.Setup(player)

	if not BarnService.Assign(player) then
		player:Kick("Não há cercados livres neste servidor. Tente outro!")
		return
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	SyncService.Push(player)
	spawnCharacter(player)
end

local function onPlayerRemoving(player: Player)
	CarryService.Remove(player)
	BarnService.Release(player)
	DataService.Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
