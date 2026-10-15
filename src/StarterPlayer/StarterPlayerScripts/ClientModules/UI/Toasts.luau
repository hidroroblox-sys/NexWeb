--!strict
-- Toasts: notificações pop-up no topo ("Você pegou um Ovo de Gelo!").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Types = require(ReplicatedStorage.Shared.Types)
local Sounds = require(script.Parent.Parent.Sounds)
local Theme = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)

local Toasts = {}

local MAX_VISIBLE = 4
local container: Frame
local counter = 0

function Toasts.Show(text: string, kind: string?, color: Color3?)
	if not container then
		return
	end
	counter += 1
	local kinds = Theme.Kinds :: { [string]: Color3 }
	local background = color or kinds[kind or "info"] or Theme.Colors.Blue

	-- Remove os mais antigos se tiver muitos
	local existing = {}
	for _, child in container:GetChildren() do
		if child:IsA("Frame") then
			table.insert(existing, child)
		end
	end
	table.sort(existing, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #existing >= MAX_VISIBLE do
		local oldest = table.remove(existing, 1)
		if oldest then
			oldest:Destroy()
		end
	end

	local toast = UIKit.Frame(container, "Toast", UDim2.new(1, 0, 0, 46), nil, Theme.Colors.White)
	toast.LayoutOrder = counter
	UIKit.Corner(toast, UDim.new(0, 14))
	UIKit.Stroke(toast, 3, Theme.Colors.Ink, true)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	-- fundo escuro para cores muito claras (ex.: Comum), mantendo contraste
	local base = if (0.299 * background.R + 0.587 * background.G + 0.114 * background.B) > 0.8
		then Theme.Darken(background, 0.45)
		else background
	gradient.Color = ColorSequence.new(Theme.Lighten(base, 0.2), Theme.Darken(base, 0.1))
	gradient.Parent = toast
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = toast
	UIKit.Label(toast, {
		Text = text,
		Font = Theme.Fonts.Title,
		Size = UDim2.new(1, -20, 1, -10),
		Position = UDim2.fromOffset(10, 5),
		MaxTextSize = 24,
		Stroke = 2.5,
		StrokeColor = Theme.Colors.Ink,
	})

	UIKit.Tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(3.2, function()
		if toast.Parent then
			UIKit.Tween(scale, 0.18, { Scale = 0.7 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			UIKit.Tween(toast, 0.18, { BackgroundTransparency = 1 })
			task.wait(0.2)
			toast:Destroy()
		end
	end)
end

function Toasts.Start(gui: ScreenGui)
	container = UIKit.Frame(gui, "Toasts", UDim2.fromOffset(460, 220), UDim2.new(0.5, 0, 0.26, 0)) -- abaixo do topo do HUD
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.ZIndex = 30 -- acima dos painéis
	UIKit.ViewportScale(container)
	local layout = UIKit.List(container, 6)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	Net.Notify.OnClientEvent:Connect(function(payload: Types.NotifyPayload)
		if typeof(payload) ~= "table" or typeof(payload.Text) ~= "string" then
			return
		end
		Toasts.Show(payload.Text, payload.Kind, payload.Color)
		if payload.Kind == "danger" then
			Sounds.Play("Error", 0.8)
		elseif payload.Kind == "rarity" or payload.Kind == "success" then
			Sounds.Play("Pickup", 1.3)
		end
	end)
end

return Toasts
