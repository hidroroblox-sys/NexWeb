--!strict
--[[
	MovementService
	  • o SERVIDOR define o WalkSpeed (o cliente nunca muda a própria velocidade)
	  • anti speed-hack simples: se o jogador anda muito mais rápido do que pode,
	    várias vezes seguidas, ele é puxado de volta para a última posição válida
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

type Tracker = {
	LastPosition: Vector3?,
	LastTime: number,
	Violations: number,
	LastValid: CFrame?,
}

local MovementService = {}

local CONFIG = GameConfig.AntiCheat
local trackers: { [Player]: Tracker } = {}

function MovementService.GetWalkSpeed(player: Player): number
	local profile = DataService.Get(player)
	local level = if profile then profile.Data.SpeedLevel else 0
	return Formulas.WalkSpeed(level)
end

function MovementService.Apply(player: Player)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		humanoid.WalkSpeed = MovementService.GetWalkSpeed(player)
	end
end

-- Chamar quando o servidor teleporta/renasce o jogador
function MovementService.Reset(player: Player)
	trackers[player] = { LastPosition = nil, LastTime = os.clock(), Violations = 0, LastValid = nil }
end

local function check(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end
	local tracker = trackers[player]
	if not tracker then
		MovementService.Reset(player)
		tracker = trackers[player]
	end

	local now = os.clock()
	local position = root.Position
	local last = tracker.LastPosition
	local dt = now - tracker.LastTime
	tracker.LastTime = now
	tracker.LastPosition = position
	if not last or dt <= 0 then
		tracker.LastValid = root.CFrame
		return
	end

	local flat = Vector3.new(position.X - last.X, 0, position.Z - last.Z).Magnitude
	local allowed = MovementService.GetWalkSpeed(player) * CONFIG.SpeedTolerance * dt + CONFIG.ExtraStuds
	if flat > allowed then
		tracker.Violations += 1
		local lastValid = tracker.LastValid
		if tracker.Violations >= CONFIG.MaxViolations and lastValid then
			warn(string.format("[AntiCheat] %s andou rápido demais (%.0f studs em %.2fs)", player.Name, flat, dt))
			root.AssemblyLinearVelocity = Vector3.zero
			character:PivotTo(lastValid)
			tracker.Violations = 0
			tracker.LastPosition = lastValid.Position
		end
	else
		tracker.Violations = math.max(0, tracker.Violations - 1)
		tracker.LastValid = root.CFrame
	end
end

function MovementService.Init()
	Players.PlayerRemoving:Connect(function(player)
		trackers[player] = nil
	end)
	if not CONFIG.Enabled then
		return
	end
	task.spawn(function()
		while true do
			task.wait(CONFIG.CheckInterval)
			for _, player in Players:GetPlayers() do
				check(player)
			end
		end
	end)
end

return MovementService
