--!strict
-- ShopPanel: LOJA — velocidade (+1/+10), carregar mais ovos e slots do celeiro.
-- O cliente só PEDE; o servidor confere o dinheiro e aplica.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local Sounds = require(script.Parent.Parent.Parent.Sounds)
local Theme = require(script.Parent.Parent.Theme)
local Toasts = require(script.Parent.Parent.Toasts)
local UIKit = require(script.Parent.Parent.UIKit)

local ShopPanel = {}

local player = Players.LocalPlayer
local Colors = Theme.Colors

local function attribute(name: string, default: number): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

type CardParts = { Card: Frame, Info: TextLabel }

local function upgradeCard(parent: Instance, order: number, icon: string, color: Color3, title: string): CardParts
	local card = UIKit.Card(parent, title, 104, order)
	UIKit.Badge(card, icon, color, UDim2.fromOffset(74, 74), UDim2.fromOffset(12, 15))
	UIKit.Label(card, {
		Name = "Title",
		Text = title,
		Font = Theme.Fonts.Title,
		Color = Colors.Ink,
		Stroke = 0,
		Size = UDim2.new(0.42, -40, 0, 34),
		Position = UDim2.fromOffset(98, 12),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 28,
	})
	local info = UIKit.Label(card, {
		Name = "Info",
		Text = "",
		Color = Colors.Muted,
		Stroke = 0,
		Size = UDim2.new(0.42, -40, 0, 44),
		Position = UDim2.fromOffset(98, 48),
		XAlign = Enum.TextXAlignment.Left,
		YAlign = Enum.TextYAlignment.Top,
		MaxTextSize = 20,
	})
	return { Card = card, Info = info }
end

local function buy(button: UIKit.Button, upgradeId: string, amount: number, refresh: () -> ())
	if not button.IsEnabled() then
		Sounds.Play("Error", 0.7)
		return
	end
	button.SetEnabled(false)
	Sounds.Play("Click", 1.2, 0.4)
	local ok, success, message = pcall(function()
		return Net.BuyUpgrade:InvokeServer(upgradeId, amount)
	end)
	if not ok then
		Toasts.Show("Erro ao comprar. Tente de novo!", "danger")
	elseif typeof(message) == "string" then
		Toasts.Show(message, if success then "success" else "danger")
		if success then
			Sounds.Play("Collect", 1.1, 0.5)
		end
	end
	refresh()
end

function ShopPanel.Create(gui: ScreenGui): UIKit.Panel
	local panel = UIKit.Panel(gui, {
		Name = "LojaPanel",
		Title = "LOJA",
		Icon = "Shop",
		Color = Colors.Green,
		DarkColor = Colors.GreenDark,
	})

	local scroll = UIKit.Scroll(panel.Body, UDim2.fromScale(1, 1))
	UIKit.List(scroll, 12).VerticalAlignment = Enum.VerticalAlignment.Top
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = scroll

	local refresh: () -> ()

	-- Velocidade
	local speed = upgradeCard(scroll, 1, "Speed", Colors.Yellow, "Velocidade")
	local speed10 = UIKit.Button({
		Name = "Speed10",
		Parent = speed.Card,
		Size = UDim2.fromOffset(124, 72),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Colors.Green,
		DarkColor = Colors.GreenDark,
		Text = "+10",
		Layout = "Text",
		MaxTextSize = 22,
		OnClick = function() end,
	})
	local speed1 = UIKit.Button({
		Name = "Speed1",
		Parent = speed.Card,
		Size = UDim2.fromOffset(124, 72),
		Position = UDim2.new(1, -146, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Colors.Green,
		DarkColor = Colors.GreenDark,
		Text = "+1",
		Layout = "Text",
		MaxTextSize = 22,
		OnClick = function() end,
	})

	-- Carregar mais ovos
	local carry = upgradeCard(scroll, 2, "Carry", Colors.Orange, "Carregar Ovos")
	local carryButton = UIKit.Button({
		Name = "Carry",
		Parent = carry.Card,
		Size = UDim2.fromOffset(150, 72),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Colors.Green,
		DarkColor = Colors.GreenDark,
		Text = "+1",
		Layout = "Text",
		MaxTextSize = 22,
	})

	-- Slots do celeiro
	local slots = upgradeCard(scroll, 3, "Slots", Colors.Purple, "Slots do Celeiro")
	local slotsButton = UIKit.Button({
		Name = "Slots",
		Parent = slots.Card,
		Size = UDim2.fromOffset(150, 72),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Colors.Green,
		DarkColor = Colors.GreenDark,
		Text = "+1",
		Layout = "Text",
		MaxTextSize = 22,
	})

	refresh = function()
		local money = attribute("Money", 0)
		local level = attribute("SpeedLevel", 0)
		local capacity = attribute("CarryCapacity", GameConfig.Carry.Start)
		local barnSlots = attribute("BarnSlots", GameConfig.Barn.StartSlots)

		-- Velocidade
		speed.Info.Text = string.format("Nível %d  •  Velocidade %d", level, Formulas.WalkSpeed(level))
		local price1, levels1 = Formulas.SpeedPurchase(level, 1)
		local price10, levels10 = Formulas.SpeedPurchase(level, 10)
		if levels1 <= 0 then
			speed1.SetText("MÁX")
			speed1.SetEnabled(false)
			speed10.SetText("MÁX")
			speed10.SetEnabled(false)
		else
			speed1.SetText("+1\n" .. Format.Money(price1))
			speed1.SetEnabled(money >= price1)
			speed10.SetText(string.format("+%d\n%s", levels10, Format.Money(price10)))
			speed10.SetEnabled(money >= price10)
		end

		-- Carregar
		carry.Info.Text = string.format("Você carrega %d ovo(s) por vez  •  máx. %d", capacity, GameConfig.Carry.Max)
		local carryPrice = Formulas.CarryPrice(capacity)
		if carryPrice then
			carryButton.SetText("+1 ovo\n" .. Format.Money(carryPrice))
			carryButton.SetEnabled(money >= carryPrice)
		else
			carryButton.SetText("MÁXIMO")
			carryButton.SetEnabled(false)
		end

		-- Slots
		slots.Info.Text = string.format("%d de %d lugares no celeiro", barnSlots, GameConfig.Barn.MaxSlots)
		local slotPrice = Formulas.SlotPrice(barnSlots)
		if slotPrice then
			slotsButton.SetText("+1 slot\n" .. Format.Money(slotPrice))
			slotsButton.SetEnabled(money >= slotPrice)
		else
			slotsButton.SetText("MÁXIMO")
			slotsButton.SetEnabled(false)
		end

		panel.Subtitle.Text = Format.Money(money)
	end

	-- Liga os cliques (precisam do refresh)
	speed1.Face.Activated:Connect(function()
		buy(speed1, "Speed", 1, refresh)
	end)
	speed10.Face.Activated:Connect(function()
		buy(speed10, "Speed", 10, refresh)
	end)
	carryButton.Face.Activated:Connect(function()
		buy(carryButton, "Carry", 1, refresh)
	end)
	slotsButton.Face.Activated:Connect(function()
		buy(slotsButton, "Slots", 1, refresh)
	end)

	for _, name in { "Money", "SpeedLevel", "CarryCapacity", "BarnSlots" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()

	return panel
end

return ShopPanel
