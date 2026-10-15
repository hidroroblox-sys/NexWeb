--!strict
--[[
	WorldFx: efeitos e textos do mundo calculados no cliente.
	  • contagem "Choca em 2:30" + barra em cima dos ovos do cercado
	  • "$/s" dos ovos do corredor (ou "???" se o animal não está no seu índice)
	  • animação de "respirar/balançar" dos animais
	  • efeitos: ovo chocando, coletar dinheiro, pegar ovo, levado pela onda
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Sounds = require(script.Parent.Parent.Sounds)
local Theme = require(script.Parent.Parent.UI.Theme)
local UIKit = require(script.Parent.Parent.UI.UIKit)
local HUD = require(script.Parent.Parent.UI.HUD)

local WorldFx = {}

type IdleEntry = { Base: CFrame, Phase: number }

local idleAnimals: { [Model]: IdleEntry } = {}
local flashFrame: Frame

-- ---------------------------------------------------------------------
-- Textos dos billboards
-- ---------------------------------------------------------------------

local function updateHatchTimer(gui: Instance, now: number)
	local hatchAt = gui:GetAttribute("HatchAt")
	local duration = gui:GetAttribute("HatchDuration")
	if typeof(hatchAt) ~= "number" or typeof(duration) ~= "number" then
		return
	end
	local remaining = hatchAt - now
	local bar = gui:FindFirstChild("Bar")
	if not bar then
		return
	end
	local fill = bar:FindFirstChild("Fill")
	local timer = bar:FindFirstChild("Timer")
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.fromScale(math.clamp(1 - remaining / math.max(duration, 1), 0, 1), 1)
	end
	if timer and timer:IsA("TextLabel") then
		timer.Text = if remaining > 0 then "Choca em " .. Format.Time(remaining) else "Chocando..."
	end
end

local function updateEggIncome(label: Instance)
	if not label:IsA("TextLabel") then
		return
	end
	local animalId = label:GetAttribute("AnimalId")
	if typeof(animalId) ~= "string" then
		return
	end
	local animal = GameConfig.AnimalsById[animalId]
	if animal and PlayerData.IsDiscovered(animalId) then
		local snapshot = PlayerData.Get()
		local rebirths = if snapshot then snapshot.Rebirths else 0
		local mutation = label:GetAttribute("Mutation")
		local mutationId = if typeof(mutation) == "string" then mutation else nil
		label.Text = Format.PerSecond(Formulas.AnimalIncome(animalId, rebirths, 1, mutationId))
	else
		label.Text = "???"
	end
end

local function refreshAllEggIncome()
	for _, label in CollectionService:GetTagged("EggIncomeLabel") do
		updateEggIncome(label)
	end
end

-- ---------------------------------------------------------------------
-- Animação dos animais
-- ---------------------------------------------------------------------

local function addIdle(instance: Instance)
	if instance:IsA("Model") then
		idleAnimals[instance] = { Base = instance:GetPivot(), Phase = math.random() * math.pi * 2 }
	end
end

local function removeIdle(instance: Instance)
	if instance:IsA("Model") then
		idleAnimals[instance] = nil
	end
end

-- ---------------------------------------------------------------------
-- Efeitos
-- ---------------------------------------------------------------------

local function burst(position: Vector3, color: Color3, amount: number, size: number)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = position
	anchor.Parent = Workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission = 0.6
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(0.5, 1.1)
	emitter.Speed = NumberRange.new(10, 22)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = anchor
	emitter:Emit(amount)

	-- bolha brilhante que cresce e some
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Shape = Enum.PartType.Ball
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.3
	ring.Size = Vector3.new(1, 1, 1)
	ring.Position = position
	ring.Parent = Workspace
	UIKit.Tween(ring, 0.45, { Size = Vector3.new(1, 1, 1) * size * 5, Transparency = 1 })

	task.delay(2, function()
		anchor:Destroy()
		ring:Destroy()
	end)
end

local function floatingText(position: Vector3, text: string, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = position + Vector3.new(0, 2, 0)
	anchor.Parent = Workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(6, 2)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor
	local label = UIKit.Label(gui, {
		Text = text,
		Font = Theme.Fonts.Title,
		Color = color,
		MaxTextSize = 60,
		Stroke = 3,
	})
	UIKit.Tween(gui, 0.9, { StudsOffset = Vector3.new(0, 4, 0) })
	task.delay(0.5, function()
		UIKit.Tween(label, 0.4, { TextTransparency = 1 })
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			UIKit.Tween(stroke, 0.4, { Transparency = 1 })
		end
	end)
	task.delay(1, function()
		anchor:Destroy()
	end)
end

local function flash(color: Color3)
	flashFrame.BackgroundColor3 = color
	flashFrame.BackgroundTransparency = 0.2
	flashFrame.Visible = true
	local tween = UIKit.Tween(flashFrame, 0.9, { BackgroundTransparency = 1 })
	tween.Completed:Once(function()
		flashFrame.Visible = false
	end)
end

local function onEffect(name: string, data: { [string]: any })
	if typeof(data) ~= "table" then
		return
	end
	if name == "Hatch" then
		local position = data.Position
		local color = data.Color
		if typeof(position) == "Vector3" and typeof(color) == "Color3" then
			local order = if typeof(data.Order) == "number" then data.Order else 1
			burst(position, color, 30 + order * 8, 1 + order * 0.15)
			local character = Players.LocalPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if root and root:IsA("BasePart") and (root.Position - position).Magnitude < 80 then
				Sounds.Play("Hatch", 0.9 + order * 0.05, 0.7)
			end
		end
	elseif name == "Collect" then
		local position = data.Position
		local amount = data.Amount
		if typeof(position) == "Vector3" and typeof(amount) == "number" then
			floatingText(position, "+" .. Format.Money(amount), Theme.Colors.Money)
			Sounds.Play("Collect", 1.5, 0.35)
		end
	elseif name == "Pickup" then
		local position = data.Position
		local color = data.Color
		if typeof(position) == "Vector3" and typeof(color) == "Color3" then
			burst(position, color, 18, 0.8)
		end
	elseif name == "WaveHit" then
		flash(Color3.fromRGB(40, 130, 230))
		Sounds.Play("WaveHit", 1, 0.8)
	elseif name == "Knockback" then
		-- levou uma tacada: cai e é empurrado (o cliente é dono da física do personagem)
		local direction = data.Direction
		local duration = if typeof(data.Time) == "number" then math.clamp(data.Time, 0.5, 4) else 2.5
		local force = if typeof(data.Force) == "number" then math.clamp(data.Force, 0, 100) else 40
		local character = Players.LocalPlayer.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if humanoid and root and root:IsA("BasePart") and typeof(direction) == "Vector3" then
			flash(Color3.fromRGB(255, 200, 60))
			Sounds.Play("Bat", 1, 0.8)
			humanoid.PlatformStand = true
			root.AssemblyLinearVelocity = direction * force + Vector3.new(0, force * 0.6, 0)
			task.delay(duration, function()
				if humanoid.Parent then
					humanoid.PlatformStand = false
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end
	end
end

-- ---------------------------------------------------------------------

function WorldFx.Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "Efeitos"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = playerGui
	flashFrame = UIKit.Frame(gui, "Flash", UDim2.fromScale(1, 1), nil, Color3.new(0, 0, 1))
	flashFrame.Visible = false
	flashFrame.BackgroundTransparency = 1

	-- Billboards de ovos do corredor
	CollectionService:GetInstanceAddedSignal("EggIncomeLabel"):Connect(updateEggIncome)
	PlayerData.Changed:Connect(refreshAllEggIncome)
	refreshAllEggIncome()

	-- Animais
	CollectionService:GetInstanceAddedSignal("IdleAnimal"):Connect(addIdle)
	CollectionService:GetInstanceRemovedSignal("IdleAnimal"):Connect(removeIdle)
	for _, instance in CollectionService:GetTagged("IdleAnimal") do
		addIdle(instance)
	end

	-- Contagem dos ovos chocando (4x por segundo)
	task.spawn(function()
		while true do
			local now = Workspace:GetServerTimeNow()
			for _, gui in CollectionService:GetTagged("HatchTimer") do
				updateHatchTimer(gui, now)
			end
			task.wait(0.25)
		end
	end)

	-- Balanço dos animais perto da câmera
	RunService.RenderStepped:Connect(function()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local cameraPosition = camera.CFrame.Position
		local t = os.clock()
		for model, entry in idleAnimals do
			if model.Parent == nil then
				idleAnimals[model] = nil
			elseif (entry.Base.Position - cameraPosition).Magnitude < 160 then
				local bob = math.sin(t * 2.2 + entry.Phase) * 0.25
				local sway = math.sin(t * 1.3 + entry.Phase) * 0.18
				model:PivotTo(entry.Base * CFrame.new(0, bob + 0.25, 0) * CFrame.Angles(0, sway, 0))
			end
		end
	end)

	Net.Effect.OnClientEvent:Connect(onEffect)

	local localPlayer = Players.LocalPlayer

	-- Portas VIP: quem tem VIP atravessa (só no próprio cliente; o servidor confere)
	local function updateDoor(door: Instance)
		if door:IsA("BasePart") then
			door.CanCollide = localPlayer:GetAttribute("Pass_VIP") ~= true
		end
	end
	local function updateAllDoors()
		for _, door in CollectionService:GetTagged("VipDoor") do
			updateDoor(door)
		end
	end
	CollectionService:GetInstanceAddedSignal("VipDoor"):Connect(updateDoor)
	localPlayer:GetAttributeChangedSignal("Pass_VIP"):Connect(updateAllDoors)
	updateAllDoors()

	-- Botões de cercado (subir nível, comprar slot) só aparecem para o dono
	local function updatePrompt(prompt: Instance)
		if not prompt:IsA("ProximityPrompt") then
			return
		end
		local function apply()
			prompt.Enabled = prompt:GetAttribute("OwnerUserId") == localPlayer.UserId
		end
		prompt:GetAttributeChangedSignal("OwnerUserId"):Connect(apply)
		apply()
	end
	CollectionService:GetInstanceAddedSignal("OwnerPrompt"):Connect(updatePrompt)
	for _, prompt in CollectionService:GetTagged("OwnerPrompt") do
		updatePrompt(prompt)
	end

	-- Anel ciano: pisou dentro = abre os UPGRADES; saiu = fecha
	local ringCenter = GameConfig.Map.UpgradeRingPosition
	local ringRadius = GameConfig.Map.UpgradeRingRadius
	local insideRing = false
	task.spawn(function()
		while true do
			task.wait(0.2)
			local character = localPlayer.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local inside = false
			if root and root:IsA("BasePart") then
				local offset = root.Position - ringCenter
				inside = Vector2.new(offset.X, offset.Z).Magnitude <= ringRadius and math.abs(offset.Y) < 8
			end
			if inside ~= insideRing then
				insideRing = inside
				if inside then
					Sounds.Play("Click", 1.4, 0.5)
					HUD.OpenPanel("Upgrades")
				else
					HUD.ClosePanel("Upgrades")
				end
			end
		end
	end)

	-- Placa do Ovo Celestial (contagem regressiva no pedestal)
	local gameState = ReplicatedStorage:WaitForChild("GameState")
	task.spawn(function()
		while true do
			local text: string
			if gameState:GetAttribute("CelestialActive") == true then
				text = "🌟 OVO CELESTIAL AQUI!"
			else
				local at = gameState:GetAttribute("CelestialAt")
				text = if typeof(at) == "number"
					then "OVO CELESTIAL EM " .. Format.Time(at - Workspace:GetServerTimeNow())
					else "OVO CELESTIAL"
			end
			for _, label in CollectionService:GetTagged("CelestialSign") do
				if label:IsA("TextLabel") then
					label.Text = text
				end
			end
			task.wait(0.5)
		end
	end)
end

return WorldFx
