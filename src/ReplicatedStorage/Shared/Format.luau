--!strict
--[[
	Format: transforma números em texto bonito.
	  Format.Money(7110)     -> "$7,110"
	  Format.Money(12345)    -> "$12.3K"
	  Format.Money(3.4e6)    -> "$3.4M"
	  Format.Time(150)       -> "2:30"
	  Format.Time(9000)      -> "2h 30m"
]]

local GameConfig = require(script.Parent.GameConfig)

local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- 1234567 -> "1,234,567"
function Format.Commas(value: number): string
	local text = tostring(math.floor(value))
	local negative = string.sub(text, 1, 1) == "-"
	if negative then
		text = string.sub(text, 2)
	end
	local formatted = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1,")))
	if string.sub(formatted, 1, 1) == "," then
		formatted = string.sub(formatted, 2)
	end
	return if negative then "-" .. formatted else formatted
end

-- Abrevia números grandes: 12345 -> "12.3K"
function Format.Number(value: number): string
	if value ~= value then
		return "0"
	end
	if math.abs(value) < GameConfig.UI.AbbreviateFrom then
		return Format.Commas(value)
	end
	local index = 0
	local scaled = value
	while math.abs(scaled) >= 1000 and index < #SUFFIXES do
		scaled /= 1000
		index += 1
	end
	local text: string
	if math.abs(scaled) >= 100 then
		text = tostring(math.floor(scaled))
	else
		text = string.format("%.1f", math.floor(scaled * 10) / 10)
		text = (string.gsub(text, "%.0$", ""))
	end
	return text .. SUFFIXES[index]
end

function Format.Money(value: number): string
	return "$" .. Format.Number(value)
end

function Format.PerSecond(value: number): string
	return "$" .. Format.Number(value) .. "/s"
end

-- Contagem regressiva: "2:30" ou "5h 59m"
function Format.Time(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	if total >= 3600 then
		local hours = total // 3600
		local minutes = (total % 3600) // 60
		return string.format("%dh %02dm", hours, minutes)
	end
	return string.format("%d:%02d", total // 60, total % 60)
end

-- Duração "humana" para textos: "1 min", "2h30", "12 h"
function Format.Duration(seconds: number): string
	if seconds < 60 then
		return string.format("%d s", seconds)
	elseif seconds < 3600 then
		return string.format("%d min", seconds // 60)
	end
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	if minutes == 0 then
		return string.format("%d h", hours)
	end
	return string.format("%dh%02d", hours, minutes)
end

return Format
