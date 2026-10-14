--!strict
--[[
	WaveRenderer: desenha as ondas no cliente (suave, sem lag).
	A posição vem da MESMA conta usada pelo servidor:
	  frente = StartZ - Speed * (agora - StartTime)
	Quem morre é decidido só pelo servidor.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)
local Types = require(ReplicatedStorage.Shared.Types)

local WaveRenderer = {}

local CONFIG = GameConfig.Waves
local WATER = Color3.fromRGB(30, 125, 220)
local FOAM = Color3.fromRGB(235, 248, 255)

local gameState = ReplicatedStorage:WaitForChild("GameState")
local active: { Types.WaveData } = {}
local visuals: { [number]: Model } = {}
local folder: Folder

local function newPart(model: Model, name: string, size: Vector3, cframe: CFrame, color: Color3, transparency: number): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Transparency = transparency
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = model
	return part
end

local function foamEmitter(parent: BasePart, face: Enum.NormalId, rate: number, size: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(FOAM)
	emitter.LightEmission = 0.2
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, size * 2.2),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(6, 14)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Rate = rate
	emitter.EmissionDirection = face
	emitter.Parent = parent
end

-- Monta a onda com origem na FRENTE, embaixo, no meio (ela anda para -Z)
local function buildWave(): Model
	local model = Instance.new("Model")
	model.Name = "Onda"
	local width = MapLayout.CorridorWidth - 0.4
	local height = CONFIG.Height
	local thickness = CONFIG.Thickness

	local body = newPart(model, "Agua", Vector3.new(width, height, thickness), CFrame.new(0, height / 2, thickness / 2), WATER, 0.22)
	body.Reflectance = 0.08

	local face = newPart(model, "Frente", Vector3.new(width, height, 1), CFrame.new(0, height / 2, 0.2), Color3.fromRGB(120, 200, 255), 0.45)
	foamEmitter(face, Enum.NormalId.Front, 70, 4)

	-- "Rolo" de espuma no topo e na base
	local crest = newPart(model, "Crista", Vector3.new(width, 9, 9), CFrame.new(0, height, 2), FOAM, 0.1)
	crest.Shape = Enum.PartType.Cylinder
	foamEmitter(crest, Enum.NormalId.Top, 40, 5)
	local base = newPart(model, "Base", Vector3.new(width, 5, 5), CFrame.new(0, 2, -0.5), FOAM, 0.2)
	base.Shape = Enum.PartType.Cylinder
	foamEmitter(base, Enum.NormalId.Front, 40, 3)

	-- Faixa escura atrás para dar profundidade
	newPart(model, "Fundo", Vector3.new(width, height * 0.8, 2), CFrame.new(0, height * 0.4, thickness), Color3.fromRGB(15, 70, 150), 0.3)

	-- O "pivô" do modelo é a frente/base/meio (as peças foram montadas em volta da origem)
	model.WorldPivot = CFrame.new()
	model.Parent = folder
	return model
end

local function decode()
	local raw = gameState:GetAttribute("Waves")
	local list: { Types.WaveData } = {}
	if typeof(raw) == "string" then
		local ok, result = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		if ok and typeof(result) == "table" then
			list = result :: { Types.WaveData }
		end
	end
	active = list

	-- Apaga visuais de ondas que já acabaram
	local alive: { [number]: boolean } = {}
	for _, wave in active do
		alive[wave.Id] = true
	end
	for id, model in visuals do
		if not alive[id] then
			model:Destroy()
			visuals[id] = nil
		end
	end
end

function WaveRenderer.GetFrontZ(wave: Types.WaveData, now: number): number
	return wave.StartZ - wave.Speed * (now - wave.StartTime)
end

-- Ondas que ainda estão dentro do corredor
function WaveRenderer.GetActive(): { Types.WaveData }
	local now = Workspace:GetServerTimeNow()
	local list = {}
	for _, wave in active do
		if WaveRenderer.GetFrontZ(wave, now) > MapLayout.CorridorStartZ then
			table.insert(list, wave)
		end
	end
	return list
end

function WaveRenderer.Start()
	folder = Instance.new("Folder")
	folder.Name = "OndasLocais"
	folder.Parent = Workspace

	gameState:GetAttributeChangedSignal("Waves"):Connect(decode)
	decode()

	RunService.RenderStepped:Connect(function()
		local now = Workspace:GetServerTimeNow()
		for _, wave in active do
			local front = WaveRenderer.GetFrontZ(wave, now)
			local model = visuals[wave.Id]
			if front <= MapLayout.CorridorStartZ - 2 then
				if model then
					model:Destroy()
					visuals[wave.Id] = nil
				end
			else
				if not model then
					model = buildWave()
					visuals[wave.Id] = model
				end
				-- some suavemente ao chegar na zona segura
				local sink = math.clamp((MapLayout.CorridorStartZ + 25 - front) / 25, 0, 1) * CONFIG.Height
				model:PivotTo(CFrame.new(0, MapLayout.FloorY - sink, math.min(front, MapLayout.CorridorEndZ)))
			end
		end
	end)
end

return WaveRenderer
