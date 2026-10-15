--!strict
-- ShopPanel: UPGRADES (abre ao pisar no anel ciano, como no original)
--   • Velocidade: pacotes +1, +5 e +10 (o +10 sai pela metade do preço)
--   • Carregar: +1 ovo por viagem (até 7)
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
	local card = UIKit.Card(parent, title, 112, order)
	UIKit.Badge(card, icon, color, UDim2.fromOffset(74, 74), UDim2.fromOffset(12, 19))
	UIKit.Label(card, {
		Name = "Title",
		Text = title,
		Font = Theme.Fonts.Title,
		Color = Colors.Ink,
		Stroke = 0,
		Size = UDim2.new(0.34, -20, 0, 34),
		Position = UDim2.fromOffset(98, 14),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 28,
	})
	local info = UIKit.Label(card, {
		Name = "Info",
		Text = "",
		Color = Colors.Muted,
		Stroke = 0,
		Size = UDim2.new(0.34, -20, 0, 48),
		Position = UDim2.fromOffset(98, 50),
		XAlign = Enum.TextXAlignment.Left,
		YAlign = Enum.TextYAlignment.Top,
		MaxTextSize = 19,
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

local function greenButton(parent: Instance, name: string, width: number, offsetX: number): UIKit.Button
	return UIKit.Button({
		Name = name,
		Parent = parent,
		Size = UDim2.fromOffset(width, 76),
		Position = UDim2.new(1, -offsetX, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color = Colors.Green,
		DarkColor = Colors.GreenDark,
		Text = "",
		Layout = "Text",
		MaxTextSize = 20,
	})
end

function ShopPanel.Create(gui: ScreenGui): UIKit.Panel
	local panel = UIKit.Panel(gui, {
		Name = "UpgradesPanel",
		Title = "UPGRADES",
		Icon = "Speed",
		Color = Color3.fromRGB(40, 200, 235),
		DarkColor = Color3.fromRGB(20, 120, 160),
	})

	local scroll = UIKit.Scroll(panel.Body, UDim2.fromScale(1, 1))
	UIKit.List(scroll, 12).VerticalAlignment = Enum.VerticalAlignment.Top
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = scroll

	-- Velocidade: +1 / +5 / +10
	local speed = upgradeCard(scroll, 1, "Speed", Colors.Yellow, "Velocidade")
	local speed10 = greenButton(speed.Card, "Speed10", 112, 12)
	local speed5 = greenButton(speed.Card, "Speed5", 112, 132)
	local speed1 = greenButton(speed.Card, "Speed1", 112, 252)

	-- Carregar mais ovos
	local carry = upgradeCard(scroll, 2, "💪", Colors.Orange, "Carregar")
	local carryButton = greenButton(carry.Card, "Carry", 150, 12)

	-- Dica dos slots (a compra é na placa do cercado, como no original)
	local tip = UIKit.Label(scroll, {
		Name = "Dica",
		Text = "📦 Mais slots: use a placa verde na frente do seu cercado!",
		Color = Colors.Muted,
		Stroke = 0,
		Size = UDim2.new(1, -12, 0, 30),
		MaxTextSize = 20,
		LayoutOrder = 3,
	})
	tip.TextWrapped = true

	local function refresh()
		local money = attribute("Money", 0)
		local level = attribute("SpeedLevel", 0)
		local capacity = attribute("CarryCapacity", GameConfig.Carry.Start)

		speed.Info.Text = string.format("Velocidade atual: %d", Formulas.WalkSpeed(level))
		local packs: { { Button: UIKit.Button, Amount: number } } = {
			{ Button = speed1, Amount = 1 },
			{ Button = speed5, Amount = 5 },
			{ Button = speed10, Amount = 10 },
		}
		for _, entry in packs do
			local price, levels = Formulas.SpeedPurchase(level, entry.Amount)
			if levels <= 0 then
				entry.Button.SetText("MÁX")
				entry.Button.SetEnabled(false)
			else
				entry.Button.SetText(string.format("+%d\n%s", levels, Format.Money(price)))
				entry.Button.SetEnabled(money >= price)
			end
		end

		carry.Info.Text = string.format("Você carrega %d ovo(s) por vez • máx. %d", capacity, GameConfig.Carry.Max)
		local carryPrice = Formulas.CarryPrice(capacity)
		if carryPrice then
			carryButton.SetText("+1 ovo\n" .. Format.Money(carryPrice))
			carryButton.SetEnabled(money >= carryPrice)
		else
			carryButton.SetText("MÁXIMO")
			carryButton.SetEnabled(false)
		end

		panel.Subtitle.Text = Format.Money(money)
	end

	speed1.Face.Activated:Connect(function()
		buy(speed1, "Speed", 1, refresh)
	end)
	speed5.Face.Activated:Connect(function()
		buy(speed5, "Speed", 5, refresh)
	end)
	speed10.Face.Activated:Connect(function()
		buy(speed10, "Speed", 10, refresh)
	end)
	carryButton.Face.Activated:Connect(function()
		buy(carryButton, "Carry", 1, refresh)
	end)

	for _, name in { "Money", "SpeedLevel", "CarryCapacity" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()

	return panel
end

return ShopPanel
