--!strict
--[[
	Theme: o "design system" da interface.
	Cores, fontes, tamanhos e ícones ficam aqui (nunca cores soltas no código).

	Regras seguidas (guia de UI/UX para mobile):
	  • botões de toque com no mínimo 44 px REAIS no celular (aqui 88 px base * escala)
	  • todo ícone tem texto junto (nada de botão só com ícone)
	  • texto branco com contorno escuro = contraste alto em qualquer fundo
	  • animações curtas (0,08 s a 0,25 s) e com significado
	  • HUD nas bordas, centro da tela livre para jogar
]]

local Theme = {}

Theme.Colors = {
	Ink = Color3.fromRGB(28, 22, 40), -- contorno de tudo
	White = Color3.fromRGB(255, 255, 255),
	Cream = Color3.fromRGB(255, 247, 228), -- fundo dos painéis
	CreamDark = Color3.fromRGB(242, 224, 190),
	Card = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(120, 110, 135),
	Money = Color3.fromRGB(110, 255, 80),
	MoneyDark = Color3.fromRGB(40, 150, 40),
	Overlay = Color3.fromRGB(10, 8, 20),

	Green = Color3.fromRGB(88, 214, 61),
	GreenDark = Color3.fromRGB(44, 140, 30),
	Blue = Color3.fromRGB(56, 160, 255),
	BlueDark = Color3.fromRGB(26, 92, 190),
	Orange = Color3.fromRGB(255, 166, 38),
	OrangeDark = Color3.fromRGB(200, 100, 10),
	Purple = Color3.fromRGB(170, 98, 255),
	PurpleDark = Color3.fromRGB(104, 50, 186),
	Red = Color3.fromRGB(255, 72, 72),
	RedDark = Color3.fromRGB(170, 28, 28),
	Gray = Color3.fromRGB(165, 165, 178),
	GrayDark = Color3.fromRGB(96, 96, 112),
	Yellow = Color3.fromRGB(255, 214, 40),
	YellowDark = Color3.fromRGB(196, 140, 0),
	SafeGreen = Color3.fromRGB(70, 200, 90),
}

-- Cor de cada tipo de notificação
Theme.Kinds = {
	info = Theme.Colors.Blue,
	success = Theme.Colors.Green,
	warning = Theme.Colors.Orange,
	danger = Theme.Colors.Red,
	rarity = Theme.Colors.Purple,
}

Theme.Fonts = {
	Title = Enum.Font.LuckiestGuy, -- títulos e botões (cartunesca, grossa)
	Body = Enum.Font.FredokaOne, -- textos
}

-- Ícones: emojis por enquanto. Para trocar por imagem, coloque o
-- "rbxassetid://..." em Theme.Images com o mesmo nome.
Theme.Icons = {
	Shop = "🛒",
	Index = "📖",
	Hatching = "🥚",
	Barn = "🏠",
	Money = "💵",
	Speed = "👟",
	Wave = "🌊",
	Close = "✖",
	Egg = "🥚",
	Carry = "🎒",
	Slots = "📦",
	Pin = "📍",
	Lock = "🔒",
	Unknown = "❓",
	Sell = "💰",
}

Theme.Images = {} :: { [string]: string }

Theme.Sizes = {
	SideButton = 88, -- botões laterais (base)
	Gap = 12,
	Margin = 12,
	Corner = 18,
	Stroke = 3,
	ButtonDepth = 6, -- "altura" 3D dos botões
}

-- Escala da interface pelo tamanho da tela (celular ~0.65, PC ~1.2)
Theme.DesignHeight = 560
Theme.DesignWidth = 900
Theme.MinScale = 0.62
Theme.MaxScale = 1.25

function Theme.Darken(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function Theme.Lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

-- Contorno branco para textos escuros (ex.: raridade Secreto), escuro para o resto
function Theme.StrokeFor(color: Color3): Color3
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return if luminance < 0.3 then Theme.Colors.White else Theme.Colors.Ink
end

return Theme
