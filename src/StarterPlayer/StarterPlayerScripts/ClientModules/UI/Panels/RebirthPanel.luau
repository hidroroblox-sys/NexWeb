--!strict
-- RebirthPanel: REBIRTH (botão roxo, como no original)
--   • precisa de Velocidade 40 no 1º, +10 a cada rebirth
--   • zera só a Velocidade; ovos, animais, dinheiro e slots ficam
--   • dinheiro multiplicado: 1,5x, 2x, 2,5x ... 11x no Rebirth 20

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local Sounds = require(script.Parent.Parent.Parent.Sounds)
local Theme = require(script.Parent.Parent.Theme)
local Toasts = require(script.Parent.Parent.Toasts)
local UIKit = require(script.Parent.Parent.UIKit)

local RebirthPanel = {}

local player = Players.LocalPlayer
local Colors = Theme.Colors

local function attribute(name: string, default: number): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

local function multiplierText(value: number): string
	local text = string.format("%.2f", value)
	text = (string.gsub(text, "0+$", ""))
	text = (string.gsub(text, "%.$", ""))
	return text .. "x"
end

function RebirthPanel.Create(gui: ScreenGui): UIKit.Panel
	local panel = UIKit.Panel(gui, {
		Name = "RebirthPanel",
		Title = "REBIRTH",
		Icon = "🔁",
		Color = Colors.Purple,
		DarkColor = Colors.PurpleDark,
	})

	local body = panel.Body
	local current = UIKit.Label(body, {
		Name = "Atual",
		Font = Theme.Fonts.Title,
		Color = Colors.Ink,
		Stroke = 0,
		Size = UDim2.new(1, 0, 0, 36),
		MaxTextSize = 30,
	})
	local multipliers = UIKit.Label(body, {
		Name = "Multiplicador",
		Font = Theme.Fonts.Title,
		Color = Colors.Purple,
		Size = UDim2.new(1, 0, 0, 52),
		Position = UDim2.fromOffset(0, 38),
		MaxTextSize = 46,
		Stroke = 3,
		StrokeColor = Colors.Ink,
	})
	local requirement = UIKit.Label(body, {
		Name = "Requisito",
		Color = Colors.Ink,
		Stroke = 0,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 96),
		MaxTextSize = 22,
	})
	local bar = UIKit.ProgressBar(body, UDim2.new(0.8, 0, 0, 36), UDim2.new(0.1, 0, 0, 128), Colors.Purple)
	UIKit.Label(body, {
		Name = "Aviso",
		Text = "Sua Velocidade volta para 16. Ovos, animais, dinheiro e slots continuam com você!",
		Color = Colors.Muted,
		Stroke = 0,
		Size = UDim2.new(1, -20, 0, 44),
		Position = UDim2.fromOffset(10, 172),
		MaxTextSize = 19,
	})

	local button = UIKit.Button({
		Name = "Renascer",
		Parent = body,
		Size = UDim2.fromOffset(260, 84),
		Position = UDim2.new(0.5, 0, 1, -4),
		AnchorPoint = Vector2.new(0.5, 1),
		Color = Colors.Purple,
		DarkColor = Colors.PurpleDark,
		Icon = "🔁",
		Text = "REBIRTH",
		Layout = "Row",
		MaxTextSize = 34,
	})

	local function refresh()
		local rebirths = attribute("Rebirths", 0)
		local level = attribute("SpeedLevel", 0)
		local speed = Formulas.WalkSpeed(level)
		local target = rebirths + 1
		current.Text = string.format("Rebirth %d  •  Dinheiro %s", rebirths, multiplierText(Formulas.IncomeMultiplier(rebirths)))
		if target > GameConfig.Rebirth.MaxRebirths then
			multipliers.Text = "MÁXIMO!"
			requirement.Text = "Você fez todos os rebirths."
			bar.Set(1, "Completo")
			button.SetEnabled(false)
			return
		end
		local required = Formulas.RebirthSpeed(target)
		multipliers.Text = string.format(
			"%s ➜ %s",
			multiplierText(Formulas.IncomeMultiplier(rebirths)),
			multiplierText(Formulas.IncomeMultiplier(target))
		)
		requirement.Text = string.format("Precisa de Velocidade %d", required)
		bar.Set(speed / required, string.format("Velocidade %d / %d", speed, required))
		button.SetEnabled(speed >= required)
		panel.Subtitle.Text = string.format("Próximo: %d", target)
	end

	button.Face.Activated:Connect(function()
		if not button.IsEnabled() then
			Sounds.Play("Error", 0.7)
			Toasts.Show("Compre mais Velocidade no anel ciano para fazer o rebirth!", "warning")
			return
		end
		button.SetEnabled(false)
		local ok, success, message = pcall(function()
			return Net.Rebirth:InvokeServer()
		end)
		if not ok then
			Toasts.Show("Erro no rebirth. Tente de novo!", "danger")
		elseif typeof(message) == "string" then
			Toasts.Show(message, if success then "rarity" else "danger", if success then Colors.Purple else nil)
			if success then
				Sounds.Play("Hatch", 0.8, 0.8)
				panel.Close()
			end
		end
		refresh()
	end)

	for _, name in { "Rebirths", "SpeedLevel" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
	return panel
end

return RebirthPanel
