--!strict
--[[
	HUD: a interface principal, no estilo do Escape Tsunami For Brainrots.

	  ┌──────────────[ 🌊 PRÓXIMA ONDA 0:42 ]──────────────┐
	  │        [🎒 1/1 ovos] [📍 Raro] [🌟 Celestial 9:12] │
	  │ [🛒 LOJA   ]                         [🥚 CHOCANDO]│
	  │ [🔁 REBIRTH]                         [🏠 CELEIRO ]│
	  │ [📖 ÍNDICE ]                                      │
	  │ [👟 Velocidade 24]                                │
	  │ [💵 $1,250       ]                      ( PULAR ) │
	  └───────────────────────────────────────────────────┘
	  • Coluna da esquerda como no original: Loja (Robux), Rebirth (roxo), Índice
	  • UPGRADES de Velocidade/Carregar abrem no anel ciano do lobby (HUD.OpenPanel)
	  • Contador da próxima onda sempre no topo; sirene quando a onda nasce
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)
local Types = require(ReplicatedStorage.Shared.Types)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Sounds = require(script.Parent.Parent.Sounds)
local WaveRenderer = require(script.Parent.Parent.World.WaveRenderer)
local ConfirmDialog = require(script.Parent.ConfirmDialog)
local BarnPanel = require(script.Parent.Panels.BarnPanel)
local HatchingPanel = require(script.Parent.Panels.HatchingPanel)
local IndexPanel = require(script.Parent.Panels.IndexPanel)
local RebirthPanel = require(script.Parent.Panels.RebirthPanel)
local ShopPanel = require(script.Parent.Panels.ShopPanel)
local StorePanel = require(script.Parent.Panels.StorePanel)
local Theme = require(script.Parent.Theme)
local Toasts = require(script.Parent.Toasts)
local UIKit = require(script.Parent.UIKit)

local HUD = {}

local player = Players.LocalPlayer
local Colors = Theme.Colors
local Sizes = Theme.Sizes

local BARN_RED = Color3.fromRGB(225, 75, 60)
local BARN_RED_DARK = Color3.fromRGB(150, 40, 30)

local function attribute(name: string, default: number): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- ---------------------------------------------------------------------
-- Painéis (só um aberto por vez)
-- ---------------------------------------------------------------------

local panels: { [string]: UIKit.Panel } = {}

function HUD.OpenPanel(name: string)
	local target = panels[name]
	if not target or target.IsOpen() then
		return
	end
	for otherName, panel in panels do
		if otherName ~= name then
			panel.Close()
		end
	end
	target.Open()
end

function HUD.ClosePanel(name: string)
	local target = panels[name]
	if target then
		target.Close()
	end
end

local function togglePanel(name: string)
	Sounds.Play("Click", 1, 0.4)
	local target = panels[name]
	if target and target.IsOpen() then
		target.Close()
	else
		HUD.OpenPanel(name)
	end
end

-- ---------------------------------------------------------------------
-- Botões laterais
-- ---------------------------------------------------------------------

local function sideCluster(gui: ScreenGui, name: string, count: number, anchorX: number, positionX: UDim, offsetY: number): Frame
	local size = Sizes.SideButton
	local height = (size + Sizes.ButtonDepth) * count + Sizes.Gap * (count - 1)
	local cluster = UIKit.Frame(gui, name, UDim2.fromOffset(size + 8, height), UDim2.new(positionX.Scale, positionX.Offset, 0.5, offsetY))
	cluster.AnchorPoint = Vector2.new(anchorX, 0.5)
	UIKit.ViewportScale(cluster)
	UIKit.List(cluster, Sizes.Gap)
	return cluster
end

local function sideButton(cluster: Frame, order: number, icon: string, text: string, color: Color3, dark: Color3, onClick: () -> ()): UIKit.Button
	return UIKit.Button({
		Name = text,
		Parent = cluster,
		LayoutOrder = order,
		Size = UDim2.fromOffset(Sizes.SideButton, Sizes.SideButton + Sizes.ButtonDepth),
		Color = color,
		DarkColor = dark,
		Icon = icon,
		Text = text,
		Layout = "Stack",
		MaxTextSize = 20,
		OnClick = onClick,
	})
end

-- ---------------------------------------------------------------------
-- Aviso do tsunami (topo)
-- ---------------------------------------------------------------------

type Banner = {
	Root: Frame,
	Gradient: UIGradient,
	Main: TextLabel,
	Sub: TextLabel,
	Pulse: UIScale,
}

local function createBanner(parent: Instance): Banner
	local root = UIKit.Frame(parent, "AvisoTsunami", UDim2.fromOffset(440, 58), nil, Colors.White)
	root.LayoutOrder = 1
	UIKit.Corner(root, UDim.new(0.5, 0))
	UIKit.Stroke(root, 3, Colors.Ink, true)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Colors.Ink)
	gradient.Parent = root
	local pulse = Instance.new("UIScale")
	pulse.Parent = root
	local main = UIKit.Label(root, {
		Name = "Main",
		Font = Theme.Fonts.Title,
		Size = UDim2.new(1, -24, 1, -10),
		Position = UDim2.fromOffset(12, 5),
		MaxTextSize = 30,
		Stroke = 2.5,
		StrokeColor = Colors.Ink,
	})
	local sub = UIKit.Label(root, {
		Name = "Sub",
		Size = UDim2.new(1, -24, 0.36, 0),
		Position = UDim2.new(0, 12, 0.6, -2),
		MaxTextSize = 18,
		Stroke = 2,
		StrokeColor = Colors.Ink,
	})
	sub.Visible = false
	return { Root = root, Gradient = gradient, Main = main, Sub = sub, Pulse = pulse }
end

local function setBannerColor(banner: Banner, color: Color3)
	banner.Gradient.Color = ColorSequence.new(Theme.Lighten(color, 0.15), Theme.Darken(color, 0.2))
end

local function setTwoLines(banner: Banner, twoLines: boolean)
	banner.Sub.Visible = twoLines
	banner.Main.Size = if twoLines then UDim2.new(1, -24, 0.6, -2) else UDim2.new(1, -24, 1, -10)
end

local function pulse(banner: Banner)
	banner.Pulse.Scale = 1.12
	UIKit.Tween(banner.Pulse, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- ---------------------------------------------------------------------

function HUD.Start()
	local playerGui = player:WaitForChild("PlayerGui")
	local gameState = ReplicatedStorage:WaitForChild("GameState")

	local gui = Instance.new("ScreenGui")
	gui.Name = "TsunamiHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	Toasts.Start(gui)

	panels.Upgrades = ShopPanel.Create(gui)
	panels.Store = StorePanel.Create(gui)
	panels.Rebirth = RebirthPanel.Create(gui)
	panels.Index = IndexPanel.Create(gui)
	panels.Hatching = HatchingPanel.Create(gui)
	panels.Barn = BarnPanel.Create(gui)

	ConfirmDialog.Start(gui)

	-- Esquerda (como no original): Loja, Rebirth (roxo) e Índice
	local left = sideCluster(gui, "Esquerda", 3, 0, UDim.new(0, Sizes.Margin), -10)
	local storeButton = sideButton(left, 1, "Shop", "Loja", Colors.Yellow, Colors.YellowDark, function()
		togglePanel("Store")
	end)
	local rebirthButton = sideButton(left, 2, "🔁", "Rebirth", Colors.Purple, Colors.PurpleDark, function()
		togglePanel("Rebirth")
	end)
	local indexButton = sideButton(left, 3, "Index", "Índice", Colors.Blue, Colors.BlueDark, function()
		togglePanel("Index")
	end)
	storeButton.SetBadge(nil)

	-- Direita: Chocando e Celeiro — acima do botão de pular do celular
	local right = sideCluster(gui, "Direita", 2, 1, UDim.new(1, -Sizes.Margin), -50)
	local hatchButton = sideButton(right, 1, "Hatching", "Chocando", Colors.Orange, Colors.OrangeDark, function()
		togglePanel("Hatching")
	end)
	sideButton(right, 2, "Barn", "Celeiro", BARN_RED, BARN_RED_DARK, function()
		togglePanel("Barn")
	end)

	-- Inferior esquerdo: velocidade + dinheiro
	local stats = UIKit.Frame(gui, "Status", UDim2.fromOffset(250, 104), UDim2.new(0, Sizes.Margin, 1, -Sizes.Margin))
	stats.AnchorPoint = Vector2.new(0, 1)
	UIKit.ViewportScale(stats)
	local statsLayout = UIKit.List(stats, 8, false, Enum.HorizontalAlignment.Left)
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	local speedPill = UIKit.Pill(stats, "Velocidade", UDim2.fromOffset(220, 44), "Speed", "16", Colors.White)
	speedPill.Root.LayoutOrder = 1
	local moneyPill = UIKit.Pill(stats, "Dinheiro", UDim2.fromOffset(250, 52), "Money", "$0", Colors.Money)
	moneyPill.Root.LayoutOrder = 2

	-- Topo: aviso do tsunami + linha de informações
	local top = UIKit.Frame(gui, "Topo", UDim2.fromOffset(560, 104), UDim2.new(0.5, 0, 0, 6))
	top.AnchorPoint = Vector2.new(0.5, 0)
	UIKit.ViewportScale(top)
	local topLayout = UIKit.List(top, 6)
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	local banner = createBanner(top)

	local infoRow = UIKit.Frame(top, "Info", UDim2.fromOffset(560, 36))
	infoRow.LayoutOrder = 2
	UIKit.List(infoRow, 8, true)
	local carryPill = UIKit.Pill(infoRow, "Carregando", UDim2.fromOffset(150, 36), "Carry", "0/1", Colors.White)
	carryPill.Root.LayoutOrder = 1
	local zonePill = UIKit.Pill(infoRow, "Zona", UDim2.fromOffset(170, 36), "Pin", "", Colors.White)
	zonePill.Root.LayoutOrder = 2
	local celestialPill = UIKit.Pill(infoRow, "Celestial", UDim2.fromOffset(210, 36), "🌟", "", Color3.fromRGB(255, 160, 220))
	celestialPill.Root.LayoutOrder = 3

	-- -----------------------------------------------------------------
	-- Dinheiro, velocidade, carga e bolinhas de notificação
	-- -----------------------------------------------------------------

	local shownMoney = attribute("Money", 0)
	local moneyValue = Instance.new("NumberValue")
	moneyValue.Value = shownMoney
	moneyValue.Changed:Connect(function(value)
		moneyPill.Label.Text = Format.Money(value)
	end)
	moneyPill.Label.Text = Format.Money(shownMoney)

	local function canRebirth(): boolean
		local target = attribute("Rebirths", 0) + 1
		return target <= GameConfig.Rebirth.MaxRebirths
			and Formulas.WalkSpeed(attribute("SpeedLevel", 0)) >= Formulas.RebirthSpeed(target)
	end

	local function refreshBadges()
		rebirthButton.SetBadge(if canRebirth() then "" else nil)
	end

	player:GetAttributeChangedSignal("Money"):Connect(function()
		local money = attribute("Money", 0)
		if money > shownMoney then
			moneyPill.Pop()
		end
		shownMoney = money
		UIKit.Tween(moneyValue, 0.35, { Value = money })
	end)

	local function onSpeed()
		local speed = Formulas.WalkSpeed(attribute("SpeedLevel", 0), player:GetAttribute("Pass_SpeedBoost") == true)
		speedPill.Label.Text = string.format("Velocidade %d", speed)
		speedPill.Pop()
		refreshBadges()
	end
	player:GetAttributeChangedSignal("SpeedLevel"):Connect(onSpeed)
	player:GetAttributeChangedSignal("Pass_SpeedBoost"):Connect(onSpeed)
	player:GetAttributeChangedSignal("Rebirths"):Connect(refreshBadges)
	onSpeed()

	local function onCarry()
		local carrying = attribute("Carrying", 0)
		local capacity = attribute("CarryCapacity", GameConfig.Carry.Start)
		carryPill.Root.Visible = carrying > 0
		if carrying >= capacity then
			carryPill.Label.Text = string.format("%d/%d CHEIO!", carrying, capacity)
			carryPill.Label.TextColor3 = Colors.Orange
		else
			carryPill.Label.Text = string.format("%d/%d ovos", carrying, capacity)
			carryPill.Label.TextColor3 = Colors.White
		end
		carryPill.Pop()
	end
	player:GetAttributeChangedSignal("Carrying"):Connect(onCarry)
	player:GetAttributeChangedSignal("CarryCapacity"):Connect(onCarry)
	onCarry()

	-- Índice: bolinha quando aparece animal novo; Chocando: contador
	local known: { [string]: boolean }? = nil
	local newCount = 0
	PlayerData.Changed:Connect(function(snapshot: Types.Snapshot)
		if known == nil then
			known = table.clone(snapshot.Index)
		else
			local current = known :: { [string]: boolean }
			for animalId in snapshot.Index do
				if not current[animalId] then
					current[animalId] = true
					newCount += 1
				end
			end
		end
		indexButton.SetBadge(if newCount > 0 then tostring(newCount) else nil)
		local hatching = HatchingPanel.CountHatching(snapshot)
		hatchButton.SetBadge(if hatching > 0 then tostring(hatching) else nil)
	end)
	panels.Index.Opened:Connect(function()
		newCount = 0
		indexButton.SetBadge(nil)
	end)

	-- Área atual (no corredor) + Ovo Celestial
	task.spawn(function()
		while true do
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local text: string? = nil
			local color = Colors.White
			if root and root:IsA("BasePart") then
				local z = root.Position.Z
				local zone = MapLayout.GetZoneAtZ(z)
				if zone then
					text = zone.Area.Name
					color = if zone.Rarity then zone.Rarity.Color else Colors.SafeGreen
				elseif z >= MapLayout.SafeZoneStartZ and z < MapLayout.CorridorStartZ then
					text = "Zona Segura"
					color = Colors.SafeGreen
				elseif z > MapLayout.CorridorEndZ then
					text = "Torre do Tsunami"
					color = Color3.fromRGB(255, 160, 220)
				end
			end
			zonePill.Root.Visible = text ~= nil
			if text then
				zonePill.Label.Text = text
				zonePill.Label.TextColor3 = color
				local stroke = zonePill.Label:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = Theme.StrokeFor(color)
				end
			end

			local celestialAt = gameState:GetAttribute("CelestialAt")
			if gameState:GetAttribute("CelestialActive") == true then
				celestialPill.Label.Text = "OVO CELESTIAL NO FIM!"
			elseif typeof(celestialAt) == "number" then
				celestialPill.Label.Text = "Celestial " .. Format.Time(celestialAt - Workspace:GetServerTimeNow())
			else
				celestialPill.Label.Text = "Celestial"
			end
			task.wait(0.25)
		end
	end)

	-- Contador da onda (sempre visível no topo)
	local sirenFor: number? = nil
	local lastTick = -1
	local state = ""
	local flashUntil = 0
	local flashType: GameConfig.WaveType? = nil
	task.spawn(function()
		while true do
			local now = Workspace:GetServerTimeNow()
			local nextAt = gameState:GetAttribute("NextWaveAt")
			local nextTypeId = gameState:GetAttribute("NextWaveType")
			local nextType = if typeof(nextTypeId) == "string" then GameConfig.WaveTypesById[nextTypeId] else nil
			local remaining = if typeof(nextAt) == "number" then nextAt - now else math.huge

			-- a onda acabou de nascer: sirene + nome dela por alguns segundos
			local activeWaves = WaveRenderer.GetActive()
			local newest = activeWaves[#activeWaves]
			if newest and newest.StartTime ~= sirenFor and now - newest.StartTime < 2 then
				sirenFor = newest.StartTime
				flashUntil = now + 4
				flashType = GameConfig.WaveTypesById[newest.Type]
				if Sounds.Has("Siren") then
					Sounds.Play("Siren", 1, 0.6)
				else
					Sounds.Play("Warning", 0.6, 0.7)
				end
			end

			if flashType and now < flashUntil then
				if state ~= "flash" then
					state = "flash"
					setTwoLines(banner, true)
					setBannerColor(banner, flashType.Color)
					pulse(banner)
				end
				banner.Main.Text = string.format("🌊 ONDA %s %s", flashType.Name, flashType.Emoji)
				banner.Sub.Text = "Esconda-se numa trincheira!"
			elseif nextType and remaining > 0 and remaining <= GameConfig.Waves.WarningTime then
				if state ~= "warning" then
					state = "warning"
					setTwoLines(banner, true)
					setBannerColor(banner, nextType.Color)
				end
				local seconds = math.ceil(remaining)
				banner.Main.Text = string.format("🌊 TSUNAMI EM %ds!", seconds)
				banner.Sub.Text = string.format("Onda %s %s", nextType.Name, nextType.Emoji)
				if seconds ~= lastTick then
					lastTick = seconds
					pulse(banner)
					Sounds.Play("Warning", if seconds <= 3 then 1.4 else 1, 0.5)
				end
			else
				if state ~= "calm" then
					state = "calm"
					setTwoLines(banner, false)
					banner.Gradient.Color = ColorSequence.new(Colors.Ink)
				end
				banner.Main.Text = if remaining < math.huge
					then "🌊 PRÓXIMA ONDA: " .. Format.Time(remaining)
					else "🌊 Mar calmo..."
			end
			task.wait(0.1)
		end
	end)
end

return HUD
