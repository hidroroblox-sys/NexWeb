--!strict
-- StorePanel: LOJA (Robux) — gamepasses do GameConfig (VIP, Turbo...).
-- Se o ID do gamepass for 0, aparece "Em breve".

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Theme = require(script.Parent.Parent.Theme)
local Toasts = require(script.Parent.Parent.Toasts)
local UIKit = require(script.Parent.Parent.UIKit)

local StorePanel = {}

local player = Players.LocalPlayer
local Colors = Theme.Colors

function StorePanel.Create(gui: ScreenGui): UIKit.Panel
	local panel = UIKit.Panel(gui, {
		Name = "LojaPanel",
		Title = "LOJA",
		Icon = "Shop",
		Color = Colors.Yellow,
		DarkColor = Colors.YellowDark,
	})
	panel.Subtitle.Text = "Robux"

	local scroll = UIKit.Scroll(panel.Body, UDim2.fromScale(1, 1))
	UIKit.List(scroll, 12).VerticalAlignment = Enum.VerticalAlignment.Top
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.Parent = scroll

	local buttons: { [string]: UIKit.Button } = {}
	for order, pass in GameConfig.GamePasses do
		local card = UIKit.Card(scroll, pass.Key, 112, order, Colors.Yellow)
		UIKit.Badge(card, pass.Icon, Colors.Yellow, UDim2.fromOffset(74, 74), UDim2.fromOffset(12, 19))
		UIKit.Label(card, {
			Text = pass.Name,
			Font = Theme.Fonts.Title,
			Color = Colors.Ink,
			Stroke = 0,
			Size = UDim2.new(0.5, -40, 0, 34),
			Position = UDim2.fromOffset(98, 12),
			XAlign = Enum.TextXAlignment.Left,
			MaxTextSize = 28,
		})
		UIKit.Label(card, {
			Text = pass.Description,
			Color = Colors.Muted,
			Stroke = 0,
			Size = UDim2.new(0.5, -40, 0, 56),
			Position = UDim2.fromOffset(98, 46),
			XAlign = Enum.TextXAlignment.Left,
			YAlign = Enum.TextYAlignment.Top,
			MaxTextSize = 18,
		})
		local button = UIKit.Button({
			Name = "Comprar",
			Parent = card,
			Size = UDim2.fromOffset(170, 76),
			Position = UDim2.new(1, -12, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			Color = Colors.Green,
			DarkColor = Colors.GreenDark,
			Text = "",
			Layout = "Text",
			MaxTextSize = 22,
			OnClick = function()
				if player:GetAttribute("Pass_" .. pass.Key) == true then
					Toasts.Show("Você já tem " .. pass.Name .. "!", "info")
				elseif pass.Id == 0 then
					Toasts.Show("Esse item chega em breve!", "info")
				else
					MarketplaceService:PromptGamePassPurchase(player, pass.Id)
				end
			end,
		})
		buttons[pass.Key] = button
	end

	local function refresh()
		for _, pass in GameConfig.GamePasses do
			local button = buttons[pass.Key]
			if player:GetAttribute("Pass_" .. pass.Key) == true then
				button.SetText("✔ Você tem")
				button.SetEnabled(false)
			elseif pass.Id == 0 then
				button.SetText("Em breve")
				button.SetEnabled(true)
			else
				button.SetText(string.format("R$ %d", pass.Price))
				button.SetEnabled(true)
			end
		end
	end

	for _, pass in GameConfig.GamePasses do
		player:GetAttributeChangedSignal("Pass_" .. pass.Key):Connect(refresh)
	end
	refresh()
	return panel
end

return StorePanel
