--!strict
--[[
	IncomeTag: o "$9.44/s" rosa em cima da cabeça de cada jogador, como no vídeo.
	Mostra a renda total por segundo dos animais do cercado (atributo IncomePerSecond,
	calculado pelo BarnService). Todo mundo vê a renda de todo mundo.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)

local IncomeTag = {}

local PINK = Color3.fromRGB(255, 120, 230)
local INK = Color3.fromRGB(60, 10, 60)

function IncomeTag.Attach(player: Player, character: Model)
	local head = character:WaitForChild("Head", 10)
	if not head or not head:IsA("BasePart") or character.Parent == nil then
		return
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "RendaPorSegundo"
	gui.Size = UDim2.fromScale(9, 1.8)
	gui.StudsOffset = Vector3.new(0, 2.8, 0)
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false

	local label = Instance.new("TextLabel")
	label.Name = "Renda"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextColor3 = PINK
	label.Text = ""
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = INK
	stroke.Parent = label
	label.Parent = gui

	local function refresh()
		local income = player:GetAttribute("IncomePerSecond")
		local value = if typeof(income) == "number" then income else 0
		label.Text = Format.PerSecond(value)
	end
	refresh()
	local connection = player:GetAttributeChangedSignal("IncomePerSecond"):Connect(refresh)
	gui.Destroying:Connect(function()
		connection:Disconnect()
	end)
	gui.Parent = head
end

return IncomeTag
