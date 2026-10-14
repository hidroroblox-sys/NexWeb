--!strict
-- HatchingPanel: CHOCANDO — lista dos ovos que estão chocando no celeiro,
-- com barra de progresso e tempo restante.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types)
local PlayerData = require(script.Parent.Parent.Parent.PlayerData)
local Theme = require(script.Parent.Parent.Theme)
local UIKit = require(script.Parent.Parent.UIKit)

local HatchingPanel = {}

local Colors = Theme.Colors

type Row = {
	Slot: Types.SlotSnapshot,
	Bar: UIKit.ProgressBar,
}

function HatchingPanel.Create(gui: ScreenGui): UIKit.Panel
	local panel = UIKit.Panel(gui, {
		Name = "ChocandoPanel",
		Title = "CHOCANDO",
		Icon = "Hatching",
		Color = Colors.Orange,
		DarkColor = Colors.OrangeDark,
	})

	local scroll = UIKit.Scroll(panel.Body, UDim2.fromScale(1, 1))
	UIKit.List(scroll, 10).VerticalAlignment = Enum.VerticalAlignment.Top
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = scroll

	local empty = UIKit.Label(panel.Body, {
		Name = "Empty",
		Text = "Nenhum ovo chocando agora.\nPegue ovos no corredor e leve para o seu celeiro! 🥚",
		Color = Colors.Muted,
		Stroke = 0,
		Size = UDim2.new(1, -40, 0, 90),
		Position = UDim2.new(0, 20, 0.5, -45),
		MaxTextSize = 24,
	})

	local rows: { Row } = {}

	local function updateTimers()
		local now = Workspace:GetServerTimeNow()
		for _, row in rows do
			local remaining = row.Slot.HatchAt - now
			local alpha = 1 - remaining / math.max(row.Slot.HatchDuration, 1)
			row.Bar.Set(alpha, if remaining > 0 then "Choca em " .. Format.Time(remaining) else "Chocando...")
		end
	end

	local function rebuild(snapshot: Types.Snapshot?)
		for _, child in scroll:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		table.clear(rows)

		local hatching: { Types.SlotSnapshot } = {}
		local used = 0
		if snapshot then
			for _, slot in snapshot.Slots do
				used += 1
				if not slot.Hatched then
					table.insert(hatching, slot)
				end
			end
		end
		table.sort(hatching, function(a, b)
			return a.HatchAt < b.HatchAt
		end)

		for order, slot in hatching do
			local egg = GameConfig.EggsById[slot.EggId]
			local rarity = GameConfig.RarityById[egg.Rarity]
			local card = UIKit.Card(scroll, "Ovo" .. slot.Index, 88, order, rarity.Color)
			UIKit.Badge(card, "Egg", egg.Color, UDim2.fromOffset(64, 64), UDim2.fromOffset(12, 12))
			UIKit.Label(card, {
				Name = "EggName",
				Text = egg.Name,
				Font = Theme.Fonts.Title,
				Color = Colors.Ink,
				Stroke = 0,
				Size = UDim2.new(0.4, -10, 0, 32),
				Position = UDim2.fromOffset(88, 12),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 24,
			})
			UIKit.Label(card, {
				Name = "Rarity",
				Text = if slot.Mutation and GameConfig.MutationsById[slot.Mutation]
					then string.format("%s • %s • Slot %d", rarity.Name, GameConfig.MutationsById[slot.Mutation].Name, slot.Index)
					else string.format("%s  •  Slot %d", rarity.Name, slot.Index),
				Font = Theme.Fonts.Title,
				Color = rarity.Color,
				Size = UDim2.new(0.4, -10, 0, 26),
				Position = UDim2.fromOffset(88, 48),
				XAlign = Enum.TextXAlignment.Left,
				MaxTextSize = 20,
				Stroke = 2,
			})
			local bar = UIKit.ProgressBar(card, UDim2.new(0.48, 0, 0, 38), UDim2.new(1, -14, 0.5, -19), Colors.Yellow)
			bar.Root.AnchorPoint = Vector2.new(1, 0)
			table.insert(rows, { Slot = slot, Bar = bar })
		end

		empty.Visible = #hatching == 0
		local barnSlots = if snapshot then snapshot.BarnSlots else GameConfig.Barn.StartSlots
		panel.Subtitle.Text = string.format("%d ovo(s)  •  %d livre(s)", #hatching, math.max(0, barnSlots - used))
		updateTimers()
	end

	PlayerData.Changed:Connect(rebuild)
	rebuild(PlayerData.Get())

	-- Atualiza os tempos só com o painel aberto
	task.spawn(function()
		while true do
			if panel.IsOpen() then
				updateTimers()
			end
			task.wait(0.25)
		end
	end)

	return panel
end

-- Quantos ovos estão chocando (para o contador no botão)
function HatchingPanel.CountHatching(snapshot: Types.Snapshot?): number
	local count = 0
	if snapshot then
		for _, slot in snapshot.Slots do
			if not slot.Hatched then
				count += 1
			end
		end
	end
	return count
end

return HatchingPanel
