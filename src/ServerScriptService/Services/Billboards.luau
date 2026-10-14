--!strict
--[[
	Billboards: placas que flutuam em cima dos ovos e animais.
	O texto que muda o tempo todo (contagem do chocar, "???" do índice)
	é atualizado pelo CLIENTE (WorldFx), para não pesar a rede.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local Billboards = {}

local INK = Color3.fromRGB(28, 22, 40)

local function strokeColorFor(color: Color3): Color3
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return if luminance < 0.3 then Color3.new(1, 1, 1) else INK
end

local function label(parent: Instance, name: string, text: string, color: Color3, font: Enum.Font, size: UDim2, position: UDim2): TextLabel
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = name
	textLabel.BackgroundTransparency = 1
	textLabel.Size = size
	textLabel.Position = position
	textLabel.Font = font
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = strokeColorFor(color)
	stroke.Parent = textLabel
	textLabel.Parent = parent
	return textLabel
end

local function newBillboard(name: string, size: UDim2, offsetY: number, maxDistance: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Size = size
	gui.StudsOffset = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	return gui
end

local function mutationText(mutationId: string?): (string?, Color3?)
	if not mutationId then
		return nil, nil
	end
	local mutation = GameConfig.MutationsById[mutationId]
	if not mutation then
		return nil, nil
	end
	return mutation.Name, mutation.Color
end

-- Ovo no corredor: nome, raridade, mutação e $/s do animal (ou "???")
function Billboards.WorldEgg(eggId: string, animalId: string, mutationId: string?, lucky: boolean?): BillboardGui
	local egg = GameConfig.EggsById[eggId]
	local rarity = GameConfig.RarityById[egg.Rarity]
	local gui = newBillboard("EggInfo", UDim2.fromScale(7, 3.2), 3.4, 80)
	local title = if lucky then "Ninho Surpresa" else egg.Name
	label(gui, "Name", title, Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.fromScale(1, 0.3), UDim2.fromScale(0, 0))
	label(gui, "Rarity", rarity.Name, rarity.Color, Enum.Font.LuckiestGuy, UDim2.fromScale(1, 0.27), UDim2.fromScale(0, 0.28))
	local mutation, mutationColor = mutationText(mutationId)
	if mutation and mutationColor and not lucky then
		label(gui, "Mutation", mutation, mutationColor, Enum.Font.LuckiestGuy, UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.54))
	end
	local income = label(gui, "Income", if lucky then "?" else "???", Color3.fromRGB(110, 255, 80), Enum.Font.FredokaOne, UDim2.fromScale(1, 0.24), UDim2.fromScale(0, 0.76))
	if not lucky then
		income:SetAttribute("AnimalId", animalId)
		income:SetAttribute("Mutation", mutationId)
		CollectionService:AddTag(income, "EggIncomeLabel")
	end
	return gui
end

-- Ovo chocando no celeiro: nome + barra + "Choca em 2:30"
function Billboards.Hatching(eggId: string, hatchAt: number, duration: number, mutationId: string?): BillboardGui
	local egg = GameConfig.EggsById[eggId]
	local rarity = GameConfig.RarityById[egg.Rarity]
	local gui = newBillboard("HatchInfo", UDim2.fromScale(6.5, 2.4), 3, 60)
	local mutation = mutationText(mutationId)
	local title = if mutation then egg.Name .. " " .. mutation else egg.Name
	label(gui, "Name", title, rarity.Color, Enum.Font.LuckiestGuy, UDim2.fromScale(1, 0.4), UDim2.fromScale(0, 0))

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BackgroundColor3 = INK
	bar.BackgroundTransparency = 0.2
	bar.Size = UDim2.fromScale(0.95, 0.45)
	bar.Position = UDim2.fromScale(0.025, 0.47)
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.5, 0)
	barCorner.Parent = bar
	local barStroke = Instance.new("UIStroke")
	barStroke.Color = INK
	barStroke.Thickness = 2
	barStroke.Parent = bar
	bar.Parent = gui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	fill.Size = UDim2.fromScale(0, 1)
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0.5, 0)
	fillCorner.Parent = fill
	fill.Parent = bar

	label(bar, "Timer", "Choca em " .. Format.Time(duration), Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.fromScale(1, 0.9), UDim2.fromScale(0, 0.05))

	gui:SetAttribute("HatchAt", hatchAt)
	gui:SetAttribute("HatchDuration", duration)
	CollectionService:AddTag(gui, "HatchTimer")
	return gui
end

-- Animal no celeiro: nome, raridade (+mutação), $/s e nível
function Billboards.Animal(animalId: string, income: number, level: number, mutationId: string?): BillboardGui
	local animal = GameConfig.AnimalsById[animalId]
	local rarity = GameConfig.RarityById[animal.Rarity]
	local gui = newBillboard("AnimalInfo", UDim2.fromScale(7, 3.2), 4, 60)
	label(gui, "Name", animal.Name, Color3.new(1, 1, 1), Enum.Font.FredokaOne, UDim2.fromScale(1, 0.28), UDim2.fromScale(0, 0))
	local mutation, mutationColor = mutationText(mutationId)
	local rarityText = if mutation then rarity.Name .. " • " .. mutation else rarity.Name
	label(gui, "Rarity", rarityText, mutationColor or rarity.Color, Enum.Font.LuckiestGuy, UDim2.fromScale(1, 0.24), UDim2.fromScale(0, 0.27))
	label(gui, "Income", Format.PerSecond(income), Color3.fromRGB(110, 255, 80), Enum.Font.FredokaOne, UDim2.fromScale(1, 0.26), UDim2.fromScale(0, 0.5))
	label(gui, "Level", "Nv. " .. level, Color3.fromRGB(255, 220, 90), Enum.Font.LuckiestGuy, UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.77))
	return gui
end

-- Placa grande com texto em uma face de uma peça
-- pixelsPerStud menor = letras maiores (texto escala até ~100 px)
function Billboards.SurfaceText(
	part: BasePart,
	face: Enum.NormalId,
	text: string,
	color: Color3,
	font: Enum.Font?,
	pixelsPerStud: number?
): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Text_" .. face.Name
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 30
	gui.LightInfluence = 0
	local textLabel = label(gui, "Label", text, color, font or Enum.Font.LuckiestGuy, UDim2.fromScale(0.96, 0.9), UDim2.fromScale(0.02, 0.05))
	local stroke = textLabel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = 4
	end
	gui.Parent = part
	return textLabel
end

return Billboards
