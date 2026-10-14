--!strict
--[[
	HUD: a interface principal (inspirada no Roube um Ovo / Fuja do Tsunami).

	  ┌───────────────[ 🌊 TSUNAMI EM 7s! ]───────────────┐
	  │              [🎒 1/1 ovos] [📍 Zona Raro]         │
	  │ [🛒 LOJA ]                           [🥚 CHOCANDO]│
	  │ [📖 ÍNDICE]                          [🏠 CELEIRO ]│
	  │                                                   │
	  │ [👟 Velocidade 12]                                │
	  │ [💵 $1,250       ]                      ( PULAR ) │
	  └───────────────────────────────────────────────────┘
	Centro da tela livre; botões grandes nas bordas (bom para celular).
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
local ShopPanel = require(script.Parent.Panels.ShopPanel)
local Theme = require(script.Parent.Theme)
local Toasts = require(script.Parent.Toasts)
local UIKit = require(script.Parent.UIKit)

local HUD = {}

local player = Players.LocalPlayer
local Colors = Theme.Colors
local Sizes = Theme.Sizes

local function attribute(name: string, default: number): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- ---------------------------------------------------------------------
-- Painéis (só um aberto por vez)
-- ---------------------------------------------------------------------

local panels: { [string]: UIKit.Panel } = {}

local function togglePanel(name: string)
	Sounds.Play("Click", 1, 0.4)
	local target = panels[name]
	if not target then
		return
	end
	if target.IsOpen() then
		target.Close()
		return
	end
	for otherName, panel in panels do
		if otherName ~= name then
			panel.Close()
		end
	end
	target.Open()
end

-- ---------------------------------------------------------------------
-- Botões laterais
-- ---------------------------------------------------------------------

local function sideCluster(gui: ScreenGui, name: string, anchorX: number, positionX: UDim, offsetY: number): Frame
	local size = Sizes.SideButton
	local cluster = UIKit.Frame(gui, name, UDim2.fromOffset(size + 8, (size + Sizes.ButtonDepth) * 2 + Sizes.Gap), UDim2.new(positionX.Scale, positionX.Offset, 0.5, offsetY))
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
	banner.Gradient.Color = ColorSequence.new(Theme.Lighten(color, 0.15), Theme.Darken(color, 0.15))
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

	panels.Shop = ShopPanel.Create(gui)
	panels.Index = IndexPanel.Create(gui)
	panels.Hatching = HatchingPanel.Create(gui)
	panels.Barn = BarnPanel.Create(gui)

	ConfirmDialog.Start(gui)

	-- Esquerda: Loja (verde) e Índice (azul)
	local left = sideCluster(gui, "Esquerda", 0, UDim.new(0, Sizes.Margin), -20)
	local shopButton = sideButton(left, 1, "Shop", "Loja", Colors.Green, Colors.GreenDark, function()
		togglePanel("Shop")
	end)
	local indexButton = sideButton(left, 2, "Index", "Índice", Colors.Blue, Colors.BlueDark, function()
		togglePanel("Index")
	end)

	-- Direita: Chocando (laranja) e Celeiro (roxo) — acima do botão de pular do celular
	local right = sideCluster(gui, "Direita", 1, UDim.new(1, -Sizes.Margin), -50)
	local hatchButton = sideButton(right, 1, "Hatching", "Chocando", Colors.Orange, Colors.OrangeDark, function()
		togglePanel("Hatching")
	end)
	sideButton(right, 2, "Barn", "Celeiro", Colors.Purple, Colors.PurpleDark, function()
		togglePanel("Barn")
	end)

	-- Inferior esquerdo: velocidade + dinheiro
	local stats = UIKit.Frame(gui, "Status", UDim2.fromOffset(250, 104), UDim2.new(0, Sizes.Margin, 1, -Sizes.Margin))
	stats.AnchorPoint = Vector2.new(0, 1)
	UIKit.ViewportScale(stats)
	local statsLayout = UIKit.List(stats, 8, false, Enum.HorizontalAlignment.Left)
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	local speedPill = UIKit.Pill(stats, "Velocidade", UDim2.fromOffset(210, 44), "Speed", "0", Colors.White)
	speedPill.Root.LayoutOrder = 1
	local moneyPill = UIKit.Pill(stats, "Dinheiro", UDim2.fromOffset(250, 52), "Money", "$0", Colors.Money)
	moneyPill.Root.LayoutOrder = 2

	-- Topo: aviso do tsunami + linha de informações
	local top = UIKit.Frame(gui, "Topo", UDim2.fromOffset(460, 104), UDim2.new(0.5, 0, 0, 6))
	top.AnchorPoint = Vector2.new(0.5, 0)
	UIKit.ViewportScale(top)
	local topLayout = UIKit.List(top, 6)
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	local banner = createBanner(top)

	local infoRow = UIKit.Frame(top, "Info", UDim2.fromOffset(460, 36))
	infoRow.LayoutOrder = 2
	UIKit.List(infoRow, 8, true)
	local carryPill = UIKit.Pill(infoRow, "Carregando", UDim2.fromOffset(170, 36), "Carry", "0/1 ovos", Colors.White)
	carryPill.Root.LayoutOrder = 1
	local zonePill = UIKit.Pill(infoRow, "Zona", UDim2.fromOffset(200, 36), "Pin", "", Colors.White)
	zonePill.Root.LayoutOrder = 2

	-- -----------------------------------------------------------------
	-- Atualizações
	-- -----------------------------------------------------------------

	-- Dinheiro com animação de contagem
	local shownMoney = attribute("Money", 0)
	local moneyValue = Instance.new("NumberValue")
	moneyValue.Value = shownMoney
	moneyValue.Changed:Connect(function(value)
		moneyPill.Label.Text = Format.Money(value)
	end)
	moneyPill.Label.Text = Format.Money(shownMoney)

	local function canBuySomething(): boolean
		local money = attribute("Money", 0)
		local price = Formulas.SpeedPurchase(attribute("SpeedLevel", 0), 1)
		local carryPrice = Formulas.CarryPrice(attribute("CarryCapacity", GameConfig.Carry.Start))
		local slotPrice = Formulas.SlotPrice(attribute("BarnSlots", GameConfig.Barn.StartSlots))
		return money >= price or (carryPrice ~= nil and money >= carryPrice) or (slotPrice ~= nil and money >= slotPrice)
	end

	local function onMoney()
		local money = attribute("Money", 0)
		if money > shownMoney then
			moneyPill.Pop()
		end
		shownMoney = money
		UIKit.Tween(moneyValue, 0.35, { Value = money })
		shopButton.SetBadge(if canBuySomething() then "" else nil)
	end
	player:GetAttributeChangedSignal("Money"):Connect(onMoney)

	local function onSpeed()
		local level = attribute("SpeedLevel", 0)
		speedPill.Label.Text = string.format("Velocidade %d", level)
		speedPill.Pop()
		shopButton.SetBadge(if canBuySomething() then "" else nil)
	end
	player:GetAttributeChangedSignal("SpeedLevel"):Connect(onSpeed)
	onSpeed()
	onMoney()

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
	for _, name in { "CarryCapacity", "BarnSlots" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			shopButton.SetBadge(if canBuySomething() then "" else nil)
		end)
	end

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

	-- Zona atual (no corredor)
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
					text = "Zona " .. zone.Rarity.Name
					color = zone.Rarity.Color
				elseif z >= MapLayout.SafeZoneStartZ and z < MapLayout.CorridorStartZ then
					text = "Zona Segura"
					color = Colors.SafeGreen
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
			task.wait(0.25)
		end
	end)

	-- Aviso do tsunami
	local sirenFor: number? = nil
	local lastTick = -1
	local state = ""
	task.spawn(function()
		while true do
			local now = Workspace:GetServerTimeNow()
			local nextAt = gameState:GetAttribute("NextWaveAt")
			local nextTypeId = gameState:GetAttribute("NextWaveType")
			local nextType = if typeof(nextTypeId) == "string" then GameConfig.WaveTypesById[nextTypeId] else nil
			local activeWaves = WaveRenderer.GetActive()
			local remaining = if typeof(nextAt) == "number" then nextAt - now else math.huge

			if nextType and remaining > 0 and remaining <= GameConfig.Waves.WarningTime then
				-- AVISO: contagem regressiva
				if state ~= "warning" then
					state = "warning"
					banner.Sub.Visible = true
					banner.Main.Size = UDim2.new(1, -24, 0.6, -2)
					setBannerColor(banner, nextType.Color)
				end
				local seconds = math.ceil(remaining)
				banner.Main.Text = string.format("🌊 TSUNAMI EM %ds!", seconds)
				banner.Sub.Text = "Onda " .. nextType.Name .. "  •  Corra para um buraco!"
				if sirenFor ~= nextAt then
					sirenFor = nextAt :: number
					if Sounds.Has("Siren") then
						Sounds.Play("Siren", 1, 0.6)
					end
				end
				if seconds ~= lastTick then
					lastTick = seconds
					banner.Pulse.Scale = 1.12
					UIKit.Tween(banner.Pulse, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
					if not Sounds.Has("Siren") or seconds <= 3 then
						Sounds.Play("Warning", if seconds <= 3 then 1.4 else 0.9, 0.5)
					end
				end
			elseif #activeWaves > 0 then
				-- ONDA NO CORREDOR
				local newest = activeWaves[#activeWaves]
				local waveType = GameConfig.WaveTypesById[newest.Type]
				if state ~= "active" then
					state = "active"
					banner.Sub.Visible = true
					banner.Main.Size = UDim2.new(1, -24, 0.6, -2)
					setBannerColor(banner, Theme.Darken(if waveType then waveType.Color else Colors.Blue, 0.15))
				end
				banner.Main.Text = "🌊 ONDA " .. (if waveType then waveType.Name else "") .. "!"
				banner.Sub.Text = "Esconda-se nos buracos!"
			else
				-- CALMO: próxima onda
				if state ~= "calm" then
					state = "calm"
					banner.Sub.Visible = false
					banner.Main.Size = UDim2.new(1, -24, 1, -10)
					banner.Gradient.Color = ColorSequence.new(Colors.Ink)
				end
				banner.Main.Text = if remaining < math.huge
					then "🌊 Próxima onda em " .. Format.Time(remaining)
					else "🌊 Mar calmo..."
			end
			task.wait(0.1)
		end
	end)
end

return HUD
