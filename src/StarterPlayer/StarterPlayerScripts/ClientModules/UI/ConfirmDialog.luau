--!strict
-- ConfirmDialog: "Tem certeza?" antes de ações importantes (vender animal raro).

local Theme = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)

local ConfirmDialog = {}

local overlay: Frame
local message: TextLabel
local confirmButton: UIKit.Button
local pending: ((boolean) -> ())? = nil

local function finish(result: boolean)
	local callback = pending
	pending = nil
	overlay.Visible = false
	if callback then
		callback(result)
	end
end

function ConfirmDialog.Ask(text: string, confirmText: string, callback: (boolean) -> ())
	if pending then
		finish(false)
	end
	pending = callback
	message.Text = text
	confirmButton.SetText(confirmText)
	overlay.Visible = true
end

function ConfirmDialog.Start(gui: ScreenGui)
	-- Fundo escuro que bloqueia cliques no resto da tela
	overlay = UIKit.Frame(gui, "ConfirmOverlay", UDim2.fromScale(1, 1), nil, Theme.Colors.Overlay)
	overlay.BackgroundTransparency = 0.45
	overlay.Active = true
	overlay.Visible = false
	overlay.ZIndex = 50

	local box = UIKit.Frame(overlay, "Box", UDim2.fromOffset(440, 230), UDim2.fromScale(0.5, 0.5), Theme.Colors.Cream)
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	UIKit.Corner(box, UDim.new(0, 22))
	UIKit.Stroke(box, 4, Theme.Colors.Ink, true)
	UIKit.ViewportScale(box)

	UIKit.Label(box, {
		Text = "TEM CERTEZA?",
		Font = Theme.Fonts.Title,
		Size = UDim2.new(1, -24, 0, 40),
		Position = UDim2.fromOffset(12, 12),
		Color = Theme.Colors.Orange,
		MaxTextSize = 34,
		Stroke = 3,
	})
	message = UIKit.Label(box, {
		Text = "",
		Size = UDim2.new(1, -32, 0, 70),
		Position = UDim2.fromOffset(16, 56),
		Color = Theme.Colors.Ink,
		Stroke = 0,
		MaxTextSize = 24,
	})

	UIKit.Button({
		Name = "Cancel",
		Parent = box,
		Size = UDim2.fromOffset(180, 64),
		Position = UDim2.new(0.5, -10, 1, -18),
		AnchorPoint = Vector2.new(1, 1),
		Color = Theme.Colors.Gray,
		DarkColor = Theme.Colors.GrayDark,
		Text = "Cancelar",
		Layout = "Text",
		OnClick = function()
			finish(false)
		end,
	})
	confirmButton = UIKit.Button({
		Name = "Confirm",
		Parent = box,
		Size = UDim2.fromOffset(180, 64),
		Position = UDim2.new(0.5, 10, 1, -18),
		AnchorPoint = Vector2.new(0, 1),
		Color = Theme.Colors.Red,
		DarkColor = Theme.Colors.RedDark,
		Text = "Vender",
		Layout = "Text",
		OnClick = function()
			finish(true)
		end,
	})
end

return ConfirmDialog
