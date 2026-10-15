--!strict
--[[
	HUD: a interface principal, igual à do vídeo do Escape Tsunami For Brainrots.

	  ┌────────────────────[ Área Comum ]─────────────────────┐
	  │ [Loja ][ VIP  ]     [🌊 Próxima onda 0:42]            │
	  │ [Índice][Renascer]  [🌟 Celestial 9:12]               │
	  │ [Chocando][Cercado]                                    │
	  │                                                        │
	  │ 👟 16   🎒 0/1          [🗑 Soltar]                     │
	  │ 🔁 0   $1,250                                 ( PULAR ) │
	  └────────────────────────────────────────────────────────┘
	  • grade de 2 colunas de ladrilhos escuros na esquerda (Loja com borda dourada e "Novo")
	  • status embaixo à esquerda: velocidade, ovos carregados, renascimentos e dinheiro
	  • nome da área no topo; contador da onda logo abaixo (vira aviso grande nos últimos 5 s)
	  • botão rosa "Soltar" aparece quando você carrega ovos (tecla G)
	  • UPGRADES de Velocidade/Carregar abrem no anel ciano do lobby (HUD.OpenPanel)
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)
local Net = require(ReplicatedStorage.Shared.Net)
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

local GOLD = Color3.fromRGB(255, 190, 40)
local DROP_PINK = Color3.fromRGB(255, 70, 140)
local DROP_PINK_DARK = Color3.fromRGB(170, 20, 80)
local TILE = 84 -- tamanho base de cada ladrilho

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
-- Grade de ladrilhos (esquerda) e linhas de status (embaixo)
-- ---------------------------------------------------------------------

local function tileGrid(gui: ScreenGui): Frame
	local gap = 8
	local rows = 3
	local grid = UIKit.Frame(gui, "Botoes", UDim2.fromOffset(TILE * 2 + gap, TILE * rows + (gap + 4) * (rows - 1)), UDim2.new(0, Sizes.Margin, 0.5, -24))
	grid.AnchorPoint = Vector2.new(0, 0.5)
	UIKit.ViewportScale(grid)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(TILE, TILE)
	layout.CellPadding = UDim2.fromOffset(gap, gap + 4)
	layout.FillDirectionMaxCells = 2
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	return grid
end

-- Linha de status: ícone + valor, fundo escuro arredondado
local function statChip(parent: Instance, name: string, order: number, width: number, icon: string, color: Color3): UIKit.Pill
	local pill = UIKit.Pill(parent, name, UDim2.fromOffset(width, 34), icon, "", color)
	pill.Root.LayoutOrder = order
	return pill
end

local function statRow(parent: Instance, order: number): Frame
	local row = UIKit.Frame(parent, "Linha" .. order, UDim2.fromOffset(300, 34))
	row.LayoutOrder = order
	UIKit.List(row, 6, true, Enum.HorizontalAlignment.Left)
	return row
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
	local root = UIKit.Frame(parent, "AvisoTsunami", UDim2.fromOffset(380, 50), nil, Colors.White)
	root.LayoutOrder = 2
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
		MaxTextSize = 26,
		Stroke = 2.5,
		StrokeColor = Colors.Ink,
	})
	local sub = UIKit.Label(root, {
		Name = "Sub",
		Size = UDim2.new(1, -24, 0.36, 0),
		Position = UDim2.new(0, 12, 0.6, -2),
		MaxTextSize = 16,
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

	-- Esquerda: grade de ladrilhos igual ao vídeo
	local grid = tileGrid(gui)
	local storeTile = UIKit.Tile({
		Name = "Loja",
		Parent = grid,
		LayoutOrder = 1,
		Icon = "Shop",
		Text = "Loja",
		Highlight = GOLD,
		Tag = "Novo",
		OnClick = function()
			togglePanel("Store")
		end,
	})
	UIKit.Tile({
		Name = "VIP",
		Parent = grid,
		LayoutOrder = 2,
		Icon = "👑",
		Text = "VIP",
		OnClick = function()
			Sounds.Play("Click", 1, 0.4)
			local pass = GameConfig.GamePassesByKey.VIP
			if player:GetAttribute("Pass_VIP") == true then
				Toasts.Show("Você já é VIP! Use as portas de vidro nas paredes 👑", "success")
			elseif not pass or pass.Id == 0 then
				HUD.OpenPanel("Store")
			else
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end
		end,
	})
	local indexButton = UIKit.Tile({
		Name = "Indice",
		Parent = grid,
		LayoutOrder = 3,
		Icon = "Index",
		Text = "Índice",
		OnClick = function()
			togglePanel("Index")
		end,
	})
	local rebirthButton = UIKit.Tile({
		Name = "Renascer",
		Parent = grid,
		LayoutOrder = 4,
		Icon = "🔁",
		Text = "Renascer",
		OnClick = function()
			togglePanel("Rebirth")
		end,
	})
	local hatchButton = UIKit.Tile({
		Name = "Chocando",
		Parent = grid,
		LayoutOrder = 5,
		Icon = "Hatching",
		Text = "Chocando",
		OnClick = function()
			togglePanel("Hatching")
		end,
	})
	UIKit.Tile({
		Name = "Cercado",
		Parent = grid,
		LayoutOrder = 6,
		Icon = "Barn",
		Text = "Cercado",
		OnClick = function()
			togglePanel("Barn")
		end,
	})
	storeTile.SetBadge(nil)

	-- Inferior esquerdo: velocidade + ovos carregados / renascimentos + dinheiro
	local stats = UIKit.Frame(gui, "Status", UDim2.fromOffset(300, 74), UDim2.new(0, Sizes.Margin, 1, -Sizes.Margin))
	stats.AnchorPoint = Vector2.new(0, 1)
	UIKit.ViewportScale(stats)
	local statsLayout = UIKit.List(stats, 6, false, Enum.HorizontalAlignment.Left)
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	local row1 = statRow(stats, 1)
	local speedPill = statChip(row1, "Velocidade", 1, 104, "Speed", Colors.White)
	local carryPill = statChip(row1, "Carregando", 2, 110, "Carry", Colors.White)
	local row2 = statRow(stats, 2)
	local rebirthPill = statChip(row2, "Renascimentos", 1, 80, "🔁", Color3.fromRGB(255, 200, 60))
	local moneyPill = statChip(row2, "Dinheiro", 2, 210, "Money", Colors.Money)

	-- Topo: nome da área + contador da onda + Ovo Celestial
	local top = UIKit.Frame(gui, "Topo", UDim2.fromOffset(520, 128), UDim2.new(0.5, 0, 0, 2))
	top.AnchorPoint = Vector2.new(0.5, 0)
	UIKit.ViewportScale(top)
	local topLayout = UIKit.List(top, 4)
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	local areaLabel = UIKit.Label(top, {
		Name = "Area",
		Text = "",
		Font = Theme.Fonts.Title,
		Size = UDim2.fromOffset(520, 36),
		MaxTextSize = 32,
		Stroke = 3,
		StrokeColor = Colors.Ink,
		LayoutOrder = 1,
	})
	local banner = createBanner(top)
	local celestialPill = UIKit.Pill(top, "Celestial", UDim2.fromOffset(230, 30), "🌟", "", Color3.fromRGB(255, 160, 220))
	celestialPill.Root.LayoutOrder = 3

	-- Botão rosa "Soltar" (só aparece quando está carregando ovos)
	local dropButton = UIKit.Button({
		Name = "Soltar",
		Parent = gui,
		Size = UDim2.fromOffset(170, 58),
		Position = UDim2.new(0.5, 0, 1, -Sizes.Margin - 70),
		AnchorPoint = Vector2.new(0.5, 1),
		Color = DROP_PINK,
		DarkColor = DROP_PINK_DARK,
		Icon = "🗑",
		Text = "Soltar",
		Layout = "Row",
		MaxTextSize = 26,
		OnClick = function()
			Sounds.Play("Click", 0.9, 0.4)
			Net.DropCarried:FireServer()
		end,
	})
	UIKit.ViewportScale(dropButton.Holder)
	dropButton.Holder.Visible = false
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.G and dropButton.Holder.Visible then
			Net.DropCarried:FireServer()
		end
	end)

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
		speedPill.Label.Text = tostring(speed)
		speedPill.Pop()
		refreshBadges()
	end
	player:GetAttributeChangedSignal("SpeedLevel"):Connect(onSpeed)
	player:GetAttributeChangedSignal("Pass_SpeedBoost"):Connect(onSpeed)
	onSpeed()

	local function onRebirths()
		rebirthPill.Label.Text = tostring(attribute("Rebirths", 0))
		refreshBadges()
	end
	player:GetAttributeChangedSignal("Rebirths"):Connect(onRebirths)
	onRebirths()

	local function onCarry()
		local carrying = attribute("Carrying", 0)
		local capacity = attribute("CarryCapacity", GameConfig.Carry.Start)
		dropButton.Holder.Visible = carrying > 0
		carryPill.Label.Text = string.format("%d/%d", carrying, capacity)
		carryPill.Label.TextColor3 = if carrying >= capacity then Colors.Orange else Colors.White
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
				elseif z < MapLayout.SafeZoneStartZ then
					text = "Base"
					color = Colors.White
				elseif z > MapLayout.CorridorEndZ then
					text = "Torre do Tsunami"
					color = Color3.fromRGB(255, 160, 220)
				end
			end
			areaLabel.Text = text or ""
			areaLabel.TextColor3 = color
			local stroke = areaLabel:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = Theme.StrokeFor(color)
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
					then "🌊 Próxima onda: " .. Format.Time(remaining)
					else "🌊 Mar calmo..."
			end
			task.wait(0.1)
		end
	end)
end

return HUD
