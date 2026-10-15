--!strict
--[[
	UIKit: peças de interface reutilizáveis.
	  • Button   — botão "gordinho" 3D (sombra embaixo, afunda ao apertar)
	  • Panel    — janela com cabeçalho colorido e botão X
	  • Pill     — cápsula escura com ícone + texto (dinheiro, velocidade...)
	  • ProgressBar, Label, Icon, Scroll
	  • ViewportScale — escala a interface pelo tamanho da tela (celular/PC)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Signal = require(ReplicatedStorage.Shared.Signal)
local Theme = require(script.Parent.Theme)

local UIKit = {}

local Colors = Theme.Colors

-- ---------------------------------------------------------------------
-- Básicos
-- ---------------------------------------------------------------------

function UIKit.Tween(instance: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

function UIKit.Corner(parent: Instance, radius: UDim?): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, Theme.Sizes.Corner)
	corner.Parent = parent
	return corner
end

function UIKit.Stroke(parent: Instance, thickness: number?, color: Color3?, border: boolean?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or Theme.Sizes.Stroke
	stroke.Color = color or Colors.Ink
	stroke.ApplyStrokeMode = if border then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

function UIKit.Frame(parent: Instance?, name: string, size: UDim2, position: UDim2?, color: Color3?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position or UDim2.new()
	frame.BorderSizePixel = 0
	if color then
		frame.BackgroundColor3 = color
	else
		frame.BackgroundTransparency = 1
	end
	frame.Parent = parent
	return frame
end

export type LabelProps = {
	Name: string?,
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	Font: Enum.Font?,
	Color: Color3?,
	StrokeColor: Color3?,
	Stroke: number?, -- 0 = sem contorno
	MaxTextSize: number?,
	XAlign: Enum.TextXAlignment?,
	YAlign: Enum.TextYAlignment?,
	LayoutOrder: number?,
	ZIndex: number?,
	RichText: boolean?,
}

function UIKit.Label(parent: Instance?, props: LabelProps): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.BackgroundTransparency = 1
	label.Text = props.Text or ""
	label.Size = props.Size or UDim2.fromScale(1, 1)
	label.Position = props.Position or UDim2.new()
	label.AnchorPoint = props.AnchorPoint or Vector2.zero
	label.Font = props.Font or Theme.Fonts.Body
	label.TextColor3 = props.Color or Colors.White
	label.TextScaled = true
	label.TextWrapped = true
	label.RichText = props.RichText == true
	label.TextXAlignment = props.XAlign or Enum.TextXAlignment.Center
	label.TextYAlignment = props.YAlign or Enum.TextYAlignment.Center
	label.LayoutOrder = props.LayoutOrder or 0
	label.ZIndex = props.ZIndex or 1
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = props.MaxTextSize or 48
	limit.Parent = label
	local strokeSize = props.Stroke or 2
	if strokeSize > 0 then
		local color = props.Color or Colors.White
		UIKit.Stroke(label, strokeSize, props.StrokeColor or Theme.StrokeFor(color))
	end
	label.Parent = parent
	return label
end

-- Ícone: usa imagem se existir em Theme.Images, senão o emoji
function UIKit.Icon(parent: Instance?, icon: string, size: UDim2, position: UDim2?): GuiObject
	local image = Theme.Images[icon]
	if image then
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "Icon"
		imageLabel.BackgroundTransparency = 1
		imageLabel.Image = image
		imageLabel.ScaleType = Enum.ScaleType.Fit
		imageLabel.Size = size
		imageLabel.Position = position or UDim2.new()
		imageLabel.Parent = parent
		return imageLabel
	end
	local text = (Theme.Icons :: { [string]: string })[icon] or icon
	local label = UIKit.Label(parent, {
		Name = "Icon",
		Text = text,
		Size = size,
		Position = position,
		Stroke = 0,
		MaxTextSize = 64,
	})
	return label
end

function UIKit.Scroll(parent: Instance?, size: UDim2, position: UDim2?): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = size
	scroll.Position = position or UDim2.new()
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = 8
	scroll.ScrollBarImageColor3 = Colors.Ink
	scroll.ScrollBarImageTransparency = 0.4
	scroll.Parent = parent
	return scroll
end

function UIKit.List(parent: Instance, padding: number, horizontal: boolean?, align: Enum.HorizontalAlignment?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, padding)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	layout.HorizontalAlignment = align or Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = parent
	return layout
end

function UIKit.Padding(parent: Instance, pixels: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = parent
end

-- ---------------------------------------------------------------------
-- Escala pela tela
-- ---------------------------------------------------------------------

local scaled: { UIScale } = {}
local currentScale = 1

local function computeScale(): number
	local camera = Workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else Vector2.new(1280, 720)
	local scale = math.min(size.Y / Theme.DesignHeight, size.X / Theme.DesignWidth)
	return math.clamp(scale, Theme.MinScale, Theme.MaxScale)
end

local function refreshScale()
	currentScale = computeScale()
	for _, uiScale in scaled do
		uiScale.Scale = currentScale
	end
end

local cameraConnection: RBXScriptConnection? = nil
local function watchCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	local camera = Workspace.CurrentCamera
	if camera then
		cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
	end
	refreshScale()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

function UIKit.ViewportScale(guiObject: GuiObject): UIScale
	local uiScale = Instance.new("UIScale")
	uiScale.Name = "ViewportScale"
	uiScale.Scale = currentScale
	uiScale.Parent = guiObject
	table.insert(scaled, uiScale)
	return uiScale
end

function UIKit.GetScale(): number
	return currentScale
end

-- ---------------------------------------------------------------------
-- Botão 3D
-- ---------------------------------------------------------------------

export type ButtonProps = {
	Name: string?,
	Parent: Instance?,
	Size: UDim2,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	Color: Color3,
	DarkColor: Color3?,
	Icon: string?,
	Text: string?,
	Layout: string?, -- "Stack" (ícone em cima) | "Row" (ícone à esquerda) | "Text"
	MaxTextSize: number?,
	OnClick: (() -> ())?,
}

export type Button = {
	Holder: Frame,
	Face: TextButton,
	Label: TextLabel?,
	SetText: (text: string) -> (),
	SetEnabled: (enabled: boolean) -> (),
	SetColor: (color: Color3, dark: Color3?) -> (),
	SetBadge: (text: string?) -> (),
	IsEnabled: () -> boolean,
}

local function gradientFor(color: Color3): ColorSequence
	return ColorSequence.new(Theme.Lighten(color, 0.28), color)
end

function UIKit.Button(props: ButtonProps): Button
	local depth = Theme.Sizes.ButtonDepth
	local color = props.Color
	local dark = props.DarkColor or Theme.Darken(color, 0.35)
	local enabled = true

	local holder = UIKit.Frame(nil, props.Name or "Button", props.Size, props.Position)
	holder.AnchorPoint = props.AnchorPoint or Vector2.zero
	holder.LayoutOrder = props.LayoutOrder or 0
	local hoverScale = Instance.new("UIScale")
	hoverScale.Parent = holder

	local shadow = UIKit.Frame(holder, "Shadow", UDim2.new(1, 0, 1, -depth), UDim2.fromOffset(0, depth), dark)
	UIKit.Corner(shadow)
	UIKit.Stroke(shadow, Theme.Sizes.Stroke, Colors.Ink, true)

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.Text = ""
	face.AutoButtonColor = false
	face.BorderSizePixel = 0
	face.BackgroundColor3 = Colors.White
	face.Size = UDim2.new(1, 0, 1, -depth)
	face.Parent = holder
	UIKit.Corner(face)
	UIKit.Stroke(face, Theme.Sizes.Stroke, Colors.Ink, true)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = gradientFor(color)
	gradient.Parent = face

	-- brilho no topo (visual "brinquedo")
	local shine = UIKit.Frame(face, "Shine", UDim2.new(1, -14, 0.28, 0), UDim2.fromOffset(7, 4), Colors.White)
	shine.BackgroundTransparency = 0.72
	UIKit.Corner(shine, UDim.new(0.5, 0))

	local layout = props.Layout or (if props.Icon and props.Text then "Stack" elseif props.Icon then "Icon" else "Text")
	local label: TextLabel? = nil
	if layout == "Stack" then
		UIKit.Icon(face, props.Icon or "", UDim2.new(1, 0, 0.56, 0), UDim2.fromScale(0, 0.04))
		label = UIKit.Label(face, {
			Name = "Text",
			Text = props.Text,
			Font = Theme.Fonts.Title,
			Size = UDim2.new(1, -8, 0.32, 0),
			Position = UDim2.new(0, 4, 0.6, 0),
			MaxTextSize = props.MaxTextSize or 22,
		})
	elseif layout == "Row" then
		local iconSize = UDim2.new(0.3, 0, 0.8, 0)
		UIKit.Icon(face, props.Icon or "", iconSize, UDim2.fromScale(0.04, 0.1))
		label = UIKit.Label(face, {
			Name = "Text",
			Text = props.Text,
			Font = Theme.Fonts.Title,
			Size = UDim2.new(0.62, 0, 0.7, 0),
			Position = UDim2.fromScale(0.34, 0.15),
			MaxTextSize = props.MaxTextSize or 26,
		})
	elseif layout == "Icon" then
		UIKit.Icon(face, props.Icon or "", UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.1, 0.1))
	else
		label = UIKit.Label(face, {
			Name = "Text",
			Text = props.Text,
			Font = Theme.Fonts.Title,
			Size = UDim2.new(1, -12, 0.78, 0),
			Position = UDim2.new(0, 6, 0.11, 0),
			MaxTextSize = props.MaxTextSize or 26,
		})
	end

	-- Bolinha vermelha de notificação (ou contador)
	local badge = UIKit.Frame(holder, "Badge", UDim2.fromOffset(28, 28), UDim2.new(1, -4, 0, 4), Colors.Red)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Visible = false
	badge.ZIndex = 5
	UIKit.Corner(badge, UDim.new(0.5, 0))
	UIKit.Stroke(badge, 2.5, Colors.White, true)
	local badgeLabel = UIKit.Label(badge, {
		Name = "Count",
		Text = "!",
		Font = Theme.Fonts.Title,
		Size = UDim2.fromScale(0.8, 0.8),
		Position = UDim2.fromScale(0.1, 0.12),
		MaxTextSize = 18,
		Stroke = 1.5,
		ZIndex = 6,
	})

	-- Animação de apertar
	local pressed = false
	local function press(down: boolean)
		if pressed == down then
			return
		end
		pressed = down
		local offset = if down then math.floor(depth * 0.75) else 0
		UIKit.Tween(face, if down then 0.06 else 0.14, { Position = UDim2.fromOffset(0, offset) }, if down then Enum.EasingStyle.Quad else Enum.EasingStyle.Back)
	end

	face.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if enabled then
				press(true)
			end
		end
	end)
	face.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			press(false)
		end
	end)
	face.MouseEnter:Connect(function()
		if enabled then
			UIKit.Tween(hoverScale, 0.12, { Scale = 1.05 })
		end
	end)
	face.MouseLeave:Connect(function()
		press(false)
		UIKit.Tween(hoverScale, 0.12, { Scale = 1 })
	end)

	local lastClick = 0
	face.Activated:Connect(function()
		if not enabled then
			return
		end
		local now = os.clock()
		if now - lastClick < 0.15 then
			return
		end
		lastClick = now
		if props.OnClick then
			task.spawn(props.OnClick)
		end
	end)

	holder.Parent = props.Parent

	local button: Button
	button = {
		Holder = holder,
		Face = face,
		Label = label,
		SetText = function(text: string)
			if label then
				label.Text = text
			end
		end,
		SetEnabled = function(value: boolean)
			enabled = value
			gradient.Color = gradientFor(if value then color else Colors.Gray)
			shadow.BackgroundColor3 = if value then dark else Colors.GrayDark
			face.AutoButtonColor = false
			if not value then
				press(false)
			end
		end,
		SetColor = function(newColor: Color3, newDark: Color3?)
			color = newColor
			dark = newDark or Theme.Darken(newColor, 0.35)
			if enabled then
				gradient.Color = gradientFor(color)
				shadow.BackgroundColor3 = dark
			end
		end,
		SetBadge = function(text: string?)
			if text == nil then
				badge.Visible = false
				return
			end
			badge.Visible = true
			badgeLabel.Text = if text == "" then "!" else text
		end,
		IsEnabled = function()
			return enabled
		end,
	}
	return button
end

-- ---------------------------------------------------------------------
-- Ladrilho do HUD (como no vídeo): quadrado escuro, ícone grande e nome embaixo
-- ---------------------------------------------------------------------

export type TileProps = {
	Name: string,
	Parent: Instance,
	LayoutOrder: number,
	Icon: string,
	Text: string,
	Highlight: Color3?, -- borda colorida (ex.: dourada na Loja)
	Tag: string?, -- etiqueta vermelha em cima (ex.: "Novo")
	OnClick: () -> (),
}

export type Tile = {
	Holder: Frame,
	Face: TextButton,
	SetBadge: (text: string?) -> (),
}

local TILE_BG = Color3.fromRGB(52, 46, 44)
local TILE_EDGE = Color3.fromRGB(18, 15, 14)
local TILE_INNER = Color3.fromRGB(95, 86, 80)

function UIKit.Tile(props: TileProps): Tile
	local holder = UIKit.Frame(props.Parent, props.Name, UDim2.fromScale(1, 1))
	holder.LayoutOrder = props.LayoutOrder
	local pressScale = Instance.new("UIScale")
	pressScale.Parent = holder

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.Text = ""
	face.AutoButtonColor = false
	face.BorderSizePixel = 0
	face.BackgroundColor3 = TILE_BG
	face.BackgroundTransparency = 0.12
	face.Size = UDim2.fromScale(1, 1)
	face.Parent = holder
	UIKit.Corner(face, UDim.new(0, 10))
	UIKit.Stroke(face, 3, props.Highlight or TILE_EDGE, true)

	local inner = UIKit.Frame(face, "Borda", UDim2.new(1, -8, 1, -8), UDim2.fromOffset(4, 4))
	UIKit.Corner(inner, UDim.new(0, 7))
	UIKit.Stroke(inner, 1.5, props.Highlight or TILE_INNER, true)

	UIKit.Icon(face, props.Icon, UDim2.fromScale(0.74, 0.58), UDim2.fromScale(0.13, 0.06))
	UIKit.Label(face, {
		Name = "Text",
		Text = props.Text,
		Font = Theme.Fonts.Title,
		Size = UDim2.new(1, -6, 0.3, 0),
		Position = UDim2.new(0, 3, 0.66, 0),
		MaxTextSize = 20,
		Stroke = 2,
		StrokeColor = Colors.Ink,
	})

	if props.Tag then
		local tag = UIKit.Frame(holder, "Etiqueta", UDim2.new(0.62, 0, 0, 20), UDim2.new(0.5, 0, 0, -6), Colors.Red)
		tag.AnchorPoint = Vector2.new(0.5, 0.5)
		tag.ZIndex = 4
		UIKit.Corner(tag, UDim.new(0, 6))
		UIKit.Stroke(tag, 2, Colors.Ink, true)
		UIKit.Label(tag, {
			Name = "Texto",
			Text = props.Tag,
			Font = Theme.Fonts.Title,
			Size = UDim2.fromScale(0.9, 0.85),
			Position = UDim2.fromScale(0.05, 0.08),
			MaxTextSize = 16,
			Stroke = 1.5,
			ZIndex = 5,
		})
	end

	local badge = UIKit.Frame(holder, "Badge", UDim2.fromOffset(26, 26), UDim2.new(1, -2, 0, 2), Colors.Red)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Visible = false
	badge.ZIndex = 6
	UIKit.Corner(badge, UDim.new(0.5, 0))
	UIKit.Stroke(badge, 2.5, Colors.White, true)
	local badgeLabel = UIKit.Label(badge, {
		Name = "Count",
		Text = "!",
		Font = Theme.Fonts.Title,
		Size = UDim2.fromScale(0.8, 0.8),
		Position = UDim2.fromScale(0.1, 0.12),
		MaxTextSize = 17,
		Stroke = 1.5,
		ZIndex = 7,
	})

	face.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			UIKit.Tween(pressScale, 0.06, { Scale = 0.92 })
		end
	end)
	face.InputEnded:Connect(function()
		UIKit.Tween(pressScale, 0.16, { Scale = 1 }, Enum.EasingStyle.Back)
	end)
	face.MouseEnter:Connect(function()
		UIKit.Tween(pressScale, 0.12, { Scale = 1.06 })
	end)
	face.MouseLeave:Connect(function()
		UIKit.Tween(pressScale, 0.12, { Scale = 1 })
	end)
	local lastClick = 0
	face.Activated:Connect(function()
		local now = os.clock()
		if now - lastClick < 0.15 then
			return
		end
		lastClick = now
		task.spawn(props.OnClick)
	end)

	return {
		Holder = holder,
		Face = face,
		SetBadge = function(text: string?)
			badge.Visible = text ~= nil
			if text ~= nil then
				badgeLabel.Text = if text == "" then "!" else text
			end
		end,
	}
end

-- ---------------------------------------------------------------------
-- Cápsula (HUD)
-- ---------------------------------------------------------------------

export type Pill = {
	Root: Frame,
	Label: TextLabel,
	Pop: () -> (),
}

function UIKit.Pill(parent: Instance?, name: string, size: UDim2, icon: string, text: string, textColor: Color3?): Pill
	local root = UIKit.Frame(parent, name, size, nil, Colors.Ink)
	root.BackgroundTransparency = 0.25
	UIKit.Corner(root, UDim.new(0.5, 0))
	UIKit.Stroke(root, 2, Colors.Ink, true)
	local popScale = Instance.new("UIScale")
	popScale.Parent = root

	local height = size.Y.Offset
	UIKit.Icon(root, icon, UDim2.new(0, height - 8, 1, -8), UDim2.fromOffset(6, 4))
	local label = UIKit.Label(root, {
		Name = "Value",
		Text = text,
		Font = Theme.Fonts.Title,
		Color = textColor or Colors.White,
		Size = UDim2.new(1, -(height + 10), 1, -10),
		Position = UDim2.fromOffset(height + 2, 5),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 30,
		Stroke = 2.5,
	})

	return {
		Root = root,
		Label = label,
		Pop = function()
			popScale.Scale = 1.12
			UIKit.Tween(popScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		end,
	}
end

-- ---------------------------------------------------------------------
-- Barra de progresso
-- ---------------------------------------------------------------------

export type ProgressBar = {
	Root: Frame,
	Set: (alpha: number, text: string) -> (),
}

function UIKit.ProgressBar(parent: Instance?, size: UDim2, position: UDim2?, color: Color3?): ProgressBar
	local root = UIKit.Frame(parent, "Progress", size, position, Colors.Ink)
	root.BackgroundTransparency = 0.15
	UIKit.Corner(root, UDim.new(0.5, 0))
	UIKit.Stroke(root, 2, Colors.Ink, true)
	local fill = UIKit.Frame(root, "Fill", UDim2.fromScale(0, 1), nil, color or Colors.Yellow)
	UIKit.Corner(fill, UDim.new(0.5, 0))
	local label = UIKit.Label(root, {
		Name = "Text",
		Size = UDim2.new(1, -8, 1, -4),
		Position = UDim2.fromOffset(4, 2),
		MaxTextSize = 20,
	})
	return {
		Root = root,
		Set = function(alpha: number, text: string)
			fill.Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1)
			label.Text = text
		end,
	}
end

-- ---------------------------------------------------------------------
-- Painel (janela)
-- ---------------------------------------------------------------------

export type PanelProps = {
	Name: string,
	Title: string,
	Icon: string,
	Color: Color3,
	DarkColor: Color3?,
	Width: number?,
	Height: number?,
}

export type Panel = {
	Root: Frame,
	Body: Frame,
	Subtitle: TextLabel,
	IsOpen: () -> boolean,
	Open: () -> (),
	Close: () -> (),
	Opened: Signal.Signal<>,
	Closed: Signal.Signal<>,
}

function UIKit.Panel(parent: Instance, props: PanelProps): Panel
	local width = props.Width or 620
	local height = props.Height or 410
	local root = UIKit.Frame(parent, props.Name, UDim2.fromOffset(width, height), UDim2.new(0.5, 0, 0.5, 12))
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Visible = false
	root.ZIndex = 20
	UIKit.ViewportScale(root)

	local window = UIKit.Frame(root, "Window", UDim2.fromScale(1, 1), nil, Colors.Cream)
	UIKit.Corner(window, UDim.new(0, 24))
	UIKit.Stroke(window, 4, Colors.Ink, true)
	local pop = Instance.new("UIScale")
	pop.Parent = window

	-- Cabeçalho colorido
	local header = UIKit.Frame(window, "Header", UDim2.new(1, 0, 0, 64), nil, Colors.White)
	UIKit.Corner(header, UDim.new(0, 24))
	local headerGradient = Instance.new("UIGradient")
	headerGradient.Rotation = 90
	headerGradient.Color = ColorSequence.new(Theme.Lighten(props.Color, 0.2), props.Color)
	headerGradient.Parent = header
	local cover = UIKit.Frame(header, "Cover", UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 1, -24), props.Color)
	cover.BorderSizePixel = 0
	local divider = UIKit.Frame(window, "Divider", UDim2.new(1, 0, 0, 4), UDim2.fromOffset(0, 64), Colors.Ink)
	divider.BorderSizePixel = 0

	UIKit.Icon(header, props.Icon, UDim2.fromOffset(46, 46), UDim2.fromOffset(16, 9))
	UIKit.Label(header, {
		Name = "Title",
		Text = props.Title,
		Font = Theme.Fonts.Title,
		Size = UDim2.new(0.55, -70, 0, 44),
		Position = UDim2.fromOffset(70, 10),
		XAlign = Enum.TextXAlignment.Left,
		MaxTextSize = 38,
		Stroke = 3,
	})
	local subtitle = UIKit.Label(header, {
		Name = "Subtitle",
		Text = "",
		Size = UDim2.new(0.45, -40, 0, 30),
		Position = UDim2.new(0.55, -24, 0, 17),
		XAlign = Enum.TextXAlignment.Right,
		MaxTextSize = 22,
		Stroke = 2,
	})

	local body = UIKit.Frame(window, "Body", UDim2.new(1, -28, 1, -86), UDim2.fromOffset(14, 76))

	local opened = Signal.new()
	local closed = Signal.new()
	local isOpen = false

	local panel: Panel
	local function close()
		if not isOpen then
			return
		end
		isOpen = false
		local tween = UIKit.Tween(pop, 0.1, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween.Completed:Once(function()
			if not isOpen then
				root.Visible = false
			end
		end)
		closed:Fire()
	end

	-- Botão fechar (X vermelho no canto)
	local closeButton = UIKit.Button({
		Name = "Close",
		Parent = window,
		Size = UDim2.fromOffset(56, 60),
		Position = UDim2.new(1, 10, 0, -12),
		AnchorPoint = Vector2.new(1, 0),
		Color = Colors.Red,
		DarkColor = Colors.RedDark,
		Text = Theme.Icons.Close,
		Layout = "Text",
		MaxTextSize = 30,
		OnClick = close,
	})
	closeButton.Holder.ZIndex = 5

	panel = {
		Root = root,
		Body = body,
		Subtitle = subtitle,
		IsOpen = function()
			return isOpen
		end,
		Open = function()
			if isOpen then
				return
			end
			isOpen = true
			root.Visible = true
			pop.Scale = 0.85
			UIKit.Tween(pop, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
			opened:Fire()
		end,
		Close = close,
		Opened = opened,
		Closed = closed,
	}
	return panel
end

-- Cartão branco com contorno (usado nas listas dos painéis)
function UIKit.Card(parent: Instance?, name: string, height: number, layoutOrder: number?, strokeColor: Color3?): Frame
	local card = UIKit.Frame(parent, name, UDim2.new(1, -12, 0, height), nil, Colors.Card)
	card.LayoutOrder = layoutOrder or 0
	UIKit.Corner(card, UDim.new(0, 16))
	UIKit.Stroke(card, 3, strokeColor or Colors.Ink, true)
	return card
end

-- Círculo colorido com ícone (retrato do ovo/animal)
function UIKit.Badge(parent: Instance?, icon: string, color: Color3, size: UDim2, position: UDim2?): Frame
	local circle = UIKit.Frame(parent, "Portrait", size, position, color)
	UIKit.Corner(circle, UDim.new(0.5, 0))
	UIKit.Stroke(circle, 3, Colors.Ink, true)
	UIKit.Icon(circle, icon, UDim2.fromScale(0.72, 0.72), UDim2.fromScale(0.14, 0.14))
	return circle
end

return UIKit
