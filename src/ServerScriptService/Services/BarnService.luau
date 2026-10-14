--!strict
--[[
	BarnService: os 8 celeiros (bases) — igual ao original, com ovos.
	  • cada jogador ganha um celeiro livre ao entrar (placa com o nome)
	  • começa com 10 slots; a PLACA na frente compra +1 slot; a cada 10 slots um ANDAR novo
	  • elevadores no fundo levam de um andar para o outro
	  • ao ENTRAR no celeiro, os ovos carregados vão sozinhos para os slots livres
	    (Ninho Surpresa abre na hora e vira um ovo)
	  • ovos chocam com o tempo (continua offline) e viram animais
	  • cada animal tem botão "Subir Nível" (renda x1,25 por nível)
	  • a renda acumula no COLETOR verde de cada slot — pise para pegar
	  • renda offline (até GameConfig.Data.OfflineIncomeHours)
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Billboards = require(script.Parent.Billboards)
local CarryService = require(script.Parent.CarryService)
local DataService = require(script.Parent.DataService)
local ModelFactory = require(script.Parent.ModelFactory)
local MovementService = require(script.Parent.MovementService)
local NotifyService = require(script.Parent.NotifyService)
local RateLimit = require(script.Parent.RateLimit)
local SyncService = require(script.Parent.SyncService)
local Wallet = require(script.Parent.Wallet)
local Format = require(ReplicatedStorage.Shared.Format)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local MapLayout = require(ReplicatedStorage.Shared.MapLayout)

type SlotVisual = {
	Index: number,
	Floor: number,
	Pen: Part,
	Pad: Part,
	PadLabel: TextLabel,
	PadPosition: Vector3,
	Content: Model?,
	ShownStored: number,
}

type Elevator = {
	Position: Vector3,
	TargetFloor: number,
}

type Barn = {
	Index: number,
	CFrame: CFrame,
	Model: Model,
	Owner: Player?,
	OwnerLabel: TextLabel,
	FacadeLabel: TextLabel,
	SignLabel: TextLabel,
	SignPrompt: ProximityPrompt,
	Spawn: SpawnLocation,
	Slots: { SlotVisual },
	FloorsFolder: Folder,
	BuiltFloors: number,
	Elevators: { Elevator },
}

local BarnService = {}

local Map = GameConfig.Map
local barns: { Barn } = {}
local barnOf: { [Player]: Barn } = {}
local lastFullMessage: { [Player]: number } = {}
local lastElevator: { [Player]: number } = {}

local COLORS = {
	Red = Color3.fromRGB(200, 45, 45),
	RedDark = Color3.fromRGB(150, 30, 30),
	Trim = Color3.fromRGB(250, 245, 235),
	Floor = Color3.fromRGB(165, 115, 65),
	Hay = Color3.fromRGB(235, 200, 100),
	Locked = Color3.fromRGB(90, 80, 70),
	Pad = Color3.fromRGB(70, 210, 90),
	PadLocked = Color3.fromRGB(70, 70, 75),
	Elevator = Color3.fromRGB(40, 230, 255),
	Ink = Color3.fromRGB(28, 22, 40),
}

-- ---------------------------------------------------------------------
-- Construção
-- ---------------------------------------------------------------------

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function textLabel(parent: Instance, text: string, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.LuckiestGuy
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = COLORS.Ink
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function setVisible(target: BasePart, visible: boolean)
	target.Transparency = if visible then 0 else 1
	for _, child in target:GetChildren() do
		if child:IsA("SurfaceGui") then
			child.Enabled = visible
		end
	end
end

local function buildBarn(index: number, origin: CFrame, parent: Instance): Barn
	local model = Instance.new("Model")
	model.Name = "Celeiro" .. index
	local size = Map.BarnSize
	local w, h, d = size.X, size.Y, size.Z

	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	-- Chão de madeira
	part(model, "Chao", Vector3.new(w, 1, d), at(0, -0.4, 0), COLORS.Floor, Enum.Material.WoodPlanks)

	-- Paredes: fundo (+Z local) e laterais. A frente (-Z) fica aberta.
	part(model, "ParedeFundo", Vector3.new(w, h, 1), at(0, h / 2, d / 2 - 0.5), COLORS.Red, Enum.Material.WoodPlanks)
	for _, side in { -1, 1 } do
		part(model, "ParedeLado", Vector3.new(1, h * 0.6, d), at(side * (w / 2 - 0.5), h * 0.3, 0), COLORS.Red, Enum.Material.WoodPlanks)
		part(model, "Pilar", Vector3.new(2, h + 2, 2), at(side * (w / 2 - 1), (h + 2) / 2, -d / 2 + 1), COLORS.Trim)
	end
	local beam = part(model, "Viga", Vector3.new(w, 4, 1.5), at(0, h + 2, -d / 2 - 0.8), COLORS.Trim)
	local facadeLabel = Billboards.SurfaceText(beam, Enum.NormalId.Front, "Celeiro livre", COLORS.RedDark)

	-- Placa flutuante com o nome do dono
	local signAnchor = part(model, "PlacaDono", Vector3.new(1, 1, 1), at(0, MapLayout.FloorHeight(2) + h + 4, 0), COLORS.Trim)
	signAnchor.Transparency = 1
	signAnchor.CanCollide = false
	signAnchor.CanQuery = false
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Dono"
	billboard.Size = UDim2.fromScale(26, 5)
	billboard.MaxDistance = 400
	billboard.LightInfluence = 0
	billboard.Parent = signAnchor
	local ownerLabel = textLabel(billboard, "Celeiro livre", Color3.new(1, 1, 1))

	-- Ponto de nascimento (na porta)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Nascimento"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 0.4, 5)
	spawn.CFrame = at(0, 0.05, -d / 2 + 5)
	spawn.CanCollide = false
	spawn.Color = COLORS.Trim
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = model

	-- Placa de COMPRAR SLOT (do lado de fora, perto da porta)
	local signPost = part(model, "PlacaSlot", Vector3.new(7, 5, 0.6), origin * CFrame.new(MapLayout.SlotSignOffset + Vector3.new(0, 4.5, 0)), Color3.fromRGB(70, 210, 90), Enum.Material.SmoothPlastic)
	part(model, "PlacaSlotPoste", Vector3.new(0.6, 2.5, 0.6), origin * CFrame.new(MapLayout.SlotSignOffset + Vector3.new(0, 1.25, 0)), COLORS.Floor, Enum.Material.Wood)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 30
	signGui.LightInfluence = 0
	signGui.Parent = signPost
	local signLabel = textLabel(signGui, "+1 SLOT", Color3.new(1, 1, 1))
	local signPrompt = Instance.new("ProximityPrompt")
	signPrompt.ActionText = "Comprar Slot"
	signPrompt.ObjectText = ""
	signPrompt.HoldDuration = 0
	signPrompt.MaxActivationDistance = 10
	signPrompt.RequiresLineOfSight = false
	signPrompt.Parent = signPost
	CollectionService:AddTag(signPrompt, "OwnerPrompt")

	-- Slots: ninho de feno + coletor (andares de cima ficam escondidos até liberar)
	local slots: { SlotVisual } = {}
	for slotIndex = 1, GameConfig.Barn.MaxSlots do
		local penOffset, padOffset = MapLayout.GetSlotOffsets(slotIndex)
		local pen = part(model, "Slot" .. slotIndex, Map.PenSize, origin * CFrame.new(penOffset + Vector3.new(0, 0.05, 0)), COLORS.Hay, Enum.Material.Fabric)
		pen.CanCollide = false
		local pad = part(model, "Coletor" .. slotIndex, Map.PadSize, origin * CFrame.new(padOffset + Vector3.new(0, 0.05, 0)), COLORS.Pad, Enum.Material.SmoothPlastic)
		pad.CanCollide = false
		local padLabel = Billboards.SurfaceText(pad, Enum.NormalId.Top, "", Color3.fromRGB(110, 255, 80), Enum.Font.FredokaOne)
		table.insert(slots, {
			Index = slotIndex,
			Floor = Formulas.FloorOfSlot(slotIndex),
			Pen = pen,
			Pad = pad,
			PadLabel = padLabel,
			PadPosition = pad.Position,
			Content = nil,
			ShownStored = -1,
		})
	end

	local floorsFolder = Instance.new("Folder")
	floorsFolder.Name = "Andares"
	floorsFolder.Parent = model

	model.Parent = parent
	return {
		Index = index,
		CFrame = origin,
		Model = model,
		Owner = nil,
		OwnerLabel = ownerLabel,
		FacadeLabel = facadeLabel,
		SignLabel = signLabel,
		SignPrompt = signPrompt,
		Spawn = spawn,
		Slots = slots,
		FloorsFolder = floorsFolder,
		BuiltFloors = 1,
		Elevators = {},
	}
end

-- Andares de cima + elevadores (recria quando o número de andares muda)
local function buildFloors(barn: Barn, floors: number)
	if barn.BuiltFloors == floors and (floors == 1 or #barn.FloorsFolder:GetChildren() > 0) then
		return
	end
	barn.FloorsFolder:ClearAllChildren()
	table.clear(barn.Elevators)
	barn.BuiltFloors = floors
	local origin = barn.CFrame
	local size = Map.BarnSize
	local w, d = size.X, size.Z

	for floor = 2, floors do
		local y = MapLayout.FloorHeight(floor)
		part(barn.FloorsFolder, "Andar" .. floor, Vector3.new(w, 1, d), origin * CFrame.new(0, y - 0.4, 0), COLORS.Floor, Enum.Material.WoodPlanks)
		part(barn.FloorsFolder, "Fundo" .. floor, Vector3.new(w, 6, 1), origin * CFrame.new(0, y + 3, d / 2 - 0.5), COLORS.Red, Enum.Material.WoodPlanks)
		for _, side in { -1, 1 } do
			part(barn.FloorsFolder, "Grade", Vector3.new(1, 4, d), origin * CFrame.new(side * (w / 2 - 0.5), y + 2, 0), COLORS.Red, Enum.Material.WoodPlanks)
		end
		part(barn.FloorsFolder, "GradeFrente", Vector3.new(w, 3, 1), origin * CFrame.new(0, y + 1.5, -d / 2 + 0.5), COLORS.Trim)
	end

	-- Elevadores: sobe no lado esquerdo, desce no direito
	for floor = 1, floors do
		local upOffset, downOffset = MapLayout.GetElevatorOffsets(floor)
		local function pad(offset: Vector3, text: string, target: number)
			local cf = origin * CFrame.new(offset + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
			local disc = part(barn.FloorsFolder, "Elevador", Vector3.new(0.3, 5, 5), cf, COLORS.Elevator, Enum.Material.Neon)
			disc.Shape = Enum.PartType.Cylinder
			disc.CanCollide = false
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromScale(6, 1.6)
			gui.StudsOffset = Vector3.new(0, 3, 0)
			gui.MaxDistance = 60
			gui.LightInfluence = 0
			gui.Parent = disc
			textLabel(gui, text, COLORS.Elevator)
			table.insert(barn.Elevators, { Position = (origin * CFrame.new(offset)).Position, TargetFloor = target })
		end
		if floor < floors then
			pad(upOffset, "⬆ ANDAR " .. (floor + 1), floor + 1)
		end
		if floor > 1 then
			pad(downOffset, "⬇ ANDAR " .. (floor - 1), floor - 1)
		end
	end
end

-- ---------------------------------------------------------------------
-- Desenho dos slots
-- ---------------------------------------------------------------------

local function updatePadLabel(slot: SlotVisual, stored: number?)
	if stored == nil then
		if slot.ShownStored ~= -2 then
			slot.PadLabel.Text = ""
			slot.ShownStored = -2
		end
		return
	end
	local value = math.floor(stored)
	if value ~= slot.ShownStored then
		slot.ShownStored = value
		slot.PadLabel.Text = Format.Money(value)
	end
end

local function updateSign(barn: Barn)
	local owner = barn.Owner
	local profile = if owner then DataService.Get(owner) else nil
	barn.SignPrompt:SetAttribute("OwnerUserId", if owner then owner.UserId else 0)
	if not profile then
		barn.SignLabel.Text = "+1 SLOT"
		return
	end
	local price = Formulas.SlotPrice(profile.Data.BarnSlots)
	if price then
		barn.SignLabel.Text = "+1 SLOT\n" .. Format.Money(price)
		barn.SignPrompt.ObjectText = Format.Money(price)
	else
		barn.SignLabel.Text = "MÁXIMO"
		barn.SignPrompt.ObjectText = "Máximo"
	end
end

local function renderSlot(barn: Barn, slotIndex: number)
	local slot = barn.Slots[slotIndex]
	if not slot then
		return
	end
	if slot.Content then
		slot.Content:Destroy()
		slot.Content = nil
	end

	local owner = barn.Owner
	local profile = if owner then DataService.Get(owner) else nil
	local barnSlots = if profile then profile.Data.BarnSlots else GameConfig.Barn.StartSlots
	local floorsUnlocked = Formulas.FloorOfSlot(barnSlots)
	local floorVisible = slot.Floor == 1 or slot.Floor <= floorsUnlocked
	local unlocked = profile ~= nil and slotIndex <= barnSlots

	setVisible(slot.Pen, floorVisible)
	setVisible(slot.Pad, floorVisible)
	slot.Pen.Color = if unlocked then COLORS.Hay else COLORS.Locked
	slot.Pad.Color = if unlocked then COLORS.Pad else COLORS.PadLocked
	if floorVisible and profile and not unlocked then
		slot.Pen.Transparency = 0.5
	end

	local data = if profile then profile.Data.Slots[tostring(slotIndex)] else nil
	if not owner or not profile or not data then
		updatePadLabel(slot, nil)
		return
	end

	local ground = slot.Pen.CFrame * CFrame.new(0, Map.PenSize.Y / 2, 0)
	if data.Hatched then
		local model = ModelFactory.CreateAnimal(data.AnimalId, 1)
		ModelFactory.ApplyMutation(model, data.Mutation)
		ModelFactory.PlaceOnGround(model, ground, 0.1)
		local root = model.PrimaryPart
		if root then
			local income = Formulas.AnimalIncome(data.AnimalId, profile.Data.Rebirths, data.Level, data.Mutation)
			Billboards.Animal(data.AnimalId, income, data.Level, data.Mutation).Parent = root

			local cost, levels = Formulas.LevelUpCost(data.AnimalId, data.Level, 1)
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "SubirNivel"
			prompt.ActionText = if levels > 0 then "Subir Nível" else "Nível Máximo"
			prompt.ObjectText = if levels > 0 then Format.Money(cost) else ""
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 9
			prompt.RequiresLineOfSight = false
			prompt.KeyboardKeyCode = Enum.KeyCode.F
			prompt:SetAttribute("OwnerUserId", owner.UserId)
			CollectionService:AddTag(prompt, "OwnerPrompt")
			prompt.Parent = root
			prompt.Triggered:Connect(function(player)
				BarnService.LevelUp(player, slotIndex, 1)
			end)
		end
		CollectionService:AddTag(model, "IdleAnimal")
		model.Parent = barn.Model
		slot.Content = model
		updatePadLabel(slot, data.Stored)
	else
		local model = ModelFactory.CreateEgg(data.EggId, 1)
		ModelFactory.ApplyMutation(model, data.Mutation)
		ModelFactory.PlaceOnGround(model, ground, 0.1)
		local root = model.PrimaryPart
		if root then
			Billboards.Hatching(data.EggId, data.HatchAt, data.HatchDuration, data.Mutation).Parent = root
		end
		CollectionService:AddTag(model, "HatchingEgg")
		model.Parent = barn.Model
		slot.Content = model
		updatePadLabel(slot, nil)
	end
end

local function renderAll(barn: Barn)
	local owner = barn.Owner
	local profile = if owner then DataService.Get(owner) else nil
	local slots = if profile then profile.Data.BarnSlots else GameConfig.Barn.StartSlots
	buildFloors(barn, if profile then Formulas.FloorOfSlot(slots) else 1)
	for slotIndex = 1, GameConfig.Barn.MaxSlots do
		renderSlot(barn, slotIndex)
	end
	updateSign(barn)
end

-- ---------------------------------------------------------------------
-- Regras do celeiro
-- ---------------------------------------------------------------------

local function getRoot(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function findFreeSlot(data: DataService.PlayerData): number?
	for slotIndex = 1, data.BarnSlots do
		if not data.Slots[tostring(slotIndex)] then
			return slotIndex
		end
	end
	return nil
end

-- Coloca os ovos carregados nos slots livres
local function placeCarried(barn: Barn, player: Player)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local data = profile.Data
	local placed = 0
	while CarryService.Count(player) > 0 do
		local free = findFreeSlot(data)
		if not free then
			local now = os.clock()
			if now - (lastFullMessage[player] or 0) > GameConfig.Barn.FullMessageCooldown then
				lastFullMessage[player] = now
				NotifyService.Notify(player, "Celeiro cheio! Venda um animal ou compre mais slots na placa", "warning")
			end
			break
		end
		local item = CarryService.TakeOne(player)
		if not item then
			break
		end
		local egg = GameConfig.EggsById[item.EggId]
		local rarity = GameConfig.RarityById[egg.Rarity]
		data.Slots[tostring(free)] = {
			EggId = item.EggId,
			AnimalId = item.AnimalId,
			Mutation = item.Mutation,
			Level = 1,
			HatchAt = os.time() + rarity.HatchTime,
			HatchDuration = rarity.HatchTime,
			Hatched = false,
			Stored = 0,
		}
		renderSlot(barn, free)
		placed += 1
		if item.Lucky then
			local slot = barn.Slots[free]
			NotifyService.EffectAll("Hatch", { Position = slot.Pen.Position + Vector3.new(0, 2, 0), Color = rarity.Color, Order = rarity.Order })
			local mutation = if item.Mutation then " " .. GameConfig.MutationsById[item.Mutation].Name else ""
			NotifyService.Notify(player, string.format("Ninho Surpresa abriu: %s%s (%s)!", egg.Name, mutation, rarity.Name), "rarity", rarity.Color)
		end
	end
	if placed > 0 then
		local text = if placed == 1 then "Ovo colocado no celeiro! 🥚" else string.format("%d ovos colocados no celeiro! 🥚", placed)
		NotifyService.Notify(player, text, "success")
		SyncService.Push(player)
	end
end

local function hatch(barn: Barn?, player: Player, profile: DataService.Profile, slotIndex: number, data: DataService.SlotData, silent: boolean)
	data.Hatched = true
	local animal = GameConfig.AnimalsById[data.AnimalId]
	local rarity = GameConfig.RarityById[animal.Rarity]
	local isNew = not profile.Data.Index[data.AnimalId]
	profile.Data.Index[data.AnimalId] = true
	profile.Data.Stats.EggsHatched += 1

	if barn then
		local slot = barn.Slots[slotIndex]
		renderSlot(barn, slotIndex)
		if not silent then
			NotifyService.EffectAll("Hatch", {
				Position = slot.Pen.Position + Vector3.new(0, 2, 0),
				Color = rarity.Color,
				Order = rarity.Order,
			})
		end
	end
	if not silent then
		local mutation = if data.Mutation then " " .. GameConfig.MutationsById[data.Mutation].Name else ""
		NotifyService.Notify(player, string.format("Seu ovo chocou: %s %s%s (%s)!", animal.Icon, animal.Name, mutation, rarity.Name), "rarity", rarity.Color)
		if isNew then
			NotifyService.Notify(player, "Novo animal no Índice! 📖", "success")
		end
	end
	SyncService.Push(player)
end

local function collect(barn: Barn, player: Player, slotIndex: number)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local data = profile.Data.Slots[tostring(slotIndex)]
	if not data or not data.Hatched then
		return
	end
	local amount = math.floor(data.Stored)
	if amount < 1 then
		return
	end
	data.Stored -= amount
	Wallet.Add(player, amount)
	local slot = barn.Slots[slotIndex]
	updatePadLabel(slot, data.Stored)
	NotifyService.Effect(player, "Collect", { Position = slot.PadPosition, Amount = amount })
end

-- Renda que aconteceu enquanto o jogador estava fora (como no original)
local function applyOffline(player: Player, profile: DataService.Profile)
	local data = profile.Data
	local hours = GameConfig.Data.OfflineIncomeHours
	local now = os.time()
	local cap = hours * 3600
	local earned = 0
	local hatchedOffline = 0
	for key, slot in data.Slots do
		if not slot.Hatched and now >= slot.HatchAt then
			local slotIndex = tonumber(key)
			if slotIndex then
				hatch(nil, player, profile, slotIndex, slot, true)
				hatchedOffline += 1
			end
		end
		if slot.Hatched and data.LastOnline > 0 and hours > 0 then
			local from = math.max(data.LastOnline, slot.HatchAt)
			local seconds = math.clamp(now - from, 0, cap)
			local amount = Formulas.AnimalIncome(slot.AnimalId, data.Rebirths, slot.Level, slot.Mutation) * seconds
			slot.Stored += amount
			earned += amount
		end
	end
	if hatchedOffline > 0 then
		NotifyService.Notify(player, string.format("%d ovo(s) chocaram enquanto você estava fora! 🐣", hatchedOffline), "success")
	end
	if earned >= 1 then
		NotifyService.Notify(player, "Enquanto você estava fora seus animais fizeram " .. Format.Money(earned) .. "! Pise nos coletores.", "success")
	end
end

-- ---------------------------------------------------------------------
-- API
-- ---------------------------------------------------------------------

function BarnService.Assign(player: Player): boolean
	for _, barn in barns do
		if barn.Owner == nil then
			barn.Owner = player
			barnOf[player] = barn
			barn.OwnerLabel.Text = "🏠 " .. player.DisplayName
			barn.FacadeLabel.Text = "Celeiro de " .. player.DisplayName
			player:SetAttribute("BarnIndex", barn.Index)
			player.RespawnLocation = barn.Spawn
			local profile = DataService.Get(player)
			if profile then
				applyOffline(player, profile)
			end
			renderAll(barn)
			return true
		end
	end
	return false
end

function BarnService.Release(player: Player)
	local barn = barnOf[player]
	if not barn then
		return
	end
	barnOf[player] = nil
	lastFullMessage[player] = nil
	barn.Owner = nil
	barn.OwnerLabel.Text = "Celeiro livre"
	barn.FacadeLabel.Text = "Celeiro livre"
	renderAll(barn)
end

function BarnService.GetSpawnCFrame(player: Player): CFrame?
	local barn = barnOf[player]
	if not barn then
		return nil
	end
	return barn.Spawn.CFrame + Vector3.new(0, 3.5, 0)
end

-- Depois de comprar slot ou fazer rebirth, redesenha tudo
function BarnService.Refresh(player: Player)
	local barn = barnOf[player]
	if barn then
		renderAll(barn)
	end
end

function BarnService.BuySlot(player: Player): (boolean, string)
	local profile = DataService.Get(player)
	if not profile then
		return false, "Seus dados ainda estão carregando..."
	end
	local data = profile.Data
	local price = Formulas.SlotPrice(data.BarnSlots)
	if not price then
		return false, "Seu celeiro já está no tamanho máximo!"
	end
	if not Wallet.TrySpend(player, price) then
		return false, "Dinheiro insuficiente! Faltam " .. Format.Money(math.max(0, price - data.Money))
	end
	local oldFloors = Formulas.FloorOfSlot(data.BarnSlots)
	data.BarnSlots += 1
	Wallet.Refresh(player)
	BarnService.Refresh(player)
	SyncService.Push(player)
	if Formulas.FloorOfSlot(data.BarnSlots) > oldFloors then
		return true, string.format("Novo ANDAR liberado! Agora você tem %d slots 🏠", data.BarnSlots)
	end
	return true, string.format("+1 slot! Agora você tem %d slots 🏠", data.BarnSlots)
end

function BarnService.LevelUp(player: Player, slotIndex: number, amount: number): (boolean, string)
	if not RateLimit.Check(player, "LevelUp", 0.12) then
		return false, "Calma! Tente de novo."
	end
	local barn = barnOf[player]
	local profile = DataService.Get(player)
	if not barn or not profile then
		return false, "Seu celeiro ainda está carregando."
	end
	local data = profile.Data.Slots[tostring(slotIndex)]
	if not data or not data.Hatched then
		return false, "Só animais podem subir de nível."
	end
	local cost, levels = Formulas.LevelUpCost(data.AnimalId, data.Level, amount)
	if levels <= 0 then
		return false, "Esse animal já está no nível máximo!"
	end
	if not Wallet.TrySpend(player, cost) then
		NotifyService.Notify(player, "Dinheiro insuficiente para subir o nível!", "danger")
		return false, "Dinheiro insuficiente! Faltam " .. Format.Money(math.max(0, cost - profile.Data.Money))
	end
	data.Level += levels
	renderSlot(barn, slotIndex)
	SyncService.Push(player)
	local animal = GameConfig.AnimalsById[data.AnimalId]
	return true, string.format("%s subiu para o nível %d! ⬆", animal.Name, data.Level)
end

function BarnService.SellSlot(player: Player, slotIndex: number): (boolean, string)
	local barn = barnOf[player]
	local profile = DataService.Get(player)
	if not barn or not profile then
		return false, "Seu celeiro ainda está carregando."
	end
	local key = tostring(slotIndex)
	local data = profile.Data.Slots[key]
	if not data then
		return false, "Esse lugar está vazio."
	end
	if not data.Hatched then
		return false, "Esse ovo ainda está chocando."
	end
	local animal = GameConfig.AnimalsById[data.AnimalId]
	local price = Formulas.SellPrice(data.AnimalId, data.Mutation)
	local stored = math.floor(data.Stored)
	profile.Data.Slots[key] = nil
	Wallet.Add(player, price + stored)
	renderSlot(barn, slotIndex)
	SyncService.Push(player)
	return true, string.format("Você vendeu %s %s por %s!", animal.Icon, animal.Name, Format.Money(price))
end

function BarnService.Init()
	local folder = Instance.new("Folder")
	folder.Name = "Celeiros"
	folder.Parent = Workspace:FindFirstChild("Mapa") or Workspace

	for _, layout in MapLayout.Barns do
		local barn = buildBarn(layout.Index, layout.CFrame, folder)
		table.insert(barns, barn)
		renderAll(barn)
		barn.SignPrompt.Triggered:Connect(function(player)
			if barn.Owner ~= player then
				NotifyService.Notify(player, "Essa placa é do dono deste celeiro!", "warning")
				return
			end
			if not RateLimit.Check(player, "BuySlot", 0.3) then
				return
			end
			local ok, message = BarnService.BuySlot(player)
			NotifyService.Notify(player, message, if ok then "success" else "danger")
		end)
	end

	-- Loop rápido: guardar ovos, coletores e elevadores
	task.spawn(function()
		while true do
			task.wait(0.2)
			local clock = os.clock()
			for _, barn in barns do
				local owner = barn.Owner
				local root = if owner then getRoot(owner) else nil
				if owner and root then
					local localPosition = barn.CFrame:PointToObjectSpace(root.Position)
					if MapLayout.IsInsideBarn(localPosition) then
						if CarryService.Count(owner) > 0 then
							placeCarried(barn, owner)
						end
						for _, slot in barn.Slots do
							local offset = root.Position - slot.PadPosition
							if
								math.abs(offset.X) <= Map.PadSize.X / 2 + 1
								and math.abs(offset.Z) <= Map.PadSize.Z / 2 + 1
								and offset.Y > -1
								and offset.Y < 7
							then
								collect(barn, owner, slot.Index)
							end
						end
					end
				end

				-- Elevadores servem para qualquer jogador
				if #barn.Elevators > 0 then
					for _, player in Players:GetPlayers() do
						local playerRoot = getRoot(player)
						if playerRoot and clock - (lastElevator[player] or 0) > 1.5 then
							for _, elevator in barn.Elevators do
								local offset = playerRoot.Position - elevator.Position
								if Vector2.new(offset.X, offset.Z).Magnitude < 2.6 and offset.Y > -1 and offset.Y < 6 then
									lastElevator[player] = clock
									local character = player.Character
									if character then
										MovementService.Reset(player)
										character:PivotTo(barn.CFrame * CFrame.new(MapLayout.GetFloorArrival(elevator.TargetFloor)))
									end
									break
								end
							end
						end
					end
				end
			end
		end
	end)

	-- Loop de 1 s: chocar ovos e gerar dinheiro
	task.spawn(function()
		while true do
			local dt = task.wait(1)
			local now = os.time()
			for _, barn in barns do
				local owner = barn.Owner
				local profile = if owner then DataService.Get(owner) else nil
				if owner and profile then
					for key, data in profile.Data.Slots do
						local slotIndex = tonumber(key)
						if slotIndex then
							if not data.Hatched and now >= data.HatchAt then
								hatch(barn, owner, profile, slotIndex, data, false)
							elseif data.Hatched then
								local income = Formulas.AnimalIncome(data.AnimalId, profile.Data.Rebirths, data.Level, data.Mutation)
								data.Stored += income * dt
								updatePadLabel(barn.Slots[slotIndex], data.Stored)
							end
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastFullMessage[player] = nil
		lastElevator[player] = nil
	end)
end

return BarnService
