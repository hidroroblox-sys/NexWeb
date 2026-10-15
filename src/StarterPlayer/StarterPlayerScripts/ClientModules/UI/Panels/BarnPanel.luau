--!strict
-- BarnPanel: MEU CERCADO — animais que você tem, quanto cada um dá por segundo
-- e o botão de vender (pede confirmação para animais raros).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local PlayerData = require(script.Parent.Parent.Parent.PlayerData)
local Sounds = require(script.Parent.Parent.Parent.Sounds)
local ConfirmDialog = require(script.Parent.Parent.ConfirmDialog)
local Theme = require(script.Parent.Parent.Theme)
local Toasts = require(script.Parent.Parent.Toasts)
local UIKit = require(script.Parent.Parent.UIKit)

local BarnPanel = {}

local Colors = Theme.Colors

local function sell(slotIndex: number)
	local ok, success, message = pcall(function()
		return Net.SellAnimal:InvokeServer(slotIndex)
	end)
	if not ok then
		Toasts.Show("Erro ao vender. Tente de novo!", "danger")
	elseif typeof(message) == "string" then
		Toasts.Show(message, if success then "success" else "danger")
		if success then
			Sounds.Play("Collect", 1, 0.6)
		end
	end
end

local function levelUp(slotIndex: number)
	local ok, success, message = pcall(function()
		return Net.LevelUp:InvokeServer(slotIndex, 1)
	end)
	if not ok then
		Toasts.Show("Erro ao subir o nível. Tente de novo!", "danger")
	elseif typeof(message) == "string" then
		Toasts.Show(message, if success then "success" else "danger")
		if success then
			Sounds.Play("Collect", 1.3, 0.5)
		end
	end
end

function BarnPanel.Create(gui: ScreenGui): UIKit.Panel
	local panel = UIKit.Panel(gui, {
		Name = "CercadoPanel",
		Title = "MEU CERCADO",
		Icon = "Barn",
		Color = Colors.Purple,
		DarkColor = Colors.PurpleDark,
	})

	local scroll = UIKit.Scroll(panel.Body, UDim2.fromScale(1, 1))
	UIKit.List(scroll, 10).VerticalAlignment = Enum.VerticalAlignment.Top
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = scroll

	local empty = UIKit.Label(panel.Body, {
		Name = "Empty",
		Text = "Nenhum animal ainda.\nChoque ovos no cercado para ganhar animais! 🐣",
		Color = Colors.Muted,
		Stroke = 0,
		Size = UDim2.new(1, -40, 0, 90),
		Position = UDim2.new(0, 20, 0.5, -45),
		MaxTextSize = 24,
	})

	local function rebuild(snapshot: Types.Snapshot?)
		for _, child in scroll:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end

		local animals: { Types.SlotSnapshot } = {}
		local rebirths = if snapshot then snapshot.Rebirths else 0
		local totalIncome = 0
		if snapshot then
			for _, slot in snapshot.Slots do
				if slot.Hatched then
					table.insert(animals, slot)
					totalIncome += Formulas.AnimalIncome(slot.AnimalId, rebirths, slot.Level, slot.Mutation)
				end
			end
		end
		table.sort(animals, function(a, b)
			return Formulas.AnimalIncome(a.AnimalId, rebirths, a.Level, a.Mutation)
				> Formulas.AnimalIncome(b.AnimalId, rebirths, b.Level, b.Mutation)
		end)

		for order, slot in animals do
			local animal = GameConfig.AnimalsById[slot.AnimalId]
			local rarity = GameConfig.RarityById[animal.Rarity]
			local mutation = if slot.Mutation then GameConfig.MutationsById[slot.Mutation] else nil
			local income = Formulas.AnimalIncome(slot.AnimalId, rebirths, slot.Level, slot.Mutation)
			local price = Formulas.SellPrice(slot.AnimalId, slot.Mutation)
			local levelCost, levels = Formulas.LevelUpCost(slot.AnimalId, slot.Level, 1)

			local card = UIKit.Card(scroll, "Animal" .. slot.Index, 104, order, if mutation then mutation.Color else rarity.Color)
			UIKit.Badge(card, animal.Icon, if mutation then mutation.Color else animal.Color, UDim2.fromOffset(70, 70), UDim2.fromOffset(12, 17))
			UIKit.Label(card, {
				Name = "AnimalName",
				Text = animal.Name,
				Font = Theme.Fonts.Title,
				Color = Colors.Ink,
				Stroke = 0,
				Size = UDim2.new(1, -384, 0, 28),
				Position = UDim2.fromOffset(92, 8),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 24,
			})
			UIKit.Label(card, {
				Name = "Rarity",
				Text = if mutation then rarity.Name .. " • " .. mutation.Name else rarity.Name,
				Font = Theme.Fonts.Title,
				Color = if mutation then mutation.Color else rarity.Color,
				Size = UDim2.new(1, -384, 0, 24),
				Position = UDim2.fromOffset(92, 38),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 20,
				Stroke = 2,
			})
			UIKit.Label(card, {
				Name = "Income",
				Text = string.format("%s  •  Nível %d", Format.PerSecond(income), slot.Level),
				Font = Theme.Fonts.Title,
				Color = Colors.Money,
				Size = UDim2.new(1, -384, 0, 28),
				Position = UDim2.fromOffset(92, 66),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 24,
				Stroke = 2.5,
				StrokeColor = Colors.Ink,
			})
			UIKit.Button({
				Name = "LevelUp",
				Parent = card,
				Size = UDim2.fromOffset(134, 76),
				Position = UDim2.new(1, -150, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Color = Colors.Green,
				DarkColor = Colors.GreenDark,
				Text = if levels > 0 then "⬆ Nível\n" .. Format.Money(levelCost) else "Nível\nmáximo",
				Layout = "Text",
				MaxTextSize = 20,
				OnClick = function()
					levelUp(slot.Index)
				end,
			})
			UIKit.Button({
				Name = "Sell",
				Parent = card,
				Size = UDim2.fromOffset(128, 76),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				Color = Colors.Red,
				DarkColor = Colors.RedDark,
				Text = "Vender\n" .. Format.Money(price),
				Layout = "Text",
				MaxTextSize = 20,
				OnClick = function()
					if rarity.Order >= GameConfig.Sell.ConfirmFromRarityOrder or mutation ~= nil then
						ConfirmDialog.Ask(
							string.format("Vender %s %s (%s) por %s?", animal.Icon, animal.Name, rarity.Name, Format.Money(price)),
							"Vender",
							function(confirmed)
								if confirmed then
									sell(slot.Index)
								end
							end
						)
					else
						sell(slot.Index)
					end
				end,
			})
		end

		empty.Visible = #animals == 0
		panel.Subtitle.Text = "Renda: " .. Format.PerSecond(totalIncome)
	end

	PlayerData.Changed:Connect(rebuild)
	rebuild(PlayerData.Get())

	return panel
end

return BarnPanel
