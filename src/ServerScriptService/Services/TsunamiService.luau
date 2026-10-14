--!strict
--[[
	TsunamiService: as ondas.
	  • de tempos em tempos (aleatório entre MinInterval e MaxInterval) uma onda nasce
	    no FIM do corredor e anda até a zona segura, onde some
	  • antes de cada onda: aviso de WarningTime segundos (o cliente mostra e toca a sirene)
	  • a posição da onda é uma CONTA (início + velocidade * tempo), igual no servidor e
	    no cliente — o cliente desenha, o servidor decide quem morre
	  • morte checada a cada frame (Heartbeat), NUNCA com .Touched:
	      a onda passou pelo jogador E ele não está dentro de um buraco E não está na zona segura
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local NotifyService = require(script.Parent.NotifyService)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)
local Types = require(ReplicatedStorage.Shared.Types)

local TsunamiService = {}

local CONFIG = GameConfig.Waves
local rng = Random.new()
local waves: { Types.WaveData } = {}
local nextWaveId = 0
local gameState: Instance

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function pickType(): GameConfig.WaveType
	local total = 0
	for _, waveType in CONFIG.Types do
		total += waveType.Weight
	end
	local roll = rng:NextNumber(0, total)
	for _, waveType in CONFIG.Types do
		roll -= waveType.Weight
		if roll <= 0 then
			return waveType
		end
	end
	return CONFIG.Types[#CONFIG.Types]
end

-- Publica as ondas ativas para os clientes (atributo com JSON)
local function publishWaves()
	gameState:SetAttribute("Waves", HttpService:JSONEncode(waves))
end

function TsunamiService.GetFrontZ(wave: Types.WaveData, time: number): number
	return wave.StartZ - wave.Speed * (time - wave.StartTime)
end

-- Jogador escondido = abaixo do chão E dentro (no sentido Z) de um buraco
local function isHidden(position: Vector3): boolean
	if position.Y > MapLayout.FloorY - CONFIG.HideDepth then
		return false
	end
	return MapLayout.IsInHole(position.Z, -1)
end

local function kill(player: Player, humanoid: Humanoid, root: BasePart, wave: Types.WaveData)
	-- "levado pela água": empurra na direção da base antes de morrer
	root.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-15, 15), 45, -wave.Speed * 1.6)
	humanoid.Health = 0
	local profile = DataService.Get(player)
	if profile then
		profile.Data.Stats.Deaths += 1
	end
	NotifyService.Effect(player, "WaveHit", {})
	NotifyService.Notify(player, "O tsunami te levou! 🌊", "danger")
end

local function spawnWave(waveType: GameConfig.WaveType)
	nextWaveId += 1
	table.insert(waves, {
		Id = nextWaveId,
		Type = waveType.Id,
		Speed = waveType.Speed,
		StartTime = now(),
		StartZ = MapLayout.CorridorEndZ,
	})
	publishWaves()
end

local function step()
	if #waves == 0 then
		return
	end
	local time = now()

	-- Remove ondas que chegaram na zona segura
	local changed = false
	for index = #waves, 1, -1 do
		if TsunamiService.GetFrontZ(waves[index], time) <= MapLayout.CorridorStartZ then
			table.remove(waves, index)
			changed = true
		end
	end
	if changed then
		publishWaves()
	end

	-- Checa cada jogador contra cada onda
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			local position = root.Position
			if not MapLayout.IsSafeZ(position.Z) and not isHidden(position) then
				for _, wave in waves do
					local front = TsunamiService.GetFrontZ(wave, time)
					if position.Z >= front and position.Z <= front + CONFIG.Thickness then
						kill(player, humanoid, root, wave)
						break
					end
				end
			end
		end
	end
end

function TsunamiService.Init()
	local existing = ReplicatedStorage:FindFirstChild("GameState")
	if not existing then
		existing = Instance.new("Folder")
		existing.Name = "GameState"
		existing.Parent = ReplicatedStorage
	end
	gameState = existing :: Instance
	publishWaves()

	RunService.Heartbeat:Connect(step)

	-- Agenda das ondas
	task.spawn(function()
		local nextAt = now() + CONFIG.FirstWaveDelay
		local nextType = pickType()
		while true do
			gameState:SetAttribute("NextWaveAt", nextAt)
			gameState:SetAttribute("NextWaveType", nextType.Id)
			task.wait(math.max(0, nextAt - now()))
			spawnWave(nextType)
			nextAt = now() + rng:NextNumber(CONFIG.MinInterval, CONFIG.MaxInterval)
			nextType = pickType()
		end
	end)
end

return TsunamiService
