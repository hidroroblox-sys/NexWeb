--!strict
-- IndexPanel: ÍNDICE — todos os animais do jogo por raridade.
-- Descobertos aparecem coloridos; os que faltam, como silhueta "???".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local PlayerData = require(script.Parent.Parent.Parent.PlayerData)
local Theme = require(script.Parent.Parent.Theme)
local UIKit = require(script.Parent.Parent.UIKit)

local IndexPanel = {}

local Colors = Theme.Colors

type CardRefs = {
	Animal: GameConfig.Animal,
	Card: Frame,
	Stroke: UIStroke,
	Icon: TextLabel,
	Name: TextLabel,
	Income: TextLabel,
}

type SectionRefs = {
	Rarity: GameConfig.Rarity,
	Header: TextLabel,
	Cards: { CardRefs },
}

function IndexPanel.Create(gui: ScreenGui): UIKit.Panel
	local panel = UIKit.Panel(gui, {
		Name = "IndicePanel",
		Title = "ÍNDICE",
		Icon = "Index",
		Color = Colors.Blue,
		DarkColor = Colors.BlueDark,
	})

	local scroll = UIKit.Scroll(panel.Body, UDim2.fromScale(1, 1))
	UIKit.List(scroll, 10).VerticalAlignment = Enum.VerticalAlignment.Top
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = scroll

	local sections: { SectionRefs } = {}

	for order, rarity in GameConfig.Rarities do
		local section = UIKit.Frame(scroll, rarity.Id, UDim2.new(1, -12, 0, 0))
		section.AutomaticSize = Enum.AutomaticSize.Y
		section.LayoutOrder = order
		UIKit.List(section, 6, false, Enum.HorizontalAlignment.Left).VerticalAlignment = Enum.VerticalAlignment.Top

		local header = UIKit.Label(section, {
			Name = "Header",
			Text = rarity.Name,
			Font = Theme.Fonts.Title,
			Color = rarity.Color,
			Size = UDim2.new(1, 0, 0, 32),
			XAlign = Enum.TextXAlignment.Left,
			MaxTextSize = 26,
			Stroke = 2.5,
			LayoutOrder = 1,
		})

		local grid = UIKit.Frame(section, "Grid", UDim2.new(1, 0, 0, 0))
		grid.AutomaticSize = Enum.AutomaticSize.Y
		grid.LayoutOrder = 2
		local gridLayout = Instance.new("UIGridLayout")
		gridLayout.CellSize = UDim2.fromOffset(104, 128)
		gridLayout.CellPadding = UDim2.fromOffset(10, 10)
		gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridLayout.Parent = grid

		local cards: { CardRefs } = {}
		for animalOrder, animal in GameConfig.AnimalsByRarity[rarity.Id] do
			local card = UIKit.Frame(grid, animal.Id, UDim2.fromOffset(104, 128), nil, Colors.Card)
			card.LayoutOrder = animalOrder
			UIKit.Corner(card, UDim.new(0, 14))
			local stroke = UIKit.Stroke(card, 3, Colors.Ink, true)
			local icon = UIKit.Label(card, {
				Name = "Icon",
				Text = animal.Icon,
				Size = UDim2.new(1, -16, 0, 56),
				Position = UDim2.fromOffset(8, 6),
				Stroke = 0,
				MaxTextSize = 52,
			})
			local name = UIKit.Label(card, {
				Name = "AnimalName",
				Text = animal.Name,
				Color = Colors.Ink,
				Stroke = 0,
				Size = UDim2.new(1, -10, 0, 34),
				Position = UDim2.fromOffset(5, 62),
				MaxTextSize = 18,
			})
			local income = UIKit.Label(card, {
				Name = "Income",
				Text = Format.PerSecond(animal.Income),
				Font = Theme.Fonts.Title,
				Color = Colors.MoneyDark,
				Stroke = 0,
				Size = UDim2.new(1, -10, 0, 24),
				Position = UDim2.fromOffset(5, 98),
				MaxTextSize = 18,
			})
			table.insert(cards, { Animal = animal, Card = card, Stroke = stroke, Icon = icon, Name = name, Income = income })
		end

		table.insert(sections, { Rarity = rarity, Header = header, Cards = cards })
	end

	local function refresh(snapshot: Types.Snapshot?)
		local index = if snapshot then snapshot.Index else {}
		local found, total = 0, 0
		for _, section in sections do
			local sectionFound = 0
			for _, refs in section.Cards do
				total += 1
				local discovered = index[refs.Animal.Id] == true
				if discovered then
					found += 1
					sectionFound += 1
					refs.Card.BackgroundColor3 = Colors.Card
					refs.Stroke.Color = section.Rarity.Color
					refs.Icon.Text = refs.Animal.Icon
					refs.Icon.TextTransparency = 0
					refs.Name.Text = refs.Animal.Name
					refs.Name.TextColor3 = Colors.Ink
					refs.Income.Text = Format.PerSecond(refs.Animal.Income)
				else
					refs.Card.BackgroundColor3 = Color3.fromRGB(45, 40, 55)
					refs.Stroke.Color = Colors.Ink
					refs.Icon.Text = "?"
					refs.Name.Text = "???"
					refs.Name.TextColor3 = Colors.Gray
					refs.Income.Text = "???"
				end
			end
			section.Header.Text = string.format("%s  (%d/%d)", section.Rarity.Name, sectionFound, #section.Cards)
		end
		panel.Subtitle.Text = string.format("%d/%d descobertos", found, total)
	end

	PlayerData.Changed:Connect(refresh)
	refresh(PlayerData.Get())

	return panel
end

return IndexPanel
