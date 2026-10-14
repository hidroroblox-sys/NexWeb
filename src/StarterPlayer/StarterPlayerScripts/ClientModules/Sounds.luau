--!strict
-- Sounds: toca os sons configurados em GameConfig.Sounds (vazio = sem som).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local Sounds = {}

local templates: { [string]: Sound } = {}

local function getTemplate(name: string): Sound?
	local id = (GameConfig.Sounds :: { [string]: string })[name]
	if not id or id == "" then
		return nil
	end
	local template = templates[name]
	if not template then
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = id
		sound.Parent = SoundService
		templates[name] = sound
		template = sound
	end
	return template
end

-- Toca um som (pode tocar vários ao mesmo tempo)
function Sounds.Play(name: string, pitch: number?, volume: number?)
	local template = getTemplate(name)
	if not template then
		return
	end
	local sound = template:Clone()
	sound.PlaybackSpeed = pitch or 1
	sound.Volume = volume or 0.5
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function Sounds.Has(name: string): boolean
	return getTemplate(name) ~= nil
end

return Sounds
