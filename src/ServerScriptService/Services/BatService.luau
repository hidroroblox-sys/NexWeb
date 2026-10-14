--!strict
--[[
	BatService: o TACO que todo jogador recebe (como no original).
	  • uma tacada em alguém no corredor faz a vítima DERRUBAR os ovos que carrega
	    e cair no chão por alguns segundos
	  • na área segura (bases + zona segura) a tacada não faz nada
	  • tudo validado no servidor: distância, direção e tempo entre tacadas
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryService = require(script.Parent.CarryService)
local EggService = require(script.Parent.EggService)
local NotifyService = require(script.Parent.NotifyService)
local RateLimit = require(script.Parent.RateLimit)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)

local BatService = {}

local CONFIG = GameConfig.Bat
local GRIP = CFrame.new(0, -1.4, 0)
local SWING_GRIP = CFrame.new(0, -1.4, 0) * CFrame.Angles(math.rad(-100), 0, 0)

local function getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function hit(attacker: Player, target: Player, targetRoot: BasePart, direction: Vector3)
	local items = CarryService.TakeAll(target)
	if #items > 0 then
		EggService.DropItems(items, targetRoot.Position)
		NotifyService.Notify(target, string.format("%s te deu uma tacada! Você derrubou %d ovo(s)!", attacker.DisplayName, #items), "danger")
		NotifyService.Notify(attacker, string.format("Tacada! %s derrubou %d ovo(s)!", target.DisplayName, #items), "success")
	end
	-- o empurrão e a queda são feitos no cliente da vítima (dono da física do personagem)
	NotifyService.Effect(target, "Knockback", { Direction = direction, Time = CONFIG.RagdollTime, Force = CONFIG.Knockback })
end

local function swing(player: Player, tool: Tool)
	if not RateLimit.Check(player, "Bat", CONFIG.Cooldown) then
		return
	end
	local root = getRoot(player)
	if not root or tool.Parent ~= player.Character then
		return
	end

	-- animação simples: gira o taco na mão
	tool.Grip = SWING_GRIP
	task.delay(0.25, function()
		tool.Grip = GRIP
	end)
	local handle = tool:FindFirstChild("Handle")
	local sound = if handle then handle:FindFirstChild("Swing") else nil
	if sound and sound:IsA("Sound") then
		sound:Play()
	end

	local look = root.CFrame.LookVector
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local otherRoot = getRoot(other)
			if otherRoot and not MapLayout.IsSafeZ(otherRoot.Position.Z) then
				local offset = otherRoot.Position - root.Position
				local distance = offset.Magnitude
				if distance <= CONFIG.Range and distance > 0.01 and look:Dot(offset.Unit) > 0.2 then
					hit(player, other, otherRoot, Vector3.new(offset.X, 0, offset.Z).Unit)
				end
			end
		end
	end
end

local function createBat(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Taco"
	tool.ToolTip = "Dê uma tacada para derrubar os ovos de quem estiver no corredor!"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.Grip = GRIP

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.7, 4.2, 0.7)
	handle.Color = Color3.fromRGB(185, 125, 65)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local tip = Instance.new("Part")
	tip.Name = "Ponta"
	tip.Shape = Enum.PartType.Ball
	tip.Size = Vector3.new(1.1, 1.1, 1.1)
	tip.Color = Color3.fromRGB(165, 105, 50)
	tip.Material = Enum.Material.Wood
	tip.CanCollide = false
	tip.Massless = true
	tip.CFrame = handle.CFrame * CFrame.new(0, 2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = tip
	weld.Parent = tip
	tip.Parent = tool

	local sound = Instance.new("Sound")
	sound.Name = "Swing"
	sound.SoundId = GameConfig.Sounds.Bat
	sound.Volume = 0.6
	sound.Parent = handle
	return tool
end

-- Entrega o taco (chamar a cada vez que o personagem nasce)
function BatService.Give(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	if backpack:FindFirstChild("Taco") then
		return
	end
	local character = player.Character
	if character and character:FindFirstChild("Taco") then
		return
	end
	local tool = createBat()
	tool.Activated:Connect(function()
		swing(player, tool)
	end)
	tool.Parent = backpack
end

return BatService
